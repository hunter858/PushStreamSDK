//
//  CCCameraPreview.m
//  001-Demo
//
//  Created by pengchao on 2022/9/14.
//
#define BOX_BOUNDS CGRectMake(0.0f, 0.0f, 150, 150.0f)

#import "AWSystemPreview.h"
#import <QuartzCore/CATransaction.h>

@interface AWSystemPreview ()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UITapGestureRecognizer        *singleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer        *doubleTapGesture;
@property (nonatomic, strong) UILongPressGestureRecognizer  *longPressGesture;
@property (nonatomic, strong) UIPinchGestureRecognizer      *pinchTagGesture;
@property (nonatomic, strong) UIView *focusBox;
@property (nonatomic, strong) UIView *exposureBox;
@end

@implementation AWSystemPreview

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [(AVCaptureVideoPreviewLayer *)self.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
       
        self.focusBox = [self viewWithColor:[UIColor colorWithRed:0.102 green:0.636 blue:1.000 alpha:1.000]];
        self.exposureBox = [self viewWithColor:[UIColor colorWithRed:1.000 green:0.421 blue:0.054 alpha:1.000]];
        [self addSubview:self.focusBox];
        [self addSubview:self.exposureBox];
        [self addGestureRecognizer:self.singleTapGesture];
        [self addGestureRecognizer:self.doubleTapGesture];
        [self addGestureRecognizer:self.pinchTagGesture];
        [self addGestureRecognizer:self.longPressGesture];
    }
    return self;
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session {
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session {
    self.videoPreviewLayer.session = session;
}

- (UITapGestureRecognizer *)singleTapGesture {
    if (!_singleTapGesture) {
        _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        _singleTapGesture.numberOfTapsRequired = 1;
        _singleTapGesture.numberOfTouchesRequired = 1;
    }
    return _singleTapGesture;
}

- (UITapGestureRecognizer *)doubleTapGesture {
    if (!_doubleTapGesture) {
        _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        _doubleTapGesture.numberOfTapsRequired = 2;
        _doubleTapGesture.numberOfTouchesRequired = 1;
    }
    return _doubleTapGesture;
}

- (UILongPressGestureRecognizer *)longPressGesture {
    if (!_longPressGesture) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        _longPressGesture.minimumPressDuration = 2;
    }
    return _longPressGesture;
}

- (UIPinchGestureRecognizer *)pinchTagGesture {
    if (!_pinchTagGesture) {
        _pinchTagGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
        _pinchTagGesture.delegate = self;
    }
    return _pinchTagGesture;
}

- (void)runBoxAnimationOnView:(UIView *)view point:(CGPoint)point {
    view.center = point;
    view.hidden = NO;
    [self bringSubviewToFront:view];
    [UIView animateWithDuration:0.15f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
                     }
                     completion:^(BOOL complete) {
                         double delayInSeconds = 0.5f;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                             view.hidden = YES;
                             view.transform = CGAffineTransformIdentity;
                         });
                     }];
}

#pragma mark - Gesture Event

- (void)singleTap:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self];
    [self runBoxAnimationOnView:self.focusBox point:point];
    if ([self.delegate respondsToSelector:@selector(singleTappedAtPoint:)]) {
        [self.delegate singleTappedAtPoint:[self captureDevicePointForPoint:point]];
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self];
    [self runBoxAnimationOnView:self.exposureBox point:point];
    if ([self.delegate respondsToSelector:@selector(doubleTappedAtPoint:)]) {
        [self.delegate doubleTappedAtPoint:[self captureDevicePointForPoint:point]];
    }
}


- (void)longPress:(UILongPressGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self];
    [self runBoxAnimationOnView:self.exposureBox point:point];
    if ([self.delegate respondsToSelector:@selector(longPressAtPoint:)]) {
        [self.delegate longPressAtPoint:[self captureDevicePointForPoint:point]];
    }
}

- (void)pinchAction:(UIPinchGestureRecognizer*)sender {
    NSLog(@"cameraPreview pinch scale:%.2f", sender.scale);
    
    if ([self.delegate respondsToSelector:@selector(updateVideoZoomFactor:)]) {
        [self.delegate updateVideoZoomFactor:sender.scale];
    }
}

- (CGPoint)captureDevicePointForPoint:(CGPoint)point {
    AVCaptureVideoPreviewLayer *layer =
        (AVCaptureVideoPreviewLayer *)self.layer;
    return [layer captureDevicePointOfInterestForPoint:point];
}


- (UIView *)viewWithColor:(UIColor *)color {
    UIView *view = [[UIView alloc] initWithFrame:BOX_BOUNDS];
    view.backgroundColor = [UIColor clearColor];
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 2.0f;
    view.hidden = YES;
    return view;
}

- (void)layoutSubviews {
    self.videoPreviewLayer.frame = self.bounds;
}

- (void)dealloc {
    //NSLog(@"%@",[self.class description]);
}

@end
