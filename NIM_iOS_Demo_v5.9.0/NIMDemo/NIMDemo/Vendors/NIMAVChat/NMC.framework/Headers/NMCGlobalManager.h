//
//  NMCGlobalManager.h
//  NMC
//
//  Created by taojinliang on 2018/8/29.
//  Copyright © 2018年 taojinliang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NMCSDKType) {
    //!< 混合  （实时音和TCP推流）  iOS
    NMCSDKType_Hybrid_iOS_TCP,
    //!< 混合  （实时音和UDP推流）  iOS
    NMCSDKType_Hybrid_iOS_UDP,
    //!< 不混合 （实时音）         iOS
    NMCSDKType_RTC_iOS,
    //!< 不混合 （实时音）         macOS
    NMCSDKType_RTC_Mac,
    //!< 不混合 （TCP推流）        iOS
    NMCSDKType_LS_iOS_TCP,
    //!< 不混合 （TCP推流MINI版本） iOS
    NMCSDKType_LS_iOS_TCP_MINI,
    //!< 不混合 （UDP推流）        iOS
    NMCSDKType_LS_iOS_UDP,
    //!< 不混合 （UDP推流MINI版本） iOS
    NMCSDKType_LS_iOS_UDP_MINI
};

@interface NMCGlobalManager : NSObject

/**
 NMC全局管理单例

 @return 实例
 */
+(NMCGlobalManager *)shareInstance;

/**
 获取当前SDK类型

 @return SDK类型
 */
-(NMCSDKType)getCurrentSDKType;

/**
 获取当前SDK的版本

 @return SDK版本
 */
-(NSString *)getCurrentSDKVersion;
@end
