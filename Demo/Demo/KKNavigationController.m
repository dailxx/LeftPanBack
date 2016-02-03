//
//  KKNavigationController.m
//  LeftPanGesture
//
//  Created by 张志恒 on 16/1/27.
//  Copyright © 2016年 张志恒. All rights reserved.
//

#import "KKNavigationController.h"


#pragma mark - UIView Category
@implementation UIView (Snapshot)

- (UIImage *)snapshot {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0);
    if ([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    } else {
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

#pragma mark - KKNavigationController
@interface KKNavigationController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView        *lastScreenShotView;
@property (nonatomic, strong) NSMutableArray     *screenShotList;
@property (nonatomic, strong) UIView             *backgroundView;
@property (nonatomic, strong) UIView             *blackMaskView;;
@property (nonatomic, assign) CGPoint            startTouch;
@property (nonatomic, assign, getter = isMoving) BOOL moving;

@end

@implementation KKNavigationController
#define kScreenWidth            CGRectGetWidth([UIScreen mainScreen].bounds)
#define kKeyWindow              [[UIApplication sharedApplication] keyWindow]
#define kAnimationDuration      0.25
#define kViewOffset             -100

#pragma mark - override methods
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.canDragBack = YES;
        self.startBackViewX = kScreenWidth;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.canDragBack = YES;
        self.startBackViewX = kScreenWidth;
    }
    return self;
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.interactivePopGestureRecognizer.enabled = NO;
    }
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handlePanGesture:)];
    [self.view addGestureRecognizer:pan];
}

- (void)dealloc {
     self.screenShotList = nil;
    
    [self.backgroundView removeFromSuperview];
    self.backgroundView = nil;
}

#pragma mark - override methods
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.screenShotList addObject:[self.view snapshot]];
    
    [super pushViewController:viewController animated:animated];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    [self.screenShotList addObject:[self.view snapshot]];
    
    [super setViewControllers:viewControllers animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    [self.screenShotList removeLastObject];
    
    return [super popViewControllerAnimated:animated];
}

#pragma mark - private methods
- (void)moveViewWithX:(CGFloat)x {
    x = x > kScreenWidth ? kScreenWidth : x;
    x = x < 0 ? 0 : x;
    
    CGRect frame = self.view.frame;
    frame.origin.x = x;
    self.view.frame = frame;
    
    CGFloat scale = (-kViewOffset) / kScreenWidth;
    CGFloat alpha = MAX(0.5 - (x / kScreenWidth / 2), 0);

    self.backgroundView.transform = CGAffineTransformMakeTranslation(scale * x, 0);
    self.blackMaskView.alpha = alpha;
}

#pragma mark - event responses
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.startTouch = [[touches anyObject] locationInView:self.view];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)pan {
    if (self.viewControllers.count <= 1 || !self.canDragBack) return;
    if (self.startTouch.x > self.startBackViewX) return;

    CGPoint touchPoint = [pan locationInView:kKeyWindow];
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.moving = YES;
            self.startTouch = touchPoint;
            
            [self.view.superview insertSubview:self.backgroundView belowSubview:self.view];
            [self.backgroundView addSubview:self.blackMaskView];
            
            if (self.lastScreenShotView) {
                [self.lastScreenShotView removeFromSuperview];
            }
            
            
            self.lastScreenShotView = [[UIImageView alloc] initWithImage:[self.screenShotList lastObject]];
            [self.backgroundView insertSubview:self.lastScreenShotView belowSubview:self.blackMaskView];
            
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            self.moving = YES;
            [self moveViewWithX:touchPoint.x - self.startTouch.x];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            if (touchPoint.x - self.startTouch.x >= (kScreenWidth / 2)) {
                [UIView animateWithDuration:kAnimationDuration
                                 animations:^{
                                     [self moveViewWithX:kScreenWidth];
                                 } completion:^(BOOL finished) {
                                     [self popViewControllerAnimated:NO];
                                     
                                     CGRect frame = self.view.frame;
                                     frame.origin.x = 0;
                                     self.view.frame = frame;
                                     
                                     self.moving = NO;
                                 }];
            } else {
                [UIView animateWithDuration:kAnimationDuration
                                 animations:^{
                                     [self moveViewWithX:0];
                                 } completion:^(BOOL finished) {
                                     self.moving = NO;
                                 }];
            }
        }
            break;
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        {
            [UIView animateWithDuration:kAnimationDuration
                             animations:^{
                                 [self moveViewWithX:0];
                             } completion:^(BOOL finished) {
                                 self.moving = NO;
                             }];
        }
            break;
        default:
            break;
    }
}

#pragma mark - delegates

#pragma mark - setters and getters
- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] initWithFrame:CGRectOffset(self.view.bounds, kViewOffset, 0)];
        _backgroundView.backgroundColor = [UIColor blackColor];
    }
    return _backgroundView;
}

- (UIView *)blackMaskView {
    if (!_blackMaskView) {
        _blackMaskView = [[UIView alloc] initWithFrame:self.view.bounds];
        _blackMaskView.backgroundColor = [UIColor blackColor];
    }
    return _blackMaskView;
}

- (NSMutableArray *)screenShotList {
    if (!_screenShotList) {
        _screenShotList = [[NSMutableArray alloc] init];
    }
    return _screenShotList;
}


@end
































