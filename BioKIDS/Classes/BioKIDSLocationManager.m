/*
  BioKIDSLocationManager.m

  Copyright (c) 2013 The Regents of the University of Michigan

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject
  to the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//#define BIOKIDS_LOCATION_MGR_DEBUG

#import "BioKIDSLocationManager.h"

// Private methods.
@interface BioKIDSLocationManager()
- (BOOL) onNewLocation:(CLLocation *)aNewLocation;
- (void) onLocationTimeout;
#if TARGET_IPHONE_SIMULATOR
- (void) onSimulateLocation;
#endif
@end

@implementation BioKIDSLocationManager

@synthesize mDelegate, mLocationManager, mIsWaitingForLocation;
@synthesize mLocationLookupStartTime, mBestLocationSoFar;

// Constants:
NSTimeInterval const kPLGetLocationTimeoutSec = 22.0;
NSTimeInterval const kPLMaxLocationAgeSecs = 10.0;
NSTimeInterval const kPLLocationWaitTimeGoodAccuracySecs = 15.0;
CLLocationDistance const kPLGoodAccuracyMeters = 2000.0;
CLLocationDistance const kPLMinLocationDistanceMovedMeters = 200;

- (id) initAndGetLocation:(id<BioKIDSLocationManagerDelegate>)aDelegate
{
	if ((self = [super init]))
	{
		self.mDelegate = aDelegate;
		self.mLocationManager = [[[CLLocationManager alloc] init] autorelease];
		self.mLocationManager.delegate = self;
		self.mLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
		self.mLocationManager.distanceFilter = kPLMinLocationDistanceMovedMeters;
		self.mBestLocationSoFar = nil;
		self.mLocationLookupStartTime = [NSDate date];
		self.mIsWaitingForLocation = YES;
#if TARGET_IPHONE_SIMULATOR
		// As of iOS 4.1, location updates are not received in the simulator
		// unless a location is picked up via Mac OS Snow Leopard (WiFi).  So,
		// we return a fake location after a short timeout.
		[self performSelector:@selector(onSimulateLocation) withObject:nil
				   afterDelay:0.25];
#else
		[self.mLocationManager startUpdatingLocation];
		[self performSelector:@selector(onLocationTimeout)
							withObject:nil afterDelay:kPLGetLocationTimeoutSec];
#endif
	}

	return self;
}


- (void) cancel
{
	self.mIsWaitingForLocation = NO;
	[self.mLocationManager stopUpdatingLocation]; // Turn off updates to save power.
	[NSObject cancelPreviousPerformRequestsWithTarget:self
					 selector:@selector(onLocationTimeout) object:nil];

	// Use autorelease to avoid releasing CLLocationManager while inside one
	// of its callbacks.
	[[self.mLocationManager retain] autorelease];
	self.mLocationManager = nil;
}


#pragma mark Memory Management
- (void) dealloc
{
	self.mDelegate = nil;
	self.mLocationManager = nil;
	self.mLocationLookupStartTime = nil;
	self.mBestLocationSoFar = nil;

	[super dealloc];
}


#pragma mark CLLocationManagerDelegate Delegate Methods
- (void)locationManager:(CLLocationManager *)aManager
	 								didUpdateLocations:(NSArray *)aLocations
{
	if (!self.mIsWaitingForLocation)
		return;

	// The freshest location is last in the array.
	for (CLLocation *loc in [aLocations reverseObjectEnumerator])
	{
		if ([self onNewLocation:loc])
			break;
	}
}


- (void)locationManager:(CLLocationManager *)aLocationManager
						didFailWithError:(NSError *)aError
{
	// If a non-transient error occurs, stop waiting.
	if (kCLErrorLocationUnknown != aError)
	{
		BOOL responseExpected = self.mIsWaitingForLocation;
		[self cancel];
		if (responseExpected)
			[self.mDelegate getLocationDidFail:self];
	}
}

#pragma mark Private Methods
// Returns YES if aLocation is acceptable (has required accuracy, etc.)
- (BOOL) onNewLocation:(CLLocation *)aNewLocation
{
	BOOL wasAccepted = NO;

	// Wait for a fairly "fresh" location.
	NSDate *timeStamp = aNewLocation.timestamp;
	NSTimeInterval ageInSeconds = [timeStamp timeIntervalSinceNow];
#ifdef BIOKIDS_LOCATION_MGR_DEBUG
	NSLog(@"onNewLocation - loc age in secs: %f", ageInSeconds);
#endif
	if (abs(ageInSeconds) < kPLMaxLocationAgeSecs)
	{
#ifdef BIOKIDS_LOCATION_MGR_DEBUG
		NSLog(@"location horAcc: %f, verAcc: %f (meters)",
			  aNewLocation.horizontalAccuracy, aNewLocation.verticalAccuracy);
#endif
		NSTimeInterval waitTimeInSeconds = [self.mLocationLookupStartTime timeIntervalSinceNow];
#ifdef BIOKIDS_LOCATION_MGR_DEBUG
		NSLog(@"wait time in secs: %f", waitTimeInSeconds);
#endif
		// Wait up to kLocationWaitTimeGoodAccuracySecs for an accurate location.
		if ((abs(waitTimeInSeconds) > kPLLocationWaitTimeGoodAccuracySecs)
			|| ((aNewLocation.horizontalAccuracy > 0)
				&& (aNewLocation.horizontalAccuracy <= kPLGoodAccuracyMeters)))
		{
#ifdef BIOKIDS_LOCATION_MGR_DEBUG
			NSLog(@"using this location");
#endif
			[self cancel];
			[self.mDelegate getLocationDidSucceed:self location:aNewLocation];
			wasAccepted = YES;
		}
		else
		{
			self.mBestLocationSoFar = aNewLocation;
			if ([self.mDelegate
				 respondsToSelector:@selector(getLocationIntermediateUpdate:location:)])
			{
				[self.mDelegate getLocationIntermediateUpdate:self
													 location:aNewLocation];
			}
#ifdef BIOKIDS_LOCATION_MGR_DEBUG
			NSLog(@"not using location yet -- not accurate enough");
#endif
		}
	}
#ifdef BIOKIDS_LOCATION_MGR_DEBUG
	else NSLog(@"not using location -- too old");
#endif

	return wasAccepted;
}


- (void)onLocationTimeout
{
	[self cancel];

	if (self.mBestLocationSoFar)
	{
		[self.mDelegate getLocationDidSucceed:self
											location:self.mBestLocationSoFar];
	}
	else
		[self.mDelegate getLocationDidFail:self];
}


#if TARGET_IPHONE_SIMULATOR
- (void) onSimulateLocation
{
	CLLocationCoordinate2D coord = { 42.17, -83.78 };	// Saline, MI
	CLLocation *loc = [[CLLocation alloc] initWithCoordinate:coord altitude:0.0
						horizontalAccuracy:kCLLocationAccuracyNearestTenMeters
						verticalAccuracy:kCLLocationAccuracyNearestTenMeters
						timestamp:[NSDate date]];
	[loc autorelease];

	NSArray *locArray = [NSArray arrayWithObject:loc];
	[self locationManager:self.mLocationManager didUpdateLocations:locArray];
}
#endif

@end
