//
//  SurveyObjectModel.m
//  Observer
//
//  Created by Regan Sarwas on 12/5/13.
//  Copyright (c) 2013 GIS Team. All rights reserved.
//

#import "SurveyObjectModel.h"
#import "ObserverModel.h"

@implementation SurveyObjectModel

+ (NSManagedObjectModel *)objectModelWithProtocol:(SProtocol *)protocol
{
    NSAssert(protocol,@"protocol must be non-null");
    NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:nil];
    if (mom) {
        mom = [self mergeMom:mom missionAttributes:protocol.missionFeature.attributes];
        for (ProtocolFeature *feature in protocol.features) {
            mom = [self mergeMom:mom featureName:feature.name attributes:feature.attributes];
        }
    }
    return mom;
}

+ (NSManagedObjectModel *) mergeMom:(NSManagedObjectModel *)mom missionAttributes:(NSArray *)attributes
{
    NSEntityDescription *entity = [[mom entitiesByName] valueForKey:kMissionPropertyEntityName];
    NSMutableArray *attributeProperties = [NSMutableArray arrayWithArray:entity.properties];
    [attributeProperties addObjectsFromArray:attributes];
    return mom;
}

+ (NSManagedObjectModel *) mergeMom:(NSManagedObjectModel *)mom featureName:(NSString *)name attributes:(NSArray *)attributes
{
    NSEntityDescription *entity;
    NSMutableArray *attributeProperties;
    if ([name isEqualToString:kMissionPropertyEntityName] || [name isEqualToString:kObservationEntityName]) {
        entity = [[mom entitiesByName] valueForKey:name];
        attributeProperties = [NSMutableArray arrayWithArray:entity.properties];
    } else {
        NSEntityDescription *observation = [[mom entitiesByName] valueForKey:kObservationEntityName];
        entity = [[NSEntityDescription alloc] init];
        entity.name = name;
        observation.subentities = [[observation subentities] arrayByAddingObject:entity];
        mom.entities = [[mom entities] arrayByAddingObject:entity];
        attributeProperties = [NSMutableArray new];
    }
    for (id obj in attributes) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *attribute = (NSDictionary *)obj;
            NSAttributeDescription *attributeDescription = [[NSAttributeDescription alloc] init];
            [attributeProperties addObject:attributeDescription];
            //TODO: Check that unexpected values in an attribute dictionary does not cause a failure
            [attributeDescription setName:attribute[@"name"]];
            [attributeDescription setAttributeType:[attribute[@"type"] unsignedIntegerValue]];
            [attributeDescription setOptional:![attribute[@"required"] boolValue]];
            [attributeDescription setDefaultValue:attribute[@"default"]];
            NSArray *constraints = attribute[@"constraints"];
            if (constraints)
            {
                NSMutableArray *predicates = [[NSMutableArray alloc] init];
                NSMutableArray *warnings = [[NSMutableArray alloc] init];
                for (NSDictionary *constraint in constraints) {
                    [predicates addObject:[NSPredicate predicateWithFormat:constraint[@"predicate"]]];
                    [warnings addObject:constraint[@"warning"]];
                    [attributeDescription setValidationPredicates:predicates
                                           withValidationWarnings:warnings];
                }
            }
        }
    }
    [entity setProperties:attributeProperties];
    return mom;
}

@end
