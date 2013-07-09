//
//  LocalMapsTableViewController.m
//  Observer
//
//  Created by Regan Sarwas on 7/5/13.
//  Copyright (c) 2013 GIS Team. All rights reserved.
//

#import "LocalMapsTableViewController.h"
#import "BaseMap.h"

@interface LocalMapsTableViewController ()

@end

@implementation LocalMapsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
     self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCount;
    if (self.editing)
    {
        rowCount = self.maps.count + (self.maps.serverMaps.count == 0 ? 1 : self.maps.serverMaps.count);
    }
    else
    {
        rowCount = self.maps.count == 0 ? 1 : self.maps.count;
    }
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (self.editing)
    {
        //display local maps first
        if (indexPath.row < self.maps.count)
        {
            static NSString *CellIdentifier = @"Local Map Description Cell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            BaseMap *map = [self.maps mapAtIndex:indexPath.row];
            cell.textLabel.text = map.name;
            cell.detailTextLabel.text = map.summary;
            // Set up the iconography
            
        }
        else
        {
            if (self.maps.serverMaps.count) {
                NSInteger index = indexPath.row - self.maps.count;
                static NSString *CellIdentifier = @"Local Map Description Cell";
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                
                BaseMap *map = self.maps.serverMaps[index];
                cell.textLabel.text = map.name;
                cell.detailTextLabel.text = map.summary;
                // Set up the iconography
            }
            else
            {
                static NSString *CellIdentifier = @"Notification Cell";
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                if (self.maps.serverMaps) //the array exist but is empty; we finished query, but got nothing
                    cell.textLabel.text = @"Click Edit to add maps.";
                else //we are still trying
                    cell.textLabel.text = @"Please wait while I look for maps...";
            }
        }
    }
    else
    {
        if (self.maps.count)
        {
            static NSString *CellIdentifier = @"Local Map Description Cell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            BaseMap *map = [self.maps mapAtIndex:indexPath.row];
            cell.textLabel.text = map.name;
            cell.detailTextLabel.text = map.summary;
            // Set up the iconography
        }
        else
        {
            static NSString *CellIdentifier = @"Notification Cell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            cell.textLabel.text = @"Click Edit to add maps.";
        }
    }    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        return (self.maps.count <= indexPath.row) ? UITableViewCellEditingStyleInsert : UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.maps removeMapAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self.maps moveMapAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.maps.currentMap = [self.maps mapAtIndex:indexPath.row];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
