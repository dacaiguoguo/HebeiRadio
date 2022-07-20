//
//  CategoryTool.h
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CategoryTool : NSObject

@end

@interface NSFileManager (NRFileManager)
- (BOOL)nr_getAllocatedSize:(unsigned long long *)size ofDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)error;

@end

@interface NSString (fsh)
- (NSString *)SHA256;
@end

@interface NSURL(fsh)
- (NSString *)title;
@end

NS_ASSUME_NONNULL_END
