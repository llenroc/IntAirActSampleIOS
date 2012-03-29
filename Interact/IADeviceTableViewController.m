//
//  IADeviceTableViewController.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-19.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IADeviceTableViewController.h"
#import "IADevice.h"
#import "IAImageServer.h"
#import "IAImages.h"
#import "IAInteract.h"
#import "IAImageClient.h"

@interface IADeviceTableViewController ()

@property (nonatomic, strong) IAInteract * interact;
@property (nonatomic, strong) NSArray *devices;

@end

@implementation IADeviceTableViewController

@synthesize interact = _interact;
@synthesize devices = _devices;

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
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:@"DeviceUpdate" object:nil];    

    if(!self.devices) {
        self.devices = self.interact.getDevices;
    }
    
}

- (IAInteract *)interact {
    if(!_interact) {
        _interact = [[IAInteract alloc] init];
        [IAImageClient setupMapping:_interact];
        [_interact registerServer:[[IAImageServer alloc] initWithInteract:_interact]];
    }
    return _interact;
}

- (void)refresh:(NSNotification*)note {
    NSLog(@"Got notified: %@", note);
    self.devices = self.interact.getDevices;
}

-(void)setDevices:(NSArray *)devices
{
    if (_devices != devices) {
        _devices = devices;
        // Model changed, so update our View (the table)
        if (self.tableView.window) [self.tableView reloadData];
    }

}

@end
