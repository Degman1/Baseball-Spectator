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
        
        cv::Mat contourPlot;
        // fill the contourPlot with a 2D array of zeros
        cv::Mat::zeros(contourInfo.height, contourInfo.width, CV_32F);
        cv::drawContours(contourPlot, offsetContour, -1, 255, 1);       // TODO may need to add another array surrounding offsetContour
        
        // find all the hough lines in the image
        cv::Mat lines;
        cv::HoughLines(contourPlot, lines, 2, M_PI / 180, 80);
        
        if (lines.empty() or lines.rows < 4) {
            return quadFit;     // the quadrilateral fit failed, so return an empty vector
        }
        
        vector<cv::Point> result = getCornersUsingHoughLines(lines, contourInfo.width, contourInfo.height);
        
        if (result.empty() or result.size() != 4) {
            return getCornersUsingExtremePoints(contourInfo.contour);
        } else {
            return result;
        }
        
        return offsetContour;
    }
    
    vector<cv::Point> getCornersUsingHoughLines(cv::Mat houghLines, int width, int height) {
        
    }
    
    vector<cv::Point> getCornersUsingExtremePoints(vector<cv::Point> contour) {
        
    }

};
