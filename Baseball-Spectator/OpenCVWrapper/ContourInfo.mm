//
//  ContourInfo.mm
//  Baseball-Spectator
//
//  Created by David Gerard on 5/23/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <UIKit/UIKit.h>

using namespace std;

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
