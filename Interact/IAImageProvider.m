//
//  InteractImageServer.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-08.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageProvider.h"
#import "IAImage.h"

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
    image.name = @"image";
    image.location = @"https://encrypted.google.com/images/srpr/logo3w.png";
    return image;
}

@end