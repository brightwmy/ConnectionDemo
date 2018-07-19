//
//  AppDelegate.m
//  ConnectionDemo
//
//  Created by wumingyun on 2018/6/10.
//  Copyright © 2018 OMI. All rights reserved.
//

#import "AppDelegate.h"

#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@import CocoaLumberjack;

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = 0;

#define  WWW_PORT 0  // 0 => automatic
#define  WWW_HOST @"www.amazon.com"
#define CERT_HOST @"www.amazon.com"

#define USE_SECURE_CONNECTION    1
#define USE_CFSTREAM_FOR_TLS     0 // Use old-school CFStream style technique
#define MANUALLY_EVALUATE_TRUST  1

#define READ_HEADER_LINE_BY_LINE 0


NSString * const kDeviceID = @"kDeviceID";

@interface AppDelegate () <GCDAsyncSocketDelegate>

@end

@implementation AppDelegate {
    GCDAsyncSocket *asyncSocket;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
//    [self startSocket];
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];

    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:appName withExtension:@"momd"]];
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSURL *sqliteURL = [[[[NSFileManager defaultManager]
                          URLsForDirectory:NSDocumentDirectory
                          inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", appName]];
    
    [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:sqliteURL options:nil error:nil];
    
    self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.mainContext.persistentStoreCoordinator = coordinator;
    self.backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.backgroundContext.persistentStoreCoordinator = coordinator;
    
    if (![[NSUserDefaults standardUserDefaults] stringForKey:kDeviceID]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSUUID UUID].UUIDString forKey:kDeviceID];
    }
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
}

- (void)startSocket
{
    // Create our GCDAsyncSocket instance.
    //
    // Notice that we give it the normal delegate AND a delegate queue.
    // The socket will do all of its operations in a background queue,
    // and you can tell it which thread/queue to invoke your delegate on.
    // In this case, we're just saying invoke us on the main thread.
    // But you can see how trivial it would be to create your own queue,
    // and parallelize your networking processing code by having your
    // delegate methods invoked and run on background queues.
    
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // Now we tell the ASYNCHRONOUS socket to connect.
    //
    // Recall that GCDAsyncSocket is ... asynchronous.
    // This means when you tell the socket to connect, it will do so ... asynchronously.
    // After all, do you want your main thread to block on a slow network connection?
    //
    // So what's with the BOOL return value, and error pointer?
    // These are for early detection of obvious problems, such as:
    //
    // - The socket is already connected.
    // - You passed in an invalid parameter.
    // - The socket isn't configured properly.
    //
    // The error message might be something like "Attempting to connect without a delegate. Set a delegate first."
    //
    // When the asynchronous sockets connects, it will invoke the socket:didConnectToHost:port: delegate method.
    
    NSError *error = nil;
    
    uint16_t port = WWW_PORT;
    if (port == 0)
    {
#if USE_SECURE_CONNECTION
        port = 443; // HTTPS
#else
        port = 80;  // HTTP
#endif
    }
    
    if (![asyncSocket connectToHost:WWW_HOST onPort:port error:&error])
    {
        DDLogError(@"Unable to connect to due to invalid configuration: %@", error);
    }
    else
    {
        DDLogVerbose(@"Connecting to \"%@\" on port %hu...", WWW_HOST, port);
    }
    
#if USE_SECURE_CONNECTION
    
    // The connect method above is asynchronous.
    // At this point, the connection has been initiated, but hasn't completed.
    // When the connection is established, our socket:didConnectToHost:port: delegate method will be invoked.
    //
    // Now, for a secure connection we have to connect to the HTTPS server running on port 443.
    // The SSL/TLS protocol runs atop TCP, so after the connection is established we want to start the TLS handshake.
    //
    // We already know this is what we want to do.
    // Wouldn't it be convenient if we could tell the socket to queue the security upgrade now instead of waiting?
    // Well in fact you can! This is part of the queued architecture of AsyncSocket.
    //
    // After the connection has been established, AsyncSocket will look in its queue for the next task.
    // There it will find, dequeue and execute our request to start the TLS security protocol.
    //
    // The options passed to the startTLS method are fully documented in the GCDAsyncSocket header file.
    
#if USE_CFSTREAM_FOR_TLS
    {
        // Use old-school CFStream style technique
        
        NSDictionary *options = @{
                                  GCDAsyncSocketUseCFStreamForTLS : @(YES),
                                  GCDAsyncSocketSSLPeerName : CERT_HOST
                                  };
        
        DDLogVerbose(@"Requesting StartTLS with options:\n%@", options);
        [asyncSocket startTLS:options];
    }
#elif MANUALLY_EVALUATE_TRUST
    {
        // Use socket:didReceiveTrust:completionHandler: delegate method for manual trust evaluation
        
        NSDictionary *options = @{
                                  GCDAsyncSocketManuallyEvaluateTrust : @(YES),
                                  GCDAsyncSocketSSLPeerName : CERT_HOST
                                  };
        
        DDLogVerbose(@"Requesting StartTLS with options:\n%@", options);
        [asyncSocket startTLS:options];
    }
#else
    {
        // Use default trust evaluation, and provide basic security parameters
        
        NSDictionary *options = @{
                                  GCDAsyncSocketSSLPeerName : CERT_HOST
                                  };
        
        DDLogVerbose(@"Requesting StartTLS with options:\n%@", options);
        [asyncSocket startTLS:options];
    }
#endif
    
#endif
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    DDLogVerbose(@"socket:didConnectToHost:%@ port:%hu", host, port);
    
    // HTTP is a really simple protocol.
    //
    // If you don't already know all about it, this is one of the best resources I know (short and sweet):
    // http://www.jmarshall.com/easy/http/
    //
    // We're just going to tell the server to send us the metadata (essentially) about a particular resource.
    // The server will send an http response, and then immediately close the connection.
    
    NSString *requestStrFrmt = @"HEAD / HTTP/1.0\r\nHost: %@\r\n\r\n";
    
    NSString *requestStr = [NSString stringWithFormat:requestStrFrmt, WWW_HOST];
    NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [asyncSocket writeData:requestData withTimeout:-1.0 tag:0];
    
    DDLogVerbose(@"Sending HTTP Request:\n%@", requestStr);
    
    // Side Note:
    //
    // The AsyncSocket family supports queued reads and writes.
    //
    // This means that you don't have to wait for the socket to connect before issuing your read or write commands.
    // If you do so before the socket is connected, it will simply queue the requests,
    // and process them after the socket is connected.
    // Also, you can issue multiple write commands (or read commands) at a time.
    // You don't have to wait for one write operation to complete before sending another write command.
    //
    // The whole point is to make YOUR code easier to write, easier to read, and easier to maintain.
    // Do networking stuff when it is easiest for you, or when it makes the most sense for you.
    // AsyncSocket adapts to your schedule, not the other way around.
    
#if READ_HEADER_LINE_BY_LINE
    
    // Now we tell the socket to read the first line of the http response header.
    // As per the http protocol, we know each header line is terminated with a CRLF (carriage return, line feed).
    
    [asyncSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1.0 tag:0];
    
#else
    
    // Now we tell the socket to read the full header for the http response.
    // As per the http protocol, we know the header is terminated with two CRLF's (carriage return, line feed).
    
    NSData *responseTerminatorData = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    
    [asyncSocket readDataToData:responseTerminatorData withTimeout:-1.0 tag:0];
    
#endif
}

- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust
completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    DDLogVerbose(@"socket:shouldTrustPeer:");
    
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bgQueue, ^{
        
        // This is where you would (eventually) invoke SecTrustEvaluate.
        // Presumably, if you're using manual trust evaluation, you're likely doing extra stuff here.
        // For example, allowing a specific self-signed certificate that is known to the app.
        
        SecTrustResultType result = kSecTrustResultDeny;
        OSStatus status = SecTrustEvaluate(trust, &result);
        
        if (status == noErr && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified)) {
            completionHandler(YES);
        }
        else {
            completionHandler(NO);
        }
    });
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    // This method will be called if USE_SECURE_CONNECTION is set
    
    DDLogVerbose(@"socketDidSecure:");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    DDLogVerbose(@"socket:didWriteDataWithTag:");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    DDLogVerbose(@"socket:didReadData:withTag:");
    
    NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
#if READ_HEADER_LINE_BY_LINE
    
    DDLogInfo(@"Line httpResponse: %@", httpResponse);
    
    // As per the http protocol, we know the header is terminated with two CRLF's.
    // In other words, an empty line.
    
    if ([data length] == 2) // 2 bytes = CRLF
    {
        DDLogInfo(@"<done>");
    }
    else
    {
        // Read the next line of the header
        [asyncSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1.0 tag:0];
    }
    
#else
    
    DDLogInfo(@"Full HTTP Response:\n%@", httpResponse);
    
#endif
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    // Since we requested HTTP/1.0, we expect the server to close the connection as soon as it has sent the response.
    
    DDLogVerbose(@"socketDidDisconnect:withError: \"%@\"", err);
}

@end
