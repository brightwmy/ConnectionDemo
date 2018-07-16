//
//  ViewController.m
//  ConnectionDemo
//
//  Created by wumingyun on 2018/6/10.
//  Copyright © 2018 OMI. All rights reserved.
//

#import "AsyncSocketViewController.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface AsyncSocketViewController () <GCDAsyncSocketDelegate>

@property (nonatomic) GCDAsyncSocket *socket;
@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end

@implementation AsyncSocketViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
}

- (IBAction)reconnect:(id)sender {
    
}

@end
