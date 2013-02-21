//
//  CopyableLabel.m
//
//  Created by Gautam Lodhiya on 19/02/13.
//

#import "CopyableAttributedLabel.h"
#import "CoreTextUtils.h"


@interface CopyableAttributedLabel() {
    CTFrameRef textFrame;
	CGRect drawingRect;
    
    CGPoint firstPoint, secondPoint;
    NSTimeInterval time;
}

-(void)resetTextFrame;
-(void)drawActiveLinkHighlightForRect:(CGRect)rect;

@end

@implementation CopyableAttributedLabel
@synthesize copyableDelegate = _copyableDelegate;

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
    if (self.copyableDelegate && [self.copyableDelegate respondsToSelector:@selector(hideView)]) {
        self.highlighted = NO;
        [self.copyableDelegate hideView];
        [self resignFirstResponder];
        
    } else {
        self.highlighted = NO;
        UIMenuController *menu = [UIMenuController sharedMenuController];
        [menu setMenuVisible:NO animated:YES];
        [menu update];
        [self resignFirstResponder];
    }
    
    
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
            if (self.copyableDelegate && [self.copyableDelegate respondsToSelector:@selector(hideView)]) {
                self.highlighted = NO;
                [self.copyableDelegate hideView];
                [self resignFirstResponder];
                
            } else {
                self.highlighted = NO;
                UIMenuController *menu = [UIMenuController sharedMenuController];
                [menu setMenuVisible:NO animated:YES];
                [menu update];
                [self resignFirstResponder];
            }
        }
        else if([self becomeFirstResponder]) {
            if (self.copyableDelegate && [self.copyableDelegate respondsToSelector:@selector(showViewAtLocation:)]) {
                [self.copyableDelegate showViewAtLocation:location];
                
            } else {
                UIMenuController *menu = [UIMenuController sharedMenuController];
                //[menu setTargetRect:self.bounds inView:self];
                [menu setTargetRect:CGRectMake(location.x, location.y, 0.0f, 0.0f) inView:self];
                [menu setMenuVisible:YES animated:YES];
            }
        }
    }
}

- (void)copy:(id) sender {
    if (self.copyableDelegate && [self.copyableDelegate respondsToSelector:@selector(stringToCopyToClipboard)]) {
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        [board setString:[self.copyableDelegate stringToCopyToClipboard]];
    } else {
        if (self.attributedText && ![self.attributedText isKindOfClass:[NSNull class]]) {
            UIPasteboard *board = [UIPasteboard generalPasteboard];
            [board setString:self.attributedText.string];
        }
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

-(void)setNeedsDisplay
{
	[self resetTextFrame];
	[super setNeedsDisplay];
}

-(void)dealloc
{
	[self resetTextFrame]; // CFRelease the text frame
    
#if ! __has_feature(objc_arc)
	[super dealloc];
#endif
}

/////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Drawing Text
/////////////////////////////////////////////////////////////////////////////////////

-(void)resetTextFrame
{
	if (textFrame)
    {
		CFRelease(textFrame);
		textFrame = NULL;
	}
}

- (void)drawTextInRect:(CGRect)rect {
    if (self.highlighted) {
        
        @autoreleasepool
        {
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            CGContextSaveGState(ctx);
            
            // flipping the context to draw core text
            // no need to flip our typographical bounds from now on
            CGContextConcatCTM(ctx, CGAffineTransformScale(CGAffineTransformMakeTranslation(0, self.bounds.size.height), 1.f, -1.f));


            
            if (textFrame == NULL)
            {
#if __has_feature(objc_arc)
                CFAttributedStringRef cfAttrStrWithLinks = (__bridge CFAttributedStringRef)self.attributedText;
#else
                CFAttributedStringRef cfAttrStrWithLinks = (CFAttributedStringRef)self.attributedText;
#endif
                
                CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(cfAttrStrWithLinks);
                drawingRect = self.bounds;
                if (self.centerVertically || self.extendBottomToFit)
                {
                    CGSize sz = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,CFRangeMake(0,0),NULL,CGSizeMake(drawingRect.size.width,CGFLOAT_MAX),NULL);
                    if (self.extendBottomToFit)
                    {
                        CGFloat delta = MAX(0.f , ceilf(sz.height - drawingRect.size.height)) + 10 /* Security margin */;
                        drawingRect.origin.y -= delta;
                        drawingRect.size.height += delta;
                    }
                    if (self.centerVertically && drawingRect.size.height > sz.height)
                    {
                        drawingRect.origin.y -= (drawingRect.size.height - sz.height)/2;
                    }
                }
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathAddRect(path, NULL, drawingRect);
                textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
                CGPathRelease(path);
                CFRelease(framesetter);
            }
            
            // draw highlights for activeLink            
            [self drawActiveLinkHighlightForRect:drawingRect];            
            
            
            CTFrameDraw(textFrame, ctx);
            
            CGContextRestoreGState(ctx);
        } // @autoreleasepool        
        
    } else {
        [super drawTextInRect:rect];
    }
}


-(void)drawActiveLinkHighlightForRect:(CGRect)rect
{    
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSaveGState(ctx);
	CGContextConcatCTM(ctx, CGAffineTransformMakeTranslation(rect.origin.x, rect.origin.y));
    if (self.highlightedLinkColor) {
        [self.highlightedLinkColor setFill];
    } else {
        [[UIColor colorWithRed:188.0f/255.0f green:210.0f/255.0f blue:229.0f/255.0f alpha:1] setFill];
    }

	
    NSRange activeLinkRange = [self.attributedText.string rangeOfString:self.attributedText.string];

	
	CFArrayRef lines = CTFrameGetLines(textFrame);
	CFIndex lineCount = CFArrayGetCount(lines);
	CGPoint lineOrigins[lineCount];
	CTFrameGetLineOrigins(textFrame, CFRangeMake(0,0), lineOrigins);
	for (CFIndex lineIndex = 0; lineIndex < lineCount; lineIndex++)
    {
		CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
		
		if (!CTLineContainsCharactersFromStringRange(line, activeLinkRange))
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
			
			if (!CTRunContainsCharactersFromStringRange(run, activeLinkRange))
            {
				if (!CGRectIsEmpty(unionRect))
                {
					CGContextFillRect(ctx, unionRect);
					unionRect = CGRectZero;
				}
				continue; // with next run
			}
			
			CGRect linkRunRect = CTRunGetTypographicBoundsAsRect(run, line, lineOrigins[lineIndex]);
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
			//unionRect = CGRectZero;
		}
	}
	CGContextRestoreGState(ctx);
}


@end
