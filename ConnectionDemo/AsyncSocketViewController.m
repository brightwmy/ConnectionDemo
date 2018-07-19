//
//  ViewController.m
//  ConnectionDemo
//
//  Created by wumingyun on 2018/6/10.
//  Copyright © 2018 OMI. All rights reserved.
//

#import "AsyncSocketViewController.h"
#import "KeyboardInputView.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "AppDelegate.h"
#import "Conversation+CoreDataClass.h"
#import "ConversationViewController.h"
#import <CoreData/CoreData.h>

@interface AsyncSocketViewController () <GCDAsyncSocketDelegate, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic) GCDAsyncSocket *socket;

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation AsyncSocketViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"updateDate" ascending:NO];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(Conversation.class)];
//    NSFetchRequest *fetchRequest = Conversation.fetchRequest;
    fetchRequest.sortDescriptors = @[sort];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:appDelegate.mainContext sectionNameKeyPath:nil cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
    [self.fetchedResultsController performFetch:nil];
}

- (IBAction)reconnect:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    Conversation *conversation = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(Conversation.class) inManagedObjectContext:appDelegate.mainContext];
    conversation.updateDate = [NSDate date];
    conversation.peerDeviceID = [NSUUID UUID].UUIDString;
    [appDelegate.mainContext save:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(UITableViewCell.class) forIndexPath:indexPath];
    cell.textLabel.text = [[(Conversation *)[self.fetchedResultsController objectAtIndexPath:indexPath] peerDeviceID] substringToIndex:5];
    cell.detailTextLabel.text = [[(Conversation *)[self.fetchedResultsController objectAtIndexPath:indexPath] updateDate] description];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fetchedResultsController.fetchedObjects.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"showConversation" sender:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ConversationViewController *vc = segue.destinationViewController;
    vc.conversation = (Conversation *)sender;
}

@end
