//
//  AppDelegate.m
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/15.
//

#import "AppDelegate.h"
#import "ViewController.h"
@import SafariServices;
@interface AppDelegate () <SFSafariViewControllerDelegate>
@property (nonatomic, strong) SFSafariViewController *safari;
@property (nonatomic, strong) ViewController *safariController;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"NSHomeDirectory%@", NSHomeDirectory());
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.safariController = [[ViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.safariController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];

    if (!_safari) {
        NSURL *destUrl = [NSUserDefaults.standardUserDefaults URLForKey:@"destUrl"];
        if (destUrl) {
            _safari = [[SFSafariViewController alloc] initWithURL:destUrl];
        }
    }
    return YES;
}


- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    NSString *sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey];
    NSLog(@"JiTingPlayerOC111%@", sourceApplication);
    NSURLComponents *com = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    com.scheme = @"http";
    NSURL *destUrl = com.URL;
    [self.safari dismissViewControllerAnimated:YES completion:^{

    }];
//    self.safari = [[SFSafariViewController alloc] initWithURL:destUrl];
    [NSUserDefaults.standardUserDefaults setURL:destUrl forKey:@"destUrl"];
    NSMutableArray *array = [NSUserDefaults.standardUserDefaults arrayForKey:@"playList"].mutableCopy;
    if (!array) {
        array = [NSMutableArray array];
    }
    if (![array containsObject:destUrl]) {
        [array addObject:[destUrl dataRepresentation]];
    }
    [NSUserDefaults.standardUserDefaults setObject:array forKey:@"playList"];
    [self.safariController loadAction:@"playList"];
//    self.safari.delegate = self;
//    [self.navigationController presentViewController:self.safari animated:YES completion:^{
//
//    }];
    return YES;
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
//    self.safari = nil;
}

- (void)statusAction:(UIButton *)sender {

    [self.navigationController presentViewController:_safari animated:YES completion:^{

    }];
}

- (void)applicationWillTerminate:(UIApplication *)application {

}
@end
