//
//  NCLabel.h
//  testing
//
//  Created by Julian Weiss on 5/1/14.
//  Copyright (c) 2014 Julian Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSInteger KNotesCounterCharCounterTag = 1, KNotesCounterWordCounterTag = 2;

@interface NCLabel : UILabel

@property(nonatomic, readwrite) CGFloat keyboardEnd, coeff;

+ (NSString *)wordOrCharCountStringFromTextView:(UITextView *)textView isChar:(BOOL)counterType;
- (instancetype)initWithFrame:(CGRect)frame andFont:(UIFont *)font;

@end
