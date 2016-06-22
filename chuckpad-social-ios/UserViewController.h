//
//  UserViewController.h
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/21/16.
//
//

#import <UIKit/UIKit.h>

@interface UserViewController : UIViewController

// Current User Header Label
@property (weak, nonatomic) IBOutlet UILabel *currentUserLabel;

// Change Password
@property (weak, nonatomic) IBOutlet UITextField *changePasswordTextField;
- (IBAction)changePasswordSubmitPressed:(id)sender;

// Log Out
- (IBAction)logoutPressed:(id)sender;

// Create User
@property (weak, nonatomic) IBOutlet UITextField *createUserUsernameField;
@property (weak, nonatomic) IBOutlet UITextField *createUserPasswordField;
@property (weak, nonatomic) IBOutlet UITextField *createUserEmailField;
- (IBAction)createUserPressed:(id)sender;

// Login
@property (weak, nonatomic) IBOutlet UITextField *loginUsernameEmailField;
@property (weak, nonatomic) IBOutlet UITextField *loginPasswordField;
- (IBAction)loginSubmitPressed:(id)sender;

@end
