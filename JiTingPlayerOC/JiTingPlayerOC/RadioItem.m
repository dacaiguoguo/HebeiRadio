//
//  RadioItem.m
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/20.
//

#import "RadioItem.h"
#import "CategoryTool.h"

@implementation RadioItem
#pragma mark - NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    if (!self) {
        return nil;
    }
    self.url = [NSURL URLWithDataRepresentation:[decoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(url))] relativeToURL:nil];
    self.addTime = [decoder decodeObjectOfClass:[NSDate class] forKey:NSStringFromSelector(@selector(addTime))];
    self.playTime = [decoder decodeObjectOfClass:[NSDate class] forKey:NSStringFromSelector(@selector(playTime))];
    self.info = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(info))];
    self.name = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(name))];
    self.pathSHA256 = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(pathSHA256))];
    self.duration = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(duration))];
    self.currentTime = [decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(currentTime))];
    self.size = [decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(size))];
    self.empty = [decoder decodeBoolForKey:NSStringFromSelector(@selector(empty))];
    return self;
}

- (NSString *)path {
    return self.url.path;
}

- (NSURL *)documentURL {
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSURL *ret = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", self.path.SHA256]];
    return ret;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[self.url dataRepresentation] forKey:NSStringFromSelector(@selector(url))];
    [coder encodeObject:self.addTime forKey:NSStringFromSelector(@selector(addTime))];
    [coder encodeObject:self.playTime forKey:NSStringFromSelector(@selector(playTime))];
    [coder encodeObject:self.info forKey:NSStringFromSelector(@selector(info))];
    [coder encodeObject:self.name forKey:NSStringFromSelector(@selector(name))];
    [coder encodeObject:self.pathSHA256 forKey:NSStringFromSelector(@selector(pathSHA256))];
    [coder encodeObject:self.duration forKey:NSStringFromSelector(@selector(duration))];
    [coder encodeObject:self.currentTime forKey:NSStringFromSelector(@selector(currentTime))];
    [coder encodeObject:self.size forKey:NSStringFromSelector(@selector(size))];
    [coder encodeBool:self.empty forKey:NSStringFromSelector(@selector(empty))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    RadioItem *serializer = [self copyWithZone:zone];
    serializer.url = self.url;
    serializer.addTime = self.addTime;
    serializer.playTime = self.playTime;
    serializer.info = self.info;
    serializer.name = self.name;
    serializer.pathSHA256 = self.pathSHA256;
    serializer.duration = self.duration;
    serializer.currentTime = self.currentTime;
    serializer.size = self.size;
    serializer.empty = self.empty;
    return serializer;
}

- (NSURL *)urlAtTime {
    NSURLComponents *coms = [NSURLComponents componentsWithURL:self.documentURL resolvingAgainstBaseURL:NO];
    coms.fragment = [NSString stringWithFormat:@"t=%@", self.currentTime];
    return coms.URL;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"name:%@ url:%@ currentTime:%@", _name, _url, _currentTime];
}

- (NSString *)times {
    int interval = self.currentTime.intValue;
    NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
    NSCalendar *calendar = NSCalendar.currentCalendar;
    calendar.locale = [NSLocale localeWithLocaleIdentifier:@"zh_Hans_CN"];//(identifier: "en_US_POSIX")
    formatter.calendar = calendar;
//    formatter.allowedUnits = NSCalendarUnitMinute;
    formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
    NSString *formattedString = [formatter stringFromTimeInterval:interval];
    return formattedString;
}
@end
