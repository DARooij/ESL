#include "object_tracker.hpp"
#include <glib.h>

ObjectTracker::ObjectTracker() {
    mask_lower_bound_ = cv::Scalar(0, 100, 100);   // Lower bound of red hue
    mask_upper_bound_ = cv::Scalar(10, 255, 255);  // Upper bound of red hue
}

cv::Mat ObjectTracker::processFrame(cv::Mat& frame) {
    g_print("Received frame of size: %dx%d\n", frame.cols, frame.rows);
    if (frame.empty()) return frame;

    cv::Mat hsv_frame, mask;

    // 1. Convert to HSV
    cv::cvtColor(frame, hsv_frame, cv::COLOR_BGR2HSV);
    g_print("Processing frame of size: %dx%d\n", frame.cols, frame.rows);

    // 2. Apply Color Mask
    cv::inRange(hsv_frame, mask_lower_bound_, mask_upper_bound_, mask);
    g_print("Mask created with %d non-zero pixels\n", cv::countNonZero(mask));

    // 3. Clean up noise with Morphological Operations
    // A 5x5 structural element works well for 320x240 resolutions
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(5, 5));
    cv::morphologyEx(mask, mask, cv::MORPH_OPEN, kernel);  // Removes background noise
    cv::morphologyEx(mask, mask, cv::MORPH_CLOSE, kernel); // Fills interior holes
    g_print("After morphological operations, mask has %d non-zero pixels\n", cv::countNonZero(mask));

    // 4. Calculate Moments
    cv::Moments moments = cv::moments(mask, true);
    g_print("Moments calculated: m00=%f, m10=%f, m01=%f\n", moments.m00, moments.m10, moments.m01);
    // Lazily prepare a debug frame only if we intend to visualize
    cv::Mat debug_frame; 

    if (moments.m00 > 100) { // Added a minimum area threshold (100 pixels) to ignore tiny noise streaks
        // Calculate center of gravity (COG)
        double cog_x = moments.m10 / moments.m00;
        double cog_y = moments.m01 / moments.m00;

        // Normalize COG
        double normalized_x = (2.0 * cog_x / mask.cols) - 1.0;
        double normalized_y = 1.0 - (2.0 * cog_y / mask.rows);
        
        std::cout << "Object at: x=" << normalized_x << ", y=" << normalized_y << "      \r" << std::flush;

        // Draw visual indicators
        debug_frame = frame.clone(); 
        cv::circle(debug_frame, cv::Point2d(cog_x, cog_y), 10, cv::Scalar(255, 0, 255), -1);
    } else {
        debug_frame = frame.clone(); // Just reference original if no object found
    }
    return debug_frame;
}