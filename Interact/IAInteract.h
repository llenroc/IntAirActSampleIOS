//
//  IAInteract.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-28.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <RestKit/RestKit.h>

#import "IADevice.h"

@interface IAInteract : NSObject

- (RKObjectManager *)objectManagerForDevice:(IADevice *)device;
- (NSString*)resourcePathFor:(NSObject*)resource withAction:(NSString*)action forObjectManager:(RKObjectManager *)manager;

@end
