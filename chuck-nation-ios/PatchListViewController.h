//
//  PatchListViewController.h
//  chuck-nation-ios
//
//  Created by Mark Cerqueira on 6/16/16.
//
//

#import <UIKit/UIKit.h>

@interface PatchListViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *loadingView;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITableView *patchTableView;

- (IBAction)documentationPressed:(id)sender;
- (IBAction)featuredPressed:(id)sender;
- (IBAction)allPressed:(id)sender;
- (IBAction)uploadOneDemo:(id)sender;
- (IBAction)uploadAllDemos:(id)sender;

@end

