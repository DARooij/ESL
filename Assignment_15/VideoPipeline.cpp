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
  GMainLoop *loop;
  GstElement *pipeline, *source, *vidconv, *encoder, *decoder, *sink;
  GstCaps *format;
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
  GstSample *sample;
  GstBuffer *buffer;
  GstMapInfo map;
  GstCaps *caps;
  GstStructure *structure;
  gint width, height;

  // 1. Pull the sample
  g_signal_emit_by_name (sink, "pull-sample", &sample);
  if (!sample) return GST_FLOW_ERROR;

  // 2. Get width and height from caps
  caps = gst_sample_get_caps(sample);
  structure = gst_caps_get_structure(caps, 0);
  gst_structure_get_int(structure, "width", &width);
  gst_structure_get_int(structure, "height", &height);

  // 3. Map the buffer memory
  buffer = gst_sample_get_buffer(sample);
  if (gst_buffer_map(buffer, &map, GST_MAP_READ)) {
      
      // 4. Wrap the raw data directly into an OpenCV Mat (Zero Copy)
      cv::Mat frame(height, width, CV_8UC3, (char*)map.data);

      // Pass it to your object tracker object (passed via the user 'data' pointer)
      // ObjectTracker *tracker = (ObjectTracker*)data;
      tracker.processFrame(frame);

      gst_buffer_unmap(buffer, &map);
  }

  gst_sample_unref(sample);
  return GST_FLOW_OK;
}

int main (int argc, char *argv[])
{
  GMainLoop *loop;
  GstElement *pipeline, *source, *vidconv, *encoder, *decoder, *sink;
  GstCaps *format;
  GstBus *bus;
  guint bus_watch_id;

  /* Initialisation */
  gst_init (&argc, &argv);

  loop = g_main_loop_new (NULL, FALSE);

  /* Create gstreamer elements */
  pipeline = gst_pipeline_new ("yuv-from-camera-pipeline");
  source   = gst_element_factory_make ("v4l2src",      "video-source");
  vidconv  = gst_element_factory_make ("videoconvert", "video-converter"); /* Added for safe format conversion */
  encoder  = gst_element_factory_make ("jpegenc",      "jpeg-encoder");
  decoder  = gst_element_factory_make ("jpegdec",      "jpeg-decoder");
  sink     = gst_element_factory_make ("appsink",      "app-sink");

  if (!pipeline || !source || !vidconv || !encoder || !decoder || !sink) {
    g_printerr ("One or more elements could not be created. Exiting.\n");
    return -1;
  }

  g_object_set (source, "device", "/dev/video0", NULL);
  g_object_set (sink, "emit-signals", TRUE, NULL);
  g_signal_connect (sink, "new-sample", G_CALLBACK (new_sample), &tracker);

  /* Set up the caps we want from the camera */
  format = gst_caps_from_string("video/x-raw, width=320, height=240, framerate=30/1");

  /* Add a message handler */
  bus = gst_pipeline_get_bus (GST_PIPELINE (pipeline));
  bus_watch_id = gst_bus_add_watch (bus, bus_call, loop);
  gst_object_unref (bus);

  /* Add all elements to the pipeline. NOTE: Do NOT add GstCaps to this function! */
  gst_bin_add_many (GST_BIN (pipeline), source, vidconv, encoder, decoder, sink, NULL);

  /* Link the elements together: 
     v4l2src -> [caps] -> videoconvert -> jpegenc -> jpegdec -> appsink */
  
  if (!gst_element_link_filtered (source, vidconv, format)) {
    g_printerr("Failed to link source to videoconvert with specified caps.\n");
    gst_caps_unref(format);
    return -1;
  }
  gst_caps_unref(format); /* Clean up caps after linking */

  gst_element_link_many (vidconv, encoder, decoder, sink, NULL);

  /* Set the pipeline to "playing" state*/
  g_print ("Now playing pipeline...\n");
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