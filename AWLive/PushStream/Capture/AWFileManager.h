//
//  AWFileManager.h
//  AWLive
//
//  Created by pengchao on 2022/6/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum : NSUInteger {
    MEDIA_TYPE_NONE,
    MEDIA_TYPE_PCM,
    MEDIA_TYPE_AAC,
    MEDIA_TYPE_H264,
    MEDIA_TYPE_FLV,
} MEDIA_TYPE;

@interface AWFileManager : NSObject


- (BOOL)clearDocumentDirWithType:(MEDIA_TYPE)type;

- (NSString *)createRandomMediaTypeName:(MEDIA_TYPE)mediaType;

- (NSString *)doucumentPath ;
    
- (NSString *)createFileWithFileName:(NSString *)fileName;

- (NSString *)createDirWithDirName:(NSString *)dirName;

- (BOOL)deleteFileWithFileName:(NSString *)fileName;

- (BOOL)clearDocumentDir;

@end

NS_ASSUME_NONNULL_END
