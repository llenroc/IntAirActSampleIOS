#import "IAServer.h"

#import <IntAirAct/IntAirAct.h>

#import "IAImageTableViewController.h"

#import "IAImageViewController.h"

@implementation IAServer

@synthesize intAirAct;
@synthesize navigationController;

-(NSNumber *)add:(NSNumber *)a to:(NSNumber *) b
{
    return [NSNumber numberWithInt:([a intValue] + [b intValue])];
}

-(void)displayImage:(IAImage *)image ofDevice:(IADevice *)device
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIMainStoryboardFile"] bundle: nil];
    
    UIViewController * rootViewController = [self.navigationController.viewControllers objectAtIndex:0];
    
    IAImageTableViewController * imageTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"ImageTableViewController"];
    imageTableViewController.intAirAct = self.intAirAct;
    imageTableViewController.device = device;
    
    IAImageViewController * imageViewController = [storyboard instantiateViewControllerWithIdentifier:@"ImageViewController"];
    imageViewController.intAirAct = self.intAirAct;
    imageViewController.image = image;
    imageViewController.device = device;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController setViewControllers:[NSArray arrayWithObjects:rootViewController, imageTableViewController, imageViewController, nil] animated:YES];
    });
}

@end
