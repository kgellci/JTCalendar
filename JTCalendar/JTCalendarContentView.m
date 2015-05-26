//
//  JTCalendarContentView.m
//  JTCalendar
//
//  Created by Jonathan Tribouharet
//

#import "JTCalendarContentView.h"

#import "JTCalendar.h"

#import "JTCalendarMonthView.h"
#import "JTCalendarWeekView.h"

#define NUMBER_PAGES_LOADED 5 // Must be the same in JTCalendarView, JTCalendarMenuView, JTCalendarContentView

@interface JTCalendarContentView() <UIGestureRecognizerDelegate>{
    NSMutableArray *monthsViews;
    UIPanGestureRecognizer *weekMonthPanGesture;
    NSLayoutConstraint *weekMonthContainerHeightConstraint;
    CGFloat minHeightForWeekMonthContainerHeightConstraint;
    CGFloat maxHeightForWeekMonthContainerHeightConstraint;
}

@end

@implementation JTCalendarContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)commonInit
{
    monthsViews = [NSMutableArray new];
    
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.pagingEnabled = YES;
    self.clipsToBounds = YES;
    
    for(int i = 0; i < NUMBER_PAGES_LOADED; ++i){
        JTCalendarMonthView *monthView = [JTCalendarMonthView new];
        [self addSubview:monthView];
        [monthsViews addObject:monthView];
    }
}

- (void)layoutSubviews
{
    [self configureConstraintsForSubviews];
    
    [super layoutSubviews];
}

- (void)configureConstraintsForSubviews
{
    self.contentOffset = CGPointMake(self.contentOffset.x, 0); // Prevent bug when contentOffset.y is negative
 
    CGFloat x = 0;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    if(self.calendarManager.calendarAppearance.readFromRightToLeft){
        for(UIView *view in [[monthsViews reverseObjectEnumerator] allObjects]){
            view.frame = CGRectMake(x, 0, width, height);
            x = CGRectGetMaxX(view.frame);
        }
    }
    else{
        for(UIView *view in monthsViews){
            view.frame = CGRectMake(x, 0, width, height);
            x = CGRectGetMaxX(view.frame);
        }
    }
    
    self.contentSize = CGSizeMake(width * NUMBER_PAGES_LOADED, height);
}

- (void)setCurrentDate:(NSDate *)currentDate
{
    self->_currentDate = currentDate;

    NSCalendar *calendar = self.calendarManager.calendarAppearance.calendar;
    
    for(int i = 0; i < NUMBER_PAGES_LOADED; ++i){
        JTCalendarMonthView *monthView = monthsViews[i];
        
        NSDateComponents *dayComponent = [NSDateComponents new];
        
        if(!self.calendarManager.calendarAppearance.isWeekMode){
            dayComponent.month = i - (NUMBER_PAGES_LOADED / 2);
         
            NSDate *monthDate = [calendar dateByAddingComponents:dayComponent toDate:self.currentDate options:0];
            monthDate = [self beginningOfMonth:monthDate];
            [monthView setBeginningOfMonth:monthDate];
        }
        else{
            dayComponent.day = 7 * (i - (NUMBER_PAGES_LOADED / 2));
            
            NSDate *monthDate = [calendar dateByAddingComponents:dayComponent toDate:self.currentDate options:0];
            monthDate = [self beginningOfWeek:monthDate];
            [monthView setBeginningOfMonth:monthDate];
        }
    }
}

- (NSDate *)beginningOfMonth:(NSDate *)date
{
    NSCalendar *calendar = self.calendarManager.calendarAppearance.calendar;
    NSDateComponents *componentsCurrentDate = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday|NSCalendarUnitWeekOfMonth fromDate:date];
    
    NSDateComponents *componentsNewDate = [NSDateComponents new];
    
    componentsNewDate.year = componentsCurrentDate.year;
    componentsNewDate.month = componentsCurrentDate.month;
    componentsNewDate.weekOfMonth = 1;
    componentsNewDate.weekday = calendar.firstWeekday;
    
    return [calendar dateFromComponents:componentsNewDate];
}

- (NSDate *)beginningOfWeek:(NSDate *)date
{
    NSCalendar *calendar = self.calendarManager.calendarAppearance.calendar;
    NSDateComponents *componentsCurrentDate = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday|NSCalendarUnitWeekOfMonth fromDate:date];
    
    NSDateComponents *componentsNewDate = [NSDateComponents new];
    
    componentsNewDate.year = componentsCurrentDate.year;
    componentsNewDate.month = componentsCurrentDate.month;
    componentsNewDate.weekOfMonth = componentsCurrentDate.weekOfMonth;
    componentsNewDate.weekday = calendar.firstWeekday;
    
    return [calendar dateFromComponents:componentsNewDate];
}

- (void)enableWeekMonthPanWithMinimumHeight:(CGFloat)minimumHeight andMaximumHeight:(CGFloat)maximumHeight byUpdatingHeightConstraint:(NSLayoutConstraint *)heightConstraint {
    if (weekMonthPanGesture) {
        [self removeGestureRecognizer:weekMonthPanGesture];
    }
    minHeightForWeekMonthContainerHeightConstraint = minimumHeight;
    maxHeightForWeekMonthContainerHeightConstraint = maximumHeight;
    weekMonthContainerHeightConstraint = heightConstraint;
    weekMonthPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleWeekMonthPan:)];
    weekMonthPanGesture.delegate = self;
    [self addGestureRecognizer:weekMonthPanGesture];
}

- (void)handleWeekMonthPan:(UIPanGestureRecognizer *)panGesture {
    CGPoint translationPoint = [panGesture translationInView:panGesture.view];
    weekMonthContainerHeightConstraint.constant += translationPoint.y;
    weekMonthContainerHeightConstraint.constant = MAX(MIN(maxHeightForWeekMonthContainerHeightConstraint, weekMonthContainerHeightConstraint.constant), minHeightForWeekMonthContainerHeightConstraint);
    CGFloat opacity = 0;
    if (self.calendarManager.calendarAppearance.isWeekMode) {
        opacity = 1.0f - (weekMonthContainerHeightConstraint.constant / maxHeightForWeekMonthContainerHeightConstraint);
    } else {
        opacity = weekMonthContainerHeightConstraint.constant / maxHeightForWeekMonthContainerHeightConstraint;
    }
    
    self.layer.opacity = opacity + 0.1f;
    if (panGesture.state == UIGestureRecognizerStateEnded) {
        if (weekMonthContainerHeightConstraint.constant < maxHeightForWeekMonthContainerHeightConstraint - minHeightForWeekMonthContainerHeightConstraint) {
            weekMonthContainerHeightConstraint.constant = minHeightForWeekMonthContainerHeightConstraint;
        } else {
            weekMonthContainerHeightConstraint.constant = maxHeightForWeekMonthContainerHeightConstraint;
        }
        weekMonthPanGesture.enabled = NO;
        [UIView animateWithDuration:0.15f animations:^{
            [self layoutIfNeeded];
            if (self.calendarManager.calendarAppearance.isWeekMode == weekMonthContainerHeightConstraint.constant < maxHeightForWeekMonthContainerHeightConstraint) {
                self.layer.opacity = 1.0f;
            } else {
                self.layer.opacity = 0.1f;
            }
        } completion:^(BOOL finished) {
            self.calendarManager.calendarAppearance.isWeekMode = weekMonthContainerHeightConstraint.constant < maxHeightForWeekMonthContainerHeightConstraint;
            [self.calendarManager reloadAppearance];
            weekMonthPanGesture.enabled = YES;
            [UIView animateWithDuration:.25
                             animations:^{
                                 self.layer.opacity = 1;
                             }];
        }];
        return;
    }
    
    [panGesture setTranslation:CGPointZero inView:panGesture.view];
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isEqual:weekMonthPanGesture]) {
        if (gestureRecognizer.numberOfTouches > 0) {
            CGPoint translation = [weekMonthPanGesture velocityInView:self];
            NSLog(@"%d", fabs(translation.y) > fabs(translation.x));
            return fabs(translation.y) > fabs(translation.x);
        } else {
            return NO;
        }
    }
    return YES;
}

#pragma mark - JTCalendarManager

- (void)setCalendarManager:(JTCalendar *)calendarManager
{
    self->_calendarManager = calendarManager;
    
    for(JTCalendarMonthView *view in monthsViews){
        [view setCalendarManager:calendarManager];
    }
}

- (void)reloadData
{
    for(JTCalendarMonthView *monthView in monthsViews){
        [monthView reloadData];
    }
}

- (void)reloadAppearance
{
    // Fix when change mode during scroll
    self.scrollEnabled = YES;
    
    for(JTCalendarMonthView *monthView in monthsViews){
        [monthView reloadAppearance];
    }
}

@end
