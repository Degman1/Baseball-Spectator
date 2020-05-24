//
//  InfieldContourFitting.mm
//  Baseball-Spectator
//
//  Created by David Gerard on 5/23/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <UIKit/UIKit.h>

#import "ContourInfo.mm"

using namespace std;

class InfieldContourFitting {
    public:
    vector<cv::Point> quadrilateralHoughFit(ContourInfo contourInfo) {
        // Use the OpenCV Hough Finding algorigthm to find the closest quadrilateral fit for the given contour
        
        vector<cv::Point> quadFit;
        
        // Offset the contour by the amount specified in offsetVector so the top left of the contour is the top left of the image
        vector<cv::Point> offsetContour;
        
        // Use a loop for now to subtract offsetVector from each point in the contour for lack of better solution
        for (cv::Point point : contourInfo.contour) {
            cv::Point offsetPoint;
            offsetPoint.x = point.x - contourInfo.x;
            offsetPoint.y = point.y - contourInfo.y;
            offsetContour.push_back(offsetPoint);
        }
        
        // fill the contourPlot with a 2D array of zeros (blank image)
        cv::Mat contourPlot = cv::Mat::zeros(contourInfo.height, contourInfo.width, CV_8UC1);
        
        //cout << "offset: " << offsetContour;
                
        // in order to use the contour to draw on another image, it must be an array of contours
        vector<vector<cv::Point>> offsetContourForDrawing;
        offsetContourForDrawing.push_back(offsetContour);
        
        // redraw the shifted contour onto the new image (perfectly fits in the image)
        cv::drawContours(contourPlot, offsetContourForDrawing, -1, cv::Scalar(255, 255, 255), 1);
                
        // find all the hough lines in the image
        vector<cv::Vec2f> lines;
        cv::HoughLines(contourPlot, lines, 2, M_PI / 180, 80);
        
        if (lines.empty() or lines.size() < 4) {
            // the quadrilateral fit failed, so try again using the extreme points
            return getCornersUsingExtremePoints(contourInfo.contour);
        }
        
        // now that we have a sufficient number of hough lines, pick the four best representative of the contour's four sides and find the intersection between those lines to get the four corners
        vector<cv::Point> result = getCornersUsingHoughLines(lines, contourInfo.width, contourInfo.height);
        
        if (result.empty() or result.size() != 4) {
            // the quadrilateral fit using hough lines failed so try again using the extreme points
            return getCornersUsingExtremePoints(contourInfo.contour);
        } else {
            return result;
        }
    }
    
    vector<cv::Point> getCornersUsingHoughLines(vector<cv::Vec2f> houghLines, int width, int height) {
        int centerX = width / 2;
        int centerY = height / 2;
        
        vector<int> boundaries;        // defines the boundaries by which
        boundaries.push_back(-100);
        boundaries.push_back(width + 100);
        boundaries.push_back(-100);
        boundaries.push_back(height + 100);
        
        int distanceThreshold = 10;
        double thetaThreshold = M_PI / 9;
        cv::Mat bestLines;
        
        vector<cv::Point> ret;
        return ret;
    }
    
    vector<cv::Point> getCornersUsingExtremePoints(vector<cv::Point> contour) {
        vector<cv::Point> ret;
        return ret;
    }

};
