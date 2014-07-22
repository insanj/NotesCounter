//
//  NCLabel.m
//  testing
//
//  Created by Julian Weiss on 5/1/14.
//  Copyright (c) 2014 Julian Weiss. All rights reserved.
//

#import "NCLabel.h"

@implementation NCLabel

+ (NSString *)wordOrCharCountStringFromTextView:(UITextView *)textView isChar:(BOOL)counterType {
	if (counterType) { // char count
		NSString *charCountString = [NSNumberFormatter localizedStringFromNumber:@([textView.text length]) numberStyle:NSNumberFormatterDecimalStyle];
		return [charCountString stringByAppendingString:@" chars"];
	}

	else {	// word count
		NSRegularExpression *wordRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\W|^)*(\\W)" options:NSRegularExpressionCaseInsensitive error:nil];
		NSUInteger wordCount = [wordRegex numberOfMatchesInString:textView.text options:0 range:NSMakeRange(0, textView.text.length)];
		NSString *wordCountString = [NSNumberFormatter localizedStringFromNumber:@(wordCount) numberStyle:NSNumberFormatterDecimalStyle];
		return [wordCountString stringByAppendingString:@" words"];
	}
}

- (instancetype)initWithFrame:(CGRect)frame andFont:(UIFont *)font{
	self = [super initWithFrame:frame];

	if (self) {
		self.textColor = [UIColor colorWithWhite:0.9 alpha:0.9];
		self.backgroundColor = [UIColor clearColor]; // [UIColor colorWithRed:52/255.0 green:53/255.0 blue:46/255.0 alpha:1.0];
		self.font = font;

		self.lineBreakMode = NSLineBreakByTruncatingMiddle;
		self.textAlignment = NSTextAlignmentLeft;
		self.numberOfLines = 1;
	
		self.userInteractionEnabled = YES;

		_textInset = UIEdgeInsetsZero;
		_showingWords = YES;
	}

	return self;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	[UIView animateWithDuration:0.25 animations:^(void) {
		self.alpha = fabs(self.alpha - 0.7);
	}];
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _textInset)];
}

@end
