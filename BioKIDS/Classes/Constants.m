/*
  Constants.m
  Created 8/12/11.

  Copyright (c) 2011 The Regents of the University of Michigan

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
const NSTimeInterval kNetworkPOSTTimeout = 120.0;	// Two minutes (but iOS enforces 4 minute minimum for POSTs).

// Notifications.
NSString *const kNotificationUploadComplete = @"BioKIDS_UploadComplete";

// Preference keys and values:
NSString * const kBioKIDSIDKey = @"BioKIDSID";
NSString * const kTrackerKey = @"Tracker";
NSString * const kZoneKey = @"Zone";
NSString * const kServerURLKey = @"ServerURL";
NSString * const kUserNameKey = @"ServerUserName";

// Keychain service names:
NSString * const kBioKIDSServiceName = @"BioKIDS";

// Sequence strings that we know about.
NSString * const kSeqNameObservationList = @"_obslist";
NSString * const kTypePlant = @"Plant";
NSString * const kSpeciesGrass = @"Grass";
NSString * const kEnergyRoleProducer = @"Producer";
NSString * const kEnergyRoleConsumer = @"Consumer";
NSString * const kHowExactExact = @"Exact count";
NSString * const kHowExactEstim = @"Estimated count";

// CSV column header.
NSString * const kCSVColumns = @"guid,date,time,group_code,location,name,how_observed,what_observed,animal_group,animal,where_observed,behavior_observed,what_eating,how_many,how_exact,plant_group,how_much_grass,energy_role,consumer_type,notes";


