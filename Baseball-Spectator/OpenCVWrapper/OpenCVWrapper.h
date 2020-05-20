//
//  OpenCVWrapper.h
//  Baseball-Spectator
//
//  Created by Joey Cohen on 1/7/20.
//  Copyright © 2020 Joey Cohen. All rights reserved.
//

#import "OpenCVWrapper.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (NSString *)openCVVersionString;
+ (UIImage *)processImage:(UIImage *)image expectedHomePlateAngle:(double)expectedHomePlateAngle;

@end

NS_ASSUME_NONNULL_END
