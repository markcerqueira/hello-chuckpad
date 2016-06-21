//
//  PatchListViewController.m
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/16/16.
//
//

#import "PatchListViewController.h"
#import "AFNetworking.h"
#import "Patch.h"
#import "ChuckPadSocial.h"

@interface PatchListViewController ()

@end

@implementation PatchListViewController {
    @private
    NSArray *patchArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.

    // Push stuff below status bar
    // TODO There must be a better way to do this (and Table View bleeds off right edge too)
    self.patchTableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);

    [self.loadingView setHidden:YES];
    [self.contentView setHidden:YES];
    
    [self refreshEnvironmentLabel];
}

- (void)refreshEnvironmentLabel {
    self.environmentLabel.text = [[ChuckPadSocial sharedInstance] getBaseUrl];
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
    
    [[ChuckPadSocial sharedInstance] getDocumentationPatches:^(NSArray *patchesArray, NSError *error) {
        [self patchLoadingCompletion:patchesArray withError:error];
    }];
}

- (IBAction)featuredPressed:(id)sender {
    [self showLoadingPatchesView];

    [[ChuckPadSocial sharedInstance] getFeaturedPatches:^(NSArray *patchesArray, NSError *error) {
        [self patchLoadingCompletion:patchesArray withError:error];
    }];
}

- (IBAction)allPressed:(id)sender {
    [self showLoadingPatchesView];

    [[ChuckPadSocial sharedInstance] getAllPatches:^(NSArray *patchesArray, NSError *error) {
        [self patchLoadingCompletion:patchesArray withError:error];
    }];
}

- (IBAction)uploadOneDemo:(id)sender {
    NSString *filename = @"demo0.ck";
    
    NSString *chuckSamplesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"chuck-samples"];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", chuckSamplesPath, filename];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];

    [[ChuckPadSocial sharedInstance] uploadPatch:filename isFeatured:NO isDocumentation:YES filename:filename fileData:fileData];
}

- (IBAction)uploadAllDemos:(id)sender {
    NSString *chuckSamplesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"chuck-samples"];
    NSError *error;
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:chuckSamplesPath error:&error];
    
    for (NSString *filename in directoryContents) {
        // Skip files that do not end in .ck
        if (![filename hasSuffix:@".ck"]) {
            continue;
        }
        
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", chuckSamplesPath, filename];
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        
        NSLog(@"Filename = %@; data length = %lu", filename, (unsigned long)[fileData length]);

        [[ChuckPadSocial sharedInstance] uploadPatch:filename isFeatured:NO isDocumentation:YES filename:filename fileData:fileData];
    }
}

- (IBAction)environmentValueChanged:(id)sender {
    [[ChuckPadSocial sharedInstance] toggleEnvironment];
    [self refreshEnvironmentLabel];
}

@end
