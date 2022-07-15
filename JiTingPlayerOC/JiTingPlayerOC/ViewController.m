//
//  ViewController.m
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/15.
//

#import "ViewController.h"
@import WebKit;
@interface ViewController ()
@property (nonatomic, strong) WKWebView *contentWebView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.statusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.statusButton.backgroundColor = UIColor.greenColor;
    self.statusButton.layer.cornerRadius = 8;
    self.statusButton.layer.masksToBounds = YES;
    [self.view addSubview:self.statusButton];
    self.statusButton.frame = CGRectMake(0, 0, 100, 100);
    self.statusButton.center = self.view.center;
    [self.statusButton addTarget:UIApplication.sharedApplication.delegate action:@selector(statusAction:) forControlEvents:UIControlEventTouchUpInside];

    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.websiteDataStore = dataStore;
    config.allowsInlineMediaPlayback = YES;
    config.processPool = [[WKProcessPool alloc] init];
    self.contentWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 100) configuration:config];
    [self.view addSubview:self.contentWebView];
    NSURL *destUrl = [NSUserDefaults.standardUserDefaults URLForKey:@"destUrl"];
    [self.contentWebView loadRequest:[NSURLRequest requestWithURL:destUrl]];
}

- (void)statusAction:(UIButton *)sender {
    
}

@end
