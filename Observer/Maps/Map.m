//
//  Map.m
//  Observer
//
//  Created by Regan Sarwas on 12/5/13.
//  Copyright (c) 2013 GIS Team. All rights reserved.
//

#import "Map.h"
#import "NSDate+Formatting.h"
#import "NSURL+unique.h"
#import "Settings.h"
#import "AKRFormatter.h"

#define kCodingVersion    1
#define kCodingVersionKey @"codingversion"
#define kUrlKey           @"url"
#define kExtentsKey       @"extents"

@interface Map()

@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) NSString *description;
@property (nonatomic, strong, readwrite) NSString *author;
@property (nonatomic, strong, readwrite) NSDate *date;
@property (nonatomic, readwrite) NSUInteger byteCount;
@property (nonatomic, readwrite) AGSEnvelope *extents;
@property (nonatomic, strong, readwrite) NSURL *thumbnailUrl;

@property (nonatomic, strong, readwrite) UIImage *thumbnail;
@property (nonatomic, strong, readwrite) AGSLocalTiledLayer *tileCache;
@property (nonatomic) BOOL thumbnailIsLoaded;
@property (nonatomic) BOOL tileCacheIsLoaded;

@property (nonatomic) BOOL downloading;
//TODO: move to NSOperation
@property (nonatomic, strong) NSURLSessionTask *downloadTask;

@end

@implementation Map

- (id)initWithURL:(NSURL *)url
{
    if (!url) {
        return nil;
    }
    if (self = [super init]) {
        _url = url;
    }
    return self;
}

- (id)initWithLocalTileCache:(NSURL *)url
{
    Map *map = [self initWithURL:url];
    if (map) {
        if (!map.tileCache) {
            return nil;
        }
        if (map.tileCache.name && ![map.tileCache.name isEqualToString:@""]) {
            map.title = map.tileCache.name;
        } else {
            map.title = [[url lastPathComponent] stringByDeletingPathExtension];
        }
        map.author = @"Unknown"; //TODO: get the author from the esriinfo.xml file in the zipped tpk
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:nil];
        map.byteCount = [fileAttributes fileSize];
        map.date = [fileAttributes fileCreationDate];  //TODO: Get the date from the esriinfo.xml file in the zipped tpk
        map.description = @"Not available."; //TODO: get the description from the esriinfo.xml file in the zipped tpk
        map.thumbnailUrl = [self thumbnailUrlForMapName:map.title];
        [UIImagePNGRepresentation(map.tileCache.thumbnail) writeToURL:map.thumbnailUrl atomically:YES];
        map.thumbnail = map.tileCache.thumbnail;
        map.thumbnailIsLoaded = YES;
        map.extents = map.tileCache.fullEnvelope;
        //exclude map from being backed up to iCloud/iTunes
        [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
    return map;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    id item = dictionary[kUrlKey];
    NSURL *url;
    if ([item isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:item];
    }
    if (!url) {
        return nil;
    }
    Map *map = [self initWithURL:url];
    if (map) {
        item = dictionary[kTitleKey];
        map.title = ([item isKindOfClass:[NSString class]] ? item : nil);
        item = dictionary[kDateKey];
        map.date = [item isKindOfClass:[NSDate class]] ? item : ([item isKindOfClass:[NSString class]] ? [AKRFormatter dateFromISOString:item] : nil);
        item = dictionary[kAuthorKey];
        map.author = ([item isKindOfClass:[NSString class]] ? item : nil);
        item =  dictionary[kSizeKey];
        map.byteCount = [item isKindOfClass:[NSNumber class]] ? [item integerValue] : 0;
        item =  dictionary[kDescriptionKey];
        map.description = [item isKindOfClass:[NSString class]] ? item : nil;
        item =  dictionary[kThumbnailUrlKey];
        map.thumbnailUrl = [item isKindOfClass:[NSString class]] ? [NSURL URLWithString:item] : nil;
        item =  dictionary[kXminKey];
        CGFloat xmin = [item isKindOfClass:[NSNumber class]] ? [item floatValue] : 0.0;
        item =  dictionary[kYminKey];
        CGFloat ymin = [item isKindOfClass:[NSNumber class]] ? [item floatValue] : 0.0;
        item =  dictionary[kXmaxKey];
        CGFloat xmax = [item isKindOfClass:[NSNumber class]] ? [item floatValue] : 0.0;
        item =  dictionary[kYmaxKey];
        CGFloat ymax = [item isKindOfClass:[NSNumber class]] ? [item floatValue] : 0.0;
        if (xmin != 0  || ymin != 0 || xmax != 0 || ymax != 0 ) {
            map.extents = [[AGSEnvelope alloc] initWithXmin:xmin ymin:ymin xmax:xmax ymax:ymax spatialReference:[AGSSpatialReference wgs84SpatialReference]];
        }
    }
    return map;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    int version = [aDecoder decodeIntForKey:kCodingVersionKey];
    switch (version) {
        case 1: {
            Map *map = [self initWithURL:[aDecoder decodeObjectForKey:kUrlKey]];
            if (map) {
                map.title = [aDecoder decodeObjectForKey:kTitleKey];
                map.author = [aDecoder decodeObjectForKey:kAuthorKey];
                map.date = [aDecoder decodeObjectForKey:kDateKey];
                map.description = [aDecoder decodeObjectForKey:kDescriptionKey];
                NSNumber *bytes = [aDecoder decodeObjectForKey:kSizeKey];
                map.byteCount = [bytes unsignedIntegerValue];
                map.thumbnailUrl = [aDecoder decodeObjectForKey:kThumbnailUrlKey];
                map.extents = [[AGSEnvelope alloc] initWithJSON:[aDecoder decodeObjectForKey:kExtentsKey]];
            }
            return map;
        }
        default:
            return nil;
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:kCodingVersion forKey:kCodingVersionKey];
    [aCoder encodeObject:self.url forKey:kUrlKey];
    [aCoder encodeObject:self.title forKey:kTitleKey];
    [aCoder encodeObject:self.author forKey:kAuthorKey];
    [aCoder encodeObject:self.date forKey:kDateKey];
    [aCoder encodeObject:self.description forKey:kDescriptionKey];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:self.byteCount] forKey:kSizeKey];
    [aCoder encodeObject:self.thumbnailUrl forKey:kThumbnailUrlKey];
    [aCoder encodeObject:[self.extents encodeToJSON] forKey:kExtentsKey];
}


#pragma mark - Lazy property initiallizers

#pragma mark - AKRTableViewItem

@synthesize title = _title;

- (NSString *)title
{
    return _title ? _title : @"No Title";
}

- (NSString *)subtitle
{
    return [NSString stringWithFormat:@"Author: %@", self.author];
}

- (NSString *)subtitle2
{
    if (self.downloading) {
        return @"Downloading...";
    } else {
        return [NSString stringWithFormat:@"Date: %@, Size: %@", [self.date stringWithMediumDateFormat], [AKRFormatter stringFromBytes:self.byteCount]];
    }
}

- (void)openThumbnailWithCompletionHandler:(void (^)(BOOL success))completionHandler
{
    dispatch_async(dispatch_queue_create("gov.nps.akr.observer", DISPATCH_QUEUE_CONCURRENT), ^{
        UIImage *thumbnail = self.thumbnail;
        if (completionHandler) {
            completionHandler(thumbnail != nil);
        }
    });
}

- (void)openTileCacheWithCompletionHandler:(void (^)(BOOL success))completionHandler
{
    dispatch_async(dispatch_queue_create("gov.nps.akr.observer", DISPATCH_QUEUE_CONCURRENT), ^{
        AGSLocalTiledLayer *tileCache = self.tileCache;
        if (completionHandler) {
            completionHandler(tileCache != nil);
        }
    });
}

- (UIImage *)thumbnail
{
    if (!_thumbnail && !self.thumbnailIsLoaded) {
        [self loadThumbnail];
    }
    return _thumbnail;
}

- (AGSLocalTiledLayer *)tileCache
{
    if (!_tileCache && !self.tileCacheIsLoaded) {
        [self loadTileCache];
    }
    return _tileCache;
}


#pragma mark - public methods

- (BOOL)isEqualToMap:(Map *)other
{
    // need to be careful with null properties.
    // without the == check, two null properties will be not equal
    if (!other) {
        return NO;
    }
    return
        (self.byteCount == other.byteCount) &&
        ((self.author == other.author) || [self.author isEqual:other.author]) &&
        ((self.date == other.date) || [self.date isEqual:other.date]);
}

- (BOOL) isValid
{
    return !self.isLocal || self.tileCache != nil;
}

- (BOOL)isLocal
{
    return self.url.isFileURL;
}

- (AKRAngleDistance *)angleDistanceFromLocation:(CLLocation *)location
{
    return [AKRAngleDistance angleDistanceFromLocation:location toGeometry:self.extents];
}

- (double)areaInKilometers
{
    if (!self.extents || self.extents.isEmpty) {
        return -1;
    }
    return [[AGSGeometryEngine defaultGeometryEngine] shapePreservingAreaOfGeometry:self.extents inUnit:AGSAreaUnitsSquareKilometers];
}

- (void)prepareToDownload
{
    self.downloading = YES;
}

- (BOOL)isDownloading
{
    return self.downloading;
}


#pragma mark - loaders

- (BOOL)loadThumbnail
{
    //TODO: cache network thumbnails, then update the object cache with the cached url
    self.thumbnailIsLoaded = YES;
    NSData *data = [NSData dataWithContentsOfURL:self.thumbnailUrl];
    //    if (![self.thumbnailUrl isFileReferenceURL]) {
    //        NSString *name = [[self.thumbnailUrl lastPathComponent] stringByDeletingPathExtension];
    //        NSURL *newUrl = [self thumbnailUrlForMapName:name];
    //        if ([data writeToURL:newUrl atomically:YES]) {
    //            self.thumbnailUrl = newUrl;
    //        }
    //    }
    //TODO: let the collection know we need to update the cache;
    _thumbnail = [[UIImage alloc] initWithData:data];
    if (!_thumbnail)
        _thumbnail = [UIImage imageNamed:@"TilePackage"];
    return !_thumbnail;
}

- (NSURL *)thumbnailUrlForMapName:(NSString *)name
{
    NSURL *library = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *folder = [library URLByAppendingPathComponent:@"mapthumbs" isDirectory:YES];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[folder path]]) {
        [[NSFileManager defaultManager] createDirectoryAtURL:folder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSURL *thumb = [[[folder URLByAppendingPathComponent:name] URLByAppendingPathExtension:@"png"] URLByUniquingPath];
    return thumb;
}

- (BOOL)loadTileCache
{
    self.tileCacheIsLoaded = YES;
    @try {
        //The AGS tile cache loader uses C++ exceptions for error handling.
        _tileCache = [[AGSLocalTiledLayer alloc] initWithPath:[self.url path]];
    }
    @catch (NSException *exception) {
        _tileCache = nil;
    }
    return _tileCache != nil;
}


#pragma mark - download
//TODO: move this to a NSOperation

- (NSURLSession *)session
{

    static NSURLSession *backgroundSession = nil;
    
    if (!_session) {
        NSURLSessionConfiguration *configuration;
        if (self.isBackground) {
            if (!backgroundSession) {
                configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"gov.nps.observer.BackgroundDownloadSession"];
                backgroundSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
            }
            _session = backgroundSession;
        } else {
            configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        }
    }
    return _session;
}

- (void)startDownload
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    self.downloadTask = [self.session downloadTaskWithRequest:request];
    self.downloading = YES;
    [self.downloadTask resume];
}

- (void)stopDownload
{
    [self.downloadTask cancel];
    self.downloading = NO;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    //TODO: implement method to support resume download (for pause or lost connection)
    AKRLog(@"did resume download");
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (downloadTask == self.downloadTask && self.progressAction){
        self.progressAction((double)totalBytesWritten, (double)totalBytesExpectedToWrite);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    self.downloading = NO;
    if (downloadTask.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (!self.destinationURL) {
        NSURL *documentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
        NSURL *originalURL = downloadTask.originalRequest.URL;
        self.destinationURL = [documentsDirectory URLByAppendingPathComponent:originalURL.lastPathComponent];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.destinationURL path]]) {
        if (self.canReplace) {
            [fileManager removeItemAtURL:self.destinationURL error:NULL];
        } else {
            self.destinationURL = [self.destinationURL URLByUniquingPath];
        }
    }
    BOOL success = [fileManager copyItemAtURL:location toURL:self.destinationURL error:nil];
    if (success) {
        self.url = self.destinationURL;
    }
    if (self.completionAction){
        self.completionAction(self.url, success);
    }
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ by %@, dated: %@", self.title, self.author, [self.date stringWithMediumDateFormat]];
}

@end
