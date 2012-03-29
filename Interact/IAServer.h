//
//  IAServer.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-29.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IAInteract;

@protocol IAServer <NSObject>

- (id)initWithInteract:(IAInteract *)interact;

@end
