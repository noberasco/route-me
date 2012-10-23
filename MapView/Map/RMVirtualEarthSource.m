//
//  RMVirtualEarthURL.m
//
// Copyright (c) 2008-2009, Route-Me Contributors
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

#import <objc/runtime.h>
#import <objc/message.h>

#import "RMVirtualEarthSource.h"

typedef enum {
  kAuthStatusNotAuthenticated = 0,
  kAuthStatusAuthenticating,
  kAuthStatusAuthenticated

} AuthStatus;

id (*decodeJSONData)(id self, SEL _cmd, NSData *data, NSUInteger opt, NSError **error) = (void*)objc_msgSend;

@interface RMVirtualEarthSource ()

- (void)authenticateWithVirtualEarthServer;
- (NSString *)quadKeyForTile:(RMTile)tile;
- (NSURL    *)urlForQuadKey:(NSString *)quadKey;
- (NSString *)mapSubDomainParameter;
- (NSString *)mapCultureParameter;

@end

@implementation RMVirtualEarthSource {
@private
  RMVirtualEarthMapType  mapType;
	NSString              *accessKey;
  AuthStatus             authStatus;
  NSCondition           *authStatusCondition;
  NSString              *urlTemplate;
  NSArray               *urlSubDomains;
  NSUInteger             urlSubDomainIndex;
  NSString              *culture;
}

#pragma mark -
#pragma mark memory management

- (id)init {
  @throw [NSException exceptionWithName:@"RMInvalidConstructorInvocation"
                                 reason:@"init invoked on RMVirtualEarthSource. Use initWithMapType:usingAccessKey: instead."
                               userInfo:nil];
}

- (id)initWithMapType:(RMVirtualEarthMapType)aMapType usingAccessKey:(NSString *)developerAccessKey {
  NSAssert(([developerAccessKey length] > 0), @"Virtual Earth access key must be non-empty");
  
  if (self = [super init]) {
    mapType             = aMapType;
    accessKey           = [developerAccessKey copy];
    authStatusCondition = [[NSCondition alloc] init];
    authStatus          = kAuthStatusAuthenticating;
    urlTemplate         = nil;
    urlSubDomains       = nil;
    urlSubDomainIndex   = 0;
    culture             = nil;
    
    //default URL for attribution image (will be overridden when auth data is received)
    self.attributionImageURL = @"http://dev.virtualearth.net/Branding/logo_powered_by.png";
    
    [self performSelectorInBackground:@selector(authenticateWithVirtualEarthServer) withObject:nil];
  }
  
  return self;
}

- (void)dealloc {
  [accessKey           release];
  [authStatusCondition release];
  [urlTemplate         release];
  [urlSubDomains       release];
  [culture             release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark RMAbstractWebMapSource methods implementation

- (NSURL *)URLForTile:(RMTile)tile {
	NSString *quadKey = [self quadKeyForTile:tile];
  NSURL    *url     = [self urlForQuadKey:quadKey];
  
	return url;
}

#pragma mark -
#pragma mark RMTileSource methods implementation

-(NSString *) uniqueTilecacheKey {
  return [NSString stringWithFormat:@"MicrosoftVirtualEarth-%@", self.shortName];
}

-(NSString *)shortName {
  NSString *string = nil;
  
  switch (mapType) {
    case kRMirtualEarthMapTypeRoad:
      string = @"Bing Road";
      break;
    case kRMirtualEarthMapTypeAerial:
      string = @"Bing Aerial";
      break;
    case kRMirtualEarthMapTypeHybrid:
      string = @"Bing Hybrid";
      break;
  }
  
  return string;
}

-(NSString *)longDescription {
	return @"Microsoft Virtual Earth. All data © Microsoft or their licensees.";
}

-(NSString *)shortAttribution {
	return @"© Microsoft Virtual Earth";
}

-(NSString *)longAttribution {
	return @"Map data © Microsoft Virtual Earth.";
}

#pragma mark -
#pragma mark internal utility methods
                        
- (NSString *)mapTypeStringForMetaDataQuery {
  NSString *string = nil;
  
  switch (mapType) {
    case kRMirtualEarthMapTypeRoad:
      string = @"Road";
      break;
    case kRMirtualEarthMapTypeAerial:
      string = @"Aerial";
      break;
    case kRMirtualEarthMapTypeHybrid:
      string = @"AerialWithLabels";
      break;
  }
  
  return string;
}

- (void)authenticateWithVirtualEarthServer {
  @autoreleasepool {
    [self retain];
    
    [authStatusCondition lock];
    
    static NSMutableDictionary *authDataContainer = nil;
    NSDictionary               *authData          = nil;
    NSString                   *mapTypeString     = [self mapTypeStringForMetaDataQuery];
    
    @synchronized([self class]) {
      if (authDataContainer == nil)
        authDataContainer = [[NSMutableDictionary alloc] init];
      else
        authData          = [authDataContainer objectForKey:mapTypeString];
    }
    
    if (authData == nil) {
      NSError  *error  = nil;
      NSString *urlStr = [NSString stringWithFormat:@"https://dev.virtualearth.net/REST/v1/Imagery/Metadata/%@?key=%@", mapTypeString, accessKey];
      NSURL    *url    = [NSURL URLWithString:urlStr];
      NSData   *data   = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
      
      if (error == nil) {
        NSDictionary *dict      = nil;
        Class         jsonClass = NSClassFromString(@"NSJSONSerialization");
        
        if (jsonClass != nil) {
          dict = decodeJSONData(jsonClass, sel_registerName("JSONObjectWithData:options:error:"), data, 0, &error);
          
          if (error != nil) {
            RMLog(@"Could not decide JSON string: %@", error);
          }
        }
        
        RMLog(@"AUTH DATA: %@", dict);
        
        if (dict != nil) {
          BOOL authenticated = [[dict objectForKey:@"authenticationResultCode"] isEqualToString:@"ValidCredentials"];

          if (authenticated) {
            authData = dict;
            
            @synchronized([self class]) {
              if ([authDataContainer objectForKey:mapTypeString] == nil) {
                [authDataContainer setObject:authData forKey:mapTypeString];
                
                RMLog(@"Successfully authenticated for BING %@ maps", mapTypeString);
              }
              else {
                //another thread already obtained authentication data
                authData = [authDataContainer objectForKey:mapTypeString];
              }
            }
          }
          else {
            RMLog(@"Could not authenticate for BING %@ maps: %@", mapTypeString, dict);
          }
        }
      }
      else {
        RMLog(@"Could not connect to BING server: %@", error);
      }
    }
    
    if (authData != nil) {
      NSArray      *resourceSets = [authData objectForKey:@"resourceSets"];
      NSDictionary *resourceSet  = [resourceSets lastObject];
      NSArray      *resources    = [resourceSet objectForKey:@"resources"];
      NSDictionary *resourceData = [resources lastObject];
      NSString     *imageUrl     = [resourceData objectForKey:@"imageUrl"];
      NSArray      *subdomains   = [resourceData objectForKey:@"imageUrlSubdomains"];
      
      if (resourceSets.count != 1) {
        RMLog(@"Expected 1 resource sets, got %d (%@)", resourceSets.count, authData);
      }
      
      if (resources.count != 1) {
        RMLog(@"Expected 1 resources, got %d (%@)", resources.count, authData);
      }
      
      self.minZoom             = [[resourceData objectForKey:@"zoomMin"] integerValue];
      self.maxZoom             = [[resourceData objectForKey:@"zoomMax"] integerValue];
      self.attributionImageURL = [authData objectForKey:@"brandLogoUri"];
      
      urlTemplate   = [imageUrl copy];
      urlSubDomains = [[NSArray alloc] initWithArray:subdomains copyItems:YES];
      
      authStatus = kAuthStatusAuthenticated;
    }
    else {
      authStatus = kAuthStatusNotAuthenticated;
    }
    
    [authStatusCondition signal];
    [authStatusCondition unlock];
    
    [self release];
  }
}

-(NSString *)quadKeyForTile:(RMTile)tile {
	NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
            @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
            self, tile.zoom, self.minZoom, self.maxZoom);
  
	NSMutableString *quadKey = [NSMutableString string];
  
	for (int i = tile.zoom; i > 0; i--) {
		int mask = 1 << (i - 1);
		int cell = 0;
    
		if ((tile.x & mask) != 0) {
			cell++;
		}
    
		if ((tile.y & mask) != 0) {
			cell += 2;
		}
    
		[quadKey appendString:[NSString stringWithFormat:@"%d", cell]];
	}
  
	return quadKey;
}

-(NSURL *)urlForQuadKey:(NSString *)quadKey {
  NSURL *url = nil;
  
  [authStatusCondition lock];
  
  while (authStatus == kAuthStatusAuthenticating)
    [authStatusCondition wait];
  
  if (urlTemplate != nil) {
    NSString *urlString = [NSString stringWithString:urlTemplate];
    
    urlString = [urlString stringByReplacingOccurrencesOfString:@"{quadkey}"   withString:quadKey];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"{subdomain}" withString:[self mapSubDomainParameter]];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"{culture}"   withString:[self mapCultureParameter]];
    
    url = [NSURL URLWithString:urlString];
  }
  
//  RMLog(@"URL: %@", url);
  
  //if not authenticated, retry, there might be network problems
  if (authStatus == kAuthStatusNotAuthenticated) {
    [self performSelectorInBackground:@selector(authenticateWithVirtualEarthServer) withObject:nil];
  }
  
  [authStatusCondition unlock];
  
  return url;
}

- (NSString *)mapSubDomainParameter {
  NSString *subdomain = nil;
  
  if (urlSubDomains.count > 0) {
    subdomain = [urlSubDomains objectAtIndex:urlSubDomainIndex++];

    if (urlSubDomainIndex == urlSubDomains.count)
      urlSubDomainIndex = 0;
  }
  
  return subdomain;
}

- (NSString *)mapCultureParameter {
  if (culture == nil)
    culture = [[NSString alloc] initWithString:[[NSLocale preferredLanguages] objectAtIndex:0]];
  
  return culture;
}

@end
