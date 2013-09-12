//
// RMAbstractWebMapSource.m
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

#import "RMAbstractWebMapSource.h"
#import "RMTileCache.h"

#define HTTP_403_FORBIDDEN 403
#define HTTP_404_NOT_FOUND 404

@implementation RMAbstractWebMapSource

@synthesize retryCount, requestTimeoutSeconds;

- (id)init
{
    if (!(self = [super init]))
        return nil;

    self.retryCount = RMAbstractWebMapSourceDefaultRetryCount;
    self.requestTimeoutSeconds = RMAbstractWebMapSourceDefaultWaitSeconds;

    return self;
}

- (NSURL *)URLForTile:(RMTile)tile
{
    @throw [NSException exceptionWithName:@"RMAbstractMethodInvocation"
                                   reason:@"URLForTile: invoked on RMAbstractWebMapSource. Override this method when instantiating an abstract class."
                                 userInfo:nil];
}

- (NSArray *)URLsForTile:(RMTile)tile
{
    return [NSArray arrayWithObjects:[self URLForTile:tile], nil];
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    __block UIImage *image = nil;

	tile = [[self mercatorToTileProjection] normaliseTile:tile];
    image = [tileCache cachedImage:tile withCacheKey:[self uniqueTilecacheKey]];

    if (image)
        return image;

    [tileCache retain];

    NSArray *URLs = [self URLsForTile:tile];

    if ([URLs count] > 1)
    {
        // fill up collection array with placeholders
        //
        NSMutableArray *tilesData = [NSMutableArray arrayWithCapacity:[URLs count]];

        for (NSUInteger p = 0; p < [URLs count]; ++p)
            [tilesData addObject:[NSNull null]];

#ifndef __IPHONE_7_0
        dispatch_group_t fetchGroup = dispatch_group_create();
#endif

        for (NSUInteger u = 0; u < [URLs count]; ++u)
        {
            NSURL *currentURL = [URLs objectAtIndex:u];

#ifndef __IPHONE_7_0
            dispatch_group_async(fetchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
            {
#endif
                NSData *tileData = nil;

                for (NSUInteger try = 0; tileData == nil && try < self.retryCount; ++try)
                {
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:currentURL];
                    [request setTimeoutInterval:(self.requestTimeoutSeconds / (CGFloat)self.retryCount)];
                    tileData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                }

                if (tileData)
                {
#ifndef __IPHONE_7_0
                    @synchronized(self)
#endif
                    {
                        // safely put into collection array in proper order
                        //
                        [tilesData replaceObjectAtIndex:u withObject:tileData];
                    };
                }
#ifndef __IPHONE_7_0
            });
#endif
        }

#ifndef __IPHONE_7_0
        // wait for whole group of fetches (with retries) to finish, then clean up
        //
        dispatch_group_wait(fetchGroup, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * self.requestTimeoutSeconds));
        dispatch_release(fetchGroup);
#endif

        // composite the collected images together
        //
        for (NSData *tileData in tilesData)
        {
            if (tileData && [tileData isKindOfClass:[NSData class]] && [tileData length])
            {
                if (image != nil)
                {
                    UIImage *imageToAdd = nil;

                    UIGraphicsBeginImageContext(image.size);
                    [image drawAtPoint:CGPointMake(0,0)];
                  
                    imageToAdd = [UIImage imageWithData:tileData];
                    imageToAdd = [self postProcessTileImage:imageToAdd];
                    [imageToAdd drawAtPoint:CGPointMake(0,0)];

                    image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
                else
                {
                    image = [UIImage imageWithData:tileData];
                    image = [self postProcessTileImage:image];
                }
            }
        }
    }
    else if (URLs.count == 1)
    {
        for (NSUInteger try = 0; image == nil && try < self.retryCount; ++try)
        {
            NSHTTPURLResponse *response = nil;
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[URLs objectAtIndex:0]];
            [request setTimeoutInterval:(self.requestTimeoutSeconds / (CGFloat)self.retryCount)];
            image = [UIImage imageWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil]];
            image = [self postProcessTileImage:image];
          
          if (response.statusCode == HTTP_403_FORBIDDEN || response.statusCode == HTTP_404_NOT_FOUND) {
            //some tile sources return HTTP_403_FORBIDDEN but give us a 'quota exceeded' image
            //and we certainly don't want to cache *that* image
            image = nil;
            
            break;
          }
        }
    }
    else
    {
      RMLog(@"ERROR: no URLs for tile");
    }

    if (image)
        [tileCache addImage:image forTile:tile withCacheKey:[self uniqueTilecacheKey]];

    [tileCache release];

    return image;
}

- (UIImage *)postProcessTileImage:(UIImage *)image {
  //no postprocessing by default
  return image;
}

@end
