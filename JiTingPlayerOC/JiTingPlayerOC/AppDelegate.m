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
    NSLog(@"sourceApplication:%@", sourceApplication);
    NSURLComponents *com = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    com.scheme = @"http";
    NSURL *destUrl = com.URL;
    [[PINCache sharedCache] setObject:destUrl forKey:@"destUrl"];
    [self.safariController loadAction:destUrl];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {

}
@end
