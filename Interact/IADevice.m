#import "IADevice.h"

@implementation IADevice

@synthesize name = _name;
@synthesize hostAndPort = _hostAndPort;

-(NSString *)description
{
    return [NSString stringWithFormat:@"Device[name: %@, hostAndPort: %@]", self.name, self.hostAndPort];
}

@end
