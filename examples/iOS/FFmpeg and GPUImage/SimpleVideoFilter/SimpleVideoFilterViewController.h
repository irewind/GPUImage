#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import <FFPlayer/Frames.h>

@interface SimpleVideoFilterViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageAlphaBlendFilter *blendFilter;
    GPUImageMovieWriter *movieWriter;
    GPUImageUIElement* uiElementInput;
    GPUImageRawDataInput* rawInput;
    CFAbsoluteTime firstFrameWallClockTime;
    EAGLContext* oglContext;
    IBOutlet UIImageView* imageView;
    GLuint defaultFramebuffer;
        
    id source;
    
    NSTimer* iTimer;
    Frames *video;
}
@property (assign,nonatomic) int fps;
@property (assign,nonatomic) int lastFps;
@property (assign,nonatomic) NSTimeInterval lastInterval;
@property (strong,nonatomic) UIButton* stopBtn;
@property (assign,nonatomic) BOOL recording;

- (IBAction)updateSliderValue:(id)sender;
-(void) stopRecording;

@end
