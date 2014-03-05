//
//  MapSelectViewController.m
//  Observer
//
//  Created by Regan Sarwas on 11/26/13.
//  Copyright (c) 2013 GIS Team. All rights reserved.
//

#import "MapSelectViewController.h"
#import "Map.h"
#import "MapCollection.h"
#import "NSIndexSet+indexPath.h"
#import "NSIndexPath+unsignedAccessors.h"

#import "MapDetailViewController.h"
#import "MapTableViewCell.h"
#import "NSDate+Formatting.h"
#import "Settings.h"


@interface MapSelectViewController ()
@property (strong, nonatomic) MapCollection *items; //Model
@property (nonatomic) BOOL showRemoteMaps;
@property (nonatomic) BOOL isBackgroundRefreshing;
@property (weak, nonatomic) IBOutlet UILabel *refreshLabel;
@property (strong, nonatomic) MapDetailViewController *detailViewController;
@end

@implementation MapSelectViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(420.0, 580.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.showRemoteMaps = ![Settings manager].hideRemoteMaps;
    self.refreshControl = [UIRefreshControl new];
}

-(void)viewWillAppear:(BOOL)animated
{
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:NO];
    [Settings manager].hideRemoteMaps = !self.showRemoteMaps;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.detailViewController = nil;
}

#pragma mark - lazy property initializers

- (MapDetailViewController *)detailViewController
{
    if (!_detailViewController) {
        _detailViewController = (MapDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    }
    return _detailViewController;
}

- (MapCollection *)items
{
    if (!_items) {
        MapCollection *maps = [MapCollection sharedCollection];
        [maps openWithCompletionHandler:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.items = maps;
                [self.tableView reloadData];
                [self setFooterText];
                [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
            });
        }];
    }
    return _items;
}



#pragma mark - Public Methods

- (void) addMap:(Map *)map
{
    [self.items insertLocalMap:map atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
}



#pragma mark - CollectionChanged

//These delegates will be called on the main queue whenever the datamodel has changed
- (void) collection:(id)collection addedLocalItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:0];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) collection:(id)collection addedRemoteItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:1];
    if (self.showRemoteMaps) {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void) collection:(id)collection removedLocalItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:0];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) collection:(id)collection removedRemoteItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:1];
    if (self.showRemoteMaps) {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void) collection:(id)collection changedLocalItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:0];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) collection:(id)collection changedRemoteItemsAtIndexes:(NSIndexSet *)indexSet
{
    NSArray *indexPaths = [indexSet indexPathsWithSection:1];
    if (self.showRemoteMaps) {
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return (NSInteger)self.items.numberOfLocalMaps;
    }
    if (section == 1 && self.showRemoteMaps) {
        return (NSInteger)self.items.numberOfRemoteMaps;
    }
    if (section == 2) {
        return tableView.isEditing ? 0 : 1;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"On this device";
    }
    if (section == 1 && self.showRemoteMaps ) {
        return @"In the cloud";
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 2) ? 40 : 75;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MapButtonCell" forIndexPath:indexPath];
        cell.textLabel.textColor = cell.tintColor;
        cell.textLabel.text = self.showRemoteMaps ? @"Show Only Downloaded Maps" : @"Show All Maps";
        return cell;
    } else {
        Map *item = (indexPath.section == 0) ? [self.items localMapAtIndex:indexPath.urow] : [self.items remoteMapAtIndex:indexPath.urow];
        NSString *identifier = (indexPath.section == 0) ? @"LocalMapCell" : @"RemoteMapCell";
        MapTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        cell.titleLabel.text = item.title;
        [item openThumbnailWithCompletionHandler:^(BOOL success) {
            //on background thread
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.thumbnailImageView.image = item.thumbnail;
            });
        }];
        cell.subtitle1Label.text = item.subtitle;
        cell.subtitle2Label.text = item.subtitle2;
        cell.downloadImageView.hidden = item.isDownloading;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (indexPath.section == 2) {
        self.showRemoteMaps = ! self.showRemoteMaps;
        [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
        return;
    }

    if (indexPath.section == 1) {
        if (self.isBackgroundRefreshing)
        {
            [[[UIAlertView alloc] initWithTitle:@"Try Again" message:@"Can not download while refreshing.  Please try again when refresh is complete." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        } else {
            [self downloadItem:indexPath];
        }
        return;
    }

    [self.items setSelectedLocalMap:indexPath.urow];
    if (self.mapSelectedAction) {
        self.mapSelectedAction(self.items.selectedLocalMap);
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

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
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
        [[[UIAlertView alloc] initWithTitle:@"Try Again" message:@"Could not make changes while refreshing.  Please try again when refresh is complete." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    if (fromIndexPath.section == 0) {
        [self.items moveLocalMapAtIndex:fromIndexPath.urow toIndex:toIndexPath.urow];
    }
    if (fromIndexPath.section == 1) {
        [self.items moveRemoteMapAtIndex:fromIndexPath.urow toIndex:toIndexPath.urow];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isBackgroundRefreshing)
    {
        [[[UIAlertView alloc] initWithTitle:@"Try Again" message:@"Could not make changes while refreshing.  Please try again when refresh is complete." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Map *map = [self.items localMapAtIndex:indexPath.urow];
        [self.items removeLocalMapAtIndex:indexPath.urow];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (self.mapDeletedAction) {
            self.mapDeletedAction(map);
        }
    }
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    //This is called _during_ the swipe to delete CommitEditing, and is ignored unless we dispatch it for later
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setEditing:NO animated:YES];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Map Details"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Map *item = indexPath.section == 0 ? [self.items localMapAtIndex:indexPath.urow] :  [self.items remoteMapAtIndex:indexPath.urow];
        MapDetailViewController *vc = (MapDetailViewController *)[segue destinationViewController];
        vc.title = segue.identifier;
        vc.map = item;
        //if we are in a popover, we want the popover to stay the same size.
        [vc setPreferredContentSize:self.preferredContentSize];
    }
}

- (void) refresh:(id)sender
{
    [self.refreshControl beginRefreshing];
    self.refreshLabel.text = @"Looking for new maps...";
    self.isBackgroundRefreshing = YES;
    self.items.delegate = self;
    [self.items refreshWithCompletionHandler:^(BOOL success) {
        //on background thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
            self.isBackgroundRefreshing = NO;
            if (success) {
                if (!self.showRemoteMaps) {
                    self.showRemoteMaps = YES;
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Can't get the map list from the server" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
            [self setFooterText];
            self.items.delegate = nil;
        });
    }];
}

- (void) downloadItem:(NSIndexPath *)indexPath
{
    MapTableViewCell *cell = (MapTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell.downloadView.downloading) {
        cell.downloadImageView.hidden = NO;
        cell.downloadView.downloading = NO;
        [self.items cancelDownloadMapAtIndex:indexPath.urow];
    } else {
        [self.items prepareToDownloadMapAtIndex:indexPath.urow];
        cell.downloadView.percentComplete = 0;
        cell.downloadImageView.hidden = YES;
        cell.downloadView.downloading = YES;
        Map *map = [self.items remoteMapAtIndex:indexPath.urow];
        map.progressAction = ^(double bytesWritten, double bytesExpected) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.downloadView.percentComplete =  bytesWritten/bytesExpected;
            });
        };
        map.completionAction = ^(NSURL *mapUrl, BOOL success) {
            //on background thread
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    self.items.delegate = self;
                    [self.items moveRemoteMapAtIndex:indexPath.urow toLocalMapAtIndex:0];
                    self.items.delegate = nil;
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Can't download map" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                    cell.downloadView.downloading = NO;
                    cell.downloadImageView.hidden = NO;
                }
            });
        };
        [map startDownload];
    }
}

- (void) stopDownloadItem:(NSIndexPath *)indexPath
{
    Map *map = [self.items remoteMapAtIndex:indexPath.urow];
    [map stopDownload];
}

- (void)setFooterText
{
    if (self.items.refreshDate) {
        if ([self.items.refreshDate isToday]) {
            self.refreshLabel.text = [NSString stringWithFormat:@"Updated %@",[self.items.refreshDate stringWithMediumTimeFormat]];
        } else {
            self.refreshLabel.text = [NSString stringWithFormat:@"Updated %@",[self.items.refreshDate stringWithMediumDateFormat]];
        }
    }
}

@end

