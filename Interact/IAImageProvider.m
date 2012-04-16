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
#import <AssetsLibrary/AssetsLibrary.h>

@interface IAImageProvider ()

@property (nonatomic) NSDictionary * idToImages;

@end

@implementation IAImageProvider

@synthesize images = _images;
@synthesize idToImages = _idToImages;

+(ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary * library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library; 
}

-(id)init
{
    self = [super init];
    if (self) {
        [self loadImages];
    }
    return self;
}

-(void)loadImages
{
    // collect the photos
    NSMutableArray * collector = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableDictionary * dictionary = [NSMutableDictionary new];
    ALAssetsLibrary * al = [[self class] defaultAssetsLibrary];
    
    __block int i = 1;
    [al enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
            if (asset) {
                NSString * prop = [asset valueForProperty:@"ALAssetPropertyType"];
                if(prop && [prop isEqualToString:@"ALAssetTypePhoto"]) {
                    ALAssetRepresentation * rep = [asset representationForUTI:@"public.jpeg"];
                    if (rep) {
                        IAImage * image = [IAImage new];
                        image.identifier = [NSNumber numberWithInt:i];
                        image.name = [NSString stringWithFormat:@"Image %i", index];
#warning implement this
                        image.location = [NSString stringWithFormat:@"http://arlos-iphone.local.:12345/images/%i.jpg", index];
                        [collector addObject:image];
                        [dictionary setObject:asset forKey:image.identifier];
                        i++;
                    }
                }
            }  
        }];
        
        self.images = collector;
        self.idToImages = dictionary;
        DDLogVerbose(@"%@", collector);
    } failureBlock:^(NSError *error) {
        NSLog(@"Boom!!!");
    }];
    
}

-(IAImage*)image:(NSNumber*)identifier
{
    return [self.images objectAtIndex:[identifier integerValue]];
}

-(NSData *)imageAsData:(NSNumber*)identifier
{
    ALAsset * ass = [self.idToImages objectForKey:identifier];

    int byteArraySize = ass.defaultRepresentation.size;
    
    DDLogVerbose(@"Size of the image: %i", byteArraySize);

    NSMutableData* rawData = [[NSMutableData alloc]initWithCapacity:byteArraySize];
    void* bufferPointer = [rawData mutableBytes];
    
    NSError* error=nil;
    [ass.defaultRepresentation getBytes:bufferPointer fromOffset:0 length:byteArraySize error:&error];
    if (error) {
        DDLogError(@"%@",error);
    }
    
    rawData = [NSMutableData dataWithBytes:bufferPointer length:byteArraySize];

    return rawData;
}

@end
