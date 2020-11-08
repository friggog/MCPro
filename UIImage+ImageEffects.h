
#import <Accelerate/Accelerate.h>

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "Headers.h"

@interface UIImage (ImageEffects)

-(UIImage*) imageWithBlurRadius:(CGFloat)radius;

@end
