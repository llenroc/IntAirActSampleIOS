#import <UIKit/UIKit.h>

#import "MWPhotoBrowser.h"

@class IAIntAirAct;

@interface IADeviceTableViewController : UITableViewController <MWPhotoBrowserDelegate>

@property (nonatomic, strong) IAIntAirAct * intAirAct;

@end
