//
//  RMCalTopoMapSource.m
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

#import "RMCalTopoMapSource.h"

@interface RMCalTopoMapSource()

@property (nonatomic, assign) RMCalTopoMapType mapType;

@end

@implementation RMCalTopoMapSource

#pragma mark -
#pragma mark memory management

- (id)initWithMapType:(RMCalTopoMapType)aMapType {
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
    case kRMCalTopoUSTopo:
      url = [NSString stringWithFormat:@"http://s3-us-west-1.amazonaws.com/caltopo/topo/%d/%d/%d.png", tile.zoom, tile.x, tile.y];
      break;
    case kRMCalTopoUSTopo1930:
      url = [NSString stringWithFormat:@"http://s3-us-west-1.amazonaws.com/ctfun/1930/%d/%d/%d.png", tile.zoom, tile.x, tile.y];
      break;
  }
  
  return [NSURL URLWithString:url];
}

#pragma mark -
#pragma mark RMTileSource methods implementation

- (NSString *)uniqueTilecacheKey {
	return [NSString stringWithFormat:@"CalTopo%@", [self mapTypeString]];
}

- (NSString *)shortName {
  NSString *string = nil;
  
  switch (self.mapType) {
    case kRMCalTopoUSTopo:
      string = NSLocalizedString(@"CalTopo US Topo", @"");
      break;
    case kRMCalTopoUSTopo1930:
      string = NSLocalizedString(@"CalTopo US Topo 1930", @"");
      break;
  }
  
  return string;
}

- (NSString *)longDescription {
	return [self shortName];
}

- (NSString *)shortAttribution {
	return @"CalTopo";
}

- (NSString *)longAttribution {
	return [self shortAttribution];
}

- (NSString *)copyrightURL {
  return @"http://caltopo.com/";
}

#pragma mark -
#pragma mark internal utility methods

- (NSString *)mapTypeString {
  NSString *string = nil;
  
  switch (self.mapType) {
    case kRMCalTopoUSTopo:
      string = @"USTopo";
      break;
    case kRMCalTopoUSTopo1930:
      string = @"USTopo1930";
      break;
  }
  
  return string;
}

@end