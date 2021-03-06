//
//  ProtocolSelectViewController.m
//  Observer
//
//  Created by Regan Sarwas on 11/20/13.
//  Copyright (c) 2013 GIS Team. All rights reserved.
//

#import "ProtocolSelectViewController.h"
#import "ProtocolDetailViewController.h"
#import "ProtocolTableViewCell.h"

#import "SProtocol.h"
#import "ProtocolCollection.h"

#import "Settings.h"
#import "NSDate+Formatting.h"
#import "NSIndexPath+unsignedAccessors.h"
#import "NSIndexSet+indexPath.h"

#define kOKButtonText              NSLocalizedString(@"OK", @"OK button text")

@interface ProtocolSelectViewController ()
@property (strong, nonatomic) ProtocolCollection *items; //Model
@property (nonatomic) BOOL showRemoteProtocols;
@property (nonatomic) BOOL isBackgroundRefreshing;
@property (weak, nonatomic) IBOutlet UILabel *refreshLabel;
@end

@implementation ProtocolSelectViewController

- (void)awakeFromNib
{
    self.clearsSelectionOnViewWillAppear = NO;
    self.preferredContentSize = CGSizeMake(380.0, 480.0);
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.showRemoteProtocols = ![Settings manager].hideRemoteProtocols;
    self.refreshControl = [UIRefreshControl new];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:NO];
    [Settings manager].hideRemoteProtocols = !self.showRemoteProtocols;
    [super viewWillDisappear:animated];
}

// Releasing the collection will save memory, but will also take time to recreate collection on each VC load
- (void)dealloc
{
    [ProtocolCollection releaseSharedCollection];
}




#pragma mark - lazy property initializers

- (ProtocolCollection *)items
{
    if (!_items) {
        ProtocolCollection *protocols = [ProtocolCollection sharedCollection];
        [protocols openWithCompletionHandler:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.items = protocols;
                [self.tableView reloadData];
                [self setFooterText];
                [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
            });
        }];
    }
    return _items;
}



#pragma mark - Public Methods

- (void)addProtocol:(SProtocol *)protocol
{
    [self.items insertLocalProtocol:protocol atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
}



#pragma mark - CollectionChanged

//These delegates will be called on the main queue whenever the datamodel has changed
- (void)collection:(id)collection addedLocalItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:0];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)collection:(id)collection addedRemoteItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:1];
    if (self.showRemoteProtocols) {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)collection:(id)collection removedLocalItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:0];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)collection:(id)collection removedRemoteItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:1];
    if (self.showRemoteProtocols) {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)collection:(id)collection changedLocalItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:0];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)collection:(id)collection changedRemoteItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:1];
    if (self.showRemoteProtocols) {
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}




#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!self.items) {
        return 0;
    } else {
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return (NSInteger)self.items.numberOfLocalProtocols;
    }
    if (section == 1 && self.showRemoteProtocols) {
        return (NSInteger)self.items.numberOfRemoteProtocols;
    }
    if (section == 2) {
        return tableView.isEditing ? 0 : 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"On this device";
    }
    if (section == 1 && self.showRemoteProtocols ) {
        return @"In the cloud";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProtocolButtonCell" forIndexPath:indexPath];
        cell.textLabel.textColor = cell.tintColor;
        cell.textLabel.text = self.showRemoteProtocols ? @"Show Only Downloaded Protocols" : @"Show All Protocols";
        return cell;
    } else {
        SProtocol *protocol = (indexPath.section == 0) ? [self.items localProtocolAtIndex:indexPath.urow] : [self.items remoteProtocolAtIndex:indexPath.urow];
        NSString *identifier = (indexPath.section == 0) ? @"LocalProtocolCell" : @"RemoteProtocolCell";
        ProtocolTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        cell.titleLabel.text = protocol.title;
        cell.subtitleLabel.text = protocol.subtitle;
        cell.downloading = protocol.isDownloading;
        cell.percentComplete = protocol.downloadPercentComplete;
        protocol.downloadProgressAction = ^(double bytesWritten, double bytesExpected) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.percentComplete = bytesWritten/bytesExpected;
            });
        };
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 2) {
        self.showRemoteProtocols = ! self.showRemoteProtocols;
        [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
        return;
    }

    if (indexPath.section == 1) {
        if (!self.isBackgroundRefreshing)
        {
            [self startStopDownloadItem:indexPath];
        }
        return;
    }

    if (indexPath.section == 0) {
        if (self.protocolSelectedAction) {
            self.protocolSelectedAction([self.items localProtocolAtIndex:indexPath.urow]);
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section < 2;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section < 2;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    return (proposedDestinationIndexPath.section == sourceIndexPath.section) ? proposedDestinationIndexPath : sourceIndexPath;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 0  ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if (fromIndexPath.section != toIndexPath.section) {
        return;
    }
    if (self.isBackgroundRefreshing)
    {
        return;
    }
    if (fromIndexPath.section == 0) {
        [self.items moveLocalProtocolAtIndex:fromIndexPath.urow toIndex:toIndexPath.urow];
    }
    if (fromIndexPath.section == 1) {
        [self.items moveRemoteProtocolAtIndex:fromIndexPath.urow toIndex:toIndexPath.urow];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isBackgroundRefreshing)
    {
        return;
    }
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.items removeLocalProtocolAtIndex:indexPath.urow];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    //This is called _during_ the swipe to delete CommitEditing, and is ignored unless we dispatch it for later
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setEditing:NO animated:YES];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Remote Protocol Details"] || [segue.identifier isEqualToString:@"Local Protocol Details"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        SProtocol *item = indexPath.section == 0 ? [self.items localProtocolAtIndex:indexPath.urow] :  [self.items remoteProtocolAtIndex:indexPath.urow];
        ProtocolDetailViewController *vc = (ProtocolDetailViewController *)segue.destinationViewController;
        vc.title = segue.identifier;
        vc.protocol = item;
        //if we are in a popover, we want the popover to stay the same size.
        vc.preferredContentSize = self.preferredContentSize;
    }
}

- (void)refresh:(id)sender
{
    [self.refreshControl beginRefreshing];
    self.refreshLabel.text = @"Looking for new protocols...";
    self.isBackgroundRefreshing = YES;
    self.items.delegate = self;
    [self.items refreshWithCompletionHandler:^(BOOL success) {
        //on background thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
            self.isBackgroundRefreshing = NO;
            if (success) {
                if (!self.showRemoteProtocols) {
                    self.showRemoteProtocols = YES;
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            } else {
                [self alert:nil message:@"Can't connect to server"];
            }
            [self setFooterText];
            self.items.delegate = nil;
        });
    }];
}

- (void)startStopDownloadItem:(NSIndexPath *)indexPath
{
    SProtocol *protocol = [self.items remoteProtocolAtIndex:indexPath.urow];
    if (protocol.isDownloading) {
        [protocol cancelDownload];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        ProtocolTableViewCell *cell = (ProtocolTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        protocol.downloadProgressAction = ^(double bytesWritten, double bytesExpected) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.percentComplete =  bytesWritten/bytesExpected;
            });
        };
        protocol.downloadCompletionAction = ^(SProtocol *newProtocol) {
            //on background thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                if (newProtocol) {
                    [self.items removeRemoteProtocolAtIndex:indexPath.urow];
                    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.items insertLocalProtocol:newProtocol atIndex:0];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                } else {
                    [self alert:nil message:@"Can't download protocol"];
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            });
        };
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [protocol startDownload];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)setFooterText
{
    if (self.items.refreshDate) {
        if (self.items.refreshDate.today) {
            self.refreshLabel.text = [NSString stringWithFormat:@"Updated %@",self.items.refreshDate.stringWithMediumTimeFormat];
        } else {
            self.refreshLabel.text = [NSString stringWithFormat:@"Updated %@",self.items.refreshDate.stringWithMediumDateFormat];
        }
    }
}

- (void) alert:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:kOKButtonText style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
