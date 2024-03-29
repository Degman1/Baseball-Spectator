//
//  ImageProcessor.mm
//  Baseball-Spectator
//
//  Created by David Gerard on 5/23/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <UIKit/UIKit.h>

#import "ContourInfo.mm"
#import "Timer.mm"
#import "InfieldContourFitting.mm"

#include <fstream>

using namespace std;

//Class to run the image processing
class ImageProcessor {
    public:
    cv::Scalar lowerGreen, upperGreen, lowerBrown, upperBrown, lowerDarkBrown, upperDarkBrown;
    Timer timer;
    
    private:
    ContourInfo wholeField = ContourInfo();
    
    public:
    ImageProcessor() {
        lowerGreen = cv::Scalar(17, 50, 20);
        upperGreen = cv::Scalar(72, 255, 242);
        
        lowerBrown = cv::Scalar(7, 80, 25);
        upperBrown = cv::Scalar(27, 255, 255);
        
        lowerDarkBrown = cv::Scalar(2, 93, 25);
        upperDarkBrown = cv::Scalar(10, 175, 150);
    }
    
    public: UIImage* processImage(UIImage* image, double expectedHomePlateAngle, string filePath, int processingState) {
        /*
         Main image processing routine
        
            1. Reset all central class variables to make sure the last image's processing data is cleared out
            2. Convert color from BGR to HSV
            3. Find all the pixels in the image that are a specific shade of green or brown to identify the field and dirt
            4. Find the location of the bases
            5. Find the location of the players
            6. Calculate the ideal location of each of the players' positions
            7. Assign each player an expected position
            8. RETURN each players' bottom point and their corresponding position
        */
        
        if (expectedHomePlateAngle >= 360 or expectedHomePlateAngle <= -360) {     //no homePlateAngle is provided, so no point in going through processing
            ofstream file;
            file.open(filePath);
            file << "bad angle";     // clears the contents of the file
            file.close();
            return image;
        }
        
        cv::Mat mat, resizedMat, hsv, greenMask, brownMask, darkBrownMask, fieldMask, erosion;
        
        UIImageToMat(image, mat);
        
        // Resize sample images to consistent height of 1080
        // TODO: Remove this after algorithm testing is complete and change static cuts to be dynamic based on the image size
        int newHeight = 1080;
        double scalePercent = newHeight / image.size.height;
        int width = int(image.size.width * scalePercent);
        cv::resize(mat, resizedMat, cv::Size(width, newHeight), 0, 0, cv::INTER_AREA);
        
        timer.start();      //NOTE: Start timer here because the image scaling takes a long time and won't be performed in the final product
        
        // Convert to HSV colorspace
        cv::cvtColor(resizedMat, hsv, cv::COLOR_RGB2HSV);
        
        // Green mask
        cv::inRange(hsv, lowerGreen, cv::Scalar(72, 255, 242), greenMask);

        // Brown Mask
        cv::inRange(hsv, cv::Scalar(7, 80, 25), cv::Scalar(27, 255, 255), brownMask);
        
        // Dark Brown Mask
        cv::inRange(hsv, cv::Scalar(2, 93, 25), cv::Scalar(10, 175, 150), darkBrownMask);
        
        // Combine each mask to get a mask of the entire playing field
        cv::bitwise_or(greenMask, brownMask, fieldMask);
        cv::bitwise_or(fieldMask, darkBrownMask, fieldMask);
        
        // resizedMat wasn't in correct format before, so change it to RGB here for in-color drawing
        cv::cvtColor(hsv, resizedMat, cv::COLOR_HSV2RGB);
        
        // do this first so that wholeInfield is set
        // Get the location of each of the actual players on the field
        vector<vector<cv::Point>> playerContours = getPlayerContourLocations(fieldMask);
        
        if (playerContours.empty() or playerContours.size() == 0) {
            ofstream file;
            file.open(filePath);
            file << "no players detected";
            file.close();
            return image;
        }
        
        // Get the location of the standard position of each of the fielders
        vector<cv::Point> expectedPositions = getPositionLocations(greenMask, expectedHomePlateAngle, processingState);
        
        if (expectedPositions.size() == 5) {
            // draw a circle over home, first, second, and third
            
            for (int i = 0; i < 4; i++) {
                // white outside
                cv::circle(resizedMat, expectedPositions[i], 25, cv::Scalar(255, 255, 255), cv::FILLED);
                // dark green inside
                cv::circle(resizedMat, expectedPositions[i], 15, cv::Scalar(94, 138, 100), cv::FILLED);
            }
            
            writeBasesToFile(expectedPositions, filePath);
            
            UIImage *result = MatToUIImage(resizedMat);
            return result;
        } else if (expectedPositions.empty() or expectedPositions.size() != 9) {
            ofstream file;
            file.open(filePath);
            file << "no infield detected";
            file.close();
            UIImage *result = MatToUIImage(resizedMat);
            return result;
        }
        
        // draw only home plate
        // white outside
        cv::circle(resizedMat, expectedPositions[1], 25, cv::Scalar(255, 255, 255), cv::FILLED);
        // dark green inside
        cv::circle(resizedMat, expectedPositions[1], 15, cv::Scalar(94, 138, 100), cv::FILLED);
        
        // Draw contours on image
        cv::drawContours(resizedMat, playerContours, -1, cv::Scalar(255, 0, 0), 5);
        
        // Draw expected positions on image for DEBUG
        //int b = 0;
        //int add = int(255 / expectedPositions.size());     // change the color to differentiate the bases
        //for (cv::Point pt : expectedPositions) {
        //    cv::circle(resizedMat, pt, 15, cv::Scalar(0, 0, b), cv::FILLED);
        //    b += add;
        //}
        
        // calculate which players are closest to which positions
        vector<vector<cv::Point>> playersByPosition = getPlayersByPosition(playerContours, expectedPositions);
        
        // print out playersByPosition for debugging
        //for ( const auto &p : playersByPosition ) {
        //   cout << p.first << '\t' << p.second << "\n";
        //}
        
        // write the resulting data to a file to be read by the swift app code
        writePlayersByPositionToFile(playersByPosition, filePath);
        
        // Convert the Mat image to a UIImage (will be the image displayed on the main screen of the app)
        UIImage *result = MatToUIImage(resizedMat);
        
        timer.stop();
        //cout << "Processing took " << timer.elapsedMilliseconds() << " milliseconds\n";
        
        return result;
    }
    
    private:
    vector<cv::Point> getPositionLocations(cv::Mat greenMask, double expectedHomePlateAngle, int processingState) {
        /*
         Sub-processing routine to find the location of each of the game positions

            1. Erode the image to get rid of small impurities
            2. Find all contours that are formed by the green mask
            3. Choose the contours that are between a certain bounding box area
            4. Choose the contours that have a certain (height/width) ratio, the smallest bounding box width, and an exact area above a certain threshold
                    --> the expected infield outline
            5. Fit a quadrilateral around the infield grass
            6. Compute ideal position locations based on the infield corners
            7. RETURN the image locations corresponding the positions in the following order:
                    (pitcher, home, first, second, third, shortstop, left field, center field, right field)
        */
        
        cv::Mat erosion;
        
        vector<cv::Point> failedVec;
        
        // Erode the image to remove impurities
        cv::erode(greenMask, erosion, getStructuringElement(cv::MORPH_RECT, cv::Size(5, 4)));
        
        // Find all contours in the image
        vector<vector<cv::Point>> contours;     // contains the array of contours
        vector<cv::Vec4i> hierarchy;            // don't actually use this
        cv::findContours(erosion, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);
                
        // Only keep the contours which have a certain bounding box area
        vector<ContourInfo> infieldContours;
        
        for (vector<cv::Point> c : contours) {
            cv::Rect rect = cv::boundingRect(c);
            double area = rect.height * rect.width;
            
            if (area > 18500 and area < 2000000) {
                ContourInfo cnt;
                cnt.contour = c;
                cnt.x = rect.x;
                cnt.y = rect.y;
                cnt.width = rect.width;
                cnt.height = rect.height;
                infieldContours.push_back(cnt);
            }
        }
        
        // Sort the list of contours from biggest area to smallest
        sort(infieldContours.begin(), infieldContours.end(), sortByArea);
        
        vector<ContourInfo> infieldShapedContours;
        
        for (ContourInfo cnt : infieldContours) {
            double ratio = cnt.height / cnt.width;
            double area = cv::contourArea(cnt.contour);
            double bbArea = cnt.getBoundingBoxArea();
            
            if (ratio < 0.4 && ratio > 0.08 && area > 10000 && area < 270000 && area / bbArea > 0.5) {
                infieldShapedContours.push_back(cnt);
            }
        }
        
        ContourInfo infield = infieldContourEdgeCut(infieldShapedContours);
        
        if (infield.x == -1) { return failedVec; }
        
        // use the hull of the infield instead of the original infield contour
        vector<cv::Point> infieldHull;
        cv::convexHull(infield.contour, infieldHull);
        infield.contour = infieldHull;
        
        InfieldContourFitting fit = InfieldContourFitting();
        vector<cv::Point> infieldCorners = fit.quadrilateralHoughFit(infield);
        
        if (infieldCorners.empty() or infieldCorners.size() == 0) {
            return failedVec;
        }
        
        if (processingState == 0) {
            infieldCorners.push_back(getAveragePoint(infieldCorners));
            return infieldCorners;
        }
        
        vector<cv::Point> bases = putBasesInOrder(infieldCorners, expectedHomePlateAngle);      // get the bases in order of pitcher, home, first, second, third
        
        vector<cv::Point> expectedPositions = calculateExpectedPositions(bases[1], bases[2], bases[3], bases[4]);
        expectedPositions.insert(expectedPositions.begin(), bases[0]);
        
        return expectedPositions;
    }
    
    static bool sortByArea(ContourInfo &struct1, ContourInfo &struct2) {
        return ((struct1.width * struct1.height) > (struct2.width * struct2.height));
    }
    
    private: vector<vector<cv::Point>> getPlayerContourLocations(cv::Mat fieldMask) {
        /*
         Sub-processing routine to find the location of the players on the field

            1. Erode the image to get rid of small impurities
            2. Find all contours that are formed by the green and brown masks
            3. Choose the contours that are between a certain bounding box area
            4. Choose the contours that have a certain (height/width) ratio and actually are located on the field
            5. RETURN an array of the players' center pixel location
         */
        
        cv::Mat erosion;
        
        // Erode the image to remove impurities
        cv::erode(fieldMask, erosion, getStructuringElement(cv::MORPH_RECT, cv::Size(5, 5)));
        
        // Find all contours in the image
        vector<vector<cv::Point>> contours;     // contains the array of contours
        vector<cv::Vec4i> hierarchy;            // don't actually use this
        cv::findContours(erosion, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);
        
        // Only keep the contours which have a certain bounding box area
        vector<ContourInfo> playerContours;
        wholeField = ContourInfo();
        wholeField.x = -1;                           // indicates that the variable is empty
        
        for (vector<cv::Point> c : contours) {
            cv::Rect rect = cv::boundingRect(c);
            double area = rect.height * rect.width;
            
            if (area > 270 and area < 8000) {       //TODO: make these numbers dependant on the infield size
                ContourInfo cnt;
                cnt.contour = c;
                cnt.x = rect.x;
                cnt.y = rect.y;
                cnt.width = rect.width;
                cnt.height = rect.height;
                playerContours.push_back(cnt);
            } else if (wholeField.x == -1 or (wholeField.width * wholeField.height) < area) {
                wholeField.contour = c;
                wholeField.x = rect.x;
                wholeField.y = rect.y;
                wholeField.width = rect.width;
                wholeField.height = rect.height;
            }
        }
                
        vector<vector<cv::Point>> players;
        
        if (wholeField.x == -1) { return players; }
        
        vector<ContourInfo> topPlayers;
        
        for (ContourInfo cnt : playerContours) {
            double ratio = cnt.height / cnt.width;
            
            if (ratio > 0.8 and ratio < 3.0) {
                topPlayers.push_back(cnt);
            }
        }
                
        if (topPlayers.size() == 0) { return players; }

        for (ContourInfo cnt : topPlayers) {
            if (isCandidatePlayerOnField(cnt, wholeField)) {
                players.push_back(cnt.contour);
            }
        }
        
        return players;
    }
    
    private: bool isCandidatePlayerOnField(ContourInfo cnt, ContourInfo field) {
        /*
         Helper method to check if a candidate player is located on the field

             1. Check if the candidate player's center point is within the field's bounding box
                 (much faster than the opencv method, so if it isn't in the bounding box it's a quick reliable way to return false)
             2. Check if the center point is actually inside the field contour
             3. RETURN true if the result is positive
         */
        
        int fieldWidth = int(field.width / 2);
        int fieldHeight = int(field.height / 2);
        
        int centerX = field.x + (field.width / 2);
        int centerY = field.y + (field.height / 2);
        
        if (cnt.x >= centerX + fieldWidth or cnt.x <= centerX - fieldWidth or
            cnt.y >= centerY + fieldHeight or centerY <= centerY - fieldHeight) {
            return false;
        }
                
        double distance = cv::pointPolygonTest(field.contour, cv::Point(cnt.x, cnt.y), true);
        
        return distance >= 0.0;
    }
    
    vector<cv::Point> putBasesInOrder(vector<cv::Point> unorderedBases, int expectedHomePlateAngle) {
        vector<cv::Point> failedVec;
        
        cv::Point pitcher;
        pitcher.x = (unorderedBases[0].x + unorderedBases[1].x + unorderedBases[2].x + unorderedBases[3].x) / 4;
        pitcher.y = (unorderedBases[0].y + unorderedBases[1].y + unorderedBases[2].y + unorderedBases[3].y) / 4;
        
        int da = 361;               // delta angle starting value
        int homePlateIndex = -1;
        
        for (int i = 0; i < unorderedBases.size(); i++) {
            int x = unorderedBases[i].x - pitcher.x;
            int y = pitcher.y - unorderedBases[i].y;           // flip because y goes up as the pixel location goes down
            float angle = atan2(y, x) * (180 / M_PI);
            
            float daTest = abs(angle - expectedHomePlateAngle);   //TODO: use the device's gyroscope to adjust the expected angle based on the device's rotation
            
            if (daTest < da) {
                da = daTest;
                homePlateIndex = i;
            }
        }
        
        if (homePlateIndex == -1) {
            return failedVec;
        }
        
        cv::Point homePlate = unorderedBases[homePlateIndex];
        cv::Point secondBase = unorderedBases[(homePlateIndex + 2) % 4];      // can do this since the corners are in order, either clockwise or counter-clockwise
        
        // Find which is first base and which is third base:
        int testBaseIndex = (homePlateIndex + 1) % 4;
        int x = unorderedBases[testBaseIndex].x - pitcher.x;
        int y = pitcher.y - unorderedBases[testBaseIndex].y;
        double angle = atan2(y, x) * (180 / M_PI);

        if (angle < 0) {
            angle += 360;
        }
        if (expectedHomePlateAngle < 0) {
            expectedHomePlateAngle += 360;
        }
        
        cv::Point firstBase, thirdBase;
        
        // first base must be the next base if moving in a counter-clockwise direction in relation to the pitcher's mound
        if ((angle > expectedHomePlateAngle and angle < expectedHomePlateAngle + 180)  or (angle + 360 > expectedHomePlateAngle and angle + 360 < expectedHomePlateAngle + 180)) {
            firstBase = unorderedBases[(homePlateIndex + 1) % 4];
            thirdBase = unorderedBases[(homePlateIndex + 3) % 4];
        } else {
            firstBase = unorderedBases[(homePlateIndex + 3) % 4];
            thirdBase = unorderedBases[(homePlateIndex + 1) % 4];
        }
        
        vector<cv::Point> bases;
        bases.push_back(pitcher);
        bases.push_back(homePlate);
        bases.push_back(firstBase);
        bases.push_back(secondBase);
        bases.push_back(thirdBase);
        
        return bases;
    }
    
    vector<cv::Point> calculateExpectedPositions(cv::Point homePlate, cv::Point firstBase, cv::Point secondBase, cv::Point thirdBase) {
        int homeToFirstDist = getDistBetweenPoints(homePlate, firstBase);
        int firstToSecondDist = getDistBetweenPoints(firstBase, secondBase);
        int secondToThirdDist = getDistBetweenPoints(secondBase, thirdBase);
        int thirdToHomeDist = getDistBetweenPoints(thirdBase, homePlate);
        // TODO: could potentially do more with this since we know each of these in real life should be around 90 ft
        
        int side1 = (homeToFirstDist + secondToThirdDist) / 2;   // average the two sides of the infield out to get a more consistent elevation multiplier
        int side2 = (firstToSecondDist + thirdToHomeDist) / 2;   // represents side1 and side2 of a parallelogram fitted around the infield grass
        
        float distRatio = side1 / side2;
        
        vector<cv::Vec3f> sortedBases;
        sortedBases.push_back(addBaseID(homePlate, 0));
        sortedBases.push_back(addBaseID(firstBase, 1));
        sortedBases.push_back(addBaseID(secondBase, 2));
        sortedBases.push_back(addBaseID(thirdBase, 3));
        
        // sort the list by the highest y coordinate (lowest in image) to find which base the user is closest to
        sort(sortedBases.begin(), sortedBases.end(), sortBySecondVectorIndex);
        
        // TODO: when able to get a real image test set, revise these values and change them base on the distance ratio as set up below
        
        cv::Point first, second, shortstop, third, leftfield, centerfield, rightfield;
        
        if (sortedBases[0][2] == 2.0 or (sortedBases[0][2] == 1.0 and sortedBases[1][2] == 2.0) or (sortedBases[0][2] == 3.0 and sortedBases[1][2] == 2.0)) {    //If the user is closer towards the outfield than the infield...
            //cout << "Sitting on the outfield side" << "\n";
            
            // use vector operations to calculate expected positions from the coordinates of the bases and the elevation multipliers
            if (distRatio >= 4.0) {        // first to second is smaller, so refine right infield, leftfield, and centerfield (same amount at if <= 0.25)
                first = calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.5);
                second = calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.5);
                shortstop = calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.5);
                third = calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.5);
                leftfield = calculatePosition(homePlate, secondBase, thirdBase, 0.8, 3.0);
                centerfield.x = homePlate.x + (3.0 * (secondBase.x - homePlate.x));
                centerfield.y = homePlate.y + (3.0 * (secondBase.y - homePlate.y));
                rightfield = calculatePosition(homePlate, secondBase, firstBase, 0.7, 3.0);
            } else if (distRatio <= 0.25) {     // home to first is smaller, so refine left infield, rightfield, and centerfield (same as if >= 4.0)
                first = calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.5);
                second = calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.5);
                shortstop = calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.5);
                third = calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.5);
                leftfield = calculatePosition(homePlate, secondBase, thirdBase, 0.8, 3.0);
                centerfield.x = homePlate.x + (3.0 * (secondBase.x - homePlate.x));
                centerfield.y = homePlate.y + (3.0 * (secondBase.y - homePlate.y));
                rightfield = calculatePosition(homePlate, secondBase, firstBase, 0.7, 3.0);
            } else {                       // normal
                first = calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.5);
                second = calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.5);
                shortstop = calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.5);
                third = calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.5);
                leftfield = calculatePosition(homePlate, secondBase, thirdBase, 0.8, 3.0);
                centerfield.x = homePlate.x + (3.0 * (secondBase.x - homePlate.x));
                centerfield.y = homePlate.y + (3.0 * (secondBase.y - homePlate.y));
                rightfield = calculatePosition(homePlate, secondBase, firstBase, 0.7, 3.0);
            }
        } else {       //if the user is closer to the infield...
            //cout << "Sitting on the infield side" << "\n";
            
            if (distRatio >= 4.0) {        // first to second is smaller, so refine right infield, leftfield, and centerfield (same amount at if <= 0.25)
                first = calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.25);
                second = calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.25);
                shortstop = calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.2);
                third = calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.2);
                leftfield = calculatePosition(homePlate, secondBase, thirdBase, 0.6, 1.7);
                centerfield.x = homePlate.x + (1.5 * (secondBase.x - homePlate.x));
                centerfield.y = homePlate.y + (1.5 * (secondBase.y - homePlate.y));
                rightfield = calculatePosition(homePlate, secondBase, firstBase, 0.7, 1.7);
            } else if (distRatio <= 0.25) {     // home to first is smaller, so refine left infield, rightfield, and centerfield (same as if >= 4.0)
                first = calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.25);
                second = calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.25);
                shortstop = calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.2);
                third = calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.2);
                leftfield = calculatePosition(homePlate, secondBase, thirdBase, 0.7, 1.7);
                centerfield.x = homePlate.x + (1.5 * (secondBase.x - homePlate.x));
                centerfield.y = homePlate.y + (1.5 * (secondBase.y - homePlate.y));
                rightfield = calculatePosition(homePlate, secondBase, firstBase, 0.7, 1.7);
            } else {                       // normal
                first = calculatePosition(homePlate, secondBase, firstBase, 0.85, 1.25);
                second = calculatePosition(homePlate, secondBase, firstBase, 0.4, 1.25);
                shortstop = calculatePosition(homePlate, secondBase, thirdBase, 0.4, 1.2);
                third = calculatePosition(homePlate, secondBase, thirdBase, 0.8, 1.2);
                leftfield = calculatePosition(homePlate, secondBase, thirdBase, 0.7, 1.7);
                centerfield.x = homePlate.x + (1.5 * (secondBase.x - homePlate.x));
                centerfield.y = homePlate.y + (1.5 * (secondBase.y - homePlate.y));
                rightfield = calculatePosition(homePlate, secondBase, firstBase, 0.7, 1.7);
            }
        }
        
        vector<cv::Point> expectedPositions;
        expectedPositions.push_back(homePlate);
        expectedPositions.push_back(first);
        expectedPositions.push_back(second);
        expectedPositions.push_back(shortstop);
        expectedPositions.push_back(third);
        expectedPositions.push_back(leftfield);
        expectedPositions.push_back(centerfield);
        expectedPositions.push_back(rightfield);
        
        return expectedPositions;
    }
    
    cv::Point calculatePosition(cv::Point homePlate, cv::Point base1, cv::Point base2, float betweenBaseMultiplier, float distanceToHomeMultiplier) {
        //Calculate the expected postition of a player a certain percent of the way between two bases and a certain percent of the way from home using vector operations
        
        cv::Point translatedPoint;
        translatedPoint.x = (homePlate.x + ((base1.x + (betweenBaseMultiplier * (base2.x - base1.x))) - homePlate.x ) * distanceToHomeMultiplier);
        translatedPoint.y = (homePlate.y + ((base1.y + (betweenBaseMultiplier * (base2.y - base1.y))) - homePlate.y ) * distanceToHomeMultiplier);
        return translatedPoint;
    }
    
    cv::Vec3f addBaseID(cv::Point point, int idNumber) {
        cv::Vec3f vec;
        vec[0] = point.x;
        vec[1] = point.y;
        vec[2] = idNumber;
        return vec;
    }
    
    static bool sortBySecondVectorIndex(cv::Vec3f &struct1, cv::Vec3f &struct2) {
        return struct1[1] > struct2[1];
    }
    
    vector<vector<cv::Point>> getPlayersByPosition(vector<vector<cv::Point>> playerContours, vector<cv::Point> expectedPositions) {
        // finds which players are closest to which position, and returns a vector of the lowest point of the contours with the index of the array indicative of the position number minus one
        // includes the expected positions in the playersByPosition vector
        
        vector<vector<cv::Point>> playersByPosition;    // the players position is indicated by the position's corresponding number minus one
        
        // populate the map with empty vectors
        for (int i = 0; i < 9; i++) {
            vector<cv::Point> vec;
            vec.push_back(expectedPositions[i]);
            playersByPosition.push_back(vec);
        }
        
        for (vector<cv::Point> contour: playerContours) {
            vector<cv::Point> contourCopy = contour;
            sort(contourCopy.begin(), contourCopy.end(), sortByYCoordinate);
            cv::Point lowestPoint = contourCopy[0];
            
            int closestPositionIndex = -1;
            int closestDistance = -1;
                        
            for (int i = 0; i < 9; i++) {
                int dist = getDistBetweenPoints(lowestPoint, expectedPositions[i]);
                
                if (closestPositionIndex == -1 or dist < closestDistance) {
                    closestPositionIndex = i;
                    closestDistance = dist;
                }
            }
            
            playersByPosition[closestPositionIndex].push_back(lowestPoint);
        }
        
        return playersByPosition;
    }
    
    static bool sortByYCoordinate(cv::Point &struct1, cv::Point &struct2) {
        return struct1.y > struct2.y;
    }
    
    int getDistBetweenPoints(cv::Point pt1, cv::Point pt2) {
        return sqrt( pow((pt1.x - pt2.x), 2) + pow((pt1.y - pt2.y), 2) );
    }
    
    void writePlayersByPositionToFile(vector<vector<cv::Point>> playersByPosition, string filePath) {
        ofstream file;
        file.open(filePath);
                
        string contents = "";
        for ( vector<cv::Point> vec : playersByPosition ) {
            string playersOfCertainPosition = "";
            for (cv::Point pt : vec) {
                playersOfCertainPosition += to_string(pt.x);
                playersOfCertainPosition += ",";
                playersOfCertainPosition += to_string(pt.y);
                playersOfCertainPosition += " ";
            }
            contents += playersOfCertainPosition;
            if (playersOfCertainPosition == "") {
                contents += "-";
            }
            contents += "\n";
        }
                
        file << contents;

        file.close();
    }
    
    void writeBasesToFile(vector<cv::Point> bases, string filePath) {
        ofstream file;
        file.open(filePath);
        string contents = to_string(bases[0].x) + "," + to_string(bases[0].y) + "\n";
        contents += to_string(bases[1].x) + "," + to_string(bases[1].y) + "\n";
        contents += to_string(bases[2].x) + "," + to_string(bases[2].y) + "\n";
        contents += to_string(bases[3].x) + "," + to_string(bases[3].y) + "\n";
        contents += to_string(bases[4].x) + "," + to_string(bases[4].y) + "\n";
        
        file << contents;
        
        file.close();
    }
    
    cv::Point getAveragePoint(vector<cv::Point> points) {
        int aveX = 0;
        int aveY = 0;
        
        for (cv::Point point : points) {
            aveX += point.x;
            aveY += point.y;
        }
        
        cv::Point avePoint;
        avePoint.x = aveX / points.size();
        avePoint.y = aveY / points.size();
        
        return avePoint;
    }
    
    float getNumOfPointsOnEdgeOfField(ContourInfo cnt) {
        //vector<cv::Point> closeWholeField;  // contains the points of the whole field contour that are in the cnt's bounding box
        int n = 0;
        
        for (cv::Point pt : wholeField.contour) {
            if (pt.x >= cnt.x && pt.x <= cnt.x + cnt.width && pt.y >= cnt.y && pt.y <= cnt.y + cnt.height) {
                n += 1;
            }
        }
        
        return n;
    }
    
    ContourInfo infieldContourEdgeCut(vector<ContourInfo> infieldShapedContours) {
        // return the infield that has the least number of points touching the edge of the field
        
        vector<ContourInfo> infields;   // used to check if multiple infields have no touching points
        ContourInfo infield;
        infield.x = -1;
        
        if (infieldShapedContours.empty() || infieldShapedContours.size() == 0) {
            return infield;
        }
        
        infield = infieldShapedContours[0];
        int lowN = -1;
        
        for (ContourInfo cnt : infieldShapedContours) {
            int n = getNumOfPointsOnEdgeOfField(cnt);
            //cout << cnt.y << ": " << n << "\n";
            if (lowN == -1 || n < lowN) {
                lowN = n;
                infield = cnt;
            }
            if (n == 0) {
                infields.push_back(cnt);
            }
        }
        //cout << " -- " << lowN;
        //cout << "\n";
        
        if (infields.size() > 1) {
            sort(infields.begin(), infields.end(), sortByArea);
            return infields[infields.size() - 1];
        }
        
        return infield;         // no infield found is identified by infield.x == -1
    }
};
