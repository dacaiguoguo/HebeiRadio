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
@import WebKit;
@import AFNetworking;
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

@interface PlayerHeaderView ()<WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *contentWebView;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSURL *pUrl;
- (void)updateWebview;
- (void)updateWebviewUrl:(NSURL *)url;
@end

@implementation PlayerHeaderView
- (void)updateWebviewUrl:(NSURL *)url {
    self.pUrl = url;
    [self.contentWebView loadRequest:[NSURLRequest requestWithURL:self.pUrl]];
}

- (void)updateWebview {
    [self.contentWebView removeFromSuperview];
    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.websiteDataStore = dataStore;
    config.allowsInlineMediaPlayback = YES;
    [config.userContentController addScriptMessageHandler:self name:@"lvJSCallNativeHandler"];
    config.processPool = [[WKProcessPool alloc] init];
    self.contentWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 100, self.bounds.size.width, 100) configuration:config];
    [self addSubview:self.contentWebView];
    [self.contentWebView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    self.backgroundColor = UIColor.darkGrayColor;
    self.contentWebView.backgroundColor = UIColor.darkGrayColor;
    self.contentWebView.opaque = NO;
    self.contentWebView.scrollView.backgroundColor = UIColor.darkGrayColor;
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self.contentWebView evaluateJavaScript:@"var temp = window.webkit.messageHandlers.lvJSCallNativeHandler.postMessage(`${document.getElementsByTagName('video')[0].currentTime}`)"
                              completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
//            NSLog(@"completionHandler:%@", obj);
        }];
    }];
    // https://developer.mozilla.org/zh-CN/docs/Web/HTML/Element/audio#属性
    // document.getElementsByTagName('video')[0].currentTime = 120; 可以直接修改
    // 可以用设置src来修改播放的文件，这样就不用更换的时候就重新创建webview了
    // document.getElementsByTagName('video')[0].src = "file:///Users/sunyanguo/Library/Developer/CoreSimulator/Devices/9856E35E-2A9F-4A9D-8B19-5EBD7C9D5CB8/data/Containers/Data/Application/C37EFEEE-F99A-4C7B-A9A6-A7C467B0AD46/Documents/59534E492EF1981126AE865C6BC8C569C2D600B3361B2CAF6F770E470320C1F6.mp4"
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"didReceiveScriptMessage:%@", message.body);
    NSString *bodys = message.body;
    NSURL *destUrl = [NSUserDefaults.standardUserDefaults URLForKey:@"destUrl"];
    NSURLComponents *coms = [NSURLComponents componentsWithURL:destUrl resolvingAgainstBaseURL:NO];
    coms.fragment = [NSString stringWithFormat:@"t=%d", bodys.intValue];
    NSURL *modifyUrl = coms.URL;
    [NSUserDefaults.standardUserDefaults setURL:modifyUrl forKey:@"destUrl"];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self updateWebview];
        self.backgroundColor = UIColor.darkGrayColor;
    }
    return self;
}

@end

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PlayerHeaderView *statusView;
@property (nonatomic, strong) NSArray *playList;
@property (nonatomic, assign) NSInteger tempRow;
@end

@implementation ViewController {
    AFURLSessionManager *manager;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    for (NSData *data in self.playList) {
        NSURL *url = [NSURL URLWithDataRepresentation:data relativeToURL:nil];
        NSLog(@"%@", url);
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tempRow = -1;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    self.view.backgroundColor = UIColor.whiteColor;
    self.playList = [NSUserDefaults.standardUserDefaults arrayForKey:@"playList"];
    [self.view addSubview:self.tableView];
    [self.tableView registerNib:[UINib nibWithNibName:@"PlayerTableViewCell" bundle:nil] forCellReuseIdentifier:@"PlayerTableViewCell"];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(60);
        make.top.leading.trailing.equalTo(self.view);
    }];
    self.statusView = [[PlayerHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    [self.view addSubview:self.statusView];
    [self.statusView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@(60));
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
        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
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
