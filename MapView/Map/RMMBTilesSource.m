//
//  RMMBTilesSource.m
//
//  Created by Justin R. Miller on 6/18/10.
//  Copyright 2012 MapBox.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//  
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//      * Neither the name of MapBox, nor the names of its contributors may be
//        used to endorse or promote products derived from this software
//        without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "RMMBTilesSource.h"
#import "RMTileImage.h"
#import "RMProjection.h"
#import "RMFractalTileProjection.h"

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@implementation RMMBTilesSource {
  RMFractalTileProjection *_tileProjection;
  FMDatabaseQueue *_queue;
}

+ (BOOL)isValidRMMBTilesSourceAtPath:(NSString *)path {
  BOOL valid  = NO;
  BOOL isDir  = NO;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
  
  if (exists == YES && isDir == NO) {
    RMMBTilesSource *mapSource = [[[RMMBTilesSource alloc] initWithPath:path] autorelease];
    
    valid = [mapSource isValid];
  }
  
  return valid;
}

- (id)initWithPath:(NSString *)path {
	if ( ! (self = [super init]))
		return nil;

	_tileProjection = [[RMFractalTileProjection alloc] initFromProjection:[self projection]
                                                         tileSideLength:kMBTilesDefaultTileSize
                                                                maxZoom:kMBTilesDefaultMaxTileZoom
                                                                minZoom:kMBTilesDefaultMinTileZoom];

    _queue = [[FMDatabaseQueue databaseQueueWithPath:path] retain];

    if ( ! _queue)
        return nil;

    [_queue inDatabase:^(FMDatabase *db) {
        [db setShouldCacheStatements:YES];
    }];

	return self;
}

- (void)dealloc
{
  [_tileProjection release]; _tileProjection = nil;
  [_queue release]; _queue = nil;
  [_attributionImageName release]; _attributionImageName = nil;
  [_attributionImageURL release]; _attributionImageURL = nil;
  
  [super dealloc];
}

@synthesize attributionImageName = _attributionImageName, attributionImageURL = _attributionImageURL;

- (void)cancelAllDownloads {
  // no-op
}

- (NSUInteger)tileSideLength
{
    return _tileProjection.tileSideLength;
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache {
  NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
      @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f", 
      self, tile.zoom, self.minZoom, self.maxZoom);

  NSInteger zoom = tile.zoom;
  NSInteger x    = tile.x;
  NSInteger y    = pow(2, zoom) - tile.y - 1;

  __block UIImage *image = nil;

  [_queue inDatabase:^(FMDatabase *db) {
    FMResultSet *results = [db executeQuery:@"select tile_data from tiles where zoom_level = ? and tile_column = ? and tile_row = ?",
                            [NSNumber numberWithShort:zoom],
                            [NSNumber numberWithUnsignedInt:x],
                            [NSNumber numberWithUnsignedInt:y]];

    if ([db hadError]) {
      image = [RMTileImage errorTile];
    }
    else {
      if ([results next] == NO) {
        image = [RMTileImage errorTile];
      }
      else {
        NSData *data = [results dataForColumn:@"tile_data"];

        if (!data)
          image = [RMTileImage errorTile];
        else
          image = [UIImage imageWithData:data];
      }
      
      [results close];
    }
  }];

  return image;
}

- (BOOL)tileSourceHasTile:(RMTile)tile
{
    return YES;
}

- (NSString *)tileURL:(RMTile)tile
{
    return nil;
}

- (NSString *)tileFile:(RMTile)tile
{
    return nil;
}

- (NSString *)tilePath
{
    return nil;
}

- (RMFractalTileProjection *)mercatorToTileProjection
{
	return _tileProjection;
}

- (RMProjection *)projection
{
	return [RMProjection googleProjection];
}

- (float)minZoom
{
    __block double minZoom;

    [_queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select min(zoom_level) from tiles"];

        if ([db hadError])
            minZoom = kMBTilesDefaultMinTileZoom;

        [results next];

        minZoom = [results doubleForColumnIndex:0];

        [results close];
    }];

    return minZoom;
}

- (float)maxZoom
{
    __block double maxZoom;

    [_queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select max(zoom_level) from tiles"];

        if ([db hadError])
            maxZoom = kMBTilesDefaultMaxTileZoom;

        [results next];

        maxZoom = [results doubleForColumnIndex:0];

        [results close];
    }];

    return maxZoom;
}

- (void)setMinZoom:(float)aMinZoom
{
    [_tileProjection setMinZoom:aMinZoom];
}

- (void)setMaxZoom:(float)aMaxZoom
{
    [_tileProjection setMaxZoom:aMaxZoom];
}

#define kDefaultLatLonBoundingBox ((RMSphericalTrapezium){.northEast = {.latitude = 90.0, .longitude = 180.0}, .southWest = {.latitude = -90.0, .longitude = -180.0}})

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    return kDefaultLatLonBoundingBox;
}

- (CLLocationCoordinate2D)centerCoordinate
{
    __block CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(0, 0);

    [_queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'center'"];

        [results next];

        if ([results stringForColumn:@"value"] && [[[results stringForColumn:@"value"] componentsSeparatedByString:@","] count] >= 2)
            centerCoordinate = CLLocationCoordinate2DMake([[[[results stringForColumn:@"value"] componentsSeparatedByString:@","] objectAtIndex:1] doubleValue],
                                                          [[[[results stringForColumn:@"value"] componentsSeparatedByString:@","] objectAtIndex:0] doubleValue]);

        [results close];
    }];
    
    return centerCoordinate;
}

- (float)centerZoom
{
    __block CGFloat centerZoom = [self minZoom];

    [_queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'center'"];

        [results next];

        if ([results stringForColumn:@"value"] && [[[results stringForColumn:@"value"] componentsSeparatedByString:@","] count] >= 3)
            centerZoom = [[[[results stringForColumn:@"value"] componentsSeparatedByString:@","] objectAtIndex:2] floatValue];

         [results close];
     }];
    
    return centerZoom;
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"*** didReceiveMemoryWarning in %@", [self class]);
}

- (NSString *)uniqueTilecacheKey
{
    return [NSString stringWithFormat:@"MBTiles%@", [_queue.path lastPathComponent]];
}

- (NSString *)shortName
{
    __block NSString *shortName = nil;

    [_queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'name'"];

        if ([db hadError])
            shortName = nil;

        [results next];

        shortName = [results stringForColumnIndex:0];

        [results close];
    }];

    return shortName;
}

- (NSString *)longDescription
{
    __block NSString *description = nil;

    [_queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'description'"];

        if ([db hadError])
            description = nil;

        [results next];

        description = [results stringForColumnIndex:0];

        [results close];
    }];

    return [NSString stringWithFormat:@"%@ - %@", [self shortName], description];
}

- (NSString *)shortAttribution
{
    __block NSString *attribution = nil;

    [_queue inDatabase:^(FMDatabase *db)
    {
        FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'attribution'"];

        if ([db hadError])
            attribution = @"Unknown MBTiles attribution";

        [results next];

        attribution = [results stringForColumnIndex:0];

        [results close];
    }];

    return attribution;
}

- (NSString *)longAttribution
{
    return [NSString stringWithFormat:@"%@ - %@", [self shortName], [self shortAttribution]];
}

- (NSString *)copyrightURL {
  return @"";
}

- (BOOL)isValid {
  __block BOOL isValid = NO;
  
  [_queue inDatabase:^(FMDatabase *db)
   {
     FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'bounds'"];
     
     [results next];
     
     NSString *boundsString = [results stringForColumnIndex:0];
     
     [results close];
     
     if (boundsString)
     {
       NSArray *parts = [boundsString componentsSeparatedByString:@","];
       
       if ([parts count] == 4)
       {
         isValid = YES;
       }
     }
   }];

  if (isValid == YES) {
    [_queue inDatabase:^(FMDatabase *db)
     {
       FMResultSet *results = [db executeQuery:@"select count(*) count from tiles"];
       
       [results next];
       
       int count = [results intForColumn:@"count"];
       
       [results close];
       
       if (count <= 0)
         isValid = NO;
     }];
  }
  
  return isValid;
}

@end
