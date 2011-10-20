/*
  Observation.m
  Created 8/15/11.

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

#import "Observation.h"
#import "Constants.h"
#import "BioKIDSUtil.h"


// Declare private methods.
@interface Observation()
	- (void)appendHTMLRow:(NSMutableString *)aHTMLStr
					label:(NSString *)aLabel
					value:(NSString *)aValue
			   multiValue:(BOOL)aIsMultiValue;
	- (void)appendHTMLRowWithKey:(NSMutableString *)aHTMLStr
						labelKey:(NSString *)aKey
						   value:(NSString *)aValue
					  multiValue:(BOOL)aIsMultiValue;
@end


@implementation Observation

// Define Constants
NSString * const kHTMLRowFmt = @"<tr><td valign='top' nowrap>%@&nbsp;</td><td><b>%@</b></td></tr>\n";


// The first 6 are required (GUID,Completed,Timestamp,BioKIDSID,Tracker,Zone).
@dynamic GUID;					// 36-character hex (unique ID).
@dynamic Timestamp;
@dynamic Completed;				// NSNumber boolValue (is this observation complete?)
@dynamic BioKIDSID;
@dynamic Tracker;
@dynamic Zone;
@dynamic HowSensed;				// pipe-separated list, e.g. See|Hear
@dynamic WhatSensed;			// e.g. Plant
@dynamic Group;					// e.g. Grass
@dynamic Species;				// e.g. Raccoon
@dynamic HowMany;
@dynamic HowManyIsEstimated;	// NSNumber boolValue
@dynamic EnergyRole;			// one of: Producer, Carnivore, Herbivore, Omnivore, Decomposer
@dynamic Microhabitat;			// pipe-separated list, e.g. Bushes|Near water
@dynamic Behavior;				// pipe-separated list, e.g. Feeding|Drinking
@dynamic WhatEating;			// e.g. Seeds
@dynamic Notes;
// The remainder are for future expansion:
@dynamic ImagePath;
@dynamic Latitude;				// NSNumber doubleValue
@dynamic Longitude;				// NSNumber doubleValue


- (NSString *)dateString:(BOOL)aFriendly
{
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	if (aFriendly)
	{
		[df setDateStyle:NSDateFormatterMediumStyle];
		[df setTimeStyle:NSDateFormatterNoStyle];
	}
	else
		[df setDateFormat:@"yyyy-MM-dd"];

	NSString *s = [df stringFromDate:self.Timestamp];
	[df release];

	return s;
}


- (NSString *)timeString:(BOOL)aFriendly
{
	NSDateFormatter *tf = [[NSDateFormatter alloc] init];
	if (aFriendly)
	{
		[tf setDateStyle:NSDateFormatterNoStyle];
		[tf setTimeStyle:NSDateFormatterShortStyle];
	}
	else
		[tf setDateFormat:@"HH:mm:ss"];

	NSString *s = [tf stringFromDate:self.Timestamp];
	[tf release];

	return s;
}


// May return nil.
- (NSString *)grassCoverageString
{
	if ([self.Species isEqualToString:kSpeciesGrass] && self.HowMany)
	{
		NSInteger count = [self.HowMany integerValue];
		NSString *key = [NSString stringWithFormat:@"GrassCoverage%d", count];
		return NSLocalizedString(key, nil);
	}

	return nil;
}


// May return nil.
- (NSString *)howExactString
{
	if (!self.HowManyIsEstimated)
		return nil;

	BOOL isEstimated = [self.HowManyIsEstimated boolValue];
	return (isEstimated) ? kHowExactEstim : kHowExactExact;
}


// May return nil.
- (NSString *)energyRoleString
{
	if (!self.EnergyRole || [self.EnergyRole isEqualToString:kEnergyRoleProducer])
		return self.EnergyRole;

	return kEnergyRoleConsumer;
}


// May return nil.
- (NSString *)consumerTypeString
{
	if (!self.EnergyRole || [self.EnergyRole isEqualToString:kEnergyRoleProducer])
		return nil;

	return self.EnergyRole;
}


// May return nil.
- (NSString *)serverString
{
	// Note: fieldMap must have exactly the same number of items as kCSVColumns.
	// A leading _A_ means only include for Animals.
	// A leading _P_ means only include for Plants.
	// A leading | means change pipe characters to commas (multivalued field).
	static NSString *fieldMap = @"GUID,,,BioKIDSID,Zone,Tracker,|HowSensed,WhatSensed,_A_Group,_A_Species,|Microhabitat,|Behavior,WhatEating,HowMany,,_P_Species,,,,Notes";

	NSArray *cols = [kCSVColumns componentsSeparatedByString:@","];
	NSArray *fields = [fieldMap componentsSeparatedByString:@","];
	if ([fields count] != [cols count])
		return nil;

	BOOL isAnimal = ![self.Group isEqualToString:kTypePlant];

	NSMutableString *resultStr = [NSMutableString stringWithCapacity:100];
	NSUInteger idx = 0;
	for (NSString *col in cols)
	{
		NSString *value = nil;
		NSString *fieldName = [fields objectAtIndex:idx];
		if ([fieldName length] > 0)
		{
			BOOL skip = NO;
			BOOL isMultiValue = NO;

			if ([fieldName hasPrefix:@"_A_"])
			{
				skip = !isAnimal;
				fieldName = [fieldName substringFromIndex:3];
			}
			else if ([fieldName hasPrefix:@"_P_"])
			{
				skip = isAnimal;
				fieldName = [fieldName substringFromIndex:3];
			}
			else if ([fieldName hasPrefix:@"|"])
			{
				isMultiValue = YES;
				fieldName = [fieldName substringFromIndex:1];
			}

			if (!skip)
			{
				id valueObj = [self valueForKey:fieldName];
				if ([valueObj isKindOfClass:[NSString class]])
				{
					if (isMultiValue)
					{
						value = [valueObj
									stringByReplacingOccurrencesOfString:@"|"
									withString:@","];
					}
					else
						value = valueObj;
				}
				else if ([valueObj isKindOfClass:[NSNumber class]])
					value = [valueObj stringValue];
			}
		}
		else if ([col isEqualToString:@"date"])
			value = [self dateString:NO];
		else if ([col isEqualToString:@"time"])
			value = [self timeString:NO];
		else if ([col isEqualToString:@"how_exact"])
			value = [self howExactString];
		else if ([col isEqualToString:@"how_much_grass"])
			value = [self grassCoverageString];
		else if ([col isEqualToString:@"energy_role"])
			value = [self energyRoleString];
		else if ([col isEqualToString:@"consumer_type"])
			value = [self consumerTypeString];

		if (idx > 0)
			[resultStr appendString:@","];
		if ([value length] > 0)
		{
			// Replace all occurrences of " with "".
			// Surround with double quotes if necessary.
			NSString *escapedVal = [value
									stringByReplacingOccurrencesOfString:@"\""
									withString:@"\"\""];
			NSCharacterSet *specialChars =
				[NSCharacterSet characterSetWithCharactersInString:@"\r\n\","];
			NSRange r = [escapedVal rangeOfCharacterFromSet:specialChars];
			if (NSNotFound == r.location)
				[resultStr appendString:escapedVal];
			else
				[resultStr appendFormat:@"\"%@\"", escapedVal];
		}

		++idx;
	}

	return resultStr;
}


// May return nil.
- (NSString *)htmlString
{
	static NSString *htmlPrefix = @"<html><head></head>\n<body><table>\n";
	static NSString *htmlSuffix = @"</table></body></html>\n";

	NSMutableString *resultStr = [NSMutableString stringWithCapacity:300];
	[resultStr appendString:htmlPrefix];

	NSString *dateStr = [NSString stringWithFormat:@"<b>%@</b>",
												[self dateString:YES]];
	[resultStr appendFormat:kHTMLRowFmt, dateStr, [self timeString:YES]];
	[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelBioKIDSID"
						 value:self.BioKIDSID multiValue:NO];
	[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelTracker"
						 value:self.Tracker multiValue:NO];
	[self appendHTMLRow:resultStr label:nil value:self.Zone multiValue:NO];

	[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelSense"
						 value:self.HowSensed multiValue:YES];
	[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelWhatSensed"
				  value:self.WhatSensed multiValue:NO];
	NSString *s = (self.Group) ? [NSString stringWithFormat:@"%@:", self.Group]
							   : nil;
	[self appendHTMLRow:resultStr label:s value:self.Species multiValue:NO];

	NSString *grassCoverage = [self grassCoverageString];
	if (grassCoverage)
	{
		[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelHowMuch"
					  value:grassCoverage multiValue:NO];
	}
	else
	{
		NSInteger count = [self.HowMany integerValue];
		NSString *key = ([self.HowManyIsEstimated boolValue]) ? @"HTMLValueApproxFmt"
													: @"HTMLValueExactFmt";
		NSString *fmt = NSLocalizedString(key, nil);
		s = [NSString stringWithFormat:fmt, count];
		[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelHowMany"
							 value:s multiValue:NO];
	}

	[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelEnergyRole"
				  value:[self energyRoleString] multiValue:NO];
	[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelMicrohabitat"
				  value:self.Microhabitat multiValue:YES];
	[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelBehavior"
				  value:self.Behavior multiValue:YES];
	[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelEating"
				  value:self.WhatEating multiValue:NO];
	[self appendHTMLRowWithKey:resultStr labelKey:@"HTMLLabelNotes"
				  value:self.Notes multiValue:NO];

	[resultStr appendString:htmlSuffix];

//	NSLog(@"%@", resultStr);
	return resultStr;
}


#pragma mark Private Methods
- (void)appendHTMLRow:(NSMutableString *)aHTMLStr label:(NSString *)aLabel
				value:(NSString *)aValue multiValue:(BOOL)aIsMultiValue
{
	if (0 == [aValue length])
		return;

	NSString *s = aValue;

	// For values that may be multivalued, replace "|" with ", "
	if (aIsMultiValue)
		s = [s stringByReplacingOccurrencesOfString:@"|" withString:@", "];

	// Escape HTML special characters (<, >, &).
	s = [s stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
	s = [s stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	s = [s stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];

	// Replace newlines with <br>s.
	s = [s stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];

	if (!aLabel)
		aLabel = @"";
	[aHTMLStr appendFormat:kHTMLRowFmt, aLabel, s];
}


- (void)appendHTMLRowWithKey:(NSMutableString *)aHTMLStr
					labelKey:(NSString *)aKey
					   value:(NSString *)aValue
				  multiValue:(BOOL)aIsMultiValue
{
	NSString *label = NSLocalizedString(aKey, nil);
	[self appendHTMLRow:aHTMLStr label:label value:aValue
										multiValue:aIsMultiValue];
}

@end
