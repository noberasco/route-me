//
//  OpenCycleMapSource.m
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

#import "RMOpenCycleMapLandscapeSource.h"

@implementation RMOpenCycleMapLandscapeSource {
  BOOL addHillshadeLayer;
}

@synthesize addHillshadeLayer;

- (id)init
{
	if (!(self = [super init]))
        return nil;

    self.minZoom = 1;
    self.maxZoom = 15;

	return self;
} 

- (NSArray *)URLsForTile:(RMTile)tile {
	NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
            @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
            self, tile.zoom, self.minZoom, self.maxZoom);
  
  NSMutableArray *array = [NSMutableArray array];
  
  [array addObject:[NSURL URLWithString:[NSString stringWithFormat:@"http://tile3.opencyclemap.org/landscape/%d/%d/%d.png", tile.zoom, tile.x, tile.y]]];
  
  if (addHillshadeLayer) {
    [array addObject:[NSURL URLWithString:[NSString stringWithFormat:@"http://129.206.74.245:8004/tms_hs.ashx?x=%d&y=%d&z=%d", tile.x, tile.y, tile.zoom]]];
    
    RMLog(@"WARNING: check licensing for hillshadeLayer: http://openmapsurfer.uni-hd.de/contact.html");
  }
  
  return array;
}

- (NSString *)uniqueTilecacheKey
{
	return @"OpenCycleMapLandscape";
}

- (NSString *)shortName
{
	return @"Open Cycle Map Landscape";
}

- (NSString *)longDescription
{
	return @"The world is full of interesting features beyond roads and houses. The landscape layer emphasises natural features and is a perfect display for those interested in nature, the countryside, and life beyond the city.";
}

- (NSString *)shortAttribution
{
	return @"© OpenCycleMap CC-BY-SA";
}

- (NSString *)longAttribution
{
	return @"Map data © OpenCycleMap, licensed under Creative Commons Share Alike By Attribution.";
}

- (NSString *)copyrightURL
{
  return @"http://www.opencyclemap.org";
}

@end
