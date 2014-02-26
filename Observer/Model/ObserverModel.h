//
//  ObserverModel.h
//  Observer
//
//  Created by Regan Sarwas on 8/14/13.
//  Copyright (c) 2013 GIS Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

//CoreData entities
#import "AdhocLocation.h"
#import "AngleDistanceLocation.h"
#import "GpsPoint.h"
#import "LocationAngleDistance.h"
#import "Observation.h"
#import "MissionProperty.h"
#import "MapReference.h"

#import "AGSPoint+AKRAdditions.h"
#import "NSArray+map.h"

#import "Enumerations.h"
#import "Settings.h"

#import "Survey.h"
#import "Map.h"
#import "SProtocol.h"

#define kAttributePrefix                 @"A_"
#define kObservationPrefix               @"O_"
#define kObservationEntityName           @"Observation"
#define kMissionEntityName               @"Mission"
#define kMissionPropertyEntityName       @"MissionProperty"
#define kGpsPointEntityName              @"GpsPoint"
#define kMapEntityName                   @"Map"
#define kAngleDistanceLocationEntityName @"AngleDistanceLocation"
#define kAdhocLocationEntityName         @"AdhocLocation"
