//
//  NCLabel.m
//  testing
//
//  Created by Julian Weiss on 5/1/14.
//  Copyright (c) 2014 Julian Weiss. All rights reserved.
//

#import "NCLabel.h"

@implementation NCLabel
@synthesize keyboardEnd, coeff;

+ (NSString *)wordCountStringFromTextView:(UITextView *)textView {
	NSRegularExpression *wordRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\W|^)*(\\W)" options:NSRegularExpressionCaseInsensitive error:nil];
	NSNumber *wordCount = @([wordRegex numberOfMatchesInString:textView.text options:0 range:NSMakeRange(0, textView.text.length)]);
	return [NSString stringWithFormat:@"  %@ words", [wordCount descriptionWithLocale:[NSLocale currentLocale]]];
}

- (instancetype)initWithFrame:(CGRect)frame andFont:(UIFont *)font{
	self = [super initWithFrame:frame];
	if (self) {
		self.lineBreakMode = NSLineBreakByTruncatingMiddle;
		self.textAlignment = NSTextAlignmentLeft;
		self.numberOfLines = 1;
		self.font = font;
		self.textColor = [UIColor colorWithWhite:0.9 alpha:0.9];
		self.backgroundColor = [UIColor colorWithRed:52/255.0 green:53/255.0 blue:46/255.0 alpha:1.0];
		self.alpha = 0.6;
		self.layer.masksToBounds = YES;
		self.layer.cornerRadius = 10.0;
		self.tag = 1337;
		self.userInteractionEnabled = YES;
	}
	
	return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[UIView animateWithDuration:0.25 animations:^(void) {
		self.alpha = fabs(self.alpha - 0.7);
	}];
	
	[super touchesBegan:touches withEvent:event];
}

@end
