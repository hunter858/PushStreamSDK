# PushStreamSDK
前段时间在`github`偶然看到了一个推流的的工程，出于兴趣拜读了一下源码；
其中也发现了一些问题; 不知道作者是出于什么样的目的没有修复这些问题，在这里我罗列了一下并修复相关问题 ；

关键字：
AudioToolBox、VideoToolBox、FAAC、libX264、libRTMP、AVFoundation


修复后的仓库地址
```
https://github.com/hunter858/PushStreamSDK
```


#### 视频问题：
1.视频在`AWAVCaptureTypeSystem  + 软编码`模式下,  视频条状马赛克
2.视频在`AWAVCaptureTypeSystem  + 硬编码`模式下，画面底部出现绿边
3.视频在`AWAVCaptureTypeGPUImage + 软编码 `模式下，画面卡住不动
4.视频在`AWAVCaptureTypeGPUImage + 软编码`模式下，画面条状马赛克

#### 音频问题：
1. 音频在`AWAudioEncoderTypeHWAACLC`模式下，声音不连续
2. 音频在`AWAudioEncoderTypeSWFAAC`模式下，声音有杂言和颤音


#### 问题1:视频在AWAVCaptureTypeSystem + 软编码 模式下，视频条状马赛克
![bug1修复前后对比](https://upload-images.jianshu.io/upload_images/1716313-ea806716bbcf75d3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

问题原因：
出现该问题的原因是，项目中采集到的视频帧率为`720x1280`；
但是在送入软编码器的实际数据是 `768x1280`，`768` 是` Y分量 BytesPerRow`的长度；




#### 问题2: 视频在AWAVCaptureTypeSystem +硬编码 模式下，画面底部出现绿边

![bug2修复前后对比](https://upload-images.jianshu.io/upload_images/1716313-24f0e65ccd0b9cac.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

问题原因：
出现该问题的原因是，`pixeBuffer`转`NSData` 然后`NSData`再转回`YUV`类型的`pixeBuffer`的过程中，`Y分量`的数据拷贝的实际长度是`768 `，代码逻辑中配置的为`videoConfig`的宽度`720`导致的;

#### 问题3: 视频在AWAVCaptureTypeGPUImage + 软编码模式下，画面卡住不动

问题原因：
原有代码在`AudioToolBox`音频编码的过程中，创建的`aw_flv_audio_tag`对象实际不包含音频数据，所以导致推的视频流实际没有音频流，从而导致画面卡住,修复该编码逻辑或渠道正确的`PCM数据`即可；
![image.png](https://upload-images.jianshu.io/upload_images/1716313-abd4221fb091a82f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



#### 问题4: 视频在AWAVCaptureTypeGPUImage + 硬编码模式下，画面花屏

![bug4修复前后对比](https://upload-images.jianshu.io/upload_images/1716313-ae0afc98485298aa.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
问题原因：
问题的原因是在使用`GPUImage`框架，获取的到的`ARGB`数据在转`YUV`数据的过程中 数据拷贝有问题 ，且`libYUV`框架的使用`ARGBToNV12()` 参数设置也有问题，和上面的问题属于同一类型的`bug`，`y_stride`不是正确的值导致的，修复该问题即可正常显示 `美颜后视频帧`；



#### 问题5: 音频在AWAudioEncoderTypeHWAACLC 模式下，声音不连续
问题原因：
在送入编码器的`PCM`数据未控制在 `1024`的样点的整数倍；应该在转码输入之前开辟一个`PCM`的`buffer`缓冲区，将传入数据控制在`1024`个样点即可解决问题

#### 问题6: 音频在 AWAudioEncoderTypeSWFAAC 模式下，颤音

```
该问题还在修复中....
该问题还在修复中....
该问题还在修复中....
```

其它关于项目的一些关键技术讲解可以看原作者的文章，这里不赘述了

*   [1小时学会：最简单的iOS直播推流（一）项目介绍](https://www.jianshu.com/p/30b82f1e61a9)
*   [1小时学会：最简单的iOS直播推流（二）代码架构概述](https://www.jianshu.com/p/77fea6e0eccb)
*   [1小时学会：最简单的iOS直播推流（三）使用系统接口捕获音视频](https://www.jianshu.com/p/19d07d5dd788)
*   [1小时学会：最简单的iOS直播推流（四）如何使用GPUImage，如何美颜](https://www.jianshu.com/p/7b484ee0fb15)
*   [1小时学会：最简单的iOS直播推流（五）yuv、pcm数据的介绍和获取](https://www.jianshu.com/p/d5489a8fe2a9)
*   [1小时学会：最简单的iOS直播推流（六）h264、aac、flv介绍](https://www.jianshu.com/p/92122e0dfdba)
*   [1小时学会：最简单的iOS直播推流（七）h264/aac 硬编码](https://www.jianshu.com/p/0f0fc1ec311a)
*   [1小时学会：最简单的iOS直播推流（八）h264/aac 软编码](https://www.jianshu.com/p/e8f56af4895d)*   [1小时学会：最简单的iOS直播推流（九）flv 编码与音视频时间戳同步](https://www.jianshu.com/p/24410b604ea9)
*   [1小时学会：最简单的iOS直播推流（十）librtmp使用介绍](https://www.jianshu.com/p/5c79b3b00d68)
*   [1小时学会：最简单的iOS直播推流（十一）sps&pps和AudioSpecificConfig介绍（完结）](https://www.jianshu.com/p/4297342231ee)


