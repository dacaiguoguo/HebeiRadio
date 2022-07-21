//
//  PlayerHeaderView.h
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PlayerHeaderView;
@class RadioItem;
@protocol PlayerHeaderViewDelegate <NSObject>

- (void)view:(PlayerHeaderView *)view didReceiveScriptMessage:(NSString *)message;

@end

@interface PlayerHeaderView : UIView
@property (nonatomic, strong) RadioItem *item;
@property (nonatomic, weak) NSObject<PlayerHeaderViewDelegate> *delegate;
- (void)updateWebview;
- (void)stopTimer;
- (void)playItem:(RadioItem *)item;
@end

NS_ASSUME_NONNULL_END
