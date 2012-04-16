//
//  InteractImageLoader.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-07.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IAImage;
@class IADevice;
@class IAInteract;

@interface IAImageClient : NSObject

+ (void) setupMapping:(IAInteract *)interact;

- (id) initWithInteract:(IAInteract *)interact;
- (void) getImages: (void (^)(NSArray *)) block fromDevice: (IADevice *) device;
- (void) displayImage: (IAImage *) image onDevice: (IADevice *) device;

@end
