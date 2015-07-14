//
//  lhSharePay.h
//  WXPayDemo
//
//  Created by 叶华英 on 15/7/13.
//  Copyright (c) 2015年 liuhuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface lhSharePay : NSObject

@property (nonatomic,strong)NSMutableData * appData;//请求的数据
@property (nonatomic,strong)NSString * nowName;//通知的名字


+ (instancetype)sharePay;

/**
 *微信支付
 *payDic存储支付需要的账号信息，appId、商户号、APIKey
 */
#pragma mark - 微信支付
- (void)wxPayWithPayDic:(NSDictionary *)payDic OrderDic:(NSDictionary *)orderDic;

/**
 *请求后台接口
 */
- (void)HTTPPOSTNormalRequestForURL:(NSString *)urlString parameters:(NSDictionary *)parameters method:(NSString *)method name:(NSString *)name;

//正在连接
+ (void)addActivityView:(UIView *)view;
+ (void)disAppearActivitiView:(UIView *)view;

@end
