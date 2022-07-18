//
//  ViewController.m
//  JiTingPlayerOC
//
//  Created by yanguo sun on 2022/7/15.
//

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
        [self.contentWebView evaluateJavaScript:@"window.webkit.messageHandlers.lvJSCallNativeHandler.postMessage(`${document.getElementsByTagName('video')[0].currentTime}`)"
                              completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
            NSLog(@"%@", obj);
        }];
    }];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    // NSLog(@"didReceiveScriptMessage:%@", message.body);
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

    self.statusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.statusButton.backgroundColor = UIColor.greenColor;
    self.statusButton.layer.cornerRadius = 8;
    self.statusButton.layer.masksToBounds = YES;
    [self.view addSubview:self.statusButton];
    self.statusButton.frame = CGRectMake(0, 0, 100, 100);
    self.statusButton.center = self.view.center;
    [self.statusButton addTarget:UIApplication.sharedApplication.delegate action:@selector(statusAction:) forControlEvents:UIControlEventTouchUpInside];
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
    cell.nameLabel.text = [url.absoluteString substringFromIndex:@"http://vod.fm.hebrbtv.com:9600/vod2/xw/".length];
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
