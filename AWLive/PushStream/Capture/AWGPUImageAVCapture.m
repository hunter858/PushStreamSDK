 

#import "AWGPUImageAVCapture.h"
#import <GPUImage/GPUImageFramework.h>
#import "GPUImageBeautifyFilter.h"
#import "AWGPUImageVideoCamera.h"
#import "libyuv.h"

//GPUImage data handler
@interface AWGPUImageAVCaptureDataHandler : GPUImageRawDataOutput< AWGPUImageVideoCameraDelegate>
@property (nonatomic, weak) AWAVCapture *capture;
@end

@implementation AWGPUImageAVCaptureDataHandler

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat capture:(AWAVCapture *)capture
{
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        self.capture = capture;
    }
    return self;
}

- (void)processAudioSample:(CMSampleBufferRef)sampleBuffer {
    if(!self.capture || !self.capture.isCapturing){
        return;
    }
    
    [self.capture sendAudioSampleBuffer:sampleBuffer];
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
    if(!self.capture || !self.capture.isCapturing){
        return;
    }
    //将bgra转为yuv
    //图像宽度
    int width = aw_stride((int)imageSize.width);
    //图像高度
    int height = imageSize.height;
    
    {/*
        //ARGB pixeBuffer
        CVPixelBufferRef bgra_pixelBuf = NULL;
        CVPixelBufferCreate(NULL, width, height, kCVPixelFormatType_32BGRA, NULL, &bgra_pixelBuf);
        
        // Lock address，锁定数据，应该是多线程防止重入操作。
        if (CVPixelBufferLockBaseAddress(bgra_pixelBuf, 0) != kCVReturnSuccess) {
            NSLog(@"encode video lock base address failed");
        }
    
        size_t y_size = aw_stride(width) * height;
        size_t BGRA_size = y_size * 4;
        uint8_t *bgra_frame = CVPixelBufferGetBaseAddressOfPlane(bgra_pixelBuf, 0);
        memcpy(bgra_frame, self.rawBytesForImage, BGRA_size);
        CVPixelBufferUnlockBaseAddress(bgra_pixelBuf, 0);
        CVPixelBufferRelease(bgra_pixelBuf);
      
        // BGRA ->ARGB
        uint8_t *ARGB_buffer = malloc(w_x_h * 4);
        memset(ARGB_buffer, 0, w_x_h * 4);
        BGRAToARGB(self.rawBytesForImage,( width*4 ),ARGB_buffer,(width*4 ),width,height);
      */
    }
    
    
    //ARGBToNV12这个函数是libyuv这个第三方库提供的一个将bgra图片转为yuv420格式的一个函数。
    //libyuv是google提供的高性能的图片转码操作。支持大量关于图片的各种高效操作，是视频推流不可缺少的重要组件，你值得拥有。
    [self lockFramebufferForReading];
    
    //YUV420F pixeBuffer
    CVPixelBufferRef yuv_pixelBuf = NULL;
    CVPixelBufferCreate(NULL, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &yuv_pixelBuf);

    CVPixelBufferLockBaseAddress(yuv_pixelBuf, 0);
    
    uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(yuv_pixelBuf, 0);
    size_t plane0_stride =  CVPixelBufferGetBytesPerRowOfPlane(yuv_pixelBuf,0);
    uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(yuv_pixelBuf, 1);
    size_t plane1_stride =  CVPixelBufferGetBytesPerRowOfPlane(yuv_pixelBuf,1);
    

    ARGBToNV12(self.rawBytesForImage, (int)(width * 4), y_frame, (int)plane0_stride, uv_frame, (int)plane1_stride, (int)width, (int)height);
    
    CVPixelBufferUnlockBaseAddress(yuv_pixelBuf, 0);
    [self unlockFramebufferAfterReading];
    
    /// YUV420F
    NSData *yuvData = [self convertVideoPixelBufferToYuvData:yuv_pixelBuf];
    CVPixelBufferRelease(yuv_pixelBuf);
    
    [self.capture sendVideoYuvData:yuvData];
}



-(NSData *) convertVideoPixelBufferToYuvData:(CVImageBufferRef) pixelBuffer{
    // 获取yuv数据
    // 通过CMSampleBufferGetImageBuffer方法，获得CVImageBufferRef。
    // 这里面就包含了yuv420数据的指针
    
    //表示开始操作数据
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    //图像宽度（像素）
    size_t y_stride = aw_stride(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0));
    
    //图像高度（像素）
    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
    //yuv中的y所占字节数
    size_t y_size = y_stride * pixelHeight;
    //yuv中的u和v分别所占的字节数
    size_t uv_size = y_size / 4;
    
    uint8_t *yuv_frame = aw_alloc(uv_size * 2 + y_size);
    
    //获取CVImageBufferRef中的y数据
    uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(yuv_frame, y_frame, y_size);
    
    //获取CMVImageBufferRef中的uv数据
    uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(yuv_frame + y_size, uv_frame, uv_size * 2);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    NSData *nv12Data = [NSData dataWithBytesNoCopy:yuv_frame length:y_size + uv_size * 2];
    //旋转
    return nv12Data;
}


@end

//GPUImage capture
@interface AWGPUImageAVCapture()
@property (nonatomic, strong) AWGPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, strong) GPUImageBeautifyFilter *beautifyFilter;
@property (nonatomic, strong) AWGPUImageAVCaptureDataHandler *dataHandler;
@end

@implementation AWGPUImageAVCapture

#pragma mark 懒加载

- (void)onInit {
    //摄像头
    _videoCamera = [[AWGPUImageVideoCamera alloc] initWithSessionPreset:self.captureSessionPreset cameraPosition:AVCaptureDevicePositionFront];
    //声音
    [_videoCamera addAudioInputsAndOutputs];
    //屏幕方向
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    //镜像策略
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
    //预览 view
    _gpuImageView = [[GPUImageView alloc] initWithFrame:self.preview.bounds];
    [self.preview addSubview:_gpuImageView];
    
    //美颜滤镜
    _beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [_videoCamera addTarget:_beautifyFilter];
    
    //美颜滤镜
    [_beautifyFilter addTarget:_gpuImageView];
    
    //数据处理
    _dataHandler = [[AWGPUImageAVCaptureDataHandler alloc] initWithImageSize:CGSizeMake(self.videoConfig.width, self.videoConfig.height) resultsInBGRAFormat:YES capture:self];
    [_beautifyFilter addTarget:_dataHandler];
    _videoCamera.awAudioDelegate = _dataHandler;
    
    [self.videoCamera startCameraCapture];
    
    [self updateFps:self.videoConfig.fps];
}

- (BOOL)startCaptureWithRtmpUrl:(NSString *)rtmpUrl {
    return [super startCaptureWithRtmpUrl:rtmpUrl];
}

- (void)switchCamera {
    [self.videoCamera rotateCamera];
    [self updateFps:self.videoConfig.fps];
}

- (void)onStartCapture {
}

- (void)onStopCapture {
}

- (void)dealloc {
    [self.videoCamera stopCameraCapture];
}

@end
