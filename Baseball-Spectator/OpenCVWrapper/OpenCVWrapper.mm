//
//  OpenCVWrapper.mm
//  Baseball-Spectator
//
//  Created by David Gerard on 1/7/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "OpenCVWrapper.h"
#import <opencv2/imgcodecs/ios.h>
#import <UIKit/UIKit.h>

#import "ImageProcessor.mm"

#include <cmath>

using namespace std;

@implementation OpenCVWrapper

+ (UIImage *)processImage:(UIImage *)image expectedHomePlateAngle:(double)expectedHomePlateAngle {
    ImageProcessor processor = ImageProcessor();
    UIImage* output = processor.processImage(image, expectedHomePlateAngle);
    
    /*int nRepeats = 1000;  //use this code to get an average processing time over n repeats
    UIImage* output;
    int total = 0;
    
    for (int i = 0; i < nRepeats; i++) {
        output = processor.processImage(image, expectedHomePlateAngle);
        timer.stop();
        total += timer.elapsedMilliseconds();
    }
    
    total /= nRepeats;
    
    cout << "Processing took " << total << " milliseconds on average after " << nRepeats << " repeats." << endl;*/
    
    return output;
}

@end
