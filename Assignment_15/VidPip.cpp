#include <opencv2/opencv.hpp>
#include "object_tracker.hpp" 

#include <gst/gst.h>
#include <glib.h>

ObjectTracker tracker;

static gboolean
bus_call (GstBus     *bus,
          GstMessage *msg,
          gpointer    data)
{
  GMainLoop *loop = (GMainLoop *) data;

  switch (GST_MESSAGE_TYPE (msg)) {

    case GST_MESSAGE_EOS:
      g_print ("End of stream\n");
      g_main_loop_quit (loop);
      break;

    case GST_MESSAGE_ERROR: {
      gchar  *debug;
      GError *error;

      gst_message_parse_error (msg, &error, &debug);
      g_free (debug);

      g_printerr ("Error: %s\n", error->message);
      g_error_free (error);

      g_main_loop_quit (loop);
      break;
    }
    default:
      break;
  }

  return TRUE;
}


static GstFlowReturn new_sample (GstElement *sink, gpointer data) {
  // Extract the appsrc we passed in via g_signal_connect
//   GstElement *appsrc = (GstElement *)data; 
  
  GstSample *sample;
  GstStructure *structure;
  GstCaps *caps;
  GstMapInfo map;
  int width, height;
  GstBuffer *buffer;

  g_signal_emit_by_name (sink, "pull-sample", &sample);
  if (!sample) return GST_FLOW_ERROR;

  caps = gst_sample_get_caps(sample);
  structure = gst_caps_get_structure (caps, 0);
  gst_structure_get_int(structure, "width", &width);
  gst_structure_get_int(structure, "height", &height);
  buffer = gst_sample_get_buffer(sample);

  if (gst_buffer_map(buffer, &map, GST_MAP_READ)) {
        // 1. Give frame to OpenCV
        cv::Mat frame(height, width, CV_8UC3, (char*)map.data);
        cv::Mat processed_frame = tracker.processFrame(frame);

        // 2. Allocate a new GStreamer buffer for the output
        // guint size = processed_frame.total() * processed_frame.elemSize();
        // GstBuffer *out_buffer = gst_buffer_new_allocate(NULL, size, NULL);
        // GstMapInfo out_map;
                
        // // 3. Copy OpenCV data into the new GStreamer buffer
        // gst_buffer_map(out_buffer, &out_map, GST_MAP_WRITE);
        // memcpy(out_map.data, processed_frame.data, size);
        // gst_buffer_unmap(out_buffer, &out_map);

        // // 4. Push the buffer into the Output Pipeline
        // GstFlowReturn ret;
        // g_signal_emit_by_name(appsrc, "push-buffer", out_buffer, &ret);
        
        // Clean up the output buffer
        // gst_buffer_unref(out_buffer);
   }

   gst_buffer_unmap(buffer, &map);
   gst_sample_unref(sample); // Don't forget to unref the sample to prevent memory leaks!
   return GST_FLOW_OK;
}

int main (int   argc,
      char *argv[])
{
  GMainLoop *loop;

  GstElement *pipeline, *source, *encoder, *decoder, *sink, *tee;
  GstCaps *format;
  GstBus *bus;
  guint bus_watch_id;

  /* Initialisation */
  gst_init (&argc, &argv);

  loop = g_main_loop_new (NULL, FALSE);

  /* Create gstreamer elements */
  pipeline = gst_pipeline_new ("yuv-from-camera-pipeline");
  source   = gst_element_factory_make ("v4l2src",       "video-source");  
  tee = gst_element_factory_make("tee", "tee");
  
  GstElement *queue_cv = gst_element_factory_make ("queue", "queue-cv");
  GstElement *queue_vid = gst_element_factory_make ("queue", "queue-vid");
  
  encoder  = gst_element_factory_make ("jpegenc",      "jpeg-encoder");
  decoder  = gst_element_factory_make ("jpegdec",  "jpeg-decoder");
  GstElement *convert = gst_element_factory_make ("videoconvert", "converter");
  GstElement *vid_convert = gst_element_factory_make ("videoconvert", "vid-convert");
  sink     = gst_element_factory_make ("appsink", "app-sink");
  GstElement *videosink = gst_element_factory_make ("autovideosink", "video-sink");

  g_object_set(videosink, "sync", FALSE, "async", FALSE, NULL);
  
if (!pipeline || !source || !encoder || !decoder || !convert || !tee || !sink || !videosink) {
    g_printerr ("One element could not be created. Exiting.\n");
    return -1;
  }

  g_object_set (source, "device", "/dev/video0", NULL);
  g_object_set (sink, "emit-signals", TRUE, NULL);
  g_object_set (videosink, "sync", FALSE, "async", FALSE, NULL);
  GstCaps *app_caps = gst_caps_from_string("video/x-raw, format=BGR");
  g_object_set(sink, "caps", app_caps, NULL);
  gst_caps_unref(app_caps);

//   GstCaps *src_caps = gst_caps_from_string("video/x-raw, format=BGR, width=320, height=240, framerate=30/1");
//   g_object_set(appsrc, "caps", src_caps, "format", GST_FORMAT_TIME, "is-live", TRUE, NULL);
//   gst_caps_unref(src_caps);

  g_signal_connect(sink, "new-sample", G_CALLBACK(new_sample), NULL);

  format  = gst_caps_from_string("image/jpeg, width=320, height=240, framerate=30/1");

  /* we add a message handler */
  bus = gst_pipeline_get_bus (GST_PIPELINE (pipeline));
  bus_watch_id = gst_bus_add_watch (bus, bus_call, loop);
  gst_object_unref (bus);

  /* we add all elements into the pipeline */
  /* file-source | ogg-demuxer | vorbis-decoder | converter | alsa-output */
gst_bin_add_many (GST_BIN (pipeline),
                    source, tee, queue_cv, encoder, decoder, convert, sink, 
                    queue_vid, vid_convert, videosink, NULL);
  /* we link the elements together */
  /* file-source -> ogg-demuxer ~> vorbis-decoder -> converter -> alsa-output */
//   gst_element_link (source, encoder);
  if (!gst_element_link(source, tee) || !gst_element_link(tee, queue_cv) 
    || !gst_element_link(queue_cv, encoder) || !gst_element_link_filtered(encoder, decoder, format) 
    || !gst_element_link_many(decoder, convert, sink, NULL) 
    || !gst_element_link(tee, queue_vid) || !gst_element_link_many(queue_vid, vid_convert, videosink, NULL))
  {
      g_printerr("Elements could not be linked. Exiting.\n");
      return -1;
  }
  //   gst_element_link_many (appsrc, out_convert, videosink, NULL);

  /* note that the demuxer will be linked to the decoder dynamically.
     The reason is that Ogg may contain various streams (for example
     audio and video). The source pad(s) will be created at run time,
     by the demuxer when it detects the amount and nature of streams.
     Therefore we connect a callback function which will be executed
     when the "pad-added" is emitted.*/

  gst_caps_unref(format);

  /* Set the pipeline to "playing" state*/
  g_print ("Now playing: %s\n", argv[1]);
  gst_element_set_state (pipeline, GST_STATE_PLAYING);


  /* Iterate */
  g_print ("Running...\n");
  g_main_loop_run (loop);


  /* Out of the main loop, clean up nicely */
  g_print ("Returned, stopping playback\n");
  gst_element_set_state (pipeline, GST_STATE_NULL);

  g_print ("Deleting pipeline\n");
  gst_object_unref (GST_OBJECT (pipeline));
  g_source_remove (bus_watch_id);
  g_main_loop_unref (loop);

  return 0;
}
