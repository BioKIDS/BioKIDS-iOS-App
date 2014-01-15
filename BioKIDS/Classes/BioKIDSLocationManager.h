/*
  BioKIDSLocationManager.h

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

#import <Foundation/Foundation.h>
#import "CoreLocation/CoreLocation.h"


@protocol BioKIDSLocationManagerDelegate;

@interface BioKIDSLocationManager : NSObject <CLLocationManagerDelegate>
{
	@private id<BioKIDSLocationManagerDelegate> mDelegate;
	@private CLLocationManager *mLocationManager;
	@private BOOL mIsWaitingForLocation;
	@private NSDate *mLocationLookupStartTime;
	@private CLLocation *mBestLocationSoFar;
}

@property (nonatomic, assign) id<BioKIDSLocationManagerDelegate> mDelegate;
@property (nonatomic, retain) CLLocationManager *mLocationManager;
@property (nonatomic, assign) BOOL mIsWaitingForLocation;
@property (nonatomic, retain) NSDate *mLocationLookupStartTime;
@property (nonatomic, retain) CLLocation *mBestLocationSoFar;

// Declare public methods.
- (id) initAndGetLocation:(id<BioKIDSLocationManagerDelegate>)aDelegate;
- (void) cancel;

@end

@protocol BioKIDSLocationManagerDelegate<NSObject>
- (void) getLocationDidFail:(BioKIDSLocationManager *)aBioKIDSLocationManager;
- (void) getLocationDidSucceed:(BioKIDSLocationManager *)aBioKIDSLocationManager
					  location:(CLLocation *)aLocation;
@optional
- (void) getLocationIntermediateUpdate:(BioKIDSLocationManager *)aBioKIDSLocationManager
							  location:(CLLocation *)aLocation;
@end
