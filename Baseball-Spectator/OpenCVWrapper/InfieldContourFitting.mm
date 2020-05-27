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
    vector<cv::Vec4f> quadrilateralHoughFit(ContourInfo contourInfo) {
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
        
        /*if (lines.empty() or lines.size() < 4) {
            // the quadrilateral fit failed, so try again using the extreme points
            return getCornersUsingExtremePoints(contourInfo.contour);
        }*/
        
        // now that we have a sufficient number of hough lines, pick the four best representative of the contour's four sides and find the intersection between those lines to get the four corners
        vector<cv::Vec4f> result = getCornersUsingHoughLines(lines, contourInfo.width, contourInfo.height);
        
        cv::Vec4f off;
        off[0] = offset.x;
        off[1] = offset.y;
        result.push_back(off);
        
        return result;
        /*
        cout << result << "\n";
        
        // if getting the corners using hough lines failed, try again using extreme points of the contour
        // TODO: find a better method than extreme points or make getCornersUsingHoughLines() more reliable
        if (result.empty() or result.size() != 4) {
            cout << "failed, trying extrema" << "\n";
            vector<cv::Point> ret = getCornersUsingExtremePoints(contourInfo.contour);
            cout << ret << "\n\n";
            return ret;
        } else {
            cout << "worked!" << "\n\n";
            return result;          //TODO: offset these points!!!
        }*/
    }
    
    vector<cv::Vec4f> getCornersUsingHoughLines(vector<cv::Vec2f> houghLines, int width, int height) {
        vector<cv::Point> emptyContourCorners;  // return this empty vector to indicate failure
        
        int centerX = width / 2;
        int centerY = height / 2;
        
        vector<int> boundaries;        // defines the boundaries by which each of the eventual corners should be inside
        boundaries.push_back(-100);
        boundaries.push_back(width + 100);
        boundaries.push_back(-100);
        boundaries.push_back(height + 100);
        
        int distanceThreshold = 10;
        double thetaThreshold = M_PI / 12;
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
            
            cout << "line: " << lineCopy << "\n";
            
            cv::Vec2f coordinateNearReference = computeLineNearReference(lineCopy, centerX, centerY);
            
            cout << "  coordNearRef: " << coordinateNearReference << "\n";
            
            if (bestLines.empty() or bestLines.size() == 0 or !isClose(bestLines, lineCopy, coordinateNearReference, distanceThreshold, thetaThreshold)) {
                cv::Vec4f goodLine;
                goodLine[0] = lineCopy[0];
                goodLine[1] = lineCopy[1];
                goodLine[2] = coordinateNearReference[0];
                goodLine[3] = coordinateNearReference[1];
                bestLines.push_back(goodLine);
                
                cout << "    worked\n";
                
                // stop when we have 4 reference lines (four sides of the quadrilateral)
            }
            
            if (bestLines.size() == 4) {
                break;
            }
        }
        
        cout << "\n";
        
        return bestLines;
        /*
        // if there are not four lines found, the fitting must have failed
        if (bestLines.size() != 4) {
            return emptyContourCorners;
        }
        
        vector<cv::Point> contourCorners;       // holds the four corners of the contour
        
        int line1Index = 0;         // start at the first line index
        set<int> usedIndices;       // hold all the line indices that have already been used to find successfull intersections
        
        // start with the first index, so move it to used
        usedIndices.insert(line1Index);
        
        // go through each possible combination of the four lines to find the four correct intersections
        while (usedIndices.size() < 4) {        //while we have not found four...
            cout << "index 1: " << line1Index << "\n";
            
            bool found = false;
            
            for (int line2Index = 0; line2Index < 4; line2Index++) {
                cout << "  index 2: " << line2Index << "\n";
                // continue to next iteration if the line2Index is already contained in usedIndices
                if (usedIndices.find(line2Index) != usedIndices.end()) {
                    cout << "    already used\n";
                    continue;
                }
                
                // find the intersection between the two
                cv::Point intersection = getIntersection(bestLines[line1Index], bestLines[line2Index]);
                
                bool passedTest = (intersection.x != -1 and intersection.x >= boundaries[0] and intersection.x <= boundaries[1] and intersection.y >= boundaries[2] and intersection.y <= boundaries[3]);
                cout << "    passed test: " << passedTest << "\n";
                
                
                // if the intersection is poosible and near where we expect it should be, then it is a correct intersection
                if (intersection.x != -1 and intersection.x >= boundaries[0] and intersection.x <= boundaries[1] and intersection.y >= boundaries[2] and intersection.y <= boundaries[3]) {
                    contourCorners.push_back(intersection);    // add the intersection to the list of contour corners
                    usedIndices.insert(line2Index);
                    line1Index = line2Index;
                    found = true;
                    cout << "\t- found inter\n";
                    break;
                }
            }
            
            if (!found) {
                return emptyContourCorners;
            }
        }
        
        // still need to add the final intersection since we only have three now
        cv::Point intersection = getIntersection(bestLines[0], bestLines[line1Index]);
        
        // once again make sure there is an intersection and that intersection is within the general area that we expect it to be
        if (intersection.x != -1 and intersection.x >= boundaries[0] and intersection.x <= boundaries[1] and intersection.y >= boundaries[2] and intersection.y <= boundaries[3]) {
            contourCorners.push_back(intersection);    // add the intersection to the list of contour corners
        }
        
        // if there are not four corners in the list, the method failed
        if (contourCorners.size() != 4) {
            return emptyContourCorners;
        }
        
        return contourCorners;*/
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
    
    cv::Vec2f computeLineNearReference(cv::Vec2f line, int contourCenterX, int contourCenterY) {
        int rho = line[0];
        double theta = line[1];

        double cosTheta = cos(theta);
        double sinTheta = sin(theta);
        double x = cosTheta * rho;
        double y = sinTheta * rho;
        
        cv::Vec2f pointNearReference;   // -1 represents None
        
        if (abs(cosTheta) < 1e-6) {
            pointNearReference[0] = -1;
            pointNearReference[1] = y;
        } else if (abs(sinTheta) < 1e-6) {
            pointNearReference[0] = x;
            pointNearReference[1] = -1;
        } else {
            pointNearReference[0] = x + (y - contourCenterY) * sinTheta / cosTheta;
            pointNearReference[1] = y + (x - contourCenterX) * cosTheta / sinTheta;
        }
        
        return pointNearReference;
    }
    
    bool isClose(vector<cv::Vec4f> bestLines, cv::Vec2f candidateLine, cv::Vec2f coordinateNearReference, int distanceThreshold, double thetaThreshold) {
        //int candidateRho = candidateLine[0];      //was never actually used
        double candidateTheta = candidateLine[1];
        
        for (cv::Vec4f line : bestLines) {
            vector<double> deltaDistances;
            
            if (coordinateNearReference[0] != -1 and line[2] != -1) {
                deltaDistances.push_back(abs(coordinateNearReference[0] - line[2]));
            }
            if (coordinateNearReference[1] != -1 and line[3] != -1) {
                deltaDistances.push_back(abs(coordinateNearReference[1] - line[3]));
            }
            if (deltaDistances.empty()) {
                return true;
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
    
    cv::Point getIntersection(cv::Vec4f line1, cv::Vec4f line2) {
        // find the intersection between two lines in Hesse normal form
        // ignore the last 2 elements from each line, they are left over from before and are not longer needed
        
        cv::Point intersection;
        intersection.x = -1;       //indicates that finding the intersection failed
        intersection.y = -1;
        
        int rho1 = line1[0];
        double theta1 = line1[1];
        int rho2 = line2[0];
        double theta2 = line2[1];
        
        if (abs(theta1 - theta2) < 1e-6) {
            return intersection;
        }
        
        double cos1 = cos(theta1);
        double sin1 = sin(theta1);
        double cos2 = cos(theta2);
        double sin2 = sin(theta2);
        
        double denom = (cos1 * sin2) - (sin1 * cos2);
        intersection.x = ((sin2 * rho1) - (sin1 * rho2)) / denom;
        intersection.y = ((cos1 * rho2) - (cos2 * rho1)) / denom;
        
        return intersection;
    }
    
    vector<cv::Point> getCornersUsingExtremePoints(vector<cv::Point> contour) {
        int minY = -1;
        cv::Point minYPoint;
        int maxY = -1;
        cv::Point maxYPoint;
        
        for (cv::Point point : contour) {           // find the lowest and highest points in the contour
            if (minY == -1 or point.y < minY) {
                minYPoint = point;
                minY = point.y;
            }
            if (maxY == -1 or point.y > maxY) {
                maxYPoint = point;
                maxY = point.y;
            }
        }
                
        int height = maxYPoint.y - minYPoint.y;
        
        vector<cv::Point> extremePoints;        // order will be: top left, top right, bottom right, bottom left
        extremePoints.push_back(maxYPoint);
        extremePoints.push_back(maxYPoint);
        extremePoints.push_back(minYPoint);
        extremePoints.push_back(minYPoint);
        
        int dyTop = int(height / 5.5);           // for image7: 10
        int dyBottom = int(height / 2.75);       // for image7: 20
        
        for (cv::Point pt : contour) {           // corrections if possible (carefull: pt is in shape of [[0, 0]])
            if (maxY - dyBottom < pt.y and maxY + dyBottom > pt.y) {
                if (pt.x < extremePoints[0].x) { // top left
                    extremePoints[0] = pt;
                }
                if (pt.x > extremePoints[1].x) { // top right
                    extremePoints[1] = pt;
                }
            }
            if (minY - dyTop < pt.y and minY + dyTop > pt.y) {
                if (pt.x > extremePoints[2].x) {  // bottom right
                    extremePoints[2] = pt;
                }
                if (pt.x < extremePoints[3].x) {  // bottom left
                    extremePoints[3] = pt;
                }
            }
        }
        
        return extremePoints;
    }
};
