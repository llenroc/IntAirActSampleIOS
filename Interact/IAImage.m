//
//  IAImage.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-20.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImage.h"

@implementation IAImage

@synthesize identifier = _identifier;

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAImage[identifier: %@]", self.identifier];
}

@end
