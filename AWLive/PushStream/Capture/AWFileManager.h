//
//  AWFileManager.h
//  AWLive
//
//  Created by pengchao on 2022/6/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum : NSUInteger {
    MEDIA_TYPE_UNKNOW,
    MEDIA_TYPE_PCM,
    MEDIA_TYPE_AAC,
    MEDIA_TYPE_H264,
    MEDIA_TYPE_FLV,
} MEDIA_TYPE;

@interface AWFileManager : NSObject
@property (unsafe_unretained, readonly) FILE *audio_file;
@property (unsafe_unretained, readonly) FILE *video_file;
@property (unsafe_unretained, readonly) FILE *pcm_file;
@property (unsafe_unretained, readonly) FILE *flv_file;

@property (nonatomic, assign) NSInteger recoderTimerNum;        ///采集时间(单位S)


- (NSString *)createFileWithMediaType:(MEDIA_TYPE)mediaType;

- (NSString *)createFileWithFileName:(NSString *)fileName;

- (BOOL)createAndOpenFileWithMediaType:(MEDIA_TYPE)mediaType;

- (BOOL)clearCacheWithMediaType:(MEDIA_TYPE)type;

- (NSString *)doucumentPath;

- (NSString *)createDirWithDirName:(NSString *)dirName;

- (BOOL)deleteFileWithFileName:(NSString *)fileName;

- (BOOL)clearDocumentDir;

- (void)startRecord;

- (void)stopRecord;

@end

NS_ASSUME_NONNULL_END
