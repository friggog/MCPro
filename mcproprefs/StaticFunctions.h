#import <sys/utsname.h>

static inline NSString *machineName() {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

static inline NSString *localisedStringForKey(NSString *key) {
    return [[NSBundle bundleWithPath:@"/Library/PreferenceBundles/MCProPrefs.bundle"] localizedStringForKey:key value:key table:nil];
}

static inline UIColor *UIColorFromHexString(NSString *hexString) {
    unsigned rgbValue = 0;
    if (! hexString) {
        return [UIColor clearColor];
    }
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

static inline NSString *HexStringFromUIColor(UIColor *colour) {
    CGFloat r, g, b, a;
    [colour getRed:&r green:&g blue:&b alpha:&a];
    int rgb = (int)(r * 255.0f)<<16 | (int)(g * 255.0f)<<8 | (int)(b * 255.0f)<<0;
    return [NSString stringWithFormat:@"#%06x", rgb];
}

static inline CGRect currentScreenBoundsDependOnOrientation() {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        screenBounds.size = CGSizeMake(width, height);
    }
    else if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        screenBounds.size = CGSizeMake(height, width);
    }
    return screenBounds;
}
