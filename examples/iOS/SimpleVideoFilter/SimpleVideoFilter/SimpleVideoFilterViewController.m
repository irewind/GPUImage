#import "SimpleVideoFilterViewController.h"

@implementation SimpleVideoFilterViewController

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
    
    if ([GPUImageContext supportsFastTextureUpload])
    {
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
        CIDetector* faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    }

    
    GPUImageView *filterView = (GPUImageView *)self.view;
        
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
    
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    filter = [[GPUImageSepiaFilter alloc] init];
    [videoCamera addTarget:filter];
    
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
    
    UILabel* timeLabel = (UILabel*)[[UILabel alloc] initWithFrame:CGRectMake(20,372,193,21)];
    timeLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    timeLabel.text = @"Time: 0.0 s";
    timeLabel.textAlignment = UITextAlignmentCenter;
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.textColor = [UIColor whiteColor];
    [v addSubview:timeLabel];

    UILabel* recLabel = (UILabel*)[[UILabel alloc] initWithFrame:CGRectMake(20,401,193,21)];
    recLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    recLabel.text = @"Recording: OFF";
    recLabel.textAlignment = UITextAlignmentCenter;
    recLabel.backgroundColor = [UIColor clearColor];
    recLabel.textColor = [UIColor whiteColor];
    [v addSubview:recLabel];    
    
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    float batteryLevel = [myDevice batteryLevel];
    
    UILabel* batteryLabel = (UILabel*)[[UILabel alloc] initWithFrame:CGRectMake(20,430,193,21)];
    batteryLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    batteryLabel.text = [NSString stringWithFormat:@"Battery: %f%%",batteryLevel * 100];
    batteryLabel.textAlignment = UITextAlignmentCenter;
    batteryLabel.backgroundColor = [UIColor clearColor];
    batteryLabel.textColor = [UIColor whiteColor];
    [v addSubview:batteryLabel];

    uiElementInput = [[GPUImageUIElement alloc] initWithView:v];
        
    [filter addTarget:blendFilter];
    [uiElementInput addTarget:blendFilter];
    
    [blendFilter addTarget:filterView];
    
    __unsafe_unretained GPUImageUIElement *weakUIElementInput = uiElementInput;
    
    NSDate *startTime = [NSDate date];
    __block NSTimeInterval initInterval = [[NSDate date] timeIntervalSinceReferenceDate];
    __block NSTimeInterval diff = 0;
    [filter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
        timeLabel.text = [NSString stringWithFormat:@"Time: %f s", -[startTime timeIntervalSinceNow]];
        
        recLabel.text = [NSString stringWithFormat:@"Recording: %@",recording?@"YES":@"NO"];
        
        diff = [NSDate timeIntervalSinceReferenceDate] - initInterval;
        
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
}

-(void)startRecordingForFilter:(id)theFilter
{
    // Record a movie for 10 s and store it in /Documents, visible via iTunes file sharing
    
    NSString* movieName = [NSString stringWithFormat:@"movie-%@",[[NSDate date] description]];
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.m4v",movieName]];
    //unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
    //    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
    //    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720.0, 1280.0)];
    //    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1080.0, 1920.0)];
    [theFilter addTarget:movieWriter];
    
    [[UIScreen mainScreen] setBrightness:0.0];
    
    double delayToStartRecording = 0.5;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        stopBtn.enabled = YES;
        recording = YES;
        NSLog(@"Start recording");
        videoCamera.audioEncodingTarget = movieWriter;
        [movieWriter startRecording];
        
        //        NSError *error = nil;
        //        if (![videoCamera.inputCamera lockForConfiguration:&error])
        //        {
        //            NSLog(@"Error locking for configuration: %@", error);
        //        }
        //        [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        //        [videoCamera.inputCamera unlockForConfiguration];
        
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

-(void) stopRecording
{
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [[UIScreen mainScreen] setBrightness:0.8];
        
        videoCamera.audioEncodingTarget = nil;
        [blendFilter removeTarget:movieWriter];
        [movieWriter finishRecording];
    
        recording = NO;
    
        NSLog(@"Movie completed");
        
        stopBtn.enabled = NO;
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

- (IBAction)updateSliderValue:(id)sender
{
    [(GPUImageSepiaFilter *)filter setIntensity:[(UISlider *)sender value]];
}

@end
