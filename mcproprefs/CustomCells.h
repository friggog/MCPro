#import <Preferences/Preferences.h>
#import <UIKit/_PSDeleteButtonCell.h>
#import <UIKit/UIKit.h>

@class CircleColourView;

@interface CHMCBubbleLinkCell :PSTableCell
@end

@interface CHMCBackgroundLinkCell :PSTableCell
@end

@interface CHMCContactLinkCell :PSTableCell
@end

@interface CHMCContactLinkCellWithColours :CHMCContactLinkCell
@end

@interface CHMCBackgroundImageViewCell :PSTableCell
@property (nonatomic, retain) UIImageView *previewImageView;
@property (nonatomic, retain) UIView *previewColourOverlayView;
@end

@interface PSDeleteTableCell :_PSDeleteButtonCell
@end

@interface CHMCBannerCell :PSTableCell {}
@end

@interface CHMCBetterSliderCell :PSSliderTableCell <UIAlertViewDelegate, UITextFieldDelegate> {
    CGFloat minimumValue;
    CGFloat maximumValue;
    NSString *title;
}
- (void)presentPopup;
@end

@interface CHMCTimeRangeControlCell :PSTableCell
@end

@interface CHMCDatePickerViewCell :PSTableCell
@end

@interface CHMCBlankTableCell :PSTableCell
@end

@interface CHMCButtonCell :PSTableCell
@end

@interface CHMCLinkToColourPickerCell :PSTableCell {
    CircleColourView *circle;
}
@end

@interface CHMCThemeListItemCell :PSTableCell
@end
