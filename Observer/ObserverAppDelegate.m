//
//  ObserverAppDelegate.m
//  Observer
//
//  Created by Regan Sarwas on 7/2/13.
//  Copyright (c) 2013 GIS Team. All rights reserved.
//

#import "ObserverAppDelegate.h"
#import "ObserverMapViewController.h"
#import "Settings.h"
#import "NSURL+unique.h"
#import "SurveyCollection.h"
#import "MapCollection.h"
#import "ProtocolCollection.h"

#define kAlertViewNewProtocol      1


@interface ObserverAppDelegate()

@property (nonatomic,strong) ObserverMapViewController *observerMapViewController;
@property (nonatomic,strong) SProtocol *protocolForSurveyCreation;

@end

@implementation ObserverAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    Map *savedMap = [[Map alloc] initWithLocalTileCache:[Settings manager].activeMapURL];
    if (savedMap.isValid) {
        self.observerMapViewController.map = savedMap;
    }
    Survey *savedSurvey = [[Survey alloc] initWithURL:[Settings manager].activeSurveyURL];
    if (savedSurvey.isValid) {
        self.observerMapViewController.survey = savedSurvey;
    }
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
    AKRLog(@"Entering Background.  Synchronizing User Defaults");
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    AKRLog(@"Terminating App.  Synchronizing User Defaults");
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // Called when this app is asked to open a resource (url) by a different app
    // The url is a local file resource (typically in Documents/Inbox), and can only
    //   be a file type that I have registered interest in (app configuration plist)
    // The user will expect a short delay to open the file
    AKRLog(@"%@ asked me to open %@", sourceApplication, url);

    //The url may contain a resource (e.g. a tile package) that we already have in the documents directory.
    //  This is unlikely, and while we could try to determine equality and return the existing resource if
    //  the new resource is a duplicate, there is a chance for false positives, which would frustrate the user.
    //  It is better to just do what the user asked - They can then determine equality and remove the duplicate.

    NSURL *documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *newUrl = [documentsDirectory URLByAppendingPathComponent:url.lastPathComponent];
    newUrl = [newUrl URLByUniquingPath];
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtURL:url toURL:newUrl error:&error];
    if (error) {
        [[[UIAlertView alloc] initWithTitle:url.lastPathComponent message:@"Unable to open file." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return NO;
    }

    if ([SurveyCollection collectsURL:newUrl]) {
        Survey *newSurvey = [[Survey alloc] initWithURL:newUrl];
        if ([newSurvey isValid]) {
            self.observerMapViewController.survey = newSurvey;
            return YES;
        } else {
            [[[UIAlertView alloc] initWithTitle:url.lastPathComponent message:@"Not a Valid Survey." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            return NO;
        }
    }
    if ([MapCollection collectsURL:url]) {
        Map *newMap = [[Map alloc] initWithLocalTileCache:newUrl];
        if ([newMap isValid]) {
            self.observerMapViewController.map = newMap;
            return YES;
        } else {
            [[[UIAlertView alloc] initWithTitle:url.lastPathComponent message:@"Not a Valid Map." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            return NO;
        }
    }
    if ([ProtocolCollection collectsURL:url]) {
        SProtocol *newProtocol = [[SProtocol alloc] initWithURL:newUrl];
        if ([newProtocol isValid]) {
            [self.observerMapViewController newProtocolAvailable:newProtocol];
            self.protocolForSurveyCreation = newProtocol;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Protocol" message:@"Do you want to open a new survey file with this protocol?" delegate:self cancelButtonTitle:@"Maybe Later" otherButtonTitles:@"Yes", nil];
            alertView.tag = kAlertViewNewProtocol;
            [alertView show];
            // handle response in UIAlertView delegate method
            return YES;
        } else {
            [[[UIAlertView alloc] initWithTitle:url.lastPathComponent message:@"Not a Valid Survey Protocol" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            return NO;
        }
    }
    AKRLog(@"Oh No!, Unhandled file type %@", url.lastPathComponent);
    return NO;
}

- (ObserverMapViewController *)observerMapViewController
{
    UIViewController *vc;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        vc = self.window.rootViewController;
    } else {
        UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
        vc = [nav.viewControllers  firstObject];;
    }
    if ([vc isKindOfClass:[ObserverMapViewController class]]) {
        return (ObserverMapViewController *)vc;
    }
    return nil;
}





#pragma mark - Delegate Methods: UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertViewNewProtocol: {
            if (buttonIndex == 1) {  //Yes to create/open a new survey
                Survey *newSurvey = [[Survey alloc] initWithProtocol:self.protocolForSurveyCreation];
                if ([newSurvey isValid]) {
                    self.observerMapViewController.survey = newSurvey;
                } else {
                    [[[UIAlertView alloc] initWithTitle:nil message:@"Unable to create new survey." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                }
            }
            break;
        }
        default:
            AKRLog(@"Oh No!, Alert View delegate called for an unknown alert view (tag = %d",alertView.tag);
            break;
    }
}

@end
