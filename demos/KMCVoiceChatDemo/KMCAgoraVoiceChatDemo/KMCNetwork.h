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

//T人
//- (void)kickUser:(NSDictionary *)param successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;

//获取连麦列表
- (void)fetchChatListWithRoomName:(NSString *)roomName successBlk:(OnSuccess)successBlk OnFailure:(OnFailure)failureBlk;



@end
