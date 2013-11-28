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
//	object stored in the array
	PPLabelLink *this = (PPLabelLink*)object;

	if (self.dummyLocation != nil)
	{
		
		return NSLocationInRange(self.dummyLocation, this.range);
	}
	
	if (self.range.location != NSNotFound)
	{
		NSRange intersection = NSIntersectionRange(self.range, this.range);
		if (intersection.length > 0) // there is some intersection, so there is a touch event to this text
			return YES;

		return NO;
	}
	
	if ((self.text != nil) && ([self.text length] > 0))
	{
		if ([self.text caseInsensitiveCompare:this.text
			 ] == 0)
		{
			return YES;
		}
	}

	return NO;
}

@end
