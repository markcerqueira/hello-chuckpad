//
//  ViewController.m
//  chuck-nation-ios
//
//  Created by Mark Cerqueira on 6/16/16.
//
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "Patch.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.

    // NSURL *url = [[NSURL alloc] initWithString:@"https://chuck-nation.herokuapp.com/patch/json/documentation"];
    NSURL *url = [[NSURL alloc] initWithString:@"https://chuck-nation.herokuapp.com/patch/json/all"];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    [manager GET:url.absoluteString parameters:nil progress:nil
         success:^(NSURLSessionTask *task, id responseObject) {
             for (id object in responseObject) {
                 // NSLog(@"JSON Object: %@", object);
                 NSLog(@"Patch: %@", [[[Patch alloc] initWithDictionary:object] description]);
             }

             // NSLog(@"JSON List: %@", responseObject);
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"Error: %@", error);
         }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
