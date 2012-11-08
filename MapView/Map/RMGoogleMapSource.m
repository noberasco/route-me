//
//  RMGoogleMapSource.m
//
// Copyright (c) 2008-2012, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RMGoogleMapSource.h"

@interface RMGoogleMapSource()

@property (nonatomic, assign  ) RMGoogleMapType         mapType;
@property (nonatomic, retain  ) NSString               *accessKey;
@property (nonatomic, readonly) NSInteger               tileWidth;
@property (nonatomic, readonly) NSInteger               tileHeight;
@property (nonatomic, assign  ) CLLocationCoordinate2D  center;

@end

@implementation RMGoogleMapSource {
  NSString               *accessKey;
  CLLocationCoordinate2D  center;
}

#pragma mark -
#pragma mark memory management

- (id)initWithMapType:(RMGoogleMapType)aMapType usingAccessKey:(NSString *)developerAccessKey {
	if (!(self = [super init]))
    return nil;
  
  self.minZoom   = 1;
  self.maxZoom   = 18;
  self.mapType   = aMapType;
  self.accessKey = developerAccessKey;
  self.center    = CLLocationCoordinate2DMake(0.0, 0.0);
  
	return self;
}

- (void)dealloc {
  [accessKey release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark properties

@synthesize accessKey;
@synthesize mapType;
@synthesize center;

- (NSInteger)tileWidth {
  return kDefaultTileSize;
}

- (NSInteger)tileHeight {
  return kDefaultTileSize;
}

#pragma mark -
#pragma mark RMAbstractWebMapSource methods implementation

- (NSURL *)URLForTile:(RMTile)tile {
	NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
            @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
            self, tile.zoom, self.minZoom, self.maxZoom);
  
  CLLocationCoordinate2D  coords = [self centerCoordinatesForTile:tile];
  NSString               *type   = [self mapTypeString];
  int                     width  = self.tileWidth;
  int                     height = self.tileHeight;
  int                     scale  = 1;
  int                     zoom   = tile.zoom;
  
  //special parameters for retina devices
  if ([[UIScreen mainScreen] scale] == 2.0) {
    width  /= 2;
    height /= 2;
    scale  *= 2;
    zoom   -= 1;
  }
  
  NSString *url = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/staticmap?center=%f,%f&zoom=%d&size=%dx%d&scale=%d&maptype=%@&sensor=true&key=%@", coords.latitude, coords.longitude, zoom, width, height, scale, type, accessKey];
  
//  NSLog(@"%@", url);
  
  return [NSURL URLWithString:url];
}

#pragma mark -
#pragma mark RMTileSource methods implementation

- (NSString *)uniqueTilecacheKey {
	return [NSString stringWithFormat:@"GoogleMap%@", [self mapTypeString]];
}

-(NSString *)shortName {
  NSString *string = nil;
  
  switch (self.mapType) {
    case kRMGoogleMapTypeRoad:
      string = @"Google Road";
      break;
    case kRMGoogleMapTypeSatellite:
      string = @"Google Satellite";
      break;
    case kRMGoogleMapTypeHybrid:
      string = @"Google Hybrid";
      break;
    case kRMGoogleMapTypeTerrain:
      string = @"Google Terrain";
      break;
  }
  
  return string;
}

- (NSString *)longDescription {
	return [self shortName];
}

- (NSString *)shortAttribution {
	return @"GOOGLE";
}

- (NSString *)longAttribution {
	return [self shortAttribution];
}

- (NSString *)copyrightURL {
  return [NSString stringWithFormat:@"http://maps.google.com?q=%f,%f&t=%@", self.center.latitude, self.center.longitude, self.mapTypeQueryString];
}

#pragma mark -
#pragma mark internal utility methods

- (CLLocationCoordinate2D)nwCoordinateForTile:(RMTile)tile {
  double            n         = M_PI - 2.0 * M_PI * tile.y / pow(2.0, tile.zoom);
	CLLocationDegrees latitude  = 180.0 / M_PI * atan(0.5 * (exp(n) - exp(-n)));
  CLLocationDegrees longitude = tile.x / pow(2.0, tile.zoom) * 360.0 - 180;
  
  return CLLocationCoordinate2DMake(latitude, longitude);
}

- (CLLocationCoordinate2D)centerCoordinatesForTile:(RMTile)tile {
  CLLocationCoordinate2D northWest = [self nwCoordinateForTile:tile];
  CLLocationCoordinate2D southEast = [self nwCoordinateForTile:RMTileMake(tile.x + 1, tile.y + 1, tile.zoom)];
  CLLocationDegrees      latitude  = (northWest.latitude  + southEast.latitude ) / 2.0;
  CLLocationDegrees      longitude = (northWest.longitude + southEast.longitude) / 2.0;
  
  self.center = CLLocationCoordinate2DMake(latitude, longitude);
  
  return center;
}

- (NSString *)mapTypeString {
  NSString *string = nil;
  
  switch (self.mapType) {
    case kRMGoogleMapTypeRoad:
      string = @"roadmap";
      break;
    case kRMGoogleMapTypeSatellite:
      string = @"satellite";
      break;
    case kRMGoogleMapTypeHybrid:
      string = @"hybrid";
      break;
    case kRMGoogleMapTypeTerrain:
      string = @"terrain";
      break;
  }
  
  return string;
}

- (NSString *)mapTypeQueryString {
  NSString *string = nil;
  
  switch (mapType) {
    case kRMGoogleMapTypeRoad:
      string = @"m";
      break;
    case kRMGoogleMapTypeSatellite:
      string = @"k";
      break;
    case kRMGoogleMapTypeHybrid:
      string = @"h";
      break;
    case kRMGoogleMapTypeTerrain:
      string = @"p";
      break;
  }

  return string;
}

@end
