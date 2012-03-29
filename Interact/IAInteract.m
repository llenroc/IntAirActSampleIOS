//
//  IAInteract.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-28.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAInteract.h"

#import "IADevice.h" 
#import "IAImageServer.h"

@interface IAInteract () {
    NSNetServiceBrowser * netServiceBrowser;
	NSNetService *serverService;
	NSMutableArray *serverAddresses;
}

@property (strong, nonatomic) NSMutableDictionary * objectManagers;
@property (strong, nonatomic) NSMutableArray * servers;
@property (strong) NSMutableArray * services;

@end

@implementation IAInteract

@synthesize objectMappingProvider = _objectMappingProvider;
@synthesize router = _router;
@synthesize httpServer = _httpServer;

@synthesize objectManagers = _objectManagers;
@synthesize servers = _servers;
@synthesize services = _services;

- (id)init
{
    self = [super init];
    if (self) {
        self.objectMappingProvider = [[RKObjectMappingProvider alloc] init];
        self.router = [RKObjectRouter new];
        self.objectManagers = [[NSMutableDictionary alloc] init];
        self.servers = [[NSMutableArray alloc] init];
        self.services = [[NSMutableArray alloc] init];
        
        netServiceBrowser = [[NSNetServiceBrowser alloc] init];
        
        [netServiceBrowser setDelegate:self];
        [netServiceBrowser searchForServicesOfType:@"_interact._tcp." inDomain:@"local."];

    }
    return self;
}

- (RKObjectManager *)objectManagerForDevice:(IADevice *)device {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    RKObjectManager * manager = [self.objectManagers objectForKey:device.hostAndPort];
    
    if(!manager) {
        manager = [[RKObjectManager alloc] initWithBaseURL:device.hostAndPort];
        
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

- (NSString*)resourcePathFor:(NSObject*)resource withAction:(NSString*)action forObjectManager:(RKObjectManager *)manager{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSString* path = [manager.router resourcePathForObject:resource method:RKRequestMethodPUT];
    path = [path stringByAppendingString:@"/"];
    path = [path stringByAppendingString:action];
    return path;
}

-(RoutingHTTPServer *)httpServer
{
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
        [_httpServer setPort:12345];
        
        // Serve files from our embedded Web folder
        NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
        DDLogInfo(@"Setting document root: %@", webPath);
        
        [_httpServer setDocumentRoot:webPath];
        
        // Start the server (and check for problems)
        
        NSError *error;
        if(![_httpServer start:&error])
        {
            DDLogError(@"Error starting HTTP Server: %@", error);
        }
    }
    return _httpServer;
}

- (void)registerServer:(id<IAServer>)server
{
    [self.servers addObject:server];
}

- (RKObjectSerializer *)serializerForObject:(id) object
{
    RKObjectMapping * mapping = [self.objectMappingProvider serializationMappingForClass:[object class]];
    return [RKObjectSerializer serializerWithObject:object mapping:mapping];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender didNotSearch:(NSDictionary *)errorInfo
{
	DDLogError(@"DidNotSearch: %@", errorInfo);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	DDLogVerbose(@"DidFindService: %@", [netService name]);
    
    [self.services addObject:netService];
    [netService setDelegate:self];
    [netService resolveWithTimeout:0.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
         didRemoveService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	DDLogVerbose(@"DidRemoveService: %@", [netService name]);
    [self.services removeObject:netService];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender
{
	DDLogInfo(@"DidStopSearch");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	DDLogError(@"DidNotResolve");
    [self.services removeObject:sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	DDLogInfo(@"DidResolve: %@:%i", [sender hostName], [sender port]);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceUpdate" object:self];
}

- (NSArray *)getDevices
{
    NSMutableArray * devices = [[NSMutableArray alloc] init];
    for(NSNetService * service in self.services) {
        if(service.hostName && service.port) {
            IADevice * device = [IADevice new];
            device.name = service.name;
            device.hostAndPort = [NSString stringWithFormat:@"http://%@:%i/", service.hostName, service.port];
            [devices addObject:device];
        }
    }
    return devices;
}

@end
