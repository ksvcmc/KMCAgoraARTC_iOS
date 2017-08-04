//
//  ChatViewController.h
//  demo
//
//  Created by 张俊 on 13/07/2017.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatViewController : UIViewController

- (instancetype)initWithData:(NSDictionary *)info;

@property(nonatomic, strong)NSDictionary *data;

@end
