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
#import "ChuckNation.h"

@interface ViewController ()

@end

@implementation ViewController {
    @private
    NSArray *patchArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.

    // Push stuff below status bar
    self.patchTableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);

    [self.loadingView setHidden:YES];
    [self.contentView setHidden:YES];
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
    cell.detailTextLabel.text = [patch description];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Patch *patch = patchArray[indexPath.row];
    
    NSLog(@"Need to download patch at: %@", patch.resourceUrl);
}

- (void)showLoadingPatchesView {
    [self.loadingView setHidden:NO];
    [self.contentView setHidden:YES];
}

- (void)patchLoadingCompletion:(NSArray *)patchList withError:(NSError *)error {
    [self.loadingView setHidden:YES];
    [self.contentView setHidden:NO];
    
    patchArray = patchList;
    
    [self.patchTableView reloadData];
}

- (IBAction)documentationPressed:(id)sender {
    [self showLoadingPatchesView];
    
    [[ChuckNation sharedInstance] getDocumentationPatches:^(NSArray *patchesArray, NSError *error) {
        [self patchLoadingCompletion:patchesArray withError:error];
    }];
}

- (IBAction)featuredPressed:(id)sender {
    [self showLoadingPatchesView];

    [[ChuckNation sharedInstance] getFeaturedPatches:^(NSArray *patchesArray, NSError *error) {
        [self patchLoadingCompletion:patchesArray withError:error];
    }];
}

- (IBAction)allPressed:(id)sender {
    [self showLoadingPatchesView];

    [[ChuckNation sharedInstance] getAllPatches:^(NSArray *patchesArray, NSError *error) {
        [self patchLoadingCompletion:patchesArray withError:error];
    }];
}

@end
