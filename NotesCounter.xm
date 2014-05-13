#import "NotesCounter.h"

#define NC_UPCOEFF 1.0
#define NC_DOWNCOEFF 2.1
#define NC_CONSTRAINT CGSizeMake(self.view.frame.size.width - 100.0, 50.0)

%hook NotesDisplayController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);

    UIFont *currentSystemFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:[UIFont systemFontSize]];
    UITextView *noteTextView = MSHookIvar<NoteContentLayer *>(self, "_contentLayer").textView;

    NSDictionary *attributes = @{ NSFontAttributeName : currentSystemFont };
    NSAttributedString *currentWordCountString = [[NSAttributedString alloc] initWithString:[NCLabel wordCountStringFromTextView:noteTextView] attributes:attributes];
    CGSize wordCountStringSize;

    // iOS 7
    if([[currentWordCountString string] respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        wordCountStringSize = [currentWordCountString.string boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
    }

    // iOS 6 and below
    else {
        wordCountStringSize = [currentWordCountString boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    }

    NCLabel *wordCounter = [[NCLabel alloc] initWithFrame:(CGRect){CGPointZero, CGSizeMake(wordCountStringSize.width + 7.0, wordCountStringSize.height + 10.0)} andFont:currentSystemFont];
    wordCounter.text = currentWordCountString.string;
    [self.view addSubview:wordCounter];

    wordCounter.coeff = NC_DOWNCOEFF;
    wordCounter.center = CGPointMake(self.view.center.x, self.view.frame.size.height - (wordCounter.frame.size.height * wordCounter.coeff));

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordCounterMoveUp:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordCounterMoveDown:) name:UIKeyboardWillHideNotification object:nil];
}

// iOS 7
- (void)noteContentLayerContentDidChange:(NoteContentLayer *)arg1 updatedTitle:(BOOL)arg2 {
    %orig(arg1, arg2);

    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    wordCounter.text = [NCLabel wordCountStringFromTextView:arg1.textView];
    
    CGRect resizeFrame = wordCounter.frame;
    NSRange attributesRange = NSMakeRange(0, wordCounter.text.length);
    resizeFrame.size.width = [wordCounter.text boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin attributes:[wordCounter.attributedText attributesAtIndex:0 effectiveRange:&attributesRange] context:nil].size.width + 7.0;
    wordCounter.frame = resizeFrame;
}

// iOS 6
- (void)noteContentLayerContentDidChange:(NoteContentLayer*)arg1 {
    %orig(arg1);

    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    wordCounter.text = [NCLabel wordCountStringFromTextView:arg1.textView];

    CGRect resizeFrame = wordCounter.frame;
    resizeFrame.size.width = [wordCounter.attributedText boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.width + 7.0;
    wordCounter.frame = resizeFrame;
}

%new - (void)wordCounterMoveUp:(NSNotification *)notification {
    ((NCLabel *)[self.view viewWithTag:1337]).coeff = NC_UPCOEFF;
    [self wordCounterMove:notification];
}

%new - (void)wordCounterMoveDown:(NSNotification *)notification {
    ((NCLabel *)[self.view viewWithTag:1337]).coeff = NC_DOWNCOEFF;
    [self wordCounterMove:notification];
}

%new - (void)wordCounterMove:(NSNotification *)notification {
    NSDictionary *keyboardUserInfo = notification.userInfo;
    NSTimeInterval keyboardDuration = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardCurve = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGRect keyboardEnd = [[keyboardUserInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardEnd = [self.view convertRect:keyboardEnd fromView:nil];

    [UIView beginAnimations:@"wordCounterResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:keyboardDuration];
    [UIView setAnimationCurve:keyboardCurve];
    
    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    wordCounter.keyboardEnd = keyboardEnd.origin.y;
    wordCounter.center = CGPointMake(self.view.center.x, wordCounter.keyboardEnd - (wordCounter.frame.size.height * wordCounter.coeff));
    
    [UIView commitAnimations];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)arg1 duration:(NSTimeInterval)arg2 {
    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    wordCounter.hidden = YES;

    %orig(arg1, arg2);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)arg1 {
    %orig(arg1);

    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    wordCounter.coeff = self.isEditing ? NC_UPCOEFF : NC_DOWNCOEFF;
  
    CGFloat centeredX = self.view.center.x;
    CGFloat keyboardEnd = self.isEditing ? wordCounter.keyboardEnd : self.view.frame.size.height;
    CGFloat centeredY = keyboardEnd - (wordCounter.frame.size.height * wordCounter.coeff);
    wordCounter.center = CGPointMake(centeredX, centeredY);

    CGFloat alpha = wordCounter.alpha;
    wordCounter.alpha = 0.0;
    wordCounter.hidden = NO;

    [UIView animateWithDuration:0.3 animations:^(void) {
        wordCounter.alpha = alpha;
    }];
}

%end
