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
    [self.safari dismissViewControllerAnimated:YES completion:^{

    }];
    self.safari = [[SFSafariViewController alloc] initWithURL:destUrl];
    self.safari.delegate = self;
    [self.navigationController presentViewController:self.safari animated:YES completion:^{

    }];
    return YES;
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
//    self.safari = nil;
    [self.safariController.statusButton addTarget:self action:@selector(statusAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)statusAction:(UIButton *)sender {
    [self.navigationController presentViewController:self.safari animated:YES completion:^{

    }];
}
@end
