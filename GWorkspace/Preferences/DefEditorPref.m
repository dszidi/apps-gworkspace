/* DefEditorPref.m
 *  
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: August 2001
 *
 * This file is part of the GNUstep GWorkspace application
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "FSNodeRep.h"
#include "DefEditorPref.h"
#include "GWorkspace.h"
#include "GNUstep.h"
#include <math.h>

#define LABEL_MARGIN 8
#define ICON_SIZE 48

static NSString *nibName = @"DefEditorPref";

@implementation DefEditorPref

- (void)dealloc
{
  TEST_RELEASE (prefbox);
  TEST_RELEASE (ednode);
  RELEASE (noEditorStr);
  RELEASE (font);
  [super dealloc];
}

- (id)init
{
  self = [super init];
  
  if (self) {  
    ASSIGN (font, [NSFont systemFontOfSize: 12]);
    ASSIGN (noEditorStr, NSLocalizedString(@"No Default Editor", @""));
  
		if ([NSBundle loadNibNamed: nibName owner: self] == NO) {
      NSLog(@"failed to load %@!", nibName);
    } else {
	    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];   
      NSString *editor = [defaults stringForKey: @"defaulteditor"];
      
      RETAIN (prefbox);
      iconBoxWidth = [iconbox frame].size.width;
      labelHeight = [nameLabel frame].size.height;
      labelOrigin = [nameLabel frame].origin;      
      RELEASE (win);
      
      fsnodeRep = [FSNodeRep sharedInstance];
		  ws = [NSWorkspace sharedWorkspace];
      
      [imView setImageScaling: NSScaleProportionally];
      
      if (editor) {
        NSString *path = [ws fullPathForApplication: editor];
        
        if (path) {
          NSImage *image;      

		      ASSIGN (ednode, [FSNode nodeWithPath: path]);
          image = [fsnodeRep iconOfSize: ICON_SIZE forNode: ednode];
          [imView setImage: image];

	        [nameLabel setStringValue: [ednode name]];
          [self tile];
        } else {
	        [nameLabel setStringValue: noEditorStr];
          [self tile];
        }
      } else {
	      [nameLabel setStringValue: noEditorStr];
        [self tile];
      }
      
      /* Internationalization */
      [chooseButt setTitle: NSLocalizedString(@"Choose", @"")];
      [iconbox setTitle: NSLocalizedString(@"Default Editor", @"")];
    }
  }
  
  return self;
}

- (NSView *)prefView
{
  return prefbox;
}

- (NSString *)prefName
{
  return NSLocalizedString(@"Editor", @"");
}

- (IBAction)chooseEditor:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSArray *fileTypes = [NSArray arrayWithObjects: @"app", @"debug", nil];
	FSNode *node;
	int result;

	[openPanel setTitle: @"open"];	
  [openPanel setAllowsMultipleSelection: NO];
  [openPanel setCanChooseFiles: YES];
  [openPanel setCanChooseDirectories: NO];

  result = [openPanel runModalForDirectory: NSHomeDirectory() file: nil types: fileTypes];
	if(result != NSOKButton) {
		return;
  }
  
	node = [FSNode nodeWithPath: [openPanel filename]];
  
  if ([node isApplication] == NO) {
    NSRunAlertPanel(nil, 
        [NSString stringWithFormat: @"%@ is not a valid application!", [node name]], 
                            @"Continue", nil, nil);  
    return;
  }	
      
  [self setEditor: [node name]];
}

- (void)setEditor:(NSString *)editor
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];     
  NSString *path;
  NSImage *image;
  
  if ([editor isEqual: [ednode name]]) {
    return;
  }
  
  path = [ws fullPathForApplication: editor];
        
  ASSIGN (ednode, [FSNode nodeWithPath: path]);
  image = [fsnodeRep iconOfSize: ICON_SIZE forNode: ednode];
  [imView setImage: image];
  
  [nameLabel setStringValue: [ednode name]];
  [self tile];
   
	[defaults setObject: [ednode name] forKey: @"defaulteditor"];
	[defaults synchronize];

	[[NSDistributedNotificationCenter defaultCenter]
 				postNotificationName: @"GWDefaultEditorChangedNotification"
	 								    object: [ednode name] 
                    userInfo: nil];
}

- (void)tile
{
  NSRect r = [nameLabel frame];
  int labw = (int)[font widthOfString: [nameLabel stringValue]] + LABEL_MARGIN;
  NSPoint p = NSMakePoint(0, labelOrigin.y);
  
  r.size.width = labw;
  [nameLabel setFrame: r];
          
  p.x = ((iconBoxWidth - [nameLabel frame].size.width) / 2);        
  [nameLabel setFrameOrigin: p]; 

  [iconbox setNeedsDisplay: YES];
}

@end








