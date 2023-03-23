//
//  AWFileManager.m
//  AWLive
//
//  Created by pengchao on 2022/6/13.
//

#import "AWFileManager.h"


const NSString * STRING_PCM  = @"pcm";
const NSString * STRING_AAC  = @"aac";
const NSString * STRING_H264 = @"h264";
const NSString * STRING_FLV  = @"flv";

@interface AWFileManager ()
@property (nonatomic, strong) dispatch_source_t dispatch_timer;
@property (unsafe_unretained, readwrite) FILE *audio_file;      //aac
@property (unsafe_unretained, readwrite) FILE *video_file;      //h264/h265
@property (unsafe_unretained, readwrite) FILE *pcm_file;        //pcm
@property (unsafe_unretained, readwrite) FILE *flv_file;        //flv
@end

@implementation AWFileManager

- (instancetype)init {
    self = [super init];
    if (self){
        self.recoderTimerNum = 10;
    }
    return self;
}

- (NSString *)createFileWithMediaType:(MEDIA_TYPE)mediaType {
    NSMutableString *fileName = [self currentTime].mutableCopy;
    switch (mediaType) {
        case MEDIA_TYPE_PCM:
            [fileName appendString:@".pcm"];
            break;
        case MEDIA_TYPE_AAC:
            [fileName appendString:@".aac"];
            break;
        case MEDIA_TYPE_H264:
            [fileName appendString:@".h264"];
            break;
        case MEDIA_TYPE_FLV:
            [fileName appendString:@".flv"];
            break;
       
        default:
            break;
    }
    return fileName;
}

- (NSString *)createFileWithFileName:(NSString *)fileName{
    if ((fileName.length <= 0)) {
        return nil;
    }
    
    MEDIA_TYPE type = MEDIA_TYPE_UNKNOW;
    NSMutableString *mediaFloderPath = [self doucumentPath].mutableCopy;
    if ([fileName containsString:STRING_AAC]) {
        type = MEDIA_TYPE_AAC;
        [mediaFloderPath appendString:@"/aac"];
        
    } else if ([fileName containsString:STRING_H264]) {
        type = MEDIA_TYPE_H264;
        [mediaFloderPath appendString:@"/h264"];
        
    } else if ([fileName containsString:STRING_FLV]) {
        type = MEDIA_TYPE_FLV;
        [mediaFloderPath appendString:@"/flv"];
        
    } else if ([fileName containsString:STRING_PCM]) {
        type = MEDIA_TYPE_PCM;
        [mediaFloderPath appendString:@"/pcm"];
    }
   
    BOOL isExitFloder = [self judgeObjectExistence:mediaFloderPath];
    if (!isExitFloder) {
        [self createFolderWithMediaType:type];
    }
    
    [mediaFloderPath appendFormat:@"/%@",fileName];
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:mediaFloderPath contents:nil attributes:nil];
    if (!success) {
        NSLog(@"create aac failed;");
    }
    return mediaFloderPath;
}

- (BOOL)createAndOpenFileWithMediaType:(MEDIA_TYPE)mediaType {
 
    
    NSString *fileName = [self createFileWithMediaType:mediaType];
    NSString *filePath = [self createFileWithFileName:fileName];
    const char *filePathStr = filePath.UTF8String;
    FILE *dump_file = fopen(filePathStr, "wb");
    
    switch (mediaType) {
        case MEDIA_TYPE_PCM:
            self.pcm_file = dump_file;
            break;
        case MEDIA_TYPE_H264:
            self.video_file = dump_file;
            break;
        case MEDIA_TYPE_AAC:
            self.audio_file = dump_file;
            break;
        case MEDIA_TYPE_FLV:
            self.flv_file = dump_file;
            break;
        default:
            break;
    }
    [self _startRecord];
    return YES;
}

- (void)startRecord {
    [self _startRecord];
}


- (void)stopRecord {
    [self _stopRecord];
}

- (BOOL)clearCacheWithMediaType:(MEDIA_TYPE)type {
    NSMutableString *document = [self doucumentPath].mutableCopy;
    [document appendFormat:@"/%@",[self stringWithMediaType:type]];
    [self removeDirWithPath:document];
    
    return YES;
}


- (BOOL)removeDirWithPath:(NSString*)path {
    /**
     检测文件是否存在
     */
    BOOL isExistence = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (isExistence) {
        NSError * error ;
        BOOL isRemove = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (isRemove) {
            NSLog(@"delete file success");
            return YES;
        }else{
            NSLog(@"delete file error:%@",error);
            return false;
        }
    } else {
        NSLog(@"delete file not exit");
        return false;
    }
    /**
     输出：
     2017-03-31 11:28:24.004 NSFileManager[2190:371451] 删除成功
     2017-03-31 11:28:24.007 NSFileManager[2190:371451] 删除成功
     */
}



- (NSString *)currentTime {
    NSDate *cureentDate  = [NSDate new];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy_MM_dd_HH:mm:ss"];
    NSString *string = [dateFormat stringFromDate:cureentDate];
    return string;
}

- (BOOL)deleteFileWithFileName:(NSString *)fileName {
    
     BOOL res = [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
     if (res) {
         NSLog(@"delete file success");
         return YES;
             
     } else {
         NSLog(@"delete file faild");
         return NO;
     }
}


- (NSString *)createFolderWithMediaType:(MEDIA_TYPE)mediaType {
    NSString *dirName = [self stringWithMediaType:mediaType];
    NSString *documentsPath = [self doucumentPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dirDirectoryPath = [documentsPath stringByAppendingPathComponent:dirName];
    // 创建目录
    BOOL res = [fileManager createDirectoryAtPath:dirDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    if (res) {
        NSLog(@"create folder success\n %@",dirDirectoryPath);
        return dirDirectoryPath;
    }else {
        NSLog(@"create folder faild");
        return nil;
    }
       
 }


-(NSString *)stringWithMediaType:(MEDIA_TYPE)mediaType{
    switch (mediaType) {
        case MEDIA_TYPE_PCM:
            return STRING_PCM;
            break;
        case MEDIA_TYPE_AAC:
            return STRING_AAC;
            break;
        case MEDIA_TYPE_H264:
            return STRING_H264;
            break;
        case MEDIA_TYPE_FLV:
            return STRING_FLV;
            break;
        default:
            return nil;
            break;
    }
}




-(BOOL)judgeObjectExistence:(NSString*)objectPath{
    /**
     判断文或者文件夹
     BOOL Existence = [fileManager fileExistsAtPath:objectPath isDirectory:YES];
     */
    BOOL isExistence = [[NSFileManager defaultManager] fileExistsAtPath:objectPath];
    if (!isExistence) {
        NSLog(@"不存在");
        return NO;
    }
    return YES;
}

- (NSString*)createFilePath:(NSString*)fileName{
    NSString * filePathString = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [NSString stringWithFormat:@"%@/%@",filePathString,fileName];
}

- (NSString *)doucumentPath {
    NSString *homeDir = NSHomeDirectory();
    NSString *documentDir = [homeDir stringByAppendingPathComponent:@"Documents"];
    return documentDir;
}

#pragma mark private

- (void)_startRecord {
    if (self.dispatch_timer) {
        return;
    }
    dispatch_queue_t FPSQueue = dispatch_queue_create("tick.recoder.timer", NULL);
    dispatch_source_t dispatch_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, FPSQueue);
    dispatch_source_set_timer(dispatch_timer, dispatch_time(DISPATCH_TIME_NOW, 0), 1 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(dispatch_timer, ^{
        @autoreleasepool {
            [self _timerInterval];
        }
    });
    dispatch_resume(dispatch_timer);
    self.dispatch_timer = dispatch_timer;
}

- (void)_stopRecord {
    if (self.dispatch_timer) dispatch_source_cancel(self.dispatch_timer);
    self.dispatch_timer = nil;
}

- (void)_timerInterval{
    self.recoderTimerNum--;
    NSLog(@"xxx _timerInterval: %d",(int)self.recoderTimerNum);
    if (self.recoderTimerNum <= 0){
        [self _stopRecord];
        self.recoderTimerNum = 10;
        self.pcm_file = NULL;
        self.audio_file = NULL;
        self.video_file = NULL;
        self.flv_file = NULL;
    }
}


@end
