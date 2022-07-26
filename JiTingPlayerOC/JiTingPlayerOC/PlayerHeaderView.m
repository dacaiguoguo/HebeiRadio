//
//  PlayerHeaderView.m
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/19.
//

#import "PlayerHeaderView.h"
#import "RadioItem.h"
@import WebKit;
@import Masonry;
@import PINCache;
@import ReactiveObjC;

@interface PlayerHeaderView ()<WKScriptMessageHandler>
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) WKWebView *contentWebView;
@end

@implementation PlayerHeaderView

- (void)playItem:(RadioItem *)item {
    if (item == nil) {
        if (self.item) {
            [self.contentWebView loadRequest:[NSURLRequest requestWithURL:self.item.documentURLWithTime]];
        }
    } else {
        self.item = item;
        [self.contentWebView loadRequest:[NSURLRequest requestWithURL:self.item.documentURLWithTime]];
    }
}
- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)updateWebview {
    [self.contentWebView removeFromSuperview];
    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.websiteDataStore = dataStore;
    config.allowsInlineMediaPlayback = YES;
    [config.userContentController addScriptMessageHandler:self name:@"lvJSCallNativeHandler"];
    config.processPool = [[WKProcessPool alloc] init];
    self.contentWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 100, self.bounds.size.width, 100) configuration:config];
    [self addSubview:self.contentWebView];
    [self.contentWebView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    self.backgroundColor = UIColor.darkGrayColor;
    self.contentWebView.backgroundColor = UIColor.darkGrayColor;
    self.contentWebView.opaque = NO;
    self.contentWebView.scrollView.backgroundColor = UIColor.darkGrayColor;
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self.contentWebView evaluateJavaScript:@"var temp = window.webkit.messageHandlers.lvJSCallNativeHandler.postMessage(`${document.getElementsByTagName('video')[0].currentTime}`)"
                              completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
            //            NSLog(@"completionHandler:%@", obj);
        }];
    }];
    // https://developer.mozilla.org/zh-CN/docs/Web/HTML/Element/audio#属性
    // document.getElementsByTagName('video')[0].currentTime = 120; 可以直接修改
    // 可以用设置src来修改播放的文件，这样就不用更换的时候就重新创建webview了
    // document.getElementsByTagName('video')[0].src = "file:///Users/sunyanguo/Library/Developer/CoreSimulator/Devices/9856E35E-2A9F-4A9D-8B19-5EBD7C9D5CB8/data/Containers/Data/Application/C37EFEEE-F99A-4C7B-A9A6-A7C467B0AD46/Documents/59534E492EF1981126AE865C6BC8C569C2D600B3361B2CAF6F770E470320C1F6.mp4"
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"didReceiveScriptMessage:%@", message.body);
    NSString *bodys = message.body;
    [self.delegate view:self didReceiveScriptMessage:bodys];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self updateWebview];
        self.backgroundColor = UIColor.darkGrayColor;
    }
    return self;
}

@end
