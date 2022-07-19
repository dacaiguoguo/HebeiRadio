//
//  PlayerHeaderView.h
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerHeaderView : UIView
- (void)updateWebview;
- (void)updateWebviewUrl:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
