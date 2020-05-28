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

using namespace std;

//Class to run the image processing
class ImageProcessor {
    public:
    cv::Scalar lowerGreen, upperGreen, lowerBrown, upperBrown, lowerDarkBrown, upperDarkBrown;
    Timer timer;
    
    ImageProcessor() {
        lowerGreen = cv::Scalar(17, 50, 20);
        upperGreen = cv::Scalar(72, 255, 242);
        
        lowerBrown = cv::Scalar(7, 80, 25);
        upperBrown = cv::Scalar(27, 255, 255);
        
        lowerDarkBrown = cv::Scalar(2, 93, 25);
        upperDarkBrown = cv::Scalar(10, 175, 150);
    }
    
    public: UIImage* processImage(UIImage* image, double expectedHomePlateAngle) {
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
            return image;
        }
        
        cv::Mat mat, resizedMat, hsv, greenMask, brownMask, darkBrownMask, fieldMask, erosion;
        
        UIImageToMat(image, mat);
        
        // Resize sample images to consistent height of 1080
        // TODO: Remove this after algorithm testing is complete
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
        
        // Get the location of the standard position of each of the fielders
        vector<cv::Point> expectedPositions = getPositionLocations(greenMask, expectedHomePlateAngle);
        
        if (expectedPositions.empty()) { return image; }    //TODO:  or expectedPositions.size() != 9
        
        // Get the location of each of the actual players on the field
        vector<vector<cv::Point>> playerContours = getPlayerContourLocations(fieldMask);
        
        if (playerContours.empty() or playerContours.size() == 0) { return image; }
        
        // resizedMat wasn't in correct format before, so change it to RGB here for in-color drawing
        cv::cvtColor(hsv, resizedMat, cv::COLOR_HSV2RGB);
        
        // Draw contours on image for DEBUG
        playerContours.push_back(expectedPositions);
        cv::drawContours(resizedMat, playerContours, -1, cv::Scalar(255, 0, 0), 3);
        
        /*int b = 0;
        int add = int(255 / expectedPositions.size());     // change the color to differentiate the bases
        for (cv::Point pt : expectedPositions) {
            cv::circle(resizedMat, pt, 15, cv::Scalar(0, 0, b), cv::FILLED);
            b += add;
        }*/
        
        //map<string, vector<cv::Point>> playersByPosition = getPlayersByPosition(playerContours, expectedPositions);
        
        /*for ( const auto &p : playersByPosition ) {
           cout << p.first << '\t' << p.second << "\n";
        }*/
        
        // Convert the Mat image to a UIImage
        UIImage *result = MatToUIImage(resizedMat);
        
        timer.stop();
        //cout << "Processing took " << timer.elapsedMilliseconds() << " milliseconds\n";

        return result;
    }
    
    private:
    vector<cv::Point> getPositionLocations(cv::Mat greenMask, double expectedHomePlateAngle) {
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
        
        ContourInfo infield = ContourInfo();
        infield.x = -1;
        
        for (ContourInfo cnt : infieldContours) {
            double ratio = cnt.height / cnt.width;
            
            if (ratio < 0.4 and (infield.x == -1 or cnt.width < infield.width) and cv::contourArea(cnt.contour) > 10000) {
                infield = cnt;
            }
        }
        
        if (infield.x == -1) { return failedVec; }       //TODO: indicate the infield was not found
        
        // use the hull of the infield instead of the original infield contour
        vector<cv::Point> infieldHull;
        cv::convexHull(infield.contour, infieldHull);
        infield.contour = infieldHull;
        
        InfieldContourFitting fit = InfieldContourFitting();
        vector<cv::Point> infieldCorners = fit.quadrilateralHoughFit(infield);
        
        if (infieldCorners.empty() or infieldCorners.size() == 0) {
            return failedVec;
        }
        
        return infieldCorners;
        
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
        ContourInfo field = ContourInfo();
        field.x = -1;                           // indicates that the variable is empty
        
        for (vector<cv::Point> c : contours) {
            cv::Rect rect = cv::boundingRect(c);
            double area = rect.height * rect.width;
            
            if (area > 270 and area < 2000) {
                ContourInfo cnt;
                cnt.contour = c;
                cnt.x = rect.x;
                cnt.y = rect.y;
                cnt.width = rect.width;
                cnt.height = rect.height;
                playerContours.push_back(cnt);
            } else if (field.x == -1 or (field.width * field.height) < area) {
                field.contour = c;
                field.x = rect.x;
                field.y = rect.y;
                field.width = rect.width;
                field.height = rect.height;
            }
        }
                
        vector<vector<cv::Point>> players;
        
        if (field.x == -1) { return players; }
        
        vector<ContourInfo> topPlayers;
        
        for (ContourInfo cnt : playerContours) {
            double ratio = cnt.height / cnt.width;
            
            if (ratio > 0.8 and ratio < 3.0) {
                topPlayers.push_back(cnt);
            }
        }
                
        if (topPlayers.size() == 0) { return players; }

        for (ContourInfo cnt : topPlayers) {
            if (isCandidatePlayerOnField(cnt, field)) {
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
    
    map<string, vector<cv::Point>> getPlayersByPosition(vector<vector<cv::Point>> playerContours, vector<cv::Point> expectedPositions) {
        map<string, vector<cv::Point>> playersByPosition;
        vector<cv::Point> emptyVec;
        
        // populate the map with the position keys
        playersByPosition["pitcher"] = emptyVec;
        playersByPosition["catcher"] = emptyVec;
        playersByPosition["first"] = emptyVec;
        playersByPosition["second"] = emptyVec;
        playersByPosition["shortstop"] = emptyVec;
        playersByPosition["third"] = emptyVec;
        playersByPosition["leftfield"] = emptyVec;
        playersByPosition["centerfield"] = emptyVec;
        playersByPosition["rightfield"] = emptyVec;
                
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
            
            switch (closestPositionIndex) {
                case 0: playersByPosition["pitcher"].push_back(lowestPoint);
                    break;
                case 1: playersByPosition["catcher"].push_back(lowestPoint);
                    break;
                case 2: playersByPosition["first"].push_back(lowestPoint);
                    break;
                case 3: playersByPosition["second"].push_back(lowestPoint);
                    break;
                case 4: playersByPosition["shortstop"].push_back(lowestPoint);
                    break;
                case 5: playersByPosition["third"].push_back(lowestPoint);
                    break;
                case 6: playersByPosition["leftfield"].push_back(lowestPoint);
                    break;
                case 7: playersByPosition["rightfield"].push_back(lowestPoint);
                    break;
                case 8: playersByPosition["centerfield"].push_back(lowestPoint);
                    break;
            }
        }
        return playersByPosition;
    }
    
    static bool sortByYCoordinate(cv::Point &struct1, cv::Point &struct2) {
        return struct1.y > struct2.y;
    }
    
    int getDistBetweenPoints(cv::Point pt1, cv::Point pt2) {
        return sqrt( pow((pt1.x - pt2.x), 2) + pow((pt1.y - pt2.y), 2) );
    }
};
