//
//  CSWebScreenShotter.h
//  PerformanceTest
//
//  Created by Pan Xiao Ping on 15/2/28.
//  Copyright (c) 2015年 Cimu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^CSScreenshot)(UIImage *screenshot);
@interface CSWebScreenShotter : NSObject

/**
 *  scrennshot html to image, usually use for table.
 */
+ (void)screenshotWithHtml:(NSString *)html
                     width:(CGFloat)width
                      font:(UIFont *)font
                     color:(UIColor *)color
                completion:(CSScreenshot)completion;

@end
