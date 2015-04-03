//
//  TGWebpageContainer.m
//  Telegram
//
//  Created by keepcoder on 01.04.15.
//  Copyright (c) 2015 keepcoder. All rights reserved.
//

#import "TGWebpageContainer.h"
#import "TGCTextView.h"
#import "TGPhotoViewer.h"
@interface TGWebpageContainer ()
@property (nonatomic,strong,readonly) TMView *containerView;
@end

@implementation TGWebpageContainer

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    
    [LINK_COLOR setFill];
    
    NSRectFill(NSMakeRect(0, 0, 2, NSHeight(self.frame)));
}

-(void)mouseDown:(NSEvent *)theEvent {
    
}



-(instancetype)initWithFrame:(NSRect)frameRect {
    if(self = [super initWithFrame:frameRect]) {
        
        _containerView = [[TMView alloc] initWithFrame:self.bounds];
        [_containerView setIsFlipped:YES];
        
        _containerView.wantsLayer = YES;
        
        [super addSubview:_containerView];
        
        
        _imageView = [[TGImageView alloc] initWithFrame:NSZeroRect];
        
        _imageView.cornerRadius = 4;
        
        [self addSubview:_imageView];
        
        _loaderView = [[TMLoaderView alloc] initWithFrame:NSMakeRect(0, 0, 40, 40)];
        
        [_loaderView setStyle:TMCircularProgressDarkStyle];
        
        
        [_imageView addSubview:_loaderView];
        
        
        dispatch_block_t block = ^ {
            [self showPhoto];
        };
        
        [_imageView setTapBlock:block];
        
        _descriptionField = [[TGCTextView alloc] initWithFrame:NSZeroRect];
        
        
        [self addSubview:_descriptionField];
        
        [_descriptionField setEditable:YES];
        
        
        self.author = [TMTextField defaultTextField];
        self.date = [TMTextField defaultTextField];
                
        
        [self addSubview:self.author];
        [self addSubview:self.date];
    }
    
    return self;
}


-(void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    [_containerView setFrame:NSMakeRect(7,0,NSWidth(frame) - 7,NSHeight(frame))];
}

-(void)addSubview:(NSView *)aView {
    [_containerView addSubview:aView];
}

-(void)setWebpage:(TGWebpageObject *)webpage {
    _webpage = webpage;
    
    
    [self.author setHidden:!webpage.author];
    [self.date setHidden:!webpage.date];
    
    if(webpage.author ) {
        [self.author setAttributedStringValue:webpage.author];
        [self.author setFrameSize:NSMakeSize([self maxTextWidth], 20)];
        [self.author setFrameOrigin:NSMakePoint([self textX], -4)];
    }
    
    if(webpage.date && webpage.author) {
        [self.date setStringValue:webpage.date];
        [self.date sizeToFit];
        [self.date setFrameOrigin:NSMakePoint(NSMaxX(self.author.frame) + 4, 0)];
    }
    
    
    [_imageView setObject:webpage.imageObject];
    
    [webpage.imageObject.supportDownloadListener setProgressHandler:^(DownloadItem *item) {
        
        [ASQueue dispatchOnMainQueue:^{
            
             [self.loaderView setProgress:item.progress animated:YES];
            
        }];
        
    }];
    
    [webpage.imageObject.supportDownloadListener setCompleteHandler:^(DownloadItem *item) {
        
        [ASQueue dispatchOnMainQueue:^{
            
            [self updateState:0];
            
        }];
        
    }];
    
}

-(BOOL)isFlipped {
    return YES;
}

-(void)updateState:(TMLoaderViewState)state {
    
    [self.loaderView setHidden:self.item.isset];
    
    [self.loaderView setState:state];
    
    [self.loaderView setProgress:self.webpage.imageObject.downloadItem.progress animated:NO];
    
    [self.loaderView setProgress:self.loaderView.currentProgress animated:YES];
    
    [self.loaderView setCenterByView:_imageView];

}

-(NSSize)containerSize {
    return _containerView.frame.size;
}

-(int)maxTextWidth {
    
    int width = self.containerSize.width;
    
    if([self.webpage.webpage.type isEqualToString:@"profile"]) {
        width = width - 75;
    }
    
    return width;
}

-(int)textX {
    
    if([self.webpage.webpage.type isEqualToString:@"profile"]) {
        return 65; // 60 + 5
    }
    
    return 0;
}

-(void)showPhoto {
    
    if(![self.webpage.webpage.type isEqualToString:@"profile"] && self.webpage.imageObject) {
        
        PreviewObject *previewObject =[[PreviewObject alloc] initWithMsdId:self.webpage.webpage.photo.n_id media:[self.webpage.webpage.photo.sizes lastObject] peer_id:0];
        
        previewObject.reservedObject = self.imageView.image;
        
        if([self.webpage.webpage.type isEqualToString:@"video"] && [self.webpage.webpage.embed_type isEqualToString:@"video/mp4"]) {
            
            previewObject.reservedObject = @{@"url":[NSURL URLWithString:self.webpage.webpage.embed_url],@"size":[NSValue valueWithSize:NSMakeSize(self.webpage.webpage.embed_width, self.webpage.webpage.embed_height)]};
            
        }
        
        [[TGPhotoViewer viewer] show:previewObject];
        
    } else {
        if([self.webpage.webpage.type isEqualToString:@"profile"]) {
            open_link(self.webpage.webpage.display_url);
        }
    }
}

@end