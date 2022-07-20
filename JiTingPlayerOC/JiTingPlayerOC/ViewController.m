//
//  ViewController.m
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/15.
//
// todo 显示下载进度条
// todo 下载的空文件进行标记 或者移除，如果下载的是空文件，那么当前播放的文件就变为list第一个？还是历史记录第一个？
// list 是否要根据播放记录 排序？还是存储记录排序？
#import "ViewController.h"
#import "PlayerTableViewCell.h"
#import "Masonry.h"
#import <CommonCrypto/CommonDigest.h>
#import "PlayerHeaderView.h"
@import WebKit;
@import AFNetworking;


@implementation NSFileManager (NRFileManager)

// This method calculates the accumulated size of a directory on the volume in bytes.
//
// As there's no simple way to get this information from the file system it has to crawl the entire hierarchy,
// accumulating the overall sum on the way. The resulting value is roughly equivalent with the amount of bytes
// that would become available on the volume if the directory would be deleted.
//
// Caveat: There are a couple of oddities that are not taken into account (like symbolic links, meta data of
// directories, hard links, ...).

- (BOOL)nr_getAllocatedSize:(unsigned long long *)size ofDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(size != NULL);
    NSParameterAssert(directoryURL != nil);

    // We'll sum up content size here:
    unsigned long long accumulatedSize = 0;

    // prefetching some properties during traversal will speed up things a bit.
    NSArray *prefetchedProperties = @[
        NSURLIsRegularFileKey,
        NSURLFileAllocatedSizeKey,
        NSURLTotalFileAllocatedSizeKey,
    ];

    // The error handler simply signals errors to outside code.
    __block BOOL errorDidOccur = NO;
    BOOL (^errorHandler)(NSURL *, NSError *) = ^(NSURL *url, NSError *localError) {
        if (error != NULL)
            *error = localError;
        errorDidOccur = YES;
        return NO;
    };

    // We have to enumerate all directory contents, including subdirectories.
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:directoryURL
                                                             includingPropertiesForKeys:prefetchedProperties
                                                                                options:(NSDirectoryEnumerationOptions)0
                                                                           errorHandler:errorHandler];

    // Start the traversal:
    for (NSURL *contentItemURL in enumerator) {

        // Bail out on errors from the errorHandler.
        if (errorDidOccur)
            return NO;

        // Get the type of this item, making sure we only sum up sizes of regular files.
        NSNumber *isRegularFile;
        if (! [contentItemURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:error])
            return NO;
        if (! [isRegularFile boolValue])
            continue; // Ignore anything except regular files.

        // To get the file's size we first try the most comprehensive value in terms of what the file may use on disk.
        // This includes metadata, compression (on file system level) and block size.
        NSNumber *fileSize;
        if (! [contentItemURL getResourceValue:&fileSize forKey:NSURLTotalFileAllocatedSizeKey error:error])
            return NO;

        // In case the value is unavailable we use the fallback value (excluding meta data and compression)
        // This value should always be available.
        if (fileSize == nil) {
            if (! [contentItemURL getResourceValue:&fileSize forKey:NSURLFileAllocatedSizeKey error:error])
                return NO;

            NSAssert(fileSize != nil, @"huh? NSURLFileAllocatedSizeKey should always return a value");
        }

        // We're good, add up the value.
        accumulatedSize += [fileSize unsignedLongLongValue];
    }

    // Bail out on errors from the errorHandler.
    if (errorDidOccur)
        return NO;

    // We finally got it.
    *size = accumulatedSize;
    return YES;
}

@end

@implementation NSString (fsh)

- (NSString *)SHA256 {
    const char* str = [self UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (CC_LONG)strlen(str), result);

    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    ret = (NSMutableString *)[ret uppercaseString];
    return ret;
}


@end

@implementation NSURL(fsh)

- (NSString *)title {
    NSURLComponents *coms = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    for (NSURLQueryItem *item in coms.queryItems) {
        if ([item.name isEqualToString:@"title"]) {
            return item.value;
        }
    }
    return nil;
}

@end


@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PlayerHeaderView *statusView;
@property (nonatomic, strong) NSArray *playList;
@property (nonatomic, assign) NSInteger tempRow;
@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, strong) UIProgressView *proView;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"播放列表";
    self.tempRow = -1;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    self.view.backgroundColor = UIColor.whiteColor;
    self.playList = [NSUserDefaults.standardUserDefaults arrayForKey:@"playList"];
    [self.view addSubview:self.tableView];
    [self.tableView registerNib:[UINib nibWithNibName:@"PlayerTableViewCell" bundle:nil] forCellReuseIdentifier:@"PlayerTableViewCell"];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-60);
        make.top.leading.trailing.equalTo(self.view);
    }];
    self.statusView = [[PlayerHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    [self.view addSubview:self.statusView];
    [self.statusView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@(60));
    }];

    self.proView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [self.view addSubview:self.proView];
    [self.proView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-60);
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@(6));
    }];
    //    self.statusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //    self.statusButton.backgroundColor = UIColor.greenColor;
    //    self.statusButton.layer.cornerRadius = 8;
    //    self.statusButton.layer.masksToBounds = YES;
    //    [self.view addSubview:self.statusButton];
    //    self.statusButton.frame = CGRectMake(0, 0, 100, 100);
    //    self.statusButton.center = self.view.center;
    //    [self.statusButton addTarget:UIApplication.sharedApplication.delegate action:@selector(statusAction:) forControlEvents:UIControlEventTouchUpInside];
    [self loadAction:nil];
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UIAlertController *editRadiusAlert = [UIAlertController alertControllerWithTitle:@"清理缓存"
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *playSafariAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"清理Document %@", [self calculateCache:NSDocumentDirectory]] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *err = nil;
            NSURL *docUrl = [fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&err];
            [fileManager removeItemAtURL:docUrl error:&err];
        }];
        [editRadiusAlert addAction:playSafariAction];

        UIAlertAction *cacheAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"清理Cache %@", [self calculateCache:NSCachesDirectory]] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *err = nil;
            NSURL *docUrl = [fileManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&err];
            [fileManager removeItemAtURL:docUrl error:&err];
        }];
        [editRadiusAlert addAction:cacheAction];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
        }];
        [editRadiusAlert addAction:cancelAction];
        [self presentViewController:editRadiusAlert animated:YES completion:^{

        }];
    }];
    UIBarButtonItem *leftbarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash primaryAction:action];
    self.navigationItem.leftBarButtonItem = leftbarButton;
    
}

- (NSString *)calculateCache:(NSSearchPathDirectory)enukey {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err = nil;
    NSURL *docUrl = [fileManager URLForDirectory:enukey inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&err];

    unsigned long long folderSize = 0;
    [NSFileManager.defaultManager nr_getAllocatedSize:&folderSize ofDirectoryAtURL:docUrl error:&err];
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];
    return folderSizeStr;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    for (NSData *data in self.playList) {
        NSURL *url = [NSURL URLWithDataRepresentation:data relativeToURL:nil];
        NSLog(@"%@", url);
    }
    if (self.playList.count == 0) {
        UIAlertController *editRadiusAlert = [UIAlertController alertControllerWithTitle:@"去添加" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *playSafariAction = [UIAlertAction actionWithTitle:@"打开备忘录" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"mobilenotes://"] options:@{} completionHandler:^(BOOL success) {

            }];
        }];
        [editRadiusAlert addAction:playSafariAction];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
        }];
        [editRadiusAlert addAction:cancelAction];
        [self presentViewController:editRadiusAlert animated:YES completion:^{

        }];
    }
}

- (void)loadAction:(NSString *)sender {
    NSURL *destUrl = [NSUserDefaults.standardUserDefaults URLForKey:@"destUrl"];
    if (!destUrl) {
        return;
    }
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSURL *ret = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [destUrl.path SHA256]]];
    if ([NSFileManager.defaultManager fileExistsAtPath:ret.path]) {
        NSDictionary<NSFileAttributeKey, id> *att =  [NSFileManager.defaultManager attributesOfItemAtPath:ret.path error:nil];
        NSNumber *sizeNumber = att[NSFileSize];
        if (sizeNumber.longValue == 0) {
            NSLog(@"File empty not play");
            // 应该alert移除这一条记录
            return;
        }
        NSURLComponents *coms = [NSURLComponents componentsWithURL:destUrl resolvingAgainstBaseURL:NO];
        NSURLComponents *retcoms = [NSURLComponents componentsWithURL:ret resolvingAgainstBaseURL:NO];
        retcoms.fragment = coms.fragment;
        [self.statusView updateWebviewUrl:retcoms.URL];
    } else {
        NSURLRequest *request = [NSURLRequest requestWithURL:destUrl];
        NSURLSessionDownloadTask *downloadTask = [self.manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {

        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            return ret;
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            if (error) {
                return;
            }
            NSDictionary<NSFileAttributeKey, id> *att =  [NSFileManager.defaultManager attributesOfItemAtPath:filePath.path error:nil];
            NSNumber *sizeNumber = att[NSFileSize];
            if (sizeNumber.longValue == 0) {
                NSLog(@"File empty downloaded");
                // 应该alert移除这一条记录
                return;
            }
            NSLog(@"File downloaded to: %@", filePath);
            [self.statusView updateWebviewUrl:filePath];
        }];
        [self.proView setProgressWithDownloadProgressOfTask:downloadTask animated:YES];
        [downloadTask resume];
    }
    if (sender.length > 0) {
        self.playList = [NSUserDefaults.standardUserDefaults arrayForKey:@"playList"];
        [self.tableView reloadData];
    }
}

- (void)statusAction:(UIButton *)sender {
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%ld", (long)row];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 100;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

#pragma mark - tableView lazy
-(UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = UIColor.whiteColor;
    }
    return _tableView;
}

#pragma mark - tableView UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.playList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PlayerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlayerTableViewCell" forIndexPath:indexPath];
    NSData *data = [self.playList objectAtIndex:indexPath.row];
    NSURL *url = [NSURL URLWithDataRepresentation:data relativeToURL:nil];
    if (url.title) {
        cell.nameLabel.text = [url.title stringByAppendingFormat:@"#%@", url.fragment?:@""];;
    } else if (url.fragment) {
        cell.nameLabel.text = [url.path stringByAppendingFormat:@"#%@", url.fragment];
    } else {
        cell.nameLabel.text = url.path;
    }
    cell.nameLabel.numberOfLines = 0;
    cell.contentView.backgroundColor = UIColor.whiteColor;
    NSURL *destUrl = [NSUserDefaults.standardUserDefaults URLForKey:@"destUrl"];
    if ([destUrl.path isEqualToString:url.path]) {
        cell.contentView.backgroundColor = [UIColor colorWithRed:0xbb/255.0 green:0xff/255.0 blue:0xaa/255.0 alpha:1];
    }
    cell.pickerView.delegate = self;
    cell.pickerView.dataSource = self;
    return cell;
}

#pragma mark - tableView--UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSData *data = [self.playList objectAtIndex:indexPath.row];
    NSURL *url = [NSURL URLWithDataRepresentation:data relativeToURL:nil];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.preferredContentSize = CGSizeMake(self.view.bounds.size.width, 200);
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    [vc.view addSubview:pickerView];
    NSURLComponents *coms = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *title = @"操作";
    NSString *tTime = @"";
    for (NSURLQueryItem *item in coms.queryItems) {
        if ([item.name isEqualToString:@"title"]) {
            title = item.value;
        }
    }

    UIAlertController *editRadiusAlert = [UIAlertController alertControllerWithTitle:title message:tTime preferredStyle:UIAlertControllerStyleActionSheet];
    [editRadiusAlert setValue:vc forKey:@"contentViewController"];
    UIAlertAction *playAction = [UIAlertAction actionWithTitle:@"直接播放" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [NSUserDefaults.standardUserDefaults setURL:url forKey:@"destUrl"];
        [self.statusView updateWebview];
        [self loadAction:@"playListPlay"];
    }];
    [editRadiusAlert addAction:playAction];

    UIAlertAction *playSafariAction = [UIAlertAction actionWithTitle:@"Safari播放" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {

        }];
    }];
    [editRadiusAlert addAction:playSafariAction];

    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        if (self.tempRow >= 0) {
            coms.fragment = [NSString stringWithFormat:@"t=%ld", (long)self.tempRow * 60];
            NSURL *modifyUrl = coms.URL;
            NSMutableArray *mut = self.playList.mutableCopy;
            mut[indexPath.row] = [modifyUrl dataRepresentation];
            [NSUserDefaults.standardUserDefaults setURL:modifyUrl forKey:@"destUrl"];
            [NSUserDefaults.standardUserDefaults setObject:mut forKey:@"playList"];
            [self.statusView updateWebview];
            [self loadAction:@"playListModify"];
            self.tempRow = -1;
        }
    }];
    [editRadiusAlert addAction:doneAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
    }];
    [editRadiusAlert addAction:cancelAction];
    [self presentViewController:editRadiusAlert animated:YES completion:^{
        [self.tableView reloadData];
    }];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSLog(@"didSelectRow:%ld", row);
    self.tempRow = row;
}

@end
