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

#import "BAGPagingScrollView.h"

#define MAX_BUFFER_SIZE 5
/*
 * Returns the correct modulus
 * http://stackoverflow.com/questions/1082917/mod-of-negative-number-is-melting-my-brain
 */
int intMod(int num, int denom) {
    int r = num%denom;
    return r<0 ? r+denom : r;
}

// Defines a modulus when the denominator = 0
int BAGintMod(int num, int denom){
	return (denom == 0 ? num : intMod(num, denom));
}

@interface BAGPagingScrollView ()
    
- (void) setup;
- (void) checkViewBuffer;
- (UIView*)viewForIndex:(int)index;
- (NSInteger)numberOfPages;
- (CGSize)pageSize;
- (void)getPreviousPage;
- (void)getNextPage;
- (void)pageControllValueChanged;
- (BOOL)removeViewsFromBuffer:(int)numberOfViews;

@property(nonatomic, retain) UIScrollView *scrollView;

@end

@implementation BAGPagingScrollView
//-----------------------------------------------------------------------------
@synthesize scrollView;

@synthesize dataSource;
- (void)setDataSource:(id<BAGPagingScrollViewDataSource>)aDataSource{
	dataSource = aDataSource;
	
	//Setup Page Controll
	if ([dataSource respondsToSelector:@selector(numberOfPagesForPagingScrollView:)]){
		int numberOfPages = [dataSource numberOfPagesForPagingScrollView:self];
		//TODO: add logic to limit the number of pages that can be displayed.
		pageControl.numberOfPages = numberOfPages; 
	}
	
	//initialize first pages
	[self goToPage:0];
}


- (void)dealloc {
	[pageControl release];
	[scrollView release];
	
    [super dealloc];
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setup];
    }
    return self;
}

//For use with Interface Builder
- (id)initWithCoder:(NSCoder *)aDecoder{
	if((self = [super initWithCoder:aDecoder])){
		[self setup];
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


#pragma mark Usage

- (void)goToPage:(int)page{

	CGSize pageSize = self.pageSize;
	
	int modPage;
	int totalPages = self.numberOfPages;
	
	for(int i = 0 ; i < 3 ; i++)
	{
		[pageView[i] removeFromSuperview];					//Remove old view
		
		modPage = (totalPages > 0 ? intMod(page-1+i,totalPages) : page);
		pageView[i] = [self viewForIndex:modPage];		//Get New View
				
		//Place new view in correct place
		pageView[i].center = CGPointMake((.5+i)*pageSize.width, pageSize.height/2);
				
		[self.scrollView addSubview:pageView[i]];		//Add to scrollview
	}	

	self.scrollView.contentOffset = CGPointMake(pageSize.width, 0);
	[self.scrollView setNeedsDisplay];
	
	pageIndex = page;
	[self checkViewBuffer];
}

/**
 * This methos animates views moving one to the left and then updates the views
 */
- (void)nextPage{
	CGFloat pageWidth = self.pageSize.width;
	[self getNextPage];
	self.scrollView.contentOffset = CGPointMake(0, 0);
	[self.scrollView setNeedsDisplay];
	[self.scrollView setContentOffset:CGPointMake(pageWidth, 0)
							 animated:YES];
}
/**
 * This methos animates views moving one to the right and then updates the views
 */
- (void)previousPage{
	CGFloat pageWidth = self.pageSize.width;
	[self getPreviousPage];
	self.scrollView.contentOffset = CGPointMake(pageWidth*2, 0);
	[self.scrollView setNeedsDisplay];
	[self.scrollView setContentOffset:CGPointMake(pageWidth, 0)
							 animated:YES];
}


#pragma mark -
#pragma mark "Private" methods

// Do the intial setup of the infinite paging view.
- (void) setup
{
	//init page index
	pageIndex = 0;
	
	//init view buffer
	viewBuffer = [[NSMutableDictionary alloc] init];
	
	//setup view
	self.backgroundColor = [UIColor clearColor];
	
	//init scroll view
	self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
	scrollView.backgroundColor = [UIColor clearColor];
	scrollView.pagingEnabled = YES;
	scrollView.delegate = self;
	scrollView.scrollEnabled = YES;
	scrollView.showsHorizontalScrollIndicator = NO;
	//scrollView.bounces = YES;
	
	//Set Content Size
	CGSize	contentSize	= scrollView.frame.size;
	CGFloat pageWidth = contentSize.width;
	contentSize.width = 3*pageWidth;
	scrollView.contentSize = contentSize;
	scrollView.contentOffset = CGPointMake(0, 0);
	
	//add scroll view
	[self addSubview:scrollView];
	
	//Set up page controll
	CGFloat height = 20;
	CGSize pageSize = self.pageSize;
	CGRect pageControlFrame= CGRectMake(0, pageSize.height-height,
										pageSize.width, height);
	pageControl = [[UIPageControl alloc] initWithFrame:pageControlFrame];
	[pageControl addTarget:self action:@selector(pageControllValueChanged) 
		  forControlEvents:UIControlEventValueChanged ];
	[self addSubview:pageControl];
}

/**
 * Returns the UIView for the specified index, checks buffer first before
 * Asking the data source for the UIView
 */
- (UIView*)viewForIndex:(int)index{
	
	NSInteger totalPages = self.numberOfPages;
	
	if(index < 0 && totalPages == 0)
		return nil;
	
	//Get Correct Index
    NSInteger modIdx = (totalPages > 0 ? intMod(index,totalPages) : index);
	
	//check if view is allready within the view buffer
	UIView *view = [viewBuffer objectForKey:[NSNumber numberWithInt:modIdx]];
	
	if( view == nil)
	{
		//get view from data source
		view = [self.dataSource pagingScrollView:self viewForPageIndex:modIdx];
		[viewBuffer setObject:view forKey:[NSNumber numberWithInt:modIdx]];
		[self checkViewBuffer];
	}
	return view;
}

// Check if view buffer violates the max. view
// buffer size and clean it up if necessary.
- (void) checkViewBuffer
{
	int removeableViews = [viewBuffer count] - MAX_BUFFER_SIZE;
	if (removeableViews > 0)
		[self removeViewsFromBuffer:removeableViews]; 
}

/**
 *  This view method trys to compleaty clear the buffer
 */
- (void)clearBuffer{
	[self removeViewsFromBuffer:[viewBuffer count] - 3];
}
		   
/**
 *  Removes one view from the buffer if possible
 *  Returns number of views that can safely be removed
 */
- (BOOL)removeViewsFromBuffer:(int)numberOfViews{
	
	int i = 0;
	int remainingViews = [viewBuffer count] - 3;
	
	//Precheck to make sure we are not doing needless work;
	if (remainingViews <= 0)
		return remainingViews; 
	
	//Get Required Indexes
	int totalPages = [self numberOfPages];
	
	int plusIdx, currIdx, minusIdx;
	if (totalPages > 0){
		plusIdx	= intMod(pageIndex+1,totalPages);
		currIdx	= intMod(pageIndex,totalPages);
		minusIdx= intMod(pageIndex-1,totalPages);
	}else {
		plusIdx = pageIndex+1;
		currIdx = pageIndex;
		minusIdx = pageIndex-1;
	}
	
	//Find views that can safely be removed
	int testValue;
	for (NSNumber *page in [viewBuffer allKeys]) 
	{
		testValue = [page intValue];
		if(testValue != plusIdx && testValue != currIdx && testValue != minusIdx)
		{
			UIView *view = [viewBuffer objectForKey:page];
			[view removeFromSuperview];
			[viewBuffer removeObjectForKey:page];
			remainingViews--;
			i++;
		}
		if(i >= numberOfViews || remainingViews <= 0)
			break;
	}
	return remainingViews;
}

/**
 * Returns the number of pages the delegate would like to display
 * Returns zero if no limit specified
 */
- (NSInteger)numberOfPages{
	
	if ([dataSource respondsToSelector:@selector(numberOfPagesForPagingScrollView:)])
		return [self.dataSource numberOfPagesForPagingScrollView:self];
	else 
		return 0;
}

/**
 * Convience method that returns the page size
 */
- (CGSize)pageSize{
	return self.scrollView.frame.size;
}

/**
 *  Called when UIPageControl is pressed
 */
- (void)pageControllValueChanged{
	
	//Get page from page controll
	int page = pageControl.currentPage;
	
	//Get adjusted page index
	int actualPageIndex = BAGintMod(pageIndex, [self numberOfPages]);
	
	if (page > actualPageIndex)
		[self nextPage];
	else if (page < actualPageIndex)
		[self previousPage];
}

#pragma mark -
#pragma mark UIScrollViewDelegate
//-----------------------------------------------------------------------------

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView{
		
	//Determine if we are on Previous, Current or Next UIView
	CGFloat contentOffset = aScrollView.contentOffset.x/self.scrollView.frame.size.width;
		
	if (contentOffset < 0.5)
		[self getPreviousPage];
	else if(contentOffset > 1.5)
		[self getNextPage];
	
	CGSize pageSize = self.scrollView.bounds.size;
	self.scrollView.contentOffset = CGPointMake(pageSize.width, 0);
	
	[self.scrollView setNeedsDisplay];
}

/**
 * Move view back to their correct locations
 */
-(void)resetPageViewLocations{
	CGSize pageSize = self.scrollView.frame.size;
	for(int i = 0 ; i < 3 ; i++){
		//Place views in correct place
		pageView[i].center = CGPointMake((.5+i)*pageSize.width, pageSize.height/2);		
	}
	//Also update pageControl index
	int totalPages = self.numberOfPages;
	pageControl.currentPage = (totalPages > 0 ? intMod(pageIndex,totalPages) : pageIndex);
}

/**
 * Shifts view pointer to views the right
 */
-(void)getNextPage{

	pageIndex++;
		
	[pageView[0] removeFromSuperview];
	pageView[0] = pageView[1];
	pageView[1] = pageView[2];
	pageView[2] = [self viewForIndex:pageIndex + 1];
	[self.scrollView addSubview:pageView[2]];
	
	[self resetPageViewLocations];
}
/**
 * Shifts view pointer to views to the left
 */
-(void)getPreviousPage{
	
	pageIndex--;
		
	[pageView[2] removeFromSuperview];
	pageView[2] = pageView[1];
	pageView[1] = pageView[0];
	pageView[0] = [self viewForIndex:pageIndex - 1];
	[self.scrollView addSubview:pageView[0]];
	
	[self resetPageViewLocations];
}

//- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)aScrollView{
//	
//}



@end

#pragma mark OLD CODE

// To Move content view back to correct place
//	CGFloat pageWidth = self.scrollView.bounds.size.width;
//	CGPoint newOffset = self.scrollView.contentOffset;
//	newOffset.x += pageWidth;
//	self.scrollView.contentOffset = newOffset;
