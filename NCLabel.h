//
//  NCLabel.h
//  testing
//
//  Created by Julian Weiss on 5/1/14.
//  Copyright (c) 2014 Julian Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCLabel : UILabel

@property(nonatomic, readwrite) UIEdgeInsets textInset;

@property(nonatomic, readwrite) BOOL showingWords;

+ (NSString *)wordOrCharCountStringFromTextView:(UITextView *)textView isChar:(BOOL)counterType;

- (instancetype)initWithFrame:(CGRect)frame andFont:(UIFont *)font;

@end
