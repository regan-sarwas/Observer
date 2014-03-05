//
//  AGSMapView+AKRAdditions.m
//  Observer
//
//  Created by Regan Sarwas on 2/27/14.
//  Copyright (c) 2014 GIS Team. All rights reserved.
//

#import "AGSMapView+AKRAdditions.h"

@implementation AGSMapView (AKRAdditions)

- (CGPoint)nearestScreenPoint :(AGSPoint *)point
{
    if (!self.visibleArea.spatialReference || !point.spatialReference) {
        return CGPointZero;
    }
    if (![self.spatialReference isEqualToSpatialReference:point.spatialReference]) {
        return CGPointZero;
    }
    if ([self.visibleArea containsPoint:point]) {
        return [self toScreenPoint:point];
    }
    AGSGeometryEngine *ge = [AGSGeometryEngine defaultGeometryEngine];
    AGSProximityResult *proximity = [ge nearestCoordinateInGeometry:self.visibleArea toPoint:point];
    return [self toScreenPoint:proximity.point];
}


@end