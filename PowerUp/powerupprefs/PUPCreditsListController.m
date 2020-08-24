#include "PUPCreditsListController.h"

#import <CepheiPrefs/HBTwitterCell.h>
#import <Cephei/NSString+HBAdditions.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIImage+Private.h>
#import <version.h>

@implementation PUPCreditsListController

+ (NSString *)hb_specifierPlist {
    return @"credits";
}
@end

@interface PUPTwitterCell : HBTwitterCell
@end

@implementation PUPTwitterCell : HBTwitterCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	

	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];



	if (self) {
		if(specifier.properties[@"smallText"] != nil){
			NSString *subtitle = [specifier.properties[@"smallText"] copy];
			self.detailTextLabel.text = [@"" stringByAppendingString:subtitle];
		}


	}
      
	return self;
}

@end