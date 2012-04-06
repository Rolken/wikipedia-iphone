//
//  WikiViewController.h
//  Wikipedia Mobile
//
//  Created by Andreas Lengyel on 2/18/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Wikipedia_MobileAppDelegate.h"
#import "MapViewController.h"
#import "MBProgressHUD.h"
#import "WikiWebViewIntermediaryDelegate.h"

@interface WikiViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate, MBProgressHUDDelegate>

@property (nonatomic, retain) Wikipedia_MobileAppDelegate *appDelegate;

@property (nonatomic, retain) NSString *wikiEntryURL;
@property (nonatomic, retain) NSString *pageTitle;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) WikiWebViewIntermediaryDelegate *webViewIntermediaryDelegate;
@property (nonatomic, retain) MapViewController *superView;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;	

- (IBAction)addBookmark;
- (IBAction)showHistory;
- (void)showLoadingHUD;
- (void)addRecentPage:(NSString *)pageName;
- (void)addBookmark:(NSString *)pageName;

@end
