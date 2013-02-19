//
//  CopyableLabel.m
//
//  Created by Gautam Lodhiya on 19/02/13.
//

#import "CopyableAttributedLabel.h"
#import "CoreTextUtils.h"


@interface CopyableAttributedLabel() {
    CGPoint firstPoint, secondPoint;
    NSTimeInterval time;
}

@end

@implementation CopyableAttributedLabel
static NSTimeInterval LONG_PRESS_THRESHOLD = 0.5;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    firstPoint=secondPoint = [touch locationInView:self];
    
    time = [event timestamp];
    
    //start timer    
    if (event.type == UIEventTypeTouches) {
        [self performSelector:@selector(longTap:)
                   withObject:touches
                   afterDelay:LONG_PRESS_THRESHOLD];
    }
    
    [super touchesBegan:touches withEvent:event];
    [[self nextResponder] touchesBegan:touches withEvent:event];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    
    
    UITouch *touch = [touches anyObject];
    secondPoint = [touch locationInView:self];
    
    
    
    NSTimeInterval diff = event.timestamp - time;
    if (diff < LONG_PRESS_THRESHOLD) {
        //short
        [super touchesEnded:touches withEvent:event];
        [[self nextResponder] touchesEnded:touches withEvent:event];
        
    } else {
        //long
        [super touchesCancelled:touches withEvent:event];
        [[self nextResponder] touchesCancelled:touches withEvent:event];
    }
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    UITouch *touch = [touches anyObject];
    secondPoint = [touch locationInView:self];
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // Reset values
    self.highlighted = NO;
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuVisible:NO animated:YES];
    [menu update];
    [self resignFirstResponder];
    
    
    if ([self pointInside:point withEvent:event])
        return self;
    
    return [super hitTest:point withEvent:event];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint([self bounds], point))
    {
        if (event.type == UIEventTypeTouches)
        {
            return YES;
        }
    }
    
    return NO;
}



#pragma mark -
#pragma mark Copy Cell Methods

- (void)longTap:(NSSet*)touches {
    //check first and second point for equals if it equals its long tap
    
    if ([NSStringFromCGPoint(firstPoint) isEqualToString:NSStringFromCGPoint(secondPoint)]) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:touch.view];
        
        /*UIMenuController *menuController = [UIMenuController sharedMenuController];
        NSAssert([self becomeFirstResponder], @"Sorry, UIMenuController will not work with %@ since it cannot become first responder", self);
        [menuController setTargetRect:CGRectMake(location.x, location.y, 0.0f, 0.0f) inView:self];
        [menuController setArrowDirection:UIMenuControllerArrowDefault];
        [menuController setMenuVisible:YES animated:YES];*/
        
        if([self isFirstResponder]) {
            self.highlighted = NO;
            UIMenuController *menu = [UIMenuController sharedMenuController];
            [menu setMenuVisible:NO animated:YES];
            [menu update];
            [self resignFirstResponder];
        }
        else if([self becomeFirstResponder]) {
            UIMenuController *menu = [UIMenuController sharedMenuController];
            //[menu setTargetRect:self.bounds inView:self];
            [menu setTargetRect:CGRectMake(location.x, location.y, 0.0f, 0.0f) inView:self];
            [menu setMenuVisible:YES animated:YES];
        }
    }
}

- (void)copy:(id) sender {
    if (self.attributedText && ![self.attributedText isKindOfClass:[NSNull class]]) {
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        [board setString:self.attributedText.string];
    }
    
    self.highlighted = NO;
    [self resignFirstResponder];
}

- (BOOL)canPerformAction:(SEL)selector withSender:(id) sender {
    if (selector == @selector(copy:)) {
        return YES;
    }
    return NO;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (BOOL)becomeFirstResponder {
    if([super becomeFirstResponder]) {
        self.highlighted = YES;
        return YES;
    }
    return NO;
}


- (void)drawTextInRect:(CGRect)rect {
    if (self.highlighted) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        CGContextConcatCTM(ctx, CGAffineTransformMakeTranslation(rect.origin.x, rect.origin.y));

        [[UIColor colorWithRed:188.0f/255.0f green:210.0f/255.0f blue:229.0f/255.0f alpha:1] setFill];
                
#if __has_feature(objc_arc)
        CFAttributedStringRef cfAttrStrWithLinks = (__bridge CFAttributedStringRef)self.attributedText;
#else
        CFAttributedStringRef cfAttrStrWithLinks = (CFAttributedStringRef)self.attributedText;
#endif
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(cfAttrStrWithLinks);
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, self.bounds);

        NSRange range = [self.attributedText.string rangeOfString:self.attributedText.string];
       CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
        
        CFArrayRef lines = CTFrameGetLines(textFrame);
        CFIndex lineCount = CFArrayGetCount(lines);
        CGPoint lineOrigins[lineCount];
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0,0), lineOrigins);
        for (CFIndex lineIndex = 0; lineIndex < lineCount; lineIndex++)
        {

            CTLineRef line = CFArrayGetValueAtIndex(lines, (lineCount - lineIndex - 1));
            
            if (!CTLineContainsCharactersFromStringRange(line, range))
            {
                continue; // with next line
            }
            
            // we use this rect to union the bounds of successive runs that belong to the same active link
            CGRect unionRect = CGRectZero;
            
            CFArrayRef runs = CTLineGetGlyphRuns(line);
            CFIndex runCount = CFArrayGetCount(runs);
            for (CFIndex runIndex = 0; runIndex < runCount; runIndex++)
            {
                CTRunRef run = CFArrayGetValueAtIndex(runs, runIndex);
                
                if (!CTRunContainsCharactersFromStringRange(run, range))    
                {
                    if (!CGRectIsEmpty(unionRect))
                    {
                        CGContextFillRect(ctx, unionRect);
                        unionRect = CGRectZero;
                    }
                    continue; // with next run
                }
                
                CGFloat ascent = 0;
                CGFloat descent = 0;
                CGFloat leading = 0;
                CGFloat width = (CGFloat)CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
                CGFloat height = ascent + descent;
                
                CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
                
                
                CGRect linkRunRect = CGRectMake(lineOrigins[lineIndex].x + xOffset,
                                                lineOrigins[lineIndex].y-descent,
                                                width,
                                                height);
                linkRunRect = CGRectIntegral(linkRunRect);		// putting the rect on pixel edges
                linkRunRect = CGRectInset(linkRunRect, -1, -1);	// increase the rect a little
                if (CGRectIsEmpty(unionRect))
                {
                    unionRect = linkRunRect;
                } else {
                    unionRect = CGRectUnion(unionRect, linkRunRect);
                }
            }
        
            if (!CGRectIsEmpty(unionRect))
            {
                CGContextFillRect(ctx, unionRect);
                unionRect = CGRectZero;
            }
        }
        [super drawTextInRect:rect];
        
    } else {
        [super drawTextInRect:rect];
    }
}

@end
