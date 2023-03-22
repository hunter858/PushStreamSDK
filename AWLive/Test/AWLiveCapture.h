 

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"

@interface AWLiveCapture : NSObject

- (instancetype)initWithViewController:(ViewController *)viewCtl;

- (void)onLayout;

- (void)updatePresent:(AVCaptureSessionPreset)present;

@end
