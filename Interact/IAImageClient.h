#import <Foundation/Foundation.h>

@class IAImage;
@class IADevice;
@class IAIntAirAct;

@interface IAImageClient : NSObject

-(id)initWithIntAirAct:(IAIntAirAct *)intAirAct;
-(void)getImages:(void (^)(NSArray *))block fromDevice:(IADevice *)device;
-(void)displayImage:(IAImage *)image ofDevice:(IADevice *)source onDevice:(IADevice *)target;

@end
