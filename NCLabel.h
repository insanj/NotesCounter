//
//  NCLabel.h
//  testing
//
//  Created by Julian Weiss on 5/1/14.
//  Copyright (c) 2014 Julian Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCLabel : UILabel

+ (NSString *)wordCountStringFromTextView:(UITextView *)textView;
- (instancetype)initWithFrame:(CGRect)frame andFont:(UIFont *)font;

@end
