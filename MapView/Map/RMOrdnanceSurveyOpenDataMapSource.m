//
//  OpenStreetMapsSource.m
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

#import "RMOrdnanceSurveyOpenDataMapSource.h"

@implementation RMOrdnanceSurveyOpenDataMapSource

- (id)init
{
	if (!(self = [super init]))
        return nil;

    self.minZoom = 1;
    self.maxZoom = 16;

	return self;
} 

- (NSURL *)URLForTile:(RMTile)tile
{
	NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
			  @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f", 
			  self, tile.zoom, self.minZoom, self.maxZoom);

  int instance = (tile.x + tile.y) % 5;
  
  return [NSURL URLWithString:[NSString stringWithFormat:@"http://t%d.cz.tileserver.com/osnew/%d/%d/%d.png", instance, tile.zoom, tile.x, tile.y]];
}

- (NSString *)uniqueTilecacheKey
{
	return @"OSOpenDataUK";
}

- (NSString *)shortName
{
	return NSLocalizedString(@"Ordnance Survey OpenData UK", @"");
}

- (NSString *)longDescription
{
	return @"Ordnance Survey makes a number of datasets available free of charge under the terms of an OS OpenData Licence.";
}

- (NSString *)shortAttribution
{
	return @"@ Crown copyright and database right 2010";
}

- (NSString *)longAttribution
{
	return @"Ordnance Survey OpenData @ Crown copyright and database right 2010 Klokan Technologies GmbH";
}

- (NSString *)copyrightURL
{
  return @"http://www.ordnancesurvey.co.uk/oswebsite/opendata";
}

@end