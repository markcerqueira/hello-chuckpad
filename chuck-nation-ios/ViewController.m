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

NSMutableArray *patchArray;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.

    // NSURL *url = [[NSURL alloc] initWithString:@"https://chuck-nation.herokuapp.com/patch/json/documentation"];
    NSURL *url = [[NSURL alloc] initWithString:@"https://chuck-nation.herokuapp.com/patch/json/all"];

    [self.loadingView setHidden:NO];
    [self.contentView setHidden:YES];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    [manager GET:url.absoluteString parameters:nil progress:nil
         success:^(NSURLSessionTask *task, id responseObject) {
             if (patchArray == nil) {
                 patchArray = [[NSMutableArray alloc] init];
             }
             
             [patchArray removeAllObjects];
             
             for (id object in responseObject) {
                 // NSLog(@"JSON Object: %@", object);
                 Patch *patch = [[Patch alloc] initWithDictionary:object];
                 NSLog(@"Patch: %@", patch.description);
                 [patchArray addObject:patch];
             }

             [self.loadingView setHidden:YES];
             [self.contentView setHidden:NO];
             
             [self.patchTableView reloadData];
             
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [patchArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PatchCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"PatchCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    Patch *patch = patchArray[indexPath.row];
    
    cell.textLabel.text = patch.name;
    cell.detailTextLabel.text = patch.resourceUrl;

    return cell;
}


@end
