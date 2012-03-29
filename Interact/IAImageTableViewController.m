//
//  IAImageTableViewController.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-19.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageTableViewController.h"
#import "IAImage.h"
#import "IAImageClient.h"
#import "IADevice.h"

@interface IAImageTableViewController ()

@property (nonatomic, strong) NSArray * images;
@property (nonatomic, strong) IAImageClient * imageClient;

@end

@implementation IAImageTableViewController

@synthesize device = _device;
@synthesize interact = _interact;

@synthesize images = _images;
@synthesize imageClient = _imageClient;

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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath * indexPath = [self.tableView indexPathForCell:sender];
    IAImage * image = [self.images objectAtIndex:indexPath.row];
    
    // be somewhat generic here (slightly advanced usage)
    // we'll segue to ANY view controller that has a device @property
    if ([segue.destinationViewController respondsToSelector:@selector(setImageURL:)]) {
        // use performSelector:withObject: to send without compiler checking
        // (which is acceptable here because we used introspection to be sure this is okay)
        NSURL * url = [NSURL URLWithString:image.location];
        [segue.destinationViewController performSelector:@selector(setImageURL:) withObject:url];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadImages];
}

- (void)setDevice:(IADevice *)device
{
    _device = device;
    self.title = device.name;
}

- (void)setImages:(NSArray *)images
{
    if (_images != images) {
        _images = images;
        // Model changed, so update our View (the table)
        if (self.tableView.window) [self.tableView reloadData];
    }
}

- (IAImageClient *)imageClient
{
    if (!_imageClient) {
        _imageClient = [[IAImageClient alloc] initWithInteract:self.interact];
    }
    return _imageClient;
}

- (void)loadImages
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if(self.interact && self.device) {
        [self.imageClient getImages:^(NSArray * images) {
            DDLogInfo(@"Loaded the following images: %@", images);
            self.images = images;
        } fromDevice:self.device];
        
    }
}

@end
