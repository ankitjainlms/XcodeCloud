//
//  OTBroadcastExtHelper.m
//  OpenTokLive
//
//  Created .
//  Copyright © 2019 TokBox, Inc. All rights reserved.
//group.com.on24.screenshareapp
//com.on24.screenshareapp.opentok

#import "OTBroadcastExtHelper.h"
#import "OTBroadcastExtAudioDevice.h"
#import <Foundation/Foundation.h>



@interface OTBroadcastExtHelper () <OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate,OTPublisherKitNetworkStatsDelegate>
{
   
   
}
@end

@implementation OTBroadcastExtHelper
{
    NSString *_partnerId;
    NSString *_sessionId;
    NSString *_token;
    NSString *_participantId;
    NSString *_idOn24;
    NSString *_controlServer;
    
    // OT vars
    OTSession* _session;
    OTPublisher* _publisher;
    OTSubscriber* _subscriber;
    OTBroadcastExtAudioDevice* _audioDevice;
    
    
    id <OTVideoCapture> _videoCapturer;
    NSUserDefaults *userDefaults;
    
    
    
}
@synthesize delegate;

-(instancetype)initWithPartnerId:(NSString *)partnerId
                       sessionId:(NSString *)sessionId
                        andToken:(NSString *)token
                   videoCapturer:(id <OTVideoCapture>)videoCapturer userDefault:(nonnull NSUserDefaults *)userDefault
{
    self = [super init];
    if (self) {
        _partnerId = partnerId;
        _sessionId = sessionId;
        _token = token;
        _videoCapturer = videoCapturer;
        userDefaults = userDefault;
         _participantId = [userDefaults objectForKey:@"participantId"];
        _idOn24 = [userDefaults objectForKey:@"idOn24"];
        _controlServer = [userDefaults objectForKey:@"controlServer"];
    }
    return self;
    
}





-(void)showMessage:(NSString *)message
{
    // for now we log to the console.
    NSLog(@"[ERROR] %@",message);
    
    NSString *msg = [NSString stringWithFormat:@"[ERROR] %@",message];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
}

-(void)connect
{
    
   
    
    if (_partnerId.length == 0 || _sessionId.length == 0 || _token.length == 0)
    {
        [self showMessage:@"[ERROR] Invalid OpenTok session info."];
        [self.delegate finishedStream:@"Invalid session info"];
        return;
    }
    
    if(_session.sessionConnectionStatus == OTSessionConnectionStatusConnected)
    {
        [self showMessage:@"[ERROR] Session already connected!"];
        return;
    }
    
    if(!_audioDevice)
    {
        _audioDevice =
        [[OTBroadcastExtAudioDevice alloc] init];
        [OTAudioDeviceManager setAudioDevice:_audioDevice];
    }
    
    _session = [[OTSession alloc] initWithApiKey:_partnerId
                                       sessionId:_sessionId
                                        delegate:self];
    
    OTError *error = nil;
    [_session connectWithToken:_token error:&error];
    if (error)
    {
        [self showMessage:[error localizedDescription]];
    }
    
       
   
    
}



-(void)disconnect
{
    
    [self sendStopSignal];
    
    NSString *msg = [NSString stringWithFormat:@"Users initiated screenshare stop"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    
    [self doUnPublish];
    
    OTError *error = nil;
    [_session disconnect:&error];
    if (error)
    {
        [self showMessage:[error localizedDescription]];
    }
    else
    {
        [self cleanupPublisher];
        NSString *msg = [NSString stringWithFormat:@"Session Disconnected"];
        [userDefaults setObject:msg forKey:@"Broadcast_status"];
        [userDefaults synchronize];
    }
}

- (void)doPublish
{
    OTPublisherSettings *settings = [[OTPublisherSettings alloc] init];
    settings.videoCapture = _videoCapturer;
    settings.name = [[UIDevice currentDevice] name];
    
    // settings.scalableScreenshare = true;
    
    _publisher = [[OTPublisher alloc] initWithDelegate:self
                                              settings:settings];
    
    _publisher.publishAudio = false;
    _publisher.videoType = OTPublisherKitVideoTypeScreen;
    
    _publisher.networkStatsDelegate = self;
    
    
    
    OTError *error = nil;
    [_session publish:_publisher error:&error];
    if (error)
    {
        [self showMessage:[error localizedDescription]];
    }
    else
    {
        NSString *msg = [NSString stringWithFormat:@"Screenshare started"];
        [userDefaults setObject:msg forKey:@"Broadcast_status"];
        [userDefaults synchronize];
        
        [self sendStartSignal];
    }
}
-(void)doUnPublish
{
    OTError *error = nil;
    [_session unpublish:_publisher error:&error];
    if (error)
    {
        [self showMessage:[error localizedDescription]];
    }
    else
    {
        NSString *msg = [NSString stringWithFormat:@"Screenshare stopped"];
        [userDefaults setObject:msg forKey:@"Broadcast_status"];
        [userDefaults synchronize];
    }
    
}

- (void)doSubscribe:(OTStream*)stream
{
    OTSubscriber *subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
    subscriber.subscribeToVideo = NO; // Nothing to show on the broadcast extension.
    
    OTError *error = nil;
    [_session subscribe:subscriber error:&error];
    if (error)
    {
        [self showMessage:[error localizedDescription]];
    }
}

- (void)cleanupPublisher
{
    _publisher = nil;
}

- (void)cleanupSubscriber
{
    _subscriber = nil;
}

- (void)cleanupSession
{
    _session = nil;
}

- (BOOL)isConnected
{
    return _session.sessionConnectionStatus == OTSessionConnectionStatusConnected;
}
-(void)writeAudioSamples:(CMSampleBufferRef)sampleBuffer
{
    [_audioDevice writeAudioSamples:sampleBuffer];
}


- (void)registerAppWithSessionId:(NSString *)sessionId
                         idOn24:(NSString *)idOn24
                appConnectionId:(NSString *)appConnectionId {
   
                    
    // Construct the URL string using stringWithFormat
    NSString *urlString = [NSString stringWithFormat:@"%@/screenshare/register_app", _controlServer];

    // Create the URL object
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Create the request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    // Create the body dictionary
    NSDictionary *bodyDict = @{
        @"sessionIdVonage": sessionId,
        @"idOn24Vonage": idOn24,
        @"connectionIdVonage": appConnectionId
    };
    
    // Convert the body dictionary to JSON
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:&error];
                    
    NSLog(@"jsonDict: %@", bodyDict);
    
    if (!jsonData) {
        NSLog(@"Error serializing JSON: %@", error);
        return;
    }
    
    // Set the request body
    request.HTTPBody = jsonData;
    
    // Set the content type
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // Create a data task
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error making request: %@", error);
            return;
        }
        
        // Handle the response
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 201) {
            NSLog(@"Successfully registered the app.");
        } else {
            NSLog(@"Failed to register the app. Status code: %ld", (long)httpResponse.statusCode);
        }
    }];
    
    // Start the data task
    [dataTask resume];
}

#pragma mark -
#pragma mark === registerAppOnServer ===
- (void)registerAppOnServer {
    [self registerAppWithSessionId:_sessionId
                           idOn24:_idOn24
                  appConnectionId:_session.connection.connectionId];
}


#pragma mark -
#pragma mark === OTSession delegate callbacks ===

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    NSString *msg = [NSString stringWithFormat:@"Session Connected "];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    [self doPublish];
    
    [self registerAppOnServer];
    
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSLog(@"sessionDidDisconnect (%@)", session.sessionId);
    NSString *msg = [NSString stringWithFormat:@"Session Disconnected"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    
    [self cleanupPublisher];
    [self cleanupSubscriber];
    [self cleanupSession];
    
    
}

- (void)session:(OTSession*)mySession streamCreated:(OTStream *)stream
{
    NSLog(@"session streamCreated (Id: %@, Name: %@, ConnectionId: %@)", stream.streamId, stream.name, stream.connection.connectionId);
    
    NSString *msg = [NSString stringWithFormat:@"Session streamCreated"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
}


- (void)session:(OTSession*)session streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (Id: %@, Name: %@, ConnectionId: %@)", stream.streamId, stream.name, stream.connection.connectionId);
    
    if([_subscriber.stream.streamId isEqualToString:stream.streamId])
        [self cleanupSubscriber];
    
    NSString *msg = [NSString stringWithFormat:@"Session streamDestroyed"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
}

- (void)session:(OTSession *)session connectionCreated:(OTConnection *)connection
{
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
    
    NSString *msg = [NSString stringWithFormat:@"Subscriber Connected"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
}

- (void)session:(OTSession *)session connectionDestroyed:(OTConnection *)connection
{
    NSLog(@"session connectionDestroyed (%@)", connection.connectionId);
    if([_subscriber.stream.connection.connectionId isEqualToString:connection.connectionId])
        [self cleanupSubscriber];
    
    NSString *msg = [NSString stringWithFormat:@"Subscriber Disconnected"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    
    
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
    
    NSString *msg = [NSString stringWithFormat:@"didFailWithError: (%@)", error.localizedDescription];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    [self.delegate finishedStream:error.localizedDescription];
}

- (void)   session:(OTSession*)session
receivedSignalType:(NSString*)type
    fromConnection:(OTConnection*)connection
        withString:(NSString*)string
{
    NSLog(@"Received receivedSignalType %@  fromConnection %@ withString %@",type,connection.data,string);
    
    Boolean fromSelf = NO;
    if ([connection.connectionId isEqualToString:session.connection.connectionId]) {
        fromSelf = YES;
        NSLog(@"self signal");
    }
    else if([type isEqualToString:@"cfs"])
    {
        NSString *jsonString = string;
        
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        
        if (!jsonDict) {
            NSLog(@"Error parsing JSON string: %@", error);
            
        }
        
        NSLog(@"JSON dictionary: %@", jsonDict);
        
        NSDictionary *dicData = jsonDict[@"data"];
        NSString *message = jsonDict[@"message"];
       
        
        if([message isEqualToString:@"call.main.room.participant.kick_out"] )
        {
            [self.delegate finishedStream:@"Meeting end"];
        }
        else if(dicData != nil)
        {
            NSNumber *publishNumber = dicData[@"publish"];
            NSString *action = dicData[@"action"];
            NSString *user_id_on24 = dicData[@"user_id_on24"];
            NSString *reason = dicData[@"reason"];
            
            if([action isEqualToString:@"stop.screenshare"] || [message isEqualToString:@"call.main.live_captioning"])
            {
                return;
            }
            BOOL publisher;
            if (publishNumber != nil) {
                publisher = [publishNumber boolValue];
                NSLog(@"Key 'publish' is here");
                if (!publisher)
                {
                    if([action isEqualToString:@"interrupt.screenshare"] && [_idOn24 isEqualToString:user_id_on24])
                    {
                        [self.delegate finishedStream:@"Screen share has been stopped."];
                    }
                    else if([message isEqualToString:@"call.presentation.room.participant.video.interrupt"] && [reason isEqualToString:@"user_disconnected"])
                    {
                        [self.delegate finishedStream:@"Screen share has been stopped."];
                    }
                    else if([message isEqualToString:@"call.presentation.room.participant.video.publish"] )
                    {
                        
                        [self.delegate finishedStream:@"Another device has started screen share."];
                    }
                }
            } else {
                // Key 'publish' is not present in the dictionary
                NSLog(@"Key 'publish' is not present in the dictionary");
            }
        }
    }
}
#pragma mark -
- (void) sendStartSignal
{
    NSLog(@"_participantId %@",_participantId);
    
    NSDictionary *data = @{
        @"channel0": @"cfs",
        @"channel1": @"all",
        @"data": @{
            @"exclude": @[],
            @"publish": @NO,
            @"type":    @"iApp",
            @"action":  @"start.screenshare"
        },
        @"direction": @"broadcast",
        @"id": _participantId,
        @"message": @"call.presentation.room.participant.video.publish",
        @"path": @[
            @{
                @"type0": @"cfs.call.presentation",
                @"type1": @""//f4148aa8-aa9b-4dae-820d-0a1a9c30a3e7
            }
        ]
    };
    
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&err];
    
    if (!jsonData) {
        NSLog(@"Error creating JSON data: %@", err);
        
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"JSON string: %@", jsonString);
    
    
    
    
    OTError* error = nil;
    [_session signalWithType:@"cfs" string:jsonString connection:nil retryAfterReconnect:NO error:&error];
    
    if (error) {
        NSLog(@"Signal error: %@", error);
    } else {
        
    }
    
}
- (void) sendStopSignal
{
    
    NSDictionary *data = @{
        @"channel0": @"cfs",
        @"channel1": @"all",
        @"data": @{
            @"exclude": @[],
            @"publish": @NO,
            @"type":    @"iApp",
            @"action":  @"stop.screenshare"
        },
        @"direction": @"broadcast",
        @"id": _participantId,
        @"message": @"call.presentation.room.participant.video.publish",
        @"path": @[
            @{
                @"type0": @"cfs.call.presentation",
                @"type1": @""//f4148aa8-aa9b-4dae-820d-0a1a9c30a3e7
            }
        ]
    };
    
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&err];
    
    if (!jsonData) {
        NSLog(@"Error creating JSON data: %@", err);
        
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"JSON string: %@", jsonString);
    
    
    
    
    OTError* error = nil;
    [_session signalWithType:@"cfs" string:jsonString connection:nil retryAfterReconnect:NO error:&error];
    
    if (error) {
        NSLog(@"Signal error: %@", error);
    } else {
        
    }
    
}



#pragma mark -
#pragma mark === OTSubscriber delegate callbacks ===

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    NSLog(@"subscriberDidConnectToStream: %@ (connectionId: %@, video type: %d)", subscriber.stream.name, subscriber.stream.connection.connectionId, subscriber.stream.videoType);
}

- (void)subscriber:(OTSubscriberKit*)subscriber didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@", subscriber.stream.streamId, error);
}

- (void)subscriberVideoDisabled:(OTSubscriberKit*)subscriber reason:(OTSubscriberVideoEventReason)reason
{
    NSLog(@"subscriberVideoDisabled %@, reason : %d", subscriber, reason);
}

- (void)subscriberVideoEnabled:(OTSubscriberKit*)subscriber reason:(OTSubscriberVideoEventReason)reason
{
    NSLog(@"subscriberVideoEnabled %@, reason : %d", subscriber, reason);
}

#pragma mark -
#pragma mark === OTPublisher delegate callbacks ===

- (void)publisher:(OTPublisherKit *)publisher streamCreated:(OTStream *)stream
{
    // This is safe since ReplayKit doesn't send any audio samples, if mic is disabled.
    _publisher.publishAudio = false;
    NSLog(@"publisher streamCreated: %@", stream);
    // NSLog(@"publisher stream connection id: %@", stream.connection.connectionId);
    
    NSString *msg = [NSString stringWithFormat:@"Screenshare in process"];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
   
}

- (void)publisher:(OTPublisherKit*)publisher streamDestroyed:(OTStream *)stream
{
    [self cleanupPublisher];
    
   
}

- (void)publisher:(OTPublisherKit*)publisher didFailWithError:(OTError*) error
{
    NSString *msg = [NSString stringWithFormat:@"publisher didFailWithError: (%@)", error.localizedDescription];
    [userDefaults setObject:msg forKey:@"Broadcast_status"];
    [userDefaults synchronize];
    
    
    NSLog(@"publisher didFailWithError %@", error);
    [self cleanupPublisher];
}


#pragma mark -
#pragma mark === Publisher NetworkStats Delegate callbacks ===

- (void)publisher:(nonnull OTPublisherKit*)publisher
videoNetworkStatsUpdated:(nonnull NSArray<OTPublisherKitVideoNetworkStats*>*)stats;
{
    // NSLog(@"stats connectionId %@ subscriberId %@ \n %lld \n %lld  \n %lld",stats.firstObject.connectionId,stats.firstObject.subscriberId,stats.firstObject.videoPacketsSent,stats.firstObject.videoPacketsLost,stats.firstObject.videoBytesSent);
}

@end
