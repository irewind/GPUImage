#import "SimpleVideoFilterViewController.h"

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kRateKey			= @"rate";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";
NSString *kTimedMetadataKey	= @"currentItem.timedMetadata";

#define FRAME_WIDTH 460
#define FRAME_HEIGHT 320

#define SCREEN_WIDTH 460.0f
#define SCREEN_HEIGHT 320.0f

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
    
    GPUImageView *filterView = (GPUImageView *)self.view;
        
    filter = [[GPUImageSepiaFilter alloc] init];
    
    blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter.mix = 1.0;

    UIView* v = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0 ,SCREEN_WIDTH, SCREEN_HEIGHT)];
    v.backgroundColor = [UIColor clearColor];
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"14.png"]];
    icon.backgroundColor = [UIColor clearColor];
    [v addSubview:icon];
    icon.frame = CGRectMake(SCREEN_WIDTH-72-20.0f, 20.0f, 72.0f, 72.0f);
    
    self.stopBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.stopBtn.frame =  CGRectMake(20,20,70,40);
    [self.stopBtn setTitle:@"Stop" forState:UIControlStateNormal];
    [self.stopBtn addTarget:self action:@selector(stopRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.stopBtn];

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
    
    [blendFilter addTarget:filterView];
    
    __unsafe_unretained GPUImageUIElement *weakUIElementInput = uiElementInput;
    
    NSDate *startTime = [NSDate date];
    __block NSTimeInterval initInterval = [[NSDate date] timeIntervalSinceReferenceDate];
    __block NSTimeInterval diff = 0;
    
    __block SimpleVideoFilterViewController* bself = self;

    [filter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime)
     {

        timeLabel.text = [NSString stringWithFormat:@"Time: %f s", -[startTime timeIntervalSinceNow]];
        
        recLabel.text = [NSString stringWithFormat:@"Recording: %@",bself.recording?@"YES":@"NO"];
        
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
                [bself stopRecording];
            }
            
            if (bself.stopBtn.enabled)
            {
                [bself restartRecording];
            }
        }

        [weakUIElementInput update];
     
    }];
    
    [self setupFFplayer];
    
    [self setupImageSource];
    
    [self startRecordingForFilter:blendFilter];
}

-(void) setupFFplayer
{
    video = [[Frames alloc] initWithVideo:@"rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov"];
    video.cgimageDelegate = self;
    // set output image size
	video.outputWidth = FRAME_WIDTH;
	video.outputHeight = FRAME_HEIGHT;
    [video setupCgimageSession];
  	// print some info about the video
	NSLog(@"video duration: %f",video.duration);
	NSLog(@"video size: %d x %d", video.sourceWidth, video.sourceHeight);
}


-(void)startRecordingForFilter:(id)theFilter
{
    // Record a movie for 10 s and store it in /Documents, visible via iTunes file sharing
    NSString* movieName = [NSString stringWithFormat:@"movie-%@",[[NSDate date] description]];
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.m4v",movieName]];
    //unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(FRAME_WIDTH, FRAME_HEIGHT)];
    
    [theFilter addTarget:movieWriter];
        
    [[UIScreen mainScreen] setBrightness:0.8];
    
    double delayToStartRecording = 0.5;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        self.stopBtn.enabled = YES;
        self.recording = YES;
        NSLog(@"Start recording");
            
        [source setAudioEncodingTarget:movieWriter];
        [movieWriter startRecording];
        
    });
    
    firstFrameWallClockTime = CFAbsoluteTimeGetCurrent();
}

-(void) restartRecording
{
    [self stopRecording];
 
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        [self startRecordingForFilter:blendFilter];
    });
}

-(IBAction)stopClicked:(id)sender
{
    self.stopBtn.enabled = NO;
    
    [self stopRecording];
}

-(void) stopRecording
{
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [[UIScreen mainScreen] setBrightness:0.8];
        
        [source setAudioEncodingTarget:nil];
        [blendFilter removeTarget:movieWriter];
        [movieWriter finishRecording];
    
        self.recording = NO;
    
        NSLog(@"Movie completed");        
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

//FFPlayer stuff

-(void)didOutputCGImageBuffer:(NSTimer *)timer {
    [video stepFrame];
    imageView.image = video.currentImage;
    
    runSynchronouslyOnVideoProcessingQueue(^{
            [self writeSample];
    });
}

-(void)setupImageSource
{
    CGImageRef imageRef = video.currentImage.CGImage;
    
    GPUImagePictureStream* picInput = [[GPUImagePictureStream alloc] initWithCGImage:imageRef];
    source = picInput;
    
    [source addTarget:filter];    
}

-(void) writeSample
{    
    
    CFAbsoluteTime thisFrameWallClockTime = CFAbsoluteTimeGetCurrent();
    CFTimeInterval elapsedTime = thisFrameWallClockTime - firstFrameWallClockTime;
    CMTime presentationTime =  CMTimeMake(elapsedTime * TIME_SCALE, TIME_SCALE);
    

        [source setImage:video.currentImage.CGImage smoothlyScaleOutput:NO];
        [source processImageWithTime:presentationTime];

}
@end
