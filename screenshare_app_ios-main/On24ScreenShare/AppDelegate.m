//
//  AppDelegate.m
//  
//
//  Copyright (c)  LMS, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    
    
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AppTerminated" object:nil];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options API_AVAILABLE(ios(9.0))
{
    NSLog(@"url recieved: %@", url);
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
       if (!components || ![components.scheme isEqualToString:@"on24screenshare"]) {
           return NO;
       }
    
    self.dicVonageInfo = [self prepareDictionaryWithQueryPram:url];
    NSLog(@"query dict: %@", self.dicVonageInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ScreenShareUrlReceived" object:nil];
    
    
    return  YES;
    
}

- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
    restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *incomingURL = userActivity.webpageURL;
        if (incomingURL) {
            NSString *path = incomingURL.path;
            NSLog(@"Path: %@", path);  // Get the path, e.g., "/screenshare/..."
            
            // Extract query parameters
            self.dicVonageInfo = [self prepareDictionaryWithQueryPram:incomingURL];
            NSLog(@"query dict: %@", self.dicVonageInfo);
            
            // Notify observers of the URL reception
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ScreenShareUrlReceived" object:nil];
        }
    }
    
    return YES;
}


//- (NSMutableDictionary *)prepareDictionaryWithQueryPram:(NSString *)query {
//    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6] ;
//    NSArray *pairs = [query componentsSeparatedByString:@"&"];
//    
//    for (NSString *pair in pairs) {
//        NSArray *elements = [pair componentsSeparatedByString:@"Vonage="];
//        if(elements.count == 2){
//            NSString *key = [[elements objectAtIndex:0] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
//            NSString *val = [[elements objectAtIndex:1] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
//            [dict setObject:val forKey:key];
//        }
//    }
//        
//    return dict;
//}

- (NSMutableDictionary *)prepareDictionaryWithQueryPram:(NSURL *)url {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            if (!components || !components.queryItems) {
                return nil;
            }
    
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            for (NSURLQueryItem *queryItem in components.queryItems) {
                info[queryItem.name] = queryItem.value;
            }
           
    return info;
}

@end
