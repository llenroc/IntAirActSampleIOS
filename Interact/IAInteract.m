#import "IAInteract.h"

#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>
#import <RestKit+Blocks/RKObjectManager+Blocks.h>

#import "IAAction.h"
#import "IADevice.h"
#import "IALocator.h"
#import "IALogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int interactLogLevel = IA_LOG_LEVEL_INFO; // | IA_LOG_FLAG_TRACE;

@interface IAInteract () {
    dispatch_queue_t serverQueue;
    
    BOOL isRunning;
}

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

/**
 * Standard Constructor.
 * Instantiates Interact, but does not start it.
 **/
-(id)init
{
    self = [super init];
    if (self) {
        IALogTrace();
        
        serverQueue = dispatch_queue_create("Interact", NULL);

        self.objectMappingProvider = [RKObjectMappingProvider new];
        self.router = [RKObjectRouter new];
        
        self.deviceList = [NSMutableDictionary new];
        self.netServiceBrowser = [NSNetServiceBrowser new];
        [self.netServiceBrowser setDelegate:self];
        self.objectManagers = [NSMutableDictionary new];
        self.privLocator = [IALocator new];
        self.services = [NSMutableSet new];
        
        [self setup];
        
        isRunning = NO;
    }
    return self;
}

/**
 * Standard Deconstructor.
 * Stops the server, and clients, and releases any resources connected with this instance.
 **/
-(void)dealloc
{
    IALogTrace();
    
    // Stop the server if it's running
	[self stop];
    
    dispatch_release(serverQueue);
}

-(BOOL)start:(NSError **)errPtr;
{
    IALogTrace();
    
    __block BOOL success = YES;
	__block NSError *err = nil;
    
    dispatch_sync(serverQueue, ^{ @autoreleasepool {
        
        success = [self.httpServer start:&err];
		if (success) {
			IALogInfo(@"%@: Started Interact.", THIS_FILE);
			
            [self.locator startTracking];
            [self.netServiceBrowser searchForServicesOfType:@"_interact._tcp." inDomain:@"local."];
            isRunning = YES;
		} else {
			IALogError(@"%@: Failed to start Interact: %@", THIS_FILE, err);
		}
	}});
	
	if (errPtr) {
		*errPtr = err;
    }
	
	return success;
}

-(BOOL)isRunning
{
	__block BOOL result;
	
	dispatch_sync(serverQueue, ^{
		result = isRunning;
	});
	
	return result;
}

-(void)stop
{
    IALogTrace();
    
    dispatch_sync(serverQueue, ^{ @autoreleasepool {

        [self.httpServer stop];
        [self.netServiceBrowser stop];
        [self.services removeAllObjects];
        self.selfDevice = nil;

        isRunning = NO;
    }});
}

-(RKObjectMappingResult*)deserializeObject:(NSData*)data
{
    IALogTrace();
    
    NSString * bodyAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSError* error = nil;
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:RKMIMETypeJSON];
    id parsedData = [parser objectFromString:bodyAsString error:&error];
    
    if (parsedData == nil && error) {
        // Parser error...
        IALogError(@"An error ocurred: %@", error);
        return NULL;
    } else {
        return [self deserializeDictionary:parsedData];
    }
}

-(RKObjectMappingResult*)deserializeDictionary:(NSDictionary*)dictionary
{
    IALogTrace();
    
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

-(void)callAction:(IAAction *)action onDevice:(IADevice *)device
{
    dispatch_queue_t queue = dispatch_queue_create("IAInteract callAction", NULL);
    dispatch_async(queue, ^{
        RKObjectManager * manager = [self objectManagerForDevice:device];
        [manager putObject:action delegate:nil];
    });
    dispatch_release(queue);
}

-(void)loadObjectsAtResourcePath:(NSString *)resourcePath fromDevice:(IADevice *)device handler:(void (^)(RKObjectLoader *, NSError *))handler
{
    dispatch_queue_t queue = dispatch_queue_create("IAImageClient getImages", NULL);
    dispatch_async(queue, ^{
        RKObjectManager * manager = [self objectManagerForDevice:device];
        [manager loadObjectsAtResourcePath:@"/images" handler:handler];
    });
    dispatch_release(queue);
}

-(void)setup
{
    RKObjectMapping * deviceMapping = [RKObjectMapping mappingForClass:[IADevice class]];
    [deviceMapping mapAttributes:@"name", @"hostAndPort", nil];
    [self.objectMappingProvider setMapping:deviceMapping forKeyPath:@"devices"];
    
    RKObjectMapping * deviceSerialization = [deviceMapping inverseMapping];
    deviceSerialization.rootKeyPath = @"devices";
    [self.objectMappingProvider setSerializationMapping:deviceSerialization forClass:[IADevice class]];
    
    RKObjectMapping * actionSerialization = [RKObjectMapping mappingForClass:[NSDictionary class]];
    actionSerialization.rootKeyPath = @"actions";
    [actionSerialization mapAttributes:@"action", nil];
    RKDynamicObjectMapping * parametersSerialization = [RKDynamicObjectMapping dynamicMappingUsingBlock:^(RKDynamicObjectMapping *dynamicMapping) {
        dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping* (id mappableData) {
            RKObjectMapping * mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
            for(NSString * parameterName in [mappableData allKeys]) {
                id value = [mappableData valueForKey:parameterName];
                RKObjectMapping * serializationMapping = [self.objectMappingProvider serializationMappingForClass:[value class]];
                [mapping mapKeyPath:parameterName toRelationship:[serializationMapping.rootKeyPath stringByAppendingFormat:@"-%@", parameterName] withMapping:serializationMapping];
            }
            return mapping;
        };
    }];
    [actionSerialization hasMany:@"parameters" withMapping:parametersSerialization];
    [self.objectMappingProvider setSerializationMapping:actionSerialization forClass:[IAAction class]];
    
    RKObjectMapping * actionMapping = [RKObjectMapping mappingForClass:[IAAction class]];
    [actionMapping mapAttributes:@"action", nil];
    RKDynamicObjectMapping * parametersMapping = [RKDynamicObjectMapping dynamicMappingUsingBlock:^(RKDynamicObjectMapping *dynamicMapping) {
        dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping* (id mappableData) {
            NSDictionary * allRegisteredMappings = [self.objectMappingProvider mappingsByKeyPath];
            RKObjectMapping * mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
            for(NSString * key in [mappableData allKeys]) {
                NSArray * keyComponents = [key componentsSeparatedByString:@"-"];
                NSString * rootKeyPath = [keyComponents objectAtIndex:0];
                if (!rootKeyPath) {
                    continue;
                }
                NSString * parameterName = [keyComponents objectAtIndex:1];
                if (!parameterName) {
                    continue;
                }
                RKObjectMapping * originalMapping = [allRegisteredMappings valueForKey:rootKeyPath];
                if(!originalMapping) {
                    continue;
                }
                [mapping mapKeyPath:key toRelationship:parameterName withMapping:originalMapping];
            }
            return mapping;
        };
    }];
    [actionMapping hasMany:@"parameters" withMapping:parametersMapping];
    [self.objectMappingProvider setMapping:actionMapping forKeyPath:@"actions"];
    
    [self.router routeClass:[IAAction class] toResourcePath:@"/action/:action" forMethod:RKRequestMethodPUT];
}

-(RKObjectManager *)objectManagerForDevice:(IADevice *)device
{
    IALogTrace();
    
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
    IALogTrace();
    return [manager.router resourcePathForObject:resource method:RKRequestMethodPUT];
}

-(RoutingHTTPServer *)httpServer
{
    IALogTrace();
    
    if(!_httpServer) {
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
        IALogInfo(@"Setting document root: %@", webPath);
        
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
    IALogError(@"%@: %@, sender: %@, error: %@", THIS_FILE, THIS_METHOD, sender, errorInfo);
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender
          didFindService:(NSNetService *)netService
              moreComing:(BOOL)moreServicesComing
{
    IALogVerbose(@"%@: %@, service: %@", THIS_FILE, THIS_METHOD, [netService name]);
    [self.services addObject:netService];
    [netService setDelegate:self];
    [netService resolveWithTimeout:0.0];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender
        didRemoveService:(NSNetService *)netService
              moreComing:(BOOL)moreServicesComing
{
	IALogVerbose(@"DidRemoveService: %@", [netService name]);
    [self.services removeObject:netService];
    [self.deviceList removeObjectForKey:netService.name];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
}

-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender
{
    IALogTrace();
}

-(void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    IALogTrace();
	IALogError(@"DidNotResolve");
    [self.services removeObject:sender];
    [self.deviceList removeObjectForKey:sender.name];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender
{
    IALogTrace();
	IALogInfo(@"DidResolve: %@:%i", [sender hostName], [sender port]);
    IADevice * device = [IADevice new];
    device.name = sender.name;
    device.hostAndPort = [NSString stringWithFormat:@"http://%@:%i/", sender.hostName, sender.port];
    [self.deviceList setObject:device forKey:device.name];
    if ([self.httpServer.publishedName isEqual:device.name]) {
        self.selfDevice = device;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
}

@end
