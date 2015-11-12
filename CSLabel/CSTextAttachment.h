//
//  CSTextAttachment.h
//  TextEditorTest
//
//  Created by Pan Xiao Ping on 15/1/21.
//  Copyright (c) 2015年 Cimu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString *const CSHTMLTextAttachmentSerializerName;

@interface CSTextAttachmentSerializer : NSObject
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) UIImage *failedImage;
@property (nonatomic, assign) CGFloat thumbImageWidth;
@property (nonatomic, assign) CGFloat scale;

+ (CSTextAttachmentSerializer *)defaultSerializer;
@end


extern NSString *const CSTextAttachmentDidDownloadNotification;
extern NSString *const CSTextAttachmentFailedDonloadNotification;

typedef enum : NSUInteger {
    CSTextAttachmentStatusReady = 0,
    CSTextAttachmentStatusDownloading,
    CSTextAttachmentStatusDownloaded,
    CSTextAttachmentStatusDownloadFailed,
} CSTextAttachmentStatus;

@interface CSTextAttachment : NSTextAttachment
@property (nonatomic, assign)  CSTextAttachmentStatus status;
@property (nonatomic, strong)  NSString *contentURL;
@property (nonatomic, strong)  CSTextAttachmentSerializer *serizlizer;
@property (strong, readonly)   UIImage *srcImage;

/** 
 *  表格属性
 */
@property (nonatomic, strong)  UIFont *tableFont;
@property (nonatomic, strong)  UIColor *tableColor;

@end
