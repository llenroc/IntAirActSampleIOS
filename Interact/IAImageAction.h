//
//  IAImageAction.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-30.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IAImage;

@interface IAImageAction : NSObject

@property (nonatomic, strong) NSString * action;
@property (nonatomic, strong) IAImage * image;

@end
