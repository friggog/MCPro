#import "CircleViews.h"

static UIColor *darkenedColour(UIColor *color) {
    CGFloat amount = 0.75;
    CGFloat hue, saturation, brightness, alpha;
    if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        brightness += (amount-1.0);
        brightness = MAX(MIN(brightness, 1.0), 0.0);
        return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    }

    CGFloat white;
    if ([color getWhite:&white alpha:&alpha]) {
        white += (amount-1.0);
        white = MAX(MIN(white, 1.0), 0.0);
        return [UIColor colorWithWhite:white alpha:1];
    }

    return [UIColor clearColor];
}

@implementation CircleColourView
- (id)initWithFrame:(CGRect)frame andColour:(UIColor *)colour {
    self = [super initWithFrame:frame];
    if (self) {
        if ([colour isEqual:[UIColor clearColor]]) {
            self.hidden = YES;
        }
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        self.layer.cornerRadius = 15;
        self.layer.borderColor = [darkenedColour(colour) CGColor];
        self.layer.borderWidth = 2.0;
        self.backgroundColor = colour;
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)col {
    if (! [col isEqual:[UIColor clearColor]]) {
        self.hidden = NO;
        self.layer.borderColor = [darkenedColour(col) CGColor];
        [super setBackgroundColor:col];
    }
}

@end

@implementation CircleGradientView
- (id)initWithFrame:(CGRect)frame andColours:(NSArray *)colours andTextColour:(UIColor *)textCol {
    self = [super initWithFrame:frame];
    if (self && colours.count > 1) {
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        self.layer.cornerRadius = 15;
        self.layer.borderColor = [darkenedColour([colours objectAtIndex:0]) CGColor];
        self.layer.borderWidth = 2.0;
        self.layer.masksToBounds = YES;

        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[colours objectAtIndex:0] CGColor], (id)[[colours objectAtIndex:1] CGColor], nil];

        [self.layer insertSublayer:gradient atIndex:0];

        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        l.text = @"T";
        l.textAlignment = NSTextAlignmentCenter;
        l.textColor = textCol;
        [self addSubview:l];

        if ([[colours objectAtIndex:0] isEqual:[UIColor clearColor]] && [[colours objectAtIndex:1] isEqual:[UIColor clearColor]] && [textCol isEqual:[UIColor clearColor]]) {
            self.hidden = YES;
        }
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)col {
    if (! [col isEqual:[UIColor clearColor]]) {
        self.hidden = NO;
        self.layer.borderColor = [darkenedColour(col) CGColor];
        [super setBackgroundColor:col];
    }
}

@end
