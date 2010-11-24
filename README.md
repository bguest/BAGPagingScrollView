BAGPagingScrollView
===================

Introduction
------------
BAGPagingScrollView does exactly what it sounds like it does. It's a UIView that correctly implements the a UIScrollView for paging over many many UIViews. It also implements a UIPageControl. 

I probably pushed this a little pre-maturely, currently it only acts as a carousal, warping back to the beginning after it comes to the last view. I'm in the midst of finishing up my masters degree, but when I get the time I'll finish up the implementation (see STDs bellow).

Getting Started
---------------
1. Clone or otherwise copy `BAGPagingScrollView.h` and `BAGPagingScrollView.m` into your project.
2. Create a BAGPagingScrollView either in Interface Builder or programiticly as you would any other UIView.
3. Set the dataSource of the BAGPagingScrollView you just created.
4. In the dataSource implement:
	- `-(NSInterger)numberOfPagesForScrollView:(BAGPagingScrollView*)pagingScrollView;`
	- `-(UIView*)pagingScrollView:(BAGPagingScrollView*)pagingScrollView viewForPageIndex:(int)index;`
	
	(See the BAGPagingScrollViewDataSource protocol in BAGPagingScrollView.h)
5. Smile!

Notes
-----
- You even thought `-(NSInterger)numberOfPagesForScrollView:(BAGPagingScrollView)pagingScrollView;` is listed as optional, you do need to implement it in your delegate, or things will crash.
- You need to present at least three views or things will not work as expected
- These things will be fixed when I (or maybe you) have the time. See the STDs below. 

STDs (Stuff to Do)
------------------
+ Make it so that an infinite number of pages can be displayed. This will be the default when the delegate does not implement the `numberOfPagesForPaginScrollView:` method.
+ Make it so that the warping feature is optional. My thought is to have this be accomplished by having the delegate return a negative number to the `numberOfPagesForPagingScrollView:` delegate method.
+ Fix bugs when less three UIViews are required to be presented
+ Implement cache similar to UITableView the uses a similar `-(UIView*)dequeueReusableViewWithIdentifier:(NSString *)identifier; `
