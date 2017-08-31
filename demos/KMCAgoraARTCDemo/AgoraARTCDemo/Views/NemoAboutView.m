//
//  NemoAboutView.m
//  Nemo
//
//  Created by iVermisseDich on 16/12/21.
//  Copyright © 2016年 com.ksyun. All rights reserved.
//

#import "NemoAboutView.h"
#import "KSYGPUStreamerKit.h"
#import "UIColor+Expanded.h"
#import "Masonry.h"

#define FONT(value) [UIFont systemFontOfSize:value]

@implementation NemoAboutView


- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    // 0. bgview
    UIView *bgView = [[UIView alloc] init];
    bgView.layer.cornerRadius = 10;
    bgView.clipsToBounds = YES;
    bgView.backgroundColor = [UIColor colorWithHexString:@"#18181d"];
   
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.numberOfLines = 20;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"声网语音连麦分为直播场景和聊天室场景，\
直播场景可推流,聊天室场景不支持推流。\
声网语音连麦可运用在金山云直播SDK上，其他SDK需要根据其开放性决定。\n\
使用说明：\n\
1.多人输入相同标题，即可进入相同房间；\n\
2.聊天室场景下进入房间即可连麦；\n\
直播场景下听众点击电话按钮即可与主播连麦；\n\
若想进一步了解请联系我们\n\
邮件：KSC-VBU-KMC@kingsoft.com\n";
    [titleLabel sizeToFit];
    titleLabel.textColor = [UIColor colorWithHexString:@"#ffffff"];
    titleLabel.font = FONT(16);
    [self changeLineSpaceForLabel:titleLabel WithSpace:5];
   
    UIButton* closeButton = [[UIButton alloc] init];
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:bgView];
    [bgView addSubview:closeButton];
    [bgView addSubview:titleLabel];
    
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(23);
        make.trailing.equalTo(self).offset(-22);
        make.top.equalTo(self).offset(104);
        make.bottom.equalTo(self).offset(-103);
    }];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(bgView).offset(13);
        make.trailing.equalTo(bgView).offset(-13);
        make.top.bottom.equalTo(bgView);
    }];
    
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bgView);
        make.trailing.equalTo(bgView);
        make.width.mas_equalTo(48);
        make.height.mas_equalTo(48);
    }];
    
 }

- (void)close{
    [_hud hide:YES];
}

-(void)changeLineSpaceForLabel:(UILabel *)label WithSpace:(float)space {
    
    NSString *labelText = label.text;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:space];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [labelText length])];
    label.attributedText = attributedString;
    [label sizeToFit];
}
@end
