/*
  Constants.h
  Created 8/12/11.

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

// Network timeouts, etc.
extern const NSTimeInterval kNetworkPOSTTimeout;

// Notifications.
extern NSString * const kNotificationUploadComplete;
extern NSString * const kNotificationClassroomUseChanged;

// Preference keys and values:
extern NSString * const kLastVersionKey;
extern NSString * const kClassroomUseKey;
extern NSString * const kBioKIDSIDKey;
extern NSString * const kTrackerKey;
extern NSString * const kZoneKey;
extern NSString * const kServerURLKey;
extern NSString * const kUserNameKey;
extern NSString * const kLastLocationDescriptionKey;

// Keychain service names:
extern NSString * const kBioKIDSServiceName;

// Sequence strings that we know about.
extern NSString * const kSeqNameObservationList;
extern NSString * const kTypePlant;
extern NSString * const kSpeciesGrass;
extern NSString * const kEnergyRoleProducer;
extern NSString * const kEnergyRoleConsumer;
extern NSString * const kHowExactExact;
extern NSString * const kHowExactEstim;

// CSV column header.
extern NSString * const kCSVColumns;
