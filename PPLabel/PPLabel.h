//
//  PPLabel.h
//  PPLabel
//
//  Created by Petr Pavlik on 12/26/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PPLabelLink.h"

@class PPLabel;

/// The delegate of a PPLabel object
@protocol PPLabelDelegate <NSObject>

@optional

/**
 Tells the delegate that the label was touched and returns which character was touched.
 
 @param label The instance of PPLabel that called this method.
 @param touch The touch that triggered this event.
 @param cIndex of a character at given point or NSNotFound.
 
 @return Return YES if the delegate handled this touch and should not be propagated any further.
 */
- (BOOL)label:(PPLabel*)label didBeginTouch:(UITouch*)touch onCharacterAtIndex:(CFIndex)charIndex;

/**
 Tells the delegate that the touch was moved.
 
 @param label The instance of PPLabel that called this method.
 @param touch The touch that triggered this event.
 @param cIndex of a character at given point or NSNotFound.
 
 @return Return YES if the delegate handled this touch and should not be propagated any further.
 */
- (BOOL)label:(PPLabel*)label didMoveTouch:(UITouch*)touch onCharacterAtIndex:(CFIndex)charIndex;

/**
 Tells the delegate that the label that it's not being touched anymore.
 
 @param label The instance of PPLabel that called this method.
 @param touch The touch that triggered this event.
 @param cIndex of a character at given point or NSNotFound.
 
 @return Return YES if the delegate handled this touch and should not be propagated any further.
 */
- (BOOL)label:(PPLabel*)label didEndTouch:(UITouch*)touch onCharacterAtIndex:(CFIndex)charIndex;

/**
 Tells the delegate that the label that it's not being touched anymore.
 
 @param label The instance of PPLabel that called this method.
 @param touch The touch that triggered this event.
 
 @return Return YES if the delegate handled this touch and should not be propagated any further.
 */
- (BOOL)label:(PPLabel*)label didCancelTouch:(UITouch*)touch;


/**
 Method that is invoked on delegate each time that the user touch a text with a link behind
 
 @param label The instance of PPLabel that called this method.
 @param labelLink The instance with the information of the text and link
 
 */
- (void)label:(PPLabel*)label didSelectTextWithLink:(PPLabelLink*)labelLink;

@end


/// Subclass of PPLabel which can detect touches and report which character was touched.
@interface PPLabel : UILabel

/**
 The object that acts as the delegate of the receiving label.
 
 @see PPLabelDelegate
 */
@property(nonatomic, weak) id <PPLabelDelegate> delegate;


@property (nonatomic, retain) NSDictionary *linkAttributes;

/**
 Cancels current touch and calls didCancelTouch: on the delegate.
 
 This method does nothing if there is no touch session.
 */
- (void)cancelCurrentTouch;

/**
 Returns the index of character at provided point or NSNotFound.
 
 @param point The point indicating where to look for.
 
 @return Index of a character at given point or NSNotFound.
 */
- (CFIndex)characterIndexAtPoint:(CGPoint)point;

/**
 Adds a link to the string specified if this exists on label text. When user tap the string the method is send to delegate if this one response to that.
 This method detects all the instances of text in label text.
 
 @param link This should be an instance of NSString with the link that will be send to delegate when string is pressed.
 
 @param text This should be an instance of NSString with the text that will be searched in the label text
 
 */
- (void)addLink:(NSString*)link withText:(NSString*)text;

/**
 Adds a link to the string specified if this exists on label text. When user tap the string the method is send to delegate if this one response to that.
 
 @param link This should be an instance of NSString with the link that will be send to delegate when string is pressed.
 
 @param text This should be an instance of NSString with the text that will be searched in the label text
 
 @param range The location of the text in the label text
 
 */
- (void)addLink:(NSString*)link withText:(NSString*)text andRange:(NSRange)range;

@end
