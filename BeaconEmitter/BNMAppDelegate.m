//
//  BNMAppDelegate.m
//  BeaconEmitter
//
//  Created by Laurent Gaches on 03/11/13.
//  Copyright (c) 2013 Binimo. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//

#import "BNMAppDelegate.h"
#import <IOBluetooth/IOBluetooth.h>

#import "BNMBeaconRegion.h"
#import "BeaconResponseReceiver.h"

@interface BNMAppDelegate () <CBPeripheralManagerDelegate>

@property (weak) IBOutlet NSTextField *uuid;
@property (weak) IBOutlet NSTextField *identifier;
@property (weak) IBOutlet NSTextField *major;
@property (weak) IBOutlet NSTextField *minor;
@property (weak) IBOutlet NSTextField *power;
@property (weak) IBOutlet NSButton *startBeaconButton;
@property (weak) IBOutlet NSTextField *bluetoothStatusLbl;
@property (weak) IBOutlet NSScrollView *namesScrollView;
@property (strong) IBOutlet NSTextView* namesFromServer;

@property (strong, nonatomic) CBPeripheralManager *manager;
@end

@implementation BNMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(helloReceived:) name:kHelloReceived object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(helloWithNameReceived:) name:kHelloWithName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(byeWithNameReceived:) name:kByeWithName object:nil];
    
    [[BeaconResponseReceiver instance] createServer];
}

-(void)helloReceived:(NSNotification*)notif{
    [self.namesFromServer.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"Hello received"]];
     
}

-(void)helloWithNameReceived:(NSNotification*) notif{
    [self.namesFromServer.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ came to range\n",notif.object]]];
    //[self.namesScrollView scrollToEndOfDocument:self];
}

-(void)byeWithNameReceived:(NSNotification*) notif{
    [self.namesFromServer.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ went out from range\n",notif.object]]];
    //[self.namesScrollView scrollToEndOfDocument:self];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    switch (peripheral.state) {
        case CBPeripheralManagerStateUnknown:
            [self.bluetoothStatusLbl setStringValue:@"The current state of the peripheral manager is unknown; an update is imminent."];
            [self.startBeaconButton setEnabled:NO];
            break;
        case CBPeripheralManagerStateUnauthorized:
            [self.bluetoothStatusLbl setStringValue:@"The app is not authorized to use the Bluetooth low energy peripheral/server role."];
            [self.startBeaconButton setEnabled:NO];
            break;
        case CBPeripheralManagerStateResetting:
            [self.bluetoothStatusLbl setStringValue:@"The connection with the system service was momentarily lost; an update is imminent."];
            [self.startBeaconButton setEnabled:NO];
            break;
        case CBPeripheralManagerStatePoweredOff:
            [self.bluetoothStatusLbl setStringValue:@"Bluetooth is currently powered off"];
            [self.startBeaconButton setEnabled:NO];
            break;
        case CBPeripheralManagerStateUnsupported:
            [self.bluetoothStatusLbl setStringValue:@"The platform doesn't support the Bluetooth low energy peripheral/server role."];
            [self.startBeaconButton setEnabled:NO];
            break;
        case CBPeripheralManagerStatePoweredOn:
            [self.bluetoothStatusLbl setStringValue:@"Bluetooth is currently powered on and is available to use."];
            [self.startBeaconButton setEnabled:YES];
            break;
    }
    
  
}

#pragma mark - Actions

- (IBAction)changeBeaconState:(NSButton *)sender {
    
    if ([self.manager isAdvertising]) {
        [self.manager stopAdvertising];
        [sender setTitle:@"Turn iBeacon on"];
    } else {
        NSString* uuidValue = self.uuid.stringValue;
        if ([uuidValue length] == 0) {
            uuidValue = [[self.uuid cell] placeholderString];
        }
        NSUUID *proximityUUID  = [[NSUUID alloc] initWithUUIDString:uuidValue];
        if (proximityUUID) {
            BNMBeaconRegion *beacon = [[BNMBeaconRegion alloc] initWithProximityUUID:proximityUUID major:self.major.intValue minor:self.minor.intValue  identifier:self.identifier.stringValue];
            NSNumber *measuredPower = nil;
            if (self.power.intValue != 0) {
                measuredPower = [NSNumber numberWithInt:self.power.intValue];
            }
            
            [self.manager startAdvertising:[beacon peripheralDataWithMeasuredPower:measuredPower]];
            [sender setTitle:@"Turn iBeacon off"];
        } else {
            NSAlert *alert =[NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The UUID format is invalid"];
            [alert runModal];
        }
    }
}

- (IBAction)handleClickRefreshButton:(id)sender {
    if ([self.manager isAdvertising]) {
        [self.manager stopAdvertising];
        [self.startBeaconButton setTitle:@"Turn iBeacon on"];
    }
    
    NSUUID *proximityUUID = [NSUUID UUID];
    [self.uuid setStringValue:[proximityUUID UUIDString]];
}


- (IBAction)handleClickCopyButton:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard writeObjects:@[self.uuid.stringValue]];
}
@end
