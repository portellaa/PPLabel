//
//  PPLabelLink.h
//  PPLabel
//
//  Created by Luís Portela Afonso on 27/11/13.
//  Copyright (c) 2013 Petr Pavlik. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPLabel;

@interface PPLabelLink : NSObject

@property (nonatomic, retain) NSString *ref;
@property (nonatomic, retain) NSString *text;
@property (nonatomic) NSRange range;
@property (nonatomic) NSUInteger *dummyLocation;

- (id)init;
- (id)initWithText:(NSString*)text link:(NSString*)link;

- (BOOL)isEqual:(id)object;

@end
