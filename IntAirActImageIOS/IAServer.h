#import <Foundation/Foundation.h>

@class IAAction;
@class IADevice;
@class IAImage;
@class IAIntAirAct;

@interface IAServer : NSObject

@property (nonatomic, weak) UINavigationController * navigationController;
@property (nonatomic, weak, readonly) IAIntAirAct * intAirAct;

-(id)initWithIntAirAct:(IAIntAirAct *)value;
-(NSNumber *)add:(NSNumber *)a to:(NSNumber *)b;
-(void)displayImage:(IAImage *)image ofDevice:(IADevice *)device;

@end