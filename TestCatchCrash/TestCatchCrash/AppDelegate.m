//
//  AppDelegate.m
//  TestCatchCrash
//
//  Created by bava on 2020/9/9.
//  Copyright © 2020 zjn. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "CatchCrashManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    ViewController *testVc = [[ViewController alloc] init];
    self.window.rootViewController = testVc;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // 注册系统异常捕获
    [[CatchCrashManager shared] registExceptionHandler];
    [[CatchCrashManager shared] registSignalExceptionHandler];
    
    return YES;
}


@end
