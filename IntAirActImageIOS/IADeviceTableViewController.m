#import "IADeviceTableViewController.h"

#import <CocoaLumberjack/DDLog.h>
#import <IntAirAct/IntAirAct.h>

#import "IAPhotoBrowser.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IADeviceTableViewController ()

@property (nonatomic, strong) NSArray * devices;
@property (nonatomic, strong) NSMutableArray * photos;

@end

@implementation IADeviceTableViewController

@synthesize intAirAct;

@synthesize devices;
@synthesize photos;

-(id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        //
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
    IADevice * dev = [self.devices objectAtIndex:indexPath.row];
    cell.textLabel.text = dev.name;
    
    return cell;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    IAPhotoBrowser * browser = [IAPhotoBrowser new];
    browser.intAirAct = self.intAirAct;
    browser.device = [self.devices objectAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:browser animated:YES];
	
	// Deselect
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
