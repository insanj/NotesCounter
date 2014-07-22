#import "NCLabel.h"
#import "substrate.h"

// Yeah, yeah, I know this isn't true.
@interface _UICompatibilityTextView : UITextView

@end

@interface NoteContentLayer : UIView <UITextViewDelegate>

@property(copy) _UICompatibilityTextView *textView;

@end

@interface NotesDisplayController : UIViewController {
    NoteContentLayer *_contentLayer;
}

- (void)noteContentLayerContentDidChange:(id)arg1 updatedTitle:(BOOL)arg2;
- (UITextView *)contentScrollView;

@end

@interface NotesDisplayController (NotesCounter)

- (void)notesCounterResizeForContents:(NSString *)contents inTextView:(UITextView *)textView;
- (void)notesCounterSwipeRecognized:(UISwipeGestureRecognizer *)sender;
- (void)notesCounterUpdateLabelInTextView:(UITextView *)textView;

- (void)notesCounterKeyboardWillShow:(NSNotification *)notification;
- (void)notesCounterKeyboardWillHide:(NSNotification *)notification;

@end
