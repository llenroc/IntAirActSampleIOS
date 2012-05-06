#import "IADeviceTableViewController.h"

#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IntAirAct.h>

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IADeviceTableViewController ()

@property (nonatomic, strong) NSArray * devices;

@end

@implementation IADeviceTableViewController

@synthesize intAirAct;

@synthesize devices;

-(id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

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
    IADevice * device = [self.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = device.name;
    cell.detailTextLabel.text = device.hostAndPort;
    
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DDLogVerbose(@"%@: %@, segue: %@, sender: %@", THIS_FILE, THIS_METHOD, segue, sender);
    
    NSIndexPath * indexPath = [self.tableView indexPathForCell:sender];
    IADevice * device = [self.devices objectAtIndex:indexPath.row];
    
    // be somewhat generic here (slightly advanced usage)
    // we'll segue to ANY view controller that has a device @property
    if ([segue.destinationViewController respondsToSelector:@selector(setIntAirAct:)]) {
        // use performSelector:withObject: to send without compiler checking
        // (which is acceptable here because we used introspection to be sure this is okay)
        [segue.destinationViewController performSelector:@selector(setIntAirAct:) withObject:self.intAirAct];
    }
    if ([segue.destinationViewController respondsToSelector:@selector(setDevice:)]) {
        [segue.destinationViewController performSelector:@selector(setDevice:) withObject:device];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    DDLogVerbose(@"%@: %@, animated: %i", THIS_FILE, THIS_METHOD, animated);
    [super viewWillAppear:animated];

    // Listens for IADeviceUpdate notifications, IntAirAct calls this notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:IADeviceUpdate object:nil];

    [self refresh:nil];
    [self.tableView reloadData];
}

-(void)refresh:(NSNotification *)note {
    DDLogVerbose(@"%@: %@, note: %@", THIS_FILE, THIS_METHOD, note);
    IACapability * imageCap = [IACapability new];
    imageCap.capability = @"GET /images";
    self.devices = [self.intAirAct devicesWithCapability:imageCap];
}

-(void)setDevices:(NSArray *)value
{    
    if (devices != value) {
        devices = value;
        // Model changed, so update our View (the table)
        if (self.tableView.window) [self.tableView reloadData];
    }

}

@end
