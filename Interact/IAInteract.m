#import "IAInteract.h"

#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "IADevice.h"
#import "IALocator.h"

@interface IAInteract ()

@property (strong) NSMutableDictionary * deviceList;
@property (nonatomic, strong) NSNetServiceBrowser * netServiceBrowser;
@property (nonatomic, strong) NSMutableDictionary * objectManagers;
@property (nonatomic, strong) IALocator * privLocator;
@property (strong) IADevice * selfDevice;
@property (strong) NSMutableSet * services;

@end

@implementation IAInteract

@synthesize httpServer = _httpServer;
@synthesize objectMappingProvider = _objectMappingProvider;
@synthesize router = _router;

@synthesize deviceList = _deviceList;
@synthesize privLocator = _privLocator;
@synthesize netServiceBrowser = _netServiceBrowser;
@synthesize objectManagers = _objectManagers;
@synthesize selfDevice = _selfDevice;
@synthesize services = _services;

-(id)init
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    self = [super init];
    if (self) {
        self.objectMappingProvider = [RKObjectMappingProvider new];
        self.router = [RKObjectRouter new];
        
        self.deviceList = [NSMutableDictionary new];
        self.netServiceBrowser = [NSNetServiceBrowser new];
        [self.netServiceBrowser setDelegate:self];
        self.objectManagers = [NSMutableDictionary new];
        self.privLocator = [IALocator new];
        self.services = [NSMutableSet new];
    }
    return self;
}

-(RKObjectManager *)objectManagerForDevice:(IADevice *)device
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    RKObjectManager * manager = [self.objectManagers objectForKey:device.hostAndPort];
    
    if(!manager) {
        manager = [[RKObjectManager alloc] initWithBaseURL:[RKURL URLWithBaseURLString:device.hostAndPort]];
        
        // Ask for & generate JSON
        manager.acceptMIMEType = RKMIMETypeJSON;
        manager.serializationMIMEType = RKMIMETypeJSON;
        
        manager.mappingProvider = self.objectMappingProvider;
        
        // Register the router
        manager.router = self.router;
        
        [self.objectManagers setObject:manager forKey:device.hostAndPort];
        
        return manager;
    }
    
    return manager;
}

-(NSString *)resourcePathFor:(NSObject *)resource forObjectManager:(RKObjectManager *)manager
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    return [manager.router resourcePathForObject:resource method:RKRequestMethodPUT];
}

-(RoutingHTTPServer *)httpServer
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if(!_httpServer) {
        // Create server using our custom MyHTTPServer class
        _httpServer = [RoutingHTTPServer new];

        // Tell server to use our custom MyHTTPConnection class.
        // [httpServer setConnectionClass:[RESTConnection class]];
        
        // Tell the server to broadcast its presence via Bonjour.
        // This allows browsers such as Safari to automatically discover our service.
        [_httpServer setType:@"_interact._tcp."];
        
        // Normally there's no need to run our server on any specific port.
        // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
        // However, for easy testing you may want force a certain port so you can just hit the refresh button.
        //[_httpServer setPort:12345];
        
        // Serve files from our embedded Web folder
        NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
        DDLogInfo(@"Setting document root: %@", webPath);
        
        [_httpServer setDocumentRoot:webPath];
    }
    return _httpServer;
}

-(RKObjectSerializer *)serializerForObject:(id)object
{
    RKObjectMapping * mapping = [self.objectMappingProvider serializationMappingForClass:[object class]];
    return [RKObjectSerializer serializerWithObject:object mapping:mapping];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender didNotSearch:(NSDictionary *)errorInfo
{
    DDLogError(@"%@: %@, sender: %@, error: %@", THIS_FILE, THIS_METHOD, sender, errorInfo);
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
    DDLogVerbose(@"%@: %@, service: %@", THIS_FILE, THIS_METHOD, [netService name]);
    [self.services addObject:netService];
    [netService setDelegate:self];
    [netService resolveWithTimeout:0.0];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender
         didRemoveService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	DDLogVerbose(@"DidRemoveService: %@", [netService name]);
    [self.services removeObject:netService];
    [self.deviceList removeObjectForKey:netService.name];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
}

-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

-(void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	DDLogError(@"DidNotResolve");
    [self.services removeObject:sender];
    [self.deviceList removeObjectForKey:sender.name];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	DDLogInfo(@"DidResolve: %@:%i", [sender hostName], [sender port]);
    IADevice * device = [IADevice new];
    device.name = sender.name;
    device.hostAndPort = [NSString stringWithFormat:@"http://%@:%i/", sender.hostName, sender.port];
    [self.deviceList setObject:device forKey:device.name];
    if ([self.httpServer.publishedName isEqual:device.name]) {
        self.selfDevice = device;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
}

-(BOOL)start:(NSError **)errPtr;
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // Start the server (and check for problems)
    NSError * error;
    if(![self.httpServer start:&error])
    {
        DDLogError(@"Error starting HTTP Server: %@", error);
        if (errPtr)
            *errPtr = error;
        return NO;
    }
    [self.locator startTracking];
    [self.netServiceBrowser searchForServicesOfType:@"_interact._tcp." inDomain:@"local."];
    return YES;
}

-(void)stop
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self.httpServer stop];
    [self.netServiceBrowser stop];
    [self.services removeAllObjects];
}

-(void)dealloc
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

-(RKObjectMappingResult*)deserializeObject:(NSData*)data
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    NSString * bodyAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSError* error = nil;
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:RKMIMETypeJSON];
    id parsedData = [parser objectFromString:bodyAsString error:&error];
    
    if (parsedData == nil && error) {
        // Parser error...
        DDLogError(@"An error ocurred: %@", error);
        return NULL;
    } else {
        return [self deserializeDictionary:parsedData];
    }
}

-(RKObjectMappingResult*)deserializeDictionary:(NSDictionary*)dictionary
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:dictionary mappingProvider:self.objectMappingProvider];
    return [mapper performMapping];
}

-(IADevice *)ownDevice
{
    return self.selfDevice;
}

-(NSArray *)devices
{
    return [self.deviceList allValues];
}

-(IALocator *)locator
{
    return self.privLocator;
}

@end
