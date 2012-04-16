//
//  IAImages.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-28.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImages.h"

@implementation IAImages

@synthesize images = _images;

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAImages[images: %@]", self.images];
}


@end
