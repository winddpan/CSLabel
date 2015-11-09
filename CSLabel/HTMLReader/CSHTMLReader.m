//
//  HTMLReader.m
//  youyushe
//
//  Created by Pan Xiao Ping on 14-7-15.
//  Copyright (c) 2014年 cimu. All rights reserved.
//

#import "CSHTMLReader.h"
#import "NSString+CSHTML.h"
#import "DTHTMLParser.h"

#define PARAGRAPH_SPACING       15
#define LINE_SPACING            5

#define ELEMENT_LIST_LEADING    20
#define ELEMENT_LIST_SPACING    LINE_SPACING

typedef enum : NSUInteger {
    HTMLElementListStyleNone,
    HTMLElementListStyleDecimal,
    HTMLElementListStyleDisc,
} HTMLElementListStyle;

typedef enum : NSUInteger {
    HTMLElementStyleNone        = 0,
    HTMLElementStyleBold        = 1 << 0,
    HTMLElementStyleItalic      = 1 << 1,
    HTMLElementStyleStrike      = 1 << 2,
    HTMLElementStyleUnderline   = 1 << 3,
    HTMLElementStyleSup         = 1 << 4,
    HTMLElementStyleSub         = 1 << 5,
    HTMLElementStyleList        = 1 << 6,
    HTMLElementStyleListItem    = 1 << 7,
    HTMLElementStyleParagraph   = 1 << 8,
} HTMLElementStyle;

@interface TagElement : NSObject
@property (nonatomic)   HTMLElementStyle style;
@property (nonatomic)   NSString *elementName;
@end
@implementation TagElement
@end

@interface ListElement : NSObject
@property (nonatomic)   HTMLElementListStyle style;
@property (nonatomic)   NSInteger depth;
@property (nonatomic)   NSInteger childCount;
@property (nonatomic)   CGFloat listIndent;
@end

@implementation ListElement
- (NSString *)description {
    return [NSString stringWithFormat:@"depth:%zd childCount:%zd listIndent:%f style:%zd", _depth, _childCount, _listIndent, _style];
}
@end

@interface CSHTMLReader() <DTHTMLParserDelegate>
{
    NSDictionary *_defaultAttribute;
    UIFont *_defatulFont;
    
    NSString *_ignoreFirstBRTag;
    NSString *_currentHref;

    NSMutableArray *_elementStack;
    NSMutableArray *_elementListStack;
    NSMutableAttributedString *_output;
}
@end

@implementation CSHTMLReader

- (NSAttributedString *)AttributedStringFromHTML:(NSString *)html attributes:(NSDictionary *)attrs
{
    if (![html isKindOfClass:[NSString class]]) {
        return nil;
    }
    _defaultAttribute = [attrs copy];
    _defatulFont = _defaultAttribute[NSFontAttributeName] ? : [UIFont systemFontOfSize:12];
    _output = [[NSMutableAttributedString alloc] init];

    html = [self replaceTables:html];
    html = [html stringByReplaceLaTextToImageUrl];
    html = [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSDictionary *replacements = @{@"<p>\\s*</p>"   : @"",
                                   @"\n"            : @"",
                                   @"<(?=[^<>]*<)"  : @"&lt;",
                                   @"<p>\\s*"       : @"<p>",
                                   @"<div>\\s*"     : @"<div>",
                                   @"\\s*<"         : @"<",
                                   };
    
    NSMutableString *handleString = [NSMutableString stringWithString:html];
    [replacements enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [handleString replaceOccurrencesOfString:key withString:value options:NSRegularExpressionSearch range:NSMakeRange(0, handleString.length)];
    }];
    
    DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:[handleString dataUsingEncoding:NSUTF8StringEncoding] encoding:NSUTF8StringEncoding];
    parser.delegate = self;
    [parser parse];

    return _output;
}

- (NSString *)replaceTables:(NSString *)html
{
    NSString *result = [html copy];
    NSString *pattern = @"<table[^<>]*?>[\\s\\S]*?<[^<>]*?/table>";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];
    
    NSArray *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, [result length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        NSString *matchString = [html substringWithRange:matchRange];
        NSString *base64Encoded = [[matchString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];

        NSString *newStr = [NSString stringWithFormat:@"<img src=\"table://%@\"/>", base64Encoded];
        result = [result stringByReplacingOccurrencesOfString:matchString withString:newStr];
    }
    return result;
}

#pragma ######## DTHTMLParser Delegate ########-
- (void)parser:(DTHTMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"HTMLParser error %@", parseError);
}

- (void)parserDidStartDocument:(DTHTMLParser *)parser
{
    _elementStack = [[NSMutableArray alloc] init];
    _elementListStack = [[NSMutableArray alloc] init];
    [_output beginEditing];
}

- (void)parserDidEndDocument:(DTHTMLParser *)parser
{
    [_output endEditing];
    
    [_elementStack removeAllObjects];
    [_elementListStack removeAllObjects];
    _elementStack = nil;
    _elementListStack = nil;
}

- (void)parser:(DTHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict
{
    elementName = [elementName lowercaseString];
    if ([elementName isEqualToString:@"html"]) return;
    
    TagElement *tag = [TagElement new];
    tag.style = HTMLElementStyleNone;
    tag.elementName = elementName;
    [_elementStack addObject:tag];
    
    if ([elementName isEqualToString:@"p"] || [elementName isEqualToString:@"li"]) {
        if (_output.length > 0) {
            [self startUpNewLine];
        }
        _ignoreFirstBRTag = elementName;
    }else if ([elementName isEqualToString:@"br"]) {
        if (_ignoreFirstBRTag) {
            _ignoreFirstBRTag = nil;
        } else {
            [self startUpNewLine];
        }
    }
    
    if ([elementName isEqualToString:@"a"]) {
        _currentHref = attributeDict[@"href"];
    }else if ([elementName isEqualToString:@"img"]) {
        NSString *url = attributeDict[@"src"];
        NSDictionary *styles = [self styleDictionaryByStr:attributeDict[@"style"]];

        CSTextAttachment *textAttachment = [[CSTextAttachment alloc] init];
        if (_defaultAttribute[CSHTMLTextAttachmentSerializerName]) {
            textAttachment.serizlizer = _defaultAttribute[CSHTMLTextAttachmentSerializerName];
        }
        textAttachment.tableFont = _defatulFont;
        textAttachment.tableColor = _defaultAttribute[NSForegroundColorAttributeName];
        textAttachment.contentURL = url;
        
        NSMutableAttributedString *attachmentStr = [[NSAttributedString attributedStringWithAttachment:textAttachment] mutableCopy];
        [attachmentStr addAttributes:[self fragmentAttribute] range:NSMakeRange(0, attachmentStr.length)];
        
        if ([styles[@"display"] isEqualToString:@"block"]) {
            
            void (^RemoveParagraphSpacing)(NSInteger, NSMutableAttributedString *) = ^void(NSInteger index, NSMutableAttributedString *input) {
                if (index < 0 || index >= input.length) {
                    return;
                }
                NSRange range;
                NSDictionary *attr = [input attributesAtIndex:index effectiveRange:&range];
                NSMutableParagraphStyle *paragraph = [attr[NSParagraphStyleAttributeName] mutableCopy];
                paragraph.paragraphSpacing = 0;
                paragraph.paragraphSpacingBefore = 0;
                if (paragraph) {
                    [input addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(range.location, range.length)];
                }
            };
            RemoveParagraphSpacing(_output.length-1, _output);
            RemoveParagraphSpacing(0, attachmentStr);

            [self startUpNewLine];
            [_output appendAttributedString:attachmentStr];
            [self startUpNewLine];
        } else {
            [_output appendAttributedString:attachmentStr];
        }

    }else if ([elementName isEqualToString:@"strong"] || [elementName isEqualToString:@"b"]) {
        tag.style = HTMLElementStyleBold;
    }else if ([elementName isEqualToString:@"em"] || [elementName isEqualToString:@"i"]) {
        tag.style = HTMLElementStyleItalic;
    }else if ([elementName isEqualToString:@"strike"]) {
        tag.style = HTMLElementStyleStrike;
    }else if ([elementName isEqualToString:@"u"]) {
        tag.style = HTMLElementStyleUnderline;
    }else if ([elementName isEqualToString:@"sub"]) {
        tag.style = HTMLElementStyleSub;
    }else if ([elementName isEqualToString:@"sup"]) {
        tag.style = HTMLElementStyleSup;
    }else if ([elementName isEqualToString:@"ul"]) {
        tag.style = HTMLElementStyleList;

        ListElement *element = [[ListElement alloc] init];
        element.depth = [[_elementListStack lastObject] depth] + 1;
        element.style = HTMLElementListStyleDisc;
        [_elementListStack addObject:element];
    }else if ([elementName isEqualToString:@"ol"]) {
        tag.style = HTMLElementStyleList;

        ListElement *element = [[ListElement alloc] init];
        element.depth = [[_elementListStack lastObject] depth] + 1;
        element.style = HTMLElementListStyleDecimal;
        [_elementListStack addObject:element];
    }else if ([elementName isEqualToString:@"li"]) {
        tag.style = HTMLElementStyleListItem;
        
        NSString *prefixStr;
        UIFont *prefixFont;
        ListElement *element = [_elementListStack lastObject];
        
        if (element.style == HTMLElementListStyleDecimal) {
            prefixFont = _defatulFont;
            prefixStr = [NSString stringWithFormat:@"%zd.", element.childCount + 1];
        } else {
            prefixFont = [UIFont fontWithName:@"Times New Roman" size:_defatulFont.pointSize];
            switch (element.depth) {
                case 0:
                case 1:
                    prefixStr = @"\u2022";
                    break;
                case 2:
                    prefixStr = @"\u25e6";
                    break;
                default:
                    prefixStr = @"\u25aa";
                    break;
            }
        }
        
        NSMutableParagraphStyle *prefixPragraph = [NSMutableParagraphStyle new];
        prefixPragraph.firstLineHeadIndent = ELEMENT_LIST_LEADING * [[_elementListStack lastObject] depth];
        prefixPragraph.lineSpacing = ELEMENT_LIST_SPACING;
        //prefixPragraph.paragraphSpacingBefore = element.childCount == 0 && element.depth == 1 ? ELEMENT_LIST_EXTER_SPACING : 0;
        
        NSMutableDictionary *prefixAttribute = [NSMutableDictionary new];
        [prefixAttribute setObject:prefixPragraph forKey:NSParagraphStyleAttributeName];
        [prefixAttribute setObject:prefixFont forKey:NSFontAttributeName];
        [prefixAttribute setObject:_defaultAttribute[NSForegroundColorAttributeName] ? : [UIColor blackColor]
                            forKey:NSForegroundColorAttributeName];

        NSMutableAttributedString *prefix = [[NSMutableAttributedString alloc] initWithString:prefixStr
                                                                     attributes:prefixAttribute];
        NSAttributedString *spacing = [[NSAttributedString alloc] initWithString:@" "
                                                                     attributes:@{ NSKernAttributeName : @(5),
                                                                                   NSFontAttributeName : prefixFont}];
        [prefix appendAttributedString:spacing];
        [_output appendAttributedString:prefix];
        
        element.childCount += 1;
        element.listIndent = [prefix size].width;
        
        prefixPragraph.headIndent = prefixPragraph.firstLineHeadIndent + element.listIndent;
    }
    else if ([attributeDict objectForKey:@"style"]) {
        HTMLElementStyle mixedStyle = HTMLElementStyleNone;
        NSDictionary *styleDict = [self styleDictionaryByStr:[attributeDict objectForKey:@"style"]];
        NSString *value = nil;
        if ((value = styleDict[@"font-style"])) {
            if ([value rangeOfString:@"italic"].location != NSNotFound || [value rangeOfString:@"oblique"].location != NSNotFound) {
                mixedStyle |= HTMLElementStyleItalic;
            }
        } else if ((value = styleDict[@"font-weight"])) {
            if ([value rangeOfString:@"bold"].location != NSNotFound) {
                mixedStyle |= HTMLElementStyleBold;
            }
        } else if ((value = styleDict[@"text-decoration"])) {
            if ([value rangeOfString:@"underline"].location != NSNotFound) {
                mixedStyle |= HTMLElementStyleUnderline;
            }
            if ([value rangeOfString:@"line-through"].location != NSNotFound) {
                mixedStyle |= HTMLElementStyleStrike;
            }
        }
        tag.style = mixedStyle;
    }
}

- (void)parser:(DTHTMLParser *)parser didEndElement:(NSString *)elementName
{
    elementName = [elementName lowercaseString];
    [_elementStack removeLastObject];
    
    if ([elementName isEqualToString:@"a"]) {
        _currentHref = nil;
    }
    if ([_ignoreFirstBRTag isEqualToString:elementName]) {
        _ignoreFirstBRTag = nil;
    }
    
    if ([elementName isEqualToString:@"ul"] || [elementName isEqualToString:@"ol"]) {
        [_elementListStack removeLastObject];
        if (_elementListStack.count == 0) {
            
            void (^AppendListParagraphSpacing)(NSInteger) = ^void(NSInteger index) {
                if (index < 0 || index >= _output.length) {
                    return;
                }
                NSRange range;
                NSDictionary *attr = [_output attributesAtIndex:index effectiveRange:&range];
                NSMutableParagraphStyle *paragraph = [attr[NSParagraphStyleAttributeName] mutableCopy] ?: [NSMutableParagraphStyle new];
                paragraph.paragraphSpacing = ELEMENT_LIST_SPACING + PARAGRAPH_SPACING;
                [_output addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(range.location, range.length)];
            };
            
            NSRange range;
            [_output attributesAtIndex:_output.length-1 effectiveRange:&range];
            
            AppendListParagraphSpacing(_output.length-1);
            AppendListParagraphSpacing(range.location-1);
            AppendListParagraphSpacing(range.location-2);
        }
    }
}

- (void)parser:(DTHTMLParser *)parser foundCharacters:(NSString *)string
{
    TagElement *ele = [_elementStack lastObject];
    if (ele.style == HTMLElementStyleList) {
        return;
    }
    
    NSDictionary *attrs = [self fragmentAttribute];
    NSMutableAttributedString *fragment = [[NSMutableAttributedString alloc] initWithString:string attributes:attrs];
    [_output appendAttributedString:fragment];
    
    // 防止样式污染
    unichar replacementChar = 0xFFFC;
    NSAttributedString *replacementString = [[NSAttributedString alloc] initWithString:[NSString stringWithCharacters:&replacementChar length:1]
                                                                            attributes:@{NSFontAttributeName:_defatulFont}];
    [_output appendAttributedString:replacementString];
}

- (BOOL)elementStyleStackContainStyle:(HTMLElementStyle)style
{
    for (TagElement *tag in _elementStack) {
        if (tag.style & style) {
            return YES;
        }
    }
    return NO;
}

- (NSDictionary *)styleDictionaryByStr:(NSString *)styleStr
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSArray *styles = [styleStr componentsSeparatedByString:@";"];
    [styles enumerateObjectsUsingBlock:^(NSString *style, NSUInteger idx, BOOL *stop) {
        NSArray *ps = [style componentsSeparatedByString:@":"];
        if (ps.count >= 2) {
            NSMutableArray *temp = [ps mutableCopy];
            [temp removeObjectAtIndex:0];
            
            NSString *key = ps[0];
            NSString *value = [temp componentsJoinedByString:@":"];
            key = [key stringByReplacingOccurrencesOfString:@" " withString:@""];
            value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
            [dictionary setValue:value forKey:key];
        }
    }];
    return dictionary.count ? dictionary : nil;
}

- (void)startUpNewLine {
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"\n" attributes:@{NSFontAttributeName:_defatulFont}];
    [_output appendAttributedString:attrStr];
}

- (NSDictionary *)fragmentAttribute
{
    NSMutableDictionary *attribute = [_defaultAttribute mutableCopy];
    UIFont *font = [_defatulFont copy];

    if ([self elementStyleStackContainStyle:HTMLElementStyleBold]) {
        UIFontDescriptor *descriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        font = [UIFont fontWithDescriptor:descriptor size:0];
    }
    if ([self elementStyleStackContainStyle:HTMLElementStyleItalic]) {
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);
        UIFontDescriptor *descriptor = [font.fontDescriptor fontDescriptorWithMatrix:matrix];
        font = [UIFont fontWithDescriptor:descriptor size:0];
    }
    [attribute setObject:font forKey:NSFontAttributeName];

    if ([self elementStyleStackContainStyle:HTMLElementStyleStrike]) {
        [attribute setObject:@(YES) forKey:NSStrikethroughStyleAttributeName];
    }
    if ([self elementStyleStackContainStyle:HTMLElementStyleUnderline]) {
        [attribute setObject:@(NSUnderlineStyleSingle) forKey:NSUnderlineStyleAttributeName];
    }
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentNatural;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionNatural;
    paragraphStyle.paragraphSpacing = PARAGRAPH_SPACING;
    paragraphStyle.lineSpacing = LINE_SPACING;
    
    if ([self elementStyleStackContainStyle:HTMLElementStyleListItem]) {
        ListElement *element = [_elementListStack lastObject];
        paragraphStyle.firstLineHeadIndent = ELEMENT_LIST_LEADING * element.depth + element.listIndent;
        paragraphStyle.headIndent = ELEMENT_LIST_LEADING * element.depth + element.listIndent;
        paragraphStyle.paragraphSpacing = 0;
    }
    [attribute setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];

    if ([self elementStyleStackContainStyle:HTMLElementStyleSup] || [self elementStyleStackContainStyle:HTMLElementStyleSub]) {
        font = [font fontWithSize:floor(font.pointSize * .75)];
        [attribute setObject:font forKey:NSFontAttributeName];
    }
    if ([self elementStyleStackContainStyle:HTMLElementStyleSup]) {
        NSDictionary *referenceInfo = @{(id)kCTBaselineClassIdeographicCentered : @(font.pointSize),
                                         (id)kCTBaselineReferenceFont : (id)font,};
        [attribute setObject:referenceInfo forKey:(id)kCTBaselineReferenceInfoAttributeName];
        [attribute setObject:(__bridge id)kCTBaselineClassIdeographicCentered forKey:(id)kCTBaselineClassAttributeName];
    } else if ([self elementStyleStackContainStyle:HTMLElementStyleSub]) {
        NSDictionary *referenceInfo = @{(id)kCTBaselineClassIdeographicCentered : @(0),
                                        (id)kCTBaselineReferenceFont : (id)font,};
        [attribute setObject:referenceInfo forKey:(id)kCTBaselineReferenceInfoAttributeName];
        [attribute setObject:(__bridge id)kCTBaselineClassIdeographicCentered forKey:(id)kCTBaselineClassAttributeName];
    }
    if (_currentHref) {
        [attribute setObject:_currentHref forKey:NSLinkAttributeName];
    }
    return attribute;
}

@end

@implementation NSAttributedString (HTMLReader)

- (instancetype)initWithHTML:(NSString *)html htmlAttributes:(NSDictionary *)htmlAttrs
{
    NSAttributedString *as = [[CSHTMLReader new] AttributedStringFromHTML:html attributes:htmlAttrs];
    
    if ([self isKindOfClass:[NSMutableAttributedString class]]) {
        self = [as mutableCopy];
    }else{
        self = [as copy];
    }
    return self;
}

@end

@implementation NSAttributedString (CSTextAttachment)

- (NSArray *)allCSAttachment
{
    NSMutableArray *array = [NSMutableArray array];
    [self enumerateAttributesInRange:NSMakeRange(0, self.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if (attrs[NSAttachmentAttributeName] && !attrs[NSLinkAttributeName]) {
            CSTextAttachment *attachment = attrs[NSAttachmentAttributeName];
            if ([attachment isKindOfClass:[CSTextAttachment class]]) {
                [array addObject:attachment];
            }
        }
    }];
    NSArray *result = [array copy];
    [array removeAllObjects];
    array = nil;
    
    return result;
}

@end
