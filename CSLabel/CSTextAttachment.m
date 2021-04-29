//
//  CSTextAttachment.m
//  TextEditorTest
//
//  Created by Pan Xiao Ping on 15/1/21.
//  Copyright (c) 2015年 Cimu. All rights reserved.
//

#import "CSTextAttachment.h"
#import "NSString+CSHTML.h"

NSString *const CSHTMLTextAttachmentSerializerName = @"CSHTMLTextAttachmentSerializerName";
NSString *const CSTextAttachmentDidDownloadNotification = @"CSTextAttachmentDidDownloadNotification";
NSString *const CSTextAttachmentFailedDownloadNotification = @"CSTextAttachmentFailedDownloadNotification";

@implementation CSTextAttachmentSerializer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.thumbImageWidth = [self.class defaultSerializer].thumbImageWidth;
        self.scale = [self.class defaultSerializer].scale;
        self.placeholderImage = [self.class defaultSerializer].placeholderImage;
        self.failedImage = [self.class defaultSerializer].failedImage;
    }
    return self;
}

- (instancetype)_superInit
{
    return [super init];
}

+ (CSTextAttachmentSerializer *)defaultSerializer {
    static dispatch_once_t onceToken;
    static CSTextAttachmentSerializer *serializer;
    dispatch_once(&onceToken, ^{
        serializer = [[CSTextAttachmentSerializer alloc] _superInit];
        serializer.scale = 1;
        serializer.thumbImageWidth = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        serializer.placeholderImage = nil;
        serializer.failedImage = nil;
    });
    return serializer;
}

@end

@implementation CSTextAttachment
@synthesize contentURL = _contentURL;

+ (NSCache *)sharedCache {
    static dispatch_once_t onceToken;
    static NSCache *cache;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * __unused notification) {
            [cache removeAllObjects];
        }];
    });
    return cache;
}

+ (NSMutableSet *)downloadingURLSet {
    static NSMutableSet *set = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        set = [[NSMutableSet alloc] init];
    });
    return set;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSString *thumbURL;
    if ((thumbURL = [self thumbURL]) != nil) {
        [[self.class downloadingURLSet] removeObject:thumbURL];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.serizlizer = [CSTextAttachmentSerializer new];
        _status = CSTextAttachmentStatusReady;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_thumbImageDownloadNotify:) name:CSTextAttachmentDidDownloadNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_thumbImageDownloadNotify:) name:CSTextAttachmentFailedDownloadNotification object:nil];
    }
    return self;
}

- (void)setContentURL:(NSString *)contentURL
{
    _contentURL = contentURL;
    
    _srcImage = [[CSTextAttachment sharedCache] objectForKey:self.thumbURL];
    if (_srcImage) {
        self.image = _srcImage;
        _status = CSTextAttachmentStatusDownloaded;
    } else {
        _status = CSTextAttachmentStatusReady;
        self.image = self.serizlizer.placeholderImage;
    }
}

- (void)setNeedsLoad {
    NSString *contentURL = self.contentURL;
    __weak typeof(self) weakSelf = self;
    
    if (_status == CSTextAttachmentStatusReady && !_srcImage) {
        _status = CSTextAttachmentStatusDownloading;
        
        NSString *thumbURL = [self thumbURL];
        NSMutableSet *downloadingURLSet = [self.class downloadingURLSet];
        BOOL isDownloading = [downloadingURLSet containsObject:thumbURL];
        if (!isDownloading) {
            [downloadingURLSet addObject:thumbURL];
            
            [self requestImageWithURL:[NSURL URLWithString:thumbURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                [downloadingURLSet removeObject:thumbURL];
                _srcImage = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
                if (error || !_srcImage) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.image = self.serizlizer.failedImage;
                        weakSelf.status = CSTextAttachmentStatusDownloadFailed;
                        [[NSNotificationCenter defaultCenter] postNotificationName:CSTextAttachmentFailedDownloadNotification object:self];
                    });
                } else {
                    [[CSTextAttachment sharedCache] setObject:_srcImage forKey:thumbURL];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.image = _srcImage;
                        weakSelf.status = CSTextAttachmentStatusDownloaded;
                        [[NSNotificationCenter defaultCenter] postNotificationName:CSTextAttachmentDidDownloadNotification object:self];
                    });
                }
            }];
        }
    }
}

- (void)requestImageWithURL:(NSURL *)url
          completionHandler:(void (^)(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error))completionHandler {
    
    NSOperatingSystemVersion ios9_0_1 = (NSOperatingSystemVersion){9, 0, 1};
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios9_0_1]) {
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            completionHandler(data, response, error);
        }];
        [task resume];
    } else {
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            completionHandler(data, response, connectionError);
        }];
    }
}

//相同的contentURL使用通知来送达所有注册的TextAttachment
- (void)_thumbImageDownloadNotify:(NSNotification *)noti
{
    CSTextAttachment *attachment = noti.object;
    if (attachment != self && [attachment.contentURL isEqualToString:self.contentURL]) {
        self.status = attachment.status;
        self.image = attachment.image;
    }
    
}

- (CGRect)boundsForConsiderSize:(CGSize)cSize
{
    CGFloat imageScale = (self.image == self.serizlizer.placeholderImage ||
                          self.image == self.serizlizer.failedImage ||
                          [self.contentURL hasPrefix:@"table://"] ||
                          [self.contentURL hasPrefix:CSLaTextURL]) ?  1 : self.serizlizer.scale;
    CGSize size = CGSizeMake(self.image.size.width * self.image.scale / [UIScreen mainScreen].scale * imageScale,
                             self.image.size.height * self.image.scale / [UIScreen mainScreen].scale * imageScale);
    
    CGFloat scale = size.width / cSize.width;
    if (scale > 1) {
        size = CGSizeMake(cSize.width, size.height / scale);
    }
    return  (CGRect){.size = CGSizeMake(floor(size.width), floor(size.height))};
}

- (NSString *)thumbURL
{
    NSArray *cdns = @[@"clouddn.com", @"qiniudn.com"];
    __block BOOL hasThumbURL = NO;
    [cdns enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([self.contentURL rangeOfString:obj].location != NSNotFound) {
            hasThumbURL = YES;
            *stop = YES;
        }
    }];
    
    if (hasThumbURL) {  //缩略图
        return [NSString stringWithFormat:@"%@?imageView/2/w/%.0f",
                self.contentURL,
                self.serizlizer.thumbImageWidth * [[UIScreen mainScreen] scale]];
    }
    return self.contentURL;
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex {
    CGRect bounds = [self boundsForConsiderSize:textContainer.size];
    return bounds;
}

- (UIImage *)imageForBounds:(CGRect)imageBounds textContainer:(NSTextContainer *)textContainer characterIndex:(NSUInteger)charIndex {
    return self.image;
}

@end
