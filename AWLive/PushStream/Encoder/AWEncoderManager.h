 

/*
 编码器管理，类似于工厂。负责生成所有的音视频编码器。
 */

#import <Foundation/Foundation.h>
#import "AWVideoEncoder.h"
#import "AWAudioEncoder.h"

typedef enum : NSUInteger {
    AWVideoEncoderTypeNone,
    AWVideoEncoderTypeHWH264,
    AWVideoEncoderTypeSWX264,
} AWVideoEncoderType;

typedef enum : NSUInteger {
    AWAudioEncoderTypeNone,
    AWAudioEncoderTypeHWAACLC,
    AWAudioEncoderTypeSWFAAC,
} AWAudioEncoderType;

@class AWVideoEncoder;
@class AWAudioEncoder;
@class AWAudioConfig;
@class AWVideoConfig;

@interface AWEncoderManager : NSObject
//编码器类型
@property (nonatomic, unsafe_unretained) AWAudioEncoderType audioEncoderType;
@property (nonatomic, unsafe_unretained) AWVideoEncoderType videoEncoderType;

//编码器
@property (nonatomic, readonly, strong) AWVideoEncoder *videoEncoder;
@property (nonatomic, readonly, strong) AWAudioEncoder *audioEncoder;

//时间戳
@property (nonatomic, unsafe_unretained) uint32_t timestamp;

//开启关闭
- (void)openWithAudioConfig:(AWAudioConfig *)audioConfig videoConfig:(AWVideoConfig *)videoConfig;
- (void)close;

- (BOOL)enableWriteAudioFile:(NSString *)fileName;
- (BOOL)enableWriteVideoFile:(NSString *)fileName;
- (BOOL)enableWriteFLVFile:(NSString *)fileName;
@end
