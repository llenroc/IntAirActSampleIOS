#import <UIKit/UIKit.h>

@class IADevice;
@class IAInteract;

@interface IAImageTableViewController : UITableViewController

@property (nonatomic, strong) IADevice * device;
@property (nonatomic, strong) IAInteract * interact;

@end
