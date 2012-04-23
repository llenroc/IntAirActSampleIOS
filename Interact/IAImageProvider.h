#import <Foundation/Foundation.h>

@class IADevice;

@interface IAImageProvider : NSObject

@property (nonatomic, strong) NSArray * images;

-(id)initWithDevice:(IADevice*)device;
-(NSData*)imageAsData:(NSNumber*)identifier;

@end
