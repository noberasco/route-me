//
//  RMUserTrackingBarButtonItem.m
//  MapView
//
//  Created by Justin Miller on 5/10/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "RMUserTrackingBarButtonItem.h"

#import "RMMapView.h"
#import "RMUserLocation.h"

typedef enum {
    RMUserTrackingButtonStateLocation = 0,
    RMUserTrackingButtonStateHeading  = 1
} RMUserTrackingButtonState;

@interface RMUserTrackingBarButtonItem ()

- (void)updateAppearance;
- (void)changeMode:(id)sender;

@end

#pragma mark -

@implementation RMUserTrackingBarButtonItem {
  NSTimer *_timer;
}

@synthesize mapView = _mapView;

- (id)initWithMapView:(RMMapView *)mapView
{
    NSAssert(mapView != nil, @"mapView must be != nil");
  
    if ( ! (self = [super initWithImage:[UIImage imageNamed:@"TrackingLocation.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(changeMode:)]))
        return nil;
  
    _mapView = [mapView retain];
    _timer   = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(updateAppearance) userInfo:nil repeats:YES];
  
    [_mapView addObserver:self forKeyPath:@"userTrackingMode"      options:NSKeyValueObservingOptionNew context:nil];
    [_mapView addObserver:self forKeyPath:@"userLocation.location" options:NSKeyValueObservingOptionNew context:nil];
  
    return [self autorelease]; //NSTimer retained us
}

- (void)dealloc
{
    [_timer invalidate];
    [_mapView removeObserver:self forKeyPath:@"userTrackingMode"];
    [_mapView removeObserver:self forKeyPath:@"userLocation.location"];
    [_mapView release]; _mapView = nil;
    
    [super dealloc];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateAppearance];
}

#pragma mark -

- (void)updateAppearance
{
    switch (_mapView.userTrackingMode) {
        case RMUserTrackingModeNone:
            self.image = [UIImage imageNamed:@"TrackingLocation.png"];
            self.style = UIBarButtonItemStyleBordered;
            break;
        case RMUserTrackingModeFollow:
            self.image = [UIImage imageNamed:@"TrackingLocation.png"];
            self.style = UIBarButtonItemStyleDone;
            break;
        case RMUserTrackingModeFollowWithHeading:
            self.image = [UIImage imageNamed:@"TrackingHeading.png"];
            self.style = UIBarButtonItemStyleDone;
            break;
    }
}

- (void)changeMode:(id)sender
{
    switch (_mapView.userTrackingMode)
    {
        case RMUserTrackingModeNone:
        default:
        {
            _mapView.userTrackingMode = RMUserTrackingModeFollow;
            
            break;
        }
        case RMUserTrackingModeFollow:
        {
            if ([CLLocationManager headingAvailable])
                _mapView.userTrackingMode = RMUserTrackingModeFollowWithHeading;
            else
                _mapView.userTrackingMode = RMUserTrackingModeNone;

            break;
        }
        case RMUserTrackingModeFollowWithHeading:
        {
            _mapView.userTrackingMode = RMUserTrackingModeNone;

            break;
        }
    }

    [self updateAppearance];
}

@end
