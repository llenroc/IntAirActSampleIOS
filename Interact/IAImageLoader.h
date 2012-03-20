//
//  InteractImageLoader.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-07.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

#import "IAImage.h"
#import "IADevice.h"

@interface IAImageLoader : NSObject

+ (void) getImages: (void (^)(NSArray *)) block fromDevice: (IADevice *) device;
+ (void) displayImage: (IAImage *) image onDevice: (IADevice *) device;

@end
