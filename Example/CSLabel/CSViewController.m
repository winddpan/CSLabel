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
    [[CSTextAttachmentSerializer defaultSerializer] setPlaceholerImage:[UIImage imageNamed:@"IMG_0355.JPG"]];

    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"HTML2" ofType:@"html"];
    NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    NSAttributedString *xx1 = [[NSAttributedString alloc] initWithHTML:html htmlAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15]}];
    
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
