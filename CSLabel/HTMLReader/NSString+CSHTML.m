//
//  NSString+HtmlTagRemove.m
//  youyushe
//
//  Created by Pan Xiao Ping on 14-9-4.
//  Copyright (c) 2014年 cimu. All rights reserved.
//

#import "NSString+CSHTML.h"

NSString* const kLaTextURL = @"https://latex.codecogs.com/gif.latex?";

@implementation NSString (CSHTML)

- (NSString *)cs_urlEncode {
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (__bridge CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
}

- (NSString *)cs_urlDecode {
    NSString *string = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                             (__bridge CFStringRef)self,
                                                                                                             CFSTR(""),
                                                                                                             CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    string = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    string = [string stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    return string;
}

- (NSString *)cs_urlByLaText:(NSString *)latext
{
    latext = [latext cs_urlDecode];
    //NSString *suffix = [@"\\inline \\dpi{200} \\fn_phv &" stringByAppendingString:latext];
    NSString *tag = [NSString stringWithFormat:@"<img src=\"%@%@\"/>", kLaTextURL, [latext cs_urlEncode]];
    
    return tag;
}

- (NSString *)stringByReplaceLaTextToImageUrl
{
    NSMutableString *result = [self mutableCopy];
    NSString *pattern = @"\\$[^\\$<>]+\\$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];
    
    NSTextCheckingResult *match;
    while ((match = [regex firstMatchInString:result options:0 range:NSMakeRange(0, result.length)]) != nil) {
        NSRange matchRange = [match range];
        NSString *tagString = [result substringWithRange:matchRange];
        NSString *latexImgTag = [self cs_urlByLaText:[tagString substringWithRange:NSMakeRange(1, tagString.length -2)] ];
        [result replaceCharactersInRange:matchRange withString:latexImgTag];
    }
    
    return [result copy];
}

@end
