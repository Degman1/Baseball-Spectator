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
        cv::Point offset;
        offset.x = contourInfo.x;
        offset.y = contourInfo.y;
        vector<cv::Point> displacedContour = offsetContour(contourInfo.contour, offset, true);
        
        // fill the contourPlot with a 2D array of zeros (blank image)
        cv::Mat contourPlot = cv::Mat::zeros(contourInfo.height, contourInfo.width, CV_8UC1);
                        
        // in order to use the contour to draw on another image, it must be an array of contours
        vector<vector<cv::Point>> displacedContourForDrawing;
        displacedContourForDrawing.push_back(displacedContour);
        
        // redraw the shifted contour onto the new image (perfectly fits in the image)
        cv::drawContours(contourPlot, displacedContourForDrawing, -1, cv::Scalar(255, 255, 255), 1);
                
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
        vector<cv::Point> contourCorners;       // eventually will hold the four corners of the contour
                                                // return this empty vector to indicate failure
        int centerX = width / 2;
        int centerY = height / 2;
        
        vector<int> boundaries;        // defines the boundaries by which
        boundaries.push_back(-100);
        boundaries.push_back(width + 100);
        boundaries.push_back(-100);
        boundaries.push_back(height + 100);
        
        int distanceThreshold = 10;
        double thetaThreshold = M_PI / 9;
        vector<cv::Vec4f> bestLines;
        
        // go through each of the lines and attempt to find the best four that fit the contour
        // they are already ordered by confidence, but some of the similar lines on the same side of the contour
        //     might both be at the top of the list
        for (cv::Vec2f line : houghLines) {
            cv::Vec2f lineCopy = line;
            
            // if the line has a negative distance, flip it so it has a positive distance, but is still the same line
            if (lineCopy[0] < 0) {
                lineCopy[0] *= -1;
                lineCopy[1] -= M_PI;
            }
            
            cv::Point coordinateNearReference = computeLineNearReference(lineCopy, centerX, centerY);
            
            if (!bestLines.empty() or bestLines.size() != 0 or !isClose(bestLines, lineCopy, coordinateNearReference, distanceThreshold, thetaThreshold)) {
                cv::Vec4f goodLine;
                goodLine[0] = lineCopy[0];
                goodLine[1] = lineCopy[1];
                goodLine[2] = coordinateNearReference.x;
                goodLine[2] = coordinateNearReference.y;
                bestLines.push_back(goodLine);
                
                // stop when we have 4 reference lines (four sides of the quadrilateral)
            }
            
            if (bestLines.size() == 4) {
                break;
            }
        }
        
        if (bestLines.size() != 4) {
            return contourCorners;
        }
        
        return contourCorners;
    }
    
    vector<cv::Point> offsetContour(vector<cv::Point> contour, cv::Point offset, bool subtract = false) {
        // add a coordinate to each of the individual coordinates in the contour
        
        vector<cv::Point> resultVector;
        int multiplier = subtract ? -1 : 1;
        
        for (cv::Point pt : contour) {
            cv::Point offsetPoint;
            offsetPoint.x = pt.x + (offset.x * multiplier);
            offsetPoint.y = pt.y + (offset.y * multiplier);
            resultVector.push_back(offsetPoint);
        }
        
        return resultVector;
    }
    
    cv::Point computeLineNearReference(cv::Vec2f line, int contourCenterX, int contourCenterY) {
        int rho = line[0];
        double theta = line[1];

        double cosTheta = cos(theta);
        double sinTheta = sin(theta);
        double x = cosTheta * rho;
        double y = sinTheta * rho;
        
        cv::Point pointNearReference;   // -1 represents None
        
        if (abs(cosTheta) < 1e-6) {
            pointNearReference.x = -1;
            pointNearReference.y = y;
        } else if (abs(sinTheta) < 1e-6) {
            pointNearReference.x = x;
            pointNearReference.y = -1;
        } else {
            pointNearReference.x = x + (y - contourCenterY) * sinTheta / cosTheta;
            pointNearReference.y = y + (x - contourCenterX) * cosTheta / sinTheta;
        }
        
        return pointNearReference;
    }
    
    bool isClose(vector<cv::Vec4f> bestLines, cv::Vec2f candidateLine, cv::Point coordinateNearReference, int distanceThreshold, double thetaThreshold) {
        //int candidateRho = candidateLine[0];      //was never actually used
        double candidateTheta = candidateLine[1];
        
        for (cv::Vec4f line : bestLines) {
            vector<double> deltaDistances;
            
            if (coordinateNearReference.x != -1 and line[2] != -1) {
                deltaDistances.push_back(abs(coordinateNearReference.x - line[2]));
            }
            if (coordinateNearReference.y != -1 and line[3] != -1) {
                deltaDistances.push_back(abs(coordinateNearReference.y - line[3]));
            }
            if (deltaDistances.empty()) {
                return false;
            }
            
            double deltaDistance = *min_element(deltaDistances.begin(), deltaDistances.end());
            
            double deltaTheta = candidateTheta - line[1];
            
            while (deltaTheta >= M_PI / 2) {
                deltaTheta -= M_PI;
            }
            while (deltaTheta <= -M_PI / 2) {
                deltaTheta += M_PI;
            }
            
            deltaTheta = abs(deltaTheta);
            
            if (deltaDistance <= distanceThreshold and deltaTheta <= thetaThreshold) {
                return true;
            }
        }
        
        return false;
    }
    
    vector<cv::Point> getCornersUsingExtremePoints(vector<cv::Point> contour) {
        vector<cv::Point> ret;
        return ret;
    }
};
