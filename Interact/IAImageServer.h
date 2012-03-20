//
//  InteractImageServer.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-08.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAImage.h"

@interface InteractImageServer : NSObject
- (NSArray*)getImages;
- (IAImage*)getImage: (NSNumber*) identifier;
@end