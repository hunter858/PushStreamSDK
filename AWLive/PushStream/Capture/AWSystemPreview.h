//
//  CCCameraPreview.h
//  001-Demo
//
//  Created by pengchao on 2022/9/14.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@protocol AWSystemPreviewDelegate <NSObject>
@optional
- (void)singleTappedAtPoint:(CGPoint)point;
- (void)doubleTappedAtPoint:(CGPoint)point;
- (void)longPressAtPoint:(CGPoint)point;
- (void)updateVideoZoomFactor:(CGFloat)factor;

@end


@interface AWSystemPreview : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong, setter=setSession:) AVCaptureSession *session;
@property (weak, nonatomic) id<AWSystemPreviewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
