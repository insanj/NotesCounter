#import "NotesCounter.h"

#define NC_UPCOEFF 1.0
#define NC_DOWNCOEFF 2.1
#define NC_CONSTRAINT CGSizeMake(self.view.frame.size.width - 100.0, 50.0)

static CGFloat upDownCoeff;
static UIScrollView *counterScrollView;

%hook NotesDisplayController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);

    UIFont *currentSystemFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:[UIFont systemFontSize]];
    UITextView *noteTextView = MSHookIvar<NoteContentLayer *>(self, "_contentLayer").textView;

    NSDictionary *attributes = @{ NSFontAttributeName : currentSystemFont };
    NSAttributedString *currentWordCountString = [[NSAttributedString alloc] initWithString:[NCLabel wordOrCharCountStringFromTextView:noteTextView  isChar:NO] attributes:attributes];
    NSAttributedString *currentCharCountString = [[NSAttributedString alloc] initWithString:[NCLabel wordOrCharCountStringFromTextView:noteTextView  isChar:YES] attributes:attributes];
   
    CGSize wordCountStringSize;
    CGSize charCountStringSize;

    // iOS 7
    if ([[currentWordCountString string] respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        wordCountStringSize = [currentWordCountString.string boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
        charCountStringSize = [currentCharCountString.string boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
    }

    // iOS 6 and below
    else {
        wordCountStringSize = [currentWordCountString boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        charCountStringSize = [currentCharCountString boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    }

    NCLabel *wordCounter, *charCounter;

    if (!counterScrollView) {
        counterScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, wordCountStringSize.width + 7.0, wordCountStringSize.height + 10.0)];
        counterScrollView.contentSize = CGSizeMake(counterScrollView.frame.size.width * 2.0, counterScrollView.frame.size.height);
        counterScrollView.backgroundColor = [UIColor colorWithRed:52.0/255.0 green:53.0/255.0 blue:46.0/255.0 alpha:1.0];
        counterScrollView.alpha = 0.6;
        counterScrollView.layer.masksToBounds = YES;
        counterScrollView.layer.cornerRadius = 10.0;
        counterScrollView.pagingEnabled =YES;
        counterScrollView.showsHorizontalScrollIndicator = NO;
       
        wordCounter = [[NCLabel alloc] initWithFrame:CGRectMake(0.0, 0.0, wordCountStringSize.width + 7.0, wordCountStringSize.height + 10.0) andFont:currentSystemFont];
       
        charCounter = [[NCLabel alloc] initWithFrame:CGRectMake(counterScrollView.contentSize.width / 2.0, 0.0, charCountStringSize.width + 7.0, charCountStringSize.height + 10.0) andFont:currentSystemFont];

        [self.view addSubview:counterScrollView];
        [counterScrollView addSubview:wordCounter];
        [counterScrollView addSubview:charCounter];
    }

    else {
        wordCounter = (NCLabel *)[counterScrollView viewWithTag:KNotesCounterWordCounterTag];
        charCounter = (NCLabel *)[counterScrollView viewWithTag:KNotesCounterCharCounterTag];
    }

    wordCounter.text = currentWordCountString.string;
    charCounter.text = currentCharCountString.string;

    [currentWordCountString release];
    [currentCharCountString release];

    upDownCoeff = NC_DOWNCOEFF;
    counterScrollView.center = CGPointMake(self.view.center.x, self.view.frame.size.height - (wordCounter.frame.size.height * upDownCoeff));

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordCounterMoveUp:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordCounterMoveDown:) name:UIKeyboardWillHideNotification object:nil];
}

// iOS 7
- (void)noteContentLayerContentDidChange:(NoteContentLayer *)arg1 updatedTitle:(BOOL)arg2 {
    %orig(arg1, arg2);

    NCLabel *wordCounter = (NCLabel *)[counterScrollView viewWithTag:KNotesCounterWordCounterTag];
    NCLabel *charCounter = (NCLabel *)[counterScrollView viewWithTag:KNotesCounterCharCounterTag];

    charCounter.text = [NCLabel wordOrCharCountStringFromTextView:arg1.textView isChar:YES];
    wordCounter.text = [NCLabel wordOrCharCountStringFromTextView:arg1.textView isChar:NO];

    CGRect resizeFrameWord = wordCounter.frame;
    CGRect resizeFrameChar = charCounter.frame;
   
    NSRange attributesRangeWord = NSMakeRange(0, wordCounter.text.length);
    NSRange attributesRangeChar = NSMakeRange(0, charCounter.text.length);
    resizeFrameWord.size.width = [wordCounter.text boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin attributes:[wordCounter.attributedText attributesAtIndex:0 effectiveRange:&attributesRangeWord] context:nil].size.width + 7.0;
    resizeFrameChar.size.width = [charCounter.text boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin attributes:[charCounter.attributedText attributesAtIndex:0 effectiveRange:&attributesRangeChar] context:nil].size.width + 7.0;
   
    wordCounter.frame = resizeFrameWord;
    charCounter.frame = resizeFrameChar;
}

// iOS 6
- (void)noteContentLayerContentDidChange:(NoteContentLayer*)arg1 {
    %orig(arg1);

    NCLabel *wordCounter = (NCLabel *)[counterScrollView viewWithTag:KNotesCounterWordCounterTag];
    NCLabel *charCounter = (NCLabel *)[counterScrollView viewWithTag:KNotesCounterCharCounterTag];

    charCounter.text = [NCLabel wordOrCharCountStringFromTextView:arg1.textView isChar:YES];
    wordCounter.text = [NCLabel wordOrCharCountStringFromTextView:arg1.textView isChar:NO] ;

    CGRect resizeFrameWord = wordCounter.frame;
    CGRect resizeFrameChar = charCounter.frame;
   
    resizeFrameWord.size.width = [wordCounter.attributedText boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.width + 7.0;
    resizeFrameChar.size.width = [charCounter.attributedText boundingRectWithSize:NC_CONSTRAINT options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.width + 7.0;
    
    wordCounter.frame = resizeFrameWord;
    charCounter.frame = resizeFrameChar;
}

%new - (void)wordCounterMoveUp:(NSNotification *)notification {
    [self wordCounterMove:notification withCoeff:NC_UPCOEFF];
}

%new - (void)wordCounterMoveDown:(NSNotification *)notification {
    [self wordCounterMove:notification withCoeff:NC_DOWNCOEFF];
}

%new - (void)wordCounterMove:(NSNotification *)notification withCoeff:(CGFloat)coeff{
    NSDictionary *keyboardUserInfo = notification.userInfo;
    NSTimeInterval keyboardDuration = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardCurve = [[keyboardUserInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect keyboardEnd = [[keyboardUserInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardEnd = [self.view convertRect:keyboardEnd fromView:nil];

    [UIView beginAnimations:@"wordCounterResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:keyboardDuration];
    [UIView setAnimationCurve:keyboardCurve];

    NCLabel *wordCounter = (NCLabel *)[counterScrollView viewWithTag:KNotesCounterWordCounterTag];
    wordCounter.keyboardEnd = keyboardEnd.origin.y;
    counterScrollView.center = CGPointMake(self.view.center.x, wordCounter.keyboardEnd - (wordCounter.frame.size.height * coeff));

    [UIView commitAnimations];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)arg1 duration:(NSTimeInterval)arg2 {
    counterScrollView.hidden = YES;
    %orig(arg1, arg2);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)arg1 {
    %orig(arg1);

    NCLabel *wordCounter = (NCLabel *)[counterScrollView viewWithTag:KNotesCounterWordCounterTag];
    upDownCoeff = self.isEditing ? NC_UPCOEFF : NC_DOWNCOEFF;

    CGFloat centeredX = self.view.center.x;
    CGFloat keyboardEnd = self.isEditing ? wordCounter.keyboardEnd : self.view.frame.size.height;
    CGFloat centeredY = keyboardEnd - (wordCounter.frame.size.height * upDownCoeff);
    counterScrollView.center = CGPointMake(centeredX, centeredY);

    CGFloat alpha = wordCounter.superview.alpha;
    wordCounter.superview.alpha = 0.0;
    wordCounter.superview.hidden = NO;

    [UIView animateWithDuration:0.3 animations:^(void) {
        wordCounter.superview.alpha = alpha;
    }];
}

- (void)dealloc {
    %orig();
    [counterScrollView release];
}

%end
