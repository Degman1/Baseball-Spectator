//
//  OpenCVWrapper.m
//  MLB_AR
//
//  Created by Joey Cohen on 1/7/20.
//  Copyright © 2020 Joey Cohen. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "OpenCVWrapper.h"
#import <opencv2/imgcodecs/ios.h>
#import <UIKit/UIKit.h>

using namespace std;

@implementation OpenCVWrapper

+ (NSString *)openCVVersionString {
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}

+ (UIImage *)convertToGrayscale:(UIImage *)image {
    cv::Mat mat;
    UIImageToMat(image, mat);
    cv::Mat gray;
    cv::cvtColor(mat, gray, cv::COLOR_RGB2GRAY);
    UIImage *grayscale = MatToUIImage(gray);
    return grayscale;
}

+ (UIImage *)blur:(UIImage *)image radius:(double)radius {
    cv::Mat mat;
    UIImageToMat(image, mat);
    cv::GaussianBlur(mat, mat, cv::Size(NULL, NULL), radius);
    UIImage *blurredImage = MatToUIImage(mat);
    return blurredImage;
}

+ (UIImage *)convertRGBtoHSV:(UIImage *)image {
    cv::Mat mat, hsv, greenMask, brownMask, darkBrownMask, fieldMask, erosion;
    
    // Convert to HSV colorspace
    UIImageToMat(image, mat);
    cv::cvtColor(mat, hsv, cv::COLOR_RGB2HSV);
    
    // Green mask
    cv::inRange(hsv, cv::Scalar(17, 50, 20), cv::Scalar(72, 255, 242), greenMask);
    
    // Brown Mask
    cv::inRange(hsv, cv::Scalar(7, 80, 25), cv::Scalar(27, 255, 255), brownMask);
    
    // Dark Brown Mask
    cv::inRange(hsv, cv::Scalar(2, 93, 25), cv::Scalar(10, 175, 150), darkBrownMask);
    
    // Combine each mask to get a mask of the entire playing field
    cv::bitwise_or(greenMask, brownMask, fieldMask);
    cv::bitwise_or(fieldMask, darkBrownMask, fieldMask);
    
    
    
    
    // Player Position Detection: ----------------------------------------------------------------------
    
    // Erode the image to remove impurities
    cv::erode(greenMask, erosion, getStructuringElement(cv::MORPH_RECT, cv::Size(4, 4)));
    
    // Find all contours in the image
    vector<vector<cv::Point>> contours;     // contains the array of contours
    vector<cv::Vec4i> hierarchy;            // don't actually use this at all
    cv::findContours(erosion, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);
    
    // Only keep the contours which have a certain bounding box area
    vector<ContourInfo> infieldContours;
    
    for (vector<cv::Point> c : contours) {
        cv::Rect rect = cv::boundingRect(c);
        double area = rect.height * rect.width;
        
        if (area > 18500 and area < 2000000) {
            ContourInfo info;
            info.contour = c;
            info.x = rect.x;
            info.y = rect.y;
            info.width = rect.width;
            info.height = rect.height;
            infieldContours.push_back(info);
        }
    }
    
    // Sort the list of contours from biggest area to smallest
    //contour_list.sort(key=lambda c: c['widths'][0] * c['widths'][1], reverse=True)
    
    UIImage *result = MatToUIImage(fieldMask);
    return result;
}

// Class to hold a contour and its basic properties
class ContourInfo {
    public:
    vector<cv::Point> contour;
    double x;
    double y;
    double width;
    double height;
    
    void printDescription(bool displayContour = false) {
        cout << "{ ";
        if (displayContour) {
            cout << "contour: " << contour << ", ";
        }
        cout << "x: " << x << ", y: " << y << ", h: " << height << ", w: " << width << " }\n";
    }
};


@end
