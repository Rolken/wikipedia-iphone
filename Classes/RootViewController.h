//
//  RootViewController.h
//  Wikipedia Mobile
//
//  Created by Andreas Lengyel on 2/3/10.
//  Copyright Wikimedia Foundation 2010. All rights reserved.
//

#import "Wikipedia_MobileAppDelegate.h"
#import "SBJson.h"
#import "MBProgressHUD.h"
#import "WikiWebViewIntermediaryDelegate.h"

@interface RootViewController : UIViewController <UISearchBarDelegate, UIWebViewDelegate, UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource, MBProgressHUDDelegate> {
	MBProgressHUD *HUD;
	NSTimer *timer;
	BOOL HUDvisible;
	
    BOOL _isDataSourceAvailable;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) WikiWebViewIntermediaryDelegate *webViewIntermediaryDelegate;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UIToolbar *toolBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, retain) NSString *pageTitle;
@property (nonatomic, retain) NSURL *externalURL;
@property (nonatomic, retain) IBOutlet UIView *shade;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;	

- (void)loadWikiEntry:(NSString *)url;
- (void)loadURL:(NSString *)url;
- (NSString *)currentURL;
- (IBAction)goBack;
- (IBAction)goForward;
- (IBAction)nearbyButton;
- (IBAction)addBookmark;
- (IBAction)showHistory;
- (IBAction)stopEditing;
- (void)showLoadingHUD;
- (void)loadStartPage;
- (void)reload;
- (void)addRecentPage:(NSString *)pageName;
- (void)addBookmark:(NSString *)pageName;
- (BOOL)isDataSourceAvailable;

@end
