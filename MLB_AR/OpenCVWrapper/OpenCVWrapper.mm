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
    cv::Mat mat, hsv, greenMask, brownMask, darkBrownMask, fieldMask;
    
    //Convert to HSV colorspace
    UIImageToMat(image, mat);
    cv::cvtColor(mat, hsv, cv::COLOR_RGB2HSV);
    
    //Green mask
    cv::inRange(hsv, cv::Scalar(17, 50, 20), cv::Scalar(72, 255, 242), greenMask);
    
    //Brown Mask
    cv::inRange(hsv, cv::Scalar(7, 80, 25), cv::Scalar(27, 255, 255), brownMask);
    
    //Dark Brown Mask
    cv::inRange(hsv, cv::Scalar(2, 93, 25), cv::Scalar(10, 175, 150), darkBrownMask);
    
    //Combine each mask to get a mask of the entire playing field
    cv::bitwise_or(greenMask, brownMask, fieldMask);
    cv::bitwise_or(fieldMask, darkBrownMask, fieldMask);
    
    UIImage *result = MatToUIImage(fieldMask);
    return result;
}

@end
