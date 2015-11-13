//
//  NSString+HtmlTagRemove.m
//  youyushe
//
//  Created by Pan Xiao Ping on 14-9-4.
//  Copyright (c) 2014年 cimu. All rights reserved.
//

#import "NSString+CSHTML.h"

NSString* const kLaTextURL = @"http://latex.codecogs.com/gif.latex?";

@implementation NSString (CSHTML)

+ (NSString *)generateRandomString:(NSInteger)num {
    NSMutableString* string = [NSMutableString stringWithCapacity:num];
    for (int i = 0; i < num; i++) {
        [string appendFormat:@"%C", (unichar)('a' + arc4random_uniform(25))];
    }
    return string;
}

+ (NSString *)generateRandomChineseString:(NSInteger)num
{
    u_int32_t scope = 0x9fbb - 0x4e00;
    NSMutableString* string = [NSMutableString stringWithCapacity:num];
    for (int i = 0; i < num; i++) {
        [string appendFormat:@"%C", (unichar)(0x4e00 + arc4random_uniform(scope))];
    }
    return string;
}


- (BOOL)isHTMLBlank {
    NSString *removeTagStr = [self stringByRemoveHTMLTag];
    if (removeTagStr.length == 0) {
        if ([self containsString:@"img"] || [self containsString:@"ul"] || [self containsString:@"ol"]) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)stringByRemoveHTMLTag
{
    NSRange r;
    NSString *s = [self copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    while ((r = [s rangeOfString:@"&\\w*;" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    s = [s stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    
    return s;
}

- (NSString *)stringByRemoveNewlineCharacters
{
    NSString *text = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return text;
}

- (NSString *)urlEncode {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"\":/?#[]@!$ &\'()*+,;=\\\"<>%{}|\\\\^~`\""]];
}

- (NSString *)urlDecode {
    return [self stringByRemovingPercentEncoding];
}

- (NSString *)urlByLaText:(NSString *)latext
{
    NSString *suffix = [@"\\inline \\dpi{200} \\fn_phv &" stringByAppendingString:latext];
    NSString *tag = [NSString stringWithFormat:@"<img src=\"%@%@\"/>", kLaTextURL, [suffix urlEncode]];
    return tag;
}

- (NSString *)stringByReplaceLaTextToImageUrl
{
    NSString *result = [self copy];
    NSString *pattern = @"\\$[^\\$]+\\$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                          options:NSRegularExpressionCaseInsensitive
                                                                            error:NULL];
    NSArray *matches = [regex matchesInString:self options:0 range:NSMakeRange(0, [self length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        NSString *tagString = [self substringWithRange:matchRange];
        
        if (tagString.length >2) {
            NSString *latexImgTag = [self urlByLaText:[tagString substringWithRange:NSMakeRange(1, tagString.length -2)] ];
            result = [result stringByReplacingOccurrencesOfString:tagString withString:latexImgTag];
        }
    }
    return result;
}

@end
