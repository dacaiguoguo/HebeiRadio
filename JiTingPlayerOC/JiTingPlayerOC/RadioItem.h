//
//  RadioItem.h
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadioItem : NSObject<NSCoding, NSCopying>
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSDate *addTime;
@property (nonatomic, copy) NSDate *playTime;
@property (nonatomic, copy) NSString *info;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *pathSHA256;
@property (nonatomic, copy) NSNumber *duration;
@property (nonatomic, copy) NSString *currentTime;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSURL *urlAtTime;
@property (nonatomic, readonly) NSURL *documentURL;
@property (nonatomic, copy) NSNumber *size;
@property (nonatomic, assign) BOOL done;
- (NSString *)showTimes;
@end

NS_ASSUME_NONNULL_END
