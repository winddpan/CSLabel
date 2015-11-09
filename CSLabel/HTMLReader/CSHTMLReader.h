//
//  HTMLReader.h
//  youyushe
//
//  Created by Pan Xiao Ping on 14-7-15.
//  Copyright (c) 2014年 cimu. All rights reserved.
//

#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>
#import "CSTextAttachment.h"

@interface CSHTMLReader : NSObject
@end

@interface NSAttributedString (HTMLReader)

/**
 *  convert html to NSAttributedString
 *
 *  @param html      pure html string, no css
 *  @param htmlAttrs sytle attrs - CSHtmlXXX
 */
- (instancetype)initWithHTML:(NSString *)html htmlAttributes:(NSDictionary *)htmlAttrs;

@end

@interface NSAttributedString (CSTextAttachment)

/**
 *  @return all CSAttachments in attributedString
 */
- (NSArray *)allCSAttachment;
@end