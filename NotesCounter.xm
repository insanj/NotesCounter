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
- (void)wordCounterMove:(NSNotification *)notification withCoeff:(CGFloat)coeff;
@end

%hook NotesDisplayController

- (void)viewDidLoad {
    %orig();

    UIFont *currentSystemFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:[UIFont systemFontSize]];
    UITextView *noteTextView = MSHookIvar<NoteContentLayer *>(self, "_contentLayer").textView;

    NSString *currentWordCountString = [NCLabel wordCountStringFromTextView:noteTextView];
    CGSize wordCountStringSize = [currentWordCountString boundingRectWithSize:(CGSize){self.view.frame.size.width - 100.0, 50.0} options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : currentSystemFont} context:nil].size;
    
    NCLabel *wordCounter = [[NCLabel alloc] initWithFrame:(CGRect){CGPointZero, (CGSize){wordCountStringSize.width + 7.0,
        wordCountStringSize.height + 10.0}} andFont:currentSystemFont];
    wordCounter.text = currentWordCountString;
    [self.view addSubview:wordCounter];
    
    wordCounter.center = CGPointMake(self.view.center.x, self.view.frame.size.height - (wordCounter.frame.size.height * 2.5));
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordCounterMoveUp:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordCounterMoveDown:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)noteContentLayerContentDidChange:(id)arg1 updatedTitle:(_Bool)arg2 {
    %orig();

    UITextView *noteTextView = ((NoteContentLayer *)arg1).textView;

    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    wordCounter.text = [NCLabel wordCountStringFromTextView:noteTextView];
    
    CGRect resizeFrame = wordCounter.frame;
    resizeFrame.size.width = [wordCounter.text boundingRectWithSize:(CGSize){self.view.frame.size.width - 100.0, 50.0} options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : wordCounter.font} context:nil].size.width + 7.0;
    wordCounter.frame = resizeFrame;
}

%new - (void)wordCounterMoveUp:(NSNotification *)notification {
    [self wordCounterMove:notification withCoeff:1.0];
}

%new - (void)wordCounterMoveDown:(NSNotification *)notification {
    [self wordCounterMove:notification withCoeff:2.0];
}

%new - (void)wordCounterMove:(NSNotification *)notification withCoeff:(CGFloat)coeff {
    NSDictionary *keyboardUserInfo = notification.userInfo;
    NSTimeInterval keyboardDuration = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardCurve = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGRect keyboardEnd = [[keyboardUserInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView beginAnimations:@"wordCounterResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:keyboardDuration];
    [UIView setAnimationCurve:keyboardCurve];
    
    NCLabel *wordCounter = (NCLabel *)[self.view viewWithTag:1337];
    wordCounter.center = CGPointMake(self.view.center.x, keyboardEnd.origin.y - (wordCounter.frame.size.height * coeff));
    
    [UIView commitAnimations];
}

%end