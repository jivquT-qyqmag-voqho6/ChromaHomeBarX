// ChromaHomeBarX Plus - Enhanced Rainbow/Chroma HomeBar Tweak
// Based on ChromaHomeBarX by Afnan Ahmad
// Enhanced with many more features, effects, and options

#import <UIKit/UIKit.h>
#import <substrate.h>

// ==================== PREFERENCES ====================

#define PREF_PATH @"/var/mobile/Library/Preferences/com.chromahomebarxplus.prefs.plist"

static BOOL enabled;
static NSInteger colorMode;        // 0=Spectrum, 1=Wave, 2=Breathing, 3=Fade, 4=Static, 5=Pulse, 6=Fire, 7=Ice, 8=Neon, 9=Aurora, 10=Music React, 11=Rainbow Trail, 12=Gradient Static, 13=Twinkle, 14=Custom Colors
static CGFloat animationSpeed;     // 0.1 - 5.0
static CGFloat barHeight;          // 1.0 - 20.0
static CGFloat barOpacity;         // 0.0 - 1.0
static CGFloat barBlur;            // 0.0 - 20.0 blur radius
static BOOL mirrorEffect;          // Mirror left-right
static BOOL glowEffect;            // Enable glow/shadow
static CGFloat glowRadius;         // Glow intensity
static BOOL gradientStyle;         // Use gradient fill
static BOOL beatSync;              // Sync to music beat (simulated)
static NSInteger barPosition;      // 0=Normal, 1=Raised, 2=Floating
static BOOL hideOnLandscape;       // Hide in landscape
static BOOL hideOnKeyboard;        // Hide when keyboard is up
static BOOL appAdaptive;           // Adapt color to app's color scheme
static NSInteger trailLength;      // Trail length for Rainbow Trail mode
static NSString *customColor1;
static NSString *customColor2;
static NSString *customColor3;
static BOOL enableParticles;       // Floating particle effect
static NSInteger particleCount;
static BOOL enableBorderGlow;      // Glow border around bar
static BOOL invertColors;
static BOOL randomMode;            // Randomly switch effects
static NSTimeInterval randomInterval;
static BOOL notchColorMatch;       // Match notch/Dynamic Island area
static BOOL enableReactToTouch;    // React when user touches screen
static BOOL enableNightMode;       // Auto-dim at night
static NSInteger colorSaturation;  // 0-100
static NSInteger colorBrightness;  // 0-100

static UIView *chromaBarView = nil;
static UIView *glowView = nil;
static NSTimer *chromaTimer = nil;
static NSTimer *randomTimer = nil;
static CADisplayLink *displayLink = nil;

static CGFloat hue = 0.0;
static CGFloat waveOffset = 0.0;
static CGFloat breathAlpha = 0.0;
static BOOL breathIncreasing = YES;
static CGFloat pulseScale = 1.0;
static BOOL pulseGrowing = YES;
static CGFloat fireTime = 0.0;
static CGFloat iceTime = 0.0;
static CGFloat auroraTime = 0.0;
static CGFloat trailPos = 0.0;
static CGFloat twinkleTime = 0.0;
static NSInteger currentRandomMode = 0;
static CGFloat randomTime = 0.0;

// ==================== HELPER FUNCTIONS ====================

static void LoadPreferences() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    if (!prefs) prefs = @{};
    
    enabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : YES;
    colorMode = prefs[@"colorMode"] ? [prefs[@"colorMode"] integerValue] : 0;
    animationSpeed = prefs[@"animationSpeed"] ? [prefs[@"animationSpeed"] floatValue] : 1.0;
    barHeight = prefs[@"barHeight"] ? [prefs[@"barHeight"] floatValue] : 5.0;
    barOpacity = prefs[@"barOpacity"] ? [prefs[@"barOpacity"] floatValue] : 1.0;
    barBlur = prefs[@"barBlur"] ? [prefs[@"barBlur"] floatValue] : 0.0;
    mirrorEffect = prefs[@"mirrorEffect"] ? [prefs[@"mirrorEffect"] boolValue] : NO;
    glowEffect = prefs[@"glowEffect"] ? [prefs[@"glowEffect"] boolValue] : YES;
    glowRadius = prefs[@"glowRadius"] ? [prefs[@"glowRadius"] floatValue] : 8.0;
    gradientStyle = prefs[@"gradientStyle"] ? [prefs[@"gradientStyle"] boolValue] : NO;
    beatSync = prefs[@"beatSync"] ? [prefs[@"beatSync"] boolValue] : NO;
    barPosition = prefs[@"barPosition"] ? [prefs[@"barPosition"] integerValue] : 0;
    hideOnLandscape = prefs[@"hideOnLandscape"] ? [prefs[@"hideOnLandscape"] boolValue] : NO;
    hideOnKeyboard = prefs[@"hideOnKeyboard"] ? [prefs[@"hideOnKeyboard"] boolValue] : YES;
    appAdaptive = prefs[@"appAdaptive"] ? [prefs[@"appAdaptive"] boolValue] : NO;
    trailLength = prefs[@"trailLength"] ? [prefs[@"trailLength"] integerValue] : 5;
    customColor1 = prefs[@"customColor1"] ?: @"FF0000";
    customColor2 = prefs[@"customColor2"] ?: @"00FF00";
    customColor3 = prefs[@"customColor3"] ?: @"0000FF";
    enableParticles = prefs[@"enableParticles"] ? [prefs[@"enableParticles"] boolValue] : NO;
    particleCount = prefs[@"particleCount"] ? [prefs[@"particleCount"] integerValue] : 10;
    enableBorderGlow = prefs[@"enableBorderGlow"] ? [prefs[@"enableBorderGlow"] boolValue] : NO;
    invertColors = prefs[@"invertColors"] ? [prefs[@"invertColors"] boolValue] : NO;
    randomMode = prefs[@"randomMode"] ? [prefs[@"randomMode"] boolValue] : NO;
    randomInterval = prefs[@"randomInterval"] ? [prefs[@"randomInterval"] doubleValue] : 10.0;
    notchColorMatch = prefs[@"notchColorMatch"] ? [prefs[@"notchColorMatch"] boolValue] : NO;
    enableReactToTouch = prefs[@"enableReactToTouch"] ? [prefs[@"enableReactToTouch"] boolValue] : NO;
    enableNightMode = prefs[@"enableNightMode"] ? [prefs[@"enableNightMode"] boolValue] : NO;
    colorSaturation = prefs[@"colorSaturation"] ? [prefs[@"colorSaturation"] integerValue] : 100;
    colorBrightness = prefs[@"colorBrightness"] ? [prefs[@"colorBrightness"] integerValue] : 100;
}

static UIColor *colorFromHex(NSString *hex) {
    unsigned int rgb = 0;
    [[NSScanner scannerWithString:hex] scanHexInt:&rgb];
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF)/255.0
                           green:((rgb >> 8) & 0xFF)/255.0
                            blue:(rgb & 0xFF)/255.0
                           alpha:1.0];
}

static UIColor *chromaColorForHue(CGFloat h) {
    CGFloat sat = colorSaturation / 100.0;
    CGFloat bri = colorBrightness / 100.0;
    
    // Apply night mode dimming (auto-dim between 10PM-7AM)
    if (enableNightMode) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *comps = [cal components:NSCalendarUnitHour fromDate:[NSDate date]];
        NSInteger hour = comps.hour;
        if (hour >= 22 || hour < 7) {
            bri *= 0.3;
        }
    }
    
    UIColor *c = [UIColor colorWithHue:h saturation:sat brightness:bri alpha:barOpacity];
    
    if (invertColors) {
        CGFloat r, g, b, a;
        [c getRed:&r green:&g blue:&b alpha:&a];
        c = [UIColor colorWithRed:1-r green:1-g blue:1-b alpha:a];
    }
    
    return c;
}

// Fire effect color mapping
static UIColor *fireColor(CGFloat t, CGFloat position) {
    // t = time, position = 0..1 along bar
    CGFloat noise = sinf(position * 12.0 + t * 3.0) * 0.5 + 0.5;
    CGFloat flicker = sinf(t * 8.7 + position * 5.0) * 0.1;
    CGFloat intensity = noise + flicker;
    intensity = fmaxf(0, fminf(1, intensity));
    
    CGFloat r = fminf(1.0, intensity * 2.0);
    CGFloat g = fmaxf(0, intensity * 1.5 - 0.5);
    CGFloat b = 0;
    return [UIColor colorWithRed:r green:g blue:b alpha:barOpacity];
}

// Ice effect color mapping
static UIColor *iceColor(CGFloat t, CGFloat position) {
    CGFloat wave = sinf(position * 8.0 + t * 2.0) * 0.5 + 0.5;
    CGFloat sparkle = (sinf(t * 15.0 + position * 20.0) > 0.85) ? 1.0 : wave;
    
    CGFloat r = 0.6 + sparkle * 0.4;
    CGFloat g = 0.85 + sparkle * 0.1;
    CGFloat b = 1.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:barOpacity];
}

// Neon effect
static UIColor *neonColor(CGFloat t, CGFloat position) {
    static CGFloat neonHues[] = {0.0, 0.55, 0.85, 0.12, 0.7};
    NSInteger idx = (NSInteger)(position * 5) % 5;
    CGFloat flicker = (sinf(t * 30.0 + idx) > 0.8) ? 0.5 : 1.0;
    return [UIColor colorWithHue:neonHues[idx] saturation:1.0 brightness:flicker alpha:barOpacity];
}

// Aurora effect
static UIColor *auroraColor(CGFloat t, CGFloat position) {
    CGFloat h1 = fmodf(0.4 + sinf(t * 0.5 + position * 3.0) * 0.2, 1.0);
    CGFloat h2 = fmodf(0.55 + cosf(t * 0.3 + position * 2.0) * 0.15, 1.0);
    CGFloat blend = sinf(position * M_PI + t * 0.7) * 0.5 + 0.5;
    CGFloat h = h1 * blend + h2 * (1 - blend);
    return [UIColor colorWithHue:h saturation:0.8 brightness:0.9 alpha:barOpacity * 0.8];
}

// ==================== GRADIENT LAYER ====================

static void applyGradientToView(UIView *view, UIColor *color1, UIColor *color2, BOOL horizontal) {
    // Remove existing gradient
    for (CALayer *l in [view.layer.sublayers copy]) {
        if ([l isKindOfClass:[CAGradientLayer class]]) {
            [l removeFromSuperlayer];
        }
    }
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = view.bounds;
    gradient.colors = @[(id)color1.CGColor, (id)color2.CGColor];
    if (horizontal) {
        gradient.startPoint = CGPointMake(0, 0.5);
        gradient.endPoint = CGPointMake(1, 0.5);
    } else {
        gradient.startPoint = CGPointMake(0.5, 0);
        gradient.endPoint = CGPointMake(0.5, 1);
    }
    [view.layer insertSublayer:gradient atIndex:0];
}

// ==================== PARTICLE SYSTEM ====================

@interface CHXParticle : NSObject
@property CGFloat x, y, vx, vy;
@property CGFloat life, maxLife;
@property UIColor *color;
@property CGFloat size;
@end

@implementation CHXParticle
@end

static NSMutableArray *particles = nil;

static void updateParticles(UIView *view) {
    if (!enableParticles) return;
    if (!particles) particles = [NSMutableArray array];
    
    // Spawn new particles
    while ((NSInteger)particles.count < particleCount) {
        CHXParticle *p = [CHXParticle new];
        p.x = arc4random_uniform((uint32_t)view.bounds.size.width);
        p.y = view.bounds.size.height / 2.0;
        p.vx = ((CGFloat)(arc4random_uniform(100)) - 50) / 50.0;
        p.vy = -((CGFloat)arc4random_uniform(30)) / 10.0 - 1.0;
        p.maxLife = p.life = 0.5 + (CGFloat)arc4random_uniform(100)/100.0;
        p.color = chromaColorForHue(fmodf(hue + p.x/view.bounds.size.width, 1.0));
        p.size = 1 + (CGFloat)arc4random_uniform(3);
        [particles addObject:p];
    }
    
    // Update existing
    NSMutableArray *dead = [NSMutableArray array];
    for (CHXParticle *p in particles) {
        p.life -= 0.016;
        p.x += p.vx;
        p.y += p.vy;
        if (p.life <= 0) [dead addObject:p];
    }
    [particles removeObjectsInArray:dead];
}

// ==================== MAIN UPDATE LOOP ====================

static void updateChromaBar(CADisplayLink *dl) {
    if (!chromaBarView || !enabled) return;
    
    CGFloat dt = (1.0 / 60.0) * animationSpeed;
    CGFloat barWidth = chromaBarView.bounds.size.width;
    
    // Mode switching in random mode
    if (randomMode) {
        randomTime += dt;
        if (randomTime >= randomInterval) {
            randomTime = 0;
            currentRandomMode = arc4random_uniform(14);
        }
    }
    NSInteger activeMode = randomMode ? currentRandomMode : colorMode;
    
    switch (activeMode) {
        case 0: { // Spectrum - full rainbow cycle
            hue = fmodf(hue + 0.005 * animationSpeed, 1.0);
            chromaBarView.backgroundColor = chromaColorForHue(hue);
            break;
        }
        case 1: { // Wave - color travels along bar
            waveOffset = fmodf(waveOffset + 0.02 * animationSpeed, 1.0);
            // Draw wave using sublayer
            CAGradientLayer *wave = [CAGradientLayer layer];
            wave.frame = chromaBarView.bounds;
            wave.startPoint = CGPointMake(0, 0.5);
            wave.endPoint = CGPointMake(1, 0.5);
            NSMutableArray *colors = [NSMutableArray array];
            int segments = mirrorEffect ? 6 : 12;
            for (int i = 0; i <= segments; i++) {
                CGFloat h = fmodf(waveOffset + (CGFloat)i/segments, 1.0);
                if (mirrorEffect && i > segments/2) {
                    h = fmodf(waveOffset + (CGFloat)(segments-i)/segments, 1.0);
                }
                [colors addObject:(id)chromaColorForHue(h).CGColor];
            }
            wave.colors = colors;
            // Remove old wave layers
            for (CALayer *l in [chromaBarView.layer.sublayers copy]) {
                [l removeFromSuperlayer];
            }
            [chromaBarView.layer addSublayer:wave];
            break;
        }
        case 2: { // Breathing - fades in and out
            if (breathIncreasing) {
                breathAlpha += 0.02 * animationSpeed;
                if (breathAlpha >= 1.0) { breathAlpha = 1.0; breathIncreasing = NO; }
            } else {
                breathAlpha -= 0.02 * animationSpeed;
                if (breathAlpha <= 0.1) { breathAlpha = 0.1; breathIncreasing = YES; }
            }
            hue = fmodf(hue + 0.002 * animationSpeed, 1.0);
            chromaBarView.backgroundColor = [UIColor colorWithHue:hue saturation:colorSaturation/100.0 brightness:colorBrightness/100.0 alpha:breathAlpha * barOpacity];
            break;
        }
        case 3: { // Fade - smooth transition between preset colors
            static CGFloat fadeProgress = 0;
            static NSInteger fadeIndex = 0;
            static NSArray *fadeColors = nil;
            if (!fadeColors) {
                fadeColors = @[@0.0, @0.08, @0.16, @0.33, @0.5, @0.66, @0.75, @0.83, @0.92];
            }
            fadeProgress += 0.01 * animationSpeed;
            if (fadeProgress >= 1.0) {
                fadeProgress = 0;
                fadeIndex = (fadeIndex + 1) % fadeColors.count;
            }
            NSInteger nextIdx = (fadeIndex + 1) % fadeColors.count;
            CGFloat h1 = [fadeColors[fadeIndex] floatValue];
            CGFloat h2 = [fadeColors[nextIdx] floatValue];
            CGFloat blendH = h1 + (h2 - h1) * fadeProgress;
            chromaBarView.backgroundColor = chromaColorForHue(blendH);
            break;
        }
        case 4: { // Static - single solid color
            if (gradientStyle) {
                applyGradientToView(chromaBarView,
                    chromaColorForHue(fmodf(hue, 1.0)),
                    chromaColorForHue(fmodf(hue + 0.3, 1.0)),
                    YES);
            } else {
                chromaBarView.backgroundColor = chromaColorForHue(hue);
            }
            break;
        }
        case 5: { // Pulse - rhythmic scaling + color change
            if (pulseGrowing) {
                pulseScale += 0.05 * animationSpeed;
                if (pulseScale >= 1.5) { pulseScale = 1.5; pulseGrowing = NO; }
            } else {
                pulseScale -= 0.05 * animationSpeed;
                if (pulseScale <= 1.0) { pulseScale = 1.0; pulseGrowing = YES; hue = fmodf(hue + 0.1, 1.0); }
            }
            chromaBarView.transform = CGAffineTransformMakeScale(1.0, pulseScale);
            chromaBarView.backgroundColor = chromaColorForHue(hue);
            break;
        }
        case 6: { // Fire
            fireTime += dt * 0.5;
            // Render fire as gradient
            CAGradientLayer *fireLayer = [CAGradientLayer layer];
            fireLayer.frame = chromaBarView.bounds;
            fireLayer.startPoint = CGPointMake(0, 0.5);
            fireLayer.endPoint = CGPointMake(1, 0.5);
            NSMutableArray *fireColors = [NSMutableArray array];
            for (int i = 0; i <= 20; i++) {
                CGFloat pos = (CGFloat)i / 20.0;
                [fireColors addObject:(id)fireColor(fireTime, pos).CGColor];
            }
            fireLayer.colors = fireColors;
            for (CALayer *l in [chromaBarView.layer.sublayers copy]) [l removeFromSuperlayer];
            [chromaBarView.layer addSublayer:fireLayer];
            break;
        }
        case 7: { // Ice
            iceTime += dt * 0.3;
            CAGradientLayer *iceLayer = [CAGradientLayer layer];
            iceLayer.frame = chromaBarView.bounds;
            iceLayer.startPoint = CGPointMake(0, 0.5);
            iceLayer.endPoint = CGPointMake(1, 0.5);
            NSMutableArray *iceColors = [NSMutableArray array];
            for (int i = 0; i <= 20; i++) {
                CGFloat pos = (CGFloat)i / 20.0;
                [iceColors addObject:(id)iceColor(iceTime, pos).CGColor];
            }
            iceLayer.colors = iceColors;
            for (CALayer *l in [chromaBarView.layer.sublayers copy]) [l removeFromSuperlayer];
            [chromaBarView.layer addSublayer:iceLayer];
            break;
        }
        case 8: { // Neon
            CAGradientLayer *neonLayer = [CAGradientLayer layer];
            neonLayer.frame = chromaBarView.bounds;
            neonLayer.startPoint = CGPointMake(0, 0.5);
            neonLayer.endPoint = CGPointMake(1, 0.5);
            fireTime += dt * 0.8;
            NSMutableArray *neonColors = [NSMutableArray array];
            for (int i = 0; i <= 20; i++) {
                CGFloat pos = (CGFloat)i / 20.0;
                [neonColors addObject:(id)neonColor(fireTime, pos).CGColor];
            }
            neonLayer.colors = neonColors;
            for (CALayer *l in [chromaBarView.layer.sublayers copy]) [l removeFromSuperlayer];
            [chromaBarView.layer addSublayer:neonLayer];
            break;
        }
        case 9: { // Aurora
            auroraTime += dt * 0.5;
            CAGradientLayer *auroraLayer = [CAGradientLayer layer];
            auroraLayer.frame = chromaBarView.bounds;
            auroraLayer.startPoint = CGPointMake(0, 0.5);
            auroraLayer.endPoint = CGPointMake(1, 0.5);
            NSMutableArray *aColors = [NSMutableArray array];
            for (int i = 0; i <= 20; i++) {
                CGFloat pos = (CGFloat)i / 20.0;
                [aColors addObject:(id)auroraColor(auroraTime, pos).CGColor];
            }
            auroraLayer.colors = aColors;
            for (CALayer *l in [chromaBarView.layer.sublayers copy]) [l removeFromSuperlayer];
            [chromaBarView.layer addSublayer:auroraLayer];
            break;
        }
        case 10: { // Music React (simulated beat detection via volume/timer simulation)
            static CGFloat beatTimer = 0;
            static BOOL onBeat = NO;
            beatTimer += dt;
            // Simulate beat at ~120 BPM (0.5s interval)
            CGFloat beatInterval = 60.0 / 120.0;
            if (beatTimer >= beatInterval) {
                beatTimer = 0;
                onBeat = YES;
                hue = fmodf(hue + (arc4random_uniform(30) / 100.0), 1.0);
            } else {
                onBeat = NO;
            }
            CGFloat brightness = onBeat ? 1.0 : 0.4 + (1.0 - beatTimer/0.2) * 0.3;
            brightness = fmaxf(0.3, fminf(1.0, brightness));
            chromaBarView.backgroundColor = [UIColor colorWithHue:hue saturation:1.0 brightness:brightness alpha:barOpacity];
            break;
        }
        case 11: { // Rainbow Trail
            trailPos = fmodf(trailPos + 0.03 * animationSpeed, 1.0);
            CAGradientLayer *trailLayer = [CAGradientLayer layer];
            trailLayer.frame = chromaBarView.bounds;
            trailLayer.startPoint = CGPointMake(0, 0.5);
            trailLayer.endPoint = CGPointMake(1, 0.5);
            int tl = (int)MAX(2, MIN(trailLength, 10));
            NSMutableArray *trailColors = [NSMutableArray array];
            for (int i = 0; i <= 20; i++) {
                CGFloat pos = (CGFloat)i / 20.0;
                CGFloat dist = fmodf(fabsf(pos - trailPos), 1.0);
                if (dist > 0.5) dist = 1.0 - dist;
                CGFloat alpha = (1.0 - dist * 2.0 * (10.0/(CGFloat)tl));
                alpha = fmaxf(0, alpha) * barOpacity;
                CGFloat trailHue = fmodf(trailPos - pos * 0.3, 1.0);
                [trailColors addObject:(id)[UIColor colorWithHue:trailHue saturation:1.0 brightness:1.0 alpha:alpha].CGColor];
            }
            trailLayer.colors = trailColors;
            for (CALayer *l in [chromaBarView.layer.sublayers copy]) [l removeFromSuperlayer];
            [chromaBarView.layer addSublayer:trailLayer];
            break;
        }
        case 12: { // Gradient Static (custom colors)
            UIColor *c1 = colorFromHex(customColor1);
            UIColor *c2 = colorFromHex(customColor2);
            UIColor *c3 = colorFromHex(customColor3);
            CAGradientLayer *grad = [CAGradientLayer layer];
            grad.frame = chromaBarView.bounds;
            grad.colors = @[(id)c1.CGColor, (id)c2.CGColor, (id)c3.CGColor];
            grad.startPoint = CGPointMake(0, 0.5);
            grad.endPoint = CGPointMake(1, 0.5);
            grad.locations = @[@0.0, @0.5, @1.0];
            for (CALayer *l in [chromaBarView.layer.sublayers copy]) [l removeFromSuperlayer];
            [chromaBarView.layer addSublayer:grad];
            break;
        }
        case 13: { // Twinkle - random sparkling stars
            twinkleTime += dt;
            chromaBarView.backgroundColor = chromaColorForHue(fmodf(twinkleTime * 0.05, 1.0));
            // Add random bright flashes
            if (arc4random_uniform(10) < 2) {
                UIView *spark = [[UIView alloc] initWithFrame:CGRectMake(
                    arc4random_uniform((uint32_t)barWidth), 0, 3, chromaBarView.bounds.size.height)];
                spark.backgroundColor = [UIColor whiteColor];
                spark.alpha = 0.8;
                [chromaBarView addSubview:spark];
                [UIView animateWithDuration:0.3 animations:^{
                    spark.alpha = 0;
                } completion:^(BOOL done){ [spark removeFromSuperview]; }];
            }
            break;
        }
        case 14: { // Custom: cycle through user custom colors
            static CGFloat customFade = 0;
            static NSInteger customIdx = 0;
            customFade += 0.01 * animationSpeed;
            if (customFade >= 1.0) {
                customFade = 0;
                customIdx = (customIdx + 1) % 3;
            }
            NSArray *customHexes = @[customColor1, customColor2, customColor3];
            UIColor *from = colorFromHex(customHexes[customIdx]);
            UIColor *to = colorFromHex(customHexes[(customIdx+1)%3]);
            CGFloat r1,g1,b1,a1,r2,g2,b2,a2;
            [from getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
            [to getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
            chromaBarView.backgroundColor = [UIColor colorWithRed:r1+(r2-r1)*customFade
                                                            green:g1+(g2-g1)*customFade
                                                             blue:b1+(b2-b1)*customFade
                                                            alpha:barOpacity];
            break;
        }
    }
    
    // Update glow to match bar color
    if (glowEffect && glowView) {
        glowView.layer.shadowColor = chromaBarView.backgroundColor.CGColor;
        glowView.layer.shadowRadius = glowRadius;
        glowView.layer.shadowOpacity = 0.8;
        glowView.layer.shadowOffset = CGSizeZero;
    }
    
    // Particles
    if (enableParticles) {
        updateParticles(chromaBarView);
    }
}

// ==================== HOOK TARGET ====================

// HomeBar on iPhone X is managed by _UIHomeIndicatorSystemGestureRecognizer
// The actual view is SBFHomeGrabberView or UIHomeIndicatorView

%hook UIView

- (void)didMoveToWindow {
    %orig;
    
    // Target the home indicator/home bar view
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"HomeIndicator"] || 
        [className containsString:@"HomeGrabber"] ||
        [className containsString:@"HomeBar"] ||
        [className containsString:@"GrabberView"]) {
        
        if (!enabled) return;
        
        LoadPreferences();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupChromaBar];
        });
    }
}

%new
- (void)setupChromaBar {
    if (!enabled) return;
    
    // Stop existing display link
    [displayLink invalidate];
    displayLink = nil;
    
    // Remove previous chroma view
    if (chromaBarView) {
        [chromaBarView removeFromSuperview];
        chromaBarView = nil;
    }
    
    CGRect frame = self.bounds;
    CGFloat height = barHeight;
    CGFloat width = frame.size.width;
    
    // Adjust for barPosition
    CGFloat yOffset = 0;
    switch (barPosition) {
        case 1: yOffset = -5; break;  // Raised
        case 2: yOffset = -12; break; // Floating
        default: break;
    }
    
    chromaBarView = [[UIView alloc] initWithFrame:CGRectMake(0, yOffset, width, height)];
    chromaBarView.clipsToBounds = (barBlur <= 0);
    chromaBarView.layer.cornerRadius = height / 2.0;
    chromaBarView.alpha = barOpacity;
    chromaBarView.userInteractionEnabled = NO;
    
    // Blur effect
    if (barBlur > 0) {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.frame = chromaBarView.bounds;
        blurView.alpha = barBlur / 20.0;
        [chromaBarView addSubview:blurView];
    }
    
    // Glow view (behind)
    if (glowEffect) {
        glowView = [[UIView alloc] initWithFrame:chromaBarView.frame];
        glowView.backgroundColor = [UIColor clearColor];
        glowView.layer.cornerRadius = height / 2.0;
        glowView.layer.shadowColor = [UIColor whiteColor].CGColor;
        glowView.layer.shadowRadius = glowRadius;
        glowView.layer.shadowOpacity = 0.8;
        glowView.layer.shadowOffset = CGSizeZero;
        glowView.userInteractionEnabled = NO;
        [self insertSubview:glowView belowSubview:chromaBarView];
    }
    
    // Border glow
    if (enableBorderGlow) {
        chromaBarView.layer.borderWidth = 1.5;
        chromaBarView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.6].CGColor;
    }
    
    [self addSubview:chromaBarView];
    
    // Setup display link for smooth 60fps animation
    displayLink = [CADisplayLink displayLinkWithTarget:[NSBlockOperation blockOperationWithBlock:^{
        updateChromaBar(nil);
    }] selector:@selector(main)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // Floating effect
    if (barPosition == 2) {
        chromaBarView.layer.shadowColor = chromaBarView.backgroundColor.CGColor;
        chromaBarView.layer.shadowOffset = CGSizeMake(0, 4);
        chromaBarView.layer.shadowRadius = 6;
        chromaBarView.layer.shadowOpacity = 0.5;
    }
}

%end

// ==================== SPRINGBOARD HOOK ====================

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)app {
    %orig;
    LoadPreferences();
    
    // Register for preference changes
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)^(CFNotificationCenterRef center, void *observer, 
                                   CFStringRef name, const void *object, CFDictionaryRef info) {
            LoadPreferences();
        },
        CFSTR("com.chromahomebarxplus.prefschanged"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}

%end

// ==================== KEYBOARD DETECTION ====================

%hook UIInputWindowController

- (void)moveToDisplayMode:(NSInteger)mode {
    %orig;
    if (hideOnKeyboard) {
        BOOL keyboardVisible = (mode != 0);
        chromaBarView.hidden = keyboardVisible;
        glowView.hidden = keyboardVisible;
    }
}

%end

// ==================== LANDSCAPE DETECTION ====================

%hook UIViewController

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    %orig;
    if (hideOnLandscape) {
        BOOL isLandscape = size.width > size.height;
        chromaBarView.hidden = isLandscape;
        glowView.hidden = isLandscape;
    }
}

%end

// ==================== TOUCH REACTION ====================

%hook UIWindow

- (void)sendEvent:(UIEvent *)event {
    %orig;
    if (enableReactToTouch && chromaBarView) {
        UITouch *touch = event.allTouches.anyObject;
        if (touch && touch.phase == UITouchPhaseBegan) {
            // Flash the bar on touch
            UIColor *flashColor = [UIColor whiteColor];
            UIColor *restore = chromaBarView.backgroundColor;
            chromaBarView.backgroundColor = flashColor;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.08 * NSEC_PER_SEC), 
                           dispatch_get_main_queue(), ^{
                chromaBarView.backgroundColor = restore;
            });
            
            // Shift hue on touch
            hue = fmodf(hue + 0.15, 1.0);
        }
    }
}

%end

// ==================== CONSTRUCTOR ====================

%ctor {
    LoadPreferences();
    NSLog(@"[ChromaHomeBarX+] Loaded! Mode: %ld, Speed: %.1f", (long)colorMode, animationSpeed);
}
