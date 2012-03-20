//
//  IADevice.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-19.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IADevice : NSObject

@property (nonatomic, retain) NSNumber* identifier;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* hostAndPort;

@end
