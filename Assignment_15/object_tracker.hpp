#ifndef OBJECT_TRACKER_HPP
#define OBJECT_TRACKER_HPP

#include <opencv2/opencv.hpp>
#include <vector>

class ObjectTracker {
public:
    ObjectTracker();
    
    // Takes the raw frame from GStreamer and processes it
    cv::Mat processFrame(cv::Mat& frame);

private:
    cv::Scalar mask_lower_bound_;
    cv::Scalar mask_upper_bound_;
};

#endif // OBJECT_TRACKER_HPP