//
//  InteractImageServer.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-08.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageProvider.h"
#import "IAImage.h"
#include <stdlib.h>


@implementation IAImageProvider

- (NSArray*)getImages {
    NSMutableArray* images = [[NSMutableArray alloc] init];
    [images addObject:[self getImage:[NSNumber numberWithInt:1]]];
    [images addObject:[self getImage:[NSNumber numberWithInt:2]]];
    [images addObject:[self getImage:[NSNumber numberWithInt:3]]];
    [images addObject:[self getImage:[NSNumber numberWithInt:4]]];
    return images;
}

- (IAImage*)getImage: (NSNumber*) identifier{
    IAImage* image = [IAImage new];
    image.identifier = identifier;
    int r = arc4random() % 4;
    switch (r) {
        case 0:
            image.name = @"Google";
            image.location = @"https://encrypted.google.com/images/srpr/logo3w.png";
            break;
        case 1:
            image.name = @"General";
            image.location = @"http://admotional.org/adstudio/img_bg_general.jpg";
            break;
        case 2:
            image.name = @"Köln";
            image.location = @"http://admotional.org/adstudio/img_bg_koeln.jpg";
            break;
        default:
            image.name = @"Berlin";
            image.location = @"http://admotional.org/adstudio/img_bg_berlin.jpg";
            break;
    }
    return image;
}

@end
