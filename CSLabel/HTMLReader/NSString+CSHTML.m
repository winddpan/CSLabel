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

- (NSString *)cs_urlEncode {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"\":/?#[]@!$ &\'()*+,;=\\\"<>%{}|\\\\^~`\""]];
}

- (NSString *)cs_urlByLaText:(NSString *)latext
{
    NSString *suffix = [@"\\inline \\dpi{200} \\fn_phv &" stringByAppendingString:latext];
    NSString *tag = [NSString stringWithFormat:@"<img src=\"%@%@\"/>", kLaTextURL, [suffix cs_urlEncode]];
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
            NSString *latexImgTag = [self cs_urlByLaText:[tagString substringWithRange:NSMakeRange(1, tagString.length -2)] ];
            result = [result stringByReplacingOccurrencesOfString:tagString withString:latexImgTag];
        }
    }
    return result;
}

@end
