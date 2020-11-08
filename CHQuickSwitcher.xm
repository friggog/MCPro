#import "CHQuickSwitcher.h"
#import "Headers.h"

@implementation CHQuickSwitcher

- (id)initWithFrame:(CGRect)frame andTargetForButtons:(id)target {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 5;
        self.clipsToBounds = YES;

        UIColor *tintCol = [[%c(CKUIBehavior) sharedBehaviors] appTintColor];

        upButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        UIImage *uImg = [UIImage imageWithContentsOfFile:@"/Applications/MobileMail.app/chevron-up.png"];
        [upButton addTarget:target action:@selector(prevConvo) forControlEvents:UIControlEventTouchDown];
        [upButton setImage:uImg forState:UIControlStateNormal];
        upButton.frame = CGRectMake(2, 0, 30, 30.0);
        upButton.tintColor = tintCol;
        [self addSubview:upButton];

        downButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        UIImage *dImg = [UIImage imageWithContentsOfFile:@"/Applications/MobileMail.app/chevron-down.png"];
        [downButton addTarget:target action:@selector(nextConvo) forControlEvents:UIControlEventTouchDown];
        [downButton setImage:dImg forState:UIControlStateNormal];
        downButton.frame = CGRectMake(2, 30, 30, 30.0);
        downButton.tintColor = tintCol;
        [self addSubview:downButton];
    }
    return self;
}

- (void)setCanGoUp:(BOOL)a {
    if (a) {
        upButton.alpha = 1;
    }
    else {
        upButton.alpha = 0.3;
    }
}

- (void)setCanGoDown:(BOOL)a {
    if (a) {
        downButton.alpha = 1;
    }
    else {
        downButton.alpha = 0.3;
    }
}

@end
