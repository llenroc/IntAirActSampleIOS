#import <Foundation/Foundation.h>

@class IAImage;
@class IADevice;
@class IAInteract;

@interface IAImageClient : NSObject

+(void)setupMapping:(IAInteract *)interact;

-(id)initWithInteract:(IAInteract *)interact;
-(void)getImages:(void (^)(NSArray *))block fromDevice:(IADevice *)device;
-(void)displayImage:(IAImage *)image onDevice:(IADevice *)device;

@end
