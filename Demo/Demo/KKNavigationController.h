//
//  KKNavigationController.h
//  LeftPanGesture
//
//  Created by 张志恒 on 16/1/27.
//  Copyright © 2016年 张志恒. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KKNavigationController : UINavigationController
/**
 *  能否左滑返回，默认为YES
 */
@property (nonatomic, assign) BOOL      canDragBack;
/**
 *  可左滑返回的区域，默认为屏幕宽度
 */
@property (nonatomic, assign) CGFloat   startBackViewX;

@end
