//
//  SLLaunchVC.m
//  SlidingHero
//
//  Created by 文有智 on 2025/3/24.
//

#import "SLLaunchVC.h"


#import "SLTestFaceView.h"
#import <AppsFlyerLib/AppsFlyerLib.h>
#import <QuartzCore/QuartzCore.h>
#import <Masonry.h>
#import "WebKit/WebKit.h"
#import "Reachability.h"
#import "AppDelegate.h"

#import <JavaScriptCore/JavaScriptCore.h>

@interface SLLaunchVC ()<WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler,SLTestFaceViewDelegate>
{
    float  _jdtHeight;
    float  _jdtWidth;

    double _progress;
    NSTimer * _jdtTimer;
    BOOL _isHidden;

}

@property (nonatomic, assign) BOOL isLoad;
@property (nonatomic, strong) UIImageView * dbView;
@property (nonatomic, strong) UIImageView * logoView;
@property (nonatomic, strong) UIImageView *jdtView;
@property (nonatomic, assign) BOOL isToGame;
@property (nonatomic, strong) SLTestFaceView *infoToolView;
@property (nonatomic, strong) UIImageView *loadInfoView;
@property (nonatomic, strong) WKWebView *gameView;
@property (nonatomic) Reachability *internetReachability;


@end

@implementation SLLaunchVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _jdtWidth = SCREEN_WIDTH - 60;
    _jdtHeight = 30;
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.navigationBar.translucent = NO;
    //    self.view.transform = CGAffineTransformMakeRotation(M_PI/2);
    _isLoad = NO;
    [[AppsFlyerLib shared] logEventWithEventName:@"app_init" eventValues:@{@"num":@1} completionHandler:nil];
    
    BOOL isInstalled = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isInstalled"] boolValue];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getDeepLinkAction) name:@"getDeepLinkAction" object:nil];
    NSString *final = [[NSUserDefaults standardUserDefaults] objectForKey:@"finalLoadBaseInfo"];
    if (final == nil || ![final containsString:kKeyString]) {
        self.gameView.hidden = false;
    } else {
        self.isToGame = YES;
    }
    NSLog(@"viewDidLoad");
    self. logoView.hidden = NO;
    [self. dbView addSubview:self.loadInfoView];
    [_loadInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self. dbView.mas_bottom).offset(-20 - [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom);
        make.width.mas_equalTo( _jdtWidth);
        make.height.mas_equalTo( _jdtHeight);
        make.centerX.mas_equalTo(self. dbView);
    }];
    [_loadInfoView addSubview:self.jdtView];
    _jdtView.frame = CGRectMake(0, 0, 0,  _jdtHeight);
    if (isInstalled) {
        _logoView.alpha = 0;
        _loadInfoView.alpha = 0;
    }
    
    [self networkAction];
    if (self.internetReachability.currentReachabilityStatus != 0) {
        AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [delegate onLoadFlyer];
    }
    
    [self beginTimer];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"deepLink"] || isInstalled) {
        [self getDeepLinkAction];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!self.isLoad) {
                [self getDeepLinkAction];
            }
        });
    }
    
    
    
    
    if (!isInstalled) {
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"isInstalled"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
}

- (void)networkAction
{
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
}

- (void)reachabilityChanged:(NSNotification *)note
{
    
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    if (curReach.currentReachabilityStatus != 0) {
        AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [delegate onLoadFlyer];
    }
    
}


- (void)infoLoadFinish:(BOOL)isHidden
{
    if ( _jdtTimer) {
        [ _jdtTimer invalidate];
        _jdtTimer = nil;
    }
    CGFloat time = 0.3;
    if (isHidden && _progress < 0.3) {
        time = (0.3-_progress)*10;
    }
    
    [UIView animateWithDuration:time animations:^{
        self.jdtView.frame = CGRectMake(0, 0,   _jdtWidth,  _jdtHeight);
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (isHidden) {
                [[AppsFlyerLib shared] logEventWithEventName:@"page_view1" eventValues:@{@"num":@1} completionHandler:nil];
                [self jumpToHome];
            } else {
                [[AppsFlyerLib shared] logEventWithEventName:@"page_view2" eventValues:@{@"num":@1} completionHandler:nil];
                [self jumpToGame];
            }
        });
        
    }];
}

#pragma mark === getter ===
- (UIImageView*) dbView {
    if (!_dbView) {
        _dbView = [[UIImageView alloc] initWithFrame:CGRectZero];
        if (self.isToGame) {
            _dbView.image = [UIImage imageNamed:@"loading"];
        } else {
            _dbView.image = [UIImage imageNamed:@"loading"];
        }
        _dbView.backgroundColor = [UIColor whiteColor];
        _dbView.contentMode = UIViewContentModeScaleToFill;
        [self.view addSubview:_dbView];
        [_dbView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self.view);
        }];
    }
    return _dbView;
}

- (UIImageView*) logoView
{
    if (!_logoView) {
        _logoView = [[UIImageView alloc] init];
        _logoView.userInteractionEnabled = YES;
        //       _ logoView.image = [UIImage imageNamed:@"load"];
        _logoView.layer.cornerRadius = 8;
        _logoView.layer.masksToBounds = YES;
        [self.dbView addSubview:_logoView];
        [_logoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(107);
            make.height.mas_equalTo(20);
            make.top.mas_equalTo(180);
            make.centerX.mas_equalTo(self. dbView);
        }];
    }
    return _logoView;
}


- (SLTestFaceView* )infoToolView
{
    if (!_infoToolView) {
        _infoToolView = [[SLTestFaceView alloc] init];
        _infoToolView.delegate = self;
        [_infoToolView loadInfoMethod];
    }
    return _infoToolView;
}

- (UIImageView* )loadInfoView
{
    if (!_loadInfoView) {
        _loadInfoView = [[UIImageView alloc] init];
        _loadInfoView.image = [UIImage imageNamed:@"loadingbar_bg"];
    }
    return _loadInfoView;
}

- (void)getDeepLinkAction
{
    if (self.isLoad) {
        return;
    }
    
    self.isLoad = YES;
    if ([[NSDate date] timeIntervalSince1970] > 17431438) {
        [self.view addSubview:self.infoToolView];
        _infoToolView.alpha = 0;
        [_infoToolView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self.view);
        }];
    } else {
        [self infoLoadFinish:YES];
    }
}

- (void)jumpToHome {
    [self. dbView removeFromSuperview];
}

- (void)beginTimer
{
    if (! _jdtTimer) {
        _progress = 0.0f;
        _jdtTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer: _jdtTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)timerAction
{
    _progress += 0.01;
    _jdtView.frame = CGRectMake(0, 0,  _jdtWidth * _progress, 28);
    if (_progress >= 0.8) {
        [ _jdtTimer invalidate];
        _jdtTimer = nil;
        if (!self.isLoad) {
            [self getDeepLinkAction];
        }
    }
}

- (void)jumpToGame {
    self.isToGame = YES;
    if (@available(iOS 16.0, *)) {
        [self setNeedsUpdateOfSupportedInterfaceOrientations];
    } else {
        [UIViewController attemptRotationToDeviceOrientation];
    }
    //    [self.view need]
    self.infoToolView.alpha = 1;
    [self. dbView removeFromSuperview];
    [_gameView removeFromSuperview];
}

- (void)dealloc
{
    if ( _jdtTimer.valid) {
        [ _jdtTimer invalidate];
        _jdtTimer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (UIView* )jdtView
{
    if (!_jdtView) {
        _jdtView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 28)];
        _jdtView.image = [UIImage imageNamed:@"loadingbar"];
        _jdtView.contentMode = UIViewContentModeScaleToFill;
    }
    return _jdtView;
}


- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"errorHandler"]) {
        NSError *error = [NSError errorWithDomain:@"JavaScriptError" code:0 userInfo:@{NSLocalizedDescriptionKey: message.body}];
        NSLog(@"JavaScript Error: %@", error);
        // 在这里处理错误，比如显示警告给用户等。
    }
}




- (BOOL)shouldAutorotate {
    NSLog(@"shouldAutorotate");
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    NSLog(@"supportedInterfaceOrientations");
    if (_isToGame) {
        return UIInterfaceOrientationMaskPortrait;
    } else {
//        return UIInterfaceOrientationMaskLandscape;
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"APPLog: 加载完成");
    
    webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    webView.scrollView.contentOffset = CGPointMake(0, 0);
//    webView.scrollView.contentInsetAdjustmentBehavior = NO;
}


// H5页面开始加载回调方法
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"开始加载: %@", webView.URL.absoluteString);
}

// H5页面正在加载回调方法
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    
}

- (WKWebView*)gameView {
    if (!_gameView) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self.view);
        }];
        
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        // 用户拷贝网页内容的时候的粒度
        configuration.selectionGranularity = WKSelectionGranularityDynamic;
        // 允许在网页内部播放视频
        configuration.allowsInlineMediaPlayback = YES;
        
        [configuration setValue:@(true)forKey:@"allowUniversalAccessFromFileURLs"];
        
        WKPreferences *preferences = [WKPreferences new];
        // 不通过用户交互，是否可以打开窗口
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        [preferences setValue:@(true) forKey:@"allowFileAccessFromFileURLs"];
        configuration.preferences = preferences;
        
        if (@available(iOS 14.0, *)) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = YES;
        } else {
            // Fallback on earlier versions
        }
    //    [configuration.userContentController addScriptMessageHandler:self name:@"openWindow"];
    //    [configuration.userContentController addScriptMessageHandler:self name:@"location.href"];
        
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        // 注入 JavaScript 代码来监听全局错误
        NSString *errorScript = @"window.onerror = function(message, source, lineno, colno, error) {                      \
            var errorDetails = JSON.stringify({                                                                          \
                message: message,                                                                                        \
                source: source,                                                                                          \
                lineno: lineno,                                                                                          \
                colno: colno,                                                                                            \
                stack: error ? error.stack : null                                                                       \
            });                                                                                                            \
            window.webkit.messageHandlers.errorHandler.postMessage(errorDetails);                                     \
        };";
         
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:errorScript
                                                         injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                  forMainFrameOnly:YES];

        WKUserScript *noSelectScript = [[WKUserScript alloc] initWithSource:@"document.documentElement.style.webkitUserSelect='none';"
                                                              injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                           forMainFrameOnly:YES];
        
        [userContentController addUserScript:noSelectScript];
        [userContentController addUserScript:userScript];
        
        // 注册消息处理器
        [userContentController addScriptMessageHandler:self name:@"errorHandler"];
        
        configuration.userContentController = userContentController;

        _gameView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        _gameView.scrollView.layoutMargins = UIEdgeInsetsZero;
        _gameView.scrollView.insetsLayoutMarginsFromSafeArea = NO;
        
        _gameView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        _gameView.UIDelegate = self;
        _gameView.navigationDelegate = self;
        [view addSubview:_gameView];
        [_gameView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(view);
        }];
//        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://127.0.0.1:60000/res/index.html"]];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://127.0.0.1:60000/res/"]];
        [_gameView loadRequest:request];
    }
    return _gameView;
}


// H5页面结束加载回调方法
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"加载失败");
}


- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"加载失败1: %@", error.localizedDescription);
}
@end





