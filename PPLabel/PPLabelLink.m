//
//  PPLabelLink.m
//  PPLabel
//
//  Created by Luís Portela Afonso on 27/11/13.
//  Copyright (c) 2013 Petr Pavlik. All rights reserved.
//

#import "PPLabelLink.h"

@implementation PPLabelLink


- (id)init
{
	self = [super init];
	
	if (self)
	{
		_range = NSMakeRange(NSNotFound, 0);
		_dummyLocation = nil;
	}
	
	return self;
}

- (id)initWithText:(NSString *)text link:(NSString *)link
{
	self = [super init];
	
	if (self)
	{
		_text = text;
		_ref = link;
	}
	
	return self;
}

- (BOOL)isEqual:(id)object
{
	PPLabelLink *this = (PPLabelLink*)object;
	
	if (this.dummyLocation != nil)
		return NSLocationInRange([this dummyLocation], _range);
	
	if (this.range.location != NSNotFound)
	{
		NSRange intersection = NSIntersectionRange(_range, this.range);
		NSLog(@"Intersection: %@", NSStringFromRange(intersection));
		if (intersection.length > 0) // there is some intersection, so there is a touch event to this text
			return YES;

		return NO;
	}
	
	if ((this.text != nil) && ([this.text length] > 0))
	{
		if ([this.text caseInsensitiveCompare:_text] == 0)
		{
			return YES;
		}
	}

	return NO;
}

@end
