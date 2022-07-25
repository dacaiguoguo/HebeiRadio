//
//  PlayerTableViewCell.m
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/18.
//

#import "PlayerTableViewCell.h"

@implementation PlayerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.playButton setImage:[UIImage systemImageNamed:@"play"] forState:UIControlStateNormal];
    self.playButton.layer.borderColor = UIColor.darkGrayColor.CGColor;
    self.playButton.layer.borderWidth = 1;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)infoAction:(id)sender {
    [self.delegate cell:self infoAction:sender];
}
@end
