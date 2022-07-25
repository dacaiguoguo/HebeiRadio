//
//  PlayerTableViewCell.h
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PlayerTableViewCell;
@protocol PlayerTableViewCellDelegate <NSObject>

- (void)cell:(PlayerTableViewCell *)cell infoAction:(id)sender;

@end
@interface PlayerTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic, weak) NSObject<PlayerTableViewCellDelegate> *delegate;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
- (IBAction)infoAction:(id)sender;
@property (strong, nonatomic) IBOutlet UIPickerView *pickerView;

@end

NS_ASSUME_NONNULL_END
