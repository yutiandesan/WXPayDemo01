//
//  lhSharePay.m
//  WXPayDemo
//
//  Created by 叶华英 on 15/7/13.
//  Copyright (c) 2015年 liuhuan. All rights reserved.
//

#import "lhSharePay.h"
#import "WeChatPayManager.h"
#import "lhMyConnection.h"

static lhSharePay * sharePay;

@implementation lhSharePay

//单例
+ (instancetype)sharePay
{
    if (sharePay) {
        return sharePay;
    }
    sharePay = [[lhSharePay alloc]init];
    
    return sharePay;
}

#pragma mark - 微信支付
- (void)wxPayWithPayDic:(NSDictionary *)payDic OrderDic:(NSDictionary *)orderDic
{
    
    NSString * appIdStr = [NSString stringWithFormat:@"%@",[payDic objectForKey:@"app_id"]];
    NSString * mchIdStr = [NSString stringWithFormat:@"%@",[payDic objectForKey:@"mch_id"]];
    NSString * apiKeyStr = [NSString stringWithFormat:@"%@",[payDic objectForKey:@"api_key"]];
    
    //创建支付签名对象 && 初始化支付签名对象
    WeChatPayManager* wxpayManager = [[WeChatPayManager alloc]initWithAppID:appIdStr mchID:mchIdStr spKey:apiKeyStr];
    
    //获取到实际调起微信支付的参数后，在app端调起支付
    //生成预支付订单，实际上就是把关键参数进行第一次加密。
    //    NSMutableDictionary *dict = [wxpayManager getPrepayWithOrderName:name
    //                                price:price
    //                                device:device];
    
    NSMutableDictionary * dict = [wxpayManager getPrepayWithPayDic:payDic withOrderDic:orderDic];
    
    if(dict == nil){
        //错误提示
        NSString *debug = [wxpayManager getDebugInfo];
        NSLog(@"%@",debug);
        return;
    }
    
    NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
    
    //调起微信支付
    PayReq* req             = [[PayReq alloc] init];
    req.openID              = [NSString stringWithFormat:@"%@",[dict objectForKey:@"appid"]];
    req.partnerId          = [NSString stringWithFormat:@"%@",[dict objectForKey:@"partnerid"]];
    req.prepayId            = [NSString stringWithFormat:@"%@",[dict objectForKey:@"prepayid"]];
    req.nonceStr            = [NSString stringWithFormat:@"%@",[dict objectForKey:@"noncestr"]];
    req.timeStamp          = (UInt32)stamp.intValue;
    req.package            = [NSString stringWithFormat:@"%@",[dict objectForKey:@"package"]];
    req.sign                = [NSString stringWithFormat:@"%@",[dict objectForKey:@"sign"]];
    
    BOOL flag = [WXApi sendReq:req];
    if (!flag) {
        NSLog(@"请求微信失败");
        //...提示用户
    }
    else{
        NSLog(@"请求成功");
    }
    
}

#pragma mark - 请求
- (void)HTTPPOSTNormalRequestForURL:(NSString *)urlString parameters:(NSDictionary *)parameters method:(NSString *)method name:(NSString *)name
{
    self.nowName = name;
    //拼接URL
    if ([name isEqualToString:@"sendMessage"]) {
        urlString = urlString;
    }
    else{
        //webUrl请求服务器接口前缀
        urlString = [webUrl stringByAppendingFormat:@"%@",urlString];
    }
    
    NSLog(@"请求链接  ---- %@",urlString);
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *URLRequest;
    
    if ([name isEqualToString:@"buyGoods"]) {
        URLRequest = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30*60];
    }
    else{
        URLRequest = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIME_OUT_INTERVAL];
    }
    
    NSString *HTTPBodyString = [self HTTPBodyWithParameters:parameters];
    [URLRequest setHTTPBody:[HTTPBodyString dataUsingEncoding:NSUTF8StringEncoding]];
    [URLRequest setHTTPMethod:method];
    
    lhMyConnection * myConnection = [[lhMyConnection alloc]initWithRequest:URLRequest delegate:self];
    myConnection.name = name;
    [myConnection start];
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
}

//生成请求body
- (NSString *)HTTPBodyWithParameters:(NSDictionary *)parameters
{
    NSMutableArray *parametersArray = [[NSMutableArray alloc]init];
    
    for (NSString *key in [parameters allKeys]) {
        id value = [parameters objectForKey:key];
        if ([value isKindOfClass:[NSString class]]) {
            NSString * tempStr = [[NSString stringWithFormat:@"%@=%@",key,value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            //            [parametersArray addObject:[NSString stringWithFormat:@"%@=%@",key,value]];
            
            [parametersArray addObject:tempStr];
        }
    }
    
    return [parametersArray componentsJoinedByString:@"&"];
}

#pragma mark - NSUrlConnectionDelegate
//开始响应
- (void)connection:(lhMyConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (self.appData) {
        self.appData  = nil;
    }
    self.appData = [NSMutableData data];
}

//得到数据
- (void)connection:(lhMyConnection *)connection didReceiveData:(NSData *)data
{
    [self.appData appendData:data];
    
}

//完成请求
- (void)connectionDidFinishLoading:(lhMyConnection *)connection
{
    
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
    NSMutableData * data = [NSMutableData dataWithData:self.appData];
    
    NSDictionary * dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:connection.name object:nil userInfo:dataDic];
    
}

//请求失败
- (void)connection:(lhMyConnection *)connection didFailWithError:(NSError *)error
{
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:self.nowName object:nil userInfo:nil];
}

#pragma mark - 正在加载
//正在连接
+ (void)addActivityView:(UIView *)view
{
    UIView * aView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
    aView.layer.cornerRadius = 10;
    aView.layer.masksToBounds = YES;
    aView.tag = 199;
    aView.center = view.center;
    aView.backgroundColor = [UIColor blackColor];
    [view addSubview:aView];
    
    UIActivityIndicatorView *waitActivity = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(10, 10, 60, 60)];
    waitActivity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [aView addSubview:waitActivity];
    [waitActivity startAnimating];
    
    [lhSharePay closeUserEnable:view];
}

+ (void)disAppearActivitiView:(UIView *)view
{
    UIView * aView = (UIView *)[view viewWithTag:199];
    if (aView) {
        [aView removeFromSuperview];
        aView = nil;
    }
    [lhSharePay openUserEnable:view];
}

+ (void)closeUserEnable:(UIView *)viw
{
    for (UIView * v in viw.subviews) {
        v.userInteractionEnabled = NO;
    }
}

+ (void)openUserEnable:(UIView *)vie
{
    for (UIView * v in vie.subviews) {
        v.userInteractionEnabled = YES;
    }
}

@end
