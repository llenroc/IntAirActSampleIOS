#import <Foundation/Foundation.h>

@class IAImage;
@class IADevice;
@class IAInteract;

@interface IAImageClient : NSObject

-(id)initWithInteract:(IAInteract *)interact;
-(void)getImages:(void (^)(NSArray *))block fromDevice:(IADevice *)device;
-(void)displayImage:(IAImage *)image ofDevice:(IADevice *)source onDevice:(IADevice *)target;

@end
