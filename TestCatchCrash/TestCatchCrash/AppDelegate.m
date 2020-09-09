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
    
    // 注册系统异常捕获
    CatchCrashManager *ccrashManager = [CatchCrashManager shared];
    [ccrashManager registExceptionHandler];
    [ccrashManager registSignalExceptionHandler];
    ccrashManager.normalExceptionBlock = ^(NSString *error) {
        NSString *receive = error;
    };
    ccrashManager.signalExceptionBlock = ^(NSString *error) {
        NSString *receive = error;
    };
    
    // 这句一定放最后面，即所有操作都应该在此之前
    [self.window makeKeyAndVisible];
    
    return YES;
}


@end
