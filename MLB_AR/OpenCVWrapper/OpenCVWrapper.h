//
//  OpenCVWrapper.h
//  OpenCVTest
//
//  Created by David Gerard on 12/19/19.
//  Copyright © 2019 David Gerard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (NSString *)openCVVersionString;
+ (UIImage *)convertToGrayscale:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
