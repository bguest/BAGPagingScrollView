/**
 * BAGPagingScrollView.m
 * iRefKickballLite
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions are met:
 * 
 * -Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 * -Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the 
 *  documentation and/or other materials provided with the distribution.
 * -Neither the name of Benjamin Guest nor the names of its 
 *  contributors may be used to endorse or promote products derived from 
 *  this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE. 
 */

#import <UIKit/UIKit.h>

@protocol BAGPagingScrollViewDataSource;


@interface BAGPagingScrollView : UIView <UIScrollViewDelegate> {
    
    id<BAGPagingScrollViewDataSource> dataSource;	//data source delegate
	
	UIScrollView		*scrollView;		//internal scroll view
	NSMutableDictionary	*viewBuffer;		//temporary view buffer
	
@private
	NSInteger	pageIndex;	//current page index
    
    //Views Used
	UIView* pageView[3];
	UIPageControl* pageControl;
}
@property(nonatomic, assign) IBOutlet id<BAGPagingScrollViewDataSource> dataSource;


//Usage
- (void)goToPage:(int)page;
- (void)nextPage;
- (void)previousPage;
- (void)clearBuffer;

@end

@protocol BAGPagingScrollViewDataSource <NSObject>

@optional
- (NSInteger)numberOfPagesForPagingScrollView:(BAGPagingScrollView*)aPageingScrollView;

@required
- (UIView*)pagingScrollView:(BAGPagingScrollView*)pagingScrollView
          viewForPageIndex:(int)index;

@end