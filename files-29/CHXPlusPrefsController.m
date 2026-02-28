// CHXPlusPrefsController.m
// Full-featured preferences UI for ChromaHomeBarX Plus

#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>

// ==================== PREVIEW BAR ====================

@interface CHXPreviewBar : UIView
@property (nonatomic) NSInteger mode;
@property (nonatomic) CGFloat speed;
@property (nonatomic) CGFloat opacity;
@property (nonatomic) CGFloat hue;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) CGFloat animTime;
@end

@implementation CHXPreviewBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = frame.size.height / 2.0;
        self.layer.masksToBounds = YES;
        self.backgroundColor = [UIColor colorWithHue:0 saturation:1 brightness:1 alpha:1];
        
        // Live preview display link
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)tick {
    self.animTime += 0.016 * (self.speed ?: 1.0);
    self.hue = fmodf(self.hue + 0.005 * (self.speed ?: 1.0), 1.0);
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // Draw gradient preview
    NSMutableArray *colors = [NSMutableArray array];
    int steps = 20;
    for (int i = 0; i <= steps; i++) {
        CGFloat t = (CGFloat)i / steps;
        CGFloat h = fmodf(self.hue + t, 1.0);
        UIColor *c = [UIColor colorWithHue:h saturation:1.0 brightness:1.0 alpha:self.opacity ?: 1.0];
        [colors addObject:(id)c.CGColor];
    }
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGGradientRef grad = CGGradientCreateWithColors(space, (__bridge CFArrayRef)colors, NULL);
    CGContextDrawLinearGradient(ctx, grad, CGPointMake(0, CGRectGetMidY(rect)), 
                                CGPointMake(rect.size.width, CGRectGetMidY(rect)), 0);
    CGGradientRelease(grad);
    CGColorSpaceRelease(space);
}

- (void)dealloc {
    [self.displayLink invalidate];
}

@end

// ==================== PREFERENCES LIST CONTROLLER ====================

@interface CHXPlusListController : PSListController
@property (nonatomic, strong) CHXPreviewBar *previewBar;
@end

@implementation CHXPlusListController

- (id)specifiers {
    if (_specifiers == nil) {
        _specifiers = [NSMutableArray array];
        
        // Helper macros for building specifiers
        #define ADD_HEADER(title) { \
            PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:title target:self \
                set:nil get:nil detail:nil cell:PSGroupCell edit:nil]; \
            [_specifiers addObject:s]; \
        }
        
        #define ADD_SWITCH(key, title, defaultVal) { \
            PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:title target:self \
                set:@selector(setPreference:specifier:) \
                get:@selector(getPreference:) \
                detail:nil cell:PSSwitchCell edit:nil]; \
            [s setProperty:key forKey:@"key"]; \
            [s setProperty:@(defaultVal) forKey:@"default"]; \
            [_specifiers addObject:s]; \
        }
        
        #define ADD_SLIDER(key, title, min, max, defaultVal) { \
            PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:title target:self \
                set:@selector(setPreference:specifier:) \
                get:@selector(getPreference:) \
                detail:nil cell:PSSliderCell edit:nil]; \
            [s setProperty:key forKey:@"key"]; \
            [s setProperty:@(min) forKey:@"min"]; \
            [s setProperty:@(max) forKey:@"max"]; \
            [s setProperty:@(defaultVal) forKey:@"default"]; \
            [_specifiers addObject:s]; \
        }
        
        // ---- MAIN ----
        ADD_HEADER(@"ChromaHomeBarX Plus");
        ADD_SWITCH(@"enabled", @"Enable Tweak", YES);
        
        // ---- ANIMATION ----
        ADD_HEADER(@"Animation");
        
        PSSpecifier *modeSpec = [PSSpecifier preferenceSpecifierNamed:@"Color Mode"
            target:self
            set:@selector(setPreference:specifier:)
            get:@selector(getPreference:)
            detail:[PSListItemsController class]
            cell:PSLinkListCell
            edit:nil];
        [modeSpec setProperty:@"colorMode" forKey:@"key"];
        [modeSpec setProperty:@0 forKey:@"default"];
        [modeSpec setProperty:@[@"Spectrum", @"Wave", @"Breathing", @"Fade", @"Static",
                                 @"Pulse", @"Fire 🔥", @"Ice ❄️", @"Neon 💡", @"Aurora 🌌",
                                 @"Music React 🎵", @"Rainbow Trail 🌈", @"Gradient Static",
                                 @"Twinkle ✨", @"Custom Colors"]
                       forKey:@"validTitles"];
        [modeSpec setProperty:@[@0,@1,@2,@3,@4,@5,@6,@7,@8,@9,@10,@11,@12,@13,@14]
                       forKey:@"validValues"];
        [_specifiers addObject:modeSpec];
        
        ADD_SLIDER(@"animationSpeed", @"Animation Speed", 0.1, 5.0, 1.0);
        ADD_SWITCH(@"mirrorEffect", @"Mirror Effect", NO);
        ADD_SWITCH(@"gradientStyle", @"Gradient Fill (Static)", NO);
        ADD_SWITCH(@"randomMode", @"Random Mode (Auto-Cycle)", NO);
        ADD_SLIDER(@"randomInterval", @"Random Interval (sec)", 3.0, 60.0, 10.0);
        
        // ---- APPEARANCE ----
        ADD_HEADER(@"Appearance");
        ADD_SLIDER(@"barHeight", @"Bar Height", 1.0, 20.0, 5.0);
        ADD_SLIDER(@"barOpacity", @"Bar Opacity", 0.0, 1.0, 1.0);
        ADD_SLIDER(@"barBlur", @"Bar Blur", 0.0, 20.0, 0.0);
        ADD_SLIDER(@"colorSaturation", @"Color Saturation", 0, 100, 100);
        ADD_SLIDER(@"colorBrightness", @"Color Brightness", 0, 100, 100);
        ADD_SWITCH(@"invertColors", @"Invert Colors", NO);
        
        PSSpecifier *posSpec = [PSSpecifier preferenceSpecifierNamed:@"Bar Position"
            target:self
            set:@selector(setPreference:specifier:)
            get:@selector(getPreference:)
            detail:[PSListItemsController class]
            cell:PSLinkListCell
            edit:nil];
        [posSpec setProperty:@"barPosition" forKey:@"key"];
        [posSpec setProperty:@0 forKey:@"default"];
        [posSpec setProperty:@[@"Normal", @"Raised", @"Floating"]
                      forKey:@"validTitles"];
        [posSpec setProperty:@[@0, @1, @2] forKey:@"validValues"];
        [_specifiers addObject:posSpec];
        
        // ---- EFFECTS ----
        ADD_HEADER(@"Effects");
        ADD_SWITCH(@"glowEffect", @"Glow Effect", YES);
        ADD_SLIDER(@"glowRadius", @"Glow Intensity", 1.0, 30.0, 8.0);
        ADD_SWITCH(@"enableBorderGlow", @"Border Glow", NO);
        ADD_SWITCH(@"enableParticles", @"Particle Sparkles", NO);
        ADD_SLIDER(@"particleCount", @"Particle Count", 1, 30, 10);
        ADD_SLIDER(@"trailLength", @"Trail Length (Trail Mode)", 1, 10, 5);
        
        // ---- CUSTOM COLORS ----
        ADD_HEADER(@"Custom Colors (Mode 14 / Gradient Static)");
        
        for (NSString *key in @[@"customColor1", @"customColor2", @"customColor3"]) {
            NSString *title = [NSString stringWithFormat:@"Color %@", 
                [@[@"1", @"2", @"3"][[[@[@"customColor1",@"customColor2",@"customColor3"] indexOfObject:key]]] description]];
            PSSpecifier *cs = [PSSpecifier preferenceSpecifierNamed:title
                target:self
                set:@selector(setPreference:specifier:)
                get:@selector(getPreference:)
                detail:nil
                cell:PSEditTextCell
                edit:nil];
            [cs setProperty:key forKey:@"key"];
            [cs setProperty:@"FF0000" forKey:@"default"];
            [_specifiers addObject:cs];
        }
        
        // ---- SMART FEATURES ----
        ADD_HEADER(@"Smart Features");
        ADD_SWITCH(@"hideOnLandscape", @"Hide in Landscape", NO);
        ADD_SWITCH(@"hideOnKeyboard", @"Hide on Keyboard", YES);
        ADD_SWITCH(@"appAdaptive", @"App Color Adaptive (Experimental)", NO);
        ADD_SWITCH(@"enableReactToTouch", @"React to Touch", NO);
        ADD_SWITCH(@"enableNightMode", @"Night Mode (Auto-Dim)", NO);
        ADD_SWITCH(@"notchColorMatch", @"Match Notch / Dynamic Island", NO);
        ADD_SWITCH(@"beatSync", @"Beat Sync (Music React)", NO);
        
        // ---- ABOUT ----
        ADD_HEADER(@"About ChromaHomeBarX Plus");
        
        PSSpecifier *about = [PSSpecifier preferenceSpecifierNamed:@"Version 2.0 — Enhanced by ChromaPlus"
            target:self set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
        [_specifiers addObject:about];
    }
    return _specifiers;
}

- (NSString *)preferencesIdentifier {
    return @"com.chromahomebarxplus.prefs";
}

- (void)setPreference:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.chromahomebarxplus.prefs.plist"] ?: [NSMutableDictionary dictionary];
    prefs[key] = value;
    [prefs writeToFile:@"/var/mobile/Library/Preferences/com.chromahomebarxplus.prefs.plist" atomically:YES];
    
    // Notify tweak
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.chromahomebarxplus.prefschanged"),
        NULL, NULL, YES);
    
    [self updatePreview];
}

- (id)getPreference:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.chromahomebarxplus.prefs.plist"] ?: @{};
    return prefs[key] ?: [specifier propertyForKey:@"default"];
}

- (UITableView *)table {
    return self.view.subviews.firstObject;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ChromaHomeBarX Plus";
    
    // Add preview bar in header
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 80)];
    header.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    
    self.previewBar = [[CHXPreviewBar alloc] initWithFrame:CGRectMake(60, 35, self.view.bounds.size.width - 120, 8)];
    [header addSubview:self.previewBar];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, self.view.bounds.size.width, 20)];
    label.text = @"✦ ChromaHomeBarX Plus ✦";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:15];
    [header addSubview:label];
    
    self.table.tableHeaderView = header;
}

- (void)updatePreview {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.chromahomebarxplus.prefs.plist"] ?: @{};
    if (prefs[@"animationSpeed"]) self.previewBar.speed = [prefs[@"animationSpeed"] floatValue];
    if (prefs[@"barOpacity"]) self.previewBar.opacity = [prefs[@"barOpacity"] floatValue];
    if (prefs[@"colorMode"]) self.previewBar.mode = [prefs[@"colorMode"] integerValue];
}

@end
