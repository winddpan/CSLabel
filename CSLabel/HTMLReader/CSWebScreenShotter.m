//
//  CSWebScreenShotter.m
//  PerformanceTest
//
//  Created by Pan Xiao Ping on 15/2/28.
//  Copyright (c) 2015年 Cimu. All rights reserved.
//

#import "CSWebScreenShotter.h"

@interface CSWebScreenShotterObject : NSObject
@property (nonatomic, strong) NSString *request;
@property (nonatomic, strong) CSScreenshot completion;
@property (nonatomic) CGFloat width;
@property (nonatomic) UIFont *font;
@property (nonatomic) UIColor *color;
@end

@implementation CSWebScreenShotterObject
@end

@interface CSWebScreenShotter () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSMutableArray *shotterQueue;
@end

@implementation CSWebScreenShotter

+(CSWebScreenShotter *)sharedShotter {
    static CSWebScreenShotter *shotter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shotter = [[CSWebScreenShotter alloc] init];
    });
    return shotter;
}

+ (void)screenshotWithHtml:(NSString *)html width:(CGFloat)width font:(UIFont *)font color:(UIColor *)color completion:(CSScreenshot)completion
{
    CSWebScreenShotterObject *object = [[CSWebScreenShotterObject alloc] init];
    object.request = html;
    object.completion = completion;
    object.width = width;
    object.font = font;
    object.color = color;
    
    [[[self class] sharedShotter] screenshotWithObject:object];
}

- (void)dealloc
{
    [self.shotterQueue removeAllObjects];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.shotterQueue = [NSMutableArray new];
    }
    return self;
}

- (void)screenshotWithObject:(CSWebScreenShotterObject *)object
{
    [self.shotterQueue addObject:object];
    [self processNextRequest];
}

- (void)processNextRequest {
    NSMutableArray *queue = self.shotterQueue;
    if (queue.count) {
        CSWebScreenShotterObject *object = [queue firstObject];
        _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, object.width, 1)];
        _webView.delegate = self;
        [_webView loadHTMLString:object.request baseURL:nil];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    _webView.backgroundColor = [UIColor yellowColor];

    if (self.shotterQueue.count) {
        CSWebScreenShotterObject *object = self.shotterQueue.firstObject;
        if (object.completion) {
            UIImage *image = [self fullScreenshot:webView];
            object.completion(image);
        }
        [self.shotterQueue removeObjectAtIndex:0];
        _webView = nil;
        [self processNextRequest];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.shotterQueue.count) {
        CSWebScreenShotterObject *object = self.shotterQueue.firstObject;
        if (object.completion) {
            object.completion(nil);
        }
        [self.shotterQueue removeObjectAtIndex:0];
        _webView = nil;
        [self processNextRequest];
    }
}

-(UIImage *)fullScreenshot:(UIWebView *)webView {
    CSWebScreenShotterObject *object = self.shotterQueue.firstObject;
    CGFloat fontSize = object.font.pointSize;
    NSString *familyName = [[[object.font.familyName componentsSeparatedByString:@" "] firstObject]
                            stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    NSString *colorHex = hexValuesFromUIColor(object.color);
    NSString *colorJS = colorHex ?
    [NSString stringWithFormat:@"document.getElementsByTagName('table')[0].style.color='%@';document.getElementsByTagName('table')[0].style.borderColor='%@'",
     colorHex, colorHex] : @"";
    
    NSArray *jss = @[colorJS,
                     @"document.body.style.margin='0';document.body.style.padding='0'",
                     @"document.getElementsByTagName('table')[0].style.padding='0';document.getElementsByTagName('table')[0].style.margin='0'",
                     [NSString stringWithFormat:@"document.body.style.fontFamily='%@'", familyName],
                     [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%.0f%%'", fontSize/16.0 *100]];
    [webView stringByEvaluatingJavaScriptFromString:[jss componentsJoinedByString:@";"]];

    CGFloat width = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('table')[0].offsetWidth;"].doubleValue +
                    [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('table')[0].offsetLeft;"].doubleValue;
    CGFloat height = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('table')[0].offsetHeight;"].doubleValue +
                    [webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('table')[0].offsetTop;"].doubleValue;

    
    webView.frame = CGRectMake(0, 0, ceil(width), ceil(height));
    UIImage *screenshot = [self screenshot:webView];
    return screenshot;
}

- (UIImage *)screenshot:(UIWebView *)webView {
    UIGraphicsBeginImageContextWithOptions(webView.frame.size, YES, 0.0f);
    [webView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenshot;
}

static inline NSString *hexValuesFromUIColor(UIColor *color) {
    if (!color) {
        return nil;
    }
    
    if (color == [UIColor whiteColor]) {
        // Special case, as white doesn't fall into the RGB color space
        return @"ffffff";
    }
    
    CGFloat red;
    CGFloat blue;
    CGFloat green;
    CGFloat alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    int redDec = (int)(red * 255);
    int greenDec = (int)(green * 255);
    int blueDec = (int)(blue * 255);
    
    NSString *returnString = [NSString stringWithFormat:@"%02x%02x%02x", (unsigned int)redDec, (unsigned int)greenDec, (unsigned int)blueDec];
    
    return returnString;
}

@end
