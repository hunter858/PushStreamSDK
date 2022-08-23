 

#import "AWEncoderManager.h"
#import "AWSWFaacEncoder.h"
#import "AWSWX264Encoder.h"
#import "AWHWAACEncoder.h"
#import "AWHWH264Encoder.h"

@interface AWEncoderManager()
{   BOOL _enableAudio;
    BOOL _enableVideo;
    BOOL _enableFlv;
}
//编码器
@property (nonatomic, strong) AWVideoEncoder *videoEncoder;
@property (nonatomic, strong) AWAudioEncoder *audioEncoder;
@end

@implementation AWEncoderManager

- (instancetype)init{
    self = [super init];
    if (self) {
        _enableAudio = NO;
        _enableVideo = NO;
        _enableFlv = NO;
    }
    return self;
}

- (void)openWithAudioConfig:(AWAudioConfig *) audioConfig videoConfig:(AWVideoConfig *) videoConfig {
    switch (self.audioEncoderType) {
        case AWAudioEncoderTypeHWAACLC:
            self.audioEncoder = [[AWHWAACEncoder alloc] init];
            break;
        case AWAudioEncoderTypeSWFAAC:
            self.audioEncoder = [[AWSWFaacEncoder alloc] init];
            break;
        default:
            NSLog(@"[E] AWEncoderManager.open please assin for audioEncoderType");
            return;
    }
    switch (self.videoEncoderType) {
        case AWVideoEncoderTypeHWH264:
            self.videoEncoder = [[AWHWH264Encoder alloc] init];
            break;
        case AWVideoEncoderTypeSWX264:
            self.videoEncoder = [[AWSWX264Encoder alloc] init];
            break;
        default:
            NSLog(@"[E] AWEncoderManager.open please assin for videoEncoderType");
            return;
    }
    
    self.audioEncoder.audioConfig = audioConfig;
    self.videoEncoder.videoConfig = videoConfig;
    
    self.audioEncoder.manager = self;
    self.videoEncoder.manager = self;
    
    [self.audioEncoder open];
    [self.videoEncoder open];
}

- (void)close {
    [self.audioEncoder close];
    [self.videoEncoder close];
    
    self.audioEncoder = nil;
    self.videoEncoder = nil;
    
    self.timestamp = 0;
    
    self.audioEncoder = AWAudioEncoderTypeNone;
    self.videoEncoder = AWVideoEncoderTypeNone;
}

- (BOOL)enableWriteAudioFile:(NSString *)fileName {
    if (fileName.length > 0) {
        _enableAudio = YES;
    }
    return _enableAudio;
}

- (BOOL)enableWriteVideoFile:(NSString *)fileName {
    if (fileName.length > 0) {
        _enableVideo = YES;
    }
    return _enableVideo;
}

- (BOOL)enableWriteFLVFile:(NSString *)fileName {
    if (fileName.length > 0) {
        _enableFlv = YES;
    }
    return _enableFlv;
}

@end
