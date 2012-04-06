//
//  WikiConnectionController.m
//  Wikipedia Mobile
//
//  Created by preilly on 1/4/12.
//  Copyright (c) 2012 Wikipedia Mobile. All rights reserved.
//

#import "WikiConnectionController.h"

@interface WikiConnectionController ()

@property (nonatomic, retain) NSMutableData* receivedData;

@end

@implementation WikiConnectionController

@synthesize connectionDelegate;
@synthesize succeededAction;
@synthesize failedAction;
@synthesize receivedData;

- (id)initWithDelegate:(id)delegate selectorForSuccess:(SEL)succeeded selectorForFailure:(SEL)failed {
    if ((self = [super init])) {
        self.connectionDelegate = delegate;
        self.succeededAction = succeeded;
        self.failedAction = failed;
    }
    return self;
}

-(void)dealloc {
    [connectionDelegate release];
    [super dealloc];
}

- (BOOL)startRequestForURL:(NSURL*)url {
    NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url];
    // cache and policy handling could go here
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    urlRequest.HTTPMethod = @"POST";
    urlRequest.HTTPShouldHandleCookies = YES;
    NSURLConnection* connectionResponse = [[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self] autorelease];

    if (!connectionResponse)
    {
        // possibly handle the error?
        return NO;
    } else {
        self.receivedData = [[[NSMutableData data] retain] autorelease];
    }
    return YES;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
    self.receivedData.length = 0;
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    [connectionDelegate performSelector:failedAction withObject:error];
    self.receivedData = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    [connectionDelegate performSelector:succeededAction withObject:self.receivedData];
    self.receivedData = nil;
}

@end