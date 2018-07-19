//
//  AppDelegate.h
//  ConnectionDemo
//
//  Created by wumingyun on 2018/6/10.
//  Copyright © 2018 OMI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) NSManagedObjectContext *mainContext;
@property (nonatomic) NSManagedObjectContext *backgroundContext;

@end

