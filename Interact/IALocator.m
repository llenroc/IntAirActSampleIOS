#import "IALocator.h"

@interface IALocator ()

@property CLLocationDirection currentHeading;
@property CLLocation * currentLocation;
@property (nonatomic, strong) CLLocationManager * locManager;
@property (nonatomic, strong) CMMotionManager * motManager;

@end

@implementation IALocator

@synthesize currentHeading = _currentHeading;
@synthesize currentLocation = _currentLocation;
@synthesize locManager = _locManager;
@synthesize motManager = _motManager;

- (void)startTracking
{
    if (!self.locManager) {
        CLLocationManager * theManager = [CLLocationManager new];
        
        // Retain the object in a property.
        self.locManager = theManager;
        _locManager.delegate = self;
    }
    
    if (!self.motManager) {
        self.motManager = [CMMotionManager new];
    }
    
    if(self.motManager.deviceMotionAvailable) {
        [self.motManager startDeviceMotionUpdates];
    } else {
        DDLogError(@"Device Motion not available");
    }
    
    // Start location services to get the true heading.
    _locManager.distanceFilter = 1000;
    _locManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    [_locManager startUpdatingLocation];
    
    // Start heading updates.
    if ([CLLocationManager headingAvailable]) {
        _locManager.headingFilter = 1;
        [_locManager startUpdatingHeading];
    }
    
    [_locManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if (newHeading.headingAccuracy < 0)
        return;
    // Use the true heading if it is valid.
    CLLocationDirection theHeading = ((newHeading.trueHeading > 0) ?
                                       newHeading.trueHeading : newHeading.magneticHeading);
    self.currentHeading = theHeading;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    // If it's a relatively recent event, turn off updates to save power
    self.currentLocation = newLocation;
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude);
    }
    // else skip the event and process the next one.
}

-(UIInterfaceOrientation)currentOrientation
{
    return [[UIApplication sharedApplication] statusBarOrientation];
}

-(CMDeviceMotion *)deviceMotion
{
    return self.motManager.deviceMotion;
}

-(float)realAngle:(float)angle
{    
    // rotate it by 90 to the left so that a swipe up is 0
    angle -= M_PI_2;
    //DDLogVerbose(@"Angle: %f", angle);
    
    // if the angle is less than zero make it that its in [0,2*pi] again
    if (angle < 0) {
        angle += M_PI * 2;
    }
    //DDLogVerbose(@"Angle: %f", angle);
    
    float heading = [self currentHeading] / 180 * M_PI;
    //DDLogVerbose(@"Heading: %f", heading);
    
    // subtract the heading to make the angle point north
    angle -= heading;
    //DDLogVerbose(@"Angle: %f", angle);
    
    // if the angle is less than zero make it that its in [0,2*pi] again
    if (angle < 0) {
        angle += M_PI * 2;
    }
    //DDLogVerbose(@"Angle: %f", angle);
    
    // account for device orientation
    switch([self currentOrientation]) {
        case UIInterfaceOrientationPortrait:
            break;
        case UIInterfaceOrientationLandscapeLeft:
            // the device has been rotated to the right, thus the interface has been rotated to the left
            angle -= M_PI_2 * 3;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angle -= M_PI;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle -= M_PI_2;
            // the device has been rotated to the left, thus the interface has been rotated to the right
            break;
    }
    //DDLogVerbose(@"Angle: %f", angle);
    
    // if the angle is less than zero make it that its in [0,2*pi] again
    if (angle < 0) {
        angle += M_PI * 2;
    }
    //DDLogVerbose(@"Angle: %f", angle);
    
    //DDLogVerbose(@"You swiped at %f", angle * 180 / M_PI);
    
    return angle;
}

@end
