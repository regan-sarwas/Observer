//
//  FeatureSelectorTableViewController.h
//  Observer
//
//  Created by Regan Sarwas on 2/21/14.
//  Copyright (c) 2014 GIS Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FeatureSelectorTableViewController : UITableViewController


//features is a dictionary of layer name (key) : Array of id<AGSFeature> (value)
//id<AGSFeature> are objects from all hit-testable layers in the map at the users touch
@property (nonatomic, strong) NSDictionary *features;

//Feature Selected Callback
@property (copy, nonatomic) void (^featureSelectedCallback)(NSString *layerName, id<AGSFeature> graphic);

@end