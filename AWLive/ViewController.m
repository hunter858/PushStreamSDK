//
//  ViewController.m
//  AWLive
//
//  Created by xxx on 5/11/16.
//
//

#import "ViewController.h"
#import "AWLiveCapture.h"
#import "AWFileManager.h"


@interface ViewController ()
@property (nonatomic, strong) AWLiveCapture *liveVideoCapture;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.liveVideoCapture = [[AWLiveCapture alloc] initWithViewController:self];
    
   
    [self initSubviews];
    
}

- (void)initSubviews {
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(0, 200, 100, 30)];
    [button setTitle:@"debugMenu" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(debugMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
    UIButton *button2 = [[UIButton alloc]initWithFrame:CGRectMake(0, 250, 100, 30)];
    [button2 setTitle:@"present" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(updatePresent) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
    UIButton *button3 = [[UIButton alloc]initWithFrame:CGRectMake(0, 300, 100, 30)];
    [button3 setTitle:@"dump" forState:UIControlStateNormal];
    [button3 addTarget:self action:@selector(dumpAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button3];
    
    [self.view bringSubviewToFront:button];
    [self.view bringSubviewToFront:button2];
    [self.view bringSubviewToFront:button3];
}


- (void)updatePresent {
    __weak typeof(self) weakSelf = self;
    NSArray *array = @[AVCaptureSessionPreset3840x2160,
                      AVCaptureSessionPreset1920x1080,
                      AVCaptureSessionPreset1280x720,
                      AVCaptureSessionPresetiFrame960x540,
                      AVCaptureSessionPreset640x480];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"change Present" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *preset in array) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:preset style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.liveVideoCapture updatePresent:preset];
        }];
        [alertController addAction:action];
    }
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancel];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)dumpAction {
    AWFileManager *fileManager = self.liveVideoCapture.fileManager;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"dump action" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *action0 = [UIAlertAction actionWithTitle:@"dump PCM" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [fileManager createAndOpenFileWithMediaType:MEDIA_TYPE_PCM];
    }];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"dump AAC" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [fileManager createAndOpenFileWithMediaType:MEDIA_TYPE_AAC];
    }];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"dump H264" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [fileManager createAndOpenFileWithMediaType:MEDIA_TYPE_H264];
    }];
    
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"dump FLV" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [fileManager createAndOpenFileWithMediaType:MEDIA_TYPE_FLV];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:action0];
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:cancel];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)debugMenu {
    
    AWFileManager *fileManager = self.liveVideoCapture.fileManager;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"debug" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *action0 = [UIAlertAction actionWithTitle:@"clean PCM" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [fileManager clearCacheWithMediaType:MEDIA_TYPE_PCM];
    }];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"clean AAC" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [fileManager clearCacheWithMediaType:MEDIA_TYPE_AAC];
    }];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"clean H264" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [fileManager clearCacheWithMediaType:MEDIA_TYPE_H264];
    }];
    
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"clean FLV" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [fileManager clearCacheWithMediaType:MEDIA_TYPE_FLV];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:action0];
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController addAction:action3];
    [alertController addAction:cancel];

    [self presentViewController:alertController animated:YES completion:nil];
    
}


-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [self.liveVideoCapture onLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
