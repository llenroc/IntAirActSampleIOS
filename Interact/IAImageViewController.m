//
//  IAImageViewController.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-20.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageViewController.h"

@interface IAImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation IAImageViewController

@synthesize imageURL = _imageURL;
@synthesize imageView = _imageView;

- (void)loadImage
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if (self.imageView) {
        if (self.imageURL) {
            dispatch_queue_t imageDownloadQ = dispatch_queue_create("Interact Image Downloader", NULL);
            dispatch_async(imageDownloadQ, ^{
                UIImage * image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.imageURL]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = image;
                });
            });
            dispatch_release(imageDownloadQ);
        } else {
            self.imageView.image = nil;
        }
    }
}

- (void)setImageURL:(NSURL *)imageURL
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if (![_imageURL isEqual:imageURL]) {
        _imageURL = imageURL;
        if (self.imageView.window) {    // we're on screen, so update the image
            [self loadImage];           
        } else {                        // we're not on screen, so no need to loadImage (it will happen next viewWillAppear:)
            self.imageView.image = nil; // but image has changed (so we can't leave imageView.image the same, so set to nil)
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.imageView.image && self.imageURL) [self loadImage];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidUnload
{
    self.imageView = nil;
    [super viewDidUnload];
}

@end
