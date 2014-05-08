//
//  RMGroundOverlayMapSource.m
//  MapView
//
//  Created by thorin on 08/05/14.
//
//

#import "RMGroundOverlayMapSource.h"

@interface RMGroundOverlayMapSource ()

@property(nonatomic, retain) NSDictionary *params;

@end

@implementation RMGroundOverlayMapSource {
@private
  NSDictionary *params;
}

#pragma mark -
#pragma mark memory management

- (id)initWithParameters:(NSDictionary *)someParams {
  if (!(self = [super init]))
    return nil;
  
  NSAssert(someParams != nil, @"Empty params parameter not allowed");
  
  self.params  = someParams;
  self.minZoom = 1;
  self.maxZoom = 19;
  
  return self;
}

- (void)dealloc {
  [params release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark properties

@synthesize params;

- (NSString *)zipFileName {
  return [self.params objectForKey:kZipFileName];
}

- (NSArray *)groundOverlays {
  return [self.params objectForKey:kGroundOverlays];
}

#pragma mark -
#pragma mark RMAbstractWebMapSource methods implementation

- (NSURL *)URLForTile:(RMTile)tile {
  return nil;
}

#pragma mark -
#pragma mark RMTileSource methods implementation

- (NSString *)uniqueTilecacheKey {
  return @"";
}

- (NSString *)shortName {
  return @"";
}

- (NSString *)longDescription {
	return @"";
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
