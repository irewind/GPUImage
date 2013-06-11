#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFilterViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageAlphaBlendFilter *blendFilter;
    GPUImageMovieWriter *movieWriter;
    GPUImageUIElement* uiElementInput;
    UIButton* stopBtn;
    BOOL recording;
    
}

@property (assign,nonatomic) int fps;
@property (assign,nonatomic) int lastFps;
@property (assign,nonatomic) NSTimeInterval lastInterval;
- (IBAction)updateSliderValue:(id)sender;
-(void) stopRecording;
@end
