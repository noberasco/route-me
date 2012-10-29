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

#import "RMVirtualEarthSource.h"

#define kAuthDataKey                 [self mapTypeStringForMetaDataQuery]
#define kUpdatedAuthDataNotification [NSString stringWithFormat:@"updatedAuthDataNotification-%@", kAuthDataKey]
#define kAuthRequestInProgressKey    [NSString stringWithFormat:@"authenticationInProgress-%@",    kAuthDataKey]

typedef enum {
  kAuthStatusAuthenticating = 0,
  kAuthStatusAuthenticated,
  kAuthStatusNotAuthenticated

} AuthStatus;

//auth data container, shared between all RMVirtualEarthSource instances
static NSMutableDictionary *authDataContainer = nil;

@interface RMVirtualEarthSource ()

- (void)authenticateWithVirtualEarthServer;
- (NSString *)quadKeyForTile:(RMTile)tile;
- (NSURL    *)urlForQuadKey:(NSString *)quadKey;
- (NSString *)mapSubDomainParameter;
- (NSString *)mapCultureParameter;

@property(nonatomic, retain) NSString   *urlTemplate;
@property(nonatomic, retain) NSArray    *urlSubDomains;
@property(nonatomic, assign) AuthStatus  authStatus;

@end

@implementation RMVirtualEarthSource {
@private
  RMVirtualEarthMapType  mapType;
	NSString              *accessKey;
  NSCondition           *authStatusCondition;
  AuthStatus             authStatus;
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
    accessKey           = [developerAccessKey retain];
    authStatusCondition = [[NSCondition alloc] init];
    authStatus          = kAuthStatusAuthenticating;
    urlTemplate         = nil;
    urlSubDomains       = nil;
    urlSubDomainIndex   = 0;
    culture             = nil;
    
    //default URL for attribution image (will be overridden when auth data is received)
    self.attributionImageURL = @"http://dev.virtualearth.net/Branding/logo_powered_by.png";
    
    @synchronized([self class]) {
      if (authDataContainer == nil)
        authDataContainer = [[NSMutableDictionary alloc] init];
    }
    
    [self performSelectorInBackground:@selector(authenticateWithVirtualEarthServer) withObject:nil];
  }
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [accessKey           release];
  [authStatusCondition release];
  [urlTemplate         release];
  [urlSubDomains       release];
  [culture             release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark properties

@synthesize urlTemplate;
@synthesize urlSubDomains;
@synthesize authStatus;

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
#pragma mark map server authentication management
                        
- (void)setAuthDataForVirtualEarthServer:(NSDictionary *)authData isFinalData:(BOOL)isFinalData {
  [authStatusCondition lock];
  
  if (authData != nil) {
    NSArray      *resourceSets = [authData objectForKey:@"resourceSets"];
    NSDictionary *resourceSet  = [resourceSets lastObject];
    NSArray      *resources    = [resourceSet objectForKey:@"resources"];
    NSDictionary *resourceData = [resources lastObject];
    
    if (resourceSets.count != 1) {
      RMLog(@"Expected 1 resource sets, got %d (%@)", resourceSets.count, authData);
    }
    
    if (resources.count != 1) {
      RMLog(@"Expected 1 resources, got %d (%@)", resources.count, authData);
    }
    
    self.minZoom             = [[resourceData objectForKey:@"zoomMin"] integerValue];
    self.maxZoom             = [[resourceData objectForKey:@"zoomMax"] integerValue];
    self.attributionImageURL = [authData objectForKey:@"brandLogoUri"];
    self.urlTemplate         = [resourceData objectForKey:@"imageUrl"];
    self.urlSubDomains       = [resourceData objectForKey:@"imageUrlSubdomains"];
    self.authStatus          = kAuthStatusAuthenticated;
    
    [authStatusCondition signal];
  }
  else if (isFinalData == YES) {
    self.authStatus          = kAuthStatusNotAuthenticated;
    
    [authStatusCondition signal];
  }
  
  [authStatusCondition unlock];
}

- (void)requestAuthDataFromVirtualEarthServer {
  NSError      *error       = nil;
  NSString     *authDataKey = kAuthDataKey;
  NSString     *urlStr      = [NSString stringWithFormat:@"https://dev.virtualearth.net/REST/v1/Imagery/Metadata/%@?key=%@", authDataKey, accessKey];
  NSURL        *url         = [NSURL URLWithString:urlStr];
  NSData       *data        = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
  NSDictionary *authData    = nil;
  
  if (error == nil) {
    NSDictionary *dict      = nil;
    Class         jsonClass = NSClassFromString(@"NSJSONSerialization");
    
    if (jsonClass != nil) {
      NSJSONReadingOptions   options        = 0;
      SEL                    selector       = @selector(JSONObjectWithData:options:error:);
      NSInvocation          *decodeJSONData = [NSInvocation invocationWithMethodSignature:[jsonClass methodSignatureForSelector:selector]];
      NSError              **errPtr         = &error;
      
      [decodeJSONData setTarget:jsonClass];
      [decodeJSONData setSelector:selector];
      [decodeJSONData setArgument:&data    atIndex:2];
      [decodeJSONData setArgument:&options atIndex:3];
      [decodeJSONData setArgument:&errPtr  atIndex:4];
      
      [decodeJSONData invoke];
      [decodeJSONData getReturnValue:&dict];
      
      if (error != nil) {
        RMLog(@"Could not decode JSON string: %@", error);
      }
    }
    
//    RMLog(@"AUTH DATA: %@", dict);
    
    if (dict != nil) {
      BOOL authenticated = [[dict objectForKey:@"authenticationResultCode"] isEqualToString:@"ValidCredentials"];
      
      if (authenticated) {
        authData = dict;
        
        @synchronized([self class]) {
          [authDataContainer setObject:authData forKey:authDataKey];
          
          RMLog(@"Successfully authenticated for BING %@ maps", authDataKey);
          
          //store updated auth data in persistent cache to be reused in case of network unavailability
          
          NSMutableData   *data     = [NSMutableData data];
          NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
          
          [archiver encodeObject:authData forKey:authDataKey];
          [archiver finishEncoding];
          [archiver release];
          
          [[NSUserDefaults standardUserDefaults] synchronize];
          [[NSUserDefaults standardUserDefaults] setObject:data forKey:authDataKey];
          [[NSUserDefaults standardUserDefaults] synchronize];
        }
      }
      else {
        //authentication failed: remove auth data from persistent cache
        
        @synchronized([self class]) {
          [[NSUserDefaults standardUserDefaults] synchronize];
          [[NSUserDefaults standardUserDefaults] removeObjectForKey:authDataKey];
          [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        RMLog(@"Could not authenticate for BING %@ maps: %@", authDataKey, dict);
      }
    }
  }
  else {
    //since we failed due to a network error (we might be in a zone with no connectivity)
    //keep our previously-cached auth data
    
    RMLog(@"Could not connect to BING server");
  }

  [self setAuthDataForVirtualEarthServer:authData isFinalData:YES];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kUpdatedAuthDataNotification object:nil];
  
  @synchronized([self class]) {
    [authDataContainer removeObjectForKey:kAuthRequestInProgressKey];
  }
}

- (void)authenticateWithVirtualEarthServer {
  @autoreleasepool {
    [self retain];
    
    NSDictionary *authData    = nil;
    NSString     *authDataKey = kAuthDataKey;
    
    //check whether we already have auth data
    @synchronized([self class]) {
      authData = [authDataContainer objectForKey:authDataKey];
    }
    
    if (authData != nil) {
      [self setAuthDataForVirtualEarthServer:authData isFinalData:YES];
    }
    else {
      //we have no auth data
      
      //if available, fetch auth data from persistent cache, to enable tile loading while we request 'real' auth data
      @synchronized([self class]) {
        NSData *data = nil;
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        data = [[NSUserDefaults standardUserDefaults] dataForKey:authDataKey];
        
        if (data != nil) {
          NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
          
          authData = [unarchiver decodeObjectForKey:authDataKey];
          
          [unarchiver finishDecoding];
          [unarchiver release];
        }
      }
      [self setAuthDataForVirtualEarthServer:authData isFinalData:NO];
      
      //check whether an authentication request is already in progress
      BOOL authInProgress = NO;
      @synchronized([self class]) {
        if ([authDataContainer objectForKey:kAuthRequestInProgressKey] != nil) {
          authInProgress = YES;
          
          [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedAuthDataNotification) name:kUpdatedAuthDataNotification object:nil];
        }
        else {
          [authDataContainer setObject:[NSNumber numberWithBool:YES] forKey:kAuthRequestInProgressKey];
        }
      }
      
      //request new auth data if no authentication request is in progress
      if (authInProgress == NO) {
        [self requestAuthDataFromVirtualEarthServer];
      }
    }
    
    [self release];
  }
}

- (void)updatedAuthDataNotification {
  NSDictionary *authData = nil;
  
  @synchronized([self class]) {
    authData = [authDataContainer objectForKey:kAuthDataKey];
  }

  [self setAuthDataForVirtualEarthServer:authData isFinalData:YES];
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
  
  while (self.authStatus == kAuthStatusAuthenticating)
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
  if (self.authStatus == kAuthStatusNotAuthenticated) {
    [self performSelectorInBackground:@selector(authenticateWithVirtualEarthServer) withObject:nil];
  }
  
  [authStatusCondition unlock];
  
  return url;
}

- (NSString *)mapSubDomainParameter {
  NSString *subdomain = nil;
  
  if (urlSubDomainIndex >= urlSubDomains.count)
    urlSubDomainIndex = 0;
  
  if (urlSubDomains.count > 0) {
    subdomain = [urlSubDomains objectAtIndex:urlSubDomainIndex++];
  }
  
  return subdomain;
}

- (NSString *)mapCultureParameter {
  if (culture == nil)
    culture = [[NSString alloc] initWithString:[[NSLocale preferredLanguages] objectAtIndex:0]];
  
  return culture;
}

@end
