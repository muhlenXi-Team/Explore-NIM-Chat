//
//  NIMNetCallVideoDevice.h
//  NIMAVChat
//
//  Created by He on 2018/10/18.
//  Copyright © 2018年 Netease. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NIMNetCallVideoDevice : NSObject
@property(nonatomic, strong) AVCaptureDevice *device;
@property(nonatomic, strong) AVCaptureDeviceInput *input;
@end

NS_ASSUME_NONNULL_END
