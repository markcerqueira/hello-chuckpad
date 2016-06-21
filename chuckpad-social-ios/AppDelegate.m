//
//  AppDelegate.m
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/16/16.
//
//

#import "AppDelegate.h"
#import "PatchListViewController.h"
#import "UserViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (UIImage *)imagePreparedForTabBarItem:(NSString *)assetName {
    UIImage *tabBarImage = [UIImage imageNamed:assetName];
    tabBarImage = [tabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    return tabBarImage;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    PatchListViewController *patchListViewController = [[PatchListViewController alloc] initWithNibName:@"PatchListViewController" bundle:nil];
    patchListViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Patches" image:[self imagePreparedForTabBarItem:@"pineapple.png"] tag:1];

    UserViewController *userViewController = [[UserViewController alloc] initWithNibName:@"UserViewController" bundle:nil];
    userViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"User" image:[self imagePreparedForTabBarItem:@"face.png"] tag:1];

    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:patchListViewController, userViewController, nil];

    self.window = [UIWindow new];

    [self.window makeKeyAndVisible];

    self.window.frame = [[UIScreen mainScreen] bounds];

    self.window.rootViewController = self.tabBarController;

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
