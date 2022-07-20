//
//  PlayerTableViewCell.h
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
- (IBAction)infoAction:(id)sender;
@property (strong, nonatomic) IBOutlet UIPickerView *pickerView;

@end

NS_ASSUME_NONNULL_END
