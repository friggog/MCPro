#import <UIKit/UIKit.h>

@interface CircleColourView :UIView
- (id)initWithFrame:(CGRect)frame andColour:(UIColor *)colour;
@end

@interface CircleGradientView :UIView
- (id)initWithFrame:(CGRect)frame andColours:(NSArray *)colours andTextColour:(UIColor *)textCol;
@end
