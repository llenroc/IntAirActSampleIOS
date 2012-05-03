#import <UIKit/UIKit.h>

@class IADevice;
@class IAIntAirAct;

@interface IAImageTableViewController : UITableViewController

@property (nonatomic, strong) IADevice * device;
@property (nonatomic, weak) IAIntAirAct * intAirAct;

@end
