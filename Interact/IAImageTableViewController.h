//
//  IAImageTableViewController.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-19.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IADevice;
@class IAInteract;

@interface IAImageTableViewController : UITableViewController

@property (nonatomic, strong) IADevice * device;
@property (nonatomic, strong) IAInteract * interact;

@end
