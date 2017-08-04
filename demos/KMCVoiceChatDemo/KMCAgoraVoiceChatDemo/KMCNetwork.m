//
//  KMCNetwork.m
//  KMCNetwork
//
//  Created by 张俊 on 17/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "KMCNetwork.h"

//#define BaseURL  @"http://voicecalldemo.api.seancloud.cn"

//线上
#define BaseURL  @"http://voicecalldemo.api.ks-live.com"
@implementation KMCNetwork


+(instancetype)sharedInst
{
    static dispatch_once_t onceToken;
    static KMCNetwork *instance;
    dispatch_once(&onceToken, ^{
        instance = [[KMCNetwork alloc] init];
    });
    return instance;
}

//post
- (void)joinRoom:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/multi/join"];
    [self _POST:path param:param success:successBlk failure:failureBlk];
}

//离开房间
- (void)leaveRoom:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/multi/leave"];
    [self _POST:path param:param success:successBlk failure:failureBlk];
}

//获取连麦列表
- (void)fetchChatListWithRoomName:(NSString *)roomName successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/multi/getChatList"];
    [self _GET:path param:@{@"roomName":roomName} success:successBlk failure:failureBlk];
}

#pragma mark -- Private Methods

- (void)_GET:(NSString *)path param:(NSDictionary *)param success:(void (^)(id _Nullable))success
                                    failure:(void (^)(NSError * _Nonnull))failure
{

    
    NSURL *dstUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, [self formatRequestParam:param]]];

    NSURLRequest *request = [NSURLRequest requestWithURL:dstUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //
        if (!error){
            if ([response isKindOfClass:[NSHTTPURLResponse class]]){
                NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
                if (statusCode != 200){
                    
                    id errVal = @(statusCode);
                    
                    if (data){
                        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        
                        if ([dict valueForKey:@"Error"]){
                            errVal = [[dict valueForKey:@"Error"] valueForKey:@"Message"];
                        }
                        
                    }
                    
                    NSError *error  = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:statusCode userInfo:@{NSLocalizedDescriptionKey:errVal}];
                    if (failure){
                        failure(error);
                    }
                }else{
                    if (success){
                        NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        success(dict);
                    }
                }
            }
            
        }else{
            if (failure){
                failure(error);
            }
        }

    }] resume];

}


- (void)_POST:(NSString *)path param:(NSDictionary *)param success:(void (^)(id _Nullable))success
     failure:(void (^)(NSError * _Nonnull))failure
{
    
    NSURL *dstUrl = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:dstUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5];
    request.HTTPMethod = @"POST";
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *strJson = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:param
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
        NSAssert(0, @"invalid param");
    } else {
        strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    request.HTTPBody   = jsonData;
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //
        if (!error){
            if ([response isKindOfClass:[NSHTTPURLResponse class]]){
                NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
                
                if (statusCode != 200){
                    
                    id errVal = @(statusCode);
                    
                    if (data){
                        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        
                        if ([dict valueForKey:@"Error"]){
                            errVal = [[dict valueForKey:@"Error"] valueForKey:@"Message"];
                        }

                    }
                    
                    NSError *error  = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:statusCode userInfo:@{NSLocalizedDescriptionKey:errVal}];
                    if (failure){
                        failure(error);
                    }
                }else{
                    if (success){
                        NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        success(dict);
                    }
                }
            }

        }else{
            if (failure){
                failure(error);
            }
        }
    }] resume];

}

- (NSString *)formatRequestParam:(NSDictionary *)param
{
    NSMutableString *str = [[NSMutableString alloc] init];
    [param enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [str appendFormat:@"%@=%@&", key, obj];
    }];
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"&"];
    return  [str stringByTrimmingCharactersInSet:characterSet];
}



@end
