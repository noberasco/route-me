//
//  RMAbstractMercatorTileSource.m
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

#import "RMAbstractMercatorTileSource.h"
#import "RMTileImage.h"
#import "RMFractalTileProjection.h"
#import "RMProjection.h"

@implementation RMAbstractMercatorTileSource
{
    RMFractalTileProjection *_tileProjection;
    NSString *_attributionImageName;
    NSString *_attributionImageURL;
#ifdef __IPHONE_7_0
    RMTileCache *_tileCache;
#endif
}

@synthesize minZoom = _minZoom, maxZoom = _maxZoom, attributionImageName = _attributionImageName, attributionImageURL = _attributionImageURL;

#ifdef __IPHONE_7_0
- (NSInteger)minimumZ {
  return (NSInteger)_minZoom;
}

- (void)setMinimumZ:(NSInteger)minimumZ {
  _minZoom = (float)minimumZ;
}

- (NSInteger)maximumZ {
  return (NSInteger)_maxZoom;
}

- (void)setMaximumZ:(NSInteger)maximumZ {
  _maxZoom = (float)maximumZ;
}

- (CGSize)tileSize {
  return CGSizeMake(self.tileSideLength, self.tileSideLength);
}

- (void)setTileSize:(CGSize)tileSize {
  NSAssert(NO, @"this property cannot be set");
}

- (RMTileCache *)tileCache {
  return _tileCache;
}

- (void)setTileCache:(RMTileCache *)tileCache {
  [_tileCache release];
  _tileCache = [tileCache retain];
}
#endif

- (id)init
{
#ifdef __IPHONE_7_0
  self = [super initWithURLTemplate:@""];
#else
  self = [super init];
#endif
  
  if (self == nil)
    return nil;

  _tileProjection = nil;

  // http://wiki.openstreetmap.org/index.php/FAQ#What_is_the_map_scale_for_a_particular_zoom_level_of_the_map.3F
  self.minZoom = kDefaultMinTileZoom;
  self.maxZoom = kDefaultMaxTileZoom;

#ifdef __IPHONE_7_0
  self.canReplaceMapContent = YES;
  self.geometryFlipped      = NO;
  self.tileCache            = nil;
#endif
  
    return self;
}

- (void)dealloc
{
    [_tileProjection release]; _tileProjection = nil;
    [_attributionImageName release]; _attributionImageName = nil;
    [_attributionImageURL release]; _attributionImageURL = nil;
#ifdef __IPHONE_7_0
    [_tileCache release]; _tileCache = nil;
#endif
    [super dealloc];
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    return kDefaultLatLonBoundingBox;
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"imageForTile:inCache: invoked on RMAbstractMercatorTileSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}    

- (void)cancelAllDownloads
{
}

- (RMProjection *)projection
{
    return [RMProjection googleProjection];
}

- (RMFractalTileProjection *)mercatorToTileProjection
{
    if ( ! _tileProjection)
    {
        _tileProjection = [[RMFractalTileProjection alloc] initFromProjection:self.projection
                                                               tileSideLength:self.tileSideLength
                                                                      maxZoom:self.maxZoom
                                                                      minZoom:self.minZoom];
    }

    return [[_tileProjection retain] autorelease];
}

- (void)didReceiveMemoryWarning
{
    LogMethod();
}

#pragma mark -

- (NSUInteger)tileSideLength
{
    return kDefaultTileSize;
}

- (NSString *)uniqueTilecacheKey
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"uniqueTilecacheKey invoked on RMAbstractMercatorTileSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}

- (NSString *)shortName
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"shortName invoked on RMAbstractMercatorTileSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}

- (NSString *)longDescription
{
	return [self shortName];
}

- (NSString *)shortAttribution
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"shortAttribution invoked on RMAbstractMercatorTileSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}

- (NSString *)longAttribution
{
	return [self shortAttribution];
}

- (NSString *)copyrightURL
{
  @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                 reason:@"copyrightURL invoked on RMAbstractMercatorTileSource. Override this method when instantiating an abstract class."
                               userInfo:nil];
}

#ifdef __IPHONE_7_0
- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *tileData, NSError *error))result {
  RMTile   tile     = RMTileMake(path.x, path.y, path.z);
  UIImage *image    = [self imageForTile:tile inCache:self.tileCache];
  NSData  *tileData = UIImagePNGRepresentation(image);
  
  result(tileData, nil);
}
#endif

@end

