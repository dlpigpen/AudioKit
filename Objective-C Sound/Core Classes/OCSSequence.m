//
//  OCSSequence.m
//  Objective-C Sound
//
//
//  Created by Aurelius Prochazka on 7/1/12.
//  Copyright (c) 2012 Hear For Yourself. All rights reserved.
//

#import "OCSSequence.h"
#import "OCSManager.h"

@interface OCSSequence () {
    NSMutableArray *events;
    NSMutableArray *times;
    NSTimer *timer;
    BOOL isPlaying;
    unsigned int index;
}
@end

@implementation OCSSequence

@synthesize events;
@synthesize times;

// -----------------------------------------------------------------------------
#  pragma mark - Initialization
// -----------------------------------------------------------------------------

- (id) init {
    self = [super init];
    if (self) {
        events = [[NSMutableArray alloc] init];
        times  = [[NSMutableArray alloc] init];
        isPlaying = NO;
    }
    return self;
}

- (void)addEvent:(OCSEvent *)event 
{
    [self addEvent:event afterDuration:0.0f];
}

- (void)addEvent:(OCSEvent *)event 
          atTime:(float)timeSinceStart;
{
    NSNumber *time = [NSNumber numberWithFloat:timeSinceStart];
    
    int insertionIndex = 0;
    BOOL doInsertion = NO;
    for (NSNumber *t in times) {
        if (t.floatValue > timeSinceStart) {
            doInsertion = YES;
            break;
        }
        insertionIndex++;
    }
    if (doInsertion) {
        [events insertObject:event atIndex:insertionIndex];
        [times  insertObject:time  atIndex:insertionIndex];
    } else {
        [events addObject:event];
        [times addObject:time];
    }
}

- (void)addEvent:(OCSEvent *)event 
   afterDuration:(float)timeSinceLastEventStarted;
{
    [events addObject:event];
    NSNumber *time = @0.0F;
    if ([times count] > 0) {
        //OCSEvent *lastEvent = [events lastObject];
        time = [NSNumber numberWithFloat:([[times lastObject] floatValue] + timeSinceLastEventStarted)];
    }
    [times addObject:time];
}

// -----------------------------------------------------------------------------
#  pragma mark - Sequence Playback Control
// -----------------------------------------------------------------------------

- (void)play
{
    index = 0;
    isPlaying = YES;
    // Delay playback until first event is set to start.
    timer = [NSTimer scheduledTimerWithTimeInterval:[[times objectAtIndex:0] floatValue]
                                             target:self
                                           selector:@selector(playNextEventInSequence:)
                                           userInfo:nil
                                            repeats:NO];
}

- (void)pause
{
    isPlaying = NO;
}

- (void)stop
{
    isPlaying = NO;
    for (OCSEvent *event in events) {
        if (event.note) {
            [event.note stop];
            [timer invalidate];
            timer = nil;
        }
    }
}


// Cue up the next event to be triggered.
- (void)playNextEventInSequence:(NSTimer *)aTimer;
{
    OCSEvent *event = [events objectAtIndex:index];
    [[OCSManager sharedOCSManager] triggerEvent:event];

    if (index < [times count]-1 && isPlaying) {
        float timeUntilNextEvent = [[times objectAtIndex:index+1] floatValue] - [[times objectAtIndex:index] floatValue];
        
        //NSLog(@"Next event in %f, times left %i", timeUntilNextEvent, [times count] - index);
        timer = [NSTimer scheduledTimerWithTimeInterval:timeUntilNextEvent
                                                 target:self 
                                               selector:@selector(playNextEventInSequence:) 
                                               userInfo:nil 
                                                repeats:NO];
        index++;

    } else {
        [timer invalidate];
        timer = nil;
    }
}


@end
