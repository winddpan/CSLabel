//
//  CSTextLink.m
//  CSLabel
//
//  Created by Pan Xiao Ping on 15/11/5.
//  Copyright © 2015年 Cimu. All rights reserved.
//

#import "CSTextLink.h"

@implementation CSTextLink
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ - %p: type:%zd range:%@ glyphRect:%@\nattributedString:%@>", self.class, self, self.type, NSStringFromRange(self.range), NSStringFromCGRect(self.glyphRect), self.attributeString];
}
@end
