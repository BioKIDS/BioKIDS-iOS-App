/*
  ObservationCell.m
  Created 9/2/11.

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

#import "ObservationCell.h"


@implementation ObservationCell

@synthesize mZoneLabel, mDidInheritCharacteristics;

// Define constants
const CGFloat kZoneLabelWidth = 100.0;
const CGFloat kZoneLabelMargin = 8.0;

- (id)initWithReuseIdentifier:(NSString *)aReuseID
{
	self = [super initWithStyle:UITableViewCellStyleSubtitle
				reuseIdentifier:aReuseID];
	if (self)
	{
		self.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;

		// Add right-aligned label for zone.
		CGRect r = {0.0};  // Adjusted in layoutSubviews
		self.mZoneLabel = [[[UILabel alloc] initWithFrame:r] autorelease];
		self.mZoneLabel.textAlignment = NSTextAlignmentRight;
		self.mZoneLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		[self.contentView addSubview:self.mZoneLabel];
	}

	return self;
}


- (void)dealloc
{
	self.mZoneLabel = nil;

	[super dealloc];
}


- (void) prepareForReuse
{
	self.mDidInheritCharacteristics = NO;

	[super prepareForReuse];
}


- (void) layoutSubviews
{
	[super layoutSubviews];

	if (!self.mDidInheritCharacteristics)
	{
		self.mZoneLabel.font = self.detailTextLabel.font;
 		self.mZoneLabel.textColor = self.detailTextLabel.textColor;
		self.mDidInheritCharacteristics = YES;
	}

	CGFloat contentWidth = self.contentView.frame.size.width;
	CGRect detailRect = self.detailTextLabel.frame;
	detailRect.size.width = contentWidth -
				(kZoneLabelWidth + 2 * kZoneLabelMargin) - detailRect.origin.x;
	self.detailTextLabel.frame = detailRect;

	CGFloat zoneOriginX = contentWidth - (kZoneLabelWidth + kZoneLabelMargin);
	CGRect zoneRect = CGRectMake(zoneOriginX, detailRect.origin.y,
								 kZoneLabelWidth, detailRect.size.height);
	self.mZoneLabel.frame = zoneRect;
}


#pragma mark Getters and Setters:
- (NSString *)zoneName
{
	return self.mZoneLabel.text;
}


- (void)setZoneName:(NSString *)aZoneName
{
	self.mZoneLabel.text = aZoneName;
}

@end
