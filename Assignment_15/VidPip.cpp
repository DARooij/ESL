#include <gst/gst.h>
#include <glib.h>

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


static GstFlowReturn new_sample (GstElement *sink, gpointer *data) {
  GstSample *sample;
  GstStructure *structure;
  GstCaps *caps;
  GstMapInfo map;
  gint width, height;
  GstBuffer *buffer;

  /* Retrieve the buffer */
  g_signal_emit_by_name (sink, "pull-sample", &sample);
  if (!sample) {
    // g_print ("*");
    return GST_FLOW_ERROR;
  }

  caps = gst_sample_get_caps(sample);
  if (!caps) {
    gst_sample_unref(sample);
    g_print ("Could not get caps from sample\n");
    return GST_FLOW_ERROR;
  }

   structure = gst_caps_get_structure (caps, 0);
   buffer = gst_sample_get_buffer(sample);
   if (gst_buffer_map(buffer, &map, GST_MAP_READ)) {
        g_print("Es gucci man bro\n");
   } else {
        g_print("No man, no es gucci\n");
   }

   gst_buffer_unmap(buffer, &map);
   return GST_FLOW_OK;
}

int main (int   argc,
      char *argv[])
{
  GMainLoop *loop;

  GstElement *pipeline, *source, *encoder, *decoder, *sink;
  GstCaps *format;
  GstBus *bus;
  guint bus_watch_id;

  /* Initialisation */
  gst_init (&argc, &argv);

  loop = g_main_loop_new (NULL, FALSE);

  /* Create gstreamer elements */
  pipeline = gst_pipeline_new ("yuv-from-camera-pipeline");
  source   = gst_element_factory_make ("v4l2src",       "video-source");
  encoder  = gst_element_factory_make ("jpegenc",      "jpeg-encoder");
  decoder     = gst_element_factory_make ("jpegdec",  "jpeg-decoder");
  sink     = gst_element_factory_make ("appsink", "app-sink");

  if (!pipeline || !source || !encoder || !decoder || !sink) {
    g_printerr ("One element could not be created. Exiting.\n");
    return -1;
  }

  g_object_set (source, "device", "/dev/video0", NULL);
  g_object_set (sink, "emit-signals", TRUE, NULL);
  g_signal_connect(sink, "new-sample", G_CALLBACK(new_sample), NULL);

  format  = gst_caps_from_string("image/jpeg, width=320, height=240, framerate=30/1");

  /* we add a message handler */
  bus = gst_pipeline_get_bus (GST_PIPELINE (pipeline));
  bus_watch_id = gst_bus_add_watch (bus, bus_call, loop);
  gst_object_unref (bus);

  /* we add all elements into the pipeline */
  /* file-source | ogg-demuxer | vorbis-decoder | converter | alsa-output */
  gst_bin_add_many (GST_BIN (pipeline),
                    source, encoder, format, decoder, sink, NULL);

  /* we link the elements together */
  /* file-source -> ogg-demuxer ~> vorbis-decoder -> converter -> alsa-output */
  gst_element_link (source, encoder);
  gst_element_link_filtered (encoder, decoder, format);
  gst_element_link (decoder, sink);

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
