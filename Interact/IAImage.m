#import "IAImage.h"

@implementation IAImage

@synthesize identifier = _identifier;
@synthesize device = _device;

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAImage[identifier: %@, device: %@]", self.identifier, self.device];
}

@end
