//
//  ViewController.h
//  chuck-nation-ios
//
//  Created by Mark Cerqueira on 6/16/16.
//
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *loadingView;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITableView *patchTableView;

@end

