//
//  IADeviceTableViewController.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-19.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IADeviceTableViewController.h"

#import "IADevice.h"
#import "IAInteract.h"

@interface IADeviceTableViewController ()

@property (nonatomic, strong) NSArray * devices;

@end

@implementation IADeviceTableViewController

@synthesize interact = _interact;

@synthesize devices = _devices;

- (id)initWithStyle:(UITableViewStyle)style
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Device";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    IADevice * device = [self.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = device.name;
    cell.detailTextLabel.text = device.hostAndPort;
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSIndexPath * indexPath = [self.tableView indexPathForCell:sender];
    IADevice * device = [self.devices objectAtIndex:indexPath.row];
    
    // be somewhat generic here (slightly advanced usage)
    // we'll segue to ANY view controller that has a device @property
    if ([segue.destinationViewController respondsToSelector:@selector(setInteract:)]) {
        // use performSelector:withObject: to send without compiler checking
        // (which is acceptable here because we used introspection to be sure this is okay)
        [segue.destinationViewController performSelector:@selector(setInteract:) withObject:self.interact];
    }
    if ([segue.destinationViewController respondsToSelector:@selector(setDevice:)]) {
        [segue.destinationViewController performSelector:@selector(setDevice:) withObject:device];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [super viewWillAppear:animated];

    // Listens for DeviceUpdate notifications, Interact calls this notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:@"DeviceUpdate" object:nil];

    [self refresh:nil];
    [self.tableView reloadData];
}

- (void)refresh:(NSNotification*)note {
    DDLogVerbose(@"%@: %@, note: %@", THIS_FILE, THIS_METHOD, note);
    self.devices = self.interact.getDevices;
}

-(void)setDevices:(NSArray *)devices
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if (_devices != devices) {
        _devices = devices;
        // Model changed, so update our View (the table)
        if (self.tableView.window) [self.tableView reloadData];
    }

}

@end
