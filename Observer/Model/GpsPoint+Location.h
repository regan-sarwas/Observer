//
//  GpsPoint+Location.h
//  Observer
//
//  Created by Regan Sarwas on 5/9/14.
//  Copyright (c) 2014 GIS Team. All rights reserved.
//

#import "GpsPoint.h"

@interface GpsPoint (Location)

- (CLLocationCoordinate2D)locationOfGps;
- (AGSPoint *)pointOfGpsWithSpatialReference:(AGSSpatialReference*)spatialReference;

@end