//
//  Rename Finder Items with Regex.m
//  Rename Finder Items with Regex
//
//  Created by Patrick Marschik on 12/5/09.
//  Copyright (c) 2009 Technische Universitaet Wien, All Rights Reserved.
//

#import <AGRegex/AGRegex.h>

#import "Rename Finder Items with Regex.h"

#define RRX_OPT_CASEINSENSITIVE @"caseInsensitive"
#define RRX_OPT_EXTENDED        @"extended"
#define RRX_OPT_LAZY            @"lazy"
#define RRX_PATTERN             @"pattern"
#define RRX_REPLACE             @"replace"
#define RRX_COMPONENT           @"component"


@interface Rename_Finder_Items_with_Regex ()

- (void)setOptionsFromProperties;
- (void)updateParametersWithDictionary:(NSDictionary *)parameters;

@end


@implementation Rename_Finder_Items_with_Regex


#pragma mark Initializers

- (id)initWithDefinition:(NSDictionary *)dict
			 fromArchive:(BOOL)archived
{
	self = [super initWithDefinition:dict fromArchive:archived];
	
	if (!self) return self;
	
	NSDictionary *parameters = [dict objectForKey:@"ActionParameters"];
	[self updateParametersWithDictionary:parameters];
	
	return self;
}


#pragma mark Private Methods

- (void)updateParametersWithDictionary:(NSDictionary *)parameters
{
	caseInsensitive = [[parameters objectForKey:RRX_OPT_CASEINSENSITIVE] boolValue];
	extended = [[parameters objectForKey:RRX_OPT_EXTENDED] boolValue];
	lazy = [[parameters objectForKey:RRX_OPT_EXTENDED] boolValue];
	
	[self setOptionsFromProperties];
	
	pattern = [parameters objectForKey:RRX_PATTERN];
	replace = [parameters objectForKey:RRX_REPLACE];
	component = [[parameters objectForKey:RRX_COMPONENT] intValue];
}

- (void)setOptionsFromProperties
{
	options = 0;
	if (caseInsensitive) options |= AGRegexCaseInsensitive;
	if (extended) options |= AGRegexExtended;
	if (lazy) options |= AGRegexLazy;
}


#pragma mark Implementation of AMBundleAction

- (void)updateParameters
{
	[self updateParametersWithDictionary:[self parameters]];
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	if (!input || !(pattern))
		return nil;
	
	AGRegex *regex = [AGRegex regexWithPattern:pattern options:options];
	
	if (!regex){
		*errorInfo = [NSDictionary dictionaryWithObjectsAndKeys: @"Invalid Regex", NSAppleScriptErrorMessage,
					  [NSNumber numberWithInt:-128], NSAppleScriptErrorNumber,
					  nil];
		
		return nil;
	}
	
	if (!replace){
		*errorInfo = [NSDictionary dictionaryWithObjectsAndKeys: @"Nothing to do", NSAppleScriptErrorNumber,
					  nil];
		
		return nil;
	}
	
	NSArray *inputArray = [input isKindOfClass:[NSArray class]] ? input : [NSArray arrayWithObject:input];
	NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:[inputArray count]];
	
	for (NSString *originalPath in inputArray) {
		NSString *basepath = [originalPath stringByDeletingLastPathComponent];
		NSString *filename = [originalPath lastPathComponent];
		NSString *extension = [filename pathExtension];
		
		/* if filename only remove extension */
		if (component == 1 && [extension length] != 0) {
			NSRange replaceRange = NSMakeRange([filename length] - [extension length] - 1, [extension length] + 1);
			
			filename = [filename stringByReplacingCharactersInRange:replaceRange withString:@""];
		}
		
		NSString *renamedFilename = filename;
		NSString *renamedExtension = extension;
		
		if(component == 0 || component == 1) /* complete or filename only */
			renamedFilename = [regex replaceWithString:replace inString:renamedFilename];
		else if(component == 2) /* extension only */
			renamedExtension = [regex replaceWithString:replace inString:renamedExtension];
		
		NSString *renamedPath = renamedFilename;
		
		if (component == 1 || component == 2) /* if we separated filename/extension ... */
			renamedPath = [renamedFilename stringByAppendingPathExtension:renamedExtension];
		
		if (!renamedPath || [renamedPath length] == 0) {
			*errorInfo = [NSDictionary dictionaryWithObjectsAndKeys: @"Resulting in empty filename", NSAppleScriptErrorNumber,
						  nil];
			
			return nil;
		}
		
		renamedPath = [basepath stringByAppendingPathComponent:renamedPath];
		
		NSError *error;
		BOOL success = [[NSFileManager defaultManager] moveItemAtPath:originalPath
															   toPath:renamedPath
																error:&error];
		
		if(!success) {
			NSLog(@"Error renaming file: %@", [error description]);
		}
		
		[returnArray addObject:renamedPath];
	}
	
	return returnArray;
}

@end
