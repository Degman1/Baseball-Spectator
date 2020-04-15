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

+ (UIImage *)processImage:(UIImage *)image expectedHomePlateAngle:(double)expectedHomePlateAngle {
    PlayerFinder finder = PlayerFinder();
    return finder.processImage(image, expectedHomePlateAngle);
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
        cout << "x: " << x << ", y: " << y << ", h: " << height << ", w: " << width;
        cout << ", a: " << (height * width) << " }\n";
    }
};

bool sortByArea(const ContourInfo &struct1, const ContourInfo &struct2) {
    return ((struct1.width * struct1.height) > (struct2.width * struct2.height));
}




class PlayerFinder {
    public:
    cv::Scalar lowerGreen, upperGreen, lowerBrown, upperBrown, lowerDarkBrown, upperDarkBrown;
    
    PlayerFinder() {
        lowerGreen = cv::Scalar(17, 50, 20);
        upperGreen = cv::Scalar(72, 255, 242);
        
        lowerBrown = cv::Scalar(7, 80, 25);
        upperBrown = cv::Scalar(27, 255, 255);
        
        lowerDarkBrown = cv::Scalar(2, 93, 25);
        upperDarkBrown = cv::Scalar(10, 175, 150);
    }
    
    UIImage* processImage(UIImage* image, double expectedHomePlateAngle) {
        cv::Mat mat, hsv, greenMask, brownMask, darkBrownMask, fieldMask, erosion;
        
        // Convert to HSV colorspace
        UIImageToMat(image, mat);
        cv::cvtColor(mat, hsv, cv::COLOR_RGB2HSV);
        
        // Green mask
        cv::inRange(hsv, lowerGreen, cv::Scalar(72, 255, 242), greenMask);
        
        // Brown Mask
        cv::inRange(hsv, cv::Scalar(7, 80, 25), cv::Scalar(27, 255, 255), brownMask);
        
        // Dark Brown Mask
        cv::inRange(hsv, cv::Scalar(2, 93, 25), cv::Scalar(10, 175, 150), darkBrownMask);
        
        // Combine each mask to get a mask of the entire playing field
        cv::bitwise_or(greenMask, brownMask, fieldMask);
        cv::bitwise_or(fieldMask, darkBrownMask, fieldMask);
        
        // Get the location of the standard position of each of the fielders
        vector<cv::Point> infieldContour = getPositionLocations(greenMask, expectedHomePlateAngle);
        
        // Get the location of each of the actual players on the field
        getPlayerContourLocations(fieldMask);
        
        vector<vector<cv::Point>> contoursToDraw;
        contoursToDraw.push_back(infieldContour);
        
        cv::drawContours(mat, contoursToDraw, -1, cv::Scalar(255, 255, 0), 10);
        
        //Convert the Mat image to a UIImage
        UIImage *result = MatToUIImage(mat);
        
        return result;
    }
    
    vector<cv::Point> getPositionLocations(cv::Mat greenMask, double expectedHomePlateAngle) {
        cv::Mat erosion;
        
        // Erode the image to remove impurities
        cv::erode(greenMask, erosion, getStructuringElement(cv::CHAIN_APPROX_SIMPLE, cv::Size(4, 4)));

        
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
        
        ContourInfo infield = ContourInfo();
        infield.x = -1;
        
        // Sort the list of contours from biggest area to smallest
        sort(infieldContours.begin(), infieldContours.end(), sortByArea);
        
        // DEBUG
        for (ContourInfo c : infieldContours) {
            c.printDescription();
        }
        cout << "\n";
        
        for (ContourInfo cnt : infieldContours) {
            double ratio = cnt.height / cnt.width;
            
            if (ratio < 0.4 and (infield.x == -1 or cnt.width < infield.width) and cv::contourArea(cnt.contour) > 10000) {
                infield = cnt;
            }
        }
        
        if (infield.x == -1) {  }
        
        vector<cv::Point> infieldHull;
        cv::convexHull(infield.contour, infieldHull);
        
        return infieldHull;
    }
    
    void getPlayerContourLocations(cv::Mat fieldMask) {
        
    }
};


@end
