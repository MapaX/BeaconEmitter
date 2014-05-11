//
//  BeaconResponseReceiver.h
//  BeaconEmitter
//
//  Created by Matti Mustonen on 08/05/14.
//  Copyright (c) 2014 Binimo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaHTTPServer/HTTPServer.h>

#define kHelloReceived @"kHelloReceived"
#define kHelloWithName @"kHelloWithName"
#define kByeWithName @"kByeWithName"

@interface BeaconResponseReceiver : NSObject

+ (BeaconResponseReceiver*)instance;
-(void)createServer;
@end
