/*
  Observation.h
  Created 8/15/11.

  Copyright (c) 2011-2013 The Regents of the University of Michigan

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
#import <CoreData/CoreData.h>


@interface Observation : NSManagedObject
{
}

@property (nonatomic, retain) NSString * GUID;
@property (nonatomic, retain) NSDate * Timestamp;
@property (nonatomic, retain) NSNumber * Completed;
@property (nonatomic, retain) NSString * BioKIDSID;
@property (nonatomic, retain) NSString * Tracker;
@property (nonatomic, retain) NSString * Zone;
@property (nonatomic, retain) NSString * HowSensed;
@property (nonatomic, retain) NSString * WhatSensed;
@property (nonatomic, retain) NSString * Group;
@property (nonatomic, retain) NSString * Species;
@property (nonatomic, retain) NSNumber * HowMany;
@property (nonatomic, retain) NSNumber * HowManyIsEstimated;
@property (nonatomic, retain) NSString * EnergyRole;
@property (nonatomic, retain) NSString * Microhabitat;
@property (nonatomic, retain) NSString * Behavior;
@property (nonatomic, retain) NSString * WhatEating;
@property (nonatomic, retain) NSString * Notes;
@property (nonatomic, retain) NSString * ImagePath;
@property (nonatomic, retain) NSNumber * Latitude;
@property (nonatomic, retain) NSNumber * Longitude;
@property (nonatomic, retain) NSNumber * locationAccuracy;
@property (nonatomic, retain) NSString * locationDescription;

// Public Methods:
- (void)deleteObservation;
- (void)updateLocation;
- (NSString *)dateString:(BOOL)aFriendly;
- (NSString *)timeString:(BOOL)aFriendly;
- (NSString *)grassCoverageString;
- (NSString *)howExactString;
- (NSString *)energyRoleString;
- (NSString *)consumerTypeString;
- (NSString *)latLongString;
- (NSString *)serverString;	// CSV
- (NSString *)htmlString;

@end
