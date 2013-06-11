#import "SimpleVideoFilterViewController.h"

@implementation SimpleVideoFilterViewController

#define SCREEN_WIDTH 320.0f
#define SCREEN_HEIGHT 460.0f

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    GPUImageView *filterView = (GPUImageView *)self.view;
        
//    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetiFrame960x540 cameraPosition:AVCaptureDevicePositionBack];
    
//    [videoCamera forceProcessingAtSizeRespectingAspectRatio:CGSize(640x480)];

    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

//    filter = [[GPUImageSepiaFilter alloc] init];
    filter = [[GPUImageFilter alloc] init];

    blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter.mix = 1.0;    

    UIView* v = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0f, 460.0f)];
    v.backgroundColor = [UIColor clearColor];
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"14.png"]];
    icon.backgroundColor = [UIColor clearColor];
    [v addSubview:icon];
    icon.frame = CGRectMake(320-72-20.0f, 20.0f, 72.0f, 72.0f);
    
    stopBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    stopBtn.frame =  CGRectMake(20,20,70,40);
    [stopBtn setTitle:@"Stop" forState:UIControlStateNormal];
    [stopBtn addTarget:self action:@selector(stopRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopBtn];
    
    UILabel* fpsLabel = (UILabel*)[[UILabel alloc] initWithFrame:CGRectMake(20,SCREEN_HEIGHT-120,193,21)];
    fpsLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    fpsLabel.text = @"FPS: 0";
    fpsLabel.textAlignment = UITextAlignmentCenter;
    fpsLabel.backgroundColor = [UIColor clearColor];
    fpsLabel.textColor = [UIColor whiteColor];
    [v addSubview:fpsLabel];
    
    UILabel* timeLabel = (UILabel*)[[UILabel alloc] initWithFrame:CGRectMake(20,SCREEN_HEIGHT-90,193,21)];
    timeLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    timeLabel.text = @"Time: 0.0 s";
    timeLabel.textAlignment = UITextAlignmentCenter;
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.textColor = [UIColor whiteColor];
    [v addSubview:timeLabel];
    
    UILabel* recLabel = (UILabel*)[[UILabel alloc] initWithFrame:CGRectMake(20,SCREEN_HEIGHT-60,193,21)];
    recLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    recLabel.text = @"Recording: OFF";
    recLabel.textAlignment = UITextAlignmentCenter;
    recLabel.backgroundColor = [UIColor clearColor];
    recLabel.textColor = [UIColor whiteColor];
    [v addSubview:recLabel];
    
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    float batteryLevel = [myDevice batteryLevel];
    
    UILabel* batteryLabel = (UILabel*)[[UILabel alloc] initWithFrame:CGRectMake(20,SCREEN_HEIGHT-30,193,21)];
    batteryLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    batteryLabel.text = [NSString stringWithFormat:@"Battery: %f%%",batteryLevel * 100];
    batteryLabel.textAlignment = UITextAlignmentCenter;
    batteryLabel.backgroundColor = [UIColor clearColor];
    batteryLabel.textColor = [UIColor whiteColor];
    [v addSubview:batteryLabel];

    uiElementInput = [[GPUImageUIElement alloc] initWithView:v];
    
    [filter addTarget:blendFilter];
    [uiElementInput addTarget:blendFilter];
//    blendFilter forceProcessingAtSizeRespectingAspectRatio:CGSize
    [videoCamera addTarget:filter];

     GPUImageFilter*  filter2 = [[GPUImageFilter alloc] init];
//        [blendFilter addTarget:filter2];
//        [filter2 addTarget:filterView];
    [filter2 forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(320, 460)];
    __unsafe_unretained GPUImageUIElement *weakUIElementInput = uiElementInput;
    
    NSDate *startTime = [NSDate date];
    __block NSTimeInterval initInterval = [[NSDate date] timeIntervalSinceReferenceDate];
    __block NSTimeInterval diff = 0;
    
    __block SimpleVideoFilterViewController* bself = self;
    
    [filter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime)
    {
        timeLabel.text = [NSString stringWithFormat:@"Time: %f s", -[startTime timeIntervalSinceNow]];
        
        recLabel.text = [NSString stringWithFormat:@"Recording: %@",recording?@"YES":@"NO"];
        
        diff = [NSDate timeIntervalSinceReferenceDate] - initInterval;
        
        if (diff - bself.lastInterval > 1.0)
        {
            bself.lastInterval = diff;
            bself.lastFps = bself.fps;
            bself.fps = 0;
        }
        bself.fps++;
        fpsLabel.text = [NSString stringWithFormat:@"FPS: %i",bself.lastFps];
        
        if ((diff) > 60.0f )
        {
            float batteryLevel = [myDevice batteryLevel];
            
            batteryLabel.text = [NSString stringWithFormat:@"Battery: %f%%",batteryLevel * 100];

            initInterval = [[NSDate date] timeIntervalSinceReferenceDate];
            NSLog (@"battery check");
            
            if (batteryLevel < 0.25f)
            {
                [self stopRecording];
            }
            
            [self restartRecording];
        }
        
        [weakUIElementInput update];
    }];
    
    [videoCamera startCameraCapture];
    
    [self startRecordingForFilter:blendFilter];
//        [self startRecordingForFilter:filter];
//    [self startRecordingForFilter:videoCamera];
}

-(void)startRecordingForFilter:(id)theFilter
{
    // Record a movie for 10 s and store it in /Documents, visible via iTunes file sharing
    
    NSString* movieName = [NSString stringWithFormat:@"movie-%@",[[NSDate date] description]];
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.m4v",movieName]];
    //unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(540.0, 960.0)];
//        movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1280.0, 720.0)];
        movieWriter.hasAudioTrack = NO;
    //    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1080.0, 1920.0)];
    [theFilter addTarget:movieWriter];
    
    //[[UIScreen mainScreen] setBrightness:0.0];
    
    double delayToStartRecording = 0.5;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        stopBtn.enabled = YES;
        recording = YES;
        NSLog(@"Start recording");
        videoCamera.audioEncodingTarget = nil;
        
        [movieWriter startRecording];
    });
}

-(void) restartRecording
{
    [self stopRecording];
 
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        [self startRecordingForFilter:blendFilter];
    });
}

        double delayInSeconds = 30.0;
        dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
            
            [filter removeTarget:movieWriter];
            videoCamera.audioEncodingTarget = nil;
            [movieWriter finishRecording];
            NSLog(@"Movie completed");
            
//            [videoCamera.inputCamera lockForConfiguration:nil];
//            [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
//            [videoCamera.inputCamera unlockForConfiguration];
        });
    });
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Map UIDeviceOrientation to UIInterfaceOrientation.
    UIInterfaceOrientation orient = UIInterfaceOrientationPortrait;
    switch ([[UIDevice currentDevice] orientation])
    {
        case UIDeviceOrientationLandscapeLeft:
            orient = UIInterfaceOrientationLandscapeLeft;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            orient = UIInterfaceOrientationLandscapeRight;
            break;
            
        case UIDeviceOrientationPortrait:
            orient = UIInterfaceOrientationPortrait;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            orient = UIInterfaceOrientationPortraitUpsideDown;
            break;
            
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            // When in doubt, stay the same.
            orient = fromInterfaceOrientation;
            break;
    }
    videoCamera.outputImageOrientation = orient;
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; // Support all orientations.
}

@end
