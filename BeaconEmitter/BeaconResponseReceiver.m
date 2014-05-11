//
//  BeaconResponseReceiver.m
//  BeaconEmitter
//
//  Created by Matti Mustonen on 08/05/14.
//

#import "BeaconResponseReceiver.h"

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

@interface BeaconResponseReceiver()

@property(nonatomic, strong) RoutingHTTPServer* http;
@end
@implementation BeaconResponseReceiver

static BeaconResponseReceiver* server;

+ (BeaconResponseReceiver*)instance
{
    static dispatch_once_t dispatchOnceToken;
    
    dispatch_once(&dispatchOnceToken, ^{
        server = [[BeaconResponseReceiver alloc] init];
    });
    return server;
}

-(void)createServer{
    NSLog(@"creating server");
    self.http = [[RoutingHTTPServer alloc] init];
    
    // Set a default Server header in the form of YourApp/1.0
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
    if (!appVersion) {
        appVersion = [bundleInfo objectForKey:@"CFBundleVersion"];
    }
    NSString *serverHeader = [NSString stringWithFormat:@"%@/%@",
                              [bundleInfo objectForKey:@"CFBundleName"],
                              appVersion];
    [self.http setDefaultHeader:@"Server" value:serverHeader];
    
    [self setupRoutes];
    [self.http setPort:15000];
    [self.http setDocumentRoot:[@"~/Sites" stringByExpandingTildeInPath]];
    
    NSError *error;
    if (![self.http start:&error]) {
        NSLog(@"Error starting HTTP server: %@", error);
    }
}

- (void)setupRoutes {
    [self.http get:@"/hello" withBlock:^(RouteRequest *request, RouteResponse *response) {
        //[[NSNotificationCenter defaultCenter] postNotificationName:kHelloReceived object:nil];
        [response respondWithString:@"Hello!"];
    }];
    
    [self.http get:@"/hello/:name" withBlock:^(RouteRequest *request, RouteResponse *response) {
        NSString* name = [request param:@"name"];
        NSDictionary* dict = @{@"name": kHelloWithName, @"object": name };
        [self performSelectorOnMainThread:@selector(postNotifNamed:) withObject:dict waitUntilDone:NO];
        [response respondWithString:[NSString stringWithFormat:@"Hello %@!", name]];
    }];
    
    [self.http get:@"/bye/:name" withBlock:^(RouteRequest *request, RouteResponse *response) {
        NSString* name = [request param:@"name"];
        NSDictionary* dict = @{@"name": kByeWithName, @"object": name };
        [self performSelectorOnMainThread:@selector(postNotifNamed:) withObject:dict waitUntilDone:NO];
        [response respondWithString:[NSString stringWithFormat:@"Bye %@!", name]];
    }];
    
    [self.http post:@"/echo" withBlock:^(RouteRequest *request, RouteResponse *response) {
        // Create a new widget, [request body] contains the POST body data.
        // For this example we're just going to echo it back.
        [response respondWithData:[request body]];
    }];
    
    // Routes can also be handled through selectors
    [self.http handleMethod:@"GET" withPath:@"/selector" target:self selector:@selector(handleSelectorRequest:withResponse:)];
}

-(void)postNotifNamed:(NSDictionary*)params{
    [[NSNotificationCenter defaultCenter] postNotificationName:[params objectForKey:@"name"] object:[params objectForKey:@"object"]];
}

- (void)handleSelectorRequest:(RouteRequest *)request withResponse:(RouteResponse *)response {
    [response respondWithString:@"Handled through selector"];
}
@end
