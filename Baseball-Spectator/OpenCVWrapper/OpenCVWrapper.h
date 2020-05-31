//
//  OpenCVWrapper.h
//  Baseball-Spectator
//
//  Created by David Gerard on 1/7/20.
//  Copyright © 2020 David Gerard. All rights reserved.
//

#import "OpenCVWrapper.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (UIImage *)processImage:(UIImage *)image expectedHomePlateAngle:(double)expectedHomePlateAngle filePath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
