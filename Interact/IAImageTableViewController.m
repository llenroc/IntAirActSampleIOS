//
//  IAImageTableViewController.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-19.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageTableViewController.h"
#import "IAImage.h"

@interface IAImageTableViewController ()

@property (nonatomic, strong) NSArray * images;

@end

@implementation IAImageTableViewController

@synthesize device = _device;
@synthesize images = _images;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.images.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Image";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    IAImage * image = [self.images objectAtIndex:indexPath.row];
    cell.textLabel.text = image.name;
    cell.detailTextLabel.text = image.location.description;
    
    return cell;
}

- (void)setDevice:(IADevice *)device
{
    _device = device;
    self.title = device.name;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
#warning Adding a standard image as a fallback
    if(!self.images) {
        IAImage * image = [[IAImage alloc] init];
        image.name = @"Name";
        NSArray * images = [[NSArray alloc] initWithObjects:image, nil];
        self.images = images;
    }
    
}


@end
