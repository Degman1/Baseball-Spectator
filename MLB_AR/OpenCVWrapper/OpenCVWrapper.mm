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

@end
