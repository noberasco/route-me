//
//  RMOpenSeaMapSource.m
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

#import "RMTopOSMUSAMapSource.h"

@implementation RMTopOSMUSAMapSource

- (id)init
{
	if (!(self = [super init]))
        return nil;

    self.minZoom = 5;
    self.maxZoom = 14;

	return self;
}

- (NSArray *)URLsForTile:(RMTile)tile
{
	NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
			  @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
			  self, tile.zoom, self.minZoom, self.maxZoom);

	return [NSArray arrayWithObjects:
          [NSURL URLWithString:[NSString stringWithFormat:@"http://tile.stamen.com/toposm-color-relief/%d/%d/%d.png", tile.zoom, tile.x, tile.y]],
          [NSURL URLWithString:[NSString stringWithFormat:@"http://tile.stamen.com/toposm-contours/%d/%d/%d.png", tile.zoom, tile.x, tile.y]],
          [NSURL URLWithString:[NSString stringWithFormat:@"http://tile.stamen.com/toposm-features/%d/%d/%d.png", tile.zoom, tile.x, tile.y]],
            nil];
}

- (NSString *)uniqueTilecacheKey
{
	return @"TopOSMUSA";
}

- (NSString *)shortName
{
	return NSLocalizedString(@"TopOSM USA", @"");
}

- (NSString *)longDescription
{
	return @"TopOSM is an OpenStreetMap-based topographic map, similar in style to the USGS and National Geographic topographic maps and (to some degree) Google Maps in \"Terrain\" mode.";
}

- (NSString *)shortAttribution
{
	return @"© OpenStreetMap-USGS CC-BY-SA";
}

- (NSString *)longAttribution
{
	return @"Map by Lars Ahlzen • License: CC-BY-SA • Data from OpenStreetMap and USGS • Tiles hosted by Stamen";
}

- (NSString *)copyrightURL
{
  return @"http://toposm.com/us";
}

@end
