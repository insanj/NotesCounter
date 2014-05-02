#include <UIKit/UIKit.h>
#import "NCLabel.h"

// Yeah, yeah, I know this isn't true.
@interface _UICompatibilityTextView : UITextView
@end 

@interface NoteContentLayer : UIView <UITextViewDelegate>
@property(copy) _UICompatibilityTextView *textView;
@end

@interface NotesDisplayController : UIViewController {
    NoteContentLayer *_contentLayer; 
}

- (void)noteContentLayerContentDidChange:(id)arg1 updatedTitle:(_Bool)arg2;
- (UITextView *)contentScrollView;
@end

@interface NotesDisplayController (NotesCounter)
- (void)wordCounterMoveUp:(NSNotification *)notification;
- (void)wordCounterMoveDown:(NSNotification *)notification;
- (void)wordCounterMove:(NSNotification *)notification;
@end

%hook NotesDisplayController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);

    UIFont *currentSystemFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:[UIFont systemFontSize]];
    UITextView *noteTextView = MSHookIvar<NoteContentLayer *>(self, "_contentLayer").textView;

    NSString *currentWordCountString = [NCLabel wordCountStringFromTextView:noteTextView];
    CGSize wordCountStringSize = [currentWordCountString boundingRectWithSize:(CGSize){self.view.frame.size.width - 100.0, 50.0} options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : currentSystemFont} context:nil].size;
    
    NCLabel *wordCounter = [[NCLabel alloc] initWithFrame:(CGRect){CGPointZero, (CGSize){wordCountStringSize.width + 7.0,
        wordCountStringSize.height + 10.0}} andFont:currentSystemFont];
    wordCounter.text = currentWordCountString;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        wordCounter.alpha = 0.0;
    }

    [self.view addSubview:wordCounter];
    wordCounter.coeff = 2.0;
    wordCounter.center = CGPointMake(self.view.center.x, self.view.frame.size.height - (wordCounter.frame.size.height * wordCounter.coeff));
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordCounterMoveUp:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordCounterMoveDown:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)noteContentLayerContentDidChange:(id)arg1 updatedTitle:(_Bool)arg2 {
    %orig(arg1, arg2);

    UITextView *noteTextView = ((NoteContentLayer *)arg1).textView;

    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    wordCounter.text = [NCLabel wordCountStringFromTextView:noteTextView];
    
    CGRect resizeFrame = wordCounter.frame;
    resizeFrame.size.width = [wordCounter.text boundingRectWithSize:(CGSize){self.view.frame.size.width - 100.0, 50.0} options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : wordCounter.font} context:nil].size.width + 7.0;
    wordCounter.frame = resizeFrame;
}

%new - (void)wordCounterMoveUp:(NSNotification *)notification {
    ((NCLabel *)[self.view viewWithTag:1337]).coeff = 1.0;
    [self wordCounterMove:notification];
}

%new - (void)wordCounterMoveDown:(NSNotification *)notification {
    ((NCLabel *)[self.view viewWithTag:1337]).coeff = 2.0;
    [self wordCounterMove:notification];
}

%new - (void)wordCounterMove:(NSNotification *)notification {
    NSDictionary *keyboardUserInfo = notification.userInfo;
    NSTimeInterval keyboardDuration = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardCurve = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGRect keyboardEnd = [[keyboardUserInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView beginAnimations:@"wordCounterResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:keyboardDuration];
    [UIView setAnimationCurve:keyboardCurve];
    
    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    wordCounter.keyboardEnd = keyboardEnd.origin.y;
    wordCounter.center = CGPointMake(self.view.center.x, wordCounter.keyboardEnd - (wordCounter.frame.size.height * wordCounter.coeff));
    
    [UIView commitAnimations];
}

- (void)willRotateToInterfaceOrientation:(long long)arg1 duration:(double)arg2 {
    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    if (UIInterfaceOrientationIsLandscape(arg1)) {
        [UIView animateWithDuration:arg2 animations:^(void) {
            wordCounter.alpha = 0.0;
        }];
    }

    %orig(arg1, arg2);
}

- (void)didRotateFromInterfaceOrientation:(long long)arg1 {
    %orig(arg1);

    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    if (UIInterfaceOrientationIsLandscape(arg1)) {
        [UIView animateWithDuration:0.1 animations:^(void) {
            wordCounter.alpha = 0.6;
        }];

        CGFloat centeredX = self.view.center.x;
        CGFloat keyboardEnd = self.isEditing ? wordCounter.keyboardEnd : self.view.frame.size.height;
        CGFloat centeredY = keyboardEnd - (wordCounter.frame.size.height * wordCounter.coeff);
        wordCounter.center = CGPointMake(centeredX, centeredY);
    }
}

%end