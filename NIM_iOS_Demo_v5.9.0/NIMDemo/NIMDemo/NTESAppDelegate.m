 //
//  AppDelegate.m
//  NIMDemo
//
//  Created by ght on 15-1-21.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESAppDelegate.h"
#import "NTESLoginViewController.h"
#import "UIView+Toast.h"
#import "NTESService.h"
#import "NTESNotificationCenter.h"
#import "NTESLogManager.h"
#import "NTESDemoConfig.h"
#import "NTESSessionUtil.h"
#import "NTESMainTabController.h"
#import "NTESLoginManager.h"
#import "NTESCustomAttachmentDecoder.h"
#import "NTESClientUtil.h"
#import "NTESNotificationCenter.h"
#import "NIMKit.h"
#import "NTESSDKConfigDelegate.h"
#import "NTESCellLayoutConfig.h"
#import "NTESSubscribeManager.h"
#import "NTESRedPacketManager.h"
#import "NTESBundleSetting.h"
#import <UserNotifications/UserNotifications.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@import PushKit;

NSString *NTESNotificationLogout = @"NTESNotificationLogout";
@interface NTESAppDelegate ()<NIMLoginManagerDelegate,PKPushRegistryDelegate>

@property (nonatomic,strong) NTESSDKConfigDelegate *sdkConfigDelegate;

@end

@implementation NTESAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    

    [self setupNIMSDK];
    [self setupServices];
    [self setupCrashlytics];
    
    [self registerPushService];
    [self commonInitListenEvents];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    [application setStatusBarStyle:UIStatusBarStyleLightContent];

    [self setupMainViewController];
    
    [[NTESRedPacketManager sharedManager] application:application didFinishLaunchingWithOptions:launchOptions];
    
    DDLogInfo(@"launch with options %@",launchOptions);
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NIMSDK sharedSDK] loginManager] removeDelegate:self];
}


#pragma mark - ApplicationDelegate
- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSInteger count = [[[NIMSDK sharedSDK] conversationManager] allUnreadCount];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NIMSDKConfig sharedConfig] setFetchAttachmentAutomaticallyAfterReceiving:[[NTESBundleSetting sharedConfig] autoFetchAttachment]];
    [[NIMSDKConfig sharedConfig] setFetchAttachmentAutomaticallyAfterReceivingInChatroom:[[NTESBundleSetting sharedConfig] autoFetchAttachment]];
    [[NIMSDK sharedSDK].resourceManager enableFileQuickTransfer:[[NTESBundleSetting sharedConfig] fileQuickTransferEnabled]];
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[NIMSDK sharedSDK] updateApnsToken:deviceToken];
    DDLogInfo(@"didRegisterForRemoteNotificationsWithDeviceToken:  %@", deviceToken);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    DDLogInfo(@"receive remote notification:  %@", userInfo);
}



- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DDLogError(@"fail to get apns token :%@",error);
}

#pragma mark PKPushRegistryDelegate
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type
{
    if ([type isEqualToString:PKPushTypeVoIP])
    {
        [[NIMSDK sharedSDK] updatePushKitToken:credentials.token];
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    DDLogInfo(@"receive payload %@ type %@",payload.dictionaryPayload,type);
    NSNumber *badge = payload.dictionaryPayload[@"aps"][@"badge"];
    if ([badge isKindOfClass:[NSNumber class]])
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = [badge integerValue];
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(NSString *)type
{
    DDLogInfo(@"registry %@ invalidate %@",registry,type);
}


#pragma mark - openURL

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[NTESRedPacketManager sharedManager] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    [[NTESRedPacketManager sharedManager] application:app openURL:url options:options];
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    //目前只有红包跳转
    return [[NTESRedPacketManager sharedManager] application:application handleOpenURL:url];
}


#pragma mark - misc
- (void)registerPushService
{
    if (@available(iOS 11.0, *))
    {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (!granted)
            {
                dispatch_async_main_safe(^{
                    [[UIApplication sharedApplication].keyWindow makeToast:@"请开启推送功能否则无法收到推送通知" duration:2.0 position:CSToastPositionCenter];
                })
            }
        }];
    }
    else
    {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    
    //pushkit
    PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushRegistry.delegate = self;
    pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];

    
    // 注册push权限，用于显示本地推送
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
}


- (void)setupMainViewController
{
    NTESLoginData *data = [[NTESLoginManager sharedManager] currentLoginData];
    NSString *account = [data account];
    NSString *token = [data token];
    
    //如果有缓存用户名密码推荐使用自动登录
    if ([account length] && [token length])
    {
        NIMAutoLoginData *loginData = [[NIMAutoLoginData alloc] init];
        loginData.account = account;
        loginData.token = token;
        
        [[[NIMSDK sharedSDK] loginManager] autoLogin:loginData];
        [[NTESServiceManager sharedManager] start];
        NTESMainTabController *mainTab = [[NTESMainTabController alloc] initWithNibName:nil bundle:nil];
        self.window.rootViewController = mainTab;
    }
    else
    {
        [self setupLoginViewController];
    }
}

- (void)commonInitListenEvents
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(logout:)
                                                 name:NTESNotificationLogout
                                               object:nil];
    
    [[[NIMSDK sharedSDK] loginManager] addDelegate:self];
}

- (void)setupLoginViewController
{
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    NTESLoginViewController *loginController = [[NTESLoginViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginController];
    self.window.rootViewController = nav;
}

#pragma mark - 注销
-(void)logout:(NSNotification *)note
{
    [self doLogout];
}

- (void)doLogout
{
    [[NTESLoginManager sharedManager] setCurrentLoginData:nil];
    [[NTESServiceManager sharedManager] destory];
    [self setupLoginViewController];
}


#pragma NIMLoginManagerDelegate
-(void)onKick:(NIMKickReason)code clientType:(NIMLoginClientType)clientType
{
    NSString *reason = @"你被踢下线";
    switch (code) {
        case NIMKickReasonByClient:
        case NIMKickReasonByClientManually:{
            NSString *clientName = [NTESClientUtil clientName:clientType];
            reason = clientName.length ? [NSString stringWithFormat:@"你的帐号被%@端踢出下线，请注意帐号信息安全",clientName] : @"你的帐号被踢出下线，请注意帐号信息安全";
            break;
        }
        case NIMKickReasonByServer:
            reason = @"你被服务器踢下线";
            break;
        default:
            break;
    }
    [[[NIMSDK sharedSDK] loginManager] logout:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NTESNotificationLogout object:nil];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"下线通知" message:reason delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }];
}

- (void)onAutoLoginFailed:(NSError *)error
{
    //只有连接发生严重错误才会走这个回调，在这个回调里应该登出，返回界面等待用户手动重新登录。
    DDLogInfo(@"onAutoLoginFailed %zd",error.code);
    [self showAutoLoginErrorAlert:error];
}


#pragma mark - logic impl
- (void)setupServices
{
    [[NTESLogManager sharedManager] start];
    [[NTESNotificationCenter sharedCenter] start];
    [[NTESSubscribeManager sharedManager] start];
    [[NTESRedPacketManager sharedManager] start];
}

- (void)setupNIMSDK
{
    //配置额外配置信息 （需要在注册 appkey 前完成
    self.sdkConfigDelegate = [[NTESSDKConfigDelegate alloc] init];
    [[NIMSDKConfig sharedConfig] setDelegate:self.sdkConfigDelegate];
    [[NIMSDKConfig sharedConfig] setShouldSyncUnreadCount:YES];
    [[NIMSDKConfig sharedConfig] setMaxAutoLoginRetryTimes:10];
    [[NIMSDKConfig sharedConfig] setMaximumLogDays:[[NTESBundleSetting sharedConfig] maximumLogDays]];
    [[NIMSDKConfig sharedConfig] setShouldCountTeamNotification:[[NTESBundleSetting sharedConfig] countTeamNotification]];
    [[NIMSDKConfig sharedConfig] setAnimatedImageThumbnailEnabled:[[NTESBundleSetting sharedConfig] animatedImageThumbnailEnabled]];
    [[NIMSDKConfig sharedConfig] setFetchAttachmentAutomaticallyAfterReceiving:[[NTESBundleSetting sharedConfig] autoFetchAttachment]];
    [[NIMSDKConfig sharedConfig] setFetchAttachmentAutomaticallyAfterReceivingInChatroom:[[NTESBundleSetting sharedConfig] autoFetchAttachment]];
    
    //多端登录时，告知其他端，这个端的登录类型，目前对于android的TV端，手表端使用。
    [[NIMSDKConfig sharedConfig] setCustomTag:[NSString stringWithFormat:@"%ld",(long)NIMLoginClientTypeiOS]];

    //appkey 是应用的标识，不同应用之间的数据（用户、消息、群组等）是完全隔离的。
    //如需打网易云信 Demo 包，请勿修改 appkey ，开发自己的应用时，请替换为自己的 appkey 。
    //并请对应更换 Demo 代码中的获取好友列表、个人信息等网易云信 SDK 未提供的接口。
    NSString *appKey        = [[NTESDemoConfig sharedConfig] appKey];
    NIMSDKOption *option    = [NIMSDKOption optionWithAppKey:appKey];
    option.apnsCername      = [[NTESDemoConfig sharedConfig] apnsCername];
    option.pkCername        = [[NTESDemoConfig sharedConfig] pkCername];
    [[NIMSDK sharedSDK] registerWithOption:option];
    
    //注册自定义消息的解析器
    [NIMCustomObject registerCustomDecoder:[NTESCustomAttachmentDecoder new]];
    
    //注册 NIMKit 自定义排版配置
    [[NIMKit sharedKit] registerLayoutConfig:[NTESCellLayoutConfig new]];
    
    BOOL isUsingDemoAppKey = [[NIMSDK sharedSDK] isUsingDemoAppKey];
    [[NIMSDKConfig sharedConfig] setTeamReceiptEnabled:isUsingDemoAppKey];
    
    //场景配置
    NSDictionary *dict = @{@"nim_custom1":@1};
    NSMutableDictionary *dict1 = [NIMSDK sharedSDK].sceneDict;
    [NIMSDK sharedSDK].sceneDict = (NSMutableDictionary *)dict;
    NSMutableDictionary *dict2 = [NIMSDK sharedSDK].sceneDict;
    NSLog(@"%@,%@",dict1,dict2);
}

- (void)setupCrashlytics
{
    //Fabric 崩溃统计
    [Fabric with:@[[Crashlytics class]]];
}

#pragma mark - 登录错误回调
- (void)showAutoLoginErrorAlert:(NSError *)error
{
    NSString *message = [NTESSessionUtil formatAutoLoginMessage:error];
    UIAlertController *vc = [UIAlertController alertControllerWithTitle:@"自动登录失败"
                                                                message:message
                                                         preferredStyle:UIAlertControllerStyleAlert];
    
    if ([error.domain isEqualToString:NIMLocalErrorDomain] &&
        error.code == NIMLocalErrorCodeAutoLoginRetryLimit)
    {
        UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试"
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                NTESLoginData *data = [[NTESLoginManager sharedManager] currentLoginData];
                                                                NSString *account = [data account];
                                                                NSString *token = [data token];
                                                                if ([account length] && [token length])
                                                                {
                                                                    NIMAutoLoginData *loginData = [[NIMAutoLoginData alloc] init];
                                                                    loginData.account = account;
                                                                    loginData.token = token;
                                                                    
                                                                    [[[NIMSDK sharedSDK] loginManager] autoLogin:loginData];
                                                                }
                                                            }];
        [vc addAction:retryAction];
    }
    
    
    
    UIAlertAction *logoutAction = [UIAlertAction actionWithTitle:@"注销"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [[[NIMSDK sharedSDK] loginManager] logout:^(NSError *error) {
                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:NTESNotificationLogout object:nil];
                                                             }];
                                                         }];
    [vc addAction:logoutAction];
    
    [self.window.rootViewController presentViewController:vc
                                                 animated:YES
                                               completion:nil];
}


@end
