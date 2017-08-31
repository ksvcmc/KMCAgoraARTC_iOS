//
//  KMCNetwork.m
//  KMCNetwork
//
//  Created by 张俊 on 17/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "KMCNetwork.h"
//debug
//#define BaseURL  @"http://voicecalldemo.api.seancloud.cn"
//release
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
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/live/join"];
    [self _POST:path param:param success:successBlk failure:failureBlk];
}

//离开房间
- (void)leaveRoom:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/live/leave"];
    [self _POST:path param:param success:successBlk failure:failureBlk];
}

//观众连麦
- (void)joinChat:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/live/chat"];
    [self _POST:path param:param success:successBlk failure:failureBlk];
}

//观众退麦
- (void)leaveChat:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/live/unchat"];
    [self _POST:path param:param success:successBlk failure:failureBlk];
}

- (void)kickUser:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/live/removeLinkChat"];
    [self _POST:path param:param success:successBlk failure:failureBlk];
}

//获取连麦列表
- (void)fetchChatListWithRoomName:(NSString *)roomName roomId:(NSNumber *)roomId successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/live/getChatList"];
    [self _GET:path param:@{@"roomName":roomName,@"roomId":roomId} success:successBlk failure:failureBlk];
}

#pragma mark -- 聊天室
//post
- (void)joinMultiRoom:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/multi/join"];
    [self _POST:path param:param success:successBlk failure:failureBlk];
}

//离开房间
- (void)leaveMultiRoom:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/multi/leave"];
    [self _POST:path param:param success:successBlk failure:failureBlk];
}

//获取连麦列表
- (void)fetchMultiChatListWithRoomName:(NSString *)roomName roomId:(NSNumber *)roomId successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk
{
    NSString *path = [NSString stringWithFormat:@"%@%@", BaseURL, @"/api/multi/getChatList"];
    [self _GET:path param:@{@"roomName":roomName,@"roomId":roomId} success:successBlk failure:failureBlk];
}

#pragma mark -- Private Methods

- (void)_GET:(NSString *)path param:(NSDictionary *)param success:(void (^)(id _Nullable))success
                                    failure:(void (^)(NSError * _Nonnull))failure
{

    NSString * str = [NSString stringWithFormat:@"%@?%@", path,[self formatRequestParam:param]];
    str = [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *dstUrl = [NSURL URLWithString:str];

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
