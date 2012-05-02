#import "IAImages.h"

@implementation IAImages

@synthesize images = _images;

-(NSString *)description
{
    return [NSString stringWithFormat:@"IAImages[images: %@]", self.images];
}

@end
