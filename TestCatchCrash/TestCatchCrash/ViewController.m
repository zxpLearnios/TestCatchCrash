//
//  ViewController.m
//  TestCatchCrash
//
//  Created by bava on 2020/9/9.
//  Copyright © 2020 zjn. All rights reserved.
//  测试崩溃、闪退、错误

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];

    // 1.
    NSString * test = @"11";
    NSArray *aaa =[NSArray arrayWithObject:test];
    //    [aaa objectAtIndex:2];

    // 2.
    [self testCrash];
}


-(void)testCrash {
    NSString *str;
    NSDictionary *dic = @{@"fkey": str};
}

@end
