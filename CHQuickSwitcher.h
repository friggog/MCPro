#import <UIKit/UIKit.h>

@interface CHQuickSwitcher:UIToolbar {
    UIButton *upButton;
    UIButton *downButton;
}

-(id) initWithFrame:(CGRect)frame andTargetForButtons:(id)target;
-(void) setCanGoUp:(BOOL)a;
-(void) setCanGoDown:(BOOL)a;

@end
