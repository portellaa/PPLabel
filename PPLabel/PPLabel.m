//
//  PPLabel.m
//  PPLabel
//
//  Created by Petr Pavlik on 12/26/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import "PPLabel.h"
#import <CoreText/CoreText.h>

@interface PPLabel ()

@property(nonatomic, strong) NSSet* lastTouches;
@property (nonatomic, retain) NSMutableArray *links;

- (void)initialize;
- (CGRect)textRect;
- (NSRange)searchForString:(NSString*)text fromRange:(NSRange)range;

@end

@implementation PPLabel

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
		[self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
		[self initialize];
    }
    return self;
}


- (CFIndex)characterIndexAtPoint:(CGPoint)point {
    
    ////////
    
    NSMutableAttributedString* optimizedAttributedText = [self.attributedText mutableCopy];
    
    // use label's font and lineBreakMode properties in case the attributedText does not contain such attributes
    [self.attributedText enumerateAttributesInRange:NSMakeRange(0, [self.attributedText length]) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        
        if (!attrs[(NSString*)kCTFontAttributeName]) {
            
            [optimizedAttributedText addAttribute:(NSString*)kCTFontAttributeName value:self.font range:NSMakeRange(0, [self.attributedText length])];
        }
        
        if (!attrs[(NSString*)kCTParagraphStyleAttributeName]) {
            
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            [paragraphStyle setLineBreakMode:self.lineBreakMode];
            
            [optimizedAttributedText addAttribute:(NSString*)kCTParagraphStyleAttributeName value:paragraphStyle range:range];
        }
    }];
    
    // modify kCTLineBreakByTruncatingTail lineBreakMode to kCTLineBreakByWordWrapping
    [optimizedAttributedText enumerateAttribute:(NSString*)kCTParagraphStyleAttributeName inRange:NSMakeRange(0, [optimizedAttributedText length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        
        NSMutableParagraphStyle* paragraphStyle = [value mutableCopy];
        
        if ([paragraphStyle lineBreakMode] == kCTLineBreakByTruncatingTail) {
            [paragraphStyle setLineBreakMode:kCTLineBreakByWordWrapping];
        }
        
        [optimizedAttributedText removeAttribute:(NSString*)kCTParagraphStyleAttributeName range:range];
        [optimizedAttributedText addAttribute:(NSString*)kCTParagraphStyleAttributeName value:paragraphStyle range:range];
    }];
    
    ////////
    
    if (!CGRectContainsPoint(self.bounds, point)) {
        return NSNotFound;
    }
    
    CGRect textRect = [self textRect];
    
    if (!CGRectContainsPoint(textRect, point)) {
        return NSNotFound;
    }
    
    // Offset tap coordinates by textRect origin to make them relative to the origin of frame
    point = CGPointMake(point.x - textRect.origin.x, point.y - textRect.origin.y);
    // Convert tap coordinates (start at top left) to CT coordinates (start at bottom left)
    point = CGPointMake(point.x, textRect.size.height - point.y);
    
    //////
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)optimizedAttributedText);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [self.attributedText length]), path, NULL);
    
    if (frame == NULL) {
        CFRelease(path);
        return NSNotFound;
    }
    
    CFArrayRef lines = CTFrameGetLines(frame);
    
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    
    //NSLog(@"num lines: %d", numberOfLines);
    
    if (numberOfLines == 0) {
        CFRelease(frame);
        CFRelease(path);
        return NSNotFound;
    }
    
    NSUInteger idx = NSNotFound;
    
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);
    
    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        // Get bounding information of line
        CGFloat ascent, descent, leading, width;
        width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat yMin = floor(lineOrigin.y - descent);
        CGFloat yMax = ceil(lineOrigin.y + ascent);
        
        // Check if we've already passed the line
        if (point.y > yMax) {
            break;
        }
        
        // Check if the point is within this line vertically
        if (point.y >= yMin) {
            
            // Check if the point is within this line horizontally
            if (point.x >= lineOrigin.x && point.x <= lineOrigin.x + width) {
                
                // Convert CT coordinates to line-relative coordinates
                CGPoint relativePoint = CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
                idx = CTLineGetStringIndexForPosition(line, relativePoint);
                
                break;
            }
        }
    }
    
    CFRelease(frame);
    CFRelease(path);
    
    return idx;
}

- (void)addLink:(NSString*)link withText:(NSString*)text
{
	BOOL allFound = NO;

	NSRange range = NSMakeRange(0, [self.text length]);
	NSRange oldRange = NSMakeRange(0, 0);
	
	while (allFound == NO)
	{
		range = NSMakeRange((oldRange.length + oldRange.location), (self.text.length - (oldRange.location + oldRange.length)));
		
		oldRange = [self searchForString:text fromRange:range];
		
		if (oldRange.location == NSNotFound)
			allFound = YES;
		else [self addLink:link withText:text andRange:oldRange];
	}
}

- (void)addLink:(NSString*)link withText:(NSString*)text andRange:(NSRange)range
{
	PPLabelLink *newLink = [[PPLabelLink alloc] init];
	[newLink setText:text];
	[newLink setRef:link];
	
	if (range.location != NSNotFound)
	{
		[newLink setRange:range];
		
		if ([self.links indexOfObject:newLink] == NSNotFound)
		{
			NSMutableAttributedString *attribString = [self.attributedText mutableCopy];
			
			[attribString addAttributes:_linkAttributes range:range];
			
			self.attributedText = attribString;
			
			[self.links addObject:newLink];
		}
	}
	
	NSLog(@"Number of lines on array: %d", [self.links count]);
}

#pragma mark - Override methods

- (void)drawRect:(CGRect)rect
{
	[self detectURLsAndAnchorsOnText];
	
	[super drawRect:rect];
}

- (void)drawTextInRect:(CGRect)rect
{
	UIEdgeInsets insets = {0, 0, 0, 0};
	
	CGRect newRect = [self textRectForBounds:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height) limitedToNumberOfLines:self.numberOfLines];

    [super drawTextInRect:UIEdgeInsetsInsetRect(newRect, insets)];
}

- (void)setLinkAttributes:(NSDictionary *)linkAttributes
{
	_linkAttributes = linkAttributes;
	
	if ([_linkAttributes count] > 0)
	{
		NSMutableAttributedString *attribString = [self.attributedText mutableCopy];
		for (int i = 0; i < [self.links count]; i++)
		{
			[attribString addAttributes:_linkAttributes range:((PPLabelLink*)[self.links objectAtIndex:i]).range];
		}
	}
}

//- (void)setText:(NSString *)text
//{
//	[super setText:text];
//	
//	[self detectURLsAndAnchorsOnText];
//}
// Not needed for now
//- (void)setAttributedText:(NSAttributedString *)attributedText
//{
//	[super setAttributedText:attributedText];
//}

#pragma mark - Private Methods

- (void)initialize
{
	self.links = [[NSMutableArray alloc] init];
	[self setUserInteractionEnabled:YES];
	
	_linkAttributes = @{NSForegroundColorAttributeName : [UIColor blueColor],
						NSFontAttributeName : [UIFont boldSystemFontOfSize:self.font.pointSize]};
}

- (NSRange)searchForString:(NSString*)text fromRange:(NSRange)range
{
	if (range.location == NSNotFound)
	{
		return [self.text rangeOfString:text];
	}
	
	return [self.text rangeOfString:text options:0 range:range];
}

- (CGRect)textRect {
    
    CGRect textRect = [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];
    textRect.origin.y = (self.bounds.size.height - textRect.size.height)/2;
    
    if (self.textAlignment == NSTextAlignmentCenter) {
        textRect.origin.x = (self.bounds.size.width - textRect.size.width)/2;
    }
    if (self.textAlignment == NSTextAlignmentRight) {
        textRect.origin.x = self.bounds.size.width - textRect.size.width;
    }
    
    return textRect;
}

//Will be used to detect simple URL's and URL's on a anchor
- (void)detectURLsAndAnchorsOnText
{
	NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:NULL];
	
    NSArray *matches = [detector matchesInString:self.text
                                         options:0
                                           range:NSMakeRange(0, self.text.length)];
	
    for (NSTextCheckingResult *match in matches)
	{
		if ([match resultType] == NSTextCheckingTypeLink)
		{
			[self addLink:match.URL.absoluteString withText:match.URL.absoluteString andRange:match.range];
		}
	}
}


#pragma mark - UILabel Touch Events Protocol Delegates

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    self.lastTouches = touches;
    
    UITouch *touch = [touches anyObject];
    CFIndex index = [self characterIndexAtPoint:[touch locationInView:self]];
	
	PPLabelLink *isLink = [[PPLabelLink alloc] init];
	[isLink setDummyLocation:index];

	NSUInteger indexOnArray = [self.links indexOfObject:isLink];
	isLink = nil;
	if (indexOnArray != NSNotFound)
	{
		if ([self.delegate respondsToSelector:@selector(label:didSelectTextWithLink:)])
		{
			[self.delegate label:self didSelectTextWithLink:[self.links objectAtIndex:indexOnArray]];
			return;
		}
	}
	
	if (![self.delegate respondsToSelector:@selector(label:didBeginTouch:onCharacterAtIndex:)])
	{
		[super touchesBegan:touches withEvent:event];
		return;
	}
    
    if (![self.delegate label:self didBeginTouch:touch onCharacterAtIndex:index]) {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    self.lastTouches = touches;
    
    UITouch *touch = [touches anyObject];
    CFIndex index = [self characterIndexAtPoint:[touch locationInView:self]];
	
	if (![self.delegate respondsToSelector:@selector(label:didMoveTouch:onCharacterAtIndex:)])
	{
		[super touchesMoved:touches withEvent:event];
		return;
	}
    
    if (![self.delegate label:self didMoveTouch:touch onCharacterAtIndex:index]) {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.lastTouches) {
        return;
    }
    
    self.lastTouches = nil;
    
    UITouch *touch = [touches anyObject];
    CFIndex index = [self characterIndexAtPoint:[touch locationInView:self]];
	
	if (![self.delegate respondsToSelector:@selector(label:didEndTouch:onCharacterAtIndex:)])
	{
		[super touchesEnded:touches withEvent:event];
		return;
	}
    
    if (![self.delegate label:self didEndTouch:touch onCharacterAtIndex:index]) {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.lastTouches) {
        return;
    }
    
    self.lastTouches = nil;
    
    UITouch *touch = [touches anyObject];
	
	if (![self.delegate respondsToSelector:@selector(label:didCancelTouch:)])
	{
		[super touchesCancelled:touches withEvent:event];
		return;
	}
    
    if (![self.delegate label:self didCancelTouch:touch]) {
        [super touchesCancelled:touches withEvent:event];
    }
}

- (void)cancelCurrentTouch {
    
    if (self.lastTouches) {
        [self.delegate label:self didCancelTouch:[self.lastTouches anyObject]];
        self.lastTouches = nil;
    }
}

@end
