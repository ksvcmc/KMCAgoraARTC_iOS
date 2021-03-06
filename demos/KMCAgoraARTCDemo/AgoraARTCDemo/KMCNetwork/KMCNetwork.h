//
//  KMCNetwork.h
//  KMCNetwork
//
//  Created by 张俊 on 17/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^OnSuccess)(NSDictionary *data);
typedef void (^OnFailure)(NSError *error);

@interface KMCNetwork : NSObject

+(instancetype)sharedInst;

//创建/加入房间
- (void)joinRoom:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;

//离开房间
- (void)leaveRoom:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;

//观众连麦
- (void)joinChat:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;

//观众退麦
- (void)leaveChat:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;

//T人
- (void)kickUser:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;

//获取连麦列表
- (void)fetchChatListWithRoomName:(NSString *)roomName roomId:(NSNumber *)roomId successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;

//加入聊天室
- (void)joinMultiRoom:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;

//离开聊天室
- (void)leaveMultiRoom:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;

//聊天室列表
- (void)fetchMultiChatListWithRoomName:(NSString *)roomName roomId:(NSNumber *)roomId successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;

@end
