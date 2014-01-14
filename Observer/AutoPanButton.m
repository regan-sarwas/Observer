//
//  AutoPanButton.m
//  Observer
//
//  Created by Regan Sarwas on 1/9/14.
//  Copyright (c) 2014 GIS Team. All rights reserved.
//

#import "AutoPanButton.h"

@interface AutoPanButton ()

@property (nonatomic, strong) UIImage *gpsOff;
@property (nonatomic, strong) UIImage *gpsOn;
@property (nonatomic, strong) UIImage *gpsRotate;

@end

@implementation AutoPanButton


- (UIImage *)gpsOff
{
    if (!_gpsOff) {
        _gpsOff = [UIImage imageNamed:@"GpsOff"];
    }
    return _gpsOff;
}

- (UIImage *)gpsOn
{
    if (!_gpsOn) {
        _gpsOn = [UIImage imageNamed:@"GpsOn"];
    }
    return _gpsOn;
}

- (UIImage *)gpsRotate
{
    if (!_gpsRotate) {
        _gpsRotate = [UIImage imageNamed:@"GpsRotate"];
    }
    return _gpsRotate;
}

- (void)turnOff
{
    //TODO: replace text with cool images/highlighting
    //self.title = @"Off";
    self.title = nil;
    self.image = self.gpsOff;
}

- (void)turnOnWithoutRotate
{
    //self.title = @"On";
    self.title = nil;
    self.image = self.gpsOn;
}

- (void)turnOnWithRotate
{
    //self.title = @"OnR";
    self.title = nil;
    self.image = self.gpsRotate;
}

@end
