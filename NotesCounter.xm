#import "NotesCounter.h"

static NCLabel *notesCounterLabel;
static CGFloat kNotesCounterOuterBottomPadding = 45.0, kNotesCounterHeight = 30.0;
static CGFloat kNotesCounterOuterSideMaxCombinedMargin = 20.0;
static CGFloat kNotesCounterInnerSidePadding = 3.0, kNotesCounterInnerTopPadding = 3.0;

// Margin from bottom of view. Does not include height of view itself, only attachment views beneath.
static CGFloat kNotesCounterBottomMargin;

%hook NotesDisplayController

// Adds a new notesCounter label, or accessing the existing one (per instance of NotesDisplayController)
// and uses -notesCounterResizeForContents to resize it appropriately, in word counting mode.
- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);

    UITextView *noteTextView = MSHookIvar<NoteContentLayer *>(self, "_contentLayer").textView;
    kNotesCounterBottomMargin = 0.0;

    if (!notesCounterLabel) {
        notesCounterLabel = [[NCLabel alloc] initWithFrame:CGRectZero andFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:[UIFont systemFontSize]]];
        notesCounterLabel.textInset = UIEdgeInsetsMake(kNotesCounterInnerTopPadding, kNotesCounterInnerSidePadding, kNotesCounterInnerTopPadding, kNotesCounterInnerSidePadding);
        notesCounterLabel.backgroundColor = [UIColor colorWithRed:52.0/255.0 green:53.0/255.0 blue:46.0/255.0 alpha:1.0];
        notesCounterLabel.layer.masksToBounds = YES;
        notesCounterLabel.layer.cornerRadius = 10.0;

        UISwipeGestureRecognizer *swipeSwitchTypeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(notesCounterSwipeRecognized:)];
        swipeSwitchTypeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight;
        [notesCounterLabel addGestureRecognizer:swipeSwitchTypeRecognizer];
        [swipeSwitchTypeRecognizer release];

        [self.view addSubview:notesCounterLabel];
    }

    notesCounterLabel.alpha = 0.6;

    [self notesCounterResizeForContents:[NCLabel wordOrCharCountStringFromTextView:noteTextView isChar:NO] inTextView:noteTextView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesCounterKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesCounterKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

// Resizes and sets the text of notesCounter label as respective to frame rules in given textView.
%new - (void)notesCounterResizeForContents:(NSString *)contents inTextView:(UITextView *)textView {
    NSDictionary *notesCounterAttributes = @{ NSFontAttributeName : notesCounterLabel.font };
    NSAttributedString *notesCounterAttributedString = [[NSAttributedString alloc] initWithString:contents attributes:notesCounterAttributes];
   
    CGSize notesCounterBoundingRectInLabel = CGSizeMake(textView.frame.size.width - ((kNotesCounterInnerSidePadding * 2.0) + kNotesCounterOuterSideMaxCombinedMargin), kNotesCounterHeight - (kNotesCounterInnerTopPadding * 2.0));
    CGSize notesCounterStringSize;

    // iOS 7
    if ([[notesCounterAttributedString string] respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        notesCounterStringSize = [[notesCounterAttributedString string] boundingRectWithSize:notesCounterBoundingRectInLabel options:NSStringDrawingUsesLineFragmentOrigin attributes:notesCounterAttributes context:nil].size;
    }

    // iOS 6 and below
    else {
        notesCounterStringSize = [notesCounterAttributedString boundingRectWithSize:notesCounterBoundingRectInLabel options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    }

    CGFloat viewHeight = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? self.view.frame.size.height - kNotesCounterBottomMargin : self.view.frame.size.width - kNotesCounterBottomMargin;

    // Center x coordinate will be set later on, all we need to worry about are y, w, h.
    CGRect notesCounterLabelFrame = CGRectMake(0.0, 0.0, fmin(notesCounterStringSize.width + (kNotesCounterInnerSidePadding * 2.0), textView.frame.size.width - kNotesCounterOuterSideMaxCombinedMargin), kNotesCounterHeight); 
    notesCounterLabelFrame.origin.y = viewHeight - (kNotesCounterOuterBottomPadding + notesCounterLabelFrame.size.height);

    notesCounterLabel.frame = notesCounterLabelFrame;
    notesCounterLabel.center = CGPointMake(textView.center.x, notesCounterLabel.center.y);

    notesCounterLabel.text = contents;
}

// Swaps contents of notesCounter label as per its showingWords property, and resizes the frame accordingly. 
%new - (void)notesCounterSwipeRecognized:(UISwipeGestureRecognizer *)sender {
    UITextView *noteTextView = MSHookIvar<NoteContentLayer *>(self, "_contentLayer").textView;
    BOOL notesCounterShowingWords = ((notesCounterLabel.showingWords = !notesCounterLabel.showingWords));
    [self notesCounterResizeForContents:[NCLabel wordOrCharCountStringFromTextView:noteTextView isChar:!notesCounterShowingWords] inTextView:noteTextView];
}

%new - (void)notesCounterUpdateLabelInTextView:(UITextView *)textView {
    NSString *notesCounterUpdatedText = [NCLabel wordOrCharCountStringFromTextView:textView isChar:!notesCounterLabel.showingWords];
    if (notesCounterUpdatedText.length > notesCounterLabel.text.length) {
        [self notesCounterResizeForContents:notesCounterUpdatedText inTextView:textView];
    }

    else {
        notesCounterLabel.text = notesCounterUpdatedText;
    }
}

// iOS 7
- (void)noteContentLayerContentDidChange:(NoteContentLayer *)arg1 updatedTitle:(BOOL)arg2 {
    %orig(arg1, arg2);
    [self notesCounterUpdateLabelInTextView:arg1.textView];
}

// iOS 6
- (void)noteContentLayerContentDidChange:(NoteContentLayer*)arg1 {
    %orig(arg1);
    [self notesCounterUpdateLabelInTextView:arg1.textView];
}

%new - (void)notesCounterKeyboardWillShow:(NSNotification *)notification {
    NSDictionary *keyboardUserInfo = notification.userInfo;
    NSTimeInterval keyboardDuration = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardCurve = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect keyboardEnd = [[keyboardUserInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardEnd = [self.view convertRect:keyboardEnd fromView:nil];

    kNotesCounterBottomMargin = keyboardEnd.origin.y / 2.0;
    CGFloat viewHeight = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? self.view.frame.size.height - kNotesCounterBottomMargin : self.view.frame.size.width - kNotesCounterBottomMargin;

    CGRect notesCounterLabelFrame = notesCounterLabel.frame;
    notesCounterLabelFrame.origin.y = viewHeight - (kNotesCounterOuterBottomPadding + notesCounterLabelFrame.size.height);

    [UIView beginAnimations:@"wordCounterResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:keyboardDuration];
    [UIView setAnimationCurve:keyboardCurve];

    notesCounterLabel.frame = notesCounterLabelFrame;

    [UIView commitAnimations];
}

%new - (void)notesCounterKeyboardWillHide:(NSNotification *)notification {
    NSDictionary *keyboardUserInfo = notification.userInfo;
    NSTimeInterval keyboardDuration = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardCurve = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect keyboardEnd = [[keyboardUserInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardEnd = [self.view convertRect:keyboardEnd fromView:nil];

    kNotesCounterBottomMargin = 0.0;
    CGFloat viewHeight = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? self.view.frame.size.height - kNotesCounterBottomMargin : self.view.frame.size.width - kNotesCounterBottomMargin;

    CGRect notesCounterLabelFrame = notesCounterLabel.frame;
    notesCounterLabelFrame.origin.y = viewHeight - (kNotesCounterOuterBottomPadding + notesCounterLabelFrame.size.height);

    [UIView beginAnimations:@"wordCounterResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:keyboardDuration];
    [UIView setAnimationCurve:keyboardCurve];

    notesCounterLabel.frame = notesCounterLabelFrame;
    
    [UIView commitAnimations];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)arg1 duration:(NSTimeInterval)arg2 {
    notesCounterLabel.hidden = YES;
    %orig(arg1, arg2);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)arg1 {
    %orig(arg1);

    CGFloat alpha = notesCounterLabel.alpha;

    notesCounterLabel.alpha = 0.0;
    notesCounterLabel.hidden = NO;

    UITextView *noteTextView = MSHookIvar<NoteContentLayer *>(self, "_contentLayer").textView;
    [self notesCounterResizeForContents:[NCLabel wordOrCharCountStringFromTextView:noteTextView isChar:!notesCounterLabel.showingWords] inTextView:noteTextView];

    [UIView animateWithDuration:0.3 animations:^(void) {
        notesCounterLabel.alpha = alpha;
    }];
}

- (void)dealloc {
    %orig();
    [notesCounterLabel release];
}

%end
