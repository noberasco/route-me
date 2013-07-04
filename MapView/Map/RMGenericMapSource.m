//
//  RMGenericMapSource.m
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

#import "RMGenericMapSource.h"

@interface RMGenericMapSource ()

@property(nonatomic, retain) NSString *urlTemplate;

@end

@implementation RMGenericMapSource {
@private
  NSString *urlTemplate;
}

#pragma mark -
#pragma mark memory management

- (id)initWithParameters:(NSDictionary *)params {
  if (!(self = [super init]))
      return nil;

  NSAssert(params != nil, @"Empty params parameter not allowed");

  self.urlTemplate = [params objectForKey:kServerUrlTemplate];
  self.minZoom     = [[params objectForKey:kMinZoom] floatValue];
  self.maxZoom     = [[params objectForKey:kMaxZoom] floatValue];

  return self;
}

- (void)dealloc {
  [urlTemplate release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark properties

@synthesize urlTemplate;

#pragma mark -
#pragma mark RMAbstractWebMapSource methods implementation

- (NSURL *)URLForTile:(RMTile)tile
{
  NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
            @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
            self, tile.zoom, self.minZoom, self.maxZoom);

  NSString *url = [NSString stringWithString:self.urlTemplate];
  
  url = [url stringByReplacingOccurrencesOfString:kXPlaceholder withString:[NSString stringWithFormat:@"%d", tile.x]];
  url = [url stringByReplacingOccurrencesOfString:kYPlaceholder withString:[NSString stringWithFormat:@"%d", tile.y]];
  url = [url stringByReplacingOccurrencesOfString:kZPlaceholder withString:[NSString stringWithFormat:@"%d", tile.zoom]];
  
  //NSLog(@"URL: %@", url);
  
  return [NSURL URLWithString:url];
}

#pragma mark -
#pragma mark RMTileSource methods implementation

- (NSString *)uniqueTilecacheKey {
  return self.urlTemplate;
}

- (NSString *)shortName {
  return @"Generic Map Source";
}

- (NSString *)longDescription {
	return @"Generic Map Source";
}

- (NSString *)shortAttribution {
	return @"";
}

- (NSString *)longAttribution {
	return @"";
}

- (NSString *)copyrightURL {
  return @"";
}

@end
