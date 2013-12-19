//
//  MapDetailViewController.m
//  Observer
//
//  Created by Regan Sarwas on 12/5/13.
//  Copyright (c) 2013 GIS Team. All rights reserved.
//

#import "MapDetailViewController.h"
#import "NSDate+Formatting.h"
#import "AKRDirectionIndicatorView.h"
#import "Settings.h"

#define TEXTMARGINS 60  //2*30pts

@interface MapDetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet AKRDirectionIndicatorView *directionIndicatorView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation MapDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.nameLabel.preferredMaxLayoutWidth = self.preferredContentSize.width - TEXTMARGINS;
    self.nameLabel.text = self.map.title;
    self.authorLabel.text = self.map.author;
    self.dateLabel.text = [self.map.date stringWithMediumDateFormat];
    [self updateSizeUI];
    [self setupLocationUI];
    self.descriptionLabel.preferredMaxLayoutWidth = self.preferredContentSize.width - TEXTMARGINS;
    self.descriptionLabel.text = self.map.description;
    self.thumbnailImageView.image = self.map.thumbnail;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unitsChanged) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.locationManager stopMonitoringSignificantLocationChanges];
    self.locationManager.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupLocationUI
{
    if (![CLLocationManager locationServicesEnabled]) {
        self.locationLabel.text = @"Location unavailable";
        return;
    }
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        //ask for permission by trying
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized)
    {
        self.locationLabel.text = @"Location not authorized";
        return;
    }
    if (!self.locationManager) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
    self.locationLabel.text = @"Waiting for current location ...";
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
    {
        self.locationLabel.text = @"Waiting for current location ...";
        [self.locationManager startMonitoringSignificantLocationChanges];
    } else {
        self.locationLabel.text = @"Location not authorized";
        if (self.locationManager) {
            [self.locationManager stopMonitoringSignificantLocationChanges];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [self updateLocationUIWithLocation:[locations lastObject]];
}

#pragma mark - NSNotification callbacks

- (void)unitsChanged
{
    [self updateSizeUI];
    if (self.locationManager) {
        [self updateLocationUIWithLocation:self.locationManager.location];
    }
}

#pragma mark - private functions

- (void)updateLocationUIWithLocation:(CLLocation *)location
{
    AKRAngleDistance *angleDistance = [self.map angleDistanceFromLocation:location];
    NSString *distanceString = [self distanceStringFromKilometers:angleDistance.kilometers];
    self.locationLabel.text = distanceString;
    self.directionIndicatorView.azimuth = angleDistance.azimuth;
    self.directionIndicatorView.azimuthUnknown = angleDistance.kilometers <= 0;
}

- (void)updateSizeUI
{
    self.sizeLabel.text = [NSString stringWithFormat:@"%@ on %@\n%@", self.map.byteSizeString, (self.map.isLocal ? @"device" : @"server"), self.map.arealSizeString];
}

#pragma mark - formatting

+ (NSString *)formatLength:(double)length
{
    static NSNumberFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSNumberFormatter new];
        formatter.maximumSignificantDigits = 4;
    });
    return [formatter stringFromNumber:[NSNumber numberWithDouble:length]];
}

- (NSString *)distanceStringFromKilometers:(double)kilometers
{
    if (kilometers < 0) {
        return @"Unknown";
    }
    if (kilometers == 0) {
        return @"On map!";
    }
    AGSSRUnit units = [Settings manager].distanceUnitsForMeasuring;
    if (units == AGSSRUnitMeter || units == AGSSRUnitKilometer) {
        return [NSString stringWithFormat:@"%@ km", [MapDetailViewController formatLength:kilometers]];
    } else {
        double miles = kilometers * 0.621371;
        return [NSString stringWithFormat:@"%@ mi", [MapDetailViewController formatLength:miles]];
    }
}

@end
