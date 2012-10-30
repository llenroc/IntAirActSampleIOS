#import "IADeviceTableViewController.h"

#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IntAirAct.h>

#import "IAPhotoBrowser.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IADeviceTableViewController ()

@property (nonatomic, strong) NSMutableArray * devices;
@property (nonatomic, strong) id deviceFoundObserver;
@property (nonatomic, strong) id deviceLostObserver;

@end

@implementation IADeviceTableViewController

-(void)viewDidLoad
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    [super viewDidLoad];
}

-(void)viewDidUnload
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.devices.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Device";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    IADevice * dev = [self.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = dev.name;
    
    return cell;
}

-(void)viewWillAppear:(BOOL)animated {
    DDLogVerbose(@"%@: %@, animated: %i", THIS_FILE, THIS_METHOD, animated);
    [super viewWillAppear:animated];

    IACapability * imageCap = [IACapability new];
    imageCap.capability = @"GET /images";

    self.deviceFoundObserver = [self.intAirAct addHandlerForDeviceFound:^(IADevice *device, BOOL ownDevice) {
        DDLogVerbose(@"%@: foundDevice: %@", THIS_FILE, device);
        if ([device.capabilities containsObject:imageCap]) {
            [self.devices addObject:device];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }];

    self.deviceLostObserver = [self.intAirAct addHandlerForDeviceLost:^(IADevice *device) {
        [self.devices removeObject:device];
        [self.tableView reloadData];
    }];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.intAirAct removeObserver:self.deviceFoundObserver];
    [self.intAirAct removeObserver:self.deviceLostObserver];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    IAPhotoBrowser * browser = [IAPhotoBrowser new];
    browser.intAirAct = self.intAirAct;
    browser.device = [self.devices objectAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:browser animated:YES];
	
	// Deselect
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSMutableArray *)devices
{
    if (!_devices) {
        _devices = [NSMutableArray new];
    }
    return _devices;
}

@end
