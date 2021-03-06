//
//  LinksViewController.m
//  PPLabel
//
//  Created by Petr Pavlik on 1/4/13.
//  Copyright (c) 2013 Petr Pavlik. All rights reserved.
//

#import "LinksViewController.h"

@interface LinksViewController ()

@property(nonatomic, strong) NSArray* matches;

@end

@implementation LinksViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.label.delegate = self;
    
//    NSError *error = NULL;
//    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
//
//    self.matches = [detector matchesInString:self.label.text options:0 range:NSMakeRange(0, self.label.text.length)];
    
//	[self highlightLinksWithIndex:NSNotFound];
	
	[self.label setLinkAttributes:@{NSForegroundColorAttributeName : [UIColor redColor],
									NSFontAttributeName : [UIFont boldSystemFontOfSize:self.label.font.pointSize]}];
	
	[self.label addLink:@"http://www.google.com" withText:@"another"];
	[self.label addLink:@"http://www.google.com" withText:@"is some"];
//	[self.label addLink:@"http://www.google.com" withText:@"text with"];
//	[self.label addLink:@"http://www.google.com" withText:@"random text"];
}

#pragma mark -

- (BOOL)label:(PPLabel *)label didBeginTouch:(UITouch *)touch onCharacterAtIndex:(CFIndex)charIndex {
    
    [self highlightLinksWithIndex:charIndex];
	
	return YES;
}

- (BOOL)label:(PPLabel *)label didMoveTouch:(UITouch *)touch onCharacterAtIndex:(CFIndex)charIndex {
    
    [self highlightLinksWithIndex:charIndex];
	
	return YES;
}

- (BOOL)label:(PPLabel *)label didEndTouch:(UITouch *)touch onCharacterAtIndex:(CFIndex)charIndex {
    
    [self highlightLinksWithIndex:NSNotFound];
    
    for (NSTextCheckingResult *match in self.matches) {
        
        if ([match resultType] == NSTextCheckingTypeLink) {
            
            NSRange matchRange = [match range];
            
            if ([self isIndex:charIndex inRange:matchRange]) {
                
                [[UIApplication sharedApplication] openURL:match.URL];
                break;
            }
        }
    }
	
	return YES;

}

- (BOOL)label:(PPLabel *)label didCancelTouch:(UITouch *)touch {
    
    [self highlightLinksWithIndex:NSNotFound];
	
	return YES;
}

#pragma mark -

- (BOOL)isIndex:(CFIndex)index inRange:(NSRange)range {
    return index > range.location && index < range.location+range.length;
}

- (void)highlightLinksWithIndex:(CFIndex)index {
    
    NSMutableAttributedString* attributedString = [self.label.attributedText mutableCopy];
    
    for (NSTextCheckingResult *match in self.matches) {
        
        if ([match resultType] == NSTextCheckingTypeLink) {
            
            NSRange matchRange = [match range];
            
            if ([self isIndex:index inRange:matchRange]) {
                [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:matchRange];
            }
            else {
                [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:matchRange];
            }
            
            [attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:matchRange];
        }
    }
    
    self.label.attributedText = attributedString;
}

- (void)label:(PPLabel *)label didSelectTextWithLink:(PPLabelLink *)labelLink
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:labelLink.text message:labelLink.ref delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [alert show];
}

@end
