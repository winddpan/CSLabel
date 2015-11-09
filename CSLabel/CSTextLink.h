//
//  CSTextLink.h
//  CSLabel
//
//  Created by Pan Xiao Ping on 15/11/5.
//  Copyright © 2015年 Cimu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CSTextLinkType) {
    CSTextLinkTypeNone = 0,
    CSTextLinkTypeImage,          // 附件图片
    CSTextLinkTypeURL,            // 超链接
};

@interface CSTextLink : NSObject
@property (nonatomic, assign) CSTextLinkType type;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, assign) CGRect glyphRect;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSDictionary *attributedDictionary;
@end
