//
//  RMArcGisMapSource.m
//
// Copyright (c) 2008-2014, Route-Me Contributors
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

#import "RMArcGisMapSource.h"

@interface RMArcGisMapSource()

@property (nonatomic, assign) RMArcGISMapType mapType;

@end

@implementation RMArcGisMapSource

#pragma mark -
#pragma mark memory management

- (id)initWithMapType:(RMArcGISMapType)aMapType {
	if (!(self = [super init]))
    return nil;
  
  self.minZoom = 1;
  self.maxZoom = 18;
  self.mapType = aMapType;
  
	return self;
}

#pragma mark -
#pragma mark properties

@synthesize mapType;

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
  
  NSString *url = nil;
  
  switch (self.mapType) {
    case kRMArcGISUSATopo:
      url = [NSString stringWithFormat:@"http://services.arcgisonline.com/ArcGIS/rest/services/USA_Topo_Maps/MapServer/tile/%d/%d/%d.png", tile.zoom, tile.y, tile.x];
      break;
    case kRMArcGISWorldTopo:
      url = [NSString stringWithFormat:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/%d/%d/%d.png", tile.zoom, tile.y, tile.x];
      break;
    case kRMArcGISWorldImagery:
      url = [NSString stringWithFormat:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/%d/%d/%d.png", tile.zoom, tile.y, tile.x];
      break;
    case kRMArcGISWorldStreetMap:
      url = [NSString stringWithFormat:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/%d/%d/%d.png", tile.zoom, tile.y, tile.x];
      break;
    case kRMArcGISNationalGeographicMap:
      url = [NSString stringWithFormat:@"http://services.arcgisonline.com/ArcGIS/rest/services/NatGeo_World_Map/MapServer/tile/%d/%d/%d.png", tile.zoom, tile.y, tile.x];
      break;
    case kRMArcGISWorldNavigationCharts:
      url = [NSString stringWithFormat:@"http://services.arcgisonline.com/ArcGIS/rest/services/Specialty/World_Navigation_Charts/MapServer/tile/%d/%d/%d.png", tile.zoom, tile.y, tile.x];
      break;
  }
  
  return [NSURL URLWithString:url];
}

#pragma mark -
#pragma mark RMTileSource methods implementation

- (NSString *)uniqueTilecacheKey {
	return [NSString stringWithFormat:@"ArcGIS%@", [self mapTypeString]];
}

- (NSString *)shortName {
  NSString *string = nil;
  
  switch (self.mapType) {
    case kRMArcGISUSATopo:
      string = NSLocalizedString(@"ArcGIS USA Topo Maps", @"");
      break;
    case kRMArcGISWorldTopo:
      string = NSLocalizedString(@"ArcGIS World Topo Maps", @"");
      break;
    case kRMArcGISWorldImagery:
      string = NSLocalizedString(@"ArcGIS World Imagery", @"");
      break;
    case kRMArcGISWorldStreetMap:
      string = NSLocalizedString(@"ArcGIS World Street Map", @"");
      break;
    case kRMArcGISNationalGeographicMap:
      string = NSLocalizedString(@"ArcGIS National Geographic Map", @"");
      break;
    case kRMArcGISWorldNavigationCharts:
      string = NSLocalizedString(@"ArcGIS World Navigation Charts", @"");
      break;
  }
  
  return string;
}

- (NSString *)longDescription {
	return [self shortName];
}

- (NSString *)shortAttribution {
	return @"ArcGIS";
}

- (NSString *)longAttribution {
	return [self shortAttribution];
}

- (NSString *)copyrightURL {
  return @"https://www.arcgis.com/";
}

#pragma mark -
#pragma mark internal utility methods

- (NSString *)mapTypeString {
  NSString *string = nil;
  
  switch (self.mapType) {
    case kRMArcGISUSATopo:
      string = @"USATopo";
      break;
    case kRMArcGISWorldTopo:
      string = @"WorldTopo";
      break;
    case kRMArcGISWorldImagery:
      string = @"WorldImagery";
      break;
    case kRMArcGISWorldStreetMap:
      string = @"WorldStreetMap";
      break;
    case kRMArcGISNationalGeographicMap:
      string = @"NationalGeographicMap";
      break;
    case kRMArcGISWorldNavigationCharts:
      string = @"WorldNavigationCharts";
      break;
  }
  
  return string;
}

@end
