 

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "AWFileManager.h"

@interface AWLiveCapture : NSObject

@property (nonatomic,strong) AWFileManager *fileManager;

- (instancetype)initWithViewController:(ViewController *)viewCtl;

- (void)onLayout;

- (void)updatePresent:(AVCaptureSessionPreset)present;

@end
