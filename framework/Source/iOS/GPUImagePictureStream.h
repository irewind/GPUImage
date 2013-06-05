#import <UIKit/UIKit.h>
#import "GPUImageOutput.h"


@interface GPUImagePictureStream : GPUImageOutput
{
    CGSize pixelSizeOfImage;
    BOOL hasProcessedImage;
    
    dispatch_semaphore_t imageUpdateSemaphore;
}

// Initialization and teardown
- (id)initWithURL:(NSURL *)url;
- (id)initWithImage:(UIImage *)newImageSource;
- (id)initWithCGImage:(CGImageRef)newImageSource;
- (id)initWithImage:(UIImage *)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;
- (id)initWithCGImage:(CGImageRef)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;

// Image rendering
- (void)processImage;
- (void)processImageWithTime:(CMTime)frameTime;
- (void)setImage:(CGImageRef)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;
- (CGSize)outputImageSize;

@end
