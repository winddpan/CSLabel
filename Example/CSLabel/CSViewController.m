//
//  CSViewController.m
//  CSLabel
//
//  Created by winddpan on 11/09/2015.
//  Copyright (c) 2015 winddpan. All rights reserved.
//

#import "CSViewController.h"

@interface CSViewController () <CSLabelDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet CSLabel *label;
@end

@implementation CSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[CSLabel appearance] setLinkTextColor:[UIColor redColor]];
    [[CSTextAttachmentSerializer defaultSerializer] setFailedImage:[UIImage imageNamed:@"IMG_0355.JPG"]];
    [[CSTextAttachmentSerializer defaultSerializer] setPlaceholderImage:[UIImage imageNamed:@"download.gif"]];
    
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"HTML2" ofType:@"html"];
    NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSAttributedString *xx1 = [[NSAttributedString alloc] initWithHTML:html attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15]}];
    
    CSLabel *testLabel = [[CSLabel alloc] init];
    testLabel.attributedText = xx1;
    
    self.label.backgroundColor = [UIColor yellowColor];
    self.label.delegate = self;
    self.label.contentInset = UIEdgeInsetsMake(20, 20, 20, 20);
    self.label.attributedText = xx1;
}

- (void)CSLabelDidUpdateAttachment:(CSLabel *)label atRange:(NSRange)range {
    NSLog(@"CSLabelDidUpdateAttachment:%@", NSStringFromRange(range));
}

- (void)CSLabel:(CSLabel *)label didSelectLink:(CSTextLink *)link {
    NSLog(@"didSelectLink:%@", link);
}

@end
