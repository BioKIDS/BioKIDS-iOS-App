/*
  OrgInfoVC.h
  Created 2/18/11.

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

@protocol InfoVCDelegate;

@interface InfoVC : UIViewController<UIWebViewDelegate>
{
	@private id<InfoVCDelegate> mDelegate;
	@private NSString *mFileBaseName;
	@private NSString *mHTMLText;
	UIWebView *mWebView;
}

@property (nonatomic, assign) id<InfoVCDelegate> mDelegate;
@property (nonatomic, retain) NSString *mFileBaseName;
@property (nonatomic, retain) NSString *mHTMLText;
@property (nonatomic, retain) IBOutlet UIWebView *mWebView;

// Methods:
// Pass a non-nil aDelegate to one of the init'ers to get a delete button.
- (id)initWithHTMLFile:(NSString *)aFileBaseName title:(NSString *)aTitle
			  delegate:(id<InfoVCDelegate>)aDelegate;
- (id)initWithHTMLText:(NSString *)aText title:(NSString *)aTitle
			  delegate:(id<InfoVCDelegate>)aDelegate;
@end

@protocol InfoVCDelegate<NSObject>
@required
- (void) InfoVCDeletePressed:(UIBarButtonItem *)aDeleteBtn;
@end
