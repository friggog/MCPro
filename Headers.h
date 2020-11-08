#import <UIKit/_UIBackdropView.h>
#import <UIKit/_UIBackdropViewSettings.h>

@class CHQuickSwitcher;
//@class CGColor;

@interface _UISearchBarSearchFieldBackgroundView : UIView {}
-(void) setStrokeColor:(id)arg1;
-(void) setFillColor:(id)arg1;
@end

@interface UITableViewCellContentView : UIView {}
@end

@interface UITableViewCellScrollView : UIView {}
@end

@interface MFRecipientTableViewCellDetailView : UIView {}
@end

@interface MFRecipientTableViewCellTitleView : UIView {}
@end

@interface ABContactHeaderView : UIView {}
@end

@interface ABMemberNameView : UIView {}
@end

@interface PUCollectionView : UIView {}
@end

@interface CKTypingIndicatorLayer : CALayer {}
@property (nonatomic, retain) NSString * senderName;
-(CGColorRef) newBubbleColour;
-(CGColorRef) newTextColour;
@end

@interface IMPerson : NSObject
@property (nonatomic, readonly) void* _recordRef;
@property (nonatomic, readonly) int _recordID;
@end

@interface IMHandle : NSObject
@property int addressBookIdentifier;
@property (nonatomic, retain, readonly) NSString* fullName;
@property IMPerson* person;
@end

@interface CKEntity : NSObject
@property (nonatomic, readonly) int identifier;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* fullName;
@property (nonatomic, readonly) void* abRecord;
@property (nonatomic, readonly) UIImage* transcriptContactImage;
@property (nonatomic) IMHandle* handle;
-(id) __ck_displayContactImage;
@end

@interface IMChat : NSObject
-(NSArray*) chatItems;
- (id)allChatProperties;
@end

@interface CKConversation : NSObject {}
@property (readonly) NSArray* messages;
@property (getter = isGroupConversation, readonly) BOOL groupConversation;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, retain) NSArray* recipients;
@property (nonatomic, readonly) CKEntity* recipient;
@property (nonatomic, readonly) NSArray* recipientStrings;
@property (nonatomic, readonly) BOOL buttonColor;
@property (nonatomic, readonly) id preferredService;
@property (nonatomic, retain) UIImage* thumbnailImage;
@property (nonatomic, retain) IMChat* chat;
@property (nonatomic, assign) BOOL unrepliedTo;
-(void) reloadIfNeeded;
-(void) setNeedsReload;
-(void*) abRecord;
-(void) loadMoreMessages;
-(void) setLimitToLoad:(unsigned int)arg1;
-(void) _handlePreferredServiceChangedNotification:(id)arg1;
-(id) uniqueIdentifier;
@end

@interface CKIMMessage : NSObject  {}
@property (readonly) BOOL isSMS;
@property (readonly) BOOL isFromMe;
@property (readonly) BOOL isOutgoing;
@property (readonly) BOOL isFromFilteredSender;
@property (readonly) BOOL isRead;
@property (readonly) BOOL isDelivered;
@property (readonly) BOOL isWaitingForDelivery;
@property (readonly) BOOL failedSend;
@property (retain) CKConversation* conversation;
@property (readonly) NSString* previewText;
@property (retain) CKEntity* sender;
@end

@interface CKTranscriptDataRow : NSObject {}
@property (retain) CKIMMessage* message;
@end

@interface CKTranscriptCollectionView : UICollectionView {}
@end

@interface UIStatusBar : NSObject {}
-(void) requestStyle:(int)arg1 animated:(BOOL)arg2;
@property (nonatomic, retain) UIColor* foregroundColor;
@end
/*
   @interface _UIBackdropView : UIView {}
   - (void)transitionToColor:(id)arg1;
   - (void)transitionToSettings:(id)arg1;
   @property (assign,nonatomic) long long style;
   @end

   @interface _UIBackdropViewSettings : NSObject {}
 + (id)settingsForStyle:(int)arg1;
   - (void)setColorTint:(id)arg1;
   @end
 */
@interface _UITextFieldRoundedRectBackgroundViewNeue : UIView {}
@property (retain) UIColor* fillColor;
@property (retain) UIColor* strokeColor;
@end

@interface CKMessageEntryView : UIView {}
@property (retain) UIButton* sendButton;
@property BOOL sendButtonColor;
@property (retain) _UITextFieldRoundedRectBackgroundViewNeue* coverView;
@property (nonatomic, copy) NSString* placeholderText;
@property (nonatomic, retain) id contentView;
@property (nonatomic, retain) _UIBackdropView* backdropView;
-(void) updateBackgroundColour;
-(void) messageEntryContentViewDidChange:(id)arg1;
//8.4
@property (nonatomic, retain) UIButton* audioButton;
@property (nonatomic, retain) UIButton* photoButton;
@end

@interface CKMessageEntryTextView : UITextView {}
@property (nonatomic, retain) UILabel* placeholderLabel;
@end

@interface CKMultipleRecipientCollapsedTableViewCell : UITableViewCell {}
@end

@interface UITextSelectionView : UIView {}
@end
@interface CKConversationListCell : UITableViewCell {}
@property (nonatomic, retain) UIView *unrepliedView;
@property (nonatomic, retain) CKConversation *associatedConversation;
@end

@interface CKConversationList : NSObject {}
+(id) sharedConversationList;
-(id) conversations;
@end

@interface CKConversationListController : NSObject {}
-(id) tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2;
@property (retain) CKConversationList* conversationList;
@end

@interface CKGradientView : UIView
@property (retain) NSArray* colors;
@end

@interface CKGradientReferenceView : UIView {}
@end

@interface CKBalloonView : UIView
@property (nonatomic, retain) NSString *senderName;
@end

@interface CKColoredBalloonView : CKBalloonView
@property int color;
@property (retain) CKGradientView* gradientView;
@end

@interface CKBalloonImageView : UIView
@end

@interface CKTranscriptMessageCell : UIView
@property (assign, nonatomic) char orientation;
@property (nonatomic, retain) UIImage* contactImage;
@property (nonatomic, retain) CKBalloonImageView* contactImageView;
-(void) setWantsContactImageLayout:(BOOL)a;
-(void) layoutSubviewsForContents;
@property (nonatomic, assign) BOOL wantsContactPic;

@property (nonatomic, retain) UIView *avatarView;
@end

@interface CKTranscriptBalloonCell : CKTranscriptMessageCell
@property (retain) CKBalloonView* balloonView;
@end

@interface CKTranscriptCollectionViewController : UIViewController {}
@property (retain) UIView* collectionView;
@property (nonatomic, retain) CKConversation* conversation;
-(void) reloadData;
@end

@interface CKTranscriptStatusController : NSObject {}
-(void) activateThemeForContactWithName:(NSString*)name;
@end

@interface CKTranscriptController : UIViewController {}
@property (retain) CKTranscriptCollectionViewController* collectionViewController;
@property (nonatomic, retain) CKMessageEntryView* entryView;
@property (nonatomic, retain) CHQuickSwitcher *quickSwitcher;
@property (nonatomic, retain) CAGradientLayer *gradientBackground;
@property (nonatomic, retain) UIImageView *backgroundImageView;
-(void) activateThemeForContactWithName:(NSString*)name;

-(CKConversation*) conversation;
-(void) nextConvo;
-(void) prevConvo;
-(void) setConversation:(id)arg1;
-(void) _refreshViewForCurrentConversationIfNeeded;
-(void) _refreshViewForNewRecipientIfNeeded;
@end

@interface CKUIBehavior : NSObject {}
+(id) sharedBehaviors;
-(id) appTintColor;
-(id) blue_balloonColors;
-(id) green_balloonColors;
-(id) gray_balloonTextColor;
-(id) green_balloonTextColor;
-(id) blue_balloonTextColor;
-(id) transcriptBackgroundColor;
-(CGFloat) transcriptContactImageDiameter;
-(CGFloat) conversationListRowHeight;
-(id) gray_balloonColors;
-(id) lightGrayColor;
-(id) gray_sendButtonColor;
@property (nonatomic, readonly) UIEdgeInsets contactPhotoTranscriptInsets;

@end

@interface UIImage (custom) {}
+(id) defaultDesktopImage;
@end

@interface CKEditableCollectionViewCell : NSObject {}
@property (retain) UIImageView* checkmark;
@end

@interface CouriaController
@property (strong, nonatomic) UIButton* photoButton;
@property (strong, nonatomic) NSString* userIdentifier;
@property (strong, nonatomic) UILabel* titleLabel;
@property (strong, nonatomic) UIImageView* mainView;
@property (strong, nonatomic) UIView* messagesView;
-(void) updateCouriaMainViewAndReset:(BOOL)reset;
@end

@interface CouriaMessageView : NSObject {}
@property (assign, nonatomic) BOOL outgoing;
@property (retain, nonatomic) NSString* message;
@property (strong, nonatomic) UIImageView* imageView;
@property (strong, nonatomic) UILabel* textView;
@end

@interface CouriaMessageCell : UIView
@property (strong, nonatomic) CouriaMessageView* messageView;
@property (strong, nonatomic) UILabel* timestampLabel;
@property (assign) BOOL hasTimestamp;
@end

@interface UIView (CHEW)
@property (retain, nonatomic) UIImage* image;
@end

@interface CKTextBalloonView : CKColoredBalloonView
-(id) textView;
@end

@interface UIImage (chew)
+(id) imageWithContentsOfCPBitmapFile:(id)arg1 flags:(int)arg2;
@end

@interface UITableView (chew)
-(void) setTableHeaderBackgroundColor:(id)arg1;
@end

@interface UITableViewCell (chew)
-(void) setSelectionTintColor:(id)arg1;
-(void) updateSelectedView;
-(void) _setupSelectedBackgroundView;
@end

@interface _UIDatePickerView : UIView
@end

@interface UIApplication (chew)
-(NSDate*) todaysDateFromString:(NSString*)time;
-(void) setDarkModeEnabled:(BOOL)enabled;
-(void) updateForDarkMode;
-(UIStatusBar*) statusBar;
@end

@interface UITableViewIndex : UITableViewCell
@property (nonatomic, retain) UIColor* indexBackgroundColor;
@end

@interface ABContactCell : UITableViewCell
@end

@interface UILabel (chew)
-(void) updateTextColour;
@end

@interface UITableViewCellSelectedBackground : UIView
-(void) setSelectionTintColor:(id)arg1;
@end

@interface _MFMailRecipientTextField : UIView
@end

@interface CKContactBalloonView : UIView
@end

@interface CKTranscriptTypingIndicatorCell : CKTranscriptMessageCell
@property (nonatomic, retain) CKTypingIndicatorLayer* typingIndicatorLayer;
@end

@interface IMService : NSObject
+(id) iMessageService;
+(id) smsService;
-(id) __ck_displayName;
-(BOOL) __ck_displayColor;
@end

@interface IMMessage : NSObject
@property (nonatomic) NSString * text;
@end

@interface IMMessageChatItem : NSObject
@property (nonatomic, retain, readonly) IMHandle* sender;
@property (readonly) BOOL isFromMe;
@property (nonatomic, retain, readonly) IMMessage* message;
@end

@interface CKBalloonChatItem : NSObject
@property (getter = isFromMe, nonatomic, readonly) bool fromMe;
@property (nonatomic, retain, readonly) IMHandle* sender;
@end

@interface CKComposeRecipientContainerView : UIView
@property (nonatomic, retain) _UIBackdropView* backdropView;
@end

@interface CKComposeRecipientView : UIView
@property (nonatomic, readonly) UILabel* labelView;
@property (nonatomic, readonly) UITextView* textView;
@end

@interface IMChatItem : NSObject
@property (nonatomic, retain, readonly) IMHandle* sender;
@property (nonatomic) BOOL isFromMe;
@end

@interface CKChatItem : NSObject
@property (nonatomic, retain, readonly) UIImage* contactImage;
@property (nonatomic, retain) IMChatItem* IMChatItem;
@property (nonatomic) BOOL hasTail;
@property id contact;
@end

@interface CKAddressBook : NSObject
+(id) transcriptContactImageOfDiameter:(double)arg1 forRecordID:(int)arg2;
@end

@interface CKTranscriptRecipientsHeaderFooterView : UIView
@property (nonatomic, retain) UILabel* headerLabel;
@property (nonatomic, retain) UILabel* preceedingSectionFooterLabel;
@end

@interface CKAvatarView : UIControl
-(id)initWithContact:(id)c;
@property (nonatomic, retain) id contact;
@end

@interface CKTranscriptGroupHeaderView : UIView
@property (nonatomic, retain) _UIBackdropView *backdropView;
@end

@interface CNAvatarCardActionCell : UIView
- (UIImageView*)actionImageView;
@end
