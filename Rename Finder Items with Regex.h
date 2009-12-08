//
//  Rename Finder Items with Regex.h
//  Rename Finder Items with Regex
//
//  Created by Patrick Marschik on 12/5/09.
//  Copyright (c) 2009 Technische Universitaet Wien, All Rights Reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>

@interface Rename_Finder_Items_with_Regex : AMBundleAction 
{
	// regex params
	BOOL caseInsensitive;
	BOOL dotAll;
	BOOL extended;
	BOOL lazy;
	int options;
	
	NSString *pattern;
	NSString *replace;
	NSInteger component;
}

- (id)initWithDefinition:(NSDictionary *)dict
			 fromArchive:(BOOL)archived;

- (id)runWithInput:(id)input
		fromAction:(AMAction *)anAction
			 error:(NSDictionary **)errorInfo;

- (void)updateParameters;

@end
