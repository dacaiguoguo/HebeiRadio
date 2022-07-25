//
//  ViewController.m
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/15.
//
// todo 显示下载进度条并且name,
// todo 打开后 当前播放显示上一次的状态
// list 是否要根据播放记录 排序？还是存储记录排序？ 已经播放完的 添加显示全部筛选按钮
// 添加应用前后台切换逻辑
#import "ViewController.h"
#import "PlayerTableViewCell.h"
#import "PlayerHeaderView.h"
#import "RadioItem.h"
#import "CategoryTool.h"
@import Masonry;
@import ReactiveObjC;
@import WebKit;
@import AFNetworking;
@import PINCache;
@import AVFoundation;

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, PlayerHeaderViewDelegate, PlayerTableViewCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PlayerHeaderView *statusView;
@property (nonatomic, strong) NSArray *playList;
@property (nonatomic, assign) NSInteger tempRow;
@property (nonatomic, assign) NSInteger rowCount;
@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, strong) UIProgressView *proView;
@end

@implementation ViewController

- (void)view:(PlayerHeaderView *)view didReceiveScriptMessage:(NSString *)message {
    RadioItem *find = view.item;
    self.title = find.name;
    if (!find.duration) {
        AVURLAsset *dsds = [[AVURLAsset alloc] initWithURL:find.documentURL options:@{}];
        find.duration = @(CMTimeGetSeconds(dsds.duration));
    }
    find.currentTime = [NSString stringWithFormat:@"%ld", message.integerValue];
    if (labs(message.integerValue - find.duration.integerValue) < 1) {
        [view stopTimer];
        find.done = YES;
        [self.tableView reloadData];
    }
    [[PINCache sharedCache] setObject:self.playList forKey:@"playHistory"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"播放列表";

    self.tempRow = -1;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    self.view.backgroundColor = UIColor.whiteColor;
    self.playList = [[PINCache sharedCache] objectForKey:@"playHistory"];
    [self.view addSubview:self.tableView];
    [[RACObserve(self, playList) distinctUntilChanged] subscribeNext:^(id  _Nullable x) {
        [self.tableView reloadData];
    }];

    [self.tableView registerNib:[UINib nibWithNibName:@"PlayerTableViewCell" bundle:nil] forCellReuseIdentifier:@"PlayerTableViewCell"];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-60);
        make.top.leading.trailing.equalTo(self.view);
    }];
    self.statusView = [[PlayerHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    [self.view addSubview:self.statusView];
    self.statusView.delegate = self;
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
    self.proView.hidden = YES;
    NSURL *lastUrl = [[PINCache sharedCache] objectForKey:@"destUrl"];
    [self loadAction:lastUrl];
    [self addClearButton];
}

- (void)addClearButton {
    UIAction *action = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UIAlertController *removeAlert = [UIAlertController alertControllerWithTitle:@"清理缓存"
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *removeDocumentAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"清理Document %@", [self calculateCache:NSDocumentDirectory]] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *err = nil;
            NSURL *docUrl = [fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&err];
            [fileManager removeItemAtURL:docUrl error:&err];
        }];
        [removeAlert addAction:removeDocumentAction];

        UIAlertAction *cacheAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"清理Cache %@", [self calculateCache:NSCachesDirectory]] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *err = nil;
            NSURL *docUrl = [fileManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&err];
            [fileManager removeItemAtURL:docUrl error:&err];
        }];
        [removeAlert addAction:cacheAction];

        NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:[PINCache.sharedCache diskCache].byteCount countStyle:NSByteCountFormatterCountStyleFile];

        UIAlertAction *cacheRecordAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"清理记录 %@", folderSizeStr] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [PINCache.sharedCache removeAllObjects];
        }];
        [removeAlert addAction:cacheRecordAction];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
        }];
        [removeAlert addAction:cancelAction];
        [self presentViewController:removeAlert animated:YES completion:^{

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
    for (RadioItem *data in self.playList) {
        NSLog(@"%@", data);
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

- (RadioItem *)lastItem {
    if (self.playList.count == 0) {
        return nil;
    }
    NSMutableArray<RadioItem *> *allPlayedItems = [NSMutableArray array];
    for (RadioItem *item in self.playList) {
        if (item.playTime) {
            [allPlayedItems addObject:item];
        }
    }
    NSArray<RadioItem *> *allPlayedItemsSorted = [allPlayedItems sortedArrayUsingComparator:^NSComparisonResult(RadioItem *obj1, RadioItem *obj2) {
        return [obj1.playTime compare:obj2.playTime];
    }];
    return allPlayedItemsSorted.firstObject;
}

- (void)loadAction:(NSURL *)destUrl {
    if (!destUrl) {
        return;
    }
    NSArray<RadioItem *> *array = [[PINCache sharedCache] objectForKey:@"playHistory"];
    BOOL hasAdd = NO;
    for (RadioItem *data in array) {
        if ([data.path isEqualToString:destUrl.path]) {
            NSURL *docUrl = data.documentURL;
            hasAdd = YES;
            if ([NSFileManager.defaultManager fileExistsAtPath:docUrl.path]) {
                NSDictionary<NSFileAttributeKey, id> *att =  [NSFileManager.defaultManager attributesOfItemAtPath:docUrl.path error:nil];
                NSNumber *sizeNumber = att[NSFileSize];
                if (sizeNumber.longValue == 0) {
                    NSLog(@"File empty not play");
                    // 应该alert移除
                    UIAlertController *editRadiusAlert = [UIAlertController alertControllerWithTitle:@"文件为空" message:nil preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
                        [[PINCache sharedCache] removeObjectForKey:@"destUrl"];
                    }];
                    [editRadiusAlert addAction:cancelAction];
                    [self presentViewController:editRadiusAlert animated:YES completion:^{

                    }];
                    return;
                }
                [self.statusView playItem:data];
            } else {
                [self downloadUrl:destUrl];
            }
        }
    }

    if (!hasAdd) {
        [self downloadUrl:destUrl];
    }
}

- (void)downloadUrl:(NSURL *)destUrl {
    NSURLRequest *request = [NSURLRequest requestWithURL:destUrl];
    NSURLSessionDownloadTask *downloadTask = [self.manager downloadTaskWithRequest:request
                                                                          progress:^(NSProgress * _Nonnull downloadProgress) {
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        NSURL *saveUrl = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", destUrl.path.SHA256]];
        return saveUrl;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        [[PINCache sharedCache] removeObjectForKey:@"destUrl"];
        self.proView.hidden = YES;
        if (error) {
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"请求报错" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [errorAlert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {}]];
            [self presentViewController:errorAlert animated:YES completion:^{}];
            return;
        }
        NSDictionary<NSFileAttributeKey, id> *att =  [NSFileManager.defaultManager attributesOfItemAtPath:filePath.path error:nil];
        NSNumber *sizeNumber = att[NSFileSize];
        if (sizeNumber.longValue == 0) {
            NSLog(@"File empty downloaded");
            // 应该alert移除
            UIAlertController *emptyAlert = [UIAlertController alertControllerWithTitle:@"文件为空" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [emptyAlert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {}]];
            [self presentViewController:emptyAlert animated:YES completion:^{}];
            return;
        }
        NSLog(@"File downloaded to: %@", filePath);
        RadioItem *item = [[RadioItem alloc] init];
        item.url = destUrl;
        item.duration = @(CMTimeGetSeconds([AVURLAsset URLAssetWithURL:item.documentURL options:@{}].duration));
        item.size = sizeNumber;
        item.addTime = NSDate.date;
        item.playTime = item.addTime;
        item.currentTime = @"0";
        NSMutableArray *mut = self.playList.mutableCopy;
        if (!mut) {
            mut = [NSMutableArray array];
        }
        [mut insertObject:item atIndex:0];
        [[PINCache sharedCache] setObject:mut forKey:@"playHistory"];
        self.playList = mut;
        [self.statusView playItem:item];
    }];
    [self.proView setProgress:0];
    self.proView.hidden = NO;
    [self.proView setProgressWithDownloadProgressOfTask:downloadTask animated:YES];
    [downloadTask resume];
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%ld", (long)row];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.rowCount;
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
    RadioItem *data = [self.playList objectAtIndex:indexPath.row];
    cell.nameLabel.numberOfLines = 0;
    if (data.done) {
        cell.nameLabel.text = [NSString stringWithFormat:@"*%@#%@", data.name, [data currentTimeShowStr]];;
    } else {
        cell.nameLabel.text = [NSString stringWithFormat:@"%@#%@", data.name, [data currentTimeShowStr]];;
    }
    if ([data.path isEqualToString:self.statusView.item.path]) {
        [cell.playButton setImage:[UIImage systemImageNamed:@"pause"] forState:UIControlStateNormal];
        cell.contentView.backgroundColor = [UIColor colorWithRed:0xbb/255.0 green:0xff/255.0 blue:0xaa/255.0 alpha:1];
    } else {
        [cell.playButton setImage:[UIImage systemImageNamed:@"play"] forState:UIControlStateNormal];
        cell.contentView.backgroundColor = UIColor.whiteColor;
    }

    cell.delegate = self;
    cell.pickerView.delegate = self;
    cell.pickerView.dataSource = self;
    return cell;
}

- (void)cell:(PlayerTableViewCell *)cell infoAction:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    RadioItem *data = [self.playList objectAtIndex:indexPath.row];
    if ([data.path isEqualToString:self.statusView.item.path]) {
        [cell.playButton setImage:[UIImage systemImageNamed:@"play"] forState:UIControlStateNormal];
        cell.contentView.backgroundColor = [UIColor colorWithRed:0xbb/255.0 green:0xff/255.0 blue:0xaa/255.0 alpha:1];
    } else {
        [cell.playButton setImage:[UIImage systemImageNamed:@"pause"] forState:UIControlStateNormal];
        [self.statusView playItem:data];
    }
    [self.tableView reloadData];
}

#pragma mark - tableView--UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RadioItem *data = [self.playList objectAtIndex:indexPath.row];
    NSURL *url = data.url;
    self.rowCount = data.duration.intValue / 60;
    UIViewController *vc = [[UIViewController alloc] init];
    vc.preferredContentSize = CGSizeMake(self.view.bounds.size.width, 200);
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    [vc.view addSubview:pickerView];

    NSString *title = data.name;

    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"从此播放" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        if (self.tempRow >= 0) {
            data.currentTime = [NSString stringWithFormat:@"%ld", (long)self.tempRow * 60];
            [self.statusView updateWebview];
            [self.statusView playItem:data];
            [[PINCache sharedCache] setObject:self.playList forKey:@"playHistory"];
            [self.tableView reloadData];
            self.tempRow = -1;
        }
    }];
    UIAlertController *actionAlert = [UIAlertController alertControllerWithTitle:title message:data.currentTime preferredStyle:UIAlertControllerStyleActionSheet];
    [actionAlert addAction:doneAction];

    [actionAlert setValue:vc forKey:@"contentViewController"];
    UIAlertAction *playAction = [UIAlertAction actionWithTitle:@"直接播放" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [self.statusView playItem:data];
        [self.tableView reloadData];
    }];
    [actionAlert addAction:playAction];

    UIAlertAction *playSafariAction = [UIAlertAction actionWithTitle:@"Safari播放" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {

        }];
    }];
    [actionAlert addAction:playSafariAction];


    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
    }];
    [actionAlert addAction:cancelAction];
    [self presentViewController:actionAlert animated:YES completion:^{
        [self.tableView reloadData];
    }];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSLog(@"didSelectRow:%ld", row);
    self.tempRow = row;
}

@end
