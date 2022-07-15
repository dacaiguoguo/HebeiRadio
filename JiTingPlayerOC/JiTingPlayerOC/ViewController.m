//
//  ViewController.m
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/15.
//

#import "ViewController.h"

@interface ViewController ()

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
}



@end
