//
//  IAImageViewController.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-20.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IAInteract;
@class IAImage;
@class IAImageClient;

@interface IAImageViewController : UIViewController

@property (nonatomic, strong) IAInteract * interact;
@property (nonatomic, strong) IAImage * image;
@property (nonatomic, strong) IAImageClient * imageClient;

@end
