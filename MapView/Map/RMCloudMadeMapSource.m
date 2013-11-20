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

#import "RMCloudMadeMapSource.h"

typedef enum {
  kAuthStatusAuthenticating = 0,
  kAuthStatusAuthenticated,
  kAuthStatusNotAuthenticated
  
} AuthStatus;

//auth data container, shared between all RMVirtualEarthSource instances
static AuthStatus  authStatus = kAuthStatusNotAuthenticated;
static NSString   *authToken  = nil;

@interface RMCloudMadeMapSource ()

@property(nonatomic, retain) NSString *apiKey;
@property(nonatomic, retain) NSString *styleID;

@end

@implementation RMCloudMadeMapSource {
@private
  NSCondition *authStatusCondition;
  NSString    *apiKey;
  NSString    *styleID;
}

#pragma mark -
#pragma mark memory management

- (id)initWithParameters:(NSDictionary *)params {
  if (!(self = [super init]))
    return nil;
  
  NSAssert(params != nil, @"Empty params parameter not allowed");
  
  authStatusCondition = [[NSCondition alloc] init];
  
  self.apiKey  = [params objectForKey:kApiKey];
  self.styleID = [params objectForKey:kStyleID];
  
  if ([[UIScreen mainScreen] scale] == 2.0) {
    self.minZoom = kDefaultMinTileZoom;
    self.maxZoom = kDefaultMaxTileZoom + 1;
  }
  else {
    self.minZoom = kDefaultMinTileZoom;
    self.maxZoom = kDefaultMaxTileZoom;
  }
  
  @synchronized([self class]) {
    if (authStatus == kAuthStatusNotAuthenticated) {
      authStatus = kAuthStatusAuthenticating;
      
      [self performSelectorInBackground:@selector(requestAuthenticationToken) withObject:nil];
    }
  }
  
  return self;
}

- (void)dealloc {
  [authStatusCondition release];
  [apiKey              release];
  [styleID             release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark properties

@synthesize apiKey;
@synthesize styleID;

#pragma mark -
#pragma mark authentication token

- (void)requestAuthenticationToken {
  @autoreleasepool {
    @synchronized([self class]) {
      [authStatusCondition lock];
      
      NSString            *url     = [NSString stringWithFormat:@"http://auth.cloudmade.com/token/%@?userid=%@", apiKey, UIDevice.currentDevice.identifierForVendor.UUIDString];
      NSData              *data    = nil;
      NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                         timeoutInterval:15.0];
      NSURLResponse       *response = nil;
      NSError             *error    = nil;
      
      request.HTTPMethod = @"POST";
      
      data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
      
      if (data != nil && ((NSHTTPURLResponse*)response).statusCode == 200) {
        authToken  = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        authStatus = kAuthStatusAuthenticated;
        
        NSLog(@"Successfully authenticated for CloudMade maps");
      }
      else if (data != nil) {
        NSString *errMsg = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        
        if (errMsg.length > 0) {
          NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[self convertHTMLErrorMessageToPlainText:errMsg] forKey:NSLocalizedDescriptionKey];
          
          error = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:userInfo];
        }
      }
      
      if (error != nil) {
        NSDictionary *dict = [NSDictionary dictionaryWithObject:error forKey:kCloudMadeAuthenticationErrorKey];
        
        NSLog(@"Could not authenticate for CloudMade maps: %@", error.localizedDescription);
        
        authStatus = kAuthStatusNotAuthenticated;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kCloudMadeAuthenticationErrorNotification object:self userInfo:dict];
      }
      
      [authStatusCondition signal];
      [authStatusCondition unlock];
    }
  }
}

- (NSString *)convertHTMLErrorMessageToPlainText:(NSString *)html {
  NSRange range = [html rangeOfString:@"</h1>\n"];
  
  //quick n dirty, server is not returning well formed HTML strings
  
  if (range.location != NSNotFound)
    html = [html substringFromIndex:(range.location + range.length)];
  
  return html;
}

#pragma mark -
#pragma mark RMAbstractWebMapSource methods implementation

- (NSURL *)URLForTile:(RMTile)tile {
  NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
            @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
            self, tile.zoom, self.minZoom, self.maxZoom);
  
  NSURL *url = nil;
  
  [authStatusCondition lock];
  
  while (authStatus == kAuthStatusAuthenticating)
    [authStatusCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
  
  if (authToken != nil) {
    NSString *str = [NSString stringWithFormat:@"http://tile.cloudmade.com/%@/%@%@/256/%d/%d/%d.png?token=%@",
                     apiKey,
                     styleID,
                     (UIScreen.mainScreen.scale == 2.0) ? @"@2x" : @"",
                     tile.zoom,
                     tile.x,
                     tile.y,
                     authToken];
    
    url = [NSURL URLWithString:str];
  }
  
  //if not authenticated, retry, there might be network problems
  if (authStatus == kAuthStatusNotAuthenticated) {
    [self performSelectorInBackground:@selector(requestAuthenticationToken) withObject:nil];
  }
  
  [authStatusCondition unlock];
  
  return url;
}

#pragma mark -
#pragma mark RMTileSource methods implementation

- (NSString *)uniqueTilecacheKey {
  return [NSString stringWithFormat:@"CloudMade-%@", styleID];
}

- (NSString *)shortName {
  return @"CloudMade Map Source";
}

- (NSString *)longDescription {
	return @"CloudMade Map Source";
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
