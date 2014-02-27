//
//  GRCustomizableWindow.m
//  GRCustomizableWindow
//
//  Created by Guilherme Rambo on 26/02/14.
//  Copyright (c) 2014 Guilherme Rambo. All rights reserved.
//

#import "GRCustomizableWindow.h"

// private class
@interface NSThemeFrame : NSView
- (BOOL)_isFullScreen;
- (id)initWithFrame:(NSRect)frameRect styleMask:(NSUInteger)aStyle owner:(NSWindow *)anOwner;
- (NSRect)_titleControlRect;
- (NSRect)contentRectForFrameRect:(NSRect)frameRect styleMask:(NSUInteger)aStyle;
@end

// this will be our frame view for the window
@interface GRCustomizableWindowFrame : NSThemeFrame

@end

// private methods on the frame view
@interface GRCustomizableWindowFrame ()

- (void)_setTitlebarHeight:(CGFloat)height;
- (void)_setTitlebarColor:(NSColor *)color;
- (void)_setTitleStringColor:(NSColor *)color;
- (void)_setTitleStringFont:(NSFont *)font;
- (void)_setCenterControls:(BOOL)center;

@end

@implementation GRCustomizableWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:NO];
    
    if (!self) return nil;
    
    // defaults
    self.titlebarHeight = @22;
    self.titlebarColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0];
    self.titleFont = [NSFont systemFontOfSize:13.0];
    
    return self;
}

// if we don't set this to NO the window will look funny
- (BOOL)_usesCustomDrawing
{
    return NO;
}

// we want to use our custom frame view class
+ (Class)frameViewClassForStyleMask:(NSUInteger)aStyle
{
    return [GRCustomizableWindowFrame class];
}

// helper method
- (GRCustomizableWindowFrame *)_frameView
{
    return (GRCustomizableWindowFrame *)[self.contentView superview];
}

- (NSRect)contentRectForFrameRect:(NSRect)frameRect styleMask:(NSUInteger)aStyle
{
    if (self.styleMask & NSFullScreenWindowMask) {
        return NSMakeRect(0, 0, NSWidth(frameRect), NSHeight(frameRect));
    } else {
        return NSMakeRect(0, 0, NSWidth(frameRect), NSHeight(frameRect)-self.titlebarHeight.doubleValue-1);
    }
}

// API...

- (void)setTitlebarHeight:(NSNumber *)titlebarHeight
{
    _titlebarHeight = [titlebarHeight copy];
    [[self _frameView] _setTitlebarHeight:_titlebarHeight.doubleValue];
    
    // only way i found to make the content rect be recalculated
    [self setFrame:NSInsetRect(self.frame, 1, 1) display:YES];
    [self setFrame:NSInsetRect(self.frame, -1, -1) display:YES];
}

- (void)setTitlebarColor:(NSColor *)titlebarColor
{
    _titlebarColor = [titlebarColor copy];
    [[self _frameView] _setTitlebarColor:_titlebarColor];
}

- (void)setTitleColor:(NSColor *)titleColor
{
    _titleColor = [titleColor copy];
    [[self _frameView] _setTitleStringColor:_titleColor];
}

- (void)setTitleFont:(NSFont *)titleFont
{
    _titleFont = [titleFont copy];
    [[self _frameView] _setTitleStringFont:titleFont];
}

- (void)setCenterControls:(BOOL)centerControls
{
    _centerControls = centerControls;
    
    [[self _frameView] _setCenterControls:_centerControls];
}

@end

@implementation GRCustomizableWindowFrame
{
    // these can be set via our private API, used by GRCustomizableWindow
    CGFloat _titlebarHeight;
    NSColor *_titlebarColor;
    NSColor *_titleStringColor;
    NSFont *_titleStringFont;
    BOOL _shouldCenterControls;
    
    // this is used internally
    NSColor *_titlebarColorNoKey;
    NSColor *_titlebarSeparatorColor;
    NSColor *_titlebarSeparatorColorNoKey;
    NSGradient *_titlebarOverlayGradient;
    NSColor *_titleStringColorNoKey;
    NSShadow *_titleStringShadow;
}

- (id)initWithFrame:(NSRect)frameRect styleMask:(NSUInteger)aStyle owner:(NSWindow *)anOwner
{
    self = [super initWithFrame:frameRect styleMask:aStyle owner:anOwner];
    
    if (!self) return nil;
    
    // initialize these to avoid burdening our drawRect:
    _titlebarOverlayGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.0] endingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.3]];
    _titlebarSeparatorColor = [NSColor colorWithCalibratedWhite:0.3 alpha:1];
    _titleStringShadow = [self _defaultTitleStringShadow];
    
    return self;
}

// helper method
- (GRCustomizableWindow *)_caWindow
{
    return (GRCustomizableWindow *)self.window;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // clear the canvas
    [[NSColor clearColor] setFill];
    NSRectFill(dirtyRect);
    
    // define our window's shape
    NSBezierPath *windowBezel = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:4 yRadius:4];
    
    // draw window background
    [self.window.backgroundColor setFill];

    // limit the drawing to be only inside this shape
    [windowBezel addClip];
    
    // fill the background
    NSRectFill(dirtyRect);
    
    // draws the textured background if this is in a textured window
    if (self.window.styleMask & NSTexturedBackgroundWindowMask) {
        [self drawTexturedBackground:dirtyRect];
        return;
    }
    
    if (![self _isFullScreen]) [self drawTitlebar];
}

- (void)drawTitlebar
{
    NSRect titlebarRect = [self titlebarRect];
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    // draw base color
    if (self.window.isKeyWindow) {
        [_titlebarColor setFill];
    } else {
        [_titlebarColorNoKey setFill];
    }
    
    NSRectFill(titlebarRect);
    
    // draw overlay gradient
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusLighter];
    [_titlebarOverlayGradient drawInRect:titlebarRect angle:90];
    
    // draw separator line
    if (self.window.isKeyWindow) {
        [_titlebarSeparatorColor setFill];
    } else {
        [_titlebarSeparatorColorNoKey setFill];
    }
    
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusDarker];
    NSRect separatorRect = NSMakeRect(titlebarRect.origin.x, NSHeight(self.frame)-NSHeight(titlebarRect)-1, NSWidth(titlebarRect), 1);
    NSRectFill(separatorRect);
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
    [self drawTitleString];
}

- (void)drawTexturedBackground:(NSRect)dirtyRect
{
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    // draw base color
    if (self.window.isKeyWindow) {
        [_titlebarColor setFill];
    } else {
        [_titlebarColorNoKey setFill];
    }
    
    NSRectFill(dirtyRect);
    
    // draw overlay gradient
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusLighter];
    [_titlebarOverlayGradient drawInRect:self.bounds angle:90];
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
    // we only draw the title if the window is not fullscreen
    if (![self _isFullScreen]) [self drawTitleString];
}

- (void)drawTitleString
{
    if (!self.window.title) return;
    
    if (!_titleStringColor) [self _setTitleStringColor:[self offsetColor:_titlebarColor by:-0.4]];
    
    NSRect titleRect = [super _titleControlRect];
    
    if (!_shouldCenterControls) {
        titleRect.origin.y += NSHeight([self titlebarRect])/2-titleRect.size.height/2-2;
    }
    
    NSDictionary *attributes;
    if (self.window.isKeyWindow) {
        attributes = @{NSFontAttributeName: _titleStringFont,
                       NSForegroundColorAttributeName : _titleStringColor,
                       NSShadowAttributeName : _titleStringShadow};
    } else {
        attributes = @{NSFontAttributeName: _titleStringFont,
                       NSForegroundColorAttributeName : _titleStringColorNoKey};
    }
    
    [self.window.title drawInRect:titleRect withAttributes:attributes];
}

// our private API...

- (void)_setTitlebarHeight:(CGFloat)height
{
    _titlebarHeight = height;
    
    // force redraw
    [self setBounds:self.bounds];
}

- (void)_setTitlebarColor:(NSColor *)color
{
    _titlebarColor = [color copy];
    
    assert(_titlebarColor != nil);

    _titlebarSeparatorColor = [self offsetColor:_titlebarColor by:-0.15];
    _titlebarSeparatorColorNoKey = [self offsetColor:_titlebarColor by:-0.08];
    _titlebarColorNoKey = [self offsetColor:_titlebarColor by:0.08];
    
    // force redraw
    [self setBounds:self.bounds];
}

- (void)_setTitleStringColor:(NSColor *)color
{
    _titleStringColor = [color copy];
    if (_titleStringColor) _titleStringColorNoKey = [self offsetColor:_titleStringColor by:0.2];
    
    _titleStringShadow = [self _defaultTitleStringShadow];
    
    // force redraw
    [self setBounds:self.bounds];
}

- (void)_setTitleStringFont:(NSFont *)font
{
    _titleStringFont = [font copy];
    
    // force redraw
    [self setBounds:self.bounds];
}

- (void)_setCenterControls:(BOOL)center
{
    _shouldCenterControls = center;
    
    // force redraw
    [self setBounds:self.bounds];
}

- (NSRect)titlebarRect
{
    return NSMakeRect(0, NSHeight(self.frame)-_titlebarHeight, NSWidth(self.frame), _titlebarHeight);
}

- (double)_titlebarHeight
{
    return _titlebarHeight;
}

- (NSPoint)_fullScreenButtonOrigin
{
    NSPoint origin = CGPointZero;
    
    if (_shouldCenterControls) {
        origin = CGPointMake(NSWidth(self.frame)-20, [self _centeredTrafficLightsY]);
    } else {
        origin = CGPointMake(NSWidth(self.frame)-20, NSHeight(self.frame)-20);
    }
    
    return origin;
}

- (NSPoint)_closeButtonOrigin
{
    NSPoint origin = CGPointZero;
    
    if (_shouldCenterControls) {
        origin = CGPointMake(6, [self _centeredTrafficLightsY]);
    } else {
        origin = CGPointMake(6, NSHeight(self.frame)-19);
    }
    
    return origin;
}

- (NSPoint)_zoomButtonOrigin
{
    NSPoint origin = CGPointZero;
    
    if (_shouldCenterControls) {
        origin = CGPointMake(46, [self _centeredTrafficLightsY]);
    } else {
        origin = CGPointMake(46, NSHeight(self.frame)-19);
    }
    
    return origin;
}

- (CGFloat)_centeredTrafficLightsY
{
    return NSHeight(self.frame)-NSHeight([self titlebarRect])/2-7;
}

- (NSShadow *)_defaultTitleStringShadow
{
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = NSMakeSize(0, -1);
    shadow.shadowBlurRadius = 1;
    
    if ([self _shouldUseDarkShadow]) {
        shadow.shadowColor = [NSColor colorWithCalibratedWhite:0 alpha:0.7];
    } else {
        shadow.shadowColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.7];
    }
    
    return shadow;
}

- (NSColor *)offsetColor:(NSColor *)color by:(CGFloat)offset {
	// Based on code by Martin Pilkington (https://github.com/pilky/M3Appkit)
    
	CGFloat red = 0;
	CGFloat green = 0;
	CGFloat blue = 0;
    
	if ([color.colorSpace isEqual:[NSColorSpace genericGrayColorSpace]]) {
		red = color.whiteComponent + offset;
		green = color.whiteComponent + offset;
		blue = color.whiteComponent + offset;
	} else {
		red = color.redComponent + offset;
		green = color.greenComponent + offset;
		blue = color.blueComponent + offset;
	}
	if (red < 0) {
		green += red/2;
		blue += red/2;
	}
	if (green < 0) {
		red += green/2;
		blue += green/2;
	}
	if (blue < 0) {
		green += blue/2;
		red += blue/2;
	}
	return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:color.alphaComponent];
}

- (BOOL)_shouldUseDarkShadow
{
    if ([_titleStringColor.colorSpace isEqual:[NSColorSpace genericGrayColorSpace]]) {
        return (_titleStringColor.whiteComponent >= 0.5);
    } else {
        return (_titleStringColor.redComponent >= 0.5 || _titleStringColor.greenComponent >= 0.5 || _titleStringColor.blueComponent >= 0.5);
    }
}

@end