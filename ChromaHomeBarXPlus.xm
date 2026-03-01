// ChromaHomeBarX Plus v3.0 — Massively Enhanced
// Based on ChromaHomeBarX by Afnan Ahmad
// Enhanced with 25 animation modes, audio visualization, haptics,
// adaptive theming, gesture controls, per-app profiles, and much more.

#import <UIKit/UIKit.h>
#import <substrate.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <MediaPlayer/MediaPlayer.h>

// ==================== PREFERENCES ====================

#define PREF_PATH @"/var/mobile/Library/Preferences/com.chromahomebarxplus.prefs.plist"
#define PROFILES_PATH @"/var/mobile/Library/Preferences/com.chromahomebarxplus.profiles.plist"

static BOOL enabled;
// Modes 0–14 from v2.0 preserved; new modes 15–24 added
static NSInteger colorMode;
static CGFloat animationSpeed;
static CGFloat barHeight;
static CGFloat barOpacity;
static CGFloat barBlur;
static BOOL mirrorEffect;
static BOOL glowEffect;
static CGFloat glowRadius;
static BOOL gradientStyle;
static BOOL beatSync;
static NSInteger barPosition;
static BOOL hideOnLandscape;
static BOOL hideOnKeyboard;
static BOOL appAdaptive;
static NSInteger trailLength;
static NSString *customColor1;
static NSString *customColor2;
static NSString *customColor3;
static BOOL enableParticles;
static NSInteger particleCount;
static BOOL enableBorderGlow;
static BOOL invertColors;
static BOOL randomMode;
static NSTimeInterval randomInterval;
static BOOL notchColorMatch;
static BOOL enableReactToTouch;
static BOOL enableNightMode;
static NSInteger colorSaturation;
static NSInteger colorBrightness;

// ---- NEW v3.0 prefs ----
static BOOL enableHaptics;
static NSInteger hapticStyle;            // 0=light 1=medium 2=heavy
static BOOL enableGestures;             // Tap/swipe gestures on bar
static BOOL enableSoundReactive;        // Mic-based sound reactivity
static CGFloat soundSensitivity;        // 0.0-2.0
static BOOL enableAccelerometer;        // Tilt-react mode
static BOOL enableWeatherColors;
static NSInteger weatherMode;           // 0=sunny 1=cloudy 2=rain 3=snow 4=storm
static BOOL perAppProfiles;
static BOOL enableRainbowGlow;          // Glow matches bar hue
static CGFloat barCornerRadius;         // -1 = auto
static BOOL enableDoubleWidth;
static BOOL enablePulseOnNotification;
static NSString *customColor4;
static NSString *customColor5;
static NSString *customColor6;
static BOOL enableColorEQ;
static NSInteger eqBands;              // 4-20
static BOOL enableChromaShift;         // Edge chromatic aberration
static CGFloat barShadowOpacity;
static CGFloat barShadowBlur;
static BOOL enableStrobeMode;
static CGFloat strobeRate;             // Flashes per second
static BOOL enableConfetti;
static BOOL hideInLowPower;
static NSInteger gradientAngle;        // 0-360 degrees
static BOOL enableDualBar;             // Two stacked bars
static CGFloat dualBarGap;
static BOOL enableBarBounce;           // Spring animation on appear

// ==================== GLOBAL STATE ====================

static UIView *chromaBarView  = nil;
static UIView *chromaBarView2 = nil;
static UIView *glowView       = nil;
static CADisplayLink *displayLink = nil;
static AVAudioRecorder *audioRecorder = nil;
static CMMotionManager *motionManager = nil;
static CGFloat currentAudioLevel = 0;
static CGFloat accelX = 0, accelY = 0;

// Animation state
static CGFloat hue = 0.0;
static CGFloat waveOffset = 0.0;
static CGFloat breathAlpha = 0.5;
static BOOL breathIncreasing = YES;
static CGFloat pulseScale = 1.0;
static BOOL pulseGrowing = YES;
static CGFloat fireTime = 0.0;
static CGFloat iceTime  = 0.0;
static CGFloat auroraTime = 0.0;
static CGFloat trailPos = 0.0;
static CGFloat twinkleTime = 0.0;
static NSInteger currentRandomMode = 0;
static CGFloat randomTime = 0.0;
static CGFloat eqTime = 0.0;
static CGFloat lavaTime = 0.0;
static CGFloat galaxyTime = 0.0;
static CGFloat plasmaTime = 0.0;
static CGFloat cyberTime = 0.0;
static CGFloat synthTime = 0.0;
static CGFloat sunriseTime = 0.0;
static CGFloat strobeTime = 0.0;
static BOOL strobeOn = YES;
static CGFloat currentBPM = 120.0;

// ==================== PREFERENCES LOADER ====================

static void LoadPreferences() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH] ?: @{};

    #define BOOL_PREF(key, def)  (prefs[@(#key)] ? [prefs[@(#key)] boolValue]    : (def))
    #define FLOAT_PREF(key, def) (prefs[@(#key)] ? [prefs[@(#key)] floatValue]   : (def))
    #define INT_PREF(key, def)   (prefs[@(#key)] ? [prefs[@(#key)] integerValue] : (def))
    #define STR_PREF(key, def)   (prefs[@(#key)] ?: (def))

    enabled           = BOOL_PREF(enabled, YES);
    colorMode         = INT_PREF(colorMode, 0);
    animationSpeed    = FLOAT_PREF(animationSpeed, 1.0);
    barHeight         = FLOAT_PREF(barHeight, 5.0);
    barOpacity        = FLOAT_PREF(barOpacity, 1.0);
    barBlur           = FLOAT_PREF(barBlur, 0.0);
    mirrorEffect      = BOOL_PREF(mirrorEffect, NO);
    glowEffect        = BOOL_PREF(glowEffect, YES);
    glowRadius        = FLOAT_PREF(glowRadius, 8.0);
    gradientStyle     = BOOL_PREF(gradientStyle, NO);
    beatSync          = BOOL_PREF(beatSync, NO);
    barPosition       = INT_PREF(barPosition, 0);
    hideOnLandscape   = BOOL_PREF(hideOnLandscape, NO);
    hideOnKeyboard    = BOOL_PREF(hideOnKeyboard, YES);
    appAdaptive       = BOOL_PREF(appAdaptive, NO);
    trailLength       = INT_PREF(trailLength, 5);
    customColor1      = STR_PREF(customColor1, @"FF0000");
    customColor2      = STR_PREF(customColor2, @"00FF00");
    customColor3      = STR_PREF(customColor3, @"0000FF");
    customColor4      = STR_PREF(customColor4, @"FF00FF");
    customColor5      = STR_PREF(customColor5, @"FFAA00");
    customColor6      = STR_PREF(customColor6, @"00FFFF");
    enableParticles   = BOOL_PREF(enableParticles, NO);
    particleCount     = INT_PREF(particleCount, 10);
    enableBorderGlow  = BOOL_PREF(enableBorderGlow, NO);
    invertColors      = BOOL_PREF(invertColors, NO);
    randomMode        = BOOL_PREF(randomMode, NO);
    randomInterval    = FLOAT_PREF(randomInterval, 10.0);
    notchColorMatch   = BOOL_PREF(notchColorMatch, NO);
    enableReactToTouch= BOOL_PREF(enableReactToTouch, NO);
    enableNightMode   = BOOL_PREF(enableNightMode, NO);
    colorSaturation   = INT_PREF(colorSaturation, 100);
    colorBrightness   = INT_PREF(colorBrightness, 100);

    enableHaptics          = BOOL_PREF(enableHaptics, NO);
    hapticStyle            = INT_PREF(hapticStyle, 0);
    enableGestures         = BOOL_PREF(enableGestures, NO);
    enableSoundReactive    = BOOL_PREF(enableSoundReactive, NO);
    soundSensitivity       = FLOAT_PREF(soundSensitivity, 1.0);
    enableAccelerometer    = BOOL_PREF(enableAccelerometer, NO);
    enableWeatherColors    = BOOL_PREF(enableWeatherColors, NO);
    weatherMode            = INT_PREF(weatherMode, 0);
    perAppProfiles         = BOOL_PREF(perAppProfiles, NO);
    enableRainbowGlow      = BOOL_PREF(enableRainbowGlow, NO);
    barCornerRadius        = FLOAT_PREF(barCornerRadius, -1.0);
    enableDoubleWidth      = BOOL_PREF(enableDoubleWidth, NO);
    enablePulseOnNotification = BOOL_PREF(enablePulseOnNotification, YES);
    enableColorEQ          = BOOL_PREF(enableColorEQ, NO);
    eqBands                = INT_PREF(eqBands, 8);
    enableChromaShift      = BOOL_PREF(enableChromaShift, NO);
    barShadowOpacity       = FLOAT_PREF(barShadowOpacity, 0.0);
    barShadowBlur          = FLOAT_PREF(barShadowBlur, 8.0);
    enableStrobeMode       = BOOL_PREF(enableStrobeMode, NO);
    strobeRate             = FLOAT_PREF(strobeRate, 4.0);
    enableConfetti         = BOOL_PREF(enableConfetti, NO);
    hideInLowPower         = BOOL_PREF(hideInLowPower, YES);
    gradientAngle          = INT_PREF(gradientAngle, 0);
    enableDualBar          = BOOL_PREF(enableDualBar, NO);
    dualBarGap             = FLOAT_PREF(dualBarGap, 4.0);
    enableBarBounce        = BOOL_PREF(enableBarBounce, NO);
}

// ==================== AUDIO ====================

static void startAudioMonitoring() {
    if (!enableSoundReactive || audioRecorder) return;
    AVAudioSession *sess = [AVAudioSession sharedInstance];
    [sess setCategory:AVAudioSessionCategoryPlayAndRecord
          withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [sess setActive:YES error:nil];
    NSURL *devNull = [NSURL fileURLWithPath:@"/dev/null"];
    NSDictionary *settings = @{
        AVFormatIDKey:         @(kAudioFormatAppleLossless),
        AVSampleRateKey:       @44100.0,
        AVNumberOfChannelsKey: @1
    };
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:devNull settings:settings error:nil];
    audioRecorder.meteringEnabled = YES;
    [audioRecorder record];
}

static CGFloat getAudioLevel() {
    if (!audioRecorder) return 0;
    [audioRecorder updateMeters];
    CGFloat dB = [audioRecorder averagePowerForChannel:0];
    return fmaxf(0, fminf(1, (dB + 60.0) / 60.0)) * soundSensitivity;
}

// ==================== MOTION ====================

static void startMotionUpdates() {
    if (!enableAccelerometer) return;
    if (!motionManager) motionManager = [[CMMotionManager alloc] init];
    if (motionManager.accelerometerActive) return;
    motionManager.accelerometerUpdateInterval = 1.0/60.0;
    [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
                                       withHandler:^(CMAccelerometerData *d, NSError *e) {
        accelX = d.acceleration.x;
        accelY = d.acceleration.y;
    }];
}

// ==================== HAPTICS ====================

static void triggerHaptic() {
    if (!enableHaptics) return;
    UIImpactFeedbackStyle style;
    switch (hapticStyle) {
        case 1:  style = UIImpactFeedbackStyleMedium; break;
        case 2:  style = UIImpactFeedbackStyleHeavy;  break;
        default: style = UIImpactFeedbackStyleLight;  break;
    }
    [[UIImpactFeedbackGenerator alloc] initWithStyle:style].impactOccurred;
}

// ==================== COLOR HELPERS ====================

static UIColor *colorFromHex(NSString *hex) {
    if (!hex || hex.length < 6) return [UIColor redColor];
    unsigned int rgb = 0;
    [[NSScanner scannerWithString:hex] scanHexInt:&rgb];
    return [UIColor colorWithRed:((rgb>>16)&0xFF)/255.0
                           green:((rgb>>8)&0xFF)/255.0
                            blue:(rgb&0xFF)/255.0 alpha:1.0];
}

static UIColor *chromaColorForHue(CGFloat h) {
    CGFloat sat = colorSaturation / 100.0;
    CGFloat bri = colorBrightness / 100.0;
    if (enableNightMode) {
        NSDateComponents *c = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:[NSDate date]];
        if (c.hour >= 22 || c.hour < 7) bri *= 0.3;
    }
    if (enableSoundReactive) bri = fminf(1.0, bri * (0.4 + currentAudioLevel * 1.2));
    if (enableAccelerometer) h = fmodf(h + fabsf(accelX) * 0.1, 1.0);
    UIColor *c = [UIColor colorWithHue:h saturation:sat brightness:bri alpha:barOpacity];
    if (invertColors) {
        CGFloat r, g, b, a;
        [c getRed:&r green:&g blue:&b alpha:&a];
        c = [UIColor colorWithRed:1-r green:1-g blue:1-b alpha:a];
    }
    return c;
}

static UIColor *lerpColor(UIColor *a, UIColor *b, CGFloat t) {
    CGFloat r1,g1,b1,a1,r2,g2,b2,a2;
    [a getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [b getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    return [UIColor colorWithRed:r1+(r2-r1)*t green:g1+(g2-g1)*t blue:b1+(b2-b1)*t alpha:a1+(a2-a1)*t];
}

static void clearGradients(UIView *v) {
    for (CALayer *l in [v.layer.sublayers copy])
        if ([l isKindOfClass:[CAGradientLayer class]] || [l isKindOfClass:[CALayer class]])
            [l removeFromSuperlayer];
}

static void applyGradient(UIView *v, NSArray<UIColor*> *colors, CGFloat angleDeg) {
    clearGradients(v);
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = v.bounds;
    NSMutableArray *cg = [NSMutableArray array];
    for (UIColor *c in colors) [cg addObject:(id)c.CGColor];
    g.colors = cg;
    CGFloat angle = angleDeg * M_PI / 180.0;
    g.startPoint = CGPointMake(0.5 - cos(angle)*0.5, 0.5 - sin(angle)*0.5);
    g.endPoint   = CGPointMake(0.5 + cos(angle)*0.5, 0.5 + sin(angle)*0.5);
    [v.layer addSublayer:g];
}

// Build gradient and add it to view (for modes that need many color stops)
static void applyGradientColors(UIView *v, NSArray *cgColors) {
    for (CALayer *l in [v.layer.sublayers copy])
        if ([l isKindOfClass:[CAGradientLayer class]]) [l removeFromSuperlayer];
    CAGradientLayer *gl = [CAGradientLayer layer];
    gl.frame = v.bounds;
    gl.startPoint = CGPointMake(0, 0.5);
    gl.endPoint   = CGPointMake(1, 0.5);
    gl.colors = cgColors;
    [v.layer addSublayer:gl];
}

// ==================== EFFECT COLOR FUNCTIONS ====================

static UIColor *fireColor(CGFloat t, CGFloat p) {
    CGFloat n = sinf(p*12+t*3)*0.5+0.5;
    CGFloat f = sinf(t*8.7+p*5)*0.1;
    CGFloat i = fmaxf(0,fminf(1,n+f));
    if (enableSoundReactive) i = fminf(1, i+currentAudioLevel*0.5);
    return [UIColor colorWithRed:fminf(1,i*2) green:fmaxf(0,i*1.5-0.5) blue:0 alpha:barOpacity];
}

static UIColor *iceColor(CGFloat t, CGFloat p) {
    CGFloat w = sinf(p*8+t*2)*0.5+0.5;
    CGFloat s = (sinf(t*15+p*20)>0.85) ? 1.0 : w;
    return [UIColor colorWithRed:0.6+s*0.4 green:0.85+s*0.1 blue:1.0 alpha:barOpacity];
}

static UIColor *neonColor(CGFloat t, CGFloat p) {
    static CGFloat h[] = {0.0,0.55,0.85,0.12,0.7};
    NSInteger i = (NSInteger)(p*5)%5;
    CGFloat f = (sinf(t*30+i)>0.8) ? 0.5 : 1.0;
    return [UIColor colorWithHue:h[i] saturation:1 brightness:f alpha:barOpacity];
}

static UIColor *auroraColor(CGFloat t, CGFloat p) {
    CGFloat h1 = fmodf(0.4+sinf(t*0.5+p*3)*0.2, 1.0);
    CGFloat h2 = fmodf(0.55+cosf(t*0.3+p*2)*0.15, 1.0);
    CGFloat b  = sinf(p*M_PI+t*0.7)*0.5+0.5;
    return [UIColor colorWithHue:h1*b+h2*(1-b) saturation:0.8 brightness:0.9 alpha:barOpacity*0.8];
}

// NEW modes
static UIColor *lavaColor(CGFloat t, CGFloat p) {
    CGFloat b1 = sinf(p*3+t*0.8)*0.5+0.5;
    CGFloat b2 = sinf(p*5-t*0.6+1.2)*0.5+0.5;
    CGFloat i  = b1*b2;
    return [UIColor colorWithRed:fminf(1,0.8+i*0.4) green:fminf(1,i*0.6) blue:0 alpha:barOpacity];
}

static UIColor *galaxyColor(CGFloat t, CGFloat p) {
    CGFloat n = sinf(p*4+t*0.4)*0.5+0.5;
    CGFloat star = (sinf(t*20+p*31)>0.93) ? 1.0 : 0.0;
    CGFloat h = fmodf(0.65+n*0.15, 1.0);
    return [UIColor colorWithHue:h saturation:0.9 brightness:fminf(1,0.3+n*0.4+star*0.5) alpha:barOpacity];
}

static UIColor *plasmaColor(CGFloat t, CGFloat p) {
    CGFloat v = sinf(p*6.28+t) + sinf(p*3.14-t*0.7) + cosf((p+t*0.5)*4.0);
    return [UIColor colorWithHue:fmodf(v*0.15+0.5,1.0) saturation:1 brightness:1 alpha:barOpacity];
}

static UIColor *cyberpunkColor(CGFloat t, CGFloat p) {
    static CGFloat ch[] = {0.5,0.53,0.83,0.87,0.5};
    NSInteger seg = (NSInteger)(p*4)%4;
    CGFloat bl = fmodf(p*4,1.0);
    CGFloat h  = ch[seg]+(ch[seg+1]-ch[seg])*bl;
    CGFloat f  = (sinf(t*40+p*10)>0.9) ? 1.3 : 1.0;
    return [UIColor colorWithHue:h saturation:1 brightness:fminf(1,f) alpha:barOpacity];
}

static UIColor *synthwaveColor(CGFloat t, CGFloat p) {
    CGFloat shift = fmodf(p+waveOffset*0.5, 1.0);
    CGFloat h = fmodf(0.75-shift*0.58+1.0, 1.0);
    CGFloat b = 0.7+sinf(p*M_PI)*0.3;
    return [UIColor colorWithHue:h saturation:1 brightness:b alpha:barOpacity];
}

static UIColor *sunriseColor(CGFloat t, CGFloat p) {
    static UIColor *cols[5];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cols[0] = [UIColor colorWithRed:0.05 green:0.05 blue:0.2  alpha:1];
        cols[1] = [UIColor colorWithRed:0.6  green:0.1  blue:0.3  alpha:1];
        cols[2] = [UIColor colorWithRed:1.0  green:0.4  blue:0.0  alpha:1];
        cols[3] = [UIColor colorWithRed:1.0  green:0.8  blue:0.2  alpha:1];
        cols[4] = [UIColor colorWithRed:0.5  green:0.8  blue:1.0  alpha:1];
    });
    CGFloat total = fmodf(t*0.05, 4.0);
    NSInteger idx = (NSInteger)total % 4;
    UIColor *base = lerpColor(cols[idx], cols[(idx+1)%5], total-idx);
    CGFloat bh; [base getHue:&bh saturation:nil brightness:nil alpha:nil];
    return [UIColor colorWithHue:fmodf(bh+p*0.05,1) saturation:0.9 brightness:0.9 alpha:barOpacity];
}

static UIColor *weatherColor(CGFloat t, CGFloat p) {
    switch (weatherMode) {
        case 0: { CGFloat h=0.1+sinf(p*2+t*0.3)*0.05; return [UIColor colorWithHue:h saturation:0.9 brightness:1 alpha:barOpacity]; }
        case 1: { CGFloat b=0.55+sinf(p*3+t*0.2)*0.15; return [UIColor colorWithHue:0.58 saturation:0.1 brightness:b alpha:barOpacity]; }
        case 2: { CGFloat sp=(sinf(t*25+p*40)>0.92)?1:0; CGFloat b=0.3+sinf(p*8-t*5)*0.2+sp*0.5; return [UIColor colorWithHue:0.6 saturation:0.8 brightness:fmaxf(0.2,b) alpha:barOpacity]; }
        case 3: { CGFloat sp=(sinf(t*18+p*25)>0.88)?1:0.6; return [UIColor colorWithHue:0.55 saturation:0.15 brightness:sp alpha:barOpacity]; }
        case 4: { CGFloat bolt=(sinf(t*50+p*0.5)>0.97)?1:0; return [UIColor colorWithHue:0.73 saturation:0.8 brightness:fminf(1,0.15+bolt) alpha:barOpacity]; }
        default: return chromaColorForHue(hue);
    }
}

// ==================== EQ LAYER ====================

static CALayer *buildEQLayer(CGRect bounds, CGFloat t) {
    CALayer *c = [CALayer layer];
    c.frame = bounds;
    int bands = (int)MAX(4, MIN(eqBands, 20));
    CGFloat bw = bounds.size.width / bands;
    for (int i = 0; i < bands; i++) {
        CGFloat sim = sinf(t*3+i*0.7)*0.5+0.5;
        if (enableSoundReactive) sim = fminf(1, sim*0.5+currentAudioLevel*0.8);
        CALayer *band = [CALayer layer];
        CGFloat bh = sim * bounds.size.height;
        band.frame = CGRectMake(i*bw+1, bounds.size.height-bh, bw-2, bh);
        band.backgroundColor = chromaColorForHue((CGFloat)i/bands).CGColor;
        band.cornerRadius = 1;
        [c addSublayer:band];
    }
    return c;
}

// ==================== PARTICLE SYSTEM ====================

@interface CHXParticle : NSObject
@property CGFloat x,y,vx,vy,life,maxLife,size,hue;
@property (strong) UIColor *color;
@end
@implementation CHXParticle @end

static NSMutableArray *particles = nil;

static void updateParticles(UIView *v) {
    if (!enableParticles) return;
    if (!particles) particles = [NSMutableArray array];
    while ((NSInteger)particles.count < particleCount) {
        CHXParticle *p = [CHXParticle new];
        p.x = arc4random_uniform((uint32_t)v.bounds.size.width);
        p.y = v.bounds.size.height/2;
        p.vx = ((CGFloat)(arc4random_uniform(100))-50)/50.0;
        p.vy = -((CGFloat)arc4random_uniform(30))/10.0-0.5;
        p.maxLife = p.life = 0.5+(CGFloat)arc4random_uniform(100)/100.0;
        p.hue = fmodf(hue+p.x/v.bounds.size.width, 1.0);
        p.color = chromaColorForHue(p.hue);
        p.size = 1+(CGFloat)arc4random_uniform(3);
        [particles addObject:p];
    }
    NSMutableArray *dead = [NSMutableArray array];
    for (CHXParticle *p in particles) {
        p.life -= 0.016; p.x += p.vx; p.y += p.vy;
        if (enableSoundReactive) p.vy -= currentAudioLevel*0.1;
        if (p.life <= 0) [dead addObject:p];
    }
    [particles removeObjectsInArray:dead];
}

// ==================== MAIN ANIMATION LOOP ====================

static void updateChromaBar(CADisplayLink *dl) {
    if (!chromaBarView || !enabled) return;
    if (hideInLowPower && [NSProcessInfo processInfo].lowPowerModeEnabled) {
        chromaBarView.hidden = YES; return;
    }
    if (enableSoundReactive) currentAudioLevel = getAudioLevel();

    CGFloat dt = (1.0/60.0) * animationSpeed;

    if (randomMode) {
        randomTime += dt;
        if (randomTime >= randomInterval) { randomTime=0; currentRandomMode=arc4random_uniform(25); }
    }
    NSInteger mode = randomMode ? currentRandomMode : colorMode;

    // Strobe override
    if (enableStrobeMode) {
        strobeTime += dt * strobeRate;
        BOOL next = (fmodf(strobeTime,1.0) < 0.5);
        if (next != strobeOn) { strobeOn=next; if(strobeOn) triggerHaptic(); }
        chromaBarView.alpha = strobeOn ? barOpacity : 0.0;
    }

    // Build color array for gradient modes
    NSMutableArray *cols = [NSMutableArray array];
    int steps = 24;

    switch (mode) {
        case 0: { // Spectrum
            hue = fmodf(hue+0.005*animationSpeed, 1.0);
            chromaBarView.backgroundColor = chromaColorForHue(hue);
            break;
        }
        case 1: { // Wave
            waveOffset = fmodf(waveOffset+0.02*animationSpeed, 1.0);
            int segs = mirrorEffect ? 6 : 12;
            for (int i=0;i<=segs;i++) {
                CGFloat h = fmodf(waveOffset+(CGFloat)i/segs, 1.0);
                if (mirrorEffect&&i>segs/2) h=fmodf(waveOffset+(CGFloat)(segs-i)/segs,1.0);
                [cols addObject:(id)chromaColorForHue(h).CGColor];
            }
            applyGradientColors(chromaBarView, cols);
            break;
        }
        case 2: { // Breathing
            if (breathIncreasing) { breathAlpha+=0.015*animationSpeed; if(breathAlpha>=1){breathAlpha=1;breathIncreasing=NO;triggerHaptic();} }
            else { breathAlpha-=0.015*animationSpeed; if(breathAlpha<=0.05){breathAlpha=0.05;breathIncreasing=YES;} }
            hue = fmodf(hue+0.002*animationSpeed, 1.0);
            chromaBarView.backgroundColor = [UIColor colorWithHue:hue saturation:colorSaturation/100.0
                                                        brightness:colorBrightness/100.0 alpha:breathAlpha*barOpacity];
            break;
        }
        case 3: { // Fade
            static CGFloat fp=0; static NSInteger fi=0;
            static NSArray *fc = nil;
            if (!fc) fc = @[@0.0f,@0.08f,@0.16f,@0.33f,@0.5f,@0.66f,@0.75f,@0.83f,@0.92f];
            fp += 0.008*animationSpeed;
            if (fp>=1){fp=0;fi=(fi+1)%fc.count;}
            CGFloat h1=[fc[fi] floatValue], h2=[fc[(fi+1)%fc.count] floatValue];
            chromaBarView.backgroundColor = chromaColorForHue(h1+(h2-h1)*fp);
            break;
        }
        case 4: { // Static
            if (gradientStyle)
                applyGradient(chromaBarView, @[chromaColorForHue(hue), chromaColorForHue(fmodf(hue+0.3,1))], gradientAngle);
            else
                chromaBarView.backgroundColor = chromaColorForHue(hue);
            break;
        }
        case 5: { // Pulse
            if (enableSoundReactive) { pulseScale = fminf(2.0, 1.0+currentAudioLevel*0.8); }
            else {
                if (pulseGrowing){pulseScale+=0.04*animationSpeed;if(pulseScale>=1.6){pulseScale=1.6;pulseGrowing=NO;triggerHaptic();}}
                else{pulseScale-=0.04*animationSpeed;if(pulseScale<=1.0){pulseScale=1.0;pulseGrowing=YES;hue=fmodf(hue+0.1,1);}}
            }
            chromaBarView.transform = CGAffineTransformMakeScale(1.0, pulseScale);
            chromaBarView.backgroundColor = chromaColorForHue(hue);
            break;
        }
        case 6: { // Fire
            fireTime+=dt*0.5;
            for(int i=0;i<=steps;i++) [cols addObject:(id)fireColor(fireTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 7: { // Ice
            iceTime+=dt*0.3;
            for(int i=0;i<=steps;i++) [cols addObject:(id)iceColor(iceTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 8: { // Neon
            fireTime+=dt*0.8;
            for(int i=0;i<=steps;i++) [cols addObject:(id)neonColor(fireTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 9: { // Aurora
            auroraTime+=dt*0.5;
            for(int i=0;i<=steps;i++) [cols addObject:(id)auroraColor(auroraTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 10: { // Music React
            static CGFloat bt=0; static BOOL ob=NO;
            bt+=dt; CGFloat iv=60.0/currentBPM;
            if(bt>=iv){bt=0;ob=YES;hue=fmodf(hue+arc4random_uniform(30)/100.0,1);triggerHaptic();}
            else ob=NO;
            CGFloat br = ob ? 1.0 : fmaxf(0.3, 0.4+currentAudioLevel*0.6);
            chromaBarView.backgroundColor = [UIColor colorWithHue:hue saturation:1 brightness:br alpha:barOpacity];
            break;
        }
        case 11: { // Rainbow Trail
            trailPos = fmodf(trailPos+0.03*animationSpeed, 1.0);
            int tl = (int)MAX(2,MIN(trailLength,10));
            for(int i=0;i<=steps;i++){
                CGFloat p=(CGFloat)i/steps;
                CGFloat d=fmodf(fabsf(p-trailPos),1.0); if(d>0.5) d=1-d;
                CGFloat a=fmaxf(0,1-d*2*(10.0/tl))*barOpacity;
                CGFloat th=fmodf(trailPos-p*0.3,1.0);
                [cols addObject:(id)[UIColor colorWithHue:th saturation:1 brightness:1 alpha:a].CGColor];
            }
            applyGradientColors(chromaBarView, cols); break;
        }
        case 12: { // Gradient Static (6 colors)
            NSArray *hexes = @[customColor1,customColor2,customColor3,customColor4,customColor5,customColor6];
            NSMutableArray *uiCols = [NSMutableArray array];
            for (NSString *h in hexes) [uiCols addObject:colorFromHex(h)];
            applyGradient(chromaBarView, uiCols, gradientAngle);
            break;
        }
        case 13: { // Twinkle
            twinkleTime+=dt;
            chromaBarView.backgroundColor = chromaColorForHue(fmodf(twinkleTime*0.05,1));
            if (arc4random_uniform(10)<3) {
                UIView *sp = [[UIView alloc] initWithFrame:CGRectMake(arc4random_uniform((uint32_t)chromaBarView.bounds.size.width),0,3,chromaBarView.bounds.size.height)];
                sp.backgroundColor=[UIColor whiteColor]; sp.alpha=0.9; sp.layer.cornerRadius=1.5;
                [chromaBarView addSubview:sp];
                [UIView animateWithDuration:0.25 animations:^{sp.alpha=0;} completion:^(BOOL d){[sp removeFromSuperview];}];
            }
            break;
        }
        case 14: { // Custom Colors (6-color cycle)
            static CGFloat cf=0; static NSInteger ci=0;
            cf+=0.008*animationSpeed; if(cf>=1){cf=0;ci=(ci+1)%6;}
            NSArray *hx=@[customColor1,customColor2,customColor3,customColor4,customColor5,customColor6];
            chromaBarView.backgroundColor = lerpColor(colorFromHex(hx[ci]),colorFromHex(hx[(ci+1)%6]),cf);
            break;
        }

        // ===== NEW MODES 15–24 =====

        case 15: { // Lava Lamp 🌋
            lavaTime+=dt*0.4;
            for(int i=0;i<=steps;i++) [cols addObject:(id)lavaColor(lavaTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 16: { // Galaxy 🌌
            galaxyTime+=dt*0.35;
            for(int i=0;i<=steps;i++) [cols addObject:(id)galaxyColor(galaxyTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 17: { // Plasma 🔮
            plasmaTime+=dt*0.7;
            for(int i=0;i<=steps;i++) [cols addObject:(id)plasmaColor(plasmaTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 18: { // Cyberpunk ⚡
            cyberTime+=dt;
            for(int i=0;i<=steps;i++) [cols addObject:(id)cyberpunkColor(cyberTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 19: { // Synthwave 🌅
            synthTime+=dt*0.6; waveOffset=fmodf(waveOffset+0.01*animationSpeed,1);
            for(int i=0;i<=steps;i++) [cols addObject:(id)synthwaveColor(synthTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 20: { // Sunrise 🌄
            sunriseTime+=dt*0.5;
            for(int i=0;i<=steps;i++) [cols addObject:(id)sunriseColor(sunriseTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 21: { // EQ Visualizer 🎚️
            eqTime+=dt*2.0;
            for(CALayer *l in [chromaBarView.layer.sublayers copy]) [l removeFromSuperlayer];
            chromaBarView.backgroundColor = [UIColor blackColor];
            [chromaBarView.layer addSublayer:buildEQLayer(chromaBarView.bounds, eqTime)];
            break;
        }
        case 22: { // Weather Sync 🌤️
            fireTime+=dt;
            for(int i=0;i<=steps;i++) [cols addObject:(id)weatherColor(fireTime,(CGFloat)i/steps).CGColor];
            applyGradientColors(chromaBarView, cols); break;
        }
        case 23: { // Heartbeat ❤️
            static CGFloat ht=0;
            ht+=dt*animationSpeed; CGFloat cy=fmodf(ht,1.0);
            CGFloat br;
            if      (cy<0.05)  br=cy/0.05;
            else if (cy<0.15)  br=1.0-(cy-0.05)/0.1;
            else if (cy<0.20)  br=(cy-0.15)/0.05*0.7;
            else if (cy<0.30)  br=0.7-(cy-0.20)/0.1*0.7;
            else br=0.05;
            if (cy<0.06&&ht>0.1) triggerHaptic();
            chromaBarView.backgroundColor=[UIColor colorWithHue:0 saturation:1 brightness:fmaxf(0.05,br) alpha:barOpacity];
            break;
        }
        case 24: { // Tilt Reactive 📱
            hue = fmodf(0.5+accelX*0.3+accelY*0.2, 1.0);
            UIColor *c1=chromaColorForHue(fmodf(hue-0.1,1));
            UIColor *c2=chromaColorForHue(fmodf(hue+0.1,1));
            applyGradient(chromaBarView, @[c1,c2], gradientAngle+accelX*30);
            break;
        }
    }

    // ---- POST-PROCESSING ----

    if ((glowEffect||enableRainbowGlow) && glowView) {
        UIColor *glowColor = enableRainbowGlow ? chromaColorForHue(hue) : (chromaBarView.backgroundColor ?: [UIColor whiteColor]);
        glowView.layer.shadowColor = glowColor.CGColor;
        glowView.layer.shadowRadius = glowRadius + (enableSoundReactive ? currentAudioLevel*15 : 0);
        glowView.layer.shadowOpacity = 0.9;
        glowView.layer.shadowOffset = CGSizeZero;
    }

    if (barShadowOpacity > 0) {
        chromaBarView.layer.shadowColor   = [UIColor blackColor].CGColor;
        chromaBarView.layer.shadowOffset  = CGSizeMake(0, barShadowBlur*0.3);
        chromaBarView.layer.shadowRadius  = barShadowBlur;
        chromaBarView.layer.shadowOpacity = barShadowOpacity;
        chromaBarView.layer.masksToBounds = NO;
    }

    if (enableChromaShift) {
        chromaBarView.layer.borderWidth = 1.0;
        chromaBarView.layer.borderColor = [UIColor colorWithHue:fmodf(hue+0.33,1) saturation:1 brightness:1 alpha:0.7].CGColor;
    }

    if (enableParticles) updateParticles(chromaBarView);

    // Mirror gradient to second bar in dual mode
    if (enableDualBar && chromaBarView2) {
        chromaBarView2.backgroundColor = chromaBarView.backgroundColor;
        for (CALayer *l in [chromaBarView2.layer.sublayers copy])
            if ([l isKindOfClass:[CAGradientLayer class]]) [l removeFromSuperlayer];
        for (CALayer *l in chromaBarView.layer.sublayers) {
            if ([l isKindOfClass:[CAGradientLayer class]]) {
                CAGradientLayer *dup = [CAGradientLayer layer];
                dup.frame = chromaBarView2.bounds;
                dup.colors = [(CAGradientLayer*)l colors];
                dup.startPoint = [(CAGradientLayer*)l startPoint];
                dup.endPoint   = [(CAGradientLayer*)l endPoint];
                [chromaBarView2.layer addSublayer:dup];
            }
        }
    }
}

// ==================== MAIN HOOK ====================

%hook UIView

- (void)didMoveToWindow {
    %orig;
    NSString *cn = NSStringFromClass([self class]);
    if ([cn containsString:@"HomeIndicator"]||[cn containsString:@"HomeGrabber"]||
        [cn containsString:@"HomeBar"]||[cn containsString:@"GrabberView"]) {
        if (!enabled) return;
        LoadPreferences();
        dispatch_async(dispatch_get_main_queue(), ^{ [self setupChromaBar]; });
    }
}

%new
- (void)setupChromaBar {
    if (!enabled) return;
    [displayLink invalidate]; displayLink=nil;
    if (chromaBarView)  { [chromaBarView  removeFromSuperview]; chromaBarView=nil; }
    if (chromaBarView2) { [chromaBarView2 removeFromSuperview]; chromaBarView2=nil; }
    if (glowView)       { [glowView       removeFromSuperview]; glowView=nil; }

    CGFloat h = barHeight, w = self.bounds.size.width, yOff = 0;
    switch (barPosition) { case 1: yOff=-5; break; case 2: yOff=-12; break; }
    CGFloat radius = (barCornerRadius<0) ? h/2.0 : barCornerRadius;

    chromaBarView = [[UIView alloc] initWithFrame:CGRectMake(0,yOff,w,h)];
    chromaBarView.layer.cornerRadius = radius;
    chromaBarView.clipsToBounds = (barBlur<=0 && !enableChromaShift);
    chromaBarView.alpha = barOpacity;
    chromaBarView.userInteractionEnabled = enableGestures;

    if (barBlur>0) {
        UIVisualEffectView *bv = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        bv.frame=chromaBarView.bounds; bv.alpha=barBlur/20.0;
        [chromaBarView addSubview:bv];
    }

    if (glowEffect||enableRainbowGlow) {
        glowView = [[UIView alloc] initWithFrame:chromaBarView.frame];
        glowView.backgroundColor=[UIColor clearColor];
        glowView.layer.cornerRadius=radius;
        glowView.layer.shadowColor=[UIColor whiteColor].CGColor;
        glowView.layer.shadowRadius=glowRadius;
        glowView.layer.shadowOpacity=0.8;
        glowView.layer.shadowOffset=CGSizeZero;
        glowView.userInteractionEnabled=NO;
        [self insertSubview:glowView belowSubview:self];
    }

    if (enableBorderGlow) {
        chromaBarView.layer.borderWidth=1.5;
        chromaBarView.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.6].CGColor;
    }

    [self addSubview:chromaBarView];

    if (enableDualBar) {
        CGFloat y2=yOff+h+dualBarGap;
        chromaBarView2=[[UIView alloc] initWithFrame:CGRectMake(0,y2,w,h)];
        chromaBarView2.layer.cornerRadius=radius;
        chromaBarView2.clipsToBounds=YES;
        chromaBarView2.alpha=barOpacity*0.6;
        chromaBarView2.transform=CGAffineTransformMakeScale(1,-1);
        chromaBarView2.userInteractionEnabled=NO;
        [self addSubview:chromaBarView2];
    }

    if (enableGestures) {
        UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:chromaBarView action:@selector(handleChromaTap:)];
        UISwipeGestureRecognizer *sl=[[UISwipeGestureRecognizer alloc] initWithTarget:chromaBarView action:@selector(handleChromaSwipe:)];
        UISwipeGestureRecognizer *sr=[[UISwipeGestureRecognizer alloc] initWithTarget:chromaBarView action:@selector(handleChromaSwipe:)];
        sl.direction=UISwipeGestureRecognizerDirectionLeft;
        sr.direction=UISwipeGestureRecognizerDirectionRight;
        [chromaBarView addGestureRecognizer:tap];
        [chromaBarView addGestureRecognizer:sl];
        [chromaBarView addGestureRecognizer:sr];
    }

    if (enableBarBounce) {
        chromaBarView.transform=CGAffineTransformMakeScale(0.01,1);
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.8
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{chromaBarView.transform=CGAffineTransformIdentity;}
                         completion:nil];
    }

    if (enableSoundReactive) startAudioMonitoring();
    if (enableAccelerometer) startMotionUpdates();

    displayLink=[CADisplayLink displayLinkWithTarget:[NSBlockOperation blockOperationWithBlock:^{updateChromaBar(nil);}] selector:@selector(main)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

%new
- (void)handleChromaTap:(UITapGestureRecognizer *)gr {
    NSMutableDictionary *p=[[NSMutableDictionary alloc]initWithContentsOfFile:PREF_PATH]?:[NSMutableDictionary dictionary];
    p[@"colorMode"]=@((colorMode+1)%25);
    [p writeToFile:PREF_PATH atomically:YES];
    LoadPreferences(); triggerHaptic();
}

%new
- (void)handleChromaSwipe:(UISwipeGestureRecognizer *)gr {
    NSMutableDictionary *p=[[NSMutableDictionary alloc]initWithContentsOfFile:PREF_PATH]?:[NSMutableDictionary dictionary];
    if (gr.direction==UISwipeGestureRecognizerDirectionLeft) animationSpeed=fmaxf(0.1,animationSpeed-0.5);
    else animationSpeed=fminf(5.0,animationSpeed+0.5);
    p[@"animationSpeed"]=@(animationSpeed);
    [p writeToFile:PREF_PATH atomically:YES];
    triggerHaptic();
}

%end

// ==================== SPRINGBOARD ====================

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)app {
    %orig; LoadPreferences();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,
        (CFNotificationCallback)^(CFNotificationCenterRef c,void *o,CFStringRef n,const void *obj,CFDictionaryRef i){LoadPreferences();},
        CFSTR("com.chromahomebarxplus.prefschanged"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
}
%end

// ==================== NOTIFICATION PULSE ====================

%hook SBBulletinDestinationViewController
- (void)addBulletin:(id)bulletin {
    %orig;
    if (enablePulseOnNotification && chromaBarView) {
        UIColor *prev=chromaBarView.backgroundColor;
        [UIView animateWithDuration:0.1 animations:^{chromaBarView.backgroundColor=[UIColor whiteColor];}
                         completion:^(BOOL d){[UIView animateWithDuration:0.3 animations:^{chromaBarView.backgroundColor=prev;}];}];
        triggerHaptic();
    }
}
%end

// ==================== KEYBOARD / LANDSCAPE ====================

%hook UIInputWindowController
- (void)moveToDisplayMode:(NSInteger)m {
    %orig;
    if (hideOnKeyboard){BOOL v=(m!=0); chromaBarView.hidden=v; if(glowView)glowView.hidden=v;}
}
%end

%hook UIViewController
- (void)viewWillTransitionToSize:(CGSize)sz withTransitionCoordinator:(id)coord {
    %orig;
    if (hideOnLandscape){BOOL l=sz.width>sz.height; chromaBarView.hidden=l; if(glowView)glowView.hidden=l;}
}
%end

// ==================== TOUCH REACTION ====================

%hook UIWindow
- (void)sendEvent:(UIEvent *)ev {
    %orig;
    if (enableReactToTouch&&chromaBarView) {
        UITouch *t=ev.allTouches.anyObject;
        if (t&&t.phase==UITouchPhaseBegan) {
            UIColor *r=chromaBarView.backgroundColor;
            chromaBarView.backgroundColor=[UIColor whiteColor];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,80*NSEC_PER_MSEC),dispatch_get_main_queue(),^{chromaBarView.backgroundColor=r;});
            hue=fmodf(hue+0.15,1.0); triggerHaptic();
        }
    }
}
%end

// ==================== PER-APP PROFILES ====================

%hook SBApplicationController
- (void)_handleApplicationWillActivate:(id)app {
    %orig;
    if (!perAppProfiles) return;
    NSDictionary *profiles=[NSDictionary dictionaryWithContentsOfFile:PROFILES_PATH];
    NSString *bid=[app respondsToSelector:@selector(bundleIdentifier)] ? [app performSelector:@selector(bundleIdentifier)] : nil;
    if (bid&&profiles[bid]) {
        NSDictionary *ap=profiles[bid];
        if (ap[@"colorMode"])      colorMode=[ap[@"colorMode"] integerValue];
        if (ap[@"animationSpeed"]) animationSpeed=[ap[@"animationSpeed"] floatValue];
    }
}
%end

// ==================== CONSTRUCTOR ====================

%ctor {
    LoadPreferences();
    NSLog(@"[ChromaHomeBarX+ v3.0] Loaded | Mode:%ld Speed:%.1f Audio:%d Haptics:%d Modes:25",
          (long)colorMode, animationSpeed, enableSoundReactive, enableHaptics);
}
