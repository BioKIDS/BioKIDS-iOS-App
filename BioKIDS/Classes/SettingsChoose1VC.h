/*
  SettingsChoose1VC.h
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

#import <UIKit/UIKit.h>


@interface SettingsChoose1VC : UITableViewController
{
	@private NSArray *mItems;
	@private NSString *mPrefKey;
	@private CGFloat mIconHeight;		// If <= 0, no icons are displayed.
	@private NSInteger mSelectedItemIndex;
}

@property (nonatomic, retain) NSArray *mItems;
@property (nonatomic, retain) NSString *mPrefKey;
@property (nonatomic, assign) CGFloat mIconHeight;
@property (nonatomic, assign) NSInteger mSelectedItemIndex;

// Public methods.
- (id)initWithList:(NSString *)aFileBaseName prefKey:(NSString *)aPrefKey
			 title:(NSString *)aTitle;

@end
