//
//  ViewController.m
//
//
//  Copyright (c) LMS, Inc. All rights reserved.
//

#import "ViewController.h"
#import <OpenTok/OpenTok.h>
#import "AppDelegate.h"


// Replace with your group key
static NSString* const kGroupName = @"group.RSJL44J28C.com.Test.Lms";
// Replace with your Extension ID
static NSString* const kPreferredExtension = @"com.Test.Lms.BroadcastUpload";

@interface ViewController ()

@end




@implementation ViewController
//#if !(TARGET_OS_SIMULATOR)
API_AVAILABLE(ios(12.0))
RPSystemBroadcastPickerView *_broadcastPickerView;
NSUserDefaults *userDefaults;
NSTimer *timer;
UIImageView *phoneIcon;
UILabel *msgLbl;

UIDeviceOrientation newOrientation;



//#endif



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleURLReceived:)
                                                 name:@"ScreenShareUrlReceived" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppTerminated:)
                                                 name:@"AppTerminated" object:nil];
    [self setupView];
    
}


-(void)viewWillAppear:(BOOL)animated
{
    
    if (@available(iOS 11.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(capturedChange)
                                                     name:UIScreenCapturedDidChangeNotification object:nil];
    }
    if([UIScreen mainScreen].isCaptured)
    {
        self.ViewScreenShare.hidden = false;
        self.lblNoUrlMsg.hidden = true;
        
        
    }
}



#pragma mark setupView

- (void)setupView {
    userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kGroupName];
    [self setupScreenShareMessage];
    [self setupBroadcastTimer];
    [self configureBroadcastPickerView];
    [self processVonageInfo];
}
    
    
- (void)setupScreenShareMessage {
    if(![UIScreen mainScreen].isCaptured)
    {
        NSString *msg = [NSString stringWithFormat:@"Waiting for user to start screen share on ON24."];
        [userDefaults setObject:msg forKey:@"Broadcast_status"];
        [userDefaults synchronize];
        self.lblon24lbl.text = @"Waiting for user to start screen share on ON24.";
        [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:20]];
    }
}

- (void)setupBroadcastTimer {
    if ([UIScreen mainScreen].isCaptured) {
        timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                 target: self
                                               selector: @selector(broadcastStatus:)
                                               userInfo: nil
                                                repeats: YES];
    }
}
    
- (void)configureBroadcastPickerView {
    if (@available(iOS 12.0, *)) {
        if([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            _broadcastPickerView =  [[RPSystemBroadcastPickerView alloc] init];
        }else if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            _broadcastPickerView =  [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
        }
        
        self.viewCenter.preferredExtension =kPreferredExtension;
        self.viewCenter.accessibilityIdentifier = @"RPSystemBroadcastPickerView";
        //_broadcastPickerView.center = self.view.center;
        self.viewCenter.showsMicrophoneButton = false;
        [self.viewCenter.layer setCornerRadius:10];
        [self.viewCenter.layer setMasksToBounds:YES];
        
        for (UIButton* button in self.viewCenter.subviews) {
            if([button isKindOfClass:[UIButton class]]){
                UIButton *newbtn = (UIButton *)button;
                [UIScreen mainScreen].isCaptured ? [newbtn setImage:[UIImage imageNamed:@"Icon"] forState:UIControlStateNormal] :[newbtn setImage:nil forState:UIControlStateNormal];
                [newbtn setTitle:[UIScreen mainScreen].isCaptured ? @" Stop Screenshare": @"Start Screenshare" forState:UIControlStateNormal];
                [newbtn.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Medium" size:8]];
                [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
                [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
                [newbtn.layer setMasksToBounds:YES];
            }
        }
    }
}
- (void)processVonageInfo {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *dic = appDelegate.dicVonageInfo;
    
    if ([self isValidDic:dic]) {
        NSString *strApi = dic[@"apiVonage"];
        NSString *strSessionId = dic[@"sessionIdVonage"];
        NSString *strToken = dic[@"tokenVonage"];
        NSString *strParticipantId = dic[@"participantIdVonage"];
        NSString *stridOn24 = dic[@"idOn24Vonage"];
        NSString *strControlServer = dic[@"controlServerVonage"];
        
        if ([self isValidApiKey:strApi] && [self isValidSessionId:strSessionId] && [self isValidToken:strToken]) {
            [userDefaults setObject:strApi forKey:@"apiKey"];
            [userDefaults setObject:strSessionId forKey:@"sessionId"];
            [userDefaults setObject:strToken forKey:@"token"];
            [userDefaults setObject:strParticipantId forKey:@"participantId"];
            [userDefaults setObject:stridOn24 forKey:@"idOn24"];
            [userDefaults setObject:strControlServer forKey:@"controlServer"];
            
            [self handleBroadcasting];
        }
    } else {
        self.ViewScreenShare.hidden = YES;
        self.lblNoUrlMsg.hidden = NO;
        if([timer isValid]){
            [timer invalidate];
            timer = nil;
        }
    }


       // testing for UI :-show button of braodcast
//        NSDictionary *environment = [[NSProcessInfo processInfo] environment];
//        NSString *uiTestRunning = environment[@"UITEST_RUNNING"];
//        
//        if ([uiTestRunning isEqualToString:@"YES"]) {
//            NSLog(@"Running UI tests...");
//            [self.ViewScreenShare setHidden:false];
//        }
    
}

- (void)handleBroadcasting {
    SEL buttonPressed = NSSelectorFromString(@"buttonPressed:");
    if([self.viewCenter respondsToSelector:buttonPressed]){
        
        [self.viewCenter performSelector:buttonPressed withObject:nil];
        
        if([UIScreen mainScreen].isCaptured){
            [self.ViewScreenShare setHidden:false];
        }
        else{
            [self.ViewScreenShare setHidden:true];
        }
    }
}



#pragma mark Validation methods
-(bool)isValidDic:(NSMutableDictionary*)dic
{
    if(dic != nil){
        
        if (dic[@"apiVonage"] != nil &&
            dic[@"sessionIdVonage"] != nil &&
            dic[@"tokenVonage"] != nil && dic[@"participantIdVonage"] != nil && dic[@"idOn24Vonage"] != nil) {
            
            return true;
        }
    }
    return false;
}
-(bool)isValidApiKey:(NSString*)api
{
    
    if([api length] == 0 && [api isEqualToString:@""])
    {
        return false;
    }
    return  true;
    
}
-(bool)isValidSessionId:(NSString*)sessionId
{
    if([sessionId length] == 0 && [sessionId isEqualToString:@""])
    {
        return false;
    }
    
    return  true;
}
-(bool)isValidToken:(NSString*)token
{
    if([self getTokenLength:token] == 0 && [token isEqualToString:@""])
    {
        return false;
    }
    return true;
}

-(NSString*)getVonageToken
{
    AppDelegate *appDelegate =  (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *dic = appDelegate.dicVonageInfo;
    return [dic valueForKey:@"tokenVonage"];
}
-(long)getTokenLength:(NSString*)token
{
    return  token.length;
}

- (void)handleURLReceived:(NSNotification *)notification {
    [self setupView];
}
- (void)handleAppTerminated:(NSNotification *)notification {
    // Invalidate the timer if it's valid
    if ([timer isValid]) {
        [timer invalidate];
        timer = nil;
    }
    
    // Remove any observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Clean up userDefaults if necessary
    [userDefaults removeObjectForKey:@"apiKey"];
    [userDefaults removeObjectForKey:@"sessionId"];
    [userDefaults removeObjectForKey:@"token"];
    [userDefaults removeObjectForKey:@"participantId"];
    [userDefaults removeObjectForKey:@"idOn24"];
    
    userDefaults = nil;
    
    // Set other properties to nil to ensure proper memory management
    _lblon24lbl = nil;
    _lblNoUrlMsg = nil;
    _ViewScreenShare = nil;
    _broadcastPickerView = nil;
}

#pragma mark Notification handler UIScreenCapturedDidChangeNotification
- (void)capturedChange {
    if (@available(iOS 11.0, *)) {
        NSLog(@"Recording Status: %s", [UIScreen mainScreen].isCaptured ? "true" : "false");
        
        
        for (UIButton* button in self.viewCenter.subviews){
            if([button isKindOfClass:[UIButton class]]){
                UIButton *newbtn = (UIButton *)button;
                [UIScreen mainScreen].isCaptured ? [newbtn setImage:[UIImage imageNamed:@"Icon"] forState:UIControlStateNormal] :[newbtn setImage:nil forState:UIControlStateNormal];
                [newbtn setTitle:[UIScreen mainScreen].isCaptured ? @" Stop Screenshare": @"Start Screenshare" forState:UIControlStateNormal];
                [newbtn.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Medium" size:[self isiPad] ?14:13]];
                [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
               [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
               [newbtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
                [newbtn.layer setMasksToBounds:YES];
            }
        }
        
        
        if([UIScreen mainScreen].isCaptured)
        {
            self.ViewScreenShare.hidden = false;
            self.lblNoUrlMsg.hidden = true;
            
            timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                     target: self
                                                   selector: @selector(broadcastStatus:)
                                                   userInfo: nil
                                                    repeats: YES];
            
        }
        else
        {
            self.ViewScreenShare.hidden = true;
            self.lblNoUrlMsg.hidden = false;
            if([timer isValid]){
                [timer invalidate];
                timer = nil;
                [self performSelector:@selector(broadcastStatus:) withObject:nil afterDelay:1.0];
            }
        }
        
    }
}



- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate {
    return UIUserInterfaceIdiomPhone != [[UIDevice currentDevice] userInterfaceIdiom];
}

-(BOOL)isiPad
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}
#pragma mark broadcastStatus
-(void)broadcastStatus:(NSTimer *)timer{
    
    NSString *strMsg = [userDefaults valueForKey:@"Broadcast_status"];
    
    // NSLog(@"status %@",strMsg);
    if([strMsg isEqualToString:@"User started screenshare – connecting to vonage"])
    {
        self.lblStatus.text = @"";
        self.lblon24lbl.text = @"ON24 is sharing and recording your screen.";
        [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:20]];
        
    }
    
    if(![self.lblStatus.text containsString:strMsg])//||[strMsg isEqualToString:@"Subscriber Connected"]||[strMsg isEqualToString:@"Subscriber Disconnected"])
    {
        NSString *strStatus = [NSString stringWithFormat:@"%@ \n %@", self.lblStatus.text, strMsg];
        self.lblStatus.text = strStatus;
        self.lblon24lbl.text = @"ON24 is sharing and recording your screen.";
        [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:20]];
        
        
    }
    
    if([strMsg isEqualToString:@"Subscriber Disconnected"] || [strMsg isEqualToString:@"Session Disconnected"] )
    {
        // self.lblon24lbl.text = @"Waiting for user to start screen share on ON24.";
        // [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:16]];
        
    }
    if([strMsg isEqualToString:@"Session Disconnected"] )
    {
        self.lblon24lbl.text = @"Waiting for user to start screen share on ON24.";
        [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:20]];
    }
    if([strMsg isEqualToString:@"Subscriber Connected"])
    {
        //  self.lblon24lbl.text = @"ON24 is sharing and recording your screen";
        // [self.lblon24lbl setFont:[UIFont fontWithName:@"Raleway-Bold" size:[self isiPad] ?20:16]];
        
    }
    
    
    
}
    
    
    


@end
