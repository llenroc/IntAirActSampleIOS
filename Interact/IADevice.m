//
//  IADevice.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-19.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IADevice.h"

@implementation IADevice

@synthesize name = _name;
@synthesize hostAndPort = _hostAndPort;

-(NSString *)description
{
    return [NSString stringWithFormat:@"Device[name: %@, hostAndPort: %@]", self.name, self.hostAndPort];
}

@end
