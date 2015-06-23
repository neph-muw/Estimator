//
//  YellowLineLabel.m
//  Estimator
//
//  Created by Roman Mykitchak on 2/4/15.
//  Copyright (c) 2015 ukrinsoft. All rights reserved.
//

#import "YellowLineLabel.h"

@implementation YellowLineLabel

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 0.5);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGColorRef color;
    if (self.linesColour!=nil) {
        color = self.linesColour.CGColor;
    }
    else
    {
        CGFloat components[] = {255.0/255.0, 249.0/255.0, 177.0/255.0, 1.0};
        color = CGColorCreate(colorspace, components);
    }
    
    CGContextSetStrokeColorWithColor(context, color);
    
    for (int i=0; i<rect.size.height; i++) {
        if (i%5 != 0) {
            CGContextMoveToPoint(context, 0.0, i);
            CGContextAddLineToPoint(context, rect.size.width , i);
        }
    }
    
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
    CGColorRelease(color);
    
    [super drawRect:rect];
}

@end
