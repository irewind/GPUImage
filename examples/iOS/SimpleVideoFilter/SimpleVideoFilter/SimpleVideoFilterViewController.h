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
    
//    NSDate* lastBatteryCheck;
}

- (IBAction)updateSliderValue:(id)sender;
-(void) stopRecording;
@end
