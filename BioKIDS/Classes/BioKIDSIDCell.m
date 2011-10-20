/*
  BioKIDSIDCell.m
  Created 4/23/10.

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

#import "BioKIDSIDCell.h"
#import "Constants.h"

@implementation BioKIDSIDCell

@synthesize mValue;

- (void) setupCell
{
	NSInteger val = [[NSUserDefaults standardUserDefaults]
						integerForKey:kBioKIDSIDKey];
	if (val != 0)
		self.mValue.text = [NSString stringWithFormat:@"%d", val];
	else
		self.mValue.text = @"";
}


- (void)dealloc
{
	self.mValue = nil;

    [super dealloc];
}


#pragma mark UIResponder Method Overrides
// Override touchesBegan to grab focus (and open the keyboard) when tap is
// inside this cell but outside our edit field, e.g., tap on the label.
- (void)touchesBegan:(NSSet *)aTouches withEvent:(UIEvent *)aEvent
{
	BOOL inTextField = NO;
	for (UITouch *touch in aTouches)
	{
		CGPoint pt = [touch locationInView:self];
		if (CGRectContainsPoint(self.mValue.frame, pt))
		{
			inTextField = YES;
			break;
		}
	}

	if (!inTextField)
		[self.mValue becomeFirstResponder];

	[super touchesBegan:aTouches withEvent:aEvent];
}


#pragma mark UITextFieldDelegate Methods
- (BOOL)textFieldShouldReturn:(UITextField *)aTextField
{
	// The user pressed the "Done" button, so dismiss the keyboard.
	[aTextField resignFirstResponder];
	return YES;
}


#pragma mark Other Public Methods
- (IBAction) onTextFieldChange:(id)aSender
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSString *t = self.mValue.text;
	NSInteger bkid = [t integerValue];
	if (0 != bkid)
		[ud setInteger:bkid forKey:kBioKIDSIDKey];
	else
		[ud removeObjectForKey:kBioKIDSIDKey];
}


// Returns YES if this was the first responder and keyboard was closed.
- (BOOL) closeKeyboard
{
	if ([self.mValue isFirstResponder])
	{
		[self.mValue resignFirstResponder];
		return YES;
	}

	return NO;
}

@end
