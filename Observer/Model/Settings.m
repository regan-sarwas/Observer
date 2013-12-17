//
//  Settings.m
//  Observer
//
//  Created by Regan Sarwas on 7/26/13.
//  Copyright (c) 2013 GIS Team. All rights reserved.
//

#import "Settings.h"

/*
 * Note:
 * if defaults system cannot find a key it returns a zero value,
 * that is nil for objects, NO for BOOL, and 0 for numbers.
 * If you provide a non-zero default, then you cannot persist
 * a zero value, as it will always be replaced with your default
 */

#define DEFAULTS_KEY_AUTOPAN_ENABLED @"autopan_enabled"
#define DEFAULTS_DEFAULT_AUTOPAN_ENABLED NO

#define DEFAULTS_KEY_AUTOPAN_MODE @"autopan_mode"
#define DEFAULTS_DEFAULT_AUTOPAN_MODE AGSLocationDisplayAutoPanModeDefault

#define DEFAULTS_KEY_UOM_DISTANCE_SIGHTING @"uom_distance_sighting"
#define DEFAULTS_DEFAULT_UOM_DISTANCE_SIGHTING AGSSRUnitMeter

#define DEFAULTS_KEY_UOM_DISTANCE_MEASURE @"uom_distance_measure"
#define DEFAULTS_DEFAULT_UOM_DISTANCE_MEASURE AGSSRUnitStatuteMile

#define DEFAULTS_KEY_ANGLE_DISTANCE_ANGLE_DIRECTION @"angle_distance_angle_direction"
#define DEFAULTS_DEFAULT_ANGLE_DISTANCE_ANGLE_DIRECTION 0

#define DEFAULTS_KEY_ANGLE_DISTANCE_DEAD_AHEAD @"angle_distance_dead_ahead"
#define DEFAULTS_DEFAULT_ANGLE_DISTANCE_DEAD_AHEAD 0

#define DEFAULTS_KEY_ANGLE_DISTANCE_LAST_DISTANCE @"angle_distance_last_distance"
#define DEFAULTS_DEFAULT_ANGLE_DISTANCE_LAST_DISTANCE nil

#define DEFAULTS_KEY_ANGLE_DISTANCE_LAST_ANGLE @"angle_distance_last_angle"
#define DEFAULTS_DEFAULT_ANGLE_DISTANCE_LAST_ANGLE nil

#define DEFAULTS_KEY_INDEX_OF_CURRENT_MAP @"index_of_current_map"
#define DEFAULTS_DEFAULT_INDEX_OF_CURRENT_MAP 0

#define DEFAULTS_KEY_INDEX_OF_CURRENT_SURVEY @"index_of_current_survey"
#define DEFAULTS_DEFAULT_INDEX_OF_CURRENT_SURVEY 0



@implementation Settings


#pragma mark - singleton

+ (Settings *)manager
{
    static Settings *_manager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (!_manager) {
            _manager = [[Settings alloc] init];
            [_manager populateRegistrationDomain];
        }
    });
    return _manager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self manager];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}



@synthesize indexOfCurrentMap = _indexOfCurrentMap;

- (NSUInteger) indexOfCurrentMap
{
    NSUInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:DEFAULTS_KEY_INDEX_OF_CURRENT_MAP];
    return value ?: DEFAULTS_DEFAULT_INDEX_OF_CURRENT_MAP;
}

- (void)setIndexOfCurrentMap:(NSUInteger)indexOfCurrentMap
{
    if (indexOfCurrentMap == DEFAULTS_DEFAULT_INDEX_OF_CURRENT_MAP) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULTS_KEY_INDEX_OF_CURRENT_MAP];
    } else {
        [[NSUserDefaults standardUserDefaults] setInteger:indexOfCurrentMap forKey:DEFAULTS_KEY_INDEX_OF_CURRENT_MAP];
    }
}



@synthesize indexOfCurrentSurvey = _indexOfCurrentSurvey;

- (NSUInteger) indexOfCurrentSurvey
{
    NSUInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:DEFAULTS_KEY_INDEX_OF_CURRENT_SURVEY];
    return value ?: DEFAULTS_DEFAULT_INDEX_OF_CURRENT_SURVEY;
}

- (void)setIndexOfCurrentSurvey:(NSUInteger)indexOfCurrentSurvey
{
    if (indexOfCurrentSurvey == DEFAULTS_DEFAULT_INDEX_OF_CURRENT_SURVEY) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULTS_KEY_INDEX_OF_CURRENT_SURVEY];
    } else {
        [[NSUserDefaults standardUserDefaults] setInteger:indexOfCurrentSurvey forKey:DEFAULTS_KEY_INDEX_OF_CURRENT_SURVEY];
    }
}



@synthesize autoPanEnabled = _autoPanEnabled;

- (BOOL) autoPanEnabled
{
    bool value = [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_KEY_AUTOPAN_ENABLED];
    return value ?: DEFAULTS_DEFAULT_AUTOPAN_ENABLED;
}

- (void) setAutoPanEnabled:(BOOL)autoPanEnabled
{
    if (autoPanEnabled == DEFAULTS_DEFAULT_AUTOPAN_ENABLED)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULTS_KEY_AUTOPAN_ENABLED];
    else
        [[NSUserDefaults standardUserDefaults] setBool:autoPanEnabled forKey:DEFAULTS_KEY_AUTOPAN_ENABLED];
}



@synthesize autoPanMode = _autoPanMode;

- (AGSLocationDisplayAutoPanMode) autoPanMode
{
    AGSLocationDisplayAutoPanMode value = [[NSUserDefaults standardUserDefaults] integerForKey:DEFAULTS_KEY_AUTOPAN_MODE];
    return value ?: DEFAULTS_DEFAULT_AUTOPAN_MODE;
}

- (void) setAutoPanMode:(AGSLocationDisplayAutoPanMode)autoPanMode
{
    if (autoPanMode == DEFAULTS_DEFAULT_AUTOPAN_MODE)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULTS_KEY_AUTOPAN_MODE];
    else
        [[NSUserDefaults standardUserDefaults] setInteger:autoPanMode forKey:DEFAULTS_KEY_AUTOPAN_MODE];
}



@synthesize distanceUnitsForSightings = _distanceUnitsForSightings;

- (AGSSRUnit) distanceUnitsForSightings
{
    AGSSRUnit value = [[NSUserDefaults standardUserDefaults] integerForKey:DEFAULTS_KEY_UOM_DISTANCE_SIGHTING];
    return value ?: DEFAULTS_DEFAULT_UOM_DISTANCE_SIGHTING;
}

- (void) setDistanceUnitsForSightings:(AGSSRUnit)distanceUnitsForSightings
{
    if (distanceUnitsForSightings == DEFAULTS_DEFAULT_UOM_DISTANCE_SIGHTING)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULTS_KEY_UOM_DISTANCE_SIGHTING];
    else
        [[NSUserDefaults standardUserDefaults] setInteger:distanceUnitsForSightings forKey:DEFAULTS_KEY_UOM_DISTANCE_SIGHTING];
}



@synthesize distanceUnitsForMeasuring = _distanceUnitsForMeasuring;

- (AGSSRUnit) distanceUnitsForMeasuring
{
    AGSSRUnit value = [[NSUserDefaults standardUserDefaults] integerForKey:DEFAULTS_KEY_UOM_DISTANCE_MEASURE];
    return value ?: DEFAULTS_DEFAULT_UOM_DISTANCE_MEASURE;
}

- (void) setDistanceUnitsForMeasuring:(AGSSRUnit)distanceUnitsForMeasuring
{
    if (distanceUnitsForMeasuring == DEFAULTS_DEFAULT_UOM_DISTANCE_MEASURE)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULTS_KEY_UOM_DISTANCE_MEASURE];
    else
        [[NSUserDefaults standardUserDefaults] setInteger:distanceUnitsForMeasuring forKey:DEFAULTS_KEY_UOM_DISTANCE_MEASURE];
}



@synthesize angleDistanceAngleDirection = _angleDistanceAngleDirection;

- (AngleDirection) angleDistanceAngleDirection
{
    AngleDirection value = [[NSUserDefaults standardUserDefaults] integerForKey:DEFAULTS_KEY_ANGLE_DISTANCE_ANGLE_DIRECTION];
    return value ?: DEFAULTS_DEFAULT_ANGLE_DISTANCE_ANGLE_DIRECTION;
}

- (void) setAngleDistanceAngleDirection:(AngleDirection)angleDistanceAngleDirection
{
    if (angleDistanceAngleDirection == DEFAULTS_DEFAULT_ANGLE_DISTANCE_ANGLE_DIRECTION)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULTS_KEY_ANGLE_DISTANCE_ANGLE_DIRECTION];
    else
        [[NSUserDefaults standardUserDefaults] setInteger:angleDistanceAngleDirection forKey:DEFAULTS_KEY_ANGLE_DISTANCE_ANGLE_DIRECTION];
}



@synthesize angleDistanceDeadAhead = _angleDistanceDeadAhead;

- (double) angleDistanceDeadAhead
{
    double value = [[NSUserDefaults standardUserDefaults] doubleForKey:DEFAULTS_KEY_ANGLE_DISTANCE_DEAD_AHEAD];
    return value ?: DEFAULTS_DEFAULT_ANGLE_DISTANCE_DEAD_AHEAD;
}

- (void) setAngleDistanceDeadAhead:(double)angleDistanceDeadAhead
{
    if (angleDistanceDeadAhead == DEFAULTS_DEFAULT_ANGLE_DISTANCE_DEAD_AHEAD)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULTS_KEY_ANGLE_DISTANCE_DEAD_AHEAD];
    else
        [[NSUserDefaults standardUserDefaults] setDouble:angleDistanceDeadAhead forKey:DEFAULTS_KEY_ANGLE_DISTANCE_DEAD_AHEAD];
}



@synthesize angleDistanceLastDistance = _angleDistanceLastDistance;

- (NSNumber *) angleDistanceLastDistance
{
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_ANGLE_DISTANCE_LAST_DISTANCE];
    return [value isKindOfClass:[NSNumber class]] ? (NSNumber *)value: DEFAULTS_DEFAULT_ANGLE_DISTANCE_LAST_DISTANCE;
}

- (void) setAngleDistanceLastDistance:(NSNumber *)angleDistanceLastDistance
{
    if (angleDistanceLastDistance == DEFAULTS_DEFAULT_ANGLE_DISTANCE_LAST_DISTANCE)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULTS_KEY_ANGLE_DISTANCE_LAST_DISTANCE];
    else
        [[NSUserDefaults standardUserDefaults] setObject:angleDistanceLastDistance forKey:DEFAULTS_KEY_ANGLE_DISTANCE_LAST_DISTANCE];
}



@synthesize angleDistanceLastAngle = _angleDistanceLastAngle;

- (NSNumber *) angleDistanceLastAngle
{
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_ANGLE_DISTANCE_LAST_ANGLE];
    return [value isKindOfClass:[NSNumber class]] ? (NSNumber *)value: DEFAULTS_DEFAULT_ANGLE_DISTANCE_LAST_ANGLE;
}

- (void) setAngleDistanceLastAngle:(NSNumber *)angleDistanceLastAngle
{
    if (angleDistanceLastAngle == DEFAULTS_DEFAULT_ANGLE_DISTANCE_LAST_ANGLE)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULTS_KEY_ANGLE_DISTANCE_LAST_ANGLE];
    else
        [[NSUserDefaults standardUserDefaults] setObject:angleDistanceLastAngle forKey:DEFAULTS_KEY_ANGLE_DISTANCE_LAST_ANGLE];
}


#pragma mark - Seed NSDefaults from Settings.Bundle

//The following two methods were borrowed from the AppPrefs Sample

// -------------------------------------------------------------------------------
//  populateRegistrationDomain
//  Locates the file representing the root page of the settings for this app,
//  invokes loadDefaults:fromSettingsPage:inSettingsBundleAtURL: on it,
//  and registers the loaded values as the app's defaults.
// -------------------------------------------------------------------------------
- (void)populateRegistrationDomain
{
    NSURL *settingsBundleURL = [[NSBundle mainBundle] URLForResource:@"Settings" withExtension:@"bundle"];
    
    // loadDefaults:fromSettingsPage:inSettingsBundleAtURL: expects its caller
    // to pass it an initialized NSMutableDictionary.
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    
    // Invoke loadDefaults:fromSettingsPage:inSettingsBundleAtURL: on the property
    // list file for the root settings page (always named Root.plist).
    [self loadDefaults:appDefaults fromSettingsPage:@"Root.plist" inSettingsBundleAtURL:settingsBundleURL];
    
    // appDefaults is now populated with the preferences and their default values.
    // Add these to the registration domain.
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// -------------------------------------------------------------------------------
//  loadDefaults:fromSettingsPage:inSettingsBundleAtURL:
//  Helper function that parses a Settings page file, extracts each preference
//  defined within along with its default value, and adds it to a mutable
//  dictionary.  If the page contains a 'Child Pane Element', this method will
//  recurs on the referenced page file.
// -------------------------------------------------------------------------------
- (void)loadDefaults:(NSMutableDictionary*)appDefaults fromSettingsPage:(NSString*)plistName inSettingsBundleAtURL:(NSURL*)settingsBundleURL
{
    // Each page of settings is represented by a property-list file that follows
    // the Settings Application Schema:
    // <https://developer.apple.com/library/ios/#documentation/PreferenceSettings/Conceptual/SettingsApplicationSchemaReference/Introduction/Introduction.html>.
    
    // Create an NSDictionary from the plist file.
    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfURL:[settingsBundleURL URLByAppendingPathComponent:plistName]];
    
    // The elements defined in a settings page are contained within an array
    // that is associated with the root-level PreferenceSpecifiers key.
    NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];
    
    for (NSDictionary *prefItem in prefSpecifierArray)
        // Each element is itself a dictionary.
    {
        // What kind of control is used to represent the preference element in the
        // Settings app.
        NSString *prefItemType = prefItem[@"Type"];
        // How this preference element maps to the defaults database for the app.
        NSString *prefItemKey = prefItem[@"Key"];
        // The default value for the preference key.
        NSString *prefItemDefaultValue = prefItem[@"DefaultValue"];
        
        if ([prefItemType isEqualToString:@"PSChildPaneSpecifier"])
            // If this is a 'Child Pane Element'.  That is, a reference to another
            // page.
        {
            // There must be a value associated with the 'File' key in this preference
            // element's dictionary.  Its value is the name of the plist file in the
            // Settings bundle for the referenced page.
            NSString *prefItemFile = prefItem[@"File"];
            
            // Recurs on the referenced page.
            [self loadDefaults:appDefaults fromSettingsPage:prefItemFile inSettingsBundleAtURL:settingsBundleURL];
        }
        else if (prefItemKey != nil && prefItemDefaultValue != nil)
            // Some elements, such as 'Group' or 'Text Field' elements do not contain
            // a key and default value.  Skip those.
        {
            [appDefaults setObject:prefItemDefaultValue forKey:prefItemKey];
        }
    }
}

@end
