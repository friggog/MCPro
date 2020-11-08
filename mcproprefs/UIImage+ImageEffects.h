
#import <Accelerate/Accelerate.h>

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface UIImage (ImageEffects)
- (UIImage *)imageWithBlurRadius:(CGFloat)radius;
- (UIImage *)scaledToSize:(CGSize)newSize;
- (UIImage *)roundImageInFrame:(CGRect)frame;
+ (UIImage *)imageWithContentsOfCPBitmapFile:(id)arg1 flags:(int)arg2;
@end
