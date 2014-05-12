#import "NotesCounter.h"

#define NC_UPCOEFF 1.0
#define NC_DOWNCOEFF 2.0

%hook NotesDisplayController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);

    UIFont *currentSystemFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:[UIFont systemFontSize]];
    UITextView *noteTextView = MSHookIvar<NoteContentLayer *>(self, "_contentLayer").textView;

    CGSize wordCountStringSize;
    //NSString *currentWordCountString = [NCLabel wordCountStringFromTextView:noteTextView];
    NSAttributedString * currentWordCountString = [[NSAttributedString alloc] initWithString:[NCLabel wordCountStringFromTextView:noteTextView] attributes:@{ NSFontAttributeName : currentSystemFont}];
    if([[currentWordCountString string] respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)])
        wordCountStringSize = [[currentWordCountString string] boundingRectWithSize:(CGSize){self.view.frame.size.width - 100.0, 50.0} options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : currentSystemFont} context:nil].size;
    wordCountStringSize = [currentWordCountString boundingRectWithSize:(CGSize){self.view.frame.size.width - 100.0, 50.0} options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;

    NCLabel *wordCounter = [[NCLabel alloc] initWithFrame:(CGRect){CGPointZero, (CGSize){wordCountStringSize.width + 7.0,
        wordCountStringSize.height + 10.0}} andFont:currentSystemFont];
    wordCounter.text = [currentWordCountString string];
    /*if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        wordCounter.alpha = 0.0;
    }*/

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
    resizeFrame.size.width = [wordCounter.text boundingRectWithSize:(CGSize){self.view.frame.size.width - 100.0, 50.0} options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : wordCounter.font} context:nil].size.width + 7.0;
    wordCounter.frame = resizeFrame;
}

// iOS 6
- (void)noteContentLayerContentDidChange:(NoteContentLayer*)arg1 {
    %orig(arg1);

    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    wordCounter.text = [NCLabel wordCountStringFromTextView:arg1.textView];
    NSAttributedString * currentWordCountString = [[NSAttributedString alloc] initWithString:wordCounter.text attributes:@{ NSFontAttributeName : wordCounter.font}];

    CGRect resizeFrame = wordCounter.frame;
    resizeFrame.size.width = [currentWordCountString boundingRectWithSize:(CGSize){self.view.frame.size.width - 100.0, 50.0} options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.width + 7.0;
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
    /*if (UIInterfaceOrientationIsLandscape(arg1)) {
        [UIView animateWithDuration:arg2 animations:^(void) {
            wordCounter.alpha = 0.0;
        }];
    }*/
    wordCounter.alpha = 0.0;
    %orig(arg1, arg2);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)arg1 {
    %orig(arg1);

    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    
    //if (UIInterfaceOrientationIsLandscape(arg1)) {
        wordCounter.coeff = self.isEditing ? NC_UPCOEFF : NC_DOWNCOEFF;
        CGFloat centeredX = self.view.center.x;
        CGFloat keyboardEnd = self.isEditing ? wordCounter.keyboardEnd : self.view.frame.size.height;
        CGFloat centeredY = keyboardEnd - (wordCounter.frame.size.height * wordCounter.coeff);
        wordCounter.center = CGPointMake(centeredX, centeredY);

        [UIView animateWithDuration:0.3 animations:^(void) {
            wordCounter.alpha = 0.6;
        }];
   // }
}

%end
