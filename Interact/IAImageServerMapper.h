//
//  InteractImageServerMapper.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-08.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import "IAImageServer.h"

@interface InteractImageServerMapper : NSObject

@property (strong, nonatomic) InteractImageServer* imageServer;

- (void)startServer;

@end
