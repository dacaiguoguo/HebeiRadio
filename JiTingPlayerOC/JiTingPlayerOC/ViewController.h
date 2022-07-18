//
//  ViewController.h
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/15.
//

#import <UIKit/UIKit.h>
@interface PlayerHeaderView: UIView

@end
@interface ViewController : UIViewController
@property (nonatomic, strong) UIButton *statusButton;
- (void)loadAction:(NSString *)sender;
@end

