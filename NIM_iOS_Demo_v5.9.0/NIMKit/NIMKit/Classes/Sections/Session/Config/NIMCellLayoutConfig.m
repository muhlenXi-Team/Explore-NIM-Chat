//
//  NIMSessionDefaultConfig.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMCellLayoutConfig.h"
#import "NIMSessionMessageContentView.h"
#import "NIMSessionUnknowContentView.h"
#import "M80AttributedLabel+NIMKit.h"
#import "NIMKitUtil.h"
#import "UIImage+NIMKit.h"
#import "NIMMessageModel.h"
#import "NIMBaseSessionContentConfig.h"
#import "NIMKit.h"

@interface NIMCellLayoutConfig()

@end

@implementation NIMCellLayoutConfig

// 返回 message 的内容大小
- (CGSize)contentSize:(NIMMessageModel *)model cellWidth:(CGFloat)cellWidth{
    id<NIMSessionContentConfig>config = [[NIMSessionContentConfigFactory sharedFacotry] configBy:model.message];
    return [config contentSize:cellWidth message:model.message];
}

// 需要构造的 cellContent 类型名
- (NSString *)cellContent:(NIMMessageModel *)model{
    id<NIMSessionContentConfig>config = [[NIMSessionContentConfigFactory sharedFacotry] configBy:model.message];
    NSString *cellContent = [config cellContent:model.message];
    return cellContent.length ? cellContent : @"NIMSessionUnknowContentView";
}

// 左对齐的气泡，cell内容 距离 气泡 的内间距
- (UIEdgeInsets)contentViewInsets:(NIMMessageModel *)model{
    id<NIMSessionContentConfig>config = [[NIMSessionContentConfigFactory sharedFacotry] configBy:model.message];    
    return [config contentViewInsets:model.message];
}

// 左对齐的气泡， cell气泡距离整个cell的内间距
- (UIEdgeInsets)cellInsets:(NIMMessageModel *)model
{
    if ([[self cellContent:model] isEqualToString:@"NIMSessionNotificationContentView"]) {
        return UIEdgeInsetsZero;
    }
    CGFloat cellTopToBubbleTop           = 3;
    CGFloat otherNickNameHeight          = 20;
    CGFloat otherBubbleOriginX           = [self shouldShowAvatar:model]? 55 : 0;
    CGFloat cellBubbleButtomToCellButtom = 13;
    if ([self shouldShowNickName:model])
    {
        //要显示名字
        return UIEdgeInsetsMake(cellTopToBubbleTop + otherNickNameHeight ,otherBubbleOriginX,cellBubbleButtomToCellButtom, 0);
    }
    else
    {
        return UIEdgeInsetsMake(cellTopToBubbleTop,otherBubbleOriginX,cellBubbleButtomToCellButtom, 0);
    }

}

// 是否显示头像
- (BOOL)shouldShowAvatar:(NIMMessageModel *)model
{
    return [[NIMKit sharedKit].config setting:model.message].showAvatar;
}

// 是否显示昵称
- (BOOL)shouldShowNickName:(NIMMessageModel *)model{
    NIMMessage *message = model.message;
    if (message.messageType == NIMMessageTypeNotification)
    {
        NIMNotificationType type = [(NIMNotificationObject *)message.messageObject notificationType];
        if (type == NIMNotificationTypeTeam) {
            return NO;
        }
    }
    if (message.messageType == NIMMessageTypeTip) {
        return NO;
    }
    return (!message.isOutgoingMsg && message.session.sessionType == NIMSessionTypeTeam);
}

// 消息显示在左边
- (BOOL)shouldShowLeft:(NIMMessageModel *)model
{
    return !model.message.isOutgoingMsg;
}

// 左对齐的气泡，头像控件的 origin 点
- (CGPoint)avatarMargin:(NIMMessageModel *)model
{
    return CGPointMake(8.f, 0.f);
}

// 左对齐的气泡，头像控件的 size
- (CGSize)avatarSize:(NIMMessageModel *)model
{
    return CGSizeMake(42, 42);
}

// 左对齐的气泡，昵称控件的 origin 点
- (CGPoint)nickNameMargin:(NIMMessageModel *)model
{
    return [self shouldShowAvatar:model] ? CGPointMake(57.f, -3.f) : CGPointMake(10.f, -3.f);
}

// 需要添加到 Cell 上的自定义视图
- (NSArray *)customViews:(NIMMessageModel *)model
{
    return nil;
}

// 是否开启 重试叹号
- (BOOL)disableRetryButton:(NIMMessageModel *)model
{
    if (!model.message.isReceivedMsg)
    {
        return model.message.deliveryState != NIMMessageDeliveryStateFailed;
    }
    else
    {
        return model.message.attachmentDownloadState != NIMMessageAttachmentDownloadStateFailed;
    }
}

@end
