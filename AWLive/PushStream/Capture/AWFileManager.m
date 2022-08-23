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

@implementation AWFileManager

- (BOOL)clearDocumentDirWithType:(MEDIA_TYPE)type {
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
            NSLog(@"%@",@"删除成功");
            return YES;
        }else{
            NSLog(@"删除失败--error:%@",error);
            return false;
        }
    }else{
        NSLog(@"文件不存在，请确认路径");
        return false;
    }
    /**
     输出：
     2017-03-31 11:28:24.004 NSFileManager[2190:371451] 删除成功
     2017-03-31 11:28:24.007 NSFileManager[2190:371451] 删除成功
     */
}

- (NSString *)createRandomMediaTypeName:(MEDIA_TYPE)mediaType {
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
         NSLog(@"文件删除成功");
         return YES;
             
     } else {
         NSLog(@"文件删除失败");
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
        NSLog(@"文件夹创建成功\n %@",dirDirectoryPath);
        return dirDirectoryPath;
    }else {
        NSLog(@"文件夹创建失败");
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


- (NSString *)createFileWithFileName:(NSString *)fileName{
    if ((fileName.length <= 0)) {
        return nil;
    }
    
    MEDIA_TYPE type = MEDIA_TYPE_NONE;
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



-(NSString*)createFilePath:(NSString*)fileName{
    NSString * filePathString = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [NSString stringWithFormat:@"%@/%@",filePathString,fileName];
}

- (NSString *)doucumentPath {
    NSString *homeDir = NSHomeDirectory();
    NSString *documentDir = [homeDir stringByAppendingPathComponent:@"Documents"];
    return documentDir;
}

@end
