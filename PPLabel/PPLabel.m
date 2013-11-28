//
//  PPLabel.m
//  PPLabel
//
//  Created by Petr Pavlik on 12/26/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import "PPLabel.h"
#import <CoreText/CoreText.h>

#import "PPLabelLink.h"

@interface PPLabel ()

@property(nonatomic, strong) NSSet* lastTouches;
@property (nonatomic, retain) NSMutableArray *links;

- (void)initialize;
- (CGRect)textRect;

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
	NSLog(@"CharacterIndexAtPoint:");
    
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
	
	NSLog(@"characterIndexAtPoint: %@ : %u", NSStringFromCGPoint(point), idx);
    
    return idx;
}

- (void)addLink:(NSString*)link withText:(NSString*)text
{
	
	PPLabelLink *newLink = [[PPLabelLink alloc] init];
	
	[newLink setRef:link];
	[newLink setText:text];
	
	NSRange range = [self.text rangeOfString:text];
	
	if (range.location != NSNotFound)
	{
		[newLink setRange:range];
		
		if ([self.links indexOfObject:newLink] == NSNotFound)
		{
			NSLog(@"Range of text %@ : %@", text, NSStringFromRange(range));
			
			NSMutableAttributedString *attribString = [self.attributedText mutableCopy];
			[attribString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:range];
			
			self.attributedText = attribString;
			
			[self.links addObject:newLink];
		}
	}
	
	NSLog(@"Number of links: %d", [self.links count]);
	
	
//	NSUInteger words = 0, characters = 0;
//	
//	if (range.location != NSNotFound)
//	{
//		NSArray *fullTextTokens = [self.text componentsSeparatedByString:@" "];
//		while (characters < range.location)
//		{
//			NSLog(@"Word: %@ at position: %d", fullTextTokens[words], words);
//			characters += ([fullTextTokens[words] length] + 1);
//			words++;
//		}
//	}
//	NSLog(@"Words: %u", words);
//	NSLog(@"Characters: %u", characters);
//	
//	NSString *result = nil;
//	NSScanner *scanner = [[NSScanner alloc] initWithString:self.text];
//	[scanner setCaseSensitive:NO];
//	if ([scanner scanUpToString:text intoString:&result] == YES)
//	{
//		NSLog(@"Founded String %@ at position: %u", text, [scanner scanLocation]);
//	}
//	
//	if ([scanner scanString:text intoString:&result])
//	{
//		NSLog(@"Founded String %@ at position: %u", text, [scanner scanLocation]);
//	}
}


#pragma mark - Override methods

- (void)setText:(NSString *)text
{
	[super setText:text];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
	[super setAttributedText:attributedText];
}


#pragma mark - Private Methods

- (void)initialize
{
	self.links = [[NSMutableArray alloc] init];
	[self setUserInteractionEnabled:YES];
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
			
		}
	}
}


#pragma mark - Protocol Delegates

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    self.lastTouches = touches;
    
    UITouch *touch = [touches anyObject];
    CFIndex index = [self characterIndexAtPoint:[touch locationInView:self]];
    
    if (![self.delegate label:self didBeginTouch:touch onCharacterAtIndex:index]) {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    self.lastTouches = touches;
    
    UITouch *touch = [touches anyObject];
    CFIndex index = [self characterIndexAtPoint:[touch locationInView:self]];
    
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
