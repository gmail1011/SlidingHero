//
//  AppDelegate.m
//  JungleRateAbby
//
//  Created by   on 2025/3/11.
//

#import "AppDelegate.h"



#import "SLLaunchVC.h"
#import <AppsFlyerLib/AppsFlyerLib.h>
#import "HTTPServer.h"
#import "ZipArchive.h"
#import "Reachability.h"
#import <GCDWebServer/GCDWebServer.h>
@import UserNotifications;
@import FirebaseCore;
@import FirebaseMessaging;

@interface AppDelegate ()<UNUserNotificationCenterDelegate, FIRMessagingDelegate, AppsFlyerLibDelegate, AppsFlyerDeepLinkDelegate>
@property (nonatomic,copy) HTTPServer *httpServer;
@property (nonatomic,copy) GCDWebServer *webServer;

@property (nonatomic) Reachability *internetReachability;
@property (nonatomic, assign) BOOL isInitAppflyer;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    self.window.rootViewController = [[SLLaunchVC alloc] init];

    _isInitAppflyer = NO;

    
    [FIRApp configure];
    [FIRMessaging messaging].delegate = self;
    
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert |
        UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    [[UNUserNotificationCenter currentNotificationCenter]
        requestAuthorizationWithOptions:authOptions
        completionHandler:^(BOOL granted, NSError * _Nullable error) {
          // ...
        }];

    [application registerForRemoteNotifications];
    
    _httpServer = [[HTTPServer alloc] init];
    [_httpServer setType:@"_http._tcp."];
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"res" ofType:@"zip"];
    
    NSArray *documentArray =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *webPath = [documentArray firstObject];
//    [[documentArray lastObject] stringByAppendingPathComponent:@"Caches"];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *dstPath = [webPath stringByAppendingPathComponent:@"res.zip"];
    if (![manager fileExistsAtPath:dstPath]) {
        BOOL ret = [manager copyItemAtPath:sourcePath toPath:dstPath error:nil];
        NSLog(@"拷贝文件结果 %@", @(ret));
        ZipArchive *zip = [[ZipArchive alloc] init];
        if ([zip UnzipOpenFile:dstPath]) {
//            NSString *targetPath = [webPath stringByAppendingPathComponent:@"Resources"];
            BOOL res = [zip UnzipFileTo:webPath overWrite:YES];
            if (res) {
                NSLog(@"解压成功");
            }
        }
    }
    NSLog(@"Setting document root: %@", webPath);
//    [_httpServer setDocumentRoot:webPath];
//    [_httpServer setPort:60000];
//        [self startAppLoad];
    _webServer = [[GCDWebServer alloc] init];
    [_webServer addGETHandlerForBasePath:@"/" directoryPath:webPath indexFilename:@"index.html" cacheAge:3600 allowRangeRequests:YES];
    [_webServer startWithPort:60000 bonjourName:nil];

    return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)onLoadFlyer {
    [[AppsFlyerLib shared] setAppsFlyerDevKey:@"EPbAJt9ezPQE7dWFX3dmBK"];
    [[AppsFlyerLib shared] setAppleAppID:@"6743694669"];
    [AppsFlyerLib shared].delegate = self;
    [AppsFlyerLib shared].deepLinkDelegate = self;
    [[AppsFlyerLib shared] setAppInviteOneLink:@"C8UB"];
    [[AppsFlyerLib shared] startWithCompletionHandler:nil];
}

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    NSLog(@"FCM registration token: %@", fcmToken);
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:fcmToken forKey:@"token"];
    [[NSNotificationCenter defaultCenter] postNotificationName:
     @"FCMToken" object:nil userInfo:dataDict];
}


- (void)onConversionDataFail:(nonnull NSError *)error {
    NSLog(@"appflyer delegate error : %@ ", error);
}

- (void)onConversionDataSuccess:(nonnull NSDictionary *)conversionInfo {
    NSLog(@"appflyer delegate success : %@ ", conversionInfo);
}

- (void)onAppOpenAttribution:(NSDictionary *)attributionData
{
    NSLog(@"appflyer onAppOpenAttribution : %@ ", attributionData);

}

- (void)onAppOpenAttributionFailure:(NSError *)error
{
    NSLog(@"appflyer onAppOpenAttribution error : %@ ", error);

}

- (void)didResolveDeepLink:(AppsFlyerDeepLinkResult *)result
{
    NSLog(@"APPLog: didResolveDeepLink  %zi   |  %@", result.status, result.deepLink.deeplinkValue);
    if (result.deepLink.deeplinkValue.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:result.deepLink.deeplinkValue forKey:@"deepLink"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"getDeepLinkAction" object:nil userInfo:nil];

}

- (void)startAppLoad
{
    // Start the server (and check for problems)
    
    NSError *error;
    if([_httpServer start:&error])
    {
        NSLog(@"Started HTTP Server on port %hu", [_httpServer listeningPort]);
    }
    else
    {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}

@end


