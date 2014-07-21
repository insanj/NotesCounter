#include <UIKit/UIKit.h>
#import "substrate.h"
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
- (void)wordCounterMove:(NSNotification *)notification  withCoeff:(CGFloat)coeff;
@end
