//
//  IAImageAction.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-30.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageAction.h"

@implementation IAImageAction

@synthesize action = _action;
@synthesize image = _image;
@synthesize device = _device;

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAImageAction[action: %@, image: %@%, device: %@]", self.action, self.image, self.device];
}


@end
