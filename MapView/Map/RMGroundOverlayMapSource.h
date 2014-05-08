//
//  RMGroundOverlayMapSource.h
//  MapView
//
//  Created by thorin on 08/05/14.
//
//

#import "RMAbstractWebMapSource.h"

#define kZipFileName    @"ZIPFILENAME"
#define kGroundOverlays @"GROUNDOVERLAYS"

@interface RMGroundOverlayMapSource : RMAbstractWebMapSource

- (id)initWithParameters:(NSDictionary *)params;

@property(nonatomic, readonly) NSString *zipFileName;
@property(nonatomic, readonly) NSArray  *groundOverlays;

@end
