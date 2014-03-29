#import "IADeviceTableViewController.h"

#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IntAirAct.h>

#import "IAImage.h"
#import "IAPhotoBrowser.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IADeviceTableViewController ()

@property (nonatomic, strong) NSMutableArray * devices;
@property (nonatomic, strong) id deviceFoundObserver;
@property (nonatomic, strong) id deviceLostObserver;
@property (nonatomic, strong) id applicationWillResignActiveObserver;

@end

@implementation IADeviceTableViewController

-(void)viewDidLoad
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    __weak IADeviceTableViewController * myself = self;

    self.deviceFoundObserver = [self.intAirAct addHandlerForDeviceFound:^(IADevice *device, BOOL ownDevice) {
        DDLogVerbose(@"%@: foundDevice: %@", THIS_FILE, device);
        if ([device.supportedRoutes containsObject:[IARoute get:@"/images"]]) {
            [myself.devices addObject:device];
            dispatch_async(dispatch_get_main_queue(), ^{
                [myself.tableView reloadData];
            });
        }
    }];

    self.deviceLostObserver = [self.intAirAct addHandlerForDeviceLost:^(IADevice *device) {
        DDLogVerbose(@"%@: removeDevice: %@", THIS_FILE, device);
        [myself.devices removeObject:device];
        dispatch_async(dispatch_get_main_queue(), ^{
            [myself.tableView reloadData];
        });
    }];

    self.applicationWillResignActiveObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.devices removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

-(void)viewDidUnload
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    [self.intAirAct removeHandler:self.deviceFoundObserver];
    [self.intAirAct removeHandler:self.deviceLostObserver];

    [[NSNotificationCenter defaultCenter] removeObserver:self.applicationWillResignActiveObserver];

    [super viewDidUnload];
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
    IADevice * device = [self.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = device.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    IAPhotoBrowser * browser = [IAPhotoBrowser new];
    browser.intAirAct = self.intAirAct;

    IARequest * request = [IARequest requestWithRoute:[IARoute routeWithAction:@"GET" resource:@"/images"] metadata:nil parameters:nil origin:self.intAirAct.ownDevice body:nil];

    IADevice * device = [self.devices objectAtIndex:indexPath.row];

    [self.intAirAct sendRequest:request toDevice:device withHandler:^(IAResponse *response, NSError *error) {
        if(!error) {
            NSArray * images = [response bodyAs:[IAImage class]];
            NSMutableArray * imageURLs = [NSMutableArray new];
            for (IAImage * img  in images) {
                NSString * imgUrlString = [NSString stringWithFormat:@"http://%@:%d/image/%@", device.host, device.port, img.identifier];
                NSURL * imgUrl = [NSURL URLWithString:imgUrlString];
                [imageURLs addObject:imgUrl];
            }
            browser.imageURLs = imageURLs;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController pushViewController:browser animated:YES];

                // Deselect
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            });
        } else {
            DDLogError(@"%@: An error ocurred while getting images: %@", THIS_FILE, error);
        }
    }];
}

-(NSMutableArray *)devices
{
    if (!_devices) {
        _devices = [NSMutableArray new];
    }
    return _devices;
}

@end
