#include <opencv2/opencv.hpp>
#include "object_tracker.hpp" 
#include <thread>
#include "Controller.hpp"

#include <gst/gst.h>
#include <glib.h>

Controller controller;
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
  std::tuple<double, double> normalized_values;

  if (gst_buffer_map(buffer, &map, GST_MAP_READ)) {
        cv::Mat frame(height, width, CV_8UC3, (char*)map.data);
        normalized_values = tracker.processFrame(frame);
   }

   controller.setReference(std::get<0>(normalized_values), std::get<1>(normalized_values));

   gst_buffer_unmap(buffer, &map);
   gst_sample_unref(sample); 
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

  g_object_set (source, "device", "/dev/video7", NULL);
  g_object_set (sink, "emit-signals", TRUE, NULL);
  g_object_set (videosink, "sync", FALSE, "async", FALSE, NULL);
  GstCaps *app_caps = gst_caps_from_string("video/x-raw, format=BGR");
  g_object_set(sink, "caps", app_caps, NULL);
  gst_caps_unref(app_caps);

  g_signal_connect(sink, "new-sample", G_CALLBACK(new_sample), NULL);

  format  = gst_caps_from_string("image/jpeg, width=320, height=240, framerate=30/1");

  /* we add a message handler */
  bus = gst_pipeline_get_bus (GST_PIPELINE (pipeline));
  bus_watch_id = gst_bus_add_watch (bus, bus_call, loop);
  gst_object_unref (bus);

  gst_bin_add_many(GST_BIN(pipeline),
                   source, tee, queue_cv, encoder, decoder, convert, sink,
                   /*queue_vid, vid_convert, videosink, */NULL);

  if (!gst_element_link(source, tee) || !gst_element_link(tee, queue_cv) 
    || !gst_element_link(queue_cv, encoder) || !gst_element_link_filtered(encoder, decoder, format) 
    || !gst_element_link_many(decoder, convert, sink, NULL) 
    /*|| !gst_element_link(tee, queue_vid) || !gst_element_link_many(queue_vid, vid_convert, videosink, NULL)*/)
  {
      g_printerr("Elements could not be linked. Exiting.\n");
      return -1;
  }

  gst_caps_unref(format);

  /* Set the pipeline to "playing" state*/
  g_print ("Now playing: %s\n", argv[1]);
  gst_element_set_state (pipeline, GST_STATE_PLAYING);

  /* Create thread to run the controller loop */
  std::thread controller_thread(&Controller::run, &controller);

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
  controller_thread.join();

  return 0;
}
