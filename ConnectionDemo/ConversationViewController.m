//
//  ConversationViewController.m
//  ConnectionDemo
//
//  Created by wumingyun on 2018/7/18.
//  Copyright © 2018 OMI. All rights reserved.
//

#import "ConversationViewController.h"
#import "Message+CoreDataClass.h"
#import "KeyboardInputView.h"
#import "AppDelegate.h"
#import "Conversation+CoreDataClass.h"
#import "MessageTableViewCell.h"

@interface ConversationViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet KeyboardInputView *keyboardView;
@property (nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation ConversationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"createDate" ascending:YES];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(Message.class)];
    
    fetchRequest.sortDescriptors = @[sort];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:appDelegate.mainContext sectionNameKeyPath:nil cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
    [self.fetchedResultsController performFetch:nil];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fetchedResultsController.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MessageTableViewCell.class) forIndexPath:indexPath];
    Message *message = (Message *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = message.text;
    return cell;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
}

#pragma mark - input

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(Message.class) inManagedObjectContext:appDelegate.mainContext];
    message.text = textField.text;
    message.createDate = [NSDate date];
    [self.conversation addMessagesObject:message];
    [appDelegate.mainContext save:nil];
    [textField resignFirstResponder];
    return YES;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    //    NSLog(@"-- %@", notification);
    //    NSLog(@"-- %@", self.keyboardView);
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    //    NSNumber *curve = [notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    //    CGRect beginFrame = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    CGRect endFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [UIView animateWithDuration:duration.doubleValue animations:^{
        self.keyboardView.transform = CGAffineTransformMakeTranslation(0,
                                                                       -(self.keyboardView.frame.origin.y - endFrame.origin.y + 30));
    } completion:^(BOOL finished) {
        
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:duration.doubleValue animations:^{
        self.keyboardView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

@end
