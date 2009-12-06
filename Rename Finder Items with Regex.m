//
//  Rename Finder Items with Regex.m
//  Rename Finder Items with Regex
//
//  Created by Patrick Marschik on 12/5/09.
//  Copyright (c) 2009 Technische Universitaet Wien, All Rights Reserved.
//

#import <AGRegex/AGRegex.h>

#import "Rename Finder Items with Regex.h"

@implementation Rename_Finder_Items_with_Regex

- (void)updateParameters
{
	self->caseInsensitive = [[[self parameters] valueForKey:@"caseInsensitive"] boolValue];
	self->extended = [[[self parameters] valueForKey:@"extended"] boolValue];
	self->lazy = [[[self parameters] valueForKey:@"lazy"] boolValue];
	
	self->options = 0;
	if (caseInsensitive) self->options |= AGRegexCaseInsensitive;
	if (extended) self->options |= AGRegexExtended;
	if (lazy) self->options |= AGRegexLazy;
	
	self->pattern = [[self parameters] valueForKey:@"pattern"];
	self->replace = [[self parameters] valueForKey:@"replace"];
	
	self->component = [[[self parameters] valueForKey:@"component"] intValue];
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	if (!input || !self->pattern)
		return nil;
	
	AGRegex *regex = [AGRegex regexWithPattern:self->pattern options:self->options];
	
	if (!regex){
		*errorInfo = [NSDictionary dictionaryWithObjectsAndKeys: @"Invalid Regex", NSAppleScriptErrorMessage,
					  [NSNumber numberWithInt:-128], NSAppleScriptErrorNumber,
					  nil];
		
		return nil;
	}
	
	if (!self->replace){
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
		if (self->component == 1 && [extension length] != 0) {
			NSRange replaceRange = NSMakeRange([filename length] - [extension length] - 1, [extension length] + 1);
			
			filename = [filename stringByReplacingCharactersInRange:replaceRange withString:@""];
		}
		
		NSString *renamedFilename = filename;
		NSString *renamedExtension = extension;
		
		if(self->component == 0 || self->component == 1) /* complete or filename only */
			renamedFilename = [regex replaceWithString:self->replace inString:renamedFilename];
		else if(self->component == 2) /* extension only */
			renamedExtension = [regex replaceWithString:self->replace inString:renamedExtension];
		
		NSString *renamedPath = renamedFilename;
		
		if (self->component == 1 || self->component == 2) /* if we separated filename/extension ... */
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
			NSLog(@"Error: %@", [error description]);
		}
		
		[returnArray addObject:renamedPath];
	}
	
	return returnArray;
}

@end
