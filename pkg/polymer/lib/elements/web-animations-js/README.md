[![Build Status](https://travis-ci.org/web-animations/web-animations-js.png?branch=master)](https://travis-ci.org/web-animations/web-animations-js)

Latest specification at http://dev.w3.org/fxtf/web-animations/.

## Learn the tech

### Why Web Animations?

Four animation-related specifications already exist on the web platform: [CSS Transitions](http://dev.w3.org/csswg/css-transitions/),
[CSS Animations](http://dev.w3.org/csswg/css-animations/), [SVG Animations](http://www.w3.org/TR/SVG/animate.html) / [SMIL](http://www.w3.org/TR/2001/REC-smil-animation-20010904/), and `requestAnimationFrame()`. However:

- *CSS Transitions / CSS Animations are not very expressive* - animations can't
be composed, or sequenced, or even reliably run in parallel; and animations can't be tweaked from script.
- *SVG Animations are very expressive, but also very complicated*. SVG Animations
can't be applied to HTML content.
- *`requestAnimationFrame()` is not a declarative approach* - it requires the use
of the main thread, and will therefore jank if the main thread is busy.

Web Animations is a new specification for animated content on the web. It's being
developed as a W3C specification as part of the CSS and SVG working groups. It aims
to address the deficiencies inherent in these four specifications. Web Animations also aims to replace the underlying implementations of CSS Transitions, CSS Animations and SVG Animations, so that:

- The code cost of supporting animations on the web is reduced.
- The various animations specifications are interoperable.
- Spec authors and browser vendors have a single place to experiment with new animation innovations to improve the Web for the future.

### Basic usage

Here's a simple example of an animation that scales and changes the opacity of
a `<div>` over 0.5 seconds. The animation alternates producing a pulsing effect.

    <div class="pulse" style="width:150px;">Hello world!</div>
    <script>
      var elem = document.querySelector('.pulse');
      var player = document.timeline.play(new Animation(elem, [
          {opacity: "0.5", transform: "scale(0.5)"}, 
          {opacity: "1.0", transform: "scale(1)"}
        ],
        {
          direction: "alternate", duration: 0.5, iterations: Infinity
        }));
    </script>

### The animation model

The Web Animations model is a description of an engine for animation content on the web. The engine is sufficiently powerful to support CSS Transitions, CSS Animations and SVG Animations.

Web Animations also exposes a JS API to the model. This API defines a number of
new interfaces that are exposed to JavaScript. We'll go through some of the more
important ones here: Animations, AnimationEffects, TimingDictionaries, TimingGroups, and Players.

An `Animation` object defines a single animation effect that applies to a single element target. For example:

    var animation = new Animation(targetElement,
        [{left: '0px'}, {left: '100px'}], 2);

Here, the target element's "left" CSS property is modified smoothly from `0px` to `100px` over 2 seconds.

### Specifying animation effects

An `AnimationEffect` object controls which CSS properties and SVG attributes are
modified by an animation, and the values that those properties and attributes
vary between. AnimationEffect objects also control whether the effect replaces
or adds to the underlying value.

There are three major kinds of effects: `KeyframeEffect`, `MotionPathEffect`, and `EffectCallback`.

#### Animating between keyframes

A `KeyframeEffect` controls one or more properties/attributes by linearly
interpolating values between specified keyframes. KeyframeEffects are usually
defined by specifying the keyframe offset and the property-value pair in a
dictionary:

    [
      {offset: 0.2, left: "35px"},
      {offset: 0.6, left: "50px"},
      {offset: 0.9, left: "70px"},
    ]

If the offset is not specified, keyframes are evenly distributed at offsets
between 0 and 1.

    [{left: "35px"}, {left: "50px"}, {left: "70px"}]

See the [specification](http://www.w3.org/TR/web-animations/#keyframe-animation-effects) for the details
of the keyframe distribution procedure, and how KeyframeEffects are
evaluated at offsets outside those specified by the keyframes.

#### Animating along paths

A `MotionPathEffect` allows elements to be animated along SVG-style paths. For example:

    <svg xmlns="http://www.w3.org/2000/svg" version="1.1">
      <defs>
        <path id=path d="M 100,100 a 75,75 0 1,0 150,0 a 75,75 0 1,0 -150,0"/>
      </defs>
    </svg>
    <script>
      var animFunc = new MotionPathEffect(document.querySelector('#path').pathSegList);
      var animation = new Animation(targetElement, animFunc, 2);
    </script>

#### Custom animation effects

An `EffectCallback` allows animations to generate call-outs to JavaScript
rather than manipulating properties directly. Please see the
[specification](http://www.w3.org/TR/web-animations/#custom-effects) for more details on this
feature.

### Sequencing and synchronizing animations

Two different types of TimingGroups (`ParGroup` and `SeqGroup`) allow animations to be synchronized and sequenced.

To play a list of animations in parallel:

    var parGroup = new ParGroup([new Animation(...), new Animation(...)]);

To play a list in sequence:

    var seqGroup = new SeqGroup([new Animation(...), new Animation(...)]);

Because `Animation`, `ParGroup`, `SeqGroup` are all TimedItems, groups can be nested:

    var parGroup = new ParGroup([
      new SeqGroup([
        new Animation(...),
        new Animation(...),
      ]),
      new Animation(...)
    ]);

Groups also take an optional TimingDictionary parameter (see below), which among other things allows iteration and timing functions to apply at the group level:

    var parGroup = new ParGroup([new Animation(...), new Animation(...)], {iterations: 4});

### Controlling the animation timing

TimingDictionaries are used to control the internal timing of an animation (players control how an animation progresses relative to document time). TimingDictionaries have several properties that can be tweaked:

- **duration**: the duration of a single iteration of the animation
- **iterations**: the number of iterations of the animation that will be played (fractional iterationss are allowed)
- **iterationStart**: the start offset of the first iteration
- **fill**: whether the animation has effect before starting the first iteration and/or after finishing the final iteration
- **delay**: the time between the animation's start time and the first animation effect of the animation
- **playbackRate**: the rate at which the animation progresses relative to external time
- **direction**: the direction in which successive iterations of the animation play back
- **easing**: fine-grained control over how external time impacts an animation across the total active duration of the animation.

The values provided within TimingDictionaries combine with the animation hierarchy
to generate concrete start and end values for animation iterations, animation
backwards fills, and animation forwards fills. There are a few simple rules which govern this:

- Animations never extend beyond the start or end values of their parent iteration.
- Animations only fill beyond their parent iteration if:
    - the relevant fill value is selected for the animation;
    - the matching fill value is selected for the parent; and
    - this is the first parent iteration (for `fill: 'backward'`) or last parent iteration (for `fill: 'forward'`)
- Missing `duration` values for TimingGroups are generated based on the calculated durations of the child animations.

The following example illustrates these rules:

    var parGroup = new ParGroup([
      new SeqGroup([
        new Animation(..., {duration: 3}),
        new Animation(..., {duration: 5, fill: 'both'})
      ], {duration: 6, delay: 3, fill: 'none'}),
      new Animation(..., {duration: 8, fill: 'forward'})
    ], {iterations: 2, fill: 'forward'});

In this example:

- The `SeqGroup` has an explicit `duration` of 6 seconds, and so the
second child animation will only play for the first 3 of its 5 second duration
- The `ParGroup` has no explicit duration, and will be provided with a
calculated duration of the max (`duration + delay`) of its children - in this case 9 seconds.
- Although `fill: "both"` is specified for the second `Animation` within the `SeqGroup`, the `SeqGroup` itself has a `fill` of "none". Hence, as the animation ends right at the end of the `SeqGroup`, the animation will only fill backwards, and only up until the boundary of the `SeqGroup` (i.e. 3 seconds after the start of the `ParGroup`).
- The `Animation` inside the `ParGroup` and the `ParGroup` are both `fill: "forward"`. Therefore the animation will fill forward in two places: 
    - from 8 seconds after the `ParGroup` starts until the second iteration of the `ParGroup` starts (i.e. for 1 second)
    - from 17 seconds after the `ParGroup` starts, extending forward indefinitely.

### Playing Animations

In order to play an `Animation` or `TimingGroup`, a `Player` must be constructed:

    var player = document.timeline.play(myAnimation);

Players provide complete control the start time and current playback head of their attached animation. However, players can't modify any internal details of an animation.

Players can be used to pause, seek, reverse, or modify the playback rate of an animation.

`document.timeline.currentTime` is a timeline's global time. It gives the number
of seconds since the document fired its load event.

## Polyfill details

### Getting started

Include `web-animations.js` in your project:

    <script src="web-animations-js/web-animations.js"></script> 

### Polyfill notes

#### Prefix handling

In order to work in as many browsers as feasible, we have decided to take the
following approach to prefix handling:

- the polyfill will automatically detect the correctly prefixed name to use when
writing animated properties back to the platform.
- where possible, the polyfill will *only* accept unprefixed versions of experimental features. For example:

        var animation = new Animation(elem, {"transform": "translate(100px, 100px)"}, 2);

  will work in all browsers that implement a conforming version of `transform`, but

        var animation =  new Animation(elem, {"-webkit-transform": "translate(100px, 100px)"}, 2);
    
  will not work anywhere.

#### Experimental features

When the polyfill requires features to implement functionality that is not inherently specified using those
features (for example, CSS `calc()` is required in order to implement merging between lengths with different units) 
then the polyfill will provide a console warning in browsers where these features are absent.

## Tools & testing

For running tests or building minified files, consult the
[tooling information](http://www.polymer-project.org/resources/tooling-strategy.html).
