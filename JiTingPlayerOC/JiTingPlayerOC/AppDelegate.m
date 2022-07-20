//
//  AppDelegate.m
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/15.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "RadioItem.h"
@import PINCache;
@import SafariServices;
@interface AppDelegate () <SFSafariViewControllerDelegate>
@property (nonatomic, strong) SFSafariViewController *safari;
@property (nonatomic, strong) ViewController *safariController;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"%@", NSHomeDirectory());
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.safariController = [[ViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.safariController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}


- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    NSString *sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey];
    NSLog(@"JiTingPlayerOC111%@", sourceApplication);
    NSURLComponents *com = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    com.scheme = @"http";
    NSURL *destUrl = com.URL;
    [[PINCache sharedCache] setObject:destUrl forKey:@"destUrl"];
    [self.safariController loadAction:destUrl];
//
//    //    self.safari = [[SFSafariViewController alloc] initWithURL:destUrl];
//    NSMutableArray<RadioItem *> *array = [[PINCache sharedCache] arrayForKey:@"playHistory"].mutableCopy;
//    if (!array) {
//        array = [NSMutableArray array];
//    }
//    BOOL hasAdd = NO;
//    for (RadioItem *data in array) {
//        NSURL *url = data.url;
//        if ([url.path isEqualToString:destUrl.path]) {
//            hasAdd = YES;
//        }
//    }
//
//    if (!hasAdd) {
//        [[PINCache sharedCache] setURL:destUrl forKey:@"destUrl"];
//    } else {
//        // todo 弹出alert 提示是否要播放？还是重新下载？
//    }
//    //    self.safari.delegate = self;
//    //    [self.navigationController presentViewController:self.safari animated:YES completion:^{
//    //
//    //    }];
    return YES;
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    //    self.safari = nil;
}

- (void)statusAction:(UIButton *)sender {

    //    [self.navigationController presentViewController:_safari animated:YES completion:^{
    //
    //    }];
}

- (void)applicationWillTerminate:(UIApplication *)application {

}
@end
