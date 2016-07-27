//
//  UserViewController.m
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/21/16.
//
//

#import "UserViewController.h"
#import "ChuckPadSocial.h"

@interface UserViewController ()

@end

@implementation UserViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self refreshCurrentUserLabel];
}

- (void)refreshCurrentUserLabel {
    if ([[ChuckPadSocial sharedInstance] isLoggedIn]) {
        self.currentUserLabel.text = [NSString stringWithFormat:@"Logged in as %@", [[ChuckPadSocial sharedInstance] getLoggedInUserName]];
    } else {
        self.currentUserLabel.text = @"No user is logged in";
    }
    
    self.changePasswordTextField.text = @"";
    
    self.createUserUsernameField.text = @"";
    self.createUserEmailField.text = @"";
    self.createUserPasswordField.text = @"";
    
    self.loginUsernameEmailField.text = @"";
    self.loginPasswordField.text = @"";
}

- (IBAction)changePasswordSubmitPressed:(id)sender {
    [[ChuckPadSocial sharedInstance] changePassword:self.changePasswordTextField.text callback:^(BOOL succeeded, NSError *error) {
        NSLog(@"%@", [NSString stringWithFormat:@"changePassword - callback with success = %d", succeeded]);
    }];
}

- (IBAction)logoutPressed:(id)sender {
    [[ChuckPadSocial sharedInstance] logOut];
    [self refreshCurrentUserLabel];
}

- (IBAction)createUserPressed:(id)sender {
    NSString *username = self.createUserUsernameField.text;
    NSString *email = self.createUserEmailField.text;
    NSString *password = self.createUserPasswordField.text;

    [[ChuckPadSocial sharedInstance] createUser:username email:email password:password callback:^(BOOL success, NSError *error) {
        NSLog(@"%@", [NSString stringWithFormat:@"createUser - callback with success = %d", success]);
        [self refreshCurrentUserLabel];
    }];
}

- (IBAction)loginSubmitPressed:(id)sender {
    NSString *usernameOrEmail = self.loginUsernameEmailField.text;
    NSString *password = self.loginPasswordField.text;

    [[ChuckPadSocial sharedInstance] logIn:usernameOrEmail password:password callback:^(BOOL success, NSError *error) {
        NSLog(@"%@", [NSString stringWithFormat:@"logIn - callback with success = %d", success]);
        [self refreshCurrentUserLabel];
    }];
}

@end
