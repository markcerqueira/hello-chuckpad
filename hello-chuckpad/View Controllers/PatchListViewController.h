//
//  PatchListViewController.h
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/16/16.
//
//

#import <UIKit/UIKit.h>

@interface PatchListViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *loadingView;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITableView *patchTableView;

@property (weak, nonatomic) IBOutlet UISwitch *environmentSwitch;
@property (weak, nonatomic) IBOutlet UILabel *environmentLabel;

- (IBAction)documentationPressed:(id)sender;
- (IBAction)featuredPressed:(id)sender;
- (IBAction)allPressed:(id)sender;
- (IBAction)uploadOneDemo:(id)sender;
- (IBAction)uploadAllDemos:(id)sender;
- (IBAction)environmentValueChanged:(id)sender;

@end

