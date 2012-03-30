#library('html');

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:html library.






Window get window() native "return window;";
_WindowImpl get _window() native "return window;";

Document get document() native "return document;";

_DocumentImpl get _document() native "return document;";

// Workaround for tags like <cite> that lack their own Element subclass --
// Dart issue 1990.
class _HTMLElementImpl extends _ElementImpl native "*HTMLElement" {
}

class _AbstractWorkerImpl extends _EventTargetImpl implements AbstractWorker native "*AbstractWorker" {

  _AbstractWorkerEventsImpl get on() =>
    new _AbstractWorkerEventsImpl(this);

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  bool $dom_dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";
}

class _AbstractWorkerEventsImpl extends _EventsImpl implements AbstractWorkerEvents {
  _AbstractWorkerEventsImpl(_ptr) : super(_ptr);

  EventListenerList get error() => _get('error');
}

class _AnchorElementImpl extends _ElementImpl implements AnchorElement native "*HTMLAnchorElement" {

  String charset;

  String coords;

  String download;

  String hash;

  String host;

  String hostname;

  String href;

  String hreflang;

  String name;

  final String origin;

  String pathname;

  String ping;

  String port;

  String protocol;

  String rel;

  String rev;

  String search;

  String shape;

  String target;

  String type;

  String toString() native;
}

class _AnimationImpl implements Animation native "*WebKitAnimation" {

  static final int DIRECTION_ALTERNATE = 1;

  static final int DIRECTION_NORMAL = 0;

  static final int FILL_BACKWARDS = 1;

  static final int FILL_BOTH = 3;

  static final int FILL_FORWARDS = 2;

  static final int FILL_NONE = 0;

  final num delay;

  final int direction;

  final num duration;

  num elapsedTime;

  final bool ended;

  final int fillMode;

  final int iterationCount;

  final String name;

  final bool paused;

  void pause() native;

  void play() native;
}

class _AnimationEventImpl extends _EventImpl implements AnimationEvent native "*WebKitAnimationEvent" {

  final String animationName;

  final num elapsedTime;
}

class _AnimationListImpl implements AnimationList native "*WebKitAnimationList" {

  final int length;

  _AnimationImpl item(int index) native;
}

class _AppletElementImpl extends _ElementImpl implements AppletElement native "*HTMLAppletElement" {

  String align;

  String alt;

  String archive;

  String code;

  String codeBase;

  String height;

  String hspace;

  String name;

  String object;

  String vspace;

  String width;
}

class _AreaElementImpl extends _ElementImpl implements AreaElement native "*HTMLAreaElement" {

  String alt;

  String coords;

  final String hash;

  final String host;

  final String hostname;

  String href;

  bool noHref;

  final String pathname;

  String ping;

  final String port;

  final String protocol;

  final String search;

  String shape;

  String target;
}

class _ArrayBufferImpl implements ArrayBuffer native "*ArrayBuffer" {

  final int byteLength;

  _ArrayBufferImpl slice(int begin, [int end = null]) native;
}

class _ArrayBufferViewImpl implements ArrayBufferView native "*ArrayBufferView" {

  final _ArrayBufferImpl buffer;

  final int byteLength;

  final int byteOffset;
}

class _AttrImpl extends _NodeImpl implements Attr native "*Attr" {

  final bool isId;

  final String name;

  final _ElementImpl ownerElement;

  final bool specified;

  String value;
}

class _AudioBufferImpl implements AudioBuffer native "*AudioBuffer" {

  final num duration;

  num gain;

  final int length;

  final int numberOfChannels;

  final num sampleRate;

  _Float32ArrayImpl getChannelData(int channelIndex) native;
}

class _AudioBufferSourceNodeImpl extends _AudioSourceNodeImpl implements AudioBufferSourceNode native "*AudioBufferSourceNode" {

  static final int FINISHED_STATE = 3;

  static final int PLAYING_STATE = 2;

  static final int SCHEDULED_STATE = 1;

  static final int UNSCHEDULED_STATE = 0;

  _AudioBufferImpl buffer;

  final _AudioGainImpl gain;

  bool loop;

  bool looping;

  final _AudioParamImpl playbackRate;

  final int playbackState;

  void noteGrainOn(num when, num grainOffset, num grainDuration) native;

  void noteOff(num when) native;

  void noteOn(num when) native;
}

class _AudioChannelMergerImpl extends _AudioNodeImpl implements AudioChannelMerger native "*AudioChannelMerger" {
}

class _AudioChannelSplitterImpl extends _AudioNodeImpl implements AudioChannelSplitter native "*AudioChannelSplitter" {
}

class _AudioContextImpl implements AudioContext native "*AudioContext" {

  final int activeSourceCount;

  final num currentTime;

  final _AudioDestinationNodeImpl destination;

  final _AudioListenerImpl listener;

  EventListener oncomplete;

  final num sampleRate;

  _RealtimeAnalyserNodeImpl createAnalyser() native;

  _BiquadFilterNodeImpl createBiquadFilter() native;

  _AudioBufferImpl createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate = null]) native;

  _AudioBufferSourceNodeImpl createBufferSource() native;

  _AudioChannelMergerImpl createChannelMerger() native;

  _AudioChannelSplitterImpl createChannelSplitter() native;

  _ConvolverNodeImpl createConvolver() native;

  _DelayNodeImpl createDelayNode([num maxDelayTime = null]) native;

  _DynamicsCompressorNodeImpl createDynamicsCompressor() native;

  _AudioGainNodeImpl createGainNode() native;

  _HighPass2FilterNodeImpl createHighPass2Filter() native;

  _JavaScriptAudioNodeImpl createJavaScriptNode(int bufferSize) native;

  _LowPass2FilterNodeImpl createLowPass2Filter() native;

  _MediaElementAudioSourceNodeImpl createMediaElementSource(_MediaElementImpl mediaElement) native;

  _AudioPannerNodeImpl createPanner() native;

  _WaveShaperNodeImpl createWaveShaper() native;

  void decodeAudioData(_ArrayBufferImpl audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) native;

  void startRendering() native;
}

class _AudioDestinationNodeImpl extends _AudioNodeImpl implements AudioDestinationNode native "*AudioDestinationNode" {

  final int numberOfChannels;
}

class _AudioElementImpl extends _MediaElementImpl implements AudioElement native "*HTMLAudioElement" {
}

class _AudioGainImpl extends _AudioParamImpl implements AudioGain native "*AudioGain" {
}

class _AudioGainNodeImpl extends _AudioNodeImpl implements AudioGainNode native "*AudioGainNode" {

  final _AudioGainImpl gain;
}

class _AudioListenerImpl implements AudioListener native "*AudioListener" {

  num dopplerFactor;

  num speedOfSound;

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;
}

class _AudioNodeImpl implements AudioNode native "*AudioNode" {

  final _AudioContextImpl context;

  final int numberOfInputs;

  final int numberOfOutputs;

  void connect(_AudioNodeImpl destination, int output, int input) native;

  void disconnect(int output) native;
}

class _AudioPannerNodeImpl extends _AudioNodeImpl implements AudioPannerNode native "*AudioPannerNode" {

  static final int EQUALPOWER = 0;

  static final int EXPONENTIAL_DISTANCE = 2;

  static final int HRTF = 1;

  static final int INVERSE_DISTANCE = 1;

  static final int LINEAR_DISTANCE = 0;

  static final int SOUNDFIELD = 2;

  final _AudioGainImpl coneGain;

  num coneInnerAngle;

  num coneOuterAngle;

  num coneOuterGain;

  final _AudioGainImpl distanceGain;

  int distanceModel;

  num maxDistance;

  int panningModel;

  num refDistance;

  num rolloffFactor;

  void setOrientation(num x, num y, num z) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;
}

class _AudioParamImpl implements AudioParam native "*AudioParam" {

  final num defaultValue;

  final num maxValue;

  final num minValue;

  final String name;

  final int units;

  num value;

  void cancelScheduledValues(num startTime) native;

  void exponentialRampToValueAtTime(num value, num time) native;

  void linearRampToValueAtTime(num value, num time) native;

  void setTargetValueAtTime(num targetValue, num time, num timeConstant) native;

  void setValueAtTime(num value, num time) native;

  void setValueCurveAtTime(_Float32ArrayImpl values, num time, num duration) native;
}

class _AudioProcessingEventImpl extends _EventImpl implements AudioProcessingEvent native "*AudioProcessingEvent" {

  final _AudioBufferImpl inputBuffer;

  final _AudioBufferImpl outputBuffer;
}

class _AudioSourceNodeImpl extends _AudioNodeImpl implements AudioSourceNode native "*AudioSourceNode" {
}

class _BRElementImpl extends _ElementImpl implements BRElement native "*HTMLBRElement" {

  String clear;
}

class _BarInfoImpl implements BarInfo native "*BarInfo" {

  final bool visible;
}

class _BaseElementImpl extends _ElementImpl implements BaseElement native "*HTMLBaseElement" {

  String href;

  String target;
}

class _BaseFontElementImpl extends _ElementImpl implements BaseFontElement native "*HTMLBaseFontElement" {

  String color;

  String face;

  int size;
}

class _BeforeLoadEventImpl extends _EventImpl implements BeforeLoadEvent native "*BeforeLoadEvent" {

  final String url;
}

class _BiquadFilterNodeImpl extends _AudioNodeImpl implements BiquadFilterNode native "*BiquadFilterNode" {

  static final int ALLPASS = 7;

  static final int BANDPASS = 2;

  static final int HIGHPASS = 1;

  static final int HIGHSHELF = 4;

  static final int LOWPASS = 0;

  static final int LOWSHELF = 3;

  static final int NOTCH = 6;

  static final int PEAKING = 5;

  final _AudioParamImpl Q;

  final _AudioParamImpl frequency;

  final _AudioParamImpl gain;

  int type;

  void getFrequencyResponse(_Float32ArrayImpl frequencyHz, _Float32ArrayImpl magResponse, _Float32ArrayImpl phaseResponse) native;
}

class _BlobImpl implements Blob native "*Blob" {

  final int size;

  final String type;

  _BlobImpl webkitSlice([int start = null, int end = null, String contentType = null]) native;
}

class _BlobBuilderImpl implements BlobBuilder native "*WebKitBlobBuilder" {

  void append(var arrayBuffer_OR_blob_OR_value, [String endings = null]) native;

  _BlobImpl getBlob([String contentType = null]) native;
}

class _BodyElementImpl extends _ElementImpl implements BodyElement native "*HTMLBodyElement" {

  _BodyElementEventsImpl get on() =>
    new _BodyElementEventsImpl(this);

  String aLink;

  String background;

  String bgColor;

  String link;

  String vLink;
}

class _BodyElementEventsImpl extends _ElementEventsImpl implements BodyElementEvents {
  _BodyElementEventsImpl(_ptr) : super(_ptr);

  EventListenerList get beforeUnload() => _get('beforeunload');

  EventListenerList get blur() => _get('blur');

  EventListenerList get error() => _get('error');

  EventListenerList get focus() => _get('focus');

  EventListenerList get hashChange() => _get('hashchange');

  EventListenerList get load() => _get('load');

  EventListenerList get message() => _get('message');

  EventListenerList get offline() => _get('offline');

  EventListenerList get online() => _get('online');

  EventListenerList get popState() => _get('popstate');

  EventListenerList get resize() => _get('resize');

  EventListenerList get storage() => _get('storage');

  EventListenerList get unload() => _get('unload');
}

class _ButtonElementImpl extends _ElementImpl implements ButtonElement native "*HTMLButtonElement" {

  bool autofocus;

  bool disabled;

  final _FormElementImpl form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  final _NodeListImpl labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateImpl validity;

  String value;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class _CDATASectionImpl extends _TextImpl implements CDATASection native "*CDATASection" {
}

class _CSSCharsetRuleImpl extends _CSSRuleImpl implements CSSCharsetRule native "*CSSCharsetRule" {

  String encoding;
}

class _CSSFontFaceRuleImpl extends _CSSRuleImpl implements CSSFontFaceRule native "*CSSFontFaceRule" {

  final _CSSStyleDeclarationImpl style;
}

class _CSSImportRuleImpl extends _CSSRuleImpl implements CSSImportRule native "*CSSImportRule" {

  final String href;

  final _MediaListImpl media;

  final _CSSStyleSheetImpl styleSheet;
}

class _CSSKeyframeRuleImpl extends _CSSRuleImpl implements CSSKeyframeRule native "*WebKitCSSKeyframeRule" {

  String keyText;

  final _CSSStyleDeclarationImpl style;
}

class _CSSKeyframesRuleImpl extends _CSSRuleImpl implements CSSKeyframesRule native "*WebKitCSSKeyframesRule" {

  final _CSSRuleListImpl cssRules;

  String name;

  void deleteRule(String key) native;

  _CSSKeyframeRuleImpl findRule(String key) native;

  void insertRule(String rule) native;
}

class _CSSMatrixImpl implements CSSMatrix native "*WebKitCSSMatrix" {

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

  num m11;

  num m12;

  num m13;

  num m14;

  num m21;

  num m22;

  num m23;

  num m24;

  num m31;

  num m32;

  num m33;

  num m34;

  num m41;

  num m42;

  num m43;

  num m44;

  _CSSMatrixImpl inverse() native;

  _CSSMatrixImpl multiply(_CSSMatrixImpl secondMatrix) native;

  _CSSMatrixImpl rotate(num rotX, num rotY, num rotZ) native;

  _CSSMatrixImpl rotateAxisAngle(num x, num y, num z, num angle) native;

  _CSSMatrixImpl scale(num scaleX, num scaleY, num scaleZ) native;

  void setMatrixValue(String string) native;

  _CSSMatrixImpl skewX(num angle) native;

  _CSSMatrixImpl skewY(num angle) native;

  String toString() native;

  _CSSMatrixImpl translate(num x, num y, num z) native;
}

class _CSSMediaRuleImpl extends _CSSRuleImpl implements CSSMediaRule native "*CSSMediaRule" {

  final _CSSRuleListImpl cssRules;

  final _MediaListImpl media;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

class _CSSPageRuleImpl extends _CSSRuleImpl implements CSSPageRule native "*CSSPageRule" {

  String selectorText;

  final _CSSStyleDeclarationImpl style;
}

class _CSSPrimitiveValueImpl extends _CSSValueImpl implements CSSPrimitiveValue native "*CSSPrimitiveValue" {

  static final int CSS_ATTR = 22;

  static final int CSS_CM = 6;

  static final int CSS_COUNTER = 23;

  static final int CSS_DEG = 11;

  static final int CSS_DIMENSION = 18;

  static final int CSS_EMS = 3;

  static final int CSS_EXS = 4;

  static final int CSS_GRAD = 13;

  static final int CSS_HZ = 16;

  static final int CSS_IDENT = 21;

  static final int CSS_IN = 8;

  static final int CSS_KHZ = 17;

  static final int CSS_MM = 7;

  static final int CSS_MS = 14;

  static final int CSS_NUMBER = 1;

  static final int CSS_PC = 10;

  static final int CSS_PERCENTAGE = 2;

  static final int CSS_PT = 9;

  static final int CSS_PX = 5;

  static final int CSS_RAD = 12;

  static final int CSS_RECT = 24;

  static final int CSS_RGBCOLOR = 25;

  static final int CSS_S = 15;

  static final int CSS_STRING = 19;

  static final int CSS_UNKNOWN = 0;

  static final int CSS_URI = 20;

  final int primitiveType;

  _CounterImpl getCounterValue() native;

  num getFloatValue(int unitType) native;

  _RGBColorImpl getRGBColorValue() native;

  _RectImpl getRectValue() native;

  String getStringValue() native;

  void setFloatValue(int unitType, num floatValue) native;

  void setStringValue(int stringType, String stringValue) native;
}

class _CSSRuleImpl implements CSSRule native "*CSSRule" {

  static final int CHARSET_RULE = 2;

  static final int FONT_FACE_RULE = 5;

  static final int IMPORT_RULE = 3;

  static final int MEDIA_RULE = 4;

  static final int PAGE_RULE = 6;

  static final int STYLE_RULE = 1;

  static final int UNKNOWN_RULE = 0;

  static final int WEBKIT_KEYFRAMES_RULE = 7;

  static final int WEBKIT_KEYFRAME_RULE = 8;

  static final int WEBKIT_REGION_RULE = 10;

  String cssText;

  final _CSSRuleImpl parentRule;

  final _CSSStyleSheetImpl parentStyleSheet;

  final int type;
}

class _CSSRuleListImpl implements CSSRuleList native "*CSSRuleList" {

  final int length;

  _CSSRuleImpl item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String _cachedBrowserPrefix;

String get _browserPrefix() {
  if (_cachedBrowserPrefix === null) {
    if (_Device.isFirefox) {
      _cachedBrowserPrefix = '-moz-';
    } else {
      _cachedBrowserPrefix = '-webkit-';
    }
    // TODO(jacobr): support IE 9.0 and Opera as well.
  }
  return _cachedBrowserPrefix;
}

class _CSSStyleDeclarationImpl implements CSSStyleDeclaration native "*CSSStyleDeclaration" {


  String cssText;

  final int length;

  final _CSSRuleImpl parentRule;

  _CSSValueImpl getPropertyCSSValue(String propertyName) native;

  String getPropertyPriority(String propertyName) native;

  String getPropertyShorthand(String propertyName) native;

  String getPropertyValue(String propertyName) native;

  bool isPropertyImplicit(String propertyName) native;

  String item(int index) native;

  String removeProperty(String propertyName) native;

  void setProperty(String propertyName, String value, [String priority = null]) native;


  // TODO(jacobr): generate this list of properties using the existing script.
    /** Gets the value of "animation" */
  String get animation() =>
    getPropertyValue('${_browserPrefix}animation');

  /** Sets the value of "animation" */
  void set animation(var value) {
    setProperty('${_browserPrefix}animation', value, '');
  }

  /** Gets the value of "animation-delay" */
  String get animationDelay() =>
    getPropertyValue('${_browserPrefix}animation-delay');

  /** Sets the value of "animation-delay" */
  void set animationDelay(var value) {
    setProperty('${_browserPrefix}animation-delay', value, '');
  }

  /** Gets the value of "animation-direction" */
  String get animationDirection() =>
    getPropertyValue('${_browserPrefix}animation-direction');

  /** Sets the value of "animation-direction" */
  void set animationDirection(var value) {
    setProperty('${_browserPrefix}animation-direction', value, '');
  }

  /** Gets the value of "animation-duration" */
  String get animationDuration() =>
    getPropertyValue('${_browserPrefix}animation-duration');

  /** Sets the value of "animation-duration" */
  void set animationDuration(var value) {
    setProperty('${_browserPrefix}animation-duration', value, '');
  }

  /** Gets the value of "animation-fill-mode" */
  String get animationFillMode() =>
    getPropertyValue('${_browserPrefix}animation-fill-mode');

  /** Sets the value of "animation-fill-mode" */
  void set animationFillMode(var value) {
    setProperty('${_browserPrefix}animation-fill-mode', value, '');
  }

  /** Gets the value of "animation-iteration-count" */
  String get animationIterationCount() =>
    getPropertyValue('${_browserPrefix}animation-iteration-count');

  /** Sets the value of "animation-iteration-count" */
  void set animationIterationCount(var value) {
    setProperty('${_browserPrefix}animation-iteration-count', value, '');
  }

  /** Gets the value of "animation-name" */
  String get animationName() =>
    getPropertyValue('${_browserPrefix}animation-name');

  /** Sets the value of "animation-name" */
  void set animationName(var value) {
    setProperty('${_browserPrefix}animation-name', value, '');
  }

  /** Gets the value of "animation-play-state" */
  String get animationPlayState() =>
    getPropertyValue('${_browserPrefix}animation-play-state');

  /** Sets the value of "animation-play-state" */
  void set animationPlayState(var value) {
    setProperty('${_browserPrefix}animation-play-state', value, '');
  }

  /** Gets the value of "animation-timing-function" */
  String get animationTimingFunction() =>
    getPropertyValue('${_browserPrefix}animation-timing-function');

  /** Sets the value of "animation-timing-function" */
  void set animationTimingFunction(var value) {
    setProperty('${_browserPrefix}animation-timing-function', value, '');
  }

  /** Gets the value of "appearance" */
  String get appearance() =>
    getPropertyValue('${_browserPrefix}appearance');

  /** Sets the value of "appearance" */
  void set appearance(var value) {
    setProperty('${_browserPrefix}appearance', value, '');
  }

  /** Gets the value of "backface-visibility" */
  String get backfaceVisibility() =>
    getPropertyValue('${_browserPrefix}backface-visibility');

  /** Sets the value of "backface-visibility" */
  void set backfaceVisibility(var value) {
    setProperty('${_browserPrefix}backface-visibility', value, '');
  }

  /** Gets the value of "background" */
  String get background() =>
    getPropertyValue('background');

  /** Sets the value of "background" */
  void set background(var value) {
    setProperty('background', value, '');
  }

  /** Gets the value of "background-attachment" */
  String get backgroundAttachment() =>
    getPropertyValue('background-attachment');

  /** Sets the value of "background-attachment" */
  void set backgroundAttachment(var value) {
    setProperty('background-attachment', value, '');
  }

  /** Gets the value of "background-clip" */
  String get backgroundClip() =>
    getPropertyValue('background-clip');

  /** Sets the value of "background-clip" */
  void set backgroundClip(var value) {
    setProperty('background-clip', value, '');
  }

  /** Gets the value of "background-color" */
  String get backgroundColor() =>
    getPropertyValue('background-color');

  /** Sets the value of "background-color" */
  void set backgroundColor(var value) {
    setProperty('background-color', value, '');
  }

  /** Gets the value of "background-composite" */
  String get backgroundComposite() =>
    getPropertyValue('${_browserPrefix}background-composite');

  /** Sets the value of "background-composite" */
  void set backgroundComposite(var value) {
    setProperty('${_browserPrefix}background-composite', value, '');
  }

  /** Gets the value of "background-image" */
  String get backgroundImage() =>
    getPropertyValue('background-image');

  /** Sets the value of "background-image" */
  void set backgroundImage(var value) {
    setProperty('background-image', value, '');
  }

  /** Gets the value of "background-origin" */
  String get backgroundOrigin() =>
    getPropertyValue('background-origin');

  /** Sets the value of "background-origin" */
  void set backgroundOrigin(var value) {
    setProperty('background-origin', value, '');
  }

  /** Gets the value of "background-position" */
  String get backgroundPosition() =>
    getPropertyValue('background-position');

  /** Sets the value of "background-position" */
  void set backgroundPosition(var value) {
    setProperty('background-position', value, '');
  }

  /** Gets the value of "background-position-x" */
  String get backgroundPositionX() =>
    getPropertyValue('background-position-x');

  /** Sets the value of "background-position-x" */
  void set backgroundPositionX(var value) {
    setProperty('background-position-x', value, '');
  }

  /** Gets the value of "background-position-y" */
  String get backgroundPositionY() =>
    getPropertyValue('background-position-y');

  /** Sets the value of "background-position-y" */
  void set backgroundPositionY(var value) {
    setProperty('background-position-y', value, '');
  }

  /** Gets the value of "background-repeat" */
  String get backgroundRepeat() =>
    getPropertyValue('background-repeat');

  /** Sets the value of "background-repeat" */
  void set backgroundRepeat(var value) {
    setProperty('background-repeat', value, '');
  }

  /** Gets the value of "background-repeat-x" */
  String get backgroundRepeatX() =>
    getPropertyValue('background-repeat-x');

  /** Sets the value of "background-repeat-x" */
  void set backgroundRepeatX(var value) {
    setProperty('background-repeat-x', value, '');
  }

  /** Gets the value of "background-repeat-y" */
  String get backgroundRepeatY() =>
    getPropertyValue('background-repeat-y');

  /** Sets the value of "background-repeat-y" */
  void set backgroundRepeatY(var value) {
    setProperty('background-repeat-y', value, '');
  }

  /** Gets the value of "background-size" */
  String get backgroundSize() =>
    getPropertyValue('background-size');

  /** Sets the value of "background-size" */
  void set backgroundSize(var value) {
    setProperty('background-size', value, '');
  }

  /** Gets the value of "border" */
  String get border() =>
    getPropertyValue('border');

  /** Sets the value of "border" */
  void set border(var value) {
    setProperty('border', value, '');
  }

  /** Gets the value of "border-after" */
  String get borderAfter() =>
    getPropertyValue('${_browserPrefix}border-after');

  /** Sets the value of "border-after" */
  void set borderAfter(var value) {
    setProperty('${_browserPrefix}border-after', value, '');
  }

  /** Gets the value of "border-after-color" */
  String get borderAfterColor() =>
    getPropertyValue('${_browserPrefix}border-after-color');

  /** Sets the value of "border-after-color" */
  void set borderAfterColor(var value) {
    setProperty('${_browserPrefix}border-after-color', value, '');
  }

  /** Gets the value of "border-after-style" */
  String get borderAfterStyle() =>
    getPropertyValue('${_browserPrefix}border-after-style');

  /** Sets the value of "border-after-style" */
  void set borderAfterStyle(var value) {
    setProperty('${_browserPrefix}border-after-style', value, '');
  }

  /** Gets the value of "border-after-width" */
  String get borderAfterWidth() =>
    getPropertyValue('${_browserPrefix}border-after-width');

  /** Sets the value of "border-after-width" */
  void set borderAfterWidth(var value) {
    setProperty('${_browserPrefix}border-after-width', value, '');
  }

  /** Gets the value of "border-before" */
  String get borderBefore() =>
    getPropertyValue('${_browserPrefix}border-before');

  /** Sets the value of "border-before" */
  void set borderBefore(var value) {
    setProperty('${_browserPrefix}border-before', value, '');
  }

  /** Gets the value of "border-before-color" */
  String get borderBeforeColor() =>
    getPropertyValue('${_browserPrefix}border-before-color');

  /** Sets the value of "border-before-color" */
  void set borderBeforeColor(var value) {
    setProperty('${_browserPrefix}border-before-color', value, '');
  }

  /** Gets the value of "border-before-style" */
  String get borderBeforeStyle() =>
    getPropertyValue('${_browserPrefix}border-before-style');

  /** Sets the value of "border-before-style" */
  void set borderBeforeStyle(var value) {
    setProperty('${_browserPrefix}border-before-style', value, '');
  }

  /** Gets the value of "border-before-width" */
  String get borderBeforeWidth() =>
    getPropertyValue('${_browserPrefix}border-before-width');

  /** Sets the value of "border-before-width" */
  void set borderBeforeWidth(var value) {
    setProperty('${_browserPrefix}border-before-width', value, '');
  }

  /** Gets the value of "border-bottom" */
  String get borderBottom() =>
    getPropertyValue('border-bottom');

  /** Sets the value of "border-bottom" */
  void set borderBottom(var value) {
    setProperty('border-bottom', value, '');
  }

  /** Gets the value of "border-bottom-color" */
  String get borderBottomColor() =>
    getPropertyValue('border-bottom-color');

  /** Sets the value of "border-bottom-color" */
  void set borderBottomColor(var value) {
    setProperty('border-bottom-color', value, '');
  }

  /** Gets the value of "border-bottom-left-radius" */
  String get borderBottomLeftRadius() =>
    getPropertyValue('border-bottom-left-radius');

  /** Sets the value of "border-bottom-left-radius" */
  void set borderBottomLeftRadius(var value) {
    setProperty('border-bottom-left-radius', value, '');
  }

  /** Gets the value of "border-bottom-right-radius" */
  String get borderBottomRightRadius() =>
    getPropertyValue('border-bottom-right-radius');

  /** Sets the value of "border-bottom-right-radius" */
  void set borderBottomRightRadius(var value) {
    setProperty('border-bottom-right-radius', value, '');
  }

  /** Gets the value of "border-bottom-style" */
  String get borderBottomStyle() =>
    getPropertyValue('border-bottom-style');

  /** Sets the value of "border-bottom-style" */
  void set borderBottomStyle(var value) {
    setProperty('border-bottom-style', value, '');
  }

  /** Gets the value of "border-bottom-width" */
  String get borderBottomWidth() =>
    getPropertyValue('border-bottom-width');

  /** Sets the value of "border-bottom-width" */
  void set borderBottomWidth(var value) {
    setProperty('border-bottom-width', value, '');
  }

  /** Gets the value of "border-collapse" */
  String get borderCollapse() =>
    getPropertyValue('border-collapse');

  /** Sets the value of "border-collapse" */
  void set borderCollapse(var value) {
    setProperty('border-collapse', value, '');
  }

  /** Gets the value of "border-color" */
  String get borderColor() =>
    getPropertyValue('border-color');

  /** Sets the value of "border-color" */
  void set borderColor(var value) {
    setProperty('border-color', value, '');
  }

  /** Gets the value of "border-end" */
  String get borderEnd() =>
    getPropertyValue('${_browserPrefix}border-end');

  /** Sets the value of "border-end" */
  void set borderEnd(var value) {
    setProperty('${_browserPrefix}border-end', value, '');
  }

  /** Gets the value of "border-end-color" */
  String get borderEndColor() =>
    getPropertyValue('${_browserPrefix}border-end-color');

  /** Sets the value of "border-end-color" */
  void set borderEndColor(var value) {
    setProperty('${_browserPrefix}border-end-color', value, '');
  }

  /** Gets the value of "border-end-style" */
  String get borderEndStyle() =>
    getPropertyValue('${_browserPrefix}border-end-style');

  /** Sets the value of "border-end-style" */
  void set borderEndStyle(var value) {
    setProperty('${_browserPrefix}border-end-style', value, '');
  }

  /** Gets the value of "border-end-width" */
  String get borderEndWidth() =>
    getPropertyValue('${_browserPrefix}border-end-width');

  /** Sets the value of "border-end-width" */
  void set borderEndWidth(var value) {
    setProperty('${_browserPrefix}border-end-width', value, '');
  }

  /** Gets the value of "border-fit" */
  String get borderFit() =>
    getPropertyValue('${_browserPrefix}border-fit');

  /** Sets the value of "border-fit" */
  void set borderFit(var value) {
    setProperty('${_browserPrefix}border-fit', value, '');
  }

  /** Gets the value of "border-horizontal-spacing" */
  String get borderHorizontalSpacing() =>
    getPropertyValue('${_browserPrefix}border-horizontal-spacing');

  /** Sets the value of "border-horizontal-spacing" */
  void set borderHorizontalSpacing(var value) {
    setProperty('${_browserPrefix}border-horizontal-spacing', value, '');
  }

  /** Gets the value of "border-image" */
  String get borderImage() =>
    getPropertyValue('border-image');

  /** Sets the value of "border-image" */
  void set borderImage(var value) {
    setProperty('border-image', value, '');
  }

  /** Gets the value of "border-image-outset" */
  String get borderImageOutset() =>
    getPropertyValue('border-image-outset');

  /** Sets the value of "border-image-outset" */
  void set borderImageOutset(var value) {
    setProperty('border-image-outset', value, '');
  }

  /** Gets the value of "border-image-repeat" */
  String get borderImageRepeat() =>
    getPropertyValue('border-image-repeat');

  /** Sets the value of "border-image-repeat" */
  void set borderImageRepeat(var value) {
    setProperty('border-image-repeat', value, '');
  }

  /** Gets the value of "border-image-slice" */
  String get borderImageSlice() =>
    getPropertyValue('border-image-slice');

  /** Sets the value of "border-image-slice" */
  void set borderImageSlice(var value) {
    setProperty('border-image-slice', value, '');
  }

  /** Gets the value of "border-image-source" */
  String get borderImageSource() =>
    getPropertyValue('border-image-source');

  /** Sets the value of "border-image-source" */
  void set borderImageSource(var value) {
    setProperty('border-image-source', value, '');
  }

  /** Gets the value of "border-image-width" */
  String get borderImageWidth() =>
    getPropertyValue('border-image-width');

  /** Sets the value of "border-image-width" */
  void set borderImageWidth(var value) {
    setProperty('border-image-width', value, '');
  }

  /** Gets the value of "border-left" */
  String get borderLeft() =>
    getPropertyValue('border-left');

  /** Sets the value of "border-left" */
  void set borderLeft(var value) {
    setProperty('border-left', value, '');
  }

  /** Gets the value of "border-left-color" */
  String get borderLeftColor() =>
    getPropertyValue('border-left-color');

  /** Sets the value of "border-left-color" */
  void set borderLeftColor(var value) {
    setProperty('border-left-color', value, '');
  }

  /** Gets the value of "border-left-style" */
  String get borderLeftStyle() =>
    getPropertyValue('border-left-style');

  /** Sets the value of "border-left-style" */
  void set borderLeftStyle(var value) {
    setProperty('border-left-style', value, '');
  }

  /** Gets the value of "border-left-width" */
  String get borderLeftWidth() =>
    getPropertyValue('border-left-width');

  /** Sets the value of "border-left-width" */
  void set borderLeftWidth(var value) {
    setProperty('border-left-width', value, '');
  }

  /** Gets the value of "border-radius" */
  String get borderRadius() =>
    getPropertyValue('border-radius');

  /** Sets the value of "border-radius" */
  void set borderRadius(var value) {
    setProperty('border-radius', value, '');
  }

  /** Gets the value of "border-right" */
  String get borderRight() =>
    getPropertyValue('border-right');

  /** Sets the value of "border-right" */
  void set borderRight(var value) {
    setProperty('border-right', value, '');
  }

  /** Gets the value of "border-right-color" */
  String get borderRightColor() =>
    getPropertyValue('border-right-color');

  /** Sets the value of "border-right-color" */
  void set borderRightColor(var value) {
    setProperty('border-right-color', value, '');
  }

  /** Gets the value of "border-right-style" */
  String get borderRightStyle() =>
    getPropertyValue('border-right-style');

  /** Sets the value of "border-right-style" */
  void set borderRightStyle(var value) {
    setProperty('border-right-style', value, '');
  }

  /** Gets the value of "border-right-width" */
  String get borderRightWidth() =>
    getPropertyValue('border-right-width');

  /** Sets the value of "border-right-width" */
  void set borderRightWidth(var value) {
    setProperty('border-right-width', value, '');
  }

  /** Gets the value of "border-spacing" */
  String get borderSpacing() =>
    getPropertyValue('border-spacing');

  /** Sets the value of "border-spacing" */
  void set borderSpacing(var value) {
    setProperty('border-spacing', value, '');
  }

  /** Gets the value of "border-start" */
  String get borderStart() =>
    getPropertyValue('${_browserPrefix}border-start');

  /** Sets the value of "border-start" */
  void set borderStart(var value) {
    setProperty('${_browserPrefix}border-start', value, '');
  }

  /** Gets the value of "border-start-color" */
  String get borderStartColor() =>
    getPropertyValue('${_browserPrefix}border-start-color');

  /** Sets the value of "border-start-color" */
  void set borderStartColor(var value) {
    setProperty('${_browserPrefix}border-start-color', value, '');
  }

  /** Gets the value of "border-start-style" */
  String get borderStartStyle() =>
    getPropertyValue('${_browserPrefix}border-start-style');

  /** Sets the value of "border-start-style" */
  void set borderStartStyle(var value) {
    setProperty('${_browserPrefix}border-start-style', value, '');
  }

  /** Gets the value of "border-start-width" */
  String get borderStartWidth() =>
    getPropertyValue('${_browserPrefix}border-start-width');

  /** Sets the value of "border-start-width" */
  void set borderStartWidth(var value) {
    setProperty('${_browserPrefix}border-start-width', value, '');
  }

  /** Gets the value of "border-style" */
  String get borderStyle() =>
    getPropertyValue('border-style');

  /** Sets the value of "border-style" */
  void set borderStyle(var value) {
    setProperty('border-style', value, '');
  }

  /** Gets the value of "border-top" */
  String get borderTop() =>
    getPropertyValue('border-top');

  /** Sets the value of "border-top" */
  void set borderTop(var value) {
    setProperty('border-top', value, '');
  }

  /** Gets the value of "border-top-color" */
  String get borderTopColor() =>
    getPropertyValue('border-top-color');

  /** Sets the value of "border-top-color" */
  void set borderTopColor(var value) {
    setProperty('border-top-color', value, '');
  }

  /** Gets the value of "border-top-left-radius" */
  String get borderTopLeftRadius() =>
    getPropertyValue('border-top-left-radius');

  /** Sets the value of "border-top-left-radius" */
  void set borderTopLeftRadius(var value) {
    setProperty('border-top-left-radius', value, '');
  }

  /** Gets the value of "border-top-right-radius" */
  String get borderTopRightRadius() =>
    getPropertyValue('border-top-right-radius');

  /** Sets the value of "border-top-right-radius" */
  void set borderTopRightRadius(var value) {
    setProperty('border-top-right-radius', value, '');
  }

  /** Gets the value of "border-top-style" */
  String get borderTopStyle() =>
    getPropertyValue('border-top-style');

  /** Sets the value of "border-top-style" */
  void set borderTopStyle(var value) {
    setProperty('border-top-style', value, '');
  }

  /** Gets the value of "border-top-width" */
  String get borderTopWidth() =>
    getPropertyValue('border-top-width');

  /** Sets the value of "border-top-width" */
  void set borderTopWidth(var value) {
    setProperty('border-top-width', value, '');
  }

  /** Gets the value of "border-vertical-spacing" */
  String get borderVerticalSpacing() =>
    getPropertyValue('${_browserPrefix}border-vertical-spacing');

  /** Sets the value of "border-vertical-spacing" */
  void set borderVerticalSpacing(var value) {
    setProperty('${_browserPrefix}border-vertical-spacing', value, '');
  }

  /** Gets the value of "border-width" */
  String get borderWidth() =>
    getPropertyValue('border-width');

  /** Sets the value of "border-width" */
  void set borderWidth(var value) {
    setProperty('border-width', value, '');
  }

  /** Gets the value of "bottom" */
  String get bottom() =>
    getPropertyValue('bottom');

  /** Sets the value of "bottom" */
  void set bottom(var value) {
    setProperty('bottom', value, '');
  }

  /** Gets the value of "box-align" */
  String get boxAlign() =>
    getPropertyValue('${_browserPrefix}box-align');

  /** Sets the value of "box-align" */
  void set boxAlign(var value) {
    setProperty('${_browserPrefix}box-align', value, '');
  }

  /** Gets the value of "box-direction" */
  String get boxDirection() =>
    getPropertyValue('${_browserPrefix}box-direction');

  /** Sets the value of "box-direction" */
  void set boxDirection(var value) {
    setProperty('${_browserPrefix}box-direction', value, '');
  }

  /** Gets the value of "box-flex" */
  String get boxFlex() =>
    getPropertyValue('${_browserPrefix}box-flex');

  /** Sets the value of "box-flex" */
  void set boxFlex(var value) {
    setProperty('${_browserPrefix}box-flex', value, '');
  }

  /** Gets the value of "box-flex-group" */
  String get boxFlexGroup() =>
    getPropertyValue('${_browserPrefix}box-flex-group');

  /** Sets the value of "box-flex-group" */
  void set boxFlexGroup(var value) {
    setProperty('${_browserPrefix}box-flex-group', value, '');
  }

  /** Gets the value of "box-lines" */
  String get boxLines() =>
    getPropertyValue('${_browserPrefix}box-lines');

  /** Sets the value of "box-lines" */
  void set boxLines(var value) {
    setProperty('${_browserPrefix}box-lines', value, '');
  }

  /** Gets the value of "box-ordinal-group" */
  String get boxOrdinalGroup() =>
    getPropertyValue('${_browserPrefix}box-ordinal-group');

  /** Sets the value of "box-ordinal-group" */
  void set boxOrdinalGroup(var value) {
    setProperty('${_browserPrefix}box-ordinal-group', value, '');
  }

  /** Gets the value of "box-orient" */
  String get boxOrient() =>
    getPropertyValue('${_browserPrefix}box-orient');

  /** Sets the value of "box-orient" */
  void set boxOrient(var value) {
    setProperty('${_browserPrefix}box-orient', value, '');
  }

  /** Gets the value of "box-pack" */
  String get boxPack() =>
    getPropertyValue('${_browserPrefix}box-pack');

  /** Sets the value of "box-pack" */
  void set boxPack(var value) {
    setProperty('${_browserPrefix}box-pack', value, '');
  }

  /** Gets the value of "box-reflect" */
  String get boxReflect() =>
    getPropertyValue('${_browserPrefix}box-reflect');

  /** Sets the value of "box-reflect" */
  void set boxReflect(var value) {
    setProperty('${_browserPrefix}box-reflect', value, '');
  }

  /** Gets the value of "box-shadow" */
  String get boxShadow() =>
    getPropertyValue('box-shadow');

  /** Sets the value of "box-shadow" */
  void set boxShadow(var value) {
    setProperty('box-shadow', value, '');
  }

  /** Gets the value of "box-sizing" */
  String get boxSizing() =>
    getPropertyValue('box-sizing');

  /** Sets the value of "box-sizing" */
  void set boxSizing(var value) {
    setProperty('box-sizing', value, '');
  }

  /** Gets the value of "caption-side" */
  String get captionSide() =>
    getPropertyValue('caption-side');

  /** Sets the value of "caption-side" */
  void set captionSide(var value) {
    setProperty('caption-side', value, '');
  }

  /** Gets the value of "clear" */
  String get clear() =>
    getPropertyValue('clear');

  /** Sets the value of "clear" */
  void set clear(var value) {
    setProperty('clear', value, '');
  }

  /** Gets the value of "clip" */
  String get clip() =>
    getPropertyValue('clip');

  /** Sets the value of "clip" */
  void set clip(var value) {
    setProperty('clip', value, '');
  }

  /** Gets the value of "color" */
  String get color() =>
    getPropertyValue('color');

  /** Sets the value of "color" */
  void set color(var value) {
    setProperty('color', value, '');
  }

  /** Gets the value of "color-correction" */
  String get colorCorrection() =>
    getPropertyValue('${_browserPrefix}color-correction');

  /** Sets the value of "color-correction" */
  void set colorCorrection(var value) {
    setProperty('${_browserPrefix}color-correction', value, '');
  }

  /** Gets the value of "column-break-after" */
  String get columnBreakAfter() =>
    getPropertyValue('${_browserPrefix}column-break-after');

  /** Sets the value of "column-break-after" */
  void set columnBreakAfter(var value) {
    setProperty('${_browserPrefix}column-break-after', value, '');
  }

  /** Gets the value of "column-break-before" */
  String get columnBreakBefore() =>
    getPropertyValue('${_browserPrefix}column-break-before');

  /** Sets the value of "column-break-before" */
  void set columnBreakBefore(var value) {
    setProperty('${_browserPrefix}column-break-before', value, '');
  }

  /** Gets the value of "column-break-inside" */
  String get columnBreakInside() =>
    getPropertyValue('${_browserPrefix}column-break-inside');

  /** Sets the value of "column-break-inside" */
  void set columnBreakInside(var value) {
    setProperty('${_browserPrefix}column-break-inside', value, '');
  }

  /** Gets the value of "column-count" */
  String get columnCount() =>
    getPropertyValue('${_browserPrefix}column-count');

  /** Sets the value of "column-count" */
  void set columnCount(var value) {
    setProperty('${_browserPrefix}column-count', value, '');
  }

  /** Gets the value of "column-gap" */
  String get columnGap() =>
    getPropertyValue('${_browserPrefix}column-gap');

  /** Sets the value of "column-gap" */
  void set columnGap(var value) {
    setProperty('${_browserPrefix}column-gap', value, '');
  }

  /** Gets the value of "column-rule" */
  String get columnRule() =>
    getPropertyValue('${_browserPrefix}column-rule');

  /** Sets the value of "column-rule" */
  void set columnRule(var value) {
    setProperty('${_browserPrefix}column-rule', value, '');
  }

  /** Gets the value of "column-rule-color" */
  String get columnRuleColor() =>
    getPropertyValue('${_browserPrefix}column-rule-color');

  /** Sets the value of "column-rule-color" */
  void set columnRuleColor(var value) {
    setProperty('${_browserPrefix}column-rule-color', value, '');
  }

  /** Gets the value of "column-rule-style" */
  String get columnRuleStyle() =>
    getPropertyValue('${_browserPrefix}column-rule-style');

  /** Sets the value of "column-rule-style" */
  void set columnRuleStyle(var value) {
    setProperty('${_browserPrefix}column-rule-style', value, '');
  }

  /** Gets the value of "column-rule-width" */
  String get columnRuleWidth() =>
    getPropertyValue('${_browserPrefix}column-rule-width');

  /** Sets the value of "column-rule-width" */
  void set columnRuleWidth(var value) {
    setProperty('${_browserPrefix}column-rule-width', value, '');
  }

  /** Gets the value of "column-span" */
  String get columnSpan() =>
    getPropertyValue('${_browserPrefix}column-span');

  /** Sets the value of "column-span" */
  void set columnSpan(var value) {
    setProperty('${_browserPrefix}column-span', value, '');
  }

  /** Gets the value of "column-width" */
  String get columnWidth() =>
    getPropertyValue('${_browserPrefix}column-width');

  /** Sets the value of "column-width" */
  void set columnWidth(var value) {
    setProperty('${_browserPrefix}column-width', value, '');
  }

  /** Gets the value of "columns" */
  String get columns() =>
    getPropertyValue('${_browserPrefix}columns');

  /** Sets the value of "columns" */
  void set columns(var value) {
    setProperty('${_browserPrefix}columns', value, '');
  }

  /** Gets the value of "content" */
  String get content() =>
    getPropertyValue('content');

  /** Sets the value of "content" */
  void set content(var value) {
    setProperty('content', value, '');
  }

  /** Gets the value of "counter-increment" */
  String get counterIncrement() =>
    getPropertyValue('counter-increment');

  /** Sets the value of "counter-increment" */
  void set counterIncrement(var value) {
    setProperty('counter-increment', value, '');
  }

  /** Gets the value of "counter-reset" */
  String get counterReset() =>
    getPropertyValue('counter-reset');

  /** Sets the value of "counter-reset" */
  void set counterReset(var value) {
    setProperty('counter-reset', value, '');
  }

  /** Gets the value of "cursor" */
  String get cursor() =>
    getPropertyValue('cursor');

  /** Sets the value of "cursor" */
  void set cursor(var value) {
    setProperty('cursor', value, '');
  }

  /** Gets the value of "direction" */
  String get direction() =>
    getPropertyValue('direction');

  /** Sets the value of "direction" */
  void set direction(var value) {
    setProperty('direction', value, '');
  }

  /** Gets the value of "display" */
  String get display() =>
    getPropertyValue('display');

  /** Sets the value of "display" */
  void set display(var value) {
    setProperty('display', value, '');
  }

  /** Gets the value of "empty-cells" */
  String get emptyCells() =>
    getPropertyValue('empty-cells');

  /** Sets the value of "empty-cells" */
  void set emptyCells(var value) {
    setProperty('empty-cells', value, '');
  }

  /** Gets the value of "filter" */
  String get filter() =>
    getPropertyValue('${_browserPrefix}filter');

  /** Sets the value of "filter" */
  void set filter(var value) {
    setProperty('${_browserPrefix}filter', value, '');
  }

  /** Gets the value of "flex-align" */
  String get flexAlign() =>
    getPropertyValue('${_browserPrefix}flex-align');

  /** Sets the value of "flex-align" */
  void set flexAlign(var value) {
    setProperty('${_browserPrefix}flex-align', value, '');
  }

  /** Gets the value of "flex-flow" */
  String get flexFlow() =>
    getPropertyValue('${_browserPrefix}flex-flow');

  /** Sets the value of "flex-flow" */
  void set flexFlow(var value) {
    setProperty('${_browserPrefix}flex-flow', value, '');
  }

  /** Gets the value of "flex-order" */
  String get flexOrder() =>
    getPropertyValue('${_browserPrefix}flex-order');

  /** Sets the value of "flex-order" */
  void set flexOrder(var value) {
    setProperty('${_browserPrefix}flex-order', value, '');
  }

  /** Gets the value of "flex-pack" */
  String get flexPack() =>
    getPropertyValue('${_browserPrefix}flex-pack');

  /** Sets the value of "flex-pack" */
  void set flexPack(var value) {
    setProperty('${_browserPrefix}flex-pack', value, '');
  }

  /** Gets the value of "float" */
  String get float() =>
    getPropertyValue('float');

  /** Sets the value of "float" */
  void set float(var value) {
    setProperty('float', value, '');
  }

  /** Gets the value of "flow-from" */
  String get flowFrom() =>
    getPropertyValue('${_browserPrefix}flow-from');

  /** Sets the value of "flow-from" */
  void set flowFrom(var value) {
    setProperty('${_browserPrefix}flow-from', value, '');
  }

  /** Gets the value of "flow-into" */
  String get flowInto() =>
    getPropertyValue('${_browserPrefix}flow-into');

  /** Sets the value of "flow-into" */
  void set flowInto(var value) {
    setProperty('${_browserPrefix}flow-into', value, '');
  }

  /** Gets the value of "font" */
  String get font() =>
    getPropertyValue('font');

  /** Sets the value of "font" */
  void set font(var value) {
    setProperty('font', value, '');
  }

  /** Gets the value of "font-family" */
  String get fontFamily() =>
    getPropertyValue('font-family');

  /** Sets the value of "font-family" */
  void set fontFamily(var value) {
    setProperty('font-family', value, '');
  }

  /** Gets the value of "font-feature-settings" */
  String get fontFeatureSettings() =>
    getPropertyValue('${_browserPrefix}font-feature-settings');

  /** Sets the value of "font-feature-settings" */
  void set fontFeatureSettings(var value) {
    setProperty('${_browserPrefix}font-feature-settings', value, '');
  }

  /** Gets the value of "font-size" */
  String get fontSize() =>
    getPropertyValue('font-size');

  /** Sets the value of "font-size" */
  void set fontSize(var value) {
    setProperty('font-size', value, '');
  }

  /** Gets the value of "font-size-delta" */
  String get fontSizeDelta() =>
    getPropertyValue('${_browserPrefix}font-size-delta');

  /** Sets the value of "font-size-delta" */
  void set fontSizeDelta(var value) {
    setProperty('${_browserPrefix}font-size-delta', value, '');
  }

  /** Gets the value of "font-smoothing" */
  String get fontSmoothing() =>
    getPropertyValue('${_browserPrefix}font-smoothing');

  /** Sets the value of "font-smoothing" */
  void set fontSmoothing(var value) {
    setProperty('${_browserPrefix}font-smoothing', value, '');
  }

  /** Gets the value of "font-stretch" */
  String get fontStretch() =>
    getPropertyValue('font-stretch');

  /** Sets the value of "font-stretch" */
  void set fontStretch(var value) {
    setProperty('font-stretch', value, '');
  }

  /** Gets the value of "font-style" */
  String get fontStyle() =>
    getPropertyValue('font-style');

  /** Sets the value of "font-style" */
  void set fontStyle(var value) {
    setProperty('font-style', value, '');
  }

  /** Gets the value of "font-variant" */
  String get fontVariant() =>
    getPropertyValue('font-variant');

  /** Sets the value of "font-variant" */
  void set fontVariant(var value) {
    setProperty('font-variant', value, '');
  }

  /** Gets the value of "font-weight" */
  String get fontWeight() =>
    getPropertyValue('font-weight');

  /** Sets the value of "font-weight" */
  void set fontWeight(var value) {
    setProperty('font-weight', value, '');
  }

  /** Gets the value of "height" */
  String get height() =>
    getPropertyValue('height');

  /** Sets the value of "height" */
  void set height(var value) {
    setProperty('height', value, '');
  }

  /** Gets the value of "highlight" */
  String get highlight() =>
    getPropertyValue('${_browserPrefix}highlight');

  /** Sets the value of "highlight" */
  void set highlight(var value) {
    setProperty('${_browserPrefix}highlight', value, '');
  }

  /** Gets the value of "hyphenate-character" */
  String get hyphenateCharacter() =>
    getPropertyValue('${_browserPrefix}hyphenate-character');

  /** Sets the value of "hyphenate-character" */
  void set hyphenateCharacter(var value) {
    setProperty('${_browserPrefix}hyphenate-character', value, '');
  }

  /** Gets the value of "hyphenate-limit-after" */
  String get hyphenateLimitAfter() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-after');

  /** Sets the value of "hyphenate-limit-after" */
  void set hyphenateLimitAfter(var value) {
    setProperty('${_browserPrefix}hyphenate-limit-after', value, '');
  }

  /** Gets the value of "hyphenate-limit-before" */
  String get hyphenateLimitBefore() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-before');

  /** Sets the value of "hyphenate-limit-before" */
  void set hyphenateLimitBefore(var value) {
    setProperty('${_browserPrefix}hyphenate-limit-before', value, '');
  }

  /** Gets the value of "hyphenate-limit-lines" */
  String get hyphenateLimitLines() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-lines');

  /** Sets the value of "hyphenate-limit-lines" */
  void set hyphenateLimitLines(var value) {
    setProperty('${_browserPrefix}hyphenate-limit-lines', value, '');
  }

  /** Gets the value of "hyphens" */
  String get hyphens() =>
    getPropertyValue('${_browserPrefix}hyphens');

  /** Sets the value of "hyphens" */
  void set hyphens(var value) {
    setProperty('${_browserPrefix}hyphens', value, '');
  }

  /** Gets the value of "image-rendering" */
  String get imageRendering() =>
    getPropertyValue('image-rendering');

  /** Sets the value of "image-rendering" */
  void set imageRendering(var value) {
    setProperty('image-rendering', value, '');
  }

  /** Gets the value of "left" */
  String get left() =>
    getPropertyValue('left');

  /** Sets the value of "left" */
  void set left(var value) {
    setProperty('left', value, '');
  }

  /** Gets the value of "letter-spacing" */
  String get letterSpacing() =>
    getPropertyValue('letter-spacing');

  /** Sets the value of "letter-spacing" */
  void set letterSpacing(var value) {
    setProperty('letter-spacing', value, '');
  }

  /** Gets the value of "line-box-contain" */
  String get lineBoxContain() =>
    getPropertyValue('${_browserPrefix}line-box-contain');

  /** Sets the value of "line-box-contain" */
  void set lineBoxContain(var value) {
    setProperty('${_browserPrefix}line-box-contain', value, '');
  }

  /** Gets the value of "line-break" */
  String get lineBreak() =>
    getPropertyValue('${_browserPrefix}line-break');

  /** Sets the value of "line-break" */
  void set lineBreak(var value) {
    setProperty('${_browserPrefix}line-break', value, '');
  }

  /** Gets the value of "line-clamp" */
  String get lineClamp() =>
    getPropertyValue('${_browserPrefix}line-clamp');

  /** Sets the value of "line-clamp" */
  void set lineClamp(var value) {
    setProperty('${_browserPrefix}line-clamp', value, '');
  }

  /** Gets the value of "line-height" */
  String get lineHeight() =>
    getPropertyValue('line-height');

  /** Sets the value of "line-height" */
  void set lineHeight(var value) {
    setProperty('line-height', value, '');
  }

  /** Gets the value of "list-style" */
  String get listStyle() =>
    getPropertyValue('list-style');

  /** Sets the value of "list-style" */
  void set listStyle(var value) {
    setProperty('list-style', value, '');
  }

  /** Gets the value of "list-style-image" */
  String get listStyleImage() =>
    getPropertyValue('list-style-image');

  /** Sets the value of "list-style-image" */
  void set listStyleImage(var value) {
    setProperty('list-style-image', value, '');
  }

  /** Gets the value of "list-style-position" */
  String get listStylePosition() =>
    getPropertyValue('list-style-position');

  /** Sets the value of "list-style-position" */
  void set listStylePosition(var value) {
    setProperty('list-style-position', value, '');
  }

  /** Gets the value of "list-style-type" */
  String get listStyleType() =>
    getPropertyValue('list-style-type');

  /** Sets the value of "list-style-type" */
  void set listStyleType(var value) {
    setProperty('list-style-type', value, '');
  }

  /** Gets the value of "locale" */
  String get locale() =>
    getPropertyValue('${_browserPrefix}locale');

  /** Sets the value of "locale" */
  void set locale(var value) {
    setProperty('${_browserPrefix}locale', value, '');
  }

  /** Gets the value of "logical-height" */
  String get logicalHeight() =>
    getPropertyValue('${_browserPrefix}logical-height');

  /** Sets the value of "logical-height" */
  void set logicalHeight(var value) {
    setProperty('${_browserPrefix}logical-height', value, '');
  }

  /** Gets the value of "logical-width" */
  String get logicalWidth() =>
    getPropertyValue('${_browserPrefix}logical-width');

  /** Sets the value of "logical-width" */
  void set logicalWidth(var value) {
    setProperty('${_browserPrefix}logical-width', value, '');
  }

  /** Gets the value of "margin" */
  String get margin() =>
    getPropertyValue('margin');

  /** Sets the value of "margin" */
  void set margin(var value) {
    setProperty('margin', value, '');
  }

  /** Gets the value of "margin-after" */
  String get marginAfter() =>
    getPropertyValue('${_browserPrefix}margin-after');

  /** Sets the value of "margin-after" */
  void set marginAfter(var value) {
    setProperty('${_browserPrefix}margin-after', value, '');
  }

  /** Gets the value of "margin-after-collapse" */
  String get marginAfterCollapse() =>
    getPropertyValue('${_browserPrefix}margin-after-collapse');

  /** Sets the value of "margin-after-collapse" */
  void set marginAfterCollapse(var value) {
    setProperty('${_browserPrefix}margin-after-collapse', value, '');
  }

  /** Gets the value of "margin-before" */
  String get marginBefore() =>
    getPropertyValue('${_browserPrefix}margin-before');

  /** Sets the value of "margin-before" */
  void set marginBefore(var value) {
    setProperty('${_browserPrefix}margin-before', value, '');
  }

  /** Gets the value of "margin-before-collapse" */
  String get marginBeforeCollapse() =>
    getPropertyValue('${_browserPrefix}margin-before-collapse');

  /** Sets the value of "margin-before-collapse" */
  void set marginBeforeCollapse(var value) {
    setProperty('${_browserPrefix}margin-before-collapse', value, '');
  }

  /** Gets the value of "margin-bottom" */
  String get marginBottom() =>
    getPropertyValue('margin-bottom');

  /** Sets the value of "margin-bottom" */
  void set marginBottom(var value) {
    setProperty('margin-bottom', value, '');
  }

  /** Gets the value of "margin-bottom-collapse" */
  String get marginBottomCollapse() =>
    getPropertyValue('${_browserPrefix}margin-bottom-collapse');

  /** Sets the value of "margin-bottom-collapse" */
  void set marginBottomCollapse(var value) {
    setProperty('${_browserPrefix}margin-bottom-collapse', value, '');
  }

  /** Gets the value of "margin-collapse" */
  String get marginCollapse() =>
    getPropertyValue('${_browserPrefix}margin-collapse');

  /** Sets the value of "margin-collapse" */
  void set marginCollapse(var value) {
    setProperty('${_browserPrefix}margin-collapse', value, '');
  }

  /** Gets the value of "margin-end" */
  String get marginEnd() =>
    getPropertyValue('${_browserPrefix}margin-end');

  /** Sets the value of "margin-end" */
  void set marginEnd(var value) {
    setProperty('${_browserPrefix}margin-end', value, '');
  }

  /** Gets the value of "margin-left" */
  String get marginLeft() =>
    getPropertyValue('margin-left');

  /** Sets the value of "margin-left" */
  void set marginLeft(var value) {
    setProperty('margin-left', value, '');
  }

  /** Gets the value of "margin-right" */
  String get marginRight() =>
    getPropertyValue('margin-right');

  /** Sets the value of "margin-right" */
  void set marginRight(var value) {
    setProperty('margin-right', value, '');
  }

  /** Gets the value of "margin-start" */
  String get marginStart() =>
    getPropertyValue('${_browserPrefix}margin-start');

  /** Sets the value of "margin-start" */
  void set marginStart(var value) {
    setProperty('${_browserPrefix}margin-start', value, '');
  }

  /** Gets the value of "margin-top" */
  String get marginTop() =>
    getPropertyValue('margin-top');

  /** Sets the value of "margin-top" */
  void set marginTop(var value) {
    setProperty('margin-top', value, '');
  }

  /** Gets the value of "margin-top-collapse" */
  String get marginTopCollapse() =>
    getPropertyValue('${_browserPrefix}margin-top-collapse');

  /** Sets the value of "margin-top-collapse" */
  void set marginTopCollapse(var value) {
    setProperty('${_browserPrefix}margin-top-collapse', value, '');
  }

  /** Gets the value of "marquee" */
  String get marquee() =>
    getPropertyValue('${_browserPrefix}marquee');

  /** Sets the value of "marquee" */
  void set marquee(var value) {
    setProperty('${_browserPrefix}marquee', value, '');
  }

  /** Gets the value of "marquee-direction" */
  String get marqueeDirection() =>
    getPropertyValue('${_browserPrefix}marquee-direction');

  /** Sets the value of "marquee-direction" */
  void set marqueeDirection(var value) {
    setProperty('${_browserPrefix}marquee-direction', value, '');
  }

  /** Gets the value of "marquee-increment" */
  String get marqueeIncrement() =>
    getPropertyValue('${_browserPrefix}marquee-increment');

  /** Sets the value of "marquee-increment" */
  void set marqueeIncrement(var value) {
    setProperty('${_browserPrefix}marquee-increment', value, '');
  }

  /** Gets the value of "marquee-repetition" */
  String get marqueeRepetition() =>
    getPropertyValue('${_browserPrefix}marquee-repetition');

  /** Sets the value of "marquee-repetition" */
  void set marqueeRepetition(var value) {
    setProperty('${_browserPrefix}marquee-repetition', value, '');
  }

  /** Gets the value of "marquee-speed" */
  String get marqueeSpeed() =>
    getPropertyValue('${_browserPrefix}marquee-speed');

  /** Sets the value of "marquee-speed" */
  void set marqueeSpeed(var value) {
    setProperty('${_browserPrefix}marquee-speed', value, '');
  }

  /** Gets the value of "marquee-style" */
  String get marqueeStyle() =>
    getPropertyValue('${_browserPrefix}marquee-style');

  /** Sets the value of "marquee-style" */
  void set marqueeStyle(var value) {
    setProperty('${_browserPrefix}marquee-style', value, '');
  }

  /** Gets the value of "mask" */
  String get mask() =>
    getPropertyValue('${_browserPrefix}mask');

  /** Sets the value of "mask" */
  void set mask(var value) {
    setProperty('${_browserPrefix}mask', value, '');
  }

  /** Gets the value of "mask-attachment" */
  String get maskAttachment() =>
    getPropertyValue('${_browserPrefix}mask-attachment');

  /** Sets the value of "mask-attachment" */
  void set maskAttachment(var value) {
    setProperty('${_browserPrefix}mask-attachment', value, '');
  }

  /** Gets the value of "mask-box-image" */
  String get maskBoxImage() =>
    getPropertyValue('${_browserPrefix}mask-box-image');

  /** Sets the value of "mask-box-image" */
  void set maskBoxImage(var value) {
    setProperty('${_browserPrefix}mask-box-image', value, '');
  }

  /** Gets the value of "mask-box-image-outset" */
  String get maskBoxImageOutset() =>
    getPropertyValue('${_browserPrefix}mask-box-image-outset');

  /** Sets the value of "mask-box-image-outset" */
  void set maskBoxImageOutset(var value) {
    setProperty('${_browserPrefix}mask-box-image-outset', value, '');
  }

  /** Gets the value of "mask-box-image-repeat" */
  String get maskBoxImageRepeat() =>
    getPropertyValue('${_browserPrefix}mask-box-image-repeat');

  /** Sets the value of "mask-box-image-repeat" */
  void set maskBoxImageRepeat(var value) {
    setProperty('${_browserPrefix}mask-box-image-repeat', value, '');
  }

  /** Gets the value of "mask-box-image-slice" */
  String get maskBoxImageSlice() =>
    getPropertyValue('${_browserPrefix}mask-box-image-slice');

  /** Sets the value of "mask-box-image-slice" */
  void set maskBoxImageSlice(var value) {
    setProperty('${_browserPrefix}mask-box-image-slice', value, '');
  }

  /** Gets the value of "mask-box-image-source" */
  String get maskBoxImageSource() =>
    getPropertyValue('${_browserPrefix}mask-box-image-source');

  /** Sets the value of "mask-box-image-source" */
  void set maskBoxImageSource(var value) {
    setProperty('${_browserPrefix}mask-box-image-source', value, '');
  }

  /** Gets the value of "mask-box-image-width" */
  String get maskBoxImageWidth() =>
    getPropertyValue('${_browserPrefix}mask-box-image-width');

  /** Sets the value of "mask-box-image-width" */
  void set maskBoxImageWidth(var value) {
    setProperty('${_browserPrefix}mask-box-image-width', value, '');
  }

  /** Gets the value of "mask-clip" */
  String get maskClip() =>
    getPropertyValue('${_browserPrefix}mask-clip');

  /** Sets the value of "mask-clip" */
  void set maskClip(var value) {
    setProperty('${_browserPrefix}mask-clip', value, '');
  }

  /** Gets the value of "mask-composite" */
  String get maskComposite() =>
    getPropertyValue('${_browserPrefix}mask-composite');

  /** Sets the value of "mask-composite" */
  void set maskComposite(var value) {
    setProperty('${_browserPrefix}mask-composite', value, '');
  }

  /** Gets the value of "mask-image" */
  String get maskImage() =>
    getPropertyValue('${_browserPrefix}mask-image');

  /** Sets the value of "mask-image" */
  void set maskImage(var value) {
    setProperty('${_browserPrefix}mask-image', value, '');
  }

  /** Gets the value of "mask-origin" */
  String get maskOrigin() =>
    getPropertyValue('${_browserPrefix}mask-origin');

  /** Sets the value of "mask-origin" */
  void set maskOrigin(var value) {
    setProperty('${_browserPrefix}mask-origin', value, '');
  }

  /** Gets the value of "mask-position" */
  String get maskPosition() =>
    getPropertyValue('${_browserPrefix}mask-position');

  /** Sets the value of "mask-position" */
  void set maskPosition(var value) {
    setProperty('${_browserPrefix}mask-position', value, '');
  }

  /** Gets the value of "mask-position-x" */
  String get maskPositionX() =>
    getPropertyValue('${_browserPrefix}mask-position-x');

  /** Sets the value of "mask-position-x" */
  void set maskPositionX(var value) {
    setProperty('${_browserPrefix}mask-position-x', value, '');
  }

  /** Gets the value of "mask-position-y" */
  String get maskPositionY() =>
    getPropertyValue('${_browserPrefix}mask-position-y');

  /** Sets the value of "mask-position-y" */
  void set maskPositionY(var value) {
    setProperty('${_browserPrefix}mask-position-y', value, '');
  }

  /** Gets the value of "mask-repeat" */
  String get maskRepeat() =>
    getPropertyValue('${_browserPrefix}mask-repeat');

  /** Sets the value of "mask-repeat" */
  void set maskRepeat(var value) {
    setProperty('${_browserPrefix}mask-repeat', value, '');
  }

  /** Gets the value of "mask-repeat-x" */
  String get maskRepeatX() =>
    getPropertyValue('${_browserPrefix}mask-repeat-x');

  /** Sets the value of "mask-repeat-x" */
  void set maskRepeatX(var value) {
    setProperty('${_browserPrefix}mask-repeat-x', value, '');
  }

  /** Gets the value of "mask-repeat-y" */
  String get maskRepeatY() =>
    getPropertyValue('${_browserPrefix}mask-repeat-y');

  /** Sets the value of "mask-repeat-y" */
  void set maskRepeatY(var value) {
    setProperty('${_browserPrefix}mask-repeat-y', value, '');
  }

  /** Gets the value of "mask-size" */
  String get maskSize() =>
    getPropertyValue('${_browserPrefix}mask-size');

  /** Sets the value of "mask-size" */
  void set maskSize(var value) {
    setProperty('${_browserPrefix}mask-size', value, '');
  }

  /** Gets the value of "match-nearest-mail-blockquote-color" */
  String get matchNearestMailBlockquoteColor() =>
    getPropertyValue('${_browserPrefix}match-nearest-mail-blockquote-color');

  /** Sets the value of "match-nearest-mail-blockquote-color" */
  void set matchNearestMailBlockquoteColor(var value) {
    setProperty('${_browserPrefix}match-nearest-mail-blockquote-color', value, '');
  }

  /** Gets the value of "max-height" */
  String get maxHeight() =>
    getPropertyValue('max-height');

  /** Sets the value of "max-height" */
  void set maxHeight(var value) {
    setProperty('max-height', value, '');
  }

  /** Gets the value of "max-logical-height" */
  String get maxLogicalHeight() =>
    getPropertyValue('${_browserPrefix}max-logical-height');

  /** Sets the value of "max-logical-height" */
  void set maxLogicalHeight(var value) {
    setProperty('${_browserPrefix}max-logical-height', value, '');
  }

  /** Gets the value of "max-logical-width" */
  String get maxLogicalWidth() =>
    getPropertyValue('${_browserPrefix}max-logical-width');

  /** Sets the value of "max-logical-width" */
  void set maxLogicalWidth(var value) {
    setProperty('${_browserPrefix}max-logical-width', value, '');
  }

  /** Gets the value of "max-width" */
  String get maxWidth() =>
    getPropertyValue('max-width');

  /** Sets the value of "max-width" */
  void set maxWidth(var value) {
    setProperty('max-width', value, '');
  }

  /** Gets the value of "min-height" */
  String get minHeight() =>
    getPropertyValue('min-height');

  /** Sets the value of "min-height" */
  void set minHeight(var value) {
    setProperty('min-height', value, '');
  }

  /** Gets the value of "min-logical-height" */
  String get minLogicalHeight() =>
    getPropertyValue('${_browserPrefix}min-logical-height');

  /** Sets the value of "min-logical-height" */
  void set minLogicalHeight(var value) {
    setProperty('${_browserPrefix}min-logical-height', value, '');
  }

  /** Gets the value of "min-logical-width" */
  String get minLogicalWidth() =>
    getPropertyValue('${_browserPrefix}min-logical-width');

  /** Sets the value of "min-logical-width" */
  void set minLogicalWidth(var value) {
    setProperty('${_browserPrefix}min-logical-width', value, '');
  }

  /** Gets the value of "min-width" */
  String get minWidth() =>
    getPropertyValue('min-width');

  /** Sets the value of "min-width" */
  void set minWidth(var value) {
    setProperty('min-width', value, '');
  }

  /** Gets the value of "nbsp-mode" */
  String get nbspMode() =>
    getPropertyValue('${_browserPrefix}nbsp-mode');

  /** Sets the value of "nbsp-mode" */
  void set nbspMode(var value) {
    setProperty('${_browserPrefix}nbsp-mode', value, '');
  }

  /** Gets the value of "opacity" */
  String get opacity() =>
    getPropertyValue('opacity');

  /** Sets the value of "opacity" */
  void set opacity(var value) {
    setProperty('opacity', value, '');
  }

  /** Gets the value of "orphans" */
  String get orphans() =>
    getPropertyValue('orphans');

  /** Sets the value of "orphans" */
  void set orphans(var value) {
    setProperty('orphans', value, '');
  }

  /** Gets the value of "outline" */
  String get outline() =>
    getPropertyValue('outline');

  /** Sets the value of "outline" */
  void set outline(var value) {
    setProperty('outline', value, '');
  }

  /** Gets the value of "outline-color" */
  String get outlineColor() =>
    getPropertyValue('outline-color');

  /** Sets the value of "outline-color" */
  void set outlineColor(var value) {
    setProperty('outline-color', value, '');
  }

  /** Gets the value of "outline-offset" */
  String get outlineOffset() =>
    getPropertyValue('outline-offset');

  /** Sets the value of "outline-offset" */
  void set outlineOffset(var value) {
    setProperty('outline-offset', value, '');
  }

  /** Gets the value of "outline-style" */
  String get outlineStyle() =>
    getPropertyValue('outline-style');

  /** Sets the value of "outline-style" */
  void set outlineStyle(var value) {
    setProperty('outline-style', value, '');
  }

  /** Gets the value of "outline-width" */
  String get outlineWidth() =>
    getPropertyValue('outline-width');

  /** Sets the value of "outline-width" */
  void set outlineWidth(var value) {
    setProperty('outline-width', value, '');
  }

  /** Gets the value of "overflow" */
  String get overflow() =>
    getPropertyValue('overflow');

  /** Sets the value of "overflow" */
  void set overflow(var value) {
    setProperty('overflow', value, '');
  }

  /** Gets the value of "overflow-x" */
  String get overflowX() =>
    getPropertyValue('overflow-x');

  /** Sets the value of "overflow-x" */
  void set overflowX(var value) {
    setProperty('overflow-x', value, '');
  }

  /** Gets the value of "overflow-y" */
  String get overflowY() =>
    getPropertyValue('overflow-y');

  /** Sets the value of "overflow-y" */
  void set overflowY(var value) {
    setProperty('overflow-y', value, '');
  }

  /** Gets the value of "padding" */
  String get padding() =>
    getPropertyValue('padding');

  /** Sets the value of "padding" */
  void set padding(var value) {
    setProperty('padding', value, '');
  }

  /** Gets the value of "padding-after" */
  String get paddingAfter() =>
    getPropertyValue('${_browserPrefix}padding-after');

  /** Sets the value of "padding-after" */
  void set paddingAfter(var value) {
    setProperty('${_browserPrefix}padding-after', value, '');
  }

  /** Gets the value of "padding-before" */
  String get paddingBefore() =>
    getPropertyValue('${_browserPrefix}padding-before');

  /** Sets the value of "padding-before" */
  void set paddingBefore(var value) {
    setProperty('${_browserPrefix}padding-before', value, '');
  }

  /** Gets the value of "padding-bottom" */
  String get paddingBottom() =>
    getPropertyValue('padding-bottom');

  /** Sets the value of "padding-bottom" */
  void set paddingBottom(var value) {
    setProperty('padding-bottom', value, '');
  }

  /** Gets the value of "padding-end" */
  String get paddingEnd() =>
    getPropertyValue('${_browserPrefix}padding-end');

  /** Sets the value of "padding-end" */
  void set paddingEnd(var value) {
    setProperty('${_browserPrefix}padding-end', value, '');
  }

  /** Gets the value of "padding-left" */
  String get paddingLeft() =>
    getPropertyValue('padding-left');

  /** Sets the value of "padding-left" */
  void set paddingLeft(var value) {
    setProperty('padding-left', value, '');
  }

  /** Gets the value of "padding-right" */
  String get paddingRight() =>
    getPropertyValue('padding-right');

  /** Sets the value of "padding-right" */
  void set paddingRight(var value) {
    setProperty('padding-right', value, '');
  }

  /** Gets the value of "padding-start" */
  String get paddingStart() =>
    getPropertyValue('${_browserPrefix}padding-start');

  /** Sets the value of "padding-start" */
  void set paddingStart(var value) {
    setProperty('${_browserPrefix}padding-start', value, '');
  }

  /** Gets the value of "padding-top" */
  String get paddingTop() =>
    getPropertyValue('padding-top');

  /** Sets the value of "padding-top" */
  void set paddingTop(var value) {
    setProperty('padding-top', value, '');
  }

  /** Gets the value of "page" */
  String get page() =>
    getPropertyValue('page');

  /** Sets the value of "page" */
  void set page(var value) {
    setProperty('page', value, '');
  }

  /** Gets the value of "page-break-after" */
  String get pageBreakAfter() =>
    getPropertyValue('page-break-after');

  /** Sets the value of "page-break-after" */
  void set pageBreakAfter(var value) {
    setProperty('page-break-after', value, '');
  }

  /** Gets the value of "page-break-before" */
  String get pageBreakBefore() =>
    getPropertyValue('page-break-before');

  /** Sets the value of "page-break-before" */
  void set pageBreakBefore(var value) {
    setProperty('page-break-before', value, '');
  }

  /** Gets the value of "page-break-inside" */
  String get pageBreakInside() =>
    getPropertyValue('page-break-inside');

  /** Sets the value of "page-break-inside" */
  void set pageBreakInside(var value) {
    setProperty('page-break-inside', value, '');
  }

  /** Gets the value of "perspective" */
  String get perspective() =>
    getPropertyValue('${_browserPrefix}perspective');

  /** Sets the value of "perspective" */
  void set perspective(var value) {
    setProperty('${_browserPrefix}perspective', value, '');
  }

  /** Gets the value of "perspective-origin" */
  String get perspectiveOrigin() =>
    getPropertyValue('${_browserPrefix}perspective-origin');

  /** Sets the value of "perspective-origin" */
  void set perspectiveOrigin(var value) {
    setProperty('${_browserPrefix}perspective-origin', value, '');
  }

  /** Gets the value of "perspective-origin-x" */
  String get perspectiveOriginX() =>
    getPropertyValue('${_browserPrefix}perspective-origin-x');

  /** Sets the value of "perspective-origin-x" */
  void set perspectiveOriginX(var value) {
    setProperty('${_browserPrefix}perspective-origin-x', value, '');
  }

  /** Gets the value of "perspective-origin-y" */
  String get perspectiveOriginY() =>
    getPropertyValue('${_browserPrefix}perspective-origin-y');

  /** Sets the value of "perspective-origin-y" */
  void set perspectiveOriginY(var value) {
    setProperty('${_browserPrefix}perspective-origin-y', value, '');
  }

  /** Gets the value of "pointer-events" */
  String get pointerEvents() =>
    getPropertyValue('pointer-events');

  /** Sets the value of "pointer-events" */
  void set pointerEvents(var value) {
    setProperty('pointer-events', value, '');
  }

  /** Gets the value of "position" */
  String get position() =>
    getPropertyValue('position');

  /** Sets the value of "position" */
  void set position(var value) {
    setProperty('position', value, '');
  }

  /** Gets the value of "quotes" */
  String get quotes() =>
    getPropertyValue('quotes');

  /** Sets the value of "quotes" */
  void set quotes(var value) {
    setProperty('quotes', value, '');
  }

  /** Gets the value of "region-break-after" */
  String get regionBreakAfter() =>
    getPropertyValue('${_browserPrefix}region-break-after');

  /** Sets the value of "region-break-after" */
  void set regionBreakAfter(var value) {
    setProperty('${_browserPrefix}region-break-after', value, '');
  }

  /** Gets the value of "region-break-before" */
  String get regionBreakBefore() =>
    getPropertyValue('${_browserPrefix}region-break-before');

  /** Sets the value of "region-break-before" */
  void set regionBreakBefore(var value) {
    setProperty('${_browserPrefix}region-break-before', value, '');
  }

  /** Gets the value of "region-break-inside" */
  String get regionBreakInside() =>
    getPropertyValue('${_browserPrefix}region-break-inside');

  /** Sets the value of "region-break-inside" */
  void set regionBreakInside(var value) {
    setProperty('${_browserPrefix}region-break-inside', value, '');
  }

  /** Gets the value of "region-overflow" */
  String get regionOverflow() =>
    getPropertyValue('${_browserPrefix}region-overflow');

  /** Sets the value of "region-overflow" */
  void set regionOverflow(var value) {
    setProperty('${_browserPrefix}region-overflow', value, '');
  }

  /** Gets the value of "resize" */
  String get resize() =>
    getPropertyValue('resize');

  /** Sets the value of "resize" */
  void set resize(var value) {
    setProperty('resize', value, '');
  }

  /** Gets the value of "right" */
  String get right() =>
    getPropertyValue('right');

  /** Sets the value of "right" */
  void set right(var value) {
    setProperty('right', value, '');
  }

  /** Gets the value of "rtl-ordering" */
  String get rtlOrdering() =>
    getPropertyValue('${_browserPrefix}rtl-ordering');

  /** Sets the value of "rtl-ordering" */
  void set rtlOrdering(var value) {
    setProperty('${_browserPrefix}rtl-ordering', value, '');
  }

  /** Gets the value of "size" */
  String get size() =>
    getPropertyValue('size');

  /** Sets the value of "size" */
  void set size(var value) {
    setProperty('size', value, '');
  }

  /** Gets the value of "speak" */
  String get speak() =>
    getPropertyValue('speak');

  /** Sets the value of "speak" */
  void set speak(var value) {
    setProperty('speak', value, '');
  }

  /** Gets the value of "src" */
  String get src() =>
    getPropertyValue('src');

  /** Sets the value of "src" */
  void set src(var value) {
    setProperty('src', value, '');
  }

  /** Gets the value of "table-layout" */
  String get tableLayout() =>
    getPropertyValue('table-layout');

  /** Sets the value of "table-layout" */
  void set tableLayout(var value) {
    setProperty('table-layout', value, '');
  }

  /** Gets the value of "tap-highlight-color" */
  String get tapHighlightColor() =>
    getPropertyValue('${_browserPrefix}tap-highlight-color');

  /** Sets the value of "tap-highlight-color" */
  void set tapHighlightColor(var value) {
    setProperty('${_browserPrefix}tap-highlight-color', value, '');
  }

  /** Gets the value of "text-align" */
  String get textAlign() =>
    getPropertyValue('text-align');

  /** Sets the value of "text-align" */
  void set textAlign(var value) {
    setProperty('text-align', value, '');
  }

  /** Gets the value of "text-combine" */
  String get textCombine() =>
    getPropertyValue('${_browserPrefix}text-combine');

  /** Sets the value of "text-combine" */
  void set textCombine(var value) {
    setProperty('${_browserPrefix}text-combine', value, '');
  }

  /** Gets the value of "text-decoration" */
  String get textDecoration() =>
    getPropertyValue('text-decoration');

  /** Sets the value of "text-decoration" */
  void set textDecoration(var value) {
    setProperty('text-decoration', value, '');
  }

  /** Gets the value of "text-decorations-in-effect" */
  String get textDecorationsInEffect() =>
    getPropertyValue('${_browserPrefix}text-decorations-in-effect');

  /** Sets the value of "text-decorations-in-effect" */
  void set textDecorationsInEffect(var value) {
    setProperty('${_browserPrefix}text-decorations-in-effect', value, '');
  }

  /** Gets the value of "text-emphasis" */
  String get textEmphasis() =>
    getPropertyValue('${_browserPrefix}text-emphasis');

  /** Sets the value of "text-emphasis" */
  void set textEmphasis(var value) {
    setProperty('${_browserPrefix}text-emphasis', value, '');
  }

  /** Gets the value of "text-emphasis-color" */
  String get textEmphasisColor() =>
    getPropertyValue('${_browserPrefix}text-emphasis-color');

  /** Sets the value of "text-emphasis-color" */
  void set textEmphasisColor(var value) {
    setProperty('${_browserPrefix}text-emphasis-color', value, '');
  }

  /** Gets the value of "text-emphasis-position" */
  String get textEmphasisPosition() =>
    getPropertyValue('${_browserPrefix}text-emphasis-position');

  /** Sets the value of "text-emphasis-position" */
  void set textEmphasisPosition(var value) {
    setProperty('${_browserPrefix}text-emphasis-position', value, '');
  }

  /** Gets the value of "text-emphasis-style" */
  String get textEmphasisStyle() =>
    getPropertyValue('${_browserPrefix}text-emphasis-style');

  /** Sets the value of "text-emphasis-style" */
  void set textEmphasisStyle(var value) {
    setProperty('${_browserPrefix}text-emphasis-style', value, '');
  }

  /** Gets the value of "text-fill-color" */
  String get textFillColor() =>
    getPropertyValue('${_browserPrefix}text-fill-color');

  /** Sets the value of "text-fill-color" */
  void set textFillColor(var value) {
    setProperty('${_browserPrefix}text-fill-color', value, '');
  }

  /** Gets the value of "text-indent" */
  String get textIndent() =>
    getPropertyValue('text-indent');

  /** Sets the value of "text-indent" */
  void set textIndent(var value) {
    setProperty('text-indent', value, '');
  }

  /** Gets the value of "text-line-through" */
  String get textLineThrough() =>
    getPropertyValue('text-line-through');

  /** Sets the value of "text-line-through" */
  void set textLineThrough(var value) {
    setProperty('text-line-through', value, '');
  }

  /** Gets the value of "text-line-through-color" */
  String get textLineThroughColor() =>
    getPropertyValue('text-line-through-color');

  /** Sets the value of "text-line-through-color" */
  void set textLineThroughColor(var value) {
    setProperty('text-line-through-color', value, '');
  }

  /** Gets the value of "text-line-through-mode" */
  String get textLineThroughMode() =>
    getPropertyValue('text-line-through-mode');

  /** Sets the value of "text-line-through-mode" */
  void set textLineThroughMode(var value) {
    setProperty('text-line-through-mode', value, '');
  }

  /** Gets the value of "text-line-through-style" */
  String get textLineThroughStyle() =>
    getPropertyValue('text-line-through-style');

  /** Sets the value of "text-line-through-style" */
  void set textLineThroughStyle(var value) {
    setProperty('text-line-through-style', value, '');
  }

  /** Gets the value of "text-line-through-width" */
  String get textLineThroughWidth() =>
    getPropertyValue('text-line-through-width');

  /** Sets the value of "text-line-through-width" */
  void set textLineThroughWidth(var value) {
    setProperty('text-line-through-width', value, '');
  }

  /** Gets the value of "text-orientation" */
  String get textOrientation() =>
    getPropertyValue('${_browserPrefix}text-orientation');

  /** Sets the value of "text-orientation" */
  void set textOrientation(var value) {
    setProperty('${_browserPrefix}text-orientation', value, '');
  }

  /** Gets the value of "text-overflow" */
  String get textOverflow() =>
    getPropertyValue('text-overflow');

  /** Sets the value of "text-overflow" */
  void set textOverflow(var value) {
    setProperty('text-overflow', value, '');
  }

  /** Gets the value of "text-overline" */
  String get textOverline() =>
    getPropertyValue('text-overline');

  /** Sets the value of "text-overline" */
  void set textOverline(var value) {
    setProperty('text-overline', value, '');
  }

  /** Gets the value of "text-overline-color" */
  String get textOverlineColor() =>
    getPropertyValue('text-overline-color');

  /** Sets the value of "text-overline-color" */
  void set textOverlineColor(var value) {
    setProperty('text-overline-color', value, '');
  }

  /** Gets the value of "text-overline-mode" */
  String get textOverlineMode() =>
    getPropertyValue('text-overline-mode');

  /** Sets the value of "text-overline-mode" */
  void set textOverlineMode(var value) {
    setProperty('text-overline-mode', value, '');
  }

  /** Gets the value of "text-overline-style" */
  String get textOverlineStyle() =>
    getPropertyValue('text-overline-style');

  /** Sets the value of "text-overline-style" */
  void set textOverlineStyle(var value) {
    setProperty('text-overline-style', value, '');
  }

  /** Gets the value of "text-overline-width" */
  String get textOverlineWidth() =>
    getPropertyValue('text-overline-width');

  /** Sets the value of "text-overline-width" */
  void set textOverlineWidth(var value) {
    setProperty('text-overline-width', value, '');
  }

  /** Gets the value of "text-rendering" */
  String get textRendering() =>
    getPropertyValue('text-rendering');

  /** Sets the value of "text-rendering" */
  void set textRendering(var value) {
    setProperty('text-rendering', value, '');
  }

  /** Gets the value of "text-security" */
  String get textSecurity() =>
    getPropertyValue('${_browserPrefix}text-security');

  /** Sets the value of "text-security" */
  void set textSecurity(var value) {
    setProperty('${_browserPrefix}text-security', value, '');
  }

  /** Gets the value of "text-shadow" */
  String get textShadow() =>
    getPropertyValue('text-shadow');

  /** Sets the value of "text-shadow" */
  void set textShadow(var value) {
    setProperty('text-shadow', value, '');
  }

  /** Gets the value of "text-size-adjust" */
  String get textSizeAdjust() =>
    getPropertyValue('${_browserPrefix}text-size-adjust');

  /** Sets the value of "text-size-adjust" */
  void set textSizeAdjust(var value) {
    setProperty('${_browserPrefix}text-size-adjust', value, '');
  }

  /** Gets the value of "text-stroke" */
  String get textStroke() =>
    getPropertyValue('${_browserPrefix}text-stroke');

  /** Sets the value of "text-stroke" */
  void set textStroke(var value) {
    setProperty('${_browserPrefix}text-stroke', value, '');
  }

  /** Gets the value of "text-stroke-color" */
  String get textStrokeColor() =>
    getPropertyValue('${_browserPrefix}text-stroke-color');

  /** Sets the value of "text-stroke-color" */
  void set textStrokeColor(var value) {
    setProperty('${_browserPrefix}text-stroke-color', value, '');
  }

  /** Gets the value of "text-stroke-width" */
  String get textStrokeWidth() =>
    getPropertyValue('${_browserPrefix}text-stroke-width');

  /** Sets the value of "text-stroke-width" */
  void set textStrokeWidth(var value) {
    setProperty('${_browserPrefix}text-stroke-width', value, '');
  }

  /** Gets the value of "text-transform" */
  String get textTransform() =>
    getPropertyValue('text-transform');

  /** Sets the value of "text-transform" */
  void set textTransform(var value) {
    setProperty('text-transform', value, '');
  }

  /** Gets the value of "text-underline" */
  String get textUnderline() =>
    getPropertyValue('text-underline');

  /** Sets the value of "text-underline" */
  void set textUnderline(var value) {
    setProperty('text-underline', value, '');
  }

  /** Gets the value of "text-underline-color" */
  String get textUnderlineColor() =>
    getPropertyValue('text-underline-color');

  /** Sets the value of "text-underline-color" */
  void set textUnderlineColor(var value) {
    setProperty('text-underline-color', value, '');
  }

  /** Gets the value of "text-underline-mode" */
  String get textUnderlineMode() =>
    getPropertyValue('text-underline-mode');

  /** Sets the value of "text-underline-mode" */
  void set textUnderlineMode(var value) {
    setProperty('text-underline-mode', value, '');
  }

  /** Gets the value of "text-underline-style" */
  String get textUnderlineStyle() =>
    getPropertyValue('text-underline-style');

  /** Sets the value of "text-underline-style" */
  void set textUnderlineStyle(var value) {
    setProperty('text-underline-style', value, '');
  }

  /** Gets the value of "text-underline-width" */
  String get textUnderlineWidth() =>
    getPropertyValue('text-underline-width');

  /** Sets the value of "text-underline-width" */
  void set textUnderlineWidth(var value) {
    setProperty('text-underline-width', value, '');
  }

  /** Gets the value of "top" */
  String get top() =>
    getPropertyValue('top');

  /** Sets the value of "top" */
  void set top(var value) {
    setProperty('top', value, '');
  }

  /** Gets the value of "transform" */
  String get transform() =>
    getPropertyValue('${_browserPrefix}transform');

  /** Sets the value of "transform" */
  void set transform(var value) {
    setProperty('${_browserPrefix}transform', value, '');
  }

  /** Gets the value of "transform-origin" */
  String get transformOrigin() =>
    getPropertyValue('${_browserPrefix}transform-origin');

  /** Sets the value of "transform-origin" */
  void set transformOrigin(var value) {
    setProperty('${_browserPrefix}transform-origin', value, '');
  }

  /** Gets the value of "transform-origin-x" */
  String get transformOriginX() =>
    getPropertyValue('${_browserPrefix}transform-origin-x');

  /** Sets the value of "transform-origin-x" */
  void set transformOriginX(var value) {
    setProperty('${_browserPrefix}transform-origin-x', value, '');
  }

  /** Gets the value of "transform-origin-y" */
  String get transformOriginY() =>
    getPropertyValue('${_browserPrefix}transform-origin-y');

  /** Sets the value of "transform-origin-y" */
  void set transformOriginY(var value) {
    setProperty('${_browserPrefix}transform-origin-y', value, '');
  }

  /** Gets the value of "transform-origin-z" */
  String get transformOriginZ() =>
    getPropertyValue('${_browserPrefix}transform-origin-z');

  /** Sets the value of "transform-origin-z" */
  void set transformOriginZ(var value) {
    setProperty('${_browserPrefix}transform-origin-z', value, '');
  }

  /** Gets the value of "transform-style" */
  String get transformStyle() =>
    getPropertyValue('${_browserPrefix}transform-style');

  /** Sets the value of "transform-style" */
  void set transformStyle(var value) {
    setProperty('${_browserPrefix}transform-style', value, '');
  }

  /** Gets the value of "transition" */
  String get transition() =>
    getPropertyValue('${_browserPrefix}transition');

  /** Sets the value of "transition" */
  void set transition(var value) {
    setProperty('${_browserPrefix}transition', value, '');
  }

  /** Gets the value of "transition-delay" */
  String get transitionDelay() =>
    getPropertyValue('${_browserPrefix}transition-delay');

  /** Sets the value of "transition-delay" */
  void set transitionDelay(var value) {
    setProperty('${_browserPrefix}transition-delay', value, '');
  }

  /** Gets the value of "transition-duration" */
  String get transitionDuration() =>
    getPropertyValue('${_browserPrefix}transition-duration');

  /** Sets the value of "transition-duration" */
  void set transitionDuration(var value) {
    setProperty('${_browserPrefix}transition-duration', value, '');
  }

  /** Gets the value of "transition-property" */
  String get transitionProperty() =>
    getPropertyValue('${_browserPrefix}transition-property');

  /** Sets the value of "transition-property" */
  void set transitionProperty(var value) {
    setProperty('${_browserPrefix}transition-property', value, '');
  }

  /** Gets the value of "transition-timing-function" */
  String get transitionTimingFunction() =>
    getPropertyValue('${_browserPrefix}transition-timing-function');

  /** Sets the value of "transition-timing-function" */
  void set transitionTimingFunction(var value) {
    setProperty('${_browserPrefix}transition-timing-function', value, '');
  }

  /** Gets the value of "unicode-bidi" */
  String get unicodeBidi() =>
    getPropertyValue('unicode-bidi');

  /** Sets the value of "unicode-bidi" */
  void set unicodeBidi(var value) {
    setProperty('unicode-bidi', value, '');
  }

  /** Gets the value of "unicode-range" */
  String get unicodeRange() =>
    getPropertyValue('unicode-range');

  /** Sets the value of "unicode-range" */
  void set unicodeRange(var value) {
    setProperty('unicode-range', value, '');
  }

  /** Gets the value of "user-drag" */
  String get userDrag() =>
    getPropertyValue('${_browserPrefix}user-drag');

  /** Sets the value of "user-drag" */
  void set userDrag(var value) {
    setProperty('${_browserPrefix}user-drag', value, '');
  }

  /** Gets the value of "user-modify" */
  String get userModify() =>
    getPropertyValue('${_browserPrefix}user-modify');

  /** Sets the value of "user-modify" */
  void set userModify(var value) {
    setProperty('${_browserPrefix}user-modify', value, '');
  }

  /** Gets the value of "user-select" */
  String get userSelect() =>
    getPropertyValue('${_browserPrefix}user-select');

  /** Sets the value of "user-select" */
  void set userSelect(var value) {
    setProperty('${_browserPrefix}user-select', value, '');
  }

  /** Gets the value of "vertical-align" */
  String get verticalAlign() =>
    getPropertyValue('vertical-align');

  /** Sets the value of "vertical-align" */
  void set verticalAlign(var value) {
    setProperty('vertical-align', value, '');
  }

  /** Gets the value of "visibility" */
  String get visibility() =>
    getPropertyValue('visibility');

  /** Sets the value of "visibility" */
  void set visibility(var value) {
    setProperty('visibility', value, '');
  }

  /** Gets the value of "white-space" */
  String get whiteSpace() =>
    getPropertyValue('white-space');

  /** Sets the value of "white-space" */
  void set whiteSpace(var value) {
    setProperty('white-space', value, '');
  }

  /** Gets the value of "widows" */
  String get widows() =>
    getPropertyValue('widows');

  /** Sets the value of "widows" */
  void set widows(var value) {
    setProperty('widows', value, '');
  }

  /** Gets the value of "width" */
  String get width() =>
    getPropertyValue('width');

  /** Sets the value of "width" */
  void set width(var value) {
    setProperty('width', value, '');
  }

  /** Gets the value of "word-break" */
  String get wordBreak() =>
    getPropertyValue('word-break');

  /** Sets the value of "word-break" */
  void set wordBreak(var value) {
    setProperty('word-break', value, '');
  }

  /** Gets the value of "word-spacing" */
  String get wordSpacing() =>
    getPropertyValue('word-spacing');

  /** Sets the value of "word-spacing" */
  void set wordSpacing(var value) {
    setProperty('word-spacing', value, '');
  }

  /** Gets the value of "word-wrap" */
  String get wordWrap() =>
    getPropertyValue('word-wrap');

  /** Sets the value of "word-wrap" */
  void set wordWrap(var value) {
    setProperty('word-wrap', value, '');
  }

  /** Gets the value of "wrap-shape" */
  String get wrapShape() =>
    getPropertyValue('${_browserPrefix}wrap-shape');

  /** Sets the value of "wrap-shape" */
  void set wrapShape(var value) {
    setProperty('${_browserPrefix}wrap-shape', value, '');
  }

  /** Gets the value of "writing-mode" */
  String get writingMode() =>
    getPropertyValue('${_browserPrefix}writing-mode');

  /** Sets the value of "writing-mode" */
  void set writingMode(var value) {
    setProperty('${_browserPrefix}writing-mode', value, '');
  }

  /** Gets the value of "z-index" */
  String get zIndex() =>
    getPropertyValue('z-index');

  /** Sets the value of "z-index" */
  void set zIndex(var value) {
    setProperty('z-index', value, '');
  }

  /** Gets the value of "zoom" */
  String get zoom() =>
    getPropertyValue('zoom');

  /** Sets the value of "zoom" */
  void set zoom(var value) {
    setProperty('zoom', value, '');
  }
}

class _CSSStyleRuleImpl extends _CSSRuleImpl implements CSSStyleRule native "*CSSStyleRule" {

  String selectorText;

  final _CSSStyleDeclarationImpl style;
}

class _CSSStyleSheetImpl extends _StyleSheetImpl implements CSSStyleSheet native "*CSSStyleSheet" {

  final _CSSRuleListImpl cssRules;

  final _CSSRuleImpl ownerRule;

  final _CSSRuleListImpl rules;

  int addRule(String selector, String style, [int index = null]) native;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;

  void removeRule(int index) native;
}

class _CSSTransformValueImpl extends _CSSValueListImpl implements CSSTransformValue native "*WebKitCSSTransformValue" {

  static final int CSS_MATRIX = 11;

  static final int CSS_MATRIX3D = 21;

  static final int CSS_PERSPECTIVE = 20;

  static final int CSS_ROTATE = 4;

  static final int CSS_ROTATE3D = 17;

  static final int CSS_ROTATEX = 14;

  static final int CSS_ROTATEY = 15;

  static final int CSS_ROTATEZ = 16;

  static final int CSS_SCALE = 5;

  static final int CSS_SCALE3D = 19;

  static final int CSS_SCALEX = 6;

  static final int CSS_SCALEY = 7;

  static final int CSS_SCALEZ = 18;

  static final int CSS_SKEW = 8;

  static final int CSS_SKEWX = 9;

  static final int CSS_SKEWY = 10;

  static final int CSS_TRANSLATE = 1;

  static final int CSS_TRANSLATE3D = 13;

  static final int CSS_TRANSLATEX = 2;

  static final int CSS_TRANSLATEY = 3;

  static final int CSS_TRANSLATEZ = 12;

  final int operationType;
}

class _CSSUnknownRuleImpl extends _CSSRuleImpl implements CSSUnknownRule native "*CSSUnknownRule" {
}

class _CSSValueImpl implements CSSValue native "*CSSValue" {

  static final int CSS_CUSTOM = 3;

  static final int CSS_INHERIT = 0;

  static final int CSS_PRIMITIVE_VALUE = 1;

  static final int CSS_VALUE_LIST = 2;

  String cssText;

  final int cssValueType;
}

class _CSSValueListImpl extends _CSSValueImpl implements CSSValueList native "*CSSValueList" {

  final int length;

  _CSSValueImpl item(int index) native;
}

class _CanvasElementImpl extends _ElementImpl implements CanvasElement native "*HTMLCanvasElement" {

  int height;

  int width;

  Object getContext(String contextId) native;

  String toDataURL(String type) native;
}

class _CanvasGradientImpl implements CanvasGradient native "*CanvasGradient" {

  void addColorStop(num offset, String color) native;
}

class _CanvasPatternImpl implements CanvasPattern native "*CanvasPattern" {
}

class _CanvasPixelArrayImpl implements CanvasPixelArray native "*CanvasPixelArray" {

  final int length;

  int operator[](int index) native "return this[index];";

  void operator[]=(int index, int value) native "this[index] = value";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<int>:

  void sort(int compare(int a, int b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  int last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<int> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [int initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<int> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <int>[]);

  // -- end List<int> mixins.
}

class _CanvasRenderingContextImpl implements CanvasRenderingContext native "*CanvasRenderingContext" {

  final _CanvasElementImpl canvas;
}

class _CanvasRenderingContext2DImpl extends _CanvasRenderingContextImpl implements CanvasRenderingContext2D native "*CanvasRenderingContext2D" {

  Dynamic fillStyle;

  String font;

  num globalAlpha;

  String globalCompositeOperation;

  String lineCap;

  String lineJoin;

  num lineWidth;

  num miterLimit;

  num shadowBlur;

  String shadowColor;

  num shadowOffsetX;

  num shadowOffsetY;

  Dynamic strokeStyle;

  String textAlign;

  String textBaseline;

  List webkitLineDash;

  num webkitLineDashOffset;

  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise) native;

  void arcTo(num x1, num y1, num x2, num y2, num radius) native;

  void beginPath() native;

  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) native;

  void clearRect(num x, num y, num width, num height) native;

  void clearShadow() native;

  void clip() native;

  void closePath() native;

  _ImageDataImpl createImageData(var imagedata_OR_sw, [num sh = null]) native;

  _CanvasGradientImpl createLinearGradient(num x0, num y0, num x1, num y1) native;

  _CanvasPatternImpl createPattern(var canvas_OR_image, String repetitionType) native;

  _CanvasGradientImpl createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) native;

  void drawImage(var canvas_OR_image_OR_video, num sx_OR_x, num sy_OR_y, [num sw_OR_width = null, num height_OR_sh = null, num dx = null, num dy = null, num dw = null, num dh = null]) native;

  void drawImageFromRect(_ImageElementImpl image, [num sx = null, num sy = null, num sw = null, num sh = null, num dx = null, num dy = null, num dw = null, num dh = null, String compositeOperation = null]) native;

  void fill() native;

  void fillRect(num x, num y, num width, num height) native;

  void fillText(String text, num x, num y, [num maxWidth = null]) native;

  _ImageDataImpl getImageData(num sx, num sy, num sw, num sh) native;

  bool isPointInPath(num x, num y) native;

  void lineTo(num x, num y) native;

  _TextMetricsImpl measureText(String text) native;

  void moveTo(num x, num y) native;

  void putImageData(_ImageDataImpl imagedata, num dx, num dy, [num dirtyX = null, num dirtyY = null, num dirtyWidth = null, num dirtyHeight = null]) native;

  void quadraticCurveTo(num cpx, num cpy, num x, num y) native;

  void rect(num x, num y, num width, num height) native;

  void restore() native;

  void rotate(num angle) native;

  void save() native;

  void scale(num sx, num sy) native;

  void setAlpha(num alpha) native;

  void setCompositeOperation(String compositeOperation) native;

  void setFillColor(var c_OR_color_OR_grayLevel_OR_r, [num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) native;

  void setLineCap(String cap) native;

  void setLineJoin(String join) native;

  void setLineWidth(num width) native;

  void setMiterLimit(num limit) native;

  void setShadow(num width, num height, num blur, [var c_OR_color_OR_grayLevel_OR_r = null, num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) native;

  void setStrokeColor(var c_OR_color_OR_grayLevel_OR_r, [num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) native;

  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy) native;

  void stroke() native;

  void strokeRect(num x, num y, num width, num height, [num lineWidth = null]) native;

  void strokeText(String text, num x, num y, [num maxWidth = null]) native;

  void transform(num m11, num m12, num m21, num m22, num dx, num dy) native;

  void translate(num tx, num ty) native;
}

class _CharacterDataImpl extends _NodeImpl implements CharacterData native "*CharacterData" {

  String data;

  final int length;

  void appendData(String data) native;

  void deleteData(int offset, int length) native;

  void insertData(int offset, String data) native;

  void replaceData(int offset, int length, String data) native;

  String substringData(int offset, int length) native;
}

class _ClientRectImpl implements ClientRect native "*ClientRect" {

  final num bottom;

  final num height;

  final num left;

  final num right;

  final num top;

  final num width;
}

class _ClientRectListImpl implements ClientRectList native "*ClientRectList" {

  final int length;

  _ClientRectImpl item(int index) native;
}

class _ClipboardImpl implements Clipboard native "*Clipboard" {

  String dropEffect;

  String effectAllowed;

  final _FileListImpl files;

  final _DataTransferItemListImpl items;

  final List types;

  void clearData([String type = null]) native;

  String getData(String type) native;

  bool setData(String type, String data) native;

  void setDragImage(_ImageElementImpl image, int x, int y) native;
}

class _CloseEventImpl extends _EventImpl implements CloseEvent native "*CloseEvent" {

  final int code;

  final String reason;

  final bool wasClean;
}

class _CommentImpl extends _CharacterDataImpl implements Comment native "*Comment" {
}

class _CompositionEventImpl extends _UIEventImpl implements CompositionEvent native "*CompositionEvent" {

  final String data;

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, _WindowImpl viewArg, String dataArg) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ConsoleImpl
    // Console is sometimes a singleton bag-of-properties without a prototype.
    implements Console 
    native "=(typeof console == 'undefined' ? {} : console)" {

  final _MemoryInfoImpl memory;

  final List<ScriptProfile> profiles;

  void assertCondition(bool condition, Object arg) native;

  void count() native;

  void debug(Object arg) native;

  void dir() native;

  void dirxml() native;

  void error(Object arg) native;

  void group(Object arg) native;

  void groupCollapsed(Object arg) native;

  void groupEnd() native;

  void info(Object arg) native;

  void log(Object arg) native;

  void markTimeline() native;

  void profile(String title) native;

  void profileEnd(String title) native;

  void time(String title) native;

  void timeEnd(String title, Object arg) native;

  void timeStamp(Object arg) native;

  void trace(Object arg) native;

  void warn(Object arg) native;

}

class _ContentElementImpl extends _ElementImpl implements ContentElement native "*HTMLContentElement" {

  String select;
}

class _ConvolverNodeImpl extends _AudioNodeImpl implements ConvolverNode native "*ConvolverNode" {

  _AudioBufferImpl buffer;

  bool normalize;
}

class _CoordinatesImpl implements Coordinates native "*Coordinates" {

  final num accuracy;

  final num altitude;

  final num altitudeAccuracy;

  final num heading;

  final num latitude;

  final num longitude;

  final num speed;
}

class _CounterImpl implements Counter native "*Counter" {

  final String identifier;

  final String listStyle;

  final String separator;
}

class _CryptoImpl implements Crypto native "*Crypto" {

  void getRandomValues(_ArrayBufferViewImpl array) native;
}

class _CustomEventImpl extends _EventImpl implements CustomEvent native "*CustomEvent" {

  final Object detail;

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) native;
}

class _DListElementImpl extends _ElementImpl implements DListElement native "*HTMLDListElement" {

  bool compact;
}

class _DOMApplicationCacheImpl extends _EventTargetImpl implements DOMApplicationCache native "*DOMApplicationCache" {

  _DOMApplicationCacheEventsImpl get on() =>
    new _DOMApplicationCacheEventsImpl(this);

  static final int CHECKING = 2;

  static final int DOWNLOADING = 3;

  static final int IDLE = 1;

  static final int OBSOLETE = 5;

  static final int UNCACHED = 0;

  static final int UPDATEREADY = 4;

  final int status;

  void abort() native;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  bool $dom_dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

  void swapCache() native;

  void update() native;
}

class _DOMApplicationCacheEventsImpl extends _EventsImpl implements DOMApplicationCacheEvents {
  _DOMApplicationCacheEventsImpl(_ptr) : super(_ptr);

  EventListenerList get cached() => _get('cached');

  EventListenerList get checking() => _get('checking');

  EventListenerList get downloading() => _get('downloading');

  EventListenerList get error() => _get('error');

  EventListenerList get noUpdate() => _get('noupdate');

  EventListenerList get obsolete() => _get('obsolete');

  EventListenerList get progress() => _get('progress');

  EventListenerList get updateReady() => _get('updateready');
}

class _DOMExceptionImpl implements DOMException native "*DOMException" {

  static final int ABORT_ERR = 20;

  static final int DATA_CLONE_ERR = 25;

  static final int DOMSTRING_SIZE_ERR = 2;

  static final int HIERARCHY_REQUEST_ERR = 3;

  static final int INDEX_SIZE_ERR = 1;

  static final int INUSE_ATTRIBUTE_ERR = 10;

  static final int INVALID_ACCESS_ERR = 15;

  static final int INVALID_CHARACTER_ERR = 5;

  static final int INVALID_MODIFICATION_ERR = 13;

  static final int INVALID_NODE_TYPE_ERR = 24;

  static final int INVALID_STATE_ERR = 11;

  static final int NAMESPACE_ERR = 14;

  static final int NETWORK_ERR = 19;

  static final int NOT_FOUND_ERR = 8;

  static final int NOT_SUPPORTED_ERR = 9;

  static final int NO_DATA_ALLOWED_ERR = 6;

  static final int NO_MODIFICATION_ALLOWED_ERR = 7;

  static final int QUOTA_EXCEEDED_ERR = 22;

  static final int SECURITY_ERR = 18;

  static final int SYNTAX_ERR = 12;

  static final int TIMEOUT_ERR = 23;

  static final int TYPE_MISMATCH_ERR = 17;

  static final int URL_MISMATCH_ERR = 21;

  static final int VALIDATION_ERR = 16;

  static final int WRONG_DOCUMENT_ERR = 4;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _DOMFileSystemImpl implements DOMFileSystem native "*DOMFileSystem" {

  final String name;

  final _DirectoryEntryImpl root;
}

class _DOMFileSystemSyncImpl implements DOMFileSystemSync native "*DOMFileSystemSync" {

  final String name;

  final _DirectoryEntrySyncImpl root;
}

class _DOMFormDataImpl implements DOMFormData native "*DOMFormData" {

  void append(String name, String value, String filename) native;
}

class _DOMImplementationImpl implements DOMImplementation native "*DOMImplementation" {

  _CSSStyleSheetImpl createCSSStyleSheet(String title, String media) native;

  _DocumentImpl createDocument(String namespaceURI, String qualifiedName, _DocumentTypeImpl doctype) native;

  _DocumentTypeImpl createDocumentType(String qualifiedName, String publicId, String systemId) native;

  _DocumentImpl createHTMLDocument(String title) native;

  bool hasFeature(String feature, String version) native;
}

class _DOMMimeTypeImpl implements DOMMimeType native "*DOMMimeType" {

  final String description;

  final _DOMPluginImpl enabledPlugin;

  final String suffixes;

  final String type;
}

class _DOMMimeTypeArrayImpl implements DOMMimeTypeArray native "*DOMMimeTypeArray" {

  final int length;

  _DOMMimeTypeImpl item(int index) native;

  _DOMMimeTypeImpl namedItem(String name) native;
}

class _DOMParserImpl implements DOMParser native "*DOMParser" {

  _DocumentImpl parseFromString(String str, String contentType) native;
}

class _DOMPluginImpl implements DOMPlugin native "*DOMPlugin" {

  final String description;

  final String filename;

  final int length;

  final String name;

  _DOMMimeTypeImpl item(int index) native;

  _DOMMimeTypeImpl namedItem(String name) native;
}

class _DOMPluginArrayImpl implements DOMPluginArray native "*DOMPluginArray" {

  final int length;

  _DOMPluginImpl item(int index) native;

  _DOMPluginImpl namedItem(String name) native;

  void refresh(bool reload) native;
}

class _DOMSelectionImpl implements DOMSelection native "*DOMSelection" {

  final _NodeImpl anchorNode;

  final int anchorOffset;

  final _NodeImpl baseNode;

  final int baseOffset;

  final _NodeImpl extentNode;

  final int extentOffset;

  final _NodeImpl focusNode;

  final int focusOffset;

  final bool isCollapsed;

  final int rangeCount;

  final String type;

  void addRange(_RangeImpl range) native;

  void collapse(_NodeImpl node, int index) native;

  void collapseToEnd() native;

  void collapseToStart() native;

  bool containsNode(_NodeImpl node, bool allowPartial) native;

  void deleteFromDocument() native;

  void empty() native;

  void extend(_NodeImpl node, int offset) native;

  _RangeImpl getRangeAt(int index) native;

  void modify(String alter, String direction, String granularity) native;

  void removeAllRanges() native;

  void selectAllChildren(_NodeImpl node) native;

  void setBaseAndExtent(_NodeImpl baseNode, int baseOffset, _NodeImpl extentNode, int extentOffset) native;

  void setPosition(_NodeImpl node, int offset) native;

  String toString() native;
}

class _DOMSettableTokenListImpl extends _DOMTokenListImpl implements DOMSettableTokenList native "*DOMSettableTokenList" {

  String value;
}

class _DOMTokenListImpl implements DOMTokenList native "*DOMTokenList" {

  final int length;

  void add(String token) native;

  bool contains(String token) native;

  String item(int index) native;

  void remove(String token) native;

  String toString() native;

  bool toggle(String token) native;
}

class _DOMURLImpl implements DOMURL native "*DOMURL" {

  String createObjectURL(var blob_OR_stream) native;

  void revokeObjectURL(String url) native;
}

class _DataTransferItemImpl implements DataTransferItem native "*DataTransferItem" {

  final String kind;

  final String type;

  _BlobImpl getAsFile() native;

  void getAsString([StringCallback callback = null]) native;
}

class _DataTransferItemListImpl implements DataTransferItemList native "*DataTransferItemList" {

  final int length;

  void add(var data_OR_file, [String type = null]) native;

  void clear() native;

  _DataTransferItemImpl item(int index) native;
}

class _DataViewImpl extends _ArrayBufferViewImpl implements DataView native "*DataView" {

  num getFloat32(int byteOffset, [bool littleEndian = null]) native;

  num getFloat64(int byteOffset, [bool littleEndian = null]) native;

  int getInt16(int byteOffset, [bool littleEndian = null]) native;

  int getInt32(int byteOffset, [bool littleEndian = null]) native;

  Object getInt8() native;

  int getUint16(int byteOffset, [bool littleEndian = null]) native;

  int getUint32(int byteOffset, [bool littleEndian = null]) native;

  Object getUint8() native;

  void setFloat32(int byteOffset, num value, [bool littleEndian = null]) native;

  void setFloat64(int byteOffset, num value, [bool littleEndian = null]) native;

  void setInt16(int byteOffset, int value, [bool littleEndian = null]) native;

  void setInt32(int byteOffset, int value, [bool littleEndian = null]) native;

  void setInt8() native;

  void setUint16(int byteOffset, int value, [bool littleEndian = null]) native;

  void setUint32(int byteOffset, int value, [bool littleEndian = null]) native;

  void setUint8() native;
}

class _DatabaseImpl implements Database native "*Database" {

  final String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback = null, SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;
}

class _DatabaseSyncImpl implements DatabaseSync native "*DatabaseSync" {

  final String lastErrorMessage;

  final String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback = null]) native;

  void readTransaction(SQLTransactionSyncCallback callback) native;

  void transaction(SQLTransactionSyncCallback callback) native;
}

class _DedicatedWorkerContextImpl extends _WorkerContextImpl implements DedicatedWorkerContext native "*DedicatedWorkerContext" {

  EventListener onmessage;

  void postMessage(Object message, [List messagePorts = null]) native;

  void webkitPostMessage(Object message, [List transferList = null]) native;
}

class _DelayNodeImpl extends _AudioNodeImpl implements DelayNode native "*DelayNode" {

  final _AudioParamImpl delayTime;
}

class _DeprecatedPeerConnectionImpl implements DeprecatedPeerConnection native "*DeprecatedPeerConnection" {

  static final int ACTIVE = 2;

  static final int CLOSED = 3;

  static final int NEGOTIATING = 1;

  static final int NEW = 0;

  final _MediaStreamListImpl localStreams;

  EventListener onaddstream;

  EventListener onconnecting;

  EventListener onmessage;

  EventListener onopen;

  EventListener onremovestream;

  EventListener onstatechange;

  final int readyState;

  final _MediaStreamListImpl remoteStreams;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void addStream(_MediaStreamImpl stream) native;

  void close() native;

  bool dispatchEvent(_EventImpl event) native;

  void processSignalingMessage(String message) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void removeStream(_MediaStreamImpl stream) native;

  void send(String text) native;
}

class _DetailsElementImpl extends _ElementImpl implements DetailsElement native "*HTMLDetailsElement" {

  bool open;
}

class _DeviceMotionEventImpl extends _EventImpl implements DeviceMotionEvent native "*DeviceMotionEvent" {

  final num interval;
}

class _DeviceOrientationEventImpl extends _EventImpl implements DeviceOrientationEvent native "*DeviceOrientationEvent" {

  final bool absolute;

  final num alpha;

  final num beta;

  final num gamma;

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute) native;
}

class _DirectoryElementImpl extends _ElementImpl implements DirectoryElement native "*HTMLDirectoryElement" {

  bool compact;
}

class _DirectoryEntryImpl extends _EntryImpl implements DirectoryEntry native "*DirectoryEntry" {

  _DirectoryReaderImpl createReader() native;

  void getDirectory(String path, [Object flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getFile(String path, [Object flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback = null]) native;
}

class _DirectoryEntrySyncImpl extends _EntrySyncImpl implements DirectoryEntrySync native "*DirectoryEntrySync" {

  _DirectoryReaderSyncImpl createReader() native;

  _DirectoryEntrySyncImpl getDirectory(String path, Object flags) native;

  _FileEntrySyncImpl getFile(String path, Object flags) native;

  void removeRecursively() native;
}

class _DirectoryReaderImpl implements DirectoryReader native "*DirectoryReader" {

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback = null]) native;
}

class _DirectoryReaderSyncImpl implements DirectoryReaderSync native "*DirectoryReaderSync" {

  _EntryArraySyncImpl readEntries() native;
}

class _DivElementImpl extends _ElementImpl implements DivElement native "*HTMLDivElement" {

  String align;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _DocumentImpl extends _NodeImpl
    implements Document
    native "*HTMLDocument"
    {


  _DocumentEventsImpl get on() =>
    new _DocumentEventsImpl(this);

  final _ElementImpl activeElement;

  _ElementImpl body;

  String charset;

  String cookie;

  _WindowImpl get window() native "return this.defaultView;";

  final _ElementImpl documentElement;

  final String domain;

  final _HeadElementImpl head;

  final String lastModified;

  final String preferredStylesheetSet;

  final String readyState;

  final String referrer;

  String selectedStylesheetSet;

  final _StyleSheetListImpl styleSheets;

  String title;

  final _ElementImpl webkitCurrentFullScreenElement;

  final bool webkitFullScreenKeyboardInputAllowed;

  final _ElementImpl webkitFullscreenElement;

  final bool webkitFullscreenEnabled;

  final bool webkitHidden;

  final bool webkitIsFullScreen;

  final String webkitVisibilityState;

  _RangeImpl caretRangeFromPoint(int x, int y) native;

  _CDATASectionImpl createCDATASection(String data) native;

  _DocumentFragmentImpl createDocumentFragment() native;

  _ElementImpl $dom_createElement(String tagName) native "return this.createElement(tagName);";

  _ElementImpl $dom_createElementNS(String namespaceURI, String qualifiedName) native "return this.createElementNS(namespaceURI, qualifiedName);";

  _EventImpl $dom_createEvent(String eventType) native "return this.createEvent(eventType);";

  _RangeImpl createRange() native;

  _TextImpl $dom_createTextNode(String data) native "return this.createTextNode(data);";

  _TouchImpl createTouch(_WindowImpl window, _EventTargetImpl target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) native;

  _TouchListImpl $dom_createTouchList() native "return this.createTouchList();";

  _ElementImpl elementFromPoint(int x, int y) native;

  bool execCommand(String command, bool userInterface, String value) native;

  _CanvasRenderingContextImpl getCSSCanvasContext(String contextId, String name, int width, int height) native;

  _ElementImpl $dom_getElementById(String elementId) native "return this.getElementById(elementId);";

  _NodeListImpl $dom_getElementsByClassName(String tagname) native "return this.getElementsByClassName(tagname);";

  _NodeListImpl $dom_getElementsByName(String elementName) native "return this.getElementsByName(elementName);";

  _NodeListImpl $dom_getElementsByTagName(String tagname) native "return this.getElementsByTagName(tagname);";

  bool queryCommandEnabled(String command) native;

  bool queryCommandIndeterm(String command) native;

  bool queryCommandState(String command) native;

  bool queryCommandSupported(String command) native;

  String queryCommandValue(String command) native;

  _ElementImpl _query(String selectors) native "return this.querySelector(selectors);";

  _NodeListImpl $dom_querySelectorAll(String selectors) native "return this.querySelectorAll(selectors);";

  void webkitCancelFullScreen() native;

  void webkitExitFullscreen() native;

  _WebKitNamedFlowImpl webkitGetFlowByName(String name) native;

  // TODO(jacobr): implement all Element methods not on Document. 

  _ElementImpl query(String selectors) {
    // It is fine for our RegExp to detect element id query selectors to have
    // false negatives but not false positives.
    if (const RegExp("^#[_a-zA-Z]\\w*\$").hasMatch(selectors)) {
      return $dom_getElementById(selectors.substring(1));
    }
    return $dom_querySelector(selectors);
  }

// TODO(jacobr): autogenerate this method.
  _ElementImpl $dom_querySelector(String selectors) native "return this.querySelector(selectors);";

  ElementList queryAll(String selectors) {
    if (const RegExp("""^\\[name=["'][^'"]+['"]\\]\$""").hasMatch(selectors)) {
      final mutableMatches = $dom_getElementsByName(
          selectors.substring(7,selectors.length - 2));
      int len = mutableMatches.length;
      final copyOfMatches = new List<Element>(len);
      for (int i = 0; i < len; ++i) {
        copyOfMatches[i] = mutableMatches[i];
      }
      return new _FrozenElementList._wrap(copyOfMatches);
    } else if (const RegExp("^[*a-zA-Z0-9]+\$").hasMatch(selectors)) {
      final mutableMatches = $dom_getElementsByTagName(selectors);
      int len = mutableMatches.length;
      final copyOfMatches = new List<Element>(len);
      for (int i = 0; i < len; ++i) {
        copyOfMatches[i] = mutableMatches[i];
      }
      return new _FrozenElementList._wrap(copyOfMatches);
    } else {
      return new _FrozenElementList._wrap($dom_querySelectorAll(selectors));
    }
  }
}

class _DocumentEventsImpl extends _ElementEventsImpl implements DocumentEvents {
  _DocumentEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get beforeCopy() => _get('beforecopy');

  EventListenerList get beforeCut() => _get('beforecut');

  EventListenerList get beforePaste() => _get('beforepaste');

  EventListenerList get blur() => _get('blur');

  EventListenerList get change() => _get('change');

  EventListenerList get click() => _get('click');

  EventListenerList get contextMenu() => _get('contextmenu');

  EventListenerList get copy() => _get('copy');

  EventListenerList get cut() => _get('cut');

  EventListenerList get doubleClick() => _get('dblclick');

  EventListenerList get drag() => _get('drag');

  EventListenerList get dragEnd() => _get('dragend');

  EventListenerList get dragEnter() => _get('dragenter');

  EventListenerList get dragLeave() => _get('dragleave');

  EventListenerList get dragOver() => _get('dragover');

  EventListenerList get dragStart() => _get('dragstart');

  EventListenerList get drop() => _get('drop');

  EventListenerList get error() => _get('error');

  EventListenerList get focus() => _get('focus');

  EventListenerList get fullscreenChange() => _get('webkitfullscreenchange');

  EventListenerList get fullscreenError() => _get('webkitfullscreenerror');

  EventListenerList get input() => _get('input');

  EventListenerList get invalid() => _get('invalid');

  EventListenerList get keyDown() => _get('keydown');

  EventListenerList get keyPress() => _get('keypress');

  EventListenerList get keyUp() => _get('keyup');

  EventListenerList get load() => _get('load');

  EventListenerList get mouseDown() => _get('mousedown');

  EventListenerList get mouseMove() => _get('mousemove');

  EventListenerList get mouseOut() => _get('mouseout');

  EventListenerList get mouseOver() => _get('mouseover');

  EventListenerList get mouseUp() => _get('mouseup');

  EventListenerList get mouseWheel() => _get('mousewheel');

  EventListenerList get paste() => _get('paste');

  EventListenerList get readyStateChange() => _get('readystatechange');

  EventListenerList get reset() => _get('reset');

  EventListenerList get scroll() => _get('scroll');

  EventListenerList get search() => _get('search');

  EventListenerList get select() => _get('select');

  EventListenerList get selectStart() => _get('selectstart');

  EventListenerList get selectionChange() => _get('selectionchange');

  EventListenerList get submit() => _get('submit');

  EventListenerList get touchCancel() => _get('touchcancel');

  EventListenerList get touchEnd() => _get('touchend');

  EventListenerList get touchMove() => _get('touchmove');

  EventListenerList get touchStart() => _get('touchstart');
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FilteredElementList implements ElementList {
  final Node _node;
  final NodeList _childNodes;

  FilteredElementList(Node node): _childNodes = node.nodes, _node = node;

  // We can't memoize this, since it's possible that children will be messed
  // with externally to this class.
  //
  // TODO(nweiz): Do we really need to copy the list to make the types work out?
  List<Element> get _filtered() =>
    new List.from(_childNodes.filter((n) => n is Element));

  // Don't use _filtered.first so we can short-circuit once we find an element.
  Element get first() {
    for (final node in _childNodes) {
      if (node is Element) {
        return node;
      }
    }
    return null;
  }

  void forEach(void f(Element element)) {
    _filtered.forEach(f);
  }

  void operator []=(int index, Element value) {
    this[index].replaceWith(value);
  }

  void set length(int newLength) {
    final len = this.length;
    if (newLength >= len) {
      return;
    } else if (newLength < 0) {
      throw const IllegalArgumentException("Invalid list length");
    }

    removeRange(newLength - 1, len - newLength);
  }

  void add(Element value) {
    _childNodes.add(value);
  }

  void addAll(Collection<Element> collection) {
    collection.forEach(add);
  }

  void addLast(Element value) {
    add(value);
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('TODO(jacobr): should we impl?');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw const NotImplementedException();
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const NotImplementedException();
  }

  void removeRange(int start, int length) {
    _filtered.getRange(start, length).forEach((el) => el.remove());
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  void clear() {
    // Currently, ElementList#clear clears even non-element nodes, so we follow
    // that behavior.
    _childNodes.clear();
  }

  Element removeLast() {
    final last = this.last();
    if (last != null) {
      last.remove();
    }
    return last;
  }

  Collection map(f(Element element)) => _filtered.map(f);
  Collection<Element> filter(bool f(Element element)) => _filtered.filter(f);
  bool every(bool f(Element element)) => _filtered.every(f);
  bool some(bool f(Element element)) => _filtered.some(f);
  bool isEmpty() => _filtered.isEmpty();
  int get length() => _filtered.length;
  Element operator [](int index) => _filtered[index];
  Iterator<Element> iterator() => _filtered.iterator();
  List<Element> getRange(int start, int length) =>
    _filtered.getRange(start, length);
  int indexOf(Element element, [int start = 0]) =>
    _filtered.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) {
    if (start === null) start = length - 1;
    return _filtered.lastIndexOf(element, start);
  }

  Element last() => _filtered.last();
}

Future<CSSStyleDeclaration> _emptyStyleFuture() {
  return _createMeasurementFuture(() => new Element.tag('div').style,
                                  new Completer<CSSStyleDeclaration>());
}

class EmptyElementRect implements ElementRect {
  final ClientRect client = const _SimpleClientRect(0, 0, 0, 0);
  final ClientRect offset = const _SimpleClientRect(0, 0, 0, 0);
  final ClientRect scroll = const _SimpleClientRect(0, 0, 0, 0);
  final ClientRect bounding = const _SimpleClientRect(0, 0, 0, 0);
  final List<ClientRect> clientRects = const <ClientRect>[];

  const EmptyElementRect();
}

class _DocumentFragmentImpl extends _NodeImpl implements DocumentFragment native "*DocumentFragment" {
  ElementList _elements;

  ElementList get elements() {
    if (_elements == null) {
      _elements = new FilteredElementList(this);
    }
    return _elements;
  }

  // TODO: The type of value should be Collection<Element>. See http://b/5392897
  void set elements(value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    final elements = this.elements;
    elements.clear();
    elements.addAll(copy);
  }

  ElementList queryAll(String selectors) =>
    new _FrozenElementList._wrap($dom_querySelectorAll(selectors));

  String get innerHTML() {
    final e = new Element.tag("div");
    e.nodes.add(this.clone(true));
    return e.innerHTML;
  }

  String get outerHTML() => innerHTML;

  // TODO(nweiz): Do we want to support some variant of innerHTML for XML and/or
  // SVG strings?
  void set innerHTML(String value) {
    this.nodes.clear();

    final e = new Element.tag("div");
    e.innerHTML = value;

    // Copy list first since we don't want liveness during iteration.
    List nodes = new List.from(e.nodes);
    this.nodes.addAll(nodes);
  }

  Node _insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case "beforebegin": return null;
      case "afterend": return null;
      case "afterbegin":
        this.insertBefore(node, this.nodes.first);
        return node;
      case "beforeend":
        this.nodes.add(node);
        return node;
      default:
        throw new IllegalArgumentException("Invalid position ${where}");
    }
  }

  Element insertAdjacentElement(String where, Element element)
    => this._insertAdjacentNode(where, element);

  void insertAdjacentText(String where, String text) {
    this._insertAdjacentNode(where, new Text(text));
  }

  void insertAdjacentHTML(String where, String text) {
    this._insertAdjacentNode(where, new DocumentFragment.html(text));
  }

  Future<ElementRect> get rect() {
    return _createMeasurementFuture(() => const EmptyElementRect(),
                                    new Completer<ElementRect>());
  }

  // If we can come up with a semi-reasonable default value for an Element
  // getter, we'll use it. In general, these return the same values as an
  // element that has no parent.
  String get contentEditable() => "false";
  bool get isContentEditable() => false;
  bool get draggable() => false;
  bool get hidden() => false;
  bool get spellcheck() => false;
  bool get translate() => false;
  int get tabIndex() => -1;
  String get id() => "";
  String get title() => "";
  String get tagName() => "";
  String get webkitdropzone() => "";
  String get webkitRegionOverflow() => "";
  Element get $dom_firstElementChild() => elements.first();
  Element get $dom_lastElementChild() => elements.last();
  Element get nextElementSibling() => null;
  Element get previousElementSibling() => null;
  Element get offsetParent() => null;
  Element get parent() => null;
  Map<String, String> get attributes() => const {};
  // Issue 174: this should be a const set.
  Set<String> get classes() => new Set<String>();
  Map<String, String> get dataAttributes() => const {};
  CSSStyleDeclaration get style() => new Element.tag('div').style;
  Future<CSSStyleDeclaration> get computedStyle() =>
      _emptyStyleFuture();
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) =>
      _emptyStyleFuture();
  bool matchesSelector(String selectors) => false;

  // Imperative Element methods are made into no-ops, as they are on parentless
  // elements.
  void blur() {}
  void focus() {}
  void click() {}
  void scrollByLines(int lines) {}
  void scrollByPages(int pages) {}
  void scrollIntoView([bool centerIfNeeded]) {}
  void webkitRequestFullScreen(int flags) {}
  void webkitRequestFullscreen() {}

  // Setters throw errors rather than being no-ops because we aren't going to
  // retain the values that were set, and erroring out seems clearer.
  void set attributes(Map<String, String> value) {
    throw new UnsupportedOperationException(
      "Attributes can't be set for document fragments.");
  }

  void set classes(Collection<String> value) {
    throw new UnsupportedOperationException(
      "Classes can't be set for document fragments.");
  }

  void set dataAttributes(Map<String, String> value) {
    throw new UnsupportedOperationException(
      "Data attributes can't be set for document fragments.");
  }

  void set contentEditable(String value) {
    throw new UnsupportedOperationException(
      "Content editable can't be set for document fragments.");
  }

  String get dir() {
    throw new UnsupportedOperationException(
      "Document fragments don't support text direction.");
  }

  void set dir(String value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support text direction.");
  }

  void set draggable(bool value) {
    throw new UnsupportedOperationException(
      "Draggable can't be set for document fragments.");
  }

  void set hidden(bool value) {
    throw new UnsupportedOperationException(
      "Hidden can't be set for document fragments.");
  }

  void set id(String value) {
    throw new UnsupportedOperationException(
      "ID can't be set for document fragments.");
  }

  String get lang() {
    throw new UnsupportedOperationException(
      "Document fragments don't support language.");
  }

  void set lang(String value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support language.");
  }

  void set scrollLeft(int value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support scrolling.");
  }

  void set scrollTop(int value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support scrolling.");
  }

  void set spellcheck(bool value) {
     throw new UnsupportedOperationException(
      "Spellcheck can't be set for document fragments.");
  }

  void set translate(bool value) {
     throw new UnsupportedOperationException(
      "Spellcheck can't be set for document fragments.");
  }

  void set tabIndex(int value) {
    throw new UnsupportedOperationException(
      "Tab index can't be set for document fragments.");
  }

  void set title(String value) {
    throw new UnsupportedOperationException(
      "Title can't be set for document fragments.");
  }

  void set webkitdropzone(String value) {
    throw new UnsupportedOperationException(
      "WebKit drop zone can't be set for document fragments.");
  }

  void set webkitRegionOverflow(String value) {
    throw new UnsupportedOperationException(
      "WebKit region overflow can't be set for document fragments.");
  }


  _ElementEventsImpl get on() =>
    new _ElementEventsImpl(this);

  _ElementImpl query(String selectors) native "return this.querySelector(selectors);";

  _NodeListImpl $dom_querySelectorAll(String selectors) native "return this.querySelectorAll(selectors);";

}

class _DocumentTypeImpl extends _NodeImpl implements DocumentType native "*DocumentType" {

  final _NamedNodeMapImpl entities;

  final String internalSubset;

  final String name;

  final _NamedNodeMapImpl notations;

  final String publicId;

  final String systemId;
}

class _DynamicsCompressorNodeImpl extends _AudioNodeImpl implements DynamicsCompressorNode native "*DynamicsCompressorNode" {

  final _AudioParamImpl knee;

  final _AudioParamImpl ratio;

  final _AudioParamImpl reduction;

  final _AudioParamImpl threshold;
}

class _EXTTextureFilterAnisotropicImpl implements EXTTextureFilterAnisotropic native "*EXTTextureFilterAnisotropic" {

  static final int MAX_TEXTURE_MAX_ANISOTROPY_EXT = 0x84FF;

  static final int TEXTURE_MAX_ANISOTROPY_EXT = 0x84FE;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): use _Lists.dart to remove some of the duplicated
// functionality.
class _ChildrenElementList implements ElementList {
  // Raw Element.
  final _ElementImpl _element;
  final _HTMLCollectionImpl _childElements;

  _ChildrenElementList._wrap(_ElementImpl element)
    : _childElements = element.$dom_children,
      _element = element;

  List<Element> _toList() {
    final output = new List(_childElements.length);
    for (int i = 0, len = _childElements.length; i < len; i++) {
      output[i] = _childElements[i];
    }
    return output;
  }

  _ElementImpl get first() {
    return _element.$dom_firstElementChild;
  }

  void forEach(void f(Element element)) {
    for (_ElementImpl element in _childElements) {
      f(element);
    }
  }

  ElementList filter(bool f(Element element)) {
    final output = <Element>[];
    forEach((Element element) {
      if (f(element)) {
        output.add(element);
      }
    });
    return new _FrozenElementList._wrap(output);
  }

  bool every(bool f(Element element)) {
    for(Element element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool some(bool f(Element element)) {
    for(Element element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  Collection map(f(Element element)) {
    final out = [];
    for (Element el in this) {
      out.add(f(el));
    }
    return out;
  }

  bool isEmpty() {
    return _element.$dom_firstElementChild == null;
  }

  int get length() {
    return _childElements.length;
  }

  _ElementImpl operator [](int index) {
    return _childElements[index];
  }

  void operator []=(int index, _ElementImpl value) {
    _element.$dom_replaceChild(value, _childElements[index]);
  }

   void set length(int newLength) {
     // TODO(jacobr): remove children when length is reduced.
     throw const UnsupportedOperationException('');
   }

  Element add(_ElementImpl value) {
    _element.$dom_appendChild(value);
    return value;
  }

  Element addLast(_ElementImpl value) => add(value);

  Iterator<Element> iterator() => _toList().iterator();

  void addAll(Collection<Element> collection) {
    for (_ElementImpl element in collection) {
      _element.$dom_appendChild(element);
    }
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('TODO(jacobr): should we impl?');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const NotImplementedException();
  }

  void removeRange(int start, int length) {
    throw const NotImplementedException();
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  List getRange(int start, int length) =>
    new _FrozenElementList._wrap(_Lists.getRange(this, start, length,
        <Element>[]));

  int indexOf(Element element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Element element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    // It is unclear if we want to keep non element nodes?
    _element.text = '';
  }

  Element removeLast() {
    final last = this.last();
    if (last != null) {
      _element.$dom_removeChild(last);
    }
    return last;
  }

  Element last() {
    return _element.$dom_lastElementChild;
  }
}

// TODO(jacobr): this is an inefficient implementation but it is hard to see
// a better option given that we cannot quite force NodeList to be an
// ElementList as there are valid cases where a NodeList JavaScript object
// contains Node objects that are not Elements.
class _FrozenElementList implements ElementList {
  final List<Node> _nodeList;

  _FrozenElementList._wrap(this._nodeList);

  Element get first() {
    return _nodeList[0];
  }

  void forEach(void f(Element element)) {
    for (Element el in this) {
      f(el);
    }
  }

  Collection map(f(Element element)) {
    final out = [];
    for (Element el in this) {
      out.add(f(el));
    }
    return out;
  }

  ElementList filter(bool f(Element element)) {
    final out = new _ElementList([]);
    for (Element el in this) {
      if (f(el)) out.add(el);
    }
    return out;
  }

  bool every(bool f(Element element)) {
    for(Element element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool some(bool f(Element element)) {
    for(Element element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  bool isEmpty() => _nodeList.isEmpty();

  int get length() => _nodeList.length;

  Element operator [](int index) => _nodeList[index];

  void operator []=(int index, Element value) {
    throw const UnsupportedOperationException('');
  }

  void set length(int newLength) {
    _nodeList.length = newLength;
  }

  void add(Element value) {
    throw const UnsupportedOperationException('');
  }

  void addLast(Element value) {
    throw const UnsupportedOperationException('');
  }

  Iterator<Element> iterator() => new _FrozenElementListIterator(this);

  void addAll(Collection<Element> collection) {
    throw const UnsupportedOperationException('');
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('');
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const UnsupportedOperationException('');
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException('');
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const UnsupportedOperationException('');
  }

  ElementList getRange(int start, int length) =>
    new _FrozenElementList._wrap(_nodeList.getRange(start, length));

  int indexOf(Element element, [int start = 0]) =>
    _nodeList.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) =>
    _nodeList.lastIndexOf(element, start);

  void clear() {
    throw const UnsupportedOperationException('');
  }

  Element removeLast() {
    throw const UnsupportedOperationException('');
  }

  Element last() => _nodeList.last();
}

class _FrozenElementListIterator implements Iterator<Element> {
  final _FrozenElementList _list;
  int _index = 0;

  _FrozenElementListIterator(this._list);

  /**
   * Gets the next element in the iteration. Throws a
   * [NoMoreElementsException] if no element is left.
   */
  Element next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }

    return _list[_index++];
  }

  /**
   * Returns whether the [Iterator] has elements left.
   */
  bool hasNext() => _index < _list.length;
}

class _ElementList extends _ListWrapper<Element> implements ElementList {
  _ElementList(List<Element> list) : super(list);

  ElementList filter(bool f(Element element)) =>
    new _ElementList(super.filter(f));

  ElementList getRange(int start, int length) =>
    new _ElementList(super.getRange(start, length));
}

class _ElementAttributeMap implements AttributeMap {

  final _ElementImpl _element;

  _ElementAttributeMap(this._element);

  bool containsValue(String value) {
    final attributes = _element.$dom_attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      if(value == attributes[i].value) {
        return true;
      }
    }
    return false;
  }

  bool containsKey(String key) {
    return _element.$dom_hasAttribute(key);
  }

  String operator [](String key) {
    return _element.$dom_getAttribute(key);
  }

  void operator []=(String key, value) {
    _element.$dom_setAttribute(key, '$value');
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      this[key] = ifAbsent();
    }
  }

  String remove(String key) {
    _element.$dom_removeAttribute(key);
  }

  void clear() {
    final attributes = _element.$dom_attributes;
    for (int i = attributes.length - 1; i >= 0; i--) {
      remove(attributes[i].name);
    }
  }

  void forEach(void f(String key, String value)) {
    final attributes = _element.$dom_attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      final item = attributes[i];
      f(item.name, item.value);
    }
  }

  Collection<String> getKeys() {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element.$dom_attributes;
    final keys = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      keys[i] = attributes[i].name;
    }
    return keys;
  }

  Collection<String> getValues() {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element.$dom_attributes;
    final values = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      values[i] = attributes[i].value;
    }
    return values;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length() {
    return _element.$dom_attributes.length;
  }

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool isEmpty() {
    return length == 0;
  }
}

/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap implements AttributeMap {

  final Map<String, String> $dom_attributes;

  _DataAttributeMap(this.$dom_attributes);

  // interface Map

  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(String value) => getValues().some((v) => v == value);

  bool containsKey(String key) => $dom_attributes.containsKey(_attr(key));

  String operator [](String key) => $dom_attributes[_attr(key)];

  void operator []=(String key, value) {
    $dom_attributes[_attr(key)] = '$value';
  }

  String putIfAbsent(String key, String ifAbsent()) {
    $dom_attributes.putIfAbsent(_attr(key), ifAbsent);
  }

  String remove(String key) => $dom_attributes.remove(_attr(key));

  void clear() {
    // Needs to operate on a snapshot since we are mutating the collection.
    for (String key in getKeys()) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        f(_strip(key), value);
      }
    });
  }

  Collection<String> getKeys() {
    final keys = new List<String>();
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        keys.add(_strip(key));
      }
    });
    return keys;
  }

  Collection<String> getValues() {
    final values = new List<String>();
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        values.add(value);
      }
    });
    return values;
  }

  int get length() => getKeys().length;

  // TODO: Use lazy iterator when it is available on Map.
  bool isEmpty() => length == 0;

  // Helpers.
  String _attr(String key) => 'data-$key';
  bool _matches(String key) => key.startsWith('data-');
  String _strip(String key) => key.substring(5);
}

class _CssClassSet implements Set<String> {

  final _ElementImpl _element;

  _CssClassSet(this._element);

  String toString() => _formatSet(_read());

  // interface Iterable - BEGIN
  Iterator<String> iterator() => _read().iterator();
  // interface Iterable - END

  // interface Collection - BEGIN
  void forEach(void f(String element)) {
    _read().forEach(f);
  }

  Collection map(f(String element)) => _read().map(f);

  Collection<String> filter(bool f(String element)) => _read().filter(f);

  bool every(bool f(String element)) => _read().every(f);

  bool some(bool f(String element)) => _read().some(f);

  bool isEmpty() => _read().isEmpty();

  int get length() =>_read().length;

  // interface Collection - END

  // interface Set - BEGIN
  bool contains(String value) => _read().contains(value);

  void add(String value) {
    // TODO - figure out if we need to do any validation here
    // or if the browser natively does enough
    _modify((s) => s.add(value));
  }

  bool remove(String value) {
    Set<String> s = _read();
    bool result = s.remove(value);
    _write(s);
    return result;
  }

  void addAll(Collection<String> collection) {
    // TODO - see comment above about validation
    _modify((s) => s.addAll(collection));
  }

  void removeAll(Collection<String> collection) {
    _modify((s) => s.removeAll(collection));
  }

  bool isSubsetOf(Collection<String> collection) =>
    _read().isSubsetOf(collection);

  bool containsAll(Collection<String> collection) =>
    _read().containsAll(collection);

  Set<String> intersection(Collection<String> other) =>
    _read().intersection(other);

  void clear() {
    _modify((s) => s.clear());
  }
  // interface Set - END

  /**
   * Helper method used to modify the set of css classes on this element.
   *
   *   f - callback with:
   *      s - a Set of all the css class name currently on this element.
   *
   *   After f returns, the modified set is written to the
   *       className property of this element.
   */
  void _modify( f(Set<String> s)) {
    Set<String> s = _read();
    f(s);
    _write(s);
  }

  /**
   * Read the class names from the Element class property,
   * and put them into a set (duplicates are discarded).
   */
  Set<String> _read() {
    // TODO(mattsh) simplify this once split can take regex.
    Set<String> s = new Set<String>();
    for (String name in _classname().split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty()) {
        s.add(trimmed);
      }
    }
    return s;
  }

  /**
   * Read the class names as a space-separated string. This is meant to be
   * overridden by subclasses.
   */
  String _classname() => _element.$dom_className;

  /**
   * Join all the elements of a set into one string and write
   * back to the element.
   */
  void _write(Set s) {
    _element.$dom_className = _formatSet(s);
  }

  String _formatSet(Set<String> s) {
    // TODO(mattsh) should be able to pass Set to String.joins http:/b/5398605
    List list = new List.from(s);
    return Strings.join(list, ' ');
  }
}

class _SimpleClientRect implements ClientRect {
  final num left;
  final num top;
  final num width;
  final num height;
  num get right() => left + width;
  num get bottom() => top + height;

  const _SimpleClientRect(this.left, this.top, this.width, this.height);

  bool operator ==(ClientRect other) {
    return other !== null && left == other.left && top == other.top
        && width == other.width && height == other.height;
  }

  String toString() => "($left, $top, $width, $height)";
}

// TODO(jacobr): we cannot currently be lazy about calculating the client
// rects as we must perform all measurement queries at a safe point to avoid
// triggering unneeded layouts.
/**
 * All your element measurement needs in one place
 * @domName none
 */
class _ElementRectImpl implements ElementRect {
  final ClientRect client;
  final ClientRect offset;
  final ClientRect scroll;

  // TODO(jacobr): should we move these outside of ElementRect to avoid the
  // overhead of computing them every time even though they are rarely used.
  final _ClientRectImpl _boundingClientRect; 
  final _ClientRectListImpl _clientRects;

  _ElementRectImpl(_ElementImpl element) :
    client = new _SimpleClientRect(element.$dom_clientLeft,
                                  element.$dom_clientTop,
                                  element.$dom_clientWidth, 
                                  element.$dom_clientHeight), 
    offset = new _SimpleClientRect(element.$dom_offsetLeft,
                                  element.$dom_offsetTop,
                                  element.$dom_offsetWidth,
                                  element.$dom_offsetHeight),
    scroll = new _SimpleClientRect(element.$dom_scrollLeft,
                                  element.$dom_scrollTop,
                                  element.$dom_scrollWidth,
                                  element.$dom_scrollHeight),
    _boundingClientRect = element.$dom_getBoundingClientRect(),
    _clientRects = element.$dom_getClientRects();

  _ClientRectImpl get bounding() => _boundingClientRect;

  // TODO(jacobr): cleanup.
  List<ClientRect> get clientRects() {
    final out = new List(_clientRects.length);
    for (num i = 0; i < _clientRects.length; i++) {
      out[i] = _clientRects.item(i);
    }
    return out;
  }
}

class _ElementImpl extends _NodeImpl implements Element native "*Element" {

  /**
   * @domName Element.hasAttribute, Element.getAttribute, Element.setAttribute,
   *   Element.removeAttribute
   */
  _ElementAttributeMap get attributes() => new _ElementAttributeMap(this);

  void set attributes(Map<String, String> value) {
    Map<String, String> attributes = this.attributes;
    attributes.clear();
    for (String key in value.getKeys()) {
      attributes[key] = value[key];
    }
  }

  void set elements(Collection<Element> value) {
    final elements = this.elements;
    elements.clear();
    elements.addAll(value);
  }

  ElementList get elements() => new _ChildrenElementList._wrap(this);

  ElementList queryAll(String selectors) =>
    new _FrozenElementList._wrap($dom_querySelectorAll(selectors));

  _CssClassSet get classes() => new _CssClassSet(this);

  void set classes(Collection<String> value) {
    _CssClassSet classSet = classes;
    classSet.clear();
    classSet.addAll(value);
  }

  Map<String, String> get dataAttributes() =>
    new _DataAttributeMap(attributes);

  void set dataAttributes(Map<String, String> value) {
    final dataAttributes = this.dataAttributes;
    dataAttributes.clear();
    for (String key in value.getKeys()) {
      dataAttributes[key] = value[key];
    }
  }

  Future<ElementRect> get rect() {
    return _createMeasurementFuture(
        () => new _ElementRectImpl(this),
        new Completer<ElementRect>());
  }

  Future<CSSStyleDeclaration> get computedStyle() {
     // TODO(jacobr): last param should be null, see b/5045788
     return getComputedStyle('');
  }

  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) {
    return _createMeasurementFuture(
        () => _window.$dom_getComputedStyle(this, pseudoElement),
        new Completer<CSSStyleDeclaration>());
  }

  _ElementEventsImpl get on() =>
    new _ElementEventsImpl(this);

  static final int ALLOW_KEYBOARD_INPUT = 1;

  int get $dom_childElementCount() native "return this.childElementCount;";

  _HTMLCollectionImpl get $dom_children() native "return this.children;";

  String get $dom_className() native "return this.className;";

  void set $dom_className(String value) native "this.className = value;";

  int get $dom_clientHeight() native "return this.clientHeight;";

  int get $dom_clientLeft() native "return this.clientLeft;";

  int get $dom_clientTop() native "return this.clientTop;";

  int get $dom_clientWidth() native "return this.clientWidth;";

  String contentEditable;

  String dir;

  bool draggable;

  _ElementImpl get $dom_firstElementChild() native "return this.firstElementChild;";

  bool hidden;

  String id;

  String innerHTML;

  final bool isContentEditable;

  String lang;

  _ElementImpl get $dom_lastElementChild() native "return this.lastElementChild;";

  final _ElementImpl nextElementSibling;

  int get $dom_offsetHeight() native "return this.offsetHeight;";

  int get $dom_offsetLeft() native "return this.offsetLeft;";

  final _ElementImpl offsetParent;

  int get $dom_offsetTop() native "return this.offsetTop;";

  int get $dom_offsetWidth() native "return this.offsetWidth;";

  final String outerHTML;

  final _ElementImpl previousElementSibling;

  int get $dom_scrollHeight() native "return this.scrollHeight;";

  int get $dom_scrollLeft() native "return this.scrollLeft;";

  void set $dom_scrollLeft(int value) native "this.scrollLeft = value;";

  int get $dom_scrollTop() native "return this.scrollTop;";

  void set $dom_scrollTop(int value) native "this.scrollTop = value;";

  int get $dom_scrollWidth() native "return this.scrollWidth;";

  bool spellcheck;

  final _CSSStyleDeclarationImpl style;

  int tabIndex;

  final String tagName;

  String title;

  bool translate;

  final String webkitRegionOverflow;

  String webkitdropzone;

  void blur() native;

  void click() native;

  void focus() native;

  String $dom_getAttribute(String name) native "return this.getAttribute(name);";

  _ClientRectImpl $dom_getBoundingClientRect() native "return this.getBoundingClientRect();";

  _ClientRectListImpl $dom_getClientRects() native "return this.getClientRects();";

  _NodeListImpl $dom_getElementsByClassName(String name) native "return this.getElementsByClassName(name);";

  _NodeListImpl $dom_getElementsByTagName(String name) native "return this.getElementsByTagName(name);";

  bool $dom_hasAttribute(String name) native "return this.hasAttribute(name);";

  _ElementImpl insertAdjacentElement(String where, _ElementImpl element) native;

  void insertAdjacentHTML(String where, String html) native;

  void insertAdjacentText(String where, String text) native;

  _ElementImpl query(String selectors) native "return this.querySelector(selectors);";

  _NodeListImpl $dom_querySelectorAll(String selectors) native "return this.querySelectorAll(selectors);";

  void $dom_removeAttribute(String name) native "this.removeAttribute(name);";

  void scrollByLines(int lines) native;

  void scrollByPages(int pages) native;

  void scrollIntoView([bool centerIfNeeded = null]) native "this.scrollIntoViewIfNeeded(centerIfNeeded);";

  void $dom_setAttribute(String name, String value) native "this.setAttribute(name, value);";

  bool matchesSelector(String selectors) native "return this.webkitMatchesSelector(selectors);";

  void webkitRequestFullScreen(int flags) native;

  void webkitRequestFullscreen() native;

}

final _START_TAG_REGEXP = const RegExp('<(\\w+)');
class _ElementFactoryProvider {
  static final _CUSTOM_PARENT_TAG_MAP = const {
    'body' : 'html',
    'head' : 'html',
    'caption' : 'table',
    'td': 'tr',
    'colgroup': 'table',
    'col' : 'colgroup',
    'tr' : 'tbody',
    'tbody' : 'table',
    'tfoot' : 'table',
    'thead' : 'table',
    'track' : 'audio',
  };

  /** @domName Document.createElement */
  factory Element.html(String html) {
    // TODO(jacobr): this method can be made more robust and performant.
    // 1) Cache the dummy parent elements required to use innerHTML rather than
    //    creating them every call.
    // 2) Verify that the html does not contain leading or trailing text nodes.
    // 3) Verify that the html does not contain both <head> and <body> tags.
    // 4) Detatch the created element from its dummy parent.
    String parentTag = 'div';
    String tag;
    final match = _START_TAG_REGEXP.firstMatch(html);
    if (match !== null) {
      tag = match.group(1).toLowerCase();
      if (_CUSTOM_PARENT_TAG_MAP.containsKey(tag)) {
        parentTag = _CUSTOM_PARENT_TAG_MAP[tag];
      }
    }
    final _ElementImpl temp = new Element.tag(parentTag);
    temp.innerHTML = html;

    Element element;
    if (temp.elements.length == 1) {
      element = temp.elements.first;
    } else if (parentTag == 'html' && temp.elements.length == 2) {
      // Work around for edge case in WebKit and possibly other browsers where
      // both body and head elements are created even though the inner html
      // only contains a head or body element.
      element = temp.elements[tag == 'head' ? 0 : 1];
    } else {
      throw new IllegalArgumentException('HTML had ${temp.elements.length} ' +
          'top level elements but 1 expected');
    }
    element.remove();
    return element;
  }

  /** @domName Document.createElement */
  // Optimization to improve performance until the frog compiler inlines this
  // method.
  factory Element.tag(String tag) native "return document.createElement(tag)";
}

class _ElementEventsImpl extends _EventsImpl implements ElementEvents {
  _ElementEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get beforeCopy() => _get('beforecopy');

  EventListenerList get beforeCut() => _get('beforecut');

  EventListenerList get beforePaste() => _get('beforepaste');

  EventListenerList get blur() => _get('blur');

  EventListenerList get change() => _get('change');

  EventListenerList get click() => _get('click');

  EventListenerList get contextMenu() => _get('contextmenu');

  EventListenerList get copy() => _get('copy');

  EventListenerList get cut() => _get('cut');

  EventListenerList get doubleClick() => _get('dblclick');

  EventListenerList get drag() => _get('drag');

  EventListenerList get dragEnd() => _get('dragend');

  EventListenerList get dragEnter() => _get('dragenter');

  EventListenerList get dragLeave() => _get('dragleave');

  EventListenerList get dragOver() => _get('dragover');

  EventListenerList get dragStart() => _get('dragstart');

  EventListenerList get drop() => _get('drop');

  EventListenerList get error() => _get('error');

  EventListenerList get focus() => _get('focus');

  EventListenerList get fullscreenChange() => _get('webkitfullscreenchange');

  EventListenerList get fullscreenError() => _get('webkitfullscreenerror');

  EventListenerList get input() => _get('input');

  EventListenerList get invalid() => _get('invalid');

  EventListenerList get keyDown() => _get('keydown');

  EventListenerList get keyPress() => _get('keypress');

  EventListenerList get keyUp() => _get('keyup');

  EventListenerList get load() => _get('load');

  EventListenerList get mouseDown() => _get('mousedown');

  EventListenerList get mouseMove() => _get('mousemove');

  EventListenerList get mouseOut() => _get('mouseout');

  EventListenerList get mouseOver() => _get('mouseover');

  EventListenerList get mouseUp() => _get('mouseup');

  EventListenerList get mouseWheel() => _get('mousewheel');

  EventListenerList get paste() => _get('paste');

  EventListenerList get reset() => _get('reset');

  EventListenerList get scroll() => _get('scroll');

  EventListenerList get search() => _get('search');

  EventListenerList get select() => _get('select');

  EventListenerList get selectStart() => _get('selectstart');

  EventListenerList get submit() => _get('submit');

  EventListenerList get touchCancel() => _get('touchcancel');

  EventListenerList get touchEnd() => _get('touchend');

  EventListenerList get touchLeave() => _get('touchleave');

  EventListenerList get touchMove() => _get('touchmove');

  EventListenerList get touchStart() => _get('touchstart');

  EventListenerList get transitionEnd() => _get('webkitTransitionEnd');
}

class _ElementTimeControlImpl implements ElementTimeControl native "*ElementTimeControl" {

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;
}

class _ElementTraversalImpl implements ElementTraversal native "*ElementTraversal" {

  final int childElementCount;

  final _ElementImpl firstElementChild;

  final _ElementImpl lastElementChild;

  final _ElementImpl nextElementSibling;

  final _ElementImpl previousElementSibling;
}

class _EmbedElementImpl extends _ElementImpl implements EmbedElement native "*HTMLEmbedElement" {

  String align;

  String height;

  String name;

  String src;

  String type;

  String width;
}

class _EntityImpl extends _NodeImpl implements Entity native "*Entity" {

  final String notationName;

  final String publicId;

  final String systemId;
}

class _EntityReferenceImpl extends _NodeImpl implements EntityReference native "*EntityReference" {
}

class _EntryImpl implements Entry native "*Entry" {

  final _DOMFileSystemImpl filesystem;

  final String fullPath;

  final bool isDirectory;

  final bool isFile;

  final String name;

  void copyTo(_DirectoryEntryImpl parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void getParent([EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void moveTo(_DirectoryEntryImpl parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void remove(VoidCallback successCallback, [ErrorCallback errorCallback = null]) native;

  String toURL() native;
}

class _EntryArrayImpl implements EntryArray native "*EntryArray" {

  final int length;

  _EntryImpl item(int index) native;
}

class _EntryArraySyncImpl implements EntryArraySync native "*EntryArraySync" {

  final int length;

  _EntrySyncImpl item(int index) native;
}

class _EntrySyncImpl implements EntrySync native "*EntrySync" {

  final _DOMFileSystemSyncImpl filesystem;

  final String fullPath;

  final bool isDirectory;

  final bool isFile;

  final String name;

  _EntrySyncImpl copyTo(_DirectoryEntrySyncImpl parent, String name) native;

  _MetadataImpl getMetadata() native;

  _DirectoryEntrySyncImpl getParent() native;

  _EntrySyncImpl moveTo(_DirectoryEntrySyncImpl parent, String name) native;

  void remove() native;

  String toURL() native;
}

class _ErrorEventImpl extends _EventImpl implements ErrorEvent native "*ErrorEvent" {

  final String filename;

  final int lineno;

  final String message;
}

class _EventImpl implements Event native "*Event" {

  static final int AT_TARGET = 2;

  static final int BLUR = 8192;

  static final int BUBBLING_PHASE = 3;

  static final int CAPTURING_PHASE = 1;

  static final int CHANGE = 32768;

  static final int CLICK = 64;

  static final int DBLCLICK = 128;

  static final int DRAGDROP = 2048;

  static final int FOCUS = 4096;

  static final int KEYDOWN = 256;

  static final int KEYPRESS = 1024;

  static final int KEYUP = 512;

  static final int MOUSEDOWN = 1;

  static final int MOUSEDRAG = 32;

  static final int MOUSEMOVE = 16;

  static final int MOUSEOUT = 8;

  static final int MOUSEOVER = 4;

  static final int MOUSEUP = 2;

  static final int SELECT = 16384;

  final bool bubbles;

  bool cancelBubble;

  final bool cancelable;

  final _ClipboardImpl clipboardData;

  final _EventTargetImpl currentTarget;

  final bool defaultPrevented;

  final int eventPhase;

  bool returnValue;

  final _EventTargetImpl srcElement;

  final _EventTargetImpl target;

  final int timeStamp;

  final String type;

  void $dom_initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) native "this.initEvent(eventTypeArg, canBubbleArg, cancelableArg);";

  void preventDefault() native;

  void stopImmediatePropagation() native;

  void stopPropagation() native;
}

class _EventExceptionImpl implements EventException native "*EventException" {

  static final int DISPATCH_REQUEST_ERR = 1;

  static final int UNSPECIFIED_EVENT_TYPE_ERR = 0;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _EventSourceImpl extends _EventTargetImpl implements EventSource native "*EventSource" {

  _EventSourceEventsImpl get on() =>
    new _EventSourceEventsImpl(this);

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  final String URL;

  final int readyState;

  final String url;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  void close() native;

  bool $dom_dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";
}

class _EventSourceEventsImpl extends _EventsImpl implements EventSourceEvents {
  _EventSourceEventsImpl(_ptr) : super(_ptr);

  EventListenerList get error() => _get('error');

  EventListenerList get message() => _get('message');

  EventListenerList get open() => _get('open');
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _EventsImpl implements Events {
  /* Raw event target. */
  // TODO(jacobr): it would be nice if we could specify this as
  // _EventTargetImpl or EventTarget
  final var _ptr;

  _EventsImpl(this._ptr);

  _EventListenerListImpl operator [](String type) => _get(type.toLowerCase());
  
  _EventListenerListImpl _get(String type) {
    return new _EventListenerListImpl(_ptr, type);
  }
}

class _EventListenerListImpl implements EventListenerList {
  
  // TODO(jacobr): make this _EventTargetImpl
  final var _ptr;
  final String _type;

  _EventListenerListImpl(this._ptr, this._type);

  // TODO(jacobr): implement equals.

  _EventListenerListImpl add(EventListener listener,
      [bool useCapture = false]) {
    _add(listener, useCapture);
    return this;
  }

  _EventListenerListImpl remove(EventListener listener,
      [bool useCapture = false]) {
    _remove(listener, useCapture);
    return this;
  }

  bool dispatch(Event evt) {
    // TODO(jacobr): what is the correct behavior here. We could alternately
    // force the event to have the expected type.
    assert(evt.type == _type);
    return _ptr.$dom_dispatchEvent(evt);
  }

  void _add(EventListener listener, bool useCapture) {
    _ptr.$dom_addEventListener(_type, listener, useCapture);
  }

  void _remove(EventListener listener, bool useCapture) {
    _ptr.$dom_removeEventListener(_type, listener, useCapture);
  }
}


class _EventTargetImpl implements EventTarget native "*EventTarget" {

  Events get on() => new _EventsImpl(this);

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  bool $dom_dispatchEvent(_EventImpl event) native "return this.dispatchEvent(event);";

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

}

class _FieldSetElementImpl extends _ElementImpl implements FieldSetElement native "*HTMLFieldSetElement" {

  final _FormElementImpl form;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateImpl validity;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class _FileImpl extends _BlobImpl implements File native "*File" {

  final Date lastModifiedDate;

  final String name;

  final String webkitRelativePath;
}

class _FileEntryImpl extends _EntryImpl implements FileEntry native "*FileEntry" {

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void file(FileCallback successCallback, [ErrorCallback errorCallback = null]) native;
}

class _FileEntrySyncImpl extends _EntrySyncImpl implements FileEntrySync native "*FileEntrySync" {

  _FileWriterSyncImpl createWriter() native;

  _FileImpl file() native;
}

class _FileErrorImpl implements FileError native "*FileError" {

  static final int ABORT_ERR = 3;

  static final int ENCODING_ERR = 5;

  static final int INVALID_MODIFICATION_ERR = 9;

  static final int INVALID_STATE_ERR = 7;

  static final int NOT_FOUND_ERR = 1;

  static final int NOT_READABLE_ERR = 4;

  static final int NO_MODIFICATION_ALLOWED_ERR = 6;

  static final int PATH_EXISTS_ERR = 12;

  static final int QUOTA_EXCEEDED_ERR = 10;

  static final int SECURITY_ERR = 2;

  static final int SYNTAX_ERR = 8;

  static final int TYPE_MISMATCH_ERR = 11;

  final int code;
}

class _FileExceptionImpl implements FileException native "*FileException" {

  static final int ABORT_ERR = 3;

  static final int ENCODING_ERR = 5;

  static final int INVALID_MODIFICATION_ERR = 9;

  static final int INVALID_STATE_ERR = 7;

  static final int NOT_FOUND_ERR = 1;

  static final int NOT_READABLE_ERR = 4;

  static final int NO_MODIFICATION_ALLOWED_ERR = 6;

  static final int PATH_EXISTS_ERR = 12;

  static final int QUOTA_EXCEEDED_ERR = 10;

  static final int SECURITY_ERR = 2;

  static final int SYNTAX_ERR = 8;

  static final int TYPE_MISMATCH_ERR = 11;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _FileListImpl implements FileList native "*FileList" {

  final int length;

  _FileImpl item(int index) native;
}

class _FileReaderImpl implements FileReader native "*FileReader" {

  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  final _FileErrorImpl error;

  EventListener onabort;

  EventListener onerror;

  EventListener onload;

  EventListener onloadend;

  EventListener onloadstart;

  EventListener onprogress;

  final int readyState;

  final Object result;

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  void readAsArrayBuffer(_BlobImpl blob) native;

  void readAsBinaryString(_BlobImpl blob) native;

  void readAsDataURL(_BlobImpl blob) native;

  void readAsText(_BlobImpl blob, [String encoding = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _FileReaderSyncImpl implements FileReaderSync native "*FileReaderSync" {

  _ArrayBufferImpl readAsArrayBuffer(_BlobImpl blob) native;

  String readAsBinaryString(_BlobImpl blob) native;

  String readAsDataURL(_BlobImpl blob) native;

  String readAsText(_BlobImpl blob, [String encoding = null]) native;
}

class _FileWriterImpl implements FileWriter native "*FileWriter" {

  static final int DONE = 2;

  static final int INIT = 0;

  static final int WRITING = 1;

  final _FileErrorImpl error;

  final int length;

  EventListener onabort;

  EventListener onerror;

  EventListener onprogress;

  EventListener onwrite;

  EventListener onwriteend;

  EventListener onwritestart;

  final int position;

  final int readyState;

  void abort() native;

  void seek(int position) native;

  void truncate(int size) native;

  void write(_BlobImpl data) native;
}

class _FileWriterSyncImpl implements FileWriterSync native "*FileWriterSync" {

  final int length;

  final int position;

  void seek(int position) native;

  void truncate(int size) native;

  void write(_BlobImpl data) native;
}

class _Float32ArrayImpl extends _ArrayBufferViewImpl implements Float32Array, List<num> native "*Float32Array" {

  factory Float32Array(int length) =>  _construct_Float32Array(length);

  factory Float32Array.fromList(List<num> list) => _construct_Float32Array(list);

  factory Float32Array.fromBuffer(ArrayBuffer buffer) => _construct_Float32Array(buffer);

  static _construct_Float32Array(arg) native 'return new Float32Array(arg);';

  static final int BYTES_PER_ELEMENT = 4;

  final int length;

  num operator[](int index) native "return this[index];";

  void operator[]=(int index, num value) native "this[index] = value";
  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<num>(this);
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<num> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(num element)) => _Collections.forEach(this, f);

  Collection map(f(num element)) => _Collections.map(this, [], f);

  Collection<num> filter(bool f(num element)) =>
     _Collections.filter(this, <num>[], f);

  bool every(bool f(num element)) => _Collections.every(this, f);

  bool some(bool f(num element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<num>:

  void sort(int compare(num a, num b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  num last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<num> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [num initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<num> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <num>[]);

  // -- end List<num> mixins.

  void setElements(Object array, [int offset = null]) native;

  _Float32ArrayImpl subarray(int start, [int end = null]) native;
}

class _Float64ArrayImpl extends _ArrayBufferViewImpl implements Float64Array, List<num> native "*Float64Array" {

  factory Float64Array(int length) =>  _construct_Float64Array(length);

  factory Float64Array.fromList(List<num> list) => _construct_Float64Array(list);

  factory Float64Array.fromBuffer(ArrayBuffer buffer) => _construct_Float64Array(buffer);

  static _construct_Float64Array(arg) native 'return new Float64Array(arg);';

  static final int BYTES_PER_ELEMENT = 8;

  final int length;

  num operator[](int index) native "return this[index];";

  void operator[]=(int index, num value) native "this[index] = value";
  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<num>(this);
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<num> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(num element)) => _Collections.forEach(this, f);

  Collection map(f(num element)) => _Collections.map(this, [], f);

  Collection<num> filter(bool f(num element)) =>
     _Collections.filter(this, <num>[], f);

  bool every(bool f(num element)) => _Collections.every(this, f);

  bool some(bool f(num element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<num>:

  void sort(int compare(num a, num b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  num last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<num> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [num initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<num> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <num>[]);

  // -- end List<num> mixins.

  void setElements(Object array, [int offset = null]) native;

  _Float64ArrayImpl subarray(int start, [int end = null]) native;
}

class _FontElementImpl extends _ElementImpl implements FontElement native "*HTMLFontElement" {

  String color;

  String face;

  String size;
}

class _FormElementImpl extends _ElementImpl implements FormElement native "*HTMLFormElement" {

  String acceptCharset;

  String action;

  String autocomplete;

  String encoding;

  String enctype;

  final int length;

  String method;

  String name;

  bool noValidate;

  String target;

  bool checkValidity() native;

  void reset() native;

  void submit() native;
}

class _FrameElementImpl extends _ElementImpl implements FrameElement native "*HTMLFrameElement" {

  final _DocumentImpl contentDocument;

  final _WindowImpl contentWindow;

  String frameBorder;

  final int height;

  String location;

  String longDesc;

  String marginHeight;

  String marginWidth;

  String name;

  bool noResize;

  String scrolling;

  String src;

  final int width;

  _SVGDocumentImpl getSVGDocument() native;
}

class _FrameSetElementImpl extends _ElementImpl implements FrameSetElement native "*HTMLFrameSetElement" {

  _FrameSetElementEventsImpl get on() =>
    new _FrameSetElementEventsImpl(this);

  String cols;

  String rows;
}

class _FrameSetElementEventsImpl extends _ElementEventsImpl implements FrameSetElementEvents {
  _FrameSetElementEventsImpl(_ptr) : super(_ptr);

  EventListenerList get beforeUnload() => _get('beforeunload');

  EventListenerList get blur() => _get('blur');

  EventListenerList get error() => _get('error');

  EventListenerList get focus() => _get('focus');

  EventListenerList get hashChange() => _get('hashchange');

  EventListenerList get load() => _get('load');

  EventListenerList get message() => _get('message');

  EventListenerList get offline() => _get('offline');

  EventListenerList get online() => _get('online');

  EventListenerList get popState() => _get('popstate');

  EventListenerList get resize() => _get('resize');

  EventListenerList get storage() => _get('storage');

  EventListenerList get unload() => _get('unload');
}

class _GeolocationImpl implements Geolocation native "*Geolocation" {

  void clearWatch(int watchId) native;

  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) native;

  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) native;
}

class _GeopositionImpl implements Geoposition native "*Geoposition" {

  final _CoordinatesImpl coords;

  final int timestamp;
}

class _HRElementImpl extends _ElementImpl implements HRElement native "*HTMLHRElement" {

  String align;

  bool noShade;

  String size;

  String width;
}

class _HTMLAllCollectionImpl implements HTMLAllCollection native "*HTMLAllCollection" {

  final int length;

  _NodeImpl item(int index) native;

  _NodeImpl namedItem(String name) native;

  _NodeListImpl tags(String name) native;
}

class _HTMLCollectionImpl implements HTMLCollection native "*HTMLCollection" {

  final int length;

  _NodeImpl operator[](int index) native "return this[index];";

  void operator[]=(int index, _NodeImpl value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     _Collections.filter(this, <Node>[], f);

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<Node>:

  void sort(int compare(Node a, Node b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  Node last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<Node> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [Node initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<Node> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <Node>[]);

  // -- end List<Node> mixins.

  _NodeImpl item(int index) native;

  _NodeImpl namedItem(String name) native;
}

class _HTMLOptionsCollectionImpl extends _HTMLCollectionImpl implements HTMLOptionsCollection native "*HTMLOptionsCollection" {

  // Shadowing definition.
  int get length() native "return this.length;";

  void set length(int value) native "this.length = value;";

  int selectedIndex;

  void remove(int index) native;
}

class _HashChangeEventImpl extends _EventImpl implements HashChangeEvent native "*HashChangeEvent" {

  final String newURL;

  final String oldURL;

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native;
}

class _HeadElementImpl extends _ElementImpl implements HeadElement native "*HTMLHeadElement" {

  String profile;
}

class _HeadingElementImpl extends _ElementImpl implements HeadingElement native "*HTMLHeadingElement" {

  String align;
}

class _HighPass2FilterNodeImpl extends _AudioNodeImpl implements HighPass2FilterNode native "*HighPass2FilterNode" {

  final _AudioParamImpl cutoff;

  final _AudioParamImpl resonance;
}

class _HistoryImpl implements History native "*History" {

  final int length;

  final Dynamic state;

  void back() native;

  void forward() native;

  void go(int distance) native;

  void pushState(Object data, String title, [String url = null]) native;

  void replaceState(Object data, String title, [String url = null]) native;
}

class _HtmlElementImpl extends _ElementImpl implements HtmlElement native "*HTMLHtmlElement" {
}

class _IDBAnyImpl implements IDBAny native "*IDBAny" {
}

class _IDBCursorImpl implements IDBCursor native "*IDBCursor" {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

  final int direction;

  final _IDBKeyImpl key;

  final _IDBKeyImpl primaryKey;

  final _IDBAnyImpl source;

  void continueFunction([_IDBKeyImpl key = null]) native;

  _IDBRequestImpl delete() native;

  _IDBRequestImpl update(Dynamic value) native;
}

class _IDBCursorWithValueImpl extends _IDBCursorImpl implements IDBCursorWithValue native "*IDBCursorWithValue" {

  final _IDBAnyImpl value;
}

class _IDBDatabaseImpl implements IDBDatabase native "*IDBDatabase" {

  final String name;

  final List<String> objectStoreNames;

  EventListener onabort;

  EventListener onerror;

  EventListener onversionchange;

  final String version;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  _IDBObjectStoreImpl createObjectStore(String name) native;

  void deleteObjectStore(String name) native;

  bool dispatchEvent(_EventImpl evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  _IDBVersionChangeRequestImpl setVersion(String version) native;

  _IDBTransactionImpl transaction(var storeName_OR_storeNames, [int mode = null]) native;
}

class _IDBDatabaseErrorImpl implements IDBDatabaseError native "*IDBDatabaseError" {

  int code;

  String message;
}

class _IDBDatabaseExceptionImpl implements IDBDatabaseException native "*IDBDatabaseException" {

  static final int ABORT_ERR = 8;

  static final int CONSTRAINT_ERR = 4;

  static final int DATA_ERR = 5;

  static final int NON_TRANSIENT_ERR = 2;

  static final int NOT_ALLOWED_ERR = 6;

  static final int NOT_FOUND_ERR = 3;

  static final int NO_ERR = 0;

  static final int QUOTA_ERR = 11;

  static final int READ_ONLY_ERR = 9;

  static final int TIMEOUT_ERR = 10;

  static final int TRANSACTION_INACTIVE_ERR = 7;

  static final int UNKNOWN_ERR = 1;

  static final int VER_ERR = 12;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _IDBFactoryImpl implements IDBFactory native "*IDBFactory" {

  int cmp(_IDBKeyImpl first, _IDBKeyImpl second) native;

  _IDBVersionChangeRequestImpl deleteDatabase(String name) native;

  _IDBRequestImpl getDatabaseNames() native;

  _IDBRequestImpl open(String name) native;
}

class _IDBIndexImpl implements IDBIndex native "*IDBIndex" {

  final String keyPath;

  final bool multiEntry;

  final String name;

  final _IDBObjectStoreImpl objectStore;

  final bool unique;

  _IDBRequestImpl count([var key_OR_range = null]) native;

  _IDBRequestImpl getObject(_IDBKeyImpl key) native;

  _IDBRequestImpl getKey(_IDBKeyImpl key) native;

  _IDBRequestImpl openCursor([_IDBKeyRangeImpl range = null, int direction = null]) native;

  _IDBRequestImpl openKeyCursor([_IDBKeyRangeImpl range = null, int direction = null]) native;
}

class _IDBKeyImpl implements IDBKey native "*IDBKey" {
}

class _IDBKeyRangeImpl implements IDBKeyRange native "*IDBKeyRange" {

  final _IDBKeyImpl lower;

  final bool lowerOpen;

  final _IDBKeyImpl upper;

  final bool upperOpen;

  _IDBKeyRangeImpl bound(_IDBKeyImpl lower, _IDBKeyImpl upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  _IDBKeyRangeImpl lowerBound(_IDBKeyImpl bound, [bool open = null]) native;

  _IDBKeyRangeImpl only(_IDBKeyImpl value) native;

  _IDBKeyRangeImpl upperBound(_IDBKeyImpl bound, [bool open = null]) native;
}

class _IDBObjectStoreImpl implements IDBObjectStore native "*IDBObjectStore" {

  final List<String> indexNames;

  final String keyPath;

  final String name;

  final _IDBTransactionImpl transaction;

  _IDBRequestImpl add(Dynamic value, [_IDBKeyImpl key = null]) native;

  _IDBRequestImpl clear() native;

  _IDBRequestImpl count([var key_OR_range = null]) native;

  _IDBIndexImpl createIndex(String name, String keyPath) native;

  _IDBRequestImpl delete(var key_OR_keyRange) native;

  void deleteIndex(String name) native;

  _IDBRequestImpl getObject(_IDBKeyImpl key) native;

  _IDBIndexImpl index(String name) native;

  _IDBRequestImpl openCursor([_IDBKeyRangeImpl range = null, int direction = null]) native;

  _IDBRequestImpl put(Dynamic value, [_IDBKeyImpl key = null]) native;
}

class _IDBRequestImpl implements IDBRequest native "*IDBRequest" {

  static final int DONE = 2;

  static final int LOADING = 1;

  final int errorCode;

  EventListener onerror;

  EventListener onsuccess;

  final int readyState;

  final _IDBAnyImpl result;

  final _IDBAnyImpl source;

  final _IDBTransactionImpl transaction;

  final String webkitErrorMessage;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _IDBTransactionImpl implements IDBTransaction native "*IDBTransaction" {

  static final int READ_ONLY = 0;

  static final int READ_WRITE = 1;

  static final int VERSION_CHANGE = 2;

  final _IDBDatabaseImpl db;

  final int mode;

  EventListener onabort;

  EventListener oncomplete;

  EventListener onerror;

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  _IDBObjectStoreImpl objectStore(String name) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _IDBVersionChangeEventImpl extends _EventImpl implements IDBVersionChangeEvent native "*IDBVersionChangeEvent" {

  final String version;
}

class _IDBVersionChangeRequestImpl extends _IDBRequestImpl implements IDBVersionChangeRequest native "*IDBVersionChangeRequest" {

  EventListener onblocked;
}

class _IFrameElementImpl extends _ElementImpl implements IFrameElement native "*HTMLIFrameElement" {

  String align;

  final _DocumentImpl contentDocument;

  final _WindowImpl contentWindow;

  String frameBorder;

  String height;

  String longDesc;

  String marginHeight;

  String marginWidth;

  String name;

  String sandbox;

  String scrolling;

  String src;

  String width;

  _SVGDocumentImpl getSVGDocument() native;
}

class _IceCandidateImpl implements IceCandidate native "*IceCandidate" {

  final String label;

  String toSdp() native;
}

class _ImageDataImpl implements ImageData native "*ImageData" {

  final _CanvasPixelArrayImpl data;

  final int height;

  final int width;
}

class _ImageElementImpl extends _ElementImpl implements ImageElement native "*HTMLImageElement" {

  String align;

  String alt;

  String border;

  final bool complete;

  String crossOrigin;

  int height;

  int hspace;

  bool isMap;

  String longDesc;

  String lowsrc;

  String name;

  final int naturalHeight;

  final int naturalWidth;

  String src;

  String useMap;

  int vspace;

  int width;

  final int x;

  final int y;
}

class _InputElementImpl extends _ElementImpl implements InputElement native "*HTMLInputElement" {

  _InputElementEventsImpl get on() =>
    new _InputElementEventsImpl(this);

  String accept;

  String align;

  String alt;

  String autocomplete;

  bool autofocus;

  bool checked;

  bool defaultChecked;

  String defaultValue;

  bool disabled;

  final _FileListImpl files;

  final _FormElementImpl form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  bool incremental;

  bool indeterminate;

  final _NodeListImpl labels;

  String max;

  int maxLength;

  String min;

  bool multiple;

  String name;

  String pattern;

  String placeholder;

  bool readOnly;

  bool required;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  int size;

  String src;

  String step;

  String type;

  String useMap;

  final String validationMessage;

  final _ValidityStateImpl validity;

  String value;

  Date valueAsDate;

  num valueAsNumber;

  bool webkitGrammar;

  bool webkitSpeech;

  bool webkitdirectory;

  final bool willValidate;

  bool checkValidity() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;

  void stepDown([int n = null]) native;

  void stepUp([int n = null]) native;
}

class _InputElementEventsImpl extends _ElementEventsImpl implements InputElementEvents {
  _InputElementEventsImpl(_ptr) : super(_ptr);

  EventListenerList get speechChange() => _get('webkitSpeechChange');
}

class _Int16ArrayImpl extends _ArrayBufferViewImpl implements Int16Array, List<int> native "*Int16Array" {

  factory Int16Array(int length) =>  _construct_Int16Array(length);

  factory Int16Array.fromList(List<int> list) => _construct_Int16Array(list);

  factory Int16Array.fromBuffer(ArrayBuffer buffer) => _construct_Int16Array(buffer);

  static _construct_Int16Array(arg) native 'return new Int16Array(arg);';

  static final int BYTES_PER_ELEMENT = 2;

  final int length;

  int operator[](int index) native "return this[index];";

  void operator[]=(int index, int value) native "this[index] = value";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<int>:

  void sort(int compare(int a, int b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  int last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<int> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [int initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<int> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <int>[]);

  // -- end List<int> mixins.

  void setElements(Object array, [int offset = null]) native;

  _Int16ArrayImpl subarray(int start, [int end = null]) native;
}

class _Int32ArrayImpl extends _ArrayBufferViewImpl implements Int32Array, List<int> native "*Int32Array" {

  factory Int32Array(int length) =>  _construct_Int32Array(length);

  factory Int32Array.fromList(List<int> list) => _construct_Int32Array(list);

  factory Int32Array.fromBuffer(ArrayBuffer buffer) => _construct_Int32Array(buffer);

  static _construct_Int32Array(arg) native 'return new Int32Array(arg);';

  static final int BYTES_PER_ELEMENT = 4;

  final int length;

  int operator[](int index) native "return this[index];";

  void operator[]=(int index, int value) native "this[index] = value";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<int>:

  void sort(int compare(int a, int b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  int last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<int> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [int initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<int> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <int>[]);

  // -- end List<int> mixins.

  void setElements(Object array, [int offset = null]) native;

  _Int32ArrayImpl subarray(int start, [int end = null]) native;
}

class _Int8ArrayImpl extends _ArrayBufferViewImpl implements Int8Array, List<int> native "*Int8Array" {

  factory Int8Array(int length) =>  _construct_Int8Array(length);

  factory Int8Array.fromList(List<int> list) => _construct_Int8Array(list);

  factory Int8Array.fromBuffer(ArrayBuffer buffer) => _construct_Int8Array(buffer);

  static _construct_Int8Array(arg) native 'return new Int8Array(arg);';

  static final int BYTES_PER_ELEMENT = 1;

  final int length;

  int operator[](int index) native "return this[index];";

  void operator[]=(int index, int value) native "this[index] = value";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<int>:

  void sort(int compare(int a, int b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  int last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<int> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [int initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<int> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <int>[]);

  // -- end List<int> mixins.

  void setElements(Object array, [int offset = null]) native;

  _Int8ArrayImpl subarray(int start, [int end = null]) native;
}

class _JavaScriptAudioNodeImpl extends _AudioNodeImpl implements JavaScriptAudioNode native "*JavaScriptAudioNode" {

  final int bufferSize;

  EventListener onaudioprocess;
}

class _JavaScriptCallFrameImpl implements JavaScriptCallFrame native "*JavaScriptCallFrame" {

  static final int CATCH_SCOPE = 4;

  static final int CLOSURE_SCOPE = 3;

  static final int GLOBAL_SCOPE = 0;

  static final int LOCAL_SCOPE = 1;

  static final int WITH_SCOPE = 2;

  final _JavaScriptCallFrameImpl caller;

  final int column;

  final String functionName;

  final int line;

  final List scopeChain;

  final int sourceID;

  final Object thisObject;

  final String type;

  void evaluate(String script) native;

  int scopeType(int scopeIndex) native;
}

class _KeyboardEventImpl extends _UIEventImpl implements KeyboardEvent native "*KeyboardEvent" {

  final bool altGraphKey;

  final bool altKey;

  final bool ctrlKey;

  final String keyIdentifier;

  final int keyLocation;

  final bool metaKey;

  final bool shiftKey;

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, _WindowImpl view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) native;
}

class _KeygenElementImpl extends _ElementImpl implements KeygenElement native "*HTMLKeygenElement" {

  bool autofocus;

  String challenge;

  bool disabled;

  final _FormElementImpl form;

  String keytype;

  final _NodeListImpl labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateImpl validity;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class _LIElementImpl extends _ElementImpl implements LIElement native "*HTMLLIElement" {

  String type;

  int value;
}

class _LabelElementImpl extends _ElementImpl implements LabelElement native "*HTMLLabelElement" {

  final _ElementImpl control;

  final _FormElementImpl form;

  String htmlFor;
}

class _LegendElementImpl extends _ElementImpl implements LegendElement native "*HTMLLegendElement" {

  String align;

  final _FormElementImpl form;
}

class _LinkElementImpl extends _ElementImpl implements LinkElement native "*HTMLLinkElement" {

  String charset;

  bool disabled;

  String href;

  String hreflang;

  String media;

  String rel;

  String rev;

  final _StyleSheetImpl sheet;

  _DOMSettableTokenListImpl sizes;

  String target;

  String type;
}

class _LocalMediaStreamImpl extends _MediaStreamImpl implements LocalMediaStream native "*LocalMediaStream" {

  void stop() native;
}

class _LocationImpl implements Location native "*Location" {

  String hash;

  String host;

  String hostname;

  String href;

  final String origin;

  String pathname;

  String port;

  String protocol;

  String search;

  void assign(String url) native;

  void reload() native;

  void replace(String url) native;

  String toString() native;
}

class _LowPass2FilterNodeImpl extends _AudioNodeImpl implements LowPass2FilterNode native "*LowPass2FilterNode" {

  final _AudioParamImpl cutoff;

  final _AudioParamImpl resonance;
}

class _MapElementImpl extends _ElementImpl implements MapElement native "*HTMLMapElement" {

  final _HTMLCollectionImpl areas;

  String name;
}

class _MarqueeElementImpl extends _ElementImpl implements MarqueeElement native "*HTMLMarqueeElement" {

  String behavior;

  String bgColor;

  String direction;

  String height;

  int hspace;

  int loop;

  int scrollAmount;

  int scrollDelay;

  bool trueSpeed;

  int vspace;

  String width;

  void start() native;

  void stop() native;
}

class _MediaControllerImpl implements MediaController native "*MediaController" {

  final _TimeRangesImpl buffered;

  num currentTime;

  num defaultPlaybackRate;

  final num duration;

  bool muted;

  final bool paused;

  num playbackRate;

  final _TimeRangesImpl played;

  final _TimeRangesImpl seekable;

  num volume;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  void pause() native;

  void play() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _MediaElementImpl extends _ElementImpl implements MediaElement native "*HTMLMediaElement" {

  static final int EOS_DECODE_ERR = 2;

  static final int EOS_NETWORK_ERR = 1;

  static final int EOS_NO_ERROR = 0;

  static final int HAVE_CURRENT_DATA = 2;

  static final int HAVE_ENOUGH_DATA = 4;

  static final int HAVE_FUTURE_DATA = 3;

  static final int HAVE_METADATA = 1;

  static final int HAVE_NOTHING = 0;

  static final int NETWORK_EMPTY = 0;

  static final int NETWORK_IDLE = 1;

  static final int NETWORK_LOADING = 2;

  static final int NETWORK_NO_SOURCE = 3;

  static final int SOURCE_CLOSED = 0;

  static final int SOURCE_ENDED = 2;

  static final int SOURCE_OPEN = 1;

  bool autoplay;

  final _TimeRangesImpl buffered;

  _MediaControllerImpl controller;

  bool controls;

  final String currentSrc;

  num currentTime;

  bool defaultMuted;

  num defaultPlaybackRate;

  final num duration;

  final bool ended;

  final _MediaErrorImpl error;

  final num initialTime;

  bool loop;

  String mediaGroup;

  bool muted;

  final int networkState;

  final bool paused;

  num playbackRate;

  final _TimeRangesImpl played;

  String preload;

  final int readyState;

  final _TimeRangesImpl seekable;

  final bool seeking;

  String src;

  final num startTime;

  final _TextTrackListImpl textTracks;

  num volume;

  final int webkitAudioDecodedByteCount;

  bool webkitClosedCaptionsVisible;

  final bool webkitHasClosedCaptions;

  final String webkitMediaSourceURL;

  bool webkitPreservesPitch;

  final int webkitSourceState;

  final int webkitVideoDecodedByteCount;

  _TextTrackImpl addTextTrack(String kind, [String label = null, String language = null]) native;

  String canPlayType(String type) native;

  void load() native;

  void pause() native;

  void play() native;

  void webkitSourceAppend(_Uint8ArrayImpl data) native;

  void webkitSourceEndOfStream(int status) native;
}

class _MediaElementAudioSourceNodeImpl extends _AudioSourceNodeImpl implements MediaElementAudioSourceNode native "*MediaElementAudioSourceNode" {

  final _MediaElementImpl mediaElement;
}

class _MediaErrorImpl implements MediaError native "*MediaError" {

  static final int MEDIA_ERR_ABORTED = 1;

  static final int MEDIA_ERR_DECODE = 3;

  static final int MEDIA_ERR_NETWORK = 2;

  static final int MEDIA_ERR_SRC_NOT_SUPPORTED = 4;

  final int code;
}

class _MediaListImpl implements MediaList native "*MediaList" {

  final int length;

  String mediaText;

  String operator[](int index) native "return this[index];";

  void operator[]=(int index, String value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }
  // -- start List<String> mixins.
  // String is the element type.

  // From Iterable<String>:

  Iterator<String> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<String>(this);
  }

  // From Collection<String>:

  void add(String value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(String value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<String> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(String element)) => _Collections.forEach(this, f);

  Collection map(f(String element)) => _Collections.map(this, [], f);

  Collection<String> filter(bool f(String element)) =>
     _Collections.filter(this, <String>[], f);

  bool every(bool f(String element)) => _Collections.every(this, f);

  bool some(bool f(String element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<String>:

  void sort(int compare(String a, String b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(String element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(String element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  String last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<String> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [String initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<String> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <String>[]);

  // -- end List<String> mixins.

  void appendMedium(String newMedium) native;

  void deleteMedium(String oldMedium) native;

  String item(int index) native;
}

class _MediaQueryListImpl implements MediaQueryList native "*MediaQueryList" {

  final bool matches;

  final String media;

  void addListener(_MediaQueryListListenerImpl listener) native;

  void removeListener(_MediaQueryListListenerImpl listener) native;
}

class _MediaQueryListListenerImpl implements MediaQueryListListener native "*MediaQueryListListener" {

  void queryChanged(_MediaQueryListImpl list) native;
}

class _MediaStreamImpl implements MediaStream native "*MediaStream" {

  static final int ENDED = 2;

  static final int LIVE = 1;

  final _MediaStreamTrackListImpl audioTracks;

  final String label;

  EventListener onended;

  final int readyState;

  final _MediaStreamTrackListImpl videoTracks;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _MediaStreamEventImpl extends _EventImpl implements MediaStreamEvent native "*MediaStreamEvent" {

  final _MediaStreamImpl stream;
}

class _MediaStreamListImpl implements MediaStreamList native "*MediaStreamList" {

  final int length;

  _MediaStreamImpl item(int index) native;
}

class _MediaStreamTrackImpl implements MediaStreamTrack native "*MediaStreamTrack" {

  bool enabled;

  final String kind;

  final String label;
}

class _MediaStreamTrackListImpl implements MediaStreamTrackList native "*MediaStreamTrackList" {

  final int length;

  _MediaStreamTrackImpl item(int index) native;
}

class _MemoryInfoImpl implements MemoryInfo native "*MemoryInfo" {

  final int jsHeapSizeLimit;

  final int totalJSHeapSize;

  final int usedJSHeapSize;
}

class _MenuElementImpl extends _ElementImpl implements MenuElement native "*HTMLMenuElement" {

  bool compact;
}

class _MessageChannelImpl implements MessageChannel native "*MessageChannel" {

  final _MessagePortImpl port1;

  final _MessagePortImpl port2;
}

class _MessageEventImpl extends _EventImpl implements MessageEvent native "*MessageEvent" {

  final Object data;

  final String lastEventId;

  final String origin;

  final List ports;

  final _WindowImpl source;

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, _WindowImpl sourceArg, List messagePorts) native;

  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, _WindowImpl sourceArg, List transferables) native;
}

class _MessagePortImpl extends _EventTargetImpl implements MessagePort native "*MessagePort" {

  _MessagePortEventsImpl get on() =>
    new _MessagePortEventsImpl(this);

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  void close() native;

  bool $dom_dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void postMessage(String message, [List messagePorts = null]) native;

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

  void start() native;

  void webkitPostMessage(String message, [List transfer = null]) native;
}

class _MessagePortEventsImpl extends _EventsImpl implements MessagePortEvents {
  _MessagePortEventsImpl(_ptr) : super(_ptr);

  EventListenerList get message() => _get('message');
}

class _MetaElementImpl extends _ElementImpl implements MetaElement native "*HTMLMetaElement" {

  String content;

  String httpEquiv;

  String name;

  String scheme;
}

class _MetadataImpl implements Metadata native "*Metadata" {

  final Date modificationTime;

  final int size;
}

class _MeterElementImpl extends _ElementImpl implements MeterElement native "*HTMLMeterElement" {

  num high;

  final _NodeListImpl labels;

  num low;

  num max;

  num min;

  num optimum;

  num value;
}

class _ModElementImpl extends _ElementImpl implements ModElement native "*HTMLModElement" {

  String cite;

  String dateTime;
}

class _MouseEventImpl extends _UIEventImpl implements MouseEvent native "*MouseEvent" {

  final bool altKey;

  final int button;

  final int clientX;

  final int clientY;

  final bool ctrlKey;

  final _ClipboardImpl dataTransfer;

  final _NodeImpl fromElement;

  final bool metaKey;

  final int offsetX;

  final int offsetY;

  final _EventTargetImpl relatedTarget;

  final int screenX;

  final int screenY;

  final bool shiftKey;

  final _NodeImpl toElement;

  final int x;

  final int y;

  void $dom_initMouseEvent(String type, bool canBubble, bool cancelable, _WindowImpl view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, _EventTargetImpl relatedTarget) native "this.initMouseEvent(type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget);";
}

class _MutationEventImpl extends _EventImpl implements MutationEvent native "*MutationEvent" {

  static final int ADDITION = 2;

  static final int MODIFICATION = 1;

  static final int REMOVAL = 3;

  final int attrChange;

  final String attrName;

  final String newValue;

  final String prevValue;

  final _NodeImpl relatedNode;

  void initMutationEvent(String type, bool canBubble, bool cancelable, _NodeImpl relatedNode, String prevValue, String newValue, String attrName, int attrChange) native;
}

class _NamedNodeMapImpl implements NamedNodeMap native "*NamedNodeMap" {

  final int length;

  _NodeImpl operator[](int index) native "return this[index];";

  void operator[]=(int index, _NodeImpl value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     _Collections.filter(this, <Node>[], f);

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<Node>:

  void sort(int compare(Node a, Node b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  Node last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<Node> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [Node initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<Node> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <Node>[]);

  // -- end List<Node> mixins.

  _NodeImpl getNamedItem(String name) native;

  _NodeImpl getNamedItemNS(String namespaceURI, String localName) native;

  _NodeImpl item(int index) native;

  _NodeImpl removeNamedItem(String name) native;

  _NodeImpl removeNamedItemNS(String namespaceURI, String localName) native;

  _NodeImpl setNamedItem(_NodeImpl node) native;

  _NodeImpl setNamedItemNS(_NodeImpl node) native;
}

class _NavigatorImpl implements Navigator native "*Navigator" {

  final String appCodeName;

  final String appName;

  final String appVersion;

  final bool cookieEnabled;

  final _GeolocationImpl geolocation;

  final String language;

  final _DOMMimeTypeArrayImpl mimeTypes;

  final bool onLine;

  final String platform;

  final _DOMPluginArrayImpl plugins;

  final String product;

  final String productSub;

  final String userAgent;

  final String vendor;

  final String vendorSub;

  void getStorageUpdates() native;

  bool javaEnabled() native;

  void registerProtocolHandler(String scheme, String url, String title) native;

  void webkitGetUserMedia(String options, NavigatorUserMediaSuccessCallback successCallback, [NavigatorUserMediaErrorCallback errorCallback = null]) native;
}

class _NavigatorUserMediaErrorImpl implements NavigatorUserMediaError native "*NavigatorUserMediaError" {

  static final int PERMISSION_DENIED = 1;

  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Lazy implementation of the child nodes of an element that does not request
 * the actual child nodes of an element until strictly necessary greatly
 * improving performance for the typical cases where it is not required.
 */
class _ChildNodeListLazy implements NodeList {
  final _NodeImpl _this;

  _ChildNodeListLazy(this._this);


  _NodeImpl get first() native "return this._this.firstChild;";
  _NodeImpl last() native "return this._this.lastChild;";

  void add(_NodeImpl value) {
    _this.$dom_appendChild(value);
  }

  void addLast(_NodeImpl value) {
    _this.$dom_appendChild(value);
  }


  void addAll(Collection<_NodeImpl> collection) {
    for (_NodeImpl node in collection) {
      _this.$dom_appendChild(node);
    }
  }

  _NodeImpl removeLast() {
    final last = last();
    if (last != null) {
      _this.$dom_removeChild(last);
    }
    return last;
  }

  void clear() {
    _this.text = '';
  }

  void operator []=(int index, _NodeImpl value) {
    _this.$dom_replaceChild(value, this[index]);
  }

  Iterator<Node> iterator() => _this.$dom_childNodes.iterator();

  // TODO(jacobr): We can implement these methods much more efficiently by
  // looking up the nodeList only once instead of once per iteration.
  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     new _NodeListWrapper(_Collections.filter(this, <Node>[], f));

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<Node>:

  // TODO(jacobr): this could be implemented for child node lists.
  // The exception we throw here is misleading.
  void sort(int compare(Node a, Node b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  // FIXME: implement thesee.
  void setRange(int start, int length, List<Node> from, [int startFrom]) {
    throw new UnsupportedOperationException(
        "Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException(
        "Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [Node initialValue]) {
    throw new UnsupportedOperationException(
        "Cannot insertRange on immutable List.");
  }
  NodeList getRange(int start, int length) =>
    new _NodeListWrapper(_Lists.getRange(this, start, length, <Node>[]));

  // -- end List<Node> mixins.

  // TODO(jacobr): benchmark whether this is more efficient or whether caching
  // a local copy of $dom_childNodes is more efficient.
  int get length() => _this.$dom_childNodes.length;

  _NodeImpl operator[](int index) => _this.$dom_childNodes[index];
}

class _NodeImpl extends _EventTargetImpl implements Node native "*Node" {
  _ChildNodeListLazy get nodes() {
    return new _ChildNodeListLazy(this);
  }

  void set nodes(Collection<Node> value) {
    // Copy list first since we don't want liveness during iteration.
    // TODO(jacobr): there is a better way to do this.
    List copy = new List.from(value);
    text = '';
    for (Node node in copy) {
      $dom_appendChild(node);
    }
  }

  // TODO(jacobr): should we throw an exception if parent is already null?
  _NodeImpl remove() {
    if (this.parent != null) {
      final _NodeImpl parent = this.parent;
      parent.$dom_removeChild(this);
    }
    return this;
  }

  _NodeImpl replaceWith(Node otherNode) {
    try {
      final _NodeImpl parent = this.parent;
      parent.$dom_replaceChild(otherNode, this);
    } catch(var e) {
      
    };
    return this;
  }


  static final int ATTRIBUTE_NODE = 2;

  static final int CDATA_SECTION_NODE = 4;

  static final int COMMENT_NODE = 8;

  static final int DOCUMENT_FRAGMENT_NODE = 11;

  static final int DOCUMENT_NODE = 9;

  static final int DOCUMENT_POSITION_CONTAINED_BY = 0x10;

  static final int DOCUMENT_POSITION_CONTAINS = 0x08;

  static final int DOCUMENT_POSITION_DISCONNECTED = 0x01;

  static final int DOCUMENT_POSITION_FOLLOWING = 0x04;

  static final int DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20;

  static final int DOCUMENT_POSITION_PRECEDING = 0x02;

  static final int DOCUMENT_TYPE_NODE = 10;

  static final int ELEMENT_NODE = 1;

  static final int ENTITY_NODE = 6;

  static final int ENTITY_REFERENCE_NODE = 5;

  static final int NOTATION_NODE = 12;

  static final int PROCESSING_INSTRUCTION_NODE = 7;

  static final int TEXT_NODE = 3;

  _NamedNodeMapImpl get $dom_attributes() native "return this.attributes;";

  _NodeListImpl get $dom_childNodes() native "return this.childNodes;";

  _NodeImpl get $dom_firstChild() native "return this.firstChild;";

  _NodeImpl get $dom_lastChild() native "return this.lastChild;";

  _NodeImpl get nextNode() native "return this.nextSibling;";

  int get $dom_nodeType() native "return this.nodeType;";

  _DocumentImpl get document() native "return this.ownerDocument;";

  _NodeImpl get parent() native "return this.parentNode;";

  _NodeImpl get previousNode() native "return this.previousSibling;";

  String get text() native "return this.textContent;";

  void set text(String value) native "this.textContent = value;";

  _NodeImpl $dom_appendChild(_NodeImpl newChild) native "return this.appendChild(newChild);";

  _NodeImpl clone(bool deep) native "return this.cloneNode(deep);";

  bool contains(_NodeImpl other) native;

  bool hasChildNodes() native;

  _NodeImpl insertBefore(_NodeImpl newChild, _NodeImpl refChild) native;

  _NodeImpl $dom_removeChild(_NodeImpl oldChild) native "return this.removeChild(oldChild);";

  _NodeImpl $dom_replaceChild(_NodeImpl newChild, _NodeImpl oldChild) native "return this.replaceChild(newChild, oldChild);";

}

class _NodeFilterImpl implements NodeFilter native "*NodeFilter" {

  static final int FILTER_ACCEPT = 1;

  static final int FILTER_REJECT = 2;

  static final int FILTER_SKIP = 3;

  static final int SHOW_ALL = 0xFFFFFFFF;

  static final int SHOW_ATTRIBUTE = 0x00000002;

  static final int SHOW_CDATA_SECTION = 0x00000008;

  static final int SHOW_COMMENT = 0x00000080;

  static final int SHOW_DOCUMENT = 0x00000100;

  static final int SHOW_DOCUMENT_FRAGMENT = 0x00000400;

  static final int SHOW_DOCUMENT_TYPE = 0x00000200;

  static final int SHOW_ELEMENT = 0x00000001;

  static final int SHOW_ENTITY = 0x00000020;

  static final int SHOW_ENTITY_REFERENCE = 0x00000010;

  static final int SHOW_NOTATION = 0x00000800;

  static final int SHOW_PROCESSING_INSTRUCTION = 0x00000040;

  static final int SHOW_TEXT = 0x00000004;

  int acceptNode(_NodeImpl n) native;
}

class _NodeIteratorImpl implements NodeIterator native "*NodeIterator" {

  final bool expandEntityReferences;

  final _NodeFilterImpl filter;

  final bool pointerBeforeReferenceNode;

  final _NodeImpl referenceNode;

  final _NodeImpl root;

  final int whatToShow;

  void detach() native;

  _NodeImpl nextNode() native;

  _NodeImpl previousNode() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(nweiz): when all implementations we target have the same name for the
// coreimpl implementation of List<E>, extend that rather than wrapping.
class _ListWrapper<E> implements List<E> {
  List _list;

  _ListWrapper(List this._list);

  Iterator<E> iterator() => _list.iterator();

  void forEach(void f(E element)) => _list.forEach(f);

  Collection map(f(E element)) => _list.map(f);

  List<E> filter(bool f(E element)) => _list.filter(f);

  bool every(bool f(E element)) => _list.every(f);

  bool some(bool f(E element)) => _list.some(f);

  bool isEmpty() => _list.isEmpty();

  int get length() => _list.length;

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) { _list[index] = value; }

  void set length(int newLength) { _list.length = newLength; }

  void add(E value) => _list.add(value);

  void addLast(E value) => _list.addLast(value);

  void addAll(Collection<E> collection) => _list.addAll(collection);

  void sort(int compare(E a, E b)) => _list.sort(compare);

  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);

  int lastIndexOf(E element, [int start = 0]) =>
    _list.lastIndexOf(element, start);

  void clear() => _list.clear();

  E removeLast() => _list.removeLast();

  E last() => _list.last();

  List<E> getRange(int start, int length) => _list.getRange(start, length);

  void setRange(int start, int length, List<E> from, [int startFrom = 0]) =>
    _list.setRange(start, length, from, startFrom);

  void removeRange(int start, int length) => _list.removeRange(start, length);

  void insertRange(int start, int length, [E initialValue = null]) =>
    _list.insertRange(start, length, initialValue);

  E get first() => _list[0];
}

/**
 * This class is used to insure the results of list operations are NodeLists
 * instead of lists.
 */
class _NodeListWrapper extends _ListWrapper<Node> implements NodeList {
  _NodeListWrapper(List list) : super(list);

  NodeList filter(bool f(Node element)) =>
    new _NodeListWrapper(_list.filter(f));

  NodeList getRange(int start, int length) =>
    new _NodeListWrapper(_list.getRange(start, length));
}

class _NodeListImpl implements NodeList native "*NodeList" {
  _NodeImpl _parent;

  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(_NodeImpl value) {
    _parent.$dom_appendChild(value);
  }

  void addLast(_NodeImpl value) {
    _parent.$dom_appendChild(value);
  }

  void addAll(Collection<_NodeImpl> collection) {
    for (_NodeImpl node in collection) {
      _parent.$dom_appendChild(node);      
    }
  }

  _NodeImpl removeLast() {
    final last = this.last();
    if (last != null) {
      _parent.$dom_removeChild(last);
    }
    return last;
  }

  void clear() {
    _parent.text = '';
  }

  void operator []=(int index, _NodeImpl value) {
    _parent.$dom_replaceChild(value, this[index]);
  }

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     new _NodeListWrapper(_Collections.filter(this, <Node>[], f));

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<Node>:

  void sort(int compare(Node a, Node b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  Node last() => this[length - 1];
  Node get first() => this[0];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<Node> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [Node initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  NodeList getRange(int start, int length) =>
    new _NodeListWrapper(_Lists.getRange(this, start, length, <Node>[]));

  // -- end List<Node> mixins.


  final int length;

  _NodeImpl operator[](int index) native "return this[index];";

}

class _NodeSelectorImpl implements NodeSelector native "*NodeSelector" {

  _ElementImpl query(String selectors) native "return this.querySelector(selectors);";

  _NodeListImpl $dom_querySelectorAll(String selectors) native "return this.querySelectorAll(selectors);";
}

class _NotationImpl extends _NodeImpl implements Notation native "*Notation" {

  final String publicId;

  final String systemId;
}

class _NotificationImpl extends _EventTargetImpl implements Notification native "*Notification" {

  _NotificationEventsImpl get on() =>
    new _NotificationEventsImpl(this);

  String dir;

  String replaceId;

  void cancel() native;

  void show() native;
}

class _NotificationEventsImpl extends _EventsImpl implements NotificationEvents {
  _NotificationEventsImpl(_ptr) : super(_ptr);

  EventListenerList get click() => _get('click');

  EventListenerList get close() => _get('close');

  EventListenerList get error() => _get('error');

  EventListenerList get show() => _get('show');
}

class _NotificationCenterImpl implements NotificationCenter native "*NotificationCenter" {

  int checkPermission() native;

  _NotificationImpl createHTMLNotification(String url) native;

  _NotificationImpl createNotification(String iconUrl, String title, String body) native;

  void requestPermission(VoidCallback callback) native;
}

class _OESStandardDerivativesImpl implements OESStandardDerivatives native "*OESStandardDerivatives" {

  static final int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;
}

class _OESTextureFloatImpl implements OESTextureFloat native "*OESTextureFloat" {
}

class _OESVertexArrayObjectImpl implements OESVertexArrayObject native "*OESVertexArrayObject" {

  static final int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  void bindVertexArrayOES(_WebGLVertexArrayObjectOESImpl arrayObject) native;

  _WebGLVertexArrayObjectOESImpl createVertexArrayOES() native;

  void deleteVertexArrayOES(_WebGLVertexArrayObjectOESImpl arrayObject) native;

  bool isVertexArrayOES(_WebGLVertexArrayObjectOESImpl arrayObject) native;
}

class _OListElementImpl extends _ElementImpl implements OListElement native "*HTMLOListElement" {

  bool compact;

  bool reversed;

  int start;

  String type;
}

class _ObjectElementImpl extends _ElementImpl implements ObjectElement native "*HTMLObjectElement" {

  String align;

  String archive;

  String border;

  String code;

  String codeBase;

  String codeType;

  final _DocumentImpl contentDocument;

  String data;

  bool declare;

  final _FormElementImpl form;

  String height;

  int hspace;

  String name;

  String standby;

  String type;

  String useMap;

  final String validationMessage;

  final _ValidityStateImpl validity;

  int vspace;

  String width;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class _OfflineAudioCompletionEventImpl extends _EventImpl implements OfflineAudioCompletionEvent native "*OfflineAudioCompletionEvent" {

  final _AudioBufferImpl renderedBuffer;
}

class _OperationNotAllowedExceptionImpl implements OperationNotAllowedException native "*OperationNotAllowedException" {

  static final int NOT_ALLOWED_ERR = 1;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _OptGroupElementImpl extends _ElementImpl implements OptGroupElement native "*HTMLOptGroupElement" {

  bool disabled;

  String label;
}

class _OptionElementImpl extends _ElementImpl implements OptionElement native "*HTMLOptionElement" {

  bool defaultSelected;

  bool disabled;

  final _FormElementImpl form;

  final int index;

  String label;

  bool selected;

  String value;
}

class _OutputElementImpl extends _ElementImpl implements OutputElement native "*HTMLOutputElement" {

  String defaultValue;

  final _FormElementImpl form;

  _DOMSettableTokenListImpl htmlFor;

  final _NodeListImpl labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateImpl validity;

  String value;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class _OverflowEventImpl extends _EventImpl implements OverflowEvent native "*OverflowEvent" {

  static final int BOTH = 2;

  static final int HORIZONTAL = 0;

  static final int VERTICAL = 1;

  final bool horizontalOverflow;

  final int orient;

  final bool verticalOverflow;
}

class _PageTransitionEventImpl extends _EventImpl implements PageTransitionEvent native "*PageTransitionEvent" {

  final bool persisted;
}

class _ParagraphElementImpl extends _ElementImpl implements ParagraphElement native "*HTMLParagraphElement" {

  String align;
}

class _ParamElementImpl extends _ElementImpl implements ParamElement native "*HTMLParamElement" {

  String name;

  String type;

  String value;

  String valueType;
}

class _PeerConnection00Impl implements PeerConnection00 native "*PeerConnection00" {

  static final int ACTIVE = 2;

  static final int CLOSED = 3;

  static final int ICE_CHECKING = 0x300;

  static final int ICE_CLOSED = 0x700;

  static final int ICE_COMPLETED = 0x500;

  static final int ICE_CONNECTED = 0x400;

  static final int ICE_FAILED = 0x600;

  static final int ICE_GATHERING = 0x100;

  static final int ICE_WAITING = 0x200;

  static final int NEGOTIATING = 1;

  static final int NEW = 0;

  static final int SDP_ANSWER = 0x300;

  static final int SDP_OFFER = 0x100;

  static final int SDP_PRANSWER = 0x200;

  final int iceState;

  final _SessionDescriptionImpl localDescription;

  final _MediaStreamListImpl localStreams;

  EventListener onaddstream;

  EventListener onconnecting;

  EventListener onopen;

  EventListener onremovestream;

  EventListener onstatechange;

  final int readyState;

  final _SessionDescriptionImpl remoteDescription;

  final _MediaStreamListImpl remoteStreams;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void addStream(_MediaStreamImpl stream, [String mediaStreamHints = null]) native;

  void close() native;

  _SessionDescriptionImpl createAnswer(String offer, [String mediaHints = null]) native;

  _SessionDescriptionImpl createOffer([String mediaHints = null]) native;

  bool dispatchEvent(_EventImpl event) native;

  void processIceMessage(_IceCandidateImpl candidate) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void removeStream(_MediaStreamImpl stream) native;

  void setLocalDescription(int action, _SessionDescriptionImpl desc) native;

  void setRemoteDescription(int action, _SessionDescriptionImpl desc) native;

  void startIce([String iceOptions = null]) native;
}

class _PerformanceImpl implements Performance native "*Performance" {

  final _MemoryInfoImpl memory;

  final _PerformanceNavigationImpl navigation;

  final _PerformanceTimingImpl timing;
}

class _PerformanceNavigationImpl implements PerformanceNavigation native "*PerformanceNavigation" {

  static final int TYPE_BACK_FORWARD = 2;

  static final int TYPE_NAVIGATE = 0;

  static final int TYPE_RELOAD = 1;

  static final int TYPE_RESERVED = 255;

  final int redirectCount;

  final int type;
}

class _PerformanceTimingImpl implements PerformanceTiming native "*PerformanceTiming" {

  final int connectEnd;

  final int connectStart;

  final int domComplete;

  final int domContentLoadedEventEnd;

  final int domContentLoadedEventStart;

  final int domInteractive;

  final int domLoading;

  final int domainLookupEnd;

  final int domainLookupStart;

  final int fetchStart;

  final int loadEventEnd;

  final int loadEventStart;

  final int navigationStart;

  final int redirectEnd;

  final int redirectStart;

  final int requestStart;

  final int responseEnd;

  final int responseStart;

  final int secureConnectionStart;

  final int unloadEventEnd;

  final int unloadEventStart;
}

class _PointImpl implements Point native "*WebKitPoint" {

  num x;

  num y;
}

class _PopStateEventImpl extends _EventImpl implements PopStateEvent native "*PopStateEvent" {

  final Object state;
}

class _PositionErrorImpl implements PositionError native "*PositionError" {

  static final int PERMISSION_DENIED = 1;

  static final int POSITION_UNAVAILABLE = 2;

  static final int TIMEOUT = 3;

  final int code;

  final String message;
}

class _PreElementImpl extends _ElementImpl implements PreElement native "*HTMLPreElement" {

  int width;

  bool wrap;
}

class _ProcessingInstructionImpl extends _NodeImpl implements ProcessingInstruction native "*ProcessingInstruction" {

  String data;

  final _StyleSheetImpl sheet;

  final String target;
}

class _ProgressElementImpl extends _ElementImpl implements ProgressElement native "*HTMLProgressElement" {

  final _NodeListImpl labels;

  num max;

  final num position;

  num value;
}

class _ProgressEventImpl extends _EventImpl implements ProgressEvent native "*ProgressEvent" {

  final bool lengthComputable;

  final int loaded;

  final int total;
}

class _QuoteElementImpl extends _ElementImpl implements QuoteElement native "*HTMLQuoteElement" {

  String cite;
}

class _RGBColorImpl implements RGBColor native "*RGBColor" {

  final _CSSPrimitiveValueImpl blue;

  final _CSSPrimitiveValueImpl green;

  final _CSSPrimitiveValueImpl red;
}

class _RangeImpl implements Range native "*Range" {

  static final int END_TO_END = 2;

  static final int END_TO_START = 3;

  static final int NODE_AFTER = 1;

  static final int NODE_BEFORE = 0;

  static final int NODE_BEFORE_AND_AFTER = 2;

  static final int NODE_INSIDE = 3;

  static final int START_TO_END = 1;

  static final int START_TO_START = 0;

  final bool collapsed;

  final _NodeImpl commonAncestorContainer;

  final _NodeImpl endContainer;

  final int endOffset;

  final _NodeImpl startContainer;

  final int startOffset;

  _DocumentFragmentImpl cloneContents() native;

  _RangeImpl cloneRange() native;

  void collapse(bool toStart) native;

  int compareNode(_NodeImpl refNode) native;

  int comparePoint(_NodeImpl refNode, int offset) native;

  _DocumentFragmentImpl createContextualFragment(String html) native;

  void deleteContents() native;

  void detach() native;

  void expand(String unit) native;

  _DocumentFragmentImpl extractContents() native;

  _ClientRectImpl getBoundingClientRect() native;

  _ClientRectListImpl getClientRects() native;

  void insertNode(_NodeImpl newNode) native;

  bool intersectsNode(_NodeImpl refNode) native;

  bool isPointInRange(_NodeImpl refNode, int offset) native;

  void selectNode(_NodeImpl refNode) native;

  void selectNodeContents(_NodeImpl refNode) native;

  void setEnd(_NodeImpl refNode, int offset) native;

  void setEndAfter(_NodeImpl refNode) native;

  void setEndBefore(_NodeImpl refNode) native;

  void setStart(_NodeImpl refNode, int offset) native;

  void setStartAfter(_NodeImpl refNode) native;

  void setStartBefore(_NodeImpl refNode) native;

  void surroundContents(_NodeImpl newParent) native;

  String toString() native;
}

class _RangeExceptionImpl implements RangeException native "*RangeException" {

  static final int BAD_BOUNDARYPOINTS_ERR = 1;

  static final int INVALID_NODE_TYPE_ERR = 2;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _RealtimeAnalyserNodeImpl extends _AudioNodeImpl implements RealtimeAnalyserNode native "*RealtimeAnalyserNode" {

  int fftSize;

  final int frequencyBinCount;

  num maxDecibels;

  num minDecibels;

  num smoothingTimeConstant;

  void getByteFrequencyData(_Uint8ArrayImpl array) native;

  void getByteTimeDomainData(_Uint8ArrayImpl array) native;

  void getFloatFrequencyData(_Float32ArrayImpl array) native;
}

class _RectImpl implements Rect native "*Rect" {

  final _CSSPrimitiveValueImpl bottom;

  final _CSSPrimitiveValueImpl left;

  final _CSSPrimitiveValueImpl right;

  final _CSSPrimitiveValueImpl top;
}

class _SQLErrorImpl implements SQLError native "*SQLError" {

  static final int CONSTRAINT_ERR = 6;

  static final int DATABASE_ERR = 1;

  static final int QUOTA_ERR = 4;

  static final int SYNTAX_ERR = 5;

  static final int TIMEOUT_ERR = 7;

  static final int TOO_LARGE_ERR = 3;

  static final int UNKNOWN_ERR = 0;

  static final int VERSION_ERR = 2;

  final int code;

  final String message;
}

class _SQLExceptionImpl implements SQLException native "*SQLException" {

  static final int CONSTRAINT_ERR = 6;

  static final int DATABASE_ERR = 1;

  static final int QUOTA_ERR = 4;

  static final int SYNTAX_ERR = 5;

  static final int TIMEOUT_ERR = 7;

  static final int TOO_LARGE_ERR = 3;

  static final int UNKNOWN_ERR = 0;

  static final int VERSION_ERR = 2;

  final int code;

  final String message;
}

class _SQLResultSetImpl implements SQLResultSet native "*SQLResultSet" {

  final int insertId;

  final _SQLResultSetRowListImpl rows;

  final int rowsAffected;
}

class _SQLResultSetRowListImpl implements SQLResultSetRowList native "*SQLResultSetRowList" {

  final int length;

  Object item(int index) native;
}

class _SQLTransactionImpl implements SQLTransaction native "*SQLTransaction" {
}

class _SQLTransactionSyncImpl implements SQLTransactionSync native "*SQLTransactionSync" {
}

class _SVGAElementImpl extends _SVGElementImpl implements SVGAElement native "*SVGAElement" {

  final _SVGAnimatedStringImpl target;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGAltGlyphDefElementImpl extends _SVGElementImpl implements SVGAltGlyphDefElement native "*SVGAltGlyphDefElement" {
}

class _SVGAltGlyphElementImpl extends _SVGTextPositioningElementImpl implements SVGAltGlyphElement native "*SVGAltGlyphElement" {

  String format;

  String glyphRef;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;
}

class _SVGAltGlyphItemElementImpl extends _SVGElementImpl implements SVGAltGlyphItemElement native "*SVGAltGlyphItemElement" {
}

class _SVGAngleImpl implements SVGAngle native "*SVGAngle" {

  static final int SVG_ANGLETYPE_DEG = 2;

  static final int SVG_ANGLETYPE_GRAD = 4;

  static final int SVG_ANGLETYPE_RAD = 3;

  static final int SVG_ANGLETYPE_UNKNOWN = 0;

  static final int SVG_ANGLETYPE_UNSPECIFIED = 1;

  final int unitType;

  num value;

  String valueAsString;

  num valueInSpecifiedUnits;

  void convertToSpecifiedUnits(int unitType) native;

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}

class _SVGAnimateColorElementImpl extends _SVGAnimationElementImpl implements SVGAnimateColorElement native "*SVGAnimateColorElement" {
}

class _SVGAnimateElementImpl extends _SVGAnimationElementImpl implements SVGAnimateElement native "*SVGAnimateElement" {
}

class _SVGAnimateMotionElementImpl extends _SVGAnimationElementImpl implements SVGAnimateMotionElement native "*SVGAnimateMotionElement" {
}

class _SVGAnimateTransformElementImpl extends _SVGAnimationElementImpl implements SVGAnimateTransformElement native "*SVGAnimateTransformElement" {
}

class _SVGAnimatedAngleImpl implements SVGAnimatedAngle native "*SVGAnimatedAngle" {

  final _SVGAngleImpl animVal;

  final _SVGAngleImpl baseVal;
}

class _SVGAnimatedBooleanImpl implements SVGAnimatedBoolean native "*SVGAnimatedBoolean" {

  final bool animVal;

  bool baseVal;
}

class _SVGAnimatedEnumerationImpl implements SVGAnimatedEnumeration native "*SVGAnimatedEnumeration" {

  final int animVal;

  int baseVal;
}

class _SVGAnimatedIntegerImpl implements SVGAnimatedInteger native "*SVGAnimatedInteger" {

  final int animVal;

  int baseVal;
}

class _SVGAnimatedLengthImpl implements SVGAnimatedLength native "*SVGAnimatedLength" {

  final _SVGLengthImpl animVal;

  final _SVGLengthImpl baseVal;
}

class _SVGAnimatedLengthListImpl implements SVGAnimatedLengthList native "*SVGAnimatedLengthList" {

  final _SVGLengthListImpl animVal;

  final _SVGLengthListImpl baseVal;
}

class _SVGAnimatedNumberImpl implements SVGAnimatedNumber native "*SVGAnimatedNumber" {

  final num animVal;

  num baseVal;
}

class _SVGAnimatedNumberListImpl implements SVGAnimatedNumberList native "*SVGAnimatedNumberList" {

  final _SVGNumberListImpl animVal;

  final _SVGNumberListImpl baseVal;
}

class _SVGAnimatedPreserveAspectRatioImpl implements SVGAnimatedPreserveAspectRatio native "*SVGAnimatedPreserveAspectRatio" {

  final _SVGPreserveAspectRatioImpl animVal;

  final _SVGPreserveAspectRatioImpl baseVal;
}

class _SVGAnimatedRectImpl implements SVGAnimatedRect native "*SVGAnimatedRect" {

  final _SVGRectImpl animVal;

  final _SVGRectImpl baseVal;
}

class _SVGAnimatedStringImpl implements SVGAnimatedString native "*SVGAnimatedString" {

  final String animVal;

  String baseVal;
}

class _SVGAnimatedTransformListImpl implements SVGAnimatedTransformList native "*SVGAnimatedTransformList" {

  final _SVGTransformListImpl animVal;

  final _SVGTransformListImpl baseVal;
}

class _SVGAnimationElementImpl extends _SVGElementImpl implements SVGAnimationElement native "*SVGAnimationElement" {

  final _SVGElementImpl targetElement;

  num getCurrentTime() native;

  num getSimpleDuration() native;

  num getStartTime() native;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From ElementTimeControl

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;
}

class _SVGCircleElementImpl extends _SVGElementImpl implements SVGCircleElement native "*SVGCircleElement" {

  final _SVGAnimatedLengthImpl cx;

  final _SVGAnimatedLengthImpl cy;

  final _SVGAnimatedLengthImpl r;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGClipPathElementImpl extends _SVGElementImpl implements SVGClipPathElement native "*SVGClipPathElement" {

  final _SVGAnimatedEnumerationImpl clipPathUnits;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGColorImpl extends _CSSValueImpl implements SVGColor native "*SVGColor" {

  static final int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static final int SVG_COLORTYPE_RGBCOLOR = 1;

  static final int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static final int SVG_COLORTYPE_UNKNOWN = 0;

  final int colorType;

  final _RGBColorImpl rgbColor;

  void setColor(int colorType, String rgbColor, String iccColor) native;

  void setRGBColor(String rgbColor) native;

  void setRGBColorICCColor(String rgbColor, String iccColor) native;
}

class _SVGComponentTransferFunctionElementImpl extends _SVGElementImpl implements SVGComponentTransferFunctionElement native "*SVGComponentTransferFunctionElement" {

  static final int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  final _SVGAnimatedNumberImpl amplitude;

  final _SVGAnimatedNumberImpl exponent;

  final _SVGAnimatedNumberImpl intercept;

  final _SVGAnimatedNumberImpl offset;

  final _SVGAnimatedNumberImpl slope;

  final _SVGAnimatedNumberListImpl tableValues;

  final _SVGAnimatedEnumerationImpl type;
}

class _SVGCursorElementImpl extends _SVGElementImpl implements SVGCursorElement native "*SVGCursorElement" {

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;
}

class _SVGDefsElementImpl extends _SVGElementImpl implements SVGDefsElement native "*SVGDefsElement" {

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGDescElementImpl extends _SVGElementImpl implements SVGDescElement native "*SVGDescElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGDocumentImpl extends _DocumentImpl implements SVGDocument native "*SVGDocument" {

  final _SVGSVGElementImpl rootElement;

  _EventImpl $dom_createEvent(String eventType) native "return this.createEvent(eventType);";
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AttributeClassSet extends _CssClassSet {
  _AttributeClassSet(element) : super(element);

  String $dom_className() => _element.attributes['class'];

  void _write(Set s) {
    _element.attributes['class'] = _formatSet(s);
  }
}

class _SVGElementImpl extends _ElementImpl implements SVGElement native "*SVGElement" {
  Set<String> get classes() {
    if (_cssClassSet === null) {
      _cssClassSet = new _AttributeClassSet(_ptr);
    }
    return _cssClassSet;
  }

  ElementList get elements() => new FilteredElementList(this);

  void set elements(Collection<Element> value) {
    final elements = this.elements;
    elements.clear();
    elements.addAll(value);
  }

  String get outerHTML() {
    final container = new Element.tag("div");
    final SVGElement clone = this.clone(true);
    container.elements.add(clone);
    return container.innerHTML;
  }

  String get innerHTML() {
    final container = new Element.tag("div");
    final SVGElement clone = this.clone(true);
    container.elements.addAll(clone.elements);
    return container.innerHTML;
  }

  void set innerHTML(String svg) {
    final container = new Element.tag("div");
    // Wrap the SVG string in <svg> so that SVGElements are created, rather than
    // HTMLElements.
    container.innerHTML = '<svg version="1.1">$svg</svg>';
    this.elements = container.elements.first.elements;
  }


  // Shadowing definition.
  String get id() native "return this.id;";

  void set id(String value) native "this.id = value;";

  final _SVGSVGElementImpl ownerSVGElement;

  final _SVGElementImpl viewportElement;

  String xmlbase;

}

class _SVGElementInstanceImpl extends _EventTargetImpl implements SVGElementInstance native "*SVGElementInstance" {

  _SVGElementInstanceEventsImpl get on() =>
    new _SVGElementInstanceEventsImpl(this);

  final _SVGElementInstanceListImpl childNodes;

  final _SVGElementImpl correspondingElement;

  final _SVGUseElementImpl correspondingUseElement;

  final _SVGElementInstanceImpl firstChild;

  final _SVGElementInstanceImpl lastChild;

  final _SVGElementInstanceImpl nextSibling;

  final _SVGElementInstanceImpl parentNode;

  final _SVGElementInstanceImpl previousSibling;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  bool $dom_dispatchEvent(_EventImpl event) native "return this.dispatchEvent(event);";

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";
}

class _SVGElementInstanceEventsImpl extends _EventsImpl implements SVGElementInstanceEvents {
  _SVGElementInstanceEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get beforeCopy() => _get('beforecopy');

  EventListenerList get beforeCut() => _get('beforecut');

  EventListenerList get beforePaste() => _get('beforepaste');

  EventListenerList get blur() => _get('blur');

  EventListenerList get change() => _get('change');

  EventListenerList get click() => _get('click');

  EventListenerList get contextMenu() => _get('contextmenu');

  EventListenerList get copy() => _get('copy');

  EventListenerList get cut() => _get('cut');

  EventListenerList get doubleClick() => _get('dblclick');

  EventListenerList get drag() => _get('drag');

  EventListenerList get dragEnd() => _get('dragend');

  EventListenerList get dragEnter() => _get('dragenter');

  EventListenerList get dragLeave() => _get('dragleave');

  EventListenerList get dragOver() => _get('dragover');

  EventListenerList get dragStart() => _get('dragstart');

  EventListenerList get drop() => _get('drop');

  EventListenerList get error() => _get('error');

  EventListenerList get focus() => _get('focus');

  EventListenerList get input() => _get('input');

  EventListenerList get keyDown() => _get('keydown');

  EventListenerList get keyPress() => _get('keypress');

  EventListenerList get keyUp() => _get('keyup');

  EventListenerList get load() => _get('load');

  EventListenerList get mouseDown() => _get('mousedown');

  EventListenerList get mouseMove() => _get('mousemove');

  EventListenerList get mouseOut() => _get('mouseout');

  EventListenerList get mouseOver() => _get('mouseover');

  EventListenerList get mouseUp() => _get('mouseup');

  EventListenerList get mouseWheel() => _get('mousewheel');

  EventListenerList get paste() => _get('paste');

  EventListenerList get reset() => _get('reset');

  EventListenerList get resize() => _get('resize');

  EventListenerList get scroll() => _get('scroll');

  EventListenerList get search() => _get('search');

  EventListenerList get select() => _get('select');

  EventListenerList get selectStart() => _get('selectstart');

  EventListenerList get submit() => _get('submit');

  EventListenerList get unload() => _get('unload');
}

class _SVGElementInstanceListImpl implements SVGElementInstanceList native "*SVGElementInstanceList" {

  final int length;

  _SVGElementInstanceImpl item(int index) native;
}

class _SVGEllipseElementImpl extends _SVGElementImpl implements SVGEllipseElement native "*SVGEllipseElement" {

  final _SVGAnimatedLengthImpl cx;

  final _SVGAnimatedLengthImpl cy;

  final _SVGAnimatedLengthImpl rx;

  final _SVGAnimatedLengthImpl ry;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGExceptionImpl implements SVGException native "*SVGException" {

  static final int SVG_INVALID_VALUE_ERR = 1;

  static final int SVG_MATRIX_NOT_INVERTABLE = 2;

  static final int SVG_WRONG_TYPE_ERR = 0;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _SVGExternalResourcesRequiredImpl implements SVGExternalResourcesRequired native "*SVGExternalResourcesRequired" {

  final _SVGAnimatedBooleanImpl externalResourcesRequired;
}

class _SVGFEBlendElementImpl extends _SVGElementImpl implements SVGFEBlendElement native "*SVGFEBlendElement" {

  static final int SVG_FEBLEND_MODE_DARKEN = 4;

  static final int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static final int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static final int SVG_FEBLEND_MODE_NORMAL = 1;

  static final int SVG_FEBLEND_MODE_SCREEN = 3;

  static final int SVG_FEBLEND_MODE_UNKNOWN = 0;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedStringImpl in2;

  final _SVGAnimatedEnumerationImpl mode;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEColorMatrixElementImpl extends _SVGElementImpl implements SVGFEColorMatrixElement native "*SVGFEColorMatrixElement" {

  static final int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static final int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static final int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static final int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static final int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedEnumerationImpl type;

  final _SVGAnimatedNumberListImpl values;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEComponentTransferElementImpl extends _SVGElementImpl implements SVGFEComponentTransferElement native "*SVGFEComponentTransferElement" {

  final _SVGAnimatedStringImpl in1;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFECompositeElementImpl extends _SVGElementImpl implements SVGFECompositeElement native "*SVGFECompositeElement" {

  static final int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static final int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static final int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static final int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static final int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static final int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static final int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedStringImpl in2;

  final _SVGAnimatedNumberImpl k1;

  final _SVGAnimatedNumberImpl k2;

  final _SVGAnimatedNumberImpl k3;

  final _SVGAnimatedNumberImpl k4;

  final _SVGAnimatedEnumerationImpl operator;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEConvolveMatrixElementImpl extends _SVGElementImpl implements SVGFEConvolveMatrixElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  final _SVGAnimatedNumberImpl bias;

  final _SVGAnimatedNumberImpl divisor;

  final _SVGAnimatedEnumerationImpl edgeMode;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedNumberListImpl kernelMatrix;

  final _SVGAnimatedNumberImpl kernelUnitLengthX;

  final _SVGAnimatedNumberImpl kernelUnitLengthY;

  final _SVGAnimatedIntegerImpl orderX;

  final _SVGAnimatedIntegerImpl orderY;

  final _SVGAnimatedBooleanImpl preserveAlpha;

  final _SVGAnimatedIntegerImpl targetX;

  final _SVGAnimatedIntegerImpl targetY;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEDiffuseLightingElementImpl extends _SVGElementImpl implements SVGFEDiffuseLightingElement native "*SVGFEDiffuseLightingElement" {

  final _SVGAnimatedNumberImpl diffuseConstant;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedNumberImpl kernelUnitLengthX;

  final _SVGAnimatedNumberImpl kernelUnitLengthY;

  final _SVGAnimatedNumberImpl surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEDisplacementMapElementImpl extends _SVGElementImpl implements SVGFEDisplacementMapElement native "*SVGFEDisplacementMapElement" {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedStringImpl in2;

  final _SVGAnimatedNumberImpl scale;

  final _SVGAnimatedEnumerationImpl xChannelSelector;

  final _SVGAnimatedEnumerationImpl yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEDistantLightElementImpl extends _SVGElementImpl implements SVGFEDistantLightElement native "*SVGFEDistantLightElement" {

  final _SVGAnimatedNumberImpl azimuth;

  final _SVGAnimatedNumberImpl elevation;
}

class _SVGFEDropShadowElementImpl extends _SVGElementImpl implements SVGFEDropShadowElement native "*SVGFEDropShadowElement" {

  final _SVGAnimatedNumberImpl dx;

  final _SVGAnimatedNumberImpl dy;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedNumberImpl stdDeviationX;

  final _SVGAnimatedNumberImpl stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEFloodElementImpl extends _SVGElementImpl implements SVGFEFloodElement native "*SVGFEFloodElement" {

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEFuncAElementImpl extends _SVGComponentTransferFunctionElementImpl implements SVGFEFuncAElement native "*SVGFEFuncAElement" {
}

class _SVGFEFuncBElementImpl extends _SVGComponentTransferFunctionElementImpl implements SVGFEFuncBElement native "*SVGFEFuncBElement" {
}

class _SVGFEFuncGElementImpl extends _SVGComponentTransferFunctionElementImpl implements SVGFEFuncGElement native "*SVGFEFuncGElement" {
}

class _SVGFEFuncRElementImpl extends _SVGComponentTransferFunctionElementImpl implements SVGFEFuncRElement native "*SVGFEFuncRElement" {
}

class _SVGFEGaussianBlurElementImpl extends _SVGElementImpl implements SVGFEGaussianBlurElement native "*SVGFEGaussianBlurElement" {

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedNumberImpl stdDeviationX;

  final _SVGAnimatedNumberImpl stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEImageElementImpl extends _SVGElementImpl implements SVGFEImageElement native "*SVGFEImageElement" {

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEMergeElementImpl extends _SVGElementImpl implements SVGFEMergeElement native "*SVGFEMergeElement" {

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEMergeNodeElementImpl extends _SVGElementImpl implements SVGFEMergeNodeElement native "*SVGFEMergeNodeElement" {

  final _SVGAnimatedStringImpl in1;
}

class _SVGFEMorphologyElementImpl extends _SVGElementImpl implements SVGFEMorphologyElement native "*SVGFEMorphologyElement" {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedEnumerationImpl operator;

  final _SVGAnimatedNumberImpl radiusX;

  final _SVGAnimatedNumberImpl radiusY;

  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEOffsetElementImpl extends _SVGElementImpl implements SVGFEOffsetElement native "*SVGFEOffsetElement" {

  final _SVGAnimatedNumberImpl dx;

  final _SVGAnimatedNumberImpl dy;

  final _SVGAnimatedStringImpl in1;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFEPointLightElementImpl extends _SVGElementImpl implements SVGFEPointLightElement native "*SVGFEPointLightElement" {

  final _SVGAnimatedNumberImpl x;

  final _SVGAnimatedNumberImpl y;

  final _SVGAnimatedNumberImpl z;
}

class _SVGFESpecularLightingElementImpl extends _SVGElementImpl implements SVGFESpecularLightingElement native "*SVGFESpecularLightingElement" {

  final _SVGAnimatedStringImpl in1;

  final _SVGAnimatedNumberImpl specularConstant;

  final _SVGAnimatedNumberImpl specularExponent;

  final _SVGAnimatedNumberImpl surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFESpotLightElementImpl extends _SVGElementImpl implements SVGFESpotLightElement native "*SVGFESpotLightElement" {

  final _SVGAnimatedNumberImpl limitingConeAngle;

  final _SVGAnimatedNumberImpl pointsAtX;

  final _SVGAnimatedNumberImpl pointsAtY;

  final _SVGAnimatedNumberImpl pointsAtZ;

  final _SVGAnimatedNumberImpl specularExponent;

  final _SVGAnimatedNumberImpl x;

  final _SVGAnimatedNumberImpl y;

  final _SVGAnimatedNumberImpl z;
}

class _SVGFETileElementImpl extends _SVGElementImpl implements SVGFETileElement native "*SVGFETileElement" {

  final _SVGAnimatedStringImpl in1;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFETurbulenceElementImpl extends _SVGElementImpl implements SVGFETurbulenceElement native "*SVGFETurbulenceElement" {

  static final int SVG_STITCHTYPE_NOSTITCH = 2;

  static final int SVG_STITCHTYPE_STITCH = 1;

  static final int SVG_STITCHTYPE_UNKNOWN = 0;

  static final int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static final int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static final int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  final _SVGAnimatedNumberImpl baseFrequencyX;

  final _SVGAnimatedNumberImpl baseFrequencyY;

  final _SVGAnimatedIntegerImpl numOctaves;

  final _SVGAnimatedNumberImpl seed;

  final _SVGAnimatedEnumerationImpl stitchTiles;

  final _SVGAnimatedEnumerationImpl type;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFilterElementImpl extends _SVGElementImpl implements SVGFilterElement native "*SVGFilterElement" {

  final _SVGAnimatedIntegerImpl filterResX;

  final _SVGAnimatedIntegerImpl filterResY;

  final _SVGAnimatedEnumerationImpl filterUnits;

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedEnumerationImpl primitiveUnits;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGFilterPrimitiveStandardAttributesImpl extends _SVGStylableImpl implements SVGFilterPrimitiveStandardAttributes native "*SVGFilterPrimitiveStandardAttributes" {

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedStringImpl result;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;
}

class _SVGFitToViewBoxImpl implements SVGFitToViewBox native "*SVGFitToViewBox" {

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;
}

class _SVGFontElementImpl extends _SVGElementImpl implements SVGFontElement native "*SVGFontElement" {
}

class _SVGFontFaceElementImpl extends _SVGElementImpl implements SVGFontFaceElement native "*SVGFontFaceElement" {
}

class _SVGFontFaceFormatElementImpl extends _SVGElementImpl implements SVGFontFaceFormatElement native "*SVGFontFaceFormatElement" {
}

class _SVGFontFaceNameElementImpl extends _SVGElementImpl implements SVGFontFaceNameElement native "*SVGFontFaceNameElement" {
}

class _SVGFontFaceSrcElementImpl extends _SVGElementImpl implements SVGFontFaceSrcElement native "*SVGFontFaceSrcElement" {
}

class _SVGFontFaceUriElementImpl extends _SVGElementImpl implements SVGFontFaceUriElement native "*SVGFontFaceUriElement" {
}

class _SVGForeignObjectElementImpl extends _SVGElementImpl implements SVGForeignObjectElement native "*SVGForeignObjectElement" {

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGGElementImpl extends _SVGElementImpl implements SVGGElement native "*SVGGElement" {

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGGlyphElementImpl extends _SVGElementImpl implements SVGGlyphElement native "*SVGGlyphElement" {
}

class _SVGGlyphRefElementImpl extends _SVGElementImpl implements SVGGlyphRefElement native "*SVGGlyphRefElement" {

  num dx;

  num dy;

  String format;

  String glyphRef;

  num x;

  num y;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGGradientElementImpl extends _SVGElementImpl implements SVGGradientElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  final _SVGAnimatedTransformListImpl gradientTransform;

  final _SVGAnimatedEnumerationImpl gradientUnits;

  final _SVGAnimatedEnumerationImpl spreadMethod;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGHKernElementImpl extends _SVGElementImpl implements SVGHKernElement native "*SVGHKernElement" {
}

class _SVGImageElementImpl extends _SVGElementImpl implements SVGImageElement native "*SVGImageElement" {

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGLangSpaceImpl implements SVGLangSpace native "*SVGLangSpace" {

  String xmllang;

  String xmlspace;
}

class _SVGLengthImpl implements SVGLength native "*SVGLength" {

  static final int SVG_LENGTHTYPE_CM = 6;

  static final int SVG_LENGTHTYPE_EMS = 3;

  static final int SVG_LENGTHTYPE_EXS = 4;

  static final int SVG_LENGTHTYPE_IN = 8;

  static final int SVG_LENGTHTYPE_MM = 7;

  static final int SVG_LENGTHTYPE_NUMBER = 1;

  static final int SVG_LENGTHTYPE_PC = 10;

  static final int SVG_LENGTHTYPE_PERCENTAGE = 2;

  static final int SVG_LENGTHTYPE_PT = 9;

  static final int SVG_LENGTHTYPE_PX = 5;

  static final int SVG_LENGTHTYPE_UNKNOWN = 0;

  final int unitType;

  num value;

  String valueAsString;

  num valueInSpecifiedUnits;

  void convertToSpecifiedUnits(int unitType) native;

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}

class _SVGLengthListImpl implements SVGLengthList native "*SVGLengthList" {

  final int numberOfItems;

  _SVGLengthImpl appendItem(_SVGLengthImpl item) native;

  void clear() native;

  _SVGLengthImpl getItem(int index) native;

  _SVGLengthImpl initialize(_SVGLengthImpl item) native;

  _SVGLengthImpl insertItemBefore(_SVGLengthImpl item, int index) native;

  _SVGLengthImpl removeItem(int index) native;

  _SVGLengthImpl replaceItem(_SVGLengthImpl item, int index) native;
}

class _SVGLineElementImpl extends _SVGElementImpl implements SVGLineElement native "*SVGLineElement" {

  final _SVGAnimatedLengthImpl x1;

  final _SVGAnimatedLengthImpl x2;

  final _SVGAnimatedLengthImpl y1;

  final _SVGAnimatedLengthImpl y2;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGLinearGradientElementImpl extends _SVGGradientElementImpl implements SVGLinearGradientElement native "*SVGLinearGradientElement" {

  final _SVGAnimatedLengthImpl x1;

  final _SVGAnimatedLengthImpl x2;

  final _SVGAnimatedLengthImpl y1;

  final _SVGAnimatedLengthImpl y2;
}

class _SVGLocatableImpl implements SVGLocatable native "*SVGLocatable" {

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGMPathElementImpl extends _SVGElementImpl implements SVGMPathElement native "*SVGMPathElement" {

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;
}

class _SVGMarkerElementImpl extends _SVGElementImpl implements SVGMarkerElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  final _SVGAnimatedLengthImpl markerHeight;

  final _SVGAnimatedEnumerationImpl markerUnits;

  final _SVGAnimatedLengthImpl markerWidth;

  final _SVGAnimatedAngleImpl orientAngle;

  final _SVGAnimatedEnumerationImpl orientType;

  final _SVGAnimatedLengthImpl refX;

  final _SVGAnimatedLengthImpl refY;

  void setOrientToAngle(_SVGAngleImpl angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;
}

class _SVGMaskElementImpl extends _SVGElementImpl implements SVGMaskElement native "*SVGMaskElement" {

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedEnumerationImpl maskContentUnits;

  final _SVGAnimatedEnumerationImpl maskUnits;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGMatrixImpl implements SVGMatrix native "*SVGMatrix" {

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

  _SVGMatrixImpl flipX() native;

  _SVGMatrixImpl flipY() native;

  _SVGMatrixImpl inverse() native;

  _SVGMatrixImpl multiply(_SVGMatrixImpl secondMatrix) native;

  _SVGMatrixImpl rotate(num angle) native;

  _SVGMatrixImpl rotateFromVector(num x, num y) native;

  _SVGMatrixImpl scale(num scaleFactor) native;

  _SVGMatrixImpl scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  _SVGMatrixImpl skewX(num angle) native;

  _SVGMatrixImpl skewY(num angle) native;

  _SVGMatrixImpl translate(num x, num y) native;
}

class _SVGMetadataElementImpl extends _SVGElementImpl implements SVGMetadataElement native "*SVGMetadataElement" {
}

class _SVGMissingGlyphElementImpl extends _SVGElementImpl implements SVGMissingGlyphElement native "*SVGMissingGlyphElement" {
}

class _SVGNumberImpl implements SVGNumber native "*SVGNumber" {

  num value;
}

class _SVGNumberListImpl implements SVGNumberList native "*SVGNumberList" {

  final int numberOfItems;

  _SVGNumberImpl appendItem(_SVGNumberImpl item) native;

  void clear() native;

  _SVGNumberImpl getItem(int index) native;

  _SVGNumberImpl initialize(_SVGNumberImpl item) native;

  _SVGNumberImpl insertItemBefore(_SVGNumberImpl item, int index) native;

  _SVGNumberImpl removeItem(int index) native;

  _SVGNumberImpl replaceItem(_SVGNumberImpl item, int index) native;
}

class _SVGPaintImpl extends _SVGColorImpl implements SVGPaint native "*SVGPaint" {

  static final int SVG_PAINTTYPE_CURRENTCOLOR = 102;

  static final int SVG_PAINTTYPE_NONE = 101;

  static final int SVG_PAINTTYPE_RGBCOLOR = 1;

  static final int SVG_PAINTTYPE_RGBCOLOR_ICCCOLOR = 2;

  static final int SVG_PAINTTYPE_UNKNOWN = 0;

  static final int SVG_PAINTTYPE_URI = 107;

  static final int SVG_PAINTTYPE_URI_CURRENTCOLOR = 104;

  static final int SVG_PAINTTYPE_URI_NONE = 103;

  static final int SVG_PAINTTYPE_URI_RGBCOLOR = 105;

  static final int SVG_PAINTTYPE_URI_RGBCOLOR_ICCCOLOR = 106;

  final int paintType;

  final String uri;

  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native;

  void setUri(String uri) native;
}

class _SVGPathElementImpl extends _SVGElementImpl implements SVGPathElement native "*SVGPathElement" {

  final _SVGPathSegListImpl animatedNormalizedPathSegList;

  final _SVGPathSegListImpl animatedPathSegList;

  final _SVGPathSegListImpl normalizedPathSegList;

  final _SVGAnimatedNumberImpl pathLength;

  final _SVGPathSegListImpl pathSegList;

  _SVGPathSegArcAbsImpl createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  _SVGPathSegArcRelImpl createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  _SVGPathSegClosePathImpl createSVGPathSegClosePath() native;

  _SVGPathSegCurvetoCubicAbsImpl createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  _SVGPathSegCurvetoCubicRelImpl createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  _SVGPathSegCurvetoCubicSmoothAbsImpl createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  _SVGPathSegCurvetoCubicSmoothRelImpl createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  _SVGPathSegCurvetoQuadraticAbsImpl createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  _SVGPathSegCurvetoQuadraticRelImpl createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  _SVGPathSegCurvetoQuadraticSmoothAbsImpl createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  _SVGPathSegCurvetoQuadraticSmoothRelImpl createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  _SVGPathSegLinetoAbsImpl createSVGPathSegLinetoAbs(num x, num y) native;

  _SVGPathSegLinetoHorizontalAbsImpl createSVGPathSegLinetoHorizontalAbs(num x) native;

  _SVGPathSegLinetoHorizontalRelImpl createSVGPathSegLinetoHorizontalRel(num x) native;

  _SVGPathSegLinetoRelImpl createSVGPathSegLinetoRel(num x, num y) native;

  _SVGPathSegLinetoVerticalAbsImpl createSVGPathSegLinetoVerticalAbs(num y) native;

  _SVGPathSegLinetoVerticalRelImpl createSVGPathSegLinetoVerticalRel(num y) native;

  _SVGPathSegMovetoAbsImpl createSVGPathSegMovetoAbs(num x, num y) native;

  _SVGPathSegMovetoRelImpl createSVGPathSegMovetoRel(num x, num y) native;

  int getPathSegAtLength(num distance) native;

  _SVGPointImpl getPointAtLength(num distance) native;

  num getTotalLength() native;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGPathSegImpl implements SVGPathSeg native "*SVGPathSeg" {

  static final int PATHSEG_ARC_ABS = 10;

  static final int PATHSEG_ARC_REL = 11;

  static final int PATHSEG_CLOSEPATH = 1;

  static final int PATHSEG_CURVETO_CUBIC_ABS = 6;

  static final int PATHSEG_CURVETO_CUBIC_REL = 7;

  static final int PATHSEG_CURVETO_CUBIC_SMOOTH_ABS = 16;

  static final int PATHSEG_CURVETO_CUBIC_SMOOTH_REL = 17;

  static final int PATHSEG_CURVETO_QUADRATIC_ABS = 8;

  static final int PATHSEG_CURVETO_QUADRATIC_REL = 9;

  static final int PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS = 18;

  static final int PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL = 19;

  static final int PATHSEG_LINETO_ABS = 4;

  static final int PATHSEG_LINETO_HORIZONTAL_ABS = 12;

  static final int PATHSEG_LINETO_HORIZONTAL_REL = 13;

  static final int PATHSEG_LINETO_REL = 5;

  static final int PATHSEG_LINETO_VERTICAL_ABS = 14;

  static final int PATHSEG_LINETO_VERTICAL_REL = 15;

  static final int PATHSEG_MOVETO_ABS = 2;

  static final int PATHSEG_MOVETO_REL = 3;

  static final int PATHSEG_UNKNOWN = 0;

  final int pathSegType;

  final String pathSegTypeAsLetter;
}

class _SVGPathSegArcAbsImpl extends _SVGPathSegImpl implements SVGPathSegArcAbs native "*SVGPathSegArcAbs" {

  num angle;

  bool largeArcFlag;

  num r1;

  num r2;

  bool sweepFlag;

  num x;

  num y;
}

class _SVGPathSegArcRelImpl extends _SVGPathSegImpl implements SVGPathSegArcRel native "*SVGPathSegArcRel" {

  num angle;

  bool largeArcFlag;

  num r1;

  num r2;

  bool sweepFlag;

  num x;

  num y;
}

class _SVGPathSegClosePathImpl extends _SVGPathSegImpl implements SVGPathSegClosePath native "*SVGPathSegClosePath" {
}

class _SVGPathSegCurvetoCubicAbsImpl extends _SVGPathSegImpl implements SVGPathSegCurvetoCubicAbs native "*SVGPathSegCurvetoCubicAbs" {

  num x;

  num x1;

  num x2;

  num y;

  num y1;

  num y2;
}

class _SVGPathSegCurvetoCubicRelImpl extends _SVGPathSegImpl implements SVGPathSegCurvetoCubicRel native "*SVGPathSegCurvetoCubicRel" {

  num x;

  num x1;

  num x2;

  num y;

  num y1;

  num y2;
}

class _SVGPathSegCurvetoCubicSmoothAbsImpl extends _SVGPathSegImpl implements SVGPathSegCurvetoCubicSmoothAbs native "*SVGPathSegCurvetoCubicSmoothAbs" {

  num x;

  num x2;

  num y;

  num y2;
}

class _SVGPathSegCurvetoCubicSmoothRelImpl extends _SVGPathSegImpl implements SVGPathSegCurvetoCubicSmoothRel native "*SVGPathSegCurvetoCubicSmoothRel" {

  num x;

  num x2;

  num y;

  num y2;
}

class _SVGPathSegCurvetoQuadraticAbsImpl extends _SVGPathSegImpl implements SVGPathSegCurvetoQuadraticAbs native "*SVGPathSegCurvetoQuadraticAbs" {

  num x;

  num x1;

  num y;

  num y1;
}

class _SVGPathSegCurvetoQuadraticRelImpl extends _SVGPathSegImpl implements SVGPathSegCurvetoQuadraticRel native "*SVGPathSegCurvetoQuadraticRel" {

  num x;

  num x1;

  num y;

  num y1;
}

class _SVGPathSegCurvetoQuadraticSmoothAbsImpl extends _SVGPathSegImpl implements SVGPathSegCurvetoQuadraticSmoothAbs native "*SVGPathSegCurvetoQuadraticSmoothAbs" {

  num x;

  num y;
}

class _SVGPathSegCurvetoQuadraticSmoothRelImpl extends _SVGPathSegImpl implements SVGPathSegCurvetoQuadraticSmoothRel native "*SVGPathSegCurvetoQuadraticSmoothRel" {

  num x;

  num y;
}

class _SVGPathSegLinetoAbsImpl extends _SVGPathSegImpl implements SVGPathSegLinetoAbs native "*SVGPathSegLinetoAbs" {

  num x;

  num y;
}

class _SVGPathSegLinetoHorizontalAbsImpl extends _SVGPathSegImpl implements SVGPathSegLinetoHorizontalAbs native "*SVGPathSegLinetoHorizontalAbs" {

  num x;
}

class _SVGPathSegLinetoHorizontalRelImpl extends _SVGPathSegImpl implements SVGPathSegLinetoHorizontalRel native "*SVGPathSegLinetoHorizontalRel" {

  num x;
}

class _SVGPathSegLinetoRelImpl extends _SVGPathSegImpl implements SVGPathSegLinetoRel native "*SVGPathSegLinetoRel" {

  num x;

  num y;
}

class _SVGPathSegLinetoVerticalAbsImpl extends _SVGPathSegImpl implements SVGPathSegLinetoVerticalAbs native "*SVGPathSegLinetoVerticalAbs" {

  num y;
}

class _SVGPathSegLinetoVerticalRelImpl extends _SVGPathSegImpl implements SVGPathSegLinetoVerticalRel native "*SVGPathSegLinetoVerticalRel" {

  num y;
}

class _SVGPathSegListImpl implements SVGPathSegList native "*SVGPathSegList" {

  final int numberOfItems;

  _SVGPathSegImpl appendItem(_SVGPathSegImpl newItem) native;

  void clear() native;

  _SVGPathSegImpl getItem(int index) native;

  _SVGPathSegImpl initialize(_SVGPathSegImpl newItem) native;

  _SVGPathSegImpl insertItemBefore(_SVGPathSegImpl newItem, int index) native;

  _SVGPathSegImpl removeItem(int index) native;

  _SVGPathSegImpl replaceItem(_SVGPathSegImpl newItem, int index) native;
}

class _SVGPathSegMovetoAbsImpl extends _SVGPathSegImpl implements SVGPathSegMovetoAbs native "*SVGPathSegMovetoAbs" {

  num x;

  num y;
}

class _SVGPathSegMovetoRelImpl extends _SVGPathSegImpl implements SVGPathSegMovetoRel native "*SVGPathSegMovetoRel" {

  num x;

  num y;
}

class _SVGPatternElementImpl extends _SVGElementImpl implements SVGPatternElement native "*SVGPatternElement" {

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedEnumerationImpl patternContentUnits;

  final _SVGAnimatedTransformListImpl patternTransform;

  final _SVGAnimatedEnumerationImpl patternUnits;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;
}

class _SVGPointImpl implements SVGPoint native "*SVGPoint" {

  num x;

  num y;

  _SVGPointImpl matrixTransform(_SVGMatrixImpl matrix) native;
}

class _SVGPointListImpl implements SVGPointList native "*SVGPointList" {

  final int numberOfItems;

  _SVGPointImpl appendItem(_SVGPointImpl item) native;

  void clear() native;

  _SVGPointImpl getItem(int index) native;

  _SVGPointImpl initialize(_SVGPointImpl item) native;

  _SVGPointImpl insertItemBefore(_SVGPointImpl item, int index) native;

  _SVGPointImpl removeItem(int index) native;

  _SVGPointImpl replaceItem(_SVGPointImpl item, int index) native;
}

class _SVGPolygonElementImpl extends _SVGElementImpl implements SVGPolygonElement native "*SVGPolygonElement" {

  final _SVGPointListImpl animatedPoints;

  final _SVGPointListImpl points;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGPolylineElementImpl extends _SVGElementImpl implements SVGPolylineElement native "*SVGPolylineElement" {

  final _SVGPointListImpl animatedPoints;

  final _SVGPointListImpl points;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGPreserveAspectRatioImpl implements SVGPreserveAspectRatio native "*SVGPreserveAspectRatio" {

  static final int SVG_MEETORSLICE_MEET = 1;

  static final int SVG_MEETORSLICE_SLICE = 2;

  static final int SVG_MEETORSLICE_UNKNOWN = 0;

  static final int SVG_PRESERVEASPECTRATIO_NONE = 1;

  static final int SVG_PRESERVEASPECTRATIO_UNKNOWN = 0;

  static final int SVG_PRESERVEASPECTRATIO_XMAXYMAX = 10;

  static final int SVG_PRESERVEASPECTRATIO_XMAXYMID = 7;

  static final int SVG_PRESERVEASPECTRATIO_XMAXYMIN = 4;

  static final int SVG_PRESERVEASPECTRATIO_XMIDYMAX = 9;

  static final int SVG_PRESERVEASPECTRATIO_XMIDYMID = 6;

  static final int SVG_PRESERVEASPECTRATIO_XMIDYMIN = 3;

  static final int SVG_PRESERVEASPECTRATIO_XMINYMAX = 8;

  static final int SVG_PRESERVEASPECTRATIO_XMINYMID = 5;

  static final int SVG_PRESERVEASPECTRATIO_XMINYMIN = 2;

  int align;

  int meetOrSlice;
}

class _SVGRadialGradientElementImpl extends _SVGGradientElementImpl implements SVGRadialGradientElement native "*SVGRadialGradientElement" {

  final _SVGAnimatedLengthImpl cx;

  final _SVGAnimatedLengthImpl cy;

  final _SVGAnimatedLengthImpl fx;

  final _SVGAnimatedLengthImpl fy;

  final _SVGAnimatedLengthImpl r;
}

class _SVGRectImpl implements SVGRect native "*SVGRect" {

  num height;

  num width;

  num x;

  num y;
}

class _SVGRectElementImpl extends _SVGElementImpl implements SVGRectElement native "*SVGRectElement" {

  final _SVGAnimatedLengthImpl height;

  final _SVGAnimatedLengthImpl rx;

  final _SVGAnimatedLengthImpl ry;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGRenderingIntentImpl implements SVGRenderingIntent native "*SVGRenderingIntent" {

  static final int RENDERING_INTENT_ABSOLUTE_COLORIMETRIC = 5;

  static final int RENDERING_INTENT_AUTO = 1;

  static final int RENDERING_INTENT_PERCEPTUAL = 2;

  static final int RENDERING_INTENT_RELATIVE_COLORIMETRIC = 3;

  static final int RENDERING_INTENT_SATURATION = 4;

  static final int RENDERING_INTENT_UNKNOWN = 0;
}

class _SVGSVGElementImpl extends _SVGElementImpl implements SVGSVGElement native "*SVGSVGElement" {

  String contentScriptType;

  String contentStyleType;

  num currentScale;

  final _SVGPointImpl currentTranslate;

  final _SVGAnimatedLengthImpl height;

  final num pixelUnitToMillimeterX;

  final num pixelUnitToMillimeterY;

  final num screenPixelToMillimeterX;

  final num screenPixelToMillimeterY;

  bool useCurrentView;

  final _SVGRectImpl viewport;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  bool animationsPaused() native;

  bool checkEnclosure(_SVGElementImpl element, _SVGRectImpl rect) native;

  bool checkIntersection(_SVGElementImpl element, _SVGRectImpl rect) native;

  _SVGAngleImpl createSVGAngle() native;

  _SVGLengthImpl createSVGLength() native;

  _SVGMatrixImpl createSVGMatrix() native;

  _SVGNumberImpl createSVGNumber() native;

  _SVGPointImpl createSVGPoint() native;

  _SVGRectImpl createSVGRect() native;

  _SVGTransformImpl createSVGTransform() native;

  _SVGTransformImpl createSVGTransformFromMatrix(_SVGMatrixImpl matrix) native;

  void deselectAll() native;

  void forceRedraw() native;

  num getCurrentTime() native;

  _ElementImpl getElementById(String elementId) native;

  _NodeListImpl getEnclosureList(_SVGRectImpl rect, _SVGElementImpl referenceElement) native;

  _NodeListImpl getIntersectionList(_SVGRectImpl rect, _SVGElementImpl referenceElement) native;

  void pauseAnimations() native;

  void setCurrentTime(num seconds) native;

  int suspendRedraw(int maxWaitMilliseconds) native;

  void unpauseAnimations() native;

  void unsuspendRedraw(int suspendHandleId) native;

  void unsuspendRedrawAll() native;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;

  // From SVGZoomAndPan

  int zoomAndPan;
}

class _SVGScriptElementImpl extends _SVGElementImpl implements SVGScriptElement native "*SVGScriptElement" {

  String type;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;
}

class _SVGSetElementImpl extends _SVGAnimationElementImpl implements SVGSetElement native "*SVGSetElement" {
}

class _SVGStopElementImpl extends _SVGElementImpl implements SVGStopElement native "*SVGStopElement" {

  final _SVGAnimatedNumberImpl offset;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGStringListImpl implements SVGStringList native "*SVGStringList" {

  final int numberOfItems;

  String appendItem(String item) native;

  void clear() native;

  String getItem(int index) native;

  String initialize(String item) native;

  String insertItemBefore(String item, int index) native;

  String removeItem(int index) native;

  String replaceItem(String item, int index) native;
}

class _SVGStylableImpl implements SVGStylable native "*SVGStylable" {

  _SVGAnimatedStringImpl get $dom_svgClassName() native "return this.className;";

  final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGStyleElementImpl extends _SVGElementImpl implements SVGStyleElement native "*SVGStyleElement" {

  bool disabled;

  String media;

  // Shadowing definition.
  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  String type;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;
}

class _SVGSwitchElementImpl extends _SVGElementImpl implements SVGSwitchElement native "*SVGSwitchElement" {

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGSymbolElementImpl extends _SVGElementImpl implements SVGSymbolElement native "*SVGSymbolElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;
}

class _SVGTRefElementImpl extends _SVGTextPositioningElementImpl implements SVGTRefElement native "*SVGTRefElement" {

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;
}

class _SVGTSpanElementImpl extends _SVGTextPositioningElementImpl implements SVGTSpanElement native "*SVGTSpanElement" {
}

class _SVGTestsImpl implements SVGTests native "*SVGTests" {

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;
}

class _SVGTextContentElementImpl extends _SVGElementImpl implements SVGTextContentElement native "*SVGTextContentElement" {

  static final int LENGTHADJUST_SPACING = 1;

  static final int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static final int LENGTHADJUST_UNKNOWN = 0;

  final _SVGAnimatedEnumerationImpl lengthAdjust;

  final _SVGAnimatedLengthImpl textLength;

  int getCharNumAtPosition(_SVGPointImpl point) native;

  num getComputedTextLength() native;

  _SVGPointImpl getEndPositionOfChar(int offset) native;

  _SVGRectImpl getExtentOfChar(int offset) native;

  int getNumberOfChars() native;

  num getRotationOfChar(int offset) native;

  _SVGPointImpl getStartPositionOfChar(int offset) native;

  num getSubStringLength(int offset, int length) native;

  void selectSubString(int offset, int length) native;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGTextElementImpl extends _SVGTextPositioningElementImpl implements SVGTextElement native "*SVGTextElement" {

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGTextPathElementImpl extends _SVGTextContentElementImpl implements SVGTextPathElement native "*SVGTextPathElement" {

  static final int TEXTPATH_METHODTYPE_ALIGN = 1;

  static final int TEXTPATH_METHODTYPE_STRETCH = 2;

  static final int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static final int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static final int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static final int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  final _SVGAnimatedEnumerationImpl method;

  final _SVGAnimatedEnumerationImpl spacing;

  final _SVGAnimatedLengthImpl startOffset;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;
}

class _SVGTextPositioningElementImpl extends _SVGTextContentElementImpl implements SVGTextPositioningElement native "*SVGTextPositioningElement" {

  final _SVGAnimatedLengthListImpl dx;

  final _SVGAnimatedLengthListImpl dy;

  final _SVGAnimatedNumberListImpl rotate;

  final _SVGAnimatedLengthListImpl x;

  final _SVGAnimatedLengthListImpl y;
}

class _SVGTitleElementImpl extends _SVGElementImpl implements SVGTitleElement native "*SVGTitleElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}

class _SVGTransformImpl implements SVGTransform native "*SVGTransform" {

  static final int SVG_TRANSFORM_MATRIX = 1;

  static final int SVG_TRANSFORM_ROTATE = 4;

  static final int SVG_TRANSFORM_SCALE = 3;

  static final int SVG_TRANSFORM_SKEWX = 5;

  static final int SVG_TRANSFORM_SKEWY = 6;

  static final int SVG_TRANSFORM_TRANSLATE = 2;

  static final int SVG_TRANSFORM_UNKNOWN = 0;

  final num angle;

  final _SVGMatrixImpl matrix;

  final int type;

  void setMatrix(_SVGMatrixImpl matrix) native;

  void setRotate(num angle, num cx, num cy) native;

  void setScale(num sx, num sy) native;

  void setSkewX(num angle) native;

  void setSkewY(num angle) native;

  void setTranslate(num tx, num ty) native;
}

class _SVGTransformListImpl implements SVGTransformList native "*SVGTransformList" {

  final int numberOfItems;

  _SVGTransformImpl appendItem(_SVGTransformImpl item) native;

  void clear() native;

  _SVGTransformImpl consolidate() native;

  _SVGTransformImpl createSVGTransformFromMatrix(_SVGMatrixImpl matrix) native;

  _SVGTransformImpl getItem(int index) native;

  _SVGTransformImpl initialize(_SVGTransformImpl item) native;

  _SVGTransformImpl insertItemBefore(_SVGTransformImpl item, int index) native;

  _SVGTransformImpl removeItem(int index) native;

  _SVGTransformImpl replaceItem(_SVGTransformImpl item, int index) native;
}

class _SVGTransformableImpl extends _SVGLocatableImpl implements SVGTransformable native "*SVGTransformable" {

  final _SVGAnimatedTransformListImpl transform;
}

class _SVGURIReferenceImpl implements SVGURIReference native "*SVGURIReference" {

  final _SVGAnimatedStringImpl href;
}

class _SVGUnitTypesImpl implements SVGUnitTypes native "*SVGUnitTypes" {

  static final int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static final int SVG_UNIT_TYPE_UNKNOWN = 0;

  static final int SVG_UNIT_TYPE_USERSPACEONUSE = 1;
}

class _SVGUseElementImpl extends _SVGElementImpl implements SVGUseElement native "*SVGUseElement" {

  final _SVGElementInstanceImpl animatedInstanceRoot;

  final _SVGAnimatedLengthImpl height;

  final _SVGElementInstanceImpl instanceRoot;

  final _SVGAnimatedLengthImpl width;

  final _SVGAnimatedLengthImpl x;

  final _SVGAnimatedLengthImpl y;

  // From SVGURIReference

  final _SVGAnimatedStringImpl href;

  // From SVGTests

  final _SVGStringListImpl requiredExtensions;

  final _SVGStringListImpl requiredFeatures;

  final _SVGStringListImpl systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get $dom_$dom_svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListImpl transform;

  // From SVGLocatable

  final _SVGElementImpl farthestViewportElement;

  final _SVGElementImpl nearestViewportElement;

  _SVGRectImpl getBBox() native;

  _SVGMatrixImpl getCTM() native;

  _SVGMatrixImpl getScreenCTM() native;

  _SVGMatrixImpl getTransformToElement(_SVGElementImpl element) native;
}

class _SVGVKernElementImpl extends _SVGElementImpl implements SVGVKernElement native "*SVGVKernElement" {
}

class _SVGViewElementImpl extends _SVGElementImpl implements SVGViewElement native "*SVGViewElement" {

  final _SVGStringListImpl viewTarget;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;

  // From SVGZoomAndPan

  int zoomAndPan;
}

class _SVGViewSpecImpl extends _SVGZoomAndPanImpl implements SVGViewSpec native "*SVGViewSpec" {

  final String preserveAspectRatioString;

  final _SVGTransformListImpl transform;

  final String transformString;

  final String viewBoxString;

  final _SVGElementImpl viewTarget;

  final String viewTargetString;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;
}

class _SVGZoomAndPanImpl implements SVGZoomAndPan native "*SVGZoomAndPan" {

  static final int SVG_ZOOMANDPAN_DISABLE = 1;

  static final int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static final int SVG_ZOOMANDPAN_UNKNOWN = 0;

  int zoomAndPan;
}

class _SVGZoomEventImpl extends _UIEventImpl implements SVGZoomEvent native "*SVGZoomEvent" {

  final num newScale;

  final _SVGPointImpl newTranslate;

  final num previousScale;

  final _SVGPointImpl previousTranslate;

  final _SVGRectImpl zoomRectScreen;
}

class _ScreenImpl implements Screen native "*Screen" {

  final int availHeight;

  final int availLeft;

  final int availTop;

  final int availWidth;

  final int colorDepth;

  final int height;

  final int pixelDepth;

  final int width;
}

class _ScriptElementImpl extends _ElementImpl implements ScriptElement native "*HTMLScriptElement" {

  bool async;

  String charset;

  String crossOrigin;

  bool defer;

  String event;

  String htmlFor;

  String src;

  String type;
}

class _ScriptProfileImpl implements ScriptProfile native "*ScriptProfile" {

  final _ScriptProfileNodeImpl head;

  final String title;

  final int uid;
}

class _ScriptProfileNodeImpl implements ScriptProfileNode native "*ScriptProfileNode" {

  final int callUID;

  final List<ScriptProfileNode> children;

  final String functionName;

  final int lineNumber;

  final int numberOfCalls;

  final num selfTime;

  final num totalTime;

  final String url;

  final bool visible;
}

class _SelectElementImpl extends _ElementImpl implements SelectElement native "*HTMLSelectElement" {

  bool autofocus;

  bool disabled;

  final _FormElementImpl form;

  final _NodeListImpl labels;

  int length;

  bool multiple;

  String name;

  final _HTMLOptionsCollectionImpl options;

  bool required;

  int selectedIndex;

  final _HTMLCollectionImpl selectedOptions;

  int size;

  final String type;

  final String validationMessage;

  final _ValidityStateImpl validity;

  String value;

  final bool willValidate;

  void add(_ElementImpl element, _ElementImpl before) native;

  bool checkValidity() native;

  _NodeImpl item(int index) native;

  _NodeImpl namedItem(String name) native;

  void setCustomValidity(String error) native;
}

class _SessionDescriptionImpl implements SessionDescription native "*SessionDescription" {

  void addCandidate(_IceCandidateImpl candidate) native;

  String toSdp() native;
}

class _ShadowElementImpl extends _ElementImpl implements ShadowElement native "*HTMLShadowElement" {
}

class _ShadowRootImpl extends _DocumentFragmentImpl implements ShadowRoot native "*ShadowRoot" {

  final _ElementImpl activeElement;

  final _ElementImpl host;

  String innerHTML;

  _ElementImpl getElementById(String elementId) native;

  _NodeListImpl getElementsByClassName(String className) native;

  _NodeListImpl getElementsByTagName(String tagName) native;

  _NodeListImpl getElementsByTagNameNS(String namespaceURI, String localName) native;
}

class _SharedWorkerImpl extends _AbstractWorkerImpl implements SharedWorker native "*SharedWorker" {

  final _MessagePortImpl port;
}

class _SharedWorkerContextImpl extends _WorkerContextImpl implements SharedWorkerContext native "*SharedWorkerContext" {

  final String name;

  EventListener onconnect;
}

class _SourceElementImpl extends _ElementImpl implements SourceElement native "*HTMLSourceElement" {

  String media;

  String src;

  String type;
}

class _SpanElementImpl extends _ElementImpl implements SpanElement native "*HTMLSpanElement" {
}

class _SpeechGrammarImpl implements SpeechGrammar native "*SpeechGrammar" {

  String src;

  num weight;
}

class _SpeechGrammarListImpl implements SpeechGrammarList native "*SpeechGrammarList" {

  final int length;

  void addFromString(String string, [num weight = null]) native;

  void addFromUri(String src, [num weight = null]) native;

  _SpeechGrammarImpl item(int index) native;
}

class _SpeechInputEventImpl extends _EventImpl implements SpeechInputEvent native "*SpeechInputEvent" {

  final _SpeechInputResultListImpl results;
}

class _SpeechInputResultImpl implements SpeechInputResult native "*SpeechInputResult" {

  final num confidence;

  final String utterance;
}

class _SpeechInputResultListImpl implements SpeechInputResultList native "*SpeechInputResultList" {

  final int length;

  _SpeechInputResultImpl item(int index) native;
}

class _SpeechRecognitionImpl implements SpeechRecognition native "*SpeechRecognition" {

  bool continuous;

  _SpeechGrammarListImpl grammars;

  String lang;

  EventListener onaudioend;

  EventListener onaudiostart;

  EventListener onend;

  EventListener onerror;

  EventListener onnomatch;

  EventListener onresult;

  EventListener onresultdeleted;

  EventListener onsoundend;

  EventListener onsoundstart;

  EventListener onspeechend;

  EventListener onspeechstart;

  EventListener onstart;

  void abort() native;

  void start() native;

  void stop() native;
}

class _SpeechRecognitionAlternativeImpl implements SpeechRecognitionAlternative native "*SpeechRecognitionAlternative" {

  final num confidence;

  final String transcript;
}

class _SpeechRecognitionErrorImpl implements SpeechRecognitionError native "*SpeechRecognitionError" {

  static final int ABORTED = 2;

  static final int AUDIO_CAPTURE = 3;

  static final int BAD_GRAMMAR = 7;

  static final int LANGUAGE_NOT_SUPPORTED = 8;

  static final int NETWORK = 4;

  static final int NOT_ALLOWED = 5;

  static final int NO_SPEECH = 1;

  static final int OTHER = 0;

  static final int SERVICE_NOT_ALLOWED = 6;

  final int code;

  final String message;
}

class _SpeechRecognitionEventImpl extends _EventImpl implements SpeechRecognitionEvent native "*SpeechRecognitionEvent" {

  final _SpeechRecognitionErrorImpl error;

  final _SpeechRecognitionResultImpl result;

  final _SpeechRecognitionResultListImpl resultHistory;

  final int resultIndex;
}

class _SpeechRecognitionResultImpl implements SpeechRecognitionResult native "*SpeechRecognitionResult" {

  bool get finalValue() native "return this.final;";

  final int length;

  _SpeechRecognitionAlternativeImpl item(int index) native;
}

class _SpeechRecognitionResultListImpl implements SpeechRecognitionResultList native "*SpeechRecognitionResultList" {

  final int length;

  _SpeechRecognitionResultImpl item(int index) native;
}

class _StorageImpl implements Storage native "*Storage" {

  final int length;

  void clear() native;

  String getItem(String key) native;

  String key(int index) native;

  void removeItem(String key) native;

  void setItem(String key, String data) native;
}

class _StorageEventImpl extends _EventImpl implements StorageEvent native "*StorageEvent" {

  final String key;

  final String newValue;

  final String oldValue;

  final _StorageImpl storageArea;

  final String url;

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, _StorageImpl storageAreaArg) native;
}

class _StorageInfoImpl implements StorageInfo native "*StorageInfo" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback = null, StorageInfoErrorCallback errorCallback = null]) native;

  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback = null, StorageInfoErrorCallback errorCallback = null]) native;
}

class _StyleElementImpl extends _ElementImpl implements StyleElement native "*HTMLStyleElement" {

  bool disabled;

  String media;

  final _StyleSheetImpl sheet;

  String type;
}

class _StyleMediaImpl implements StyleMedia native "*StyleMedia" {

  final String type;

  bool matchMedium(String mediaquery) native;
}

class _StyleSheetImpl implements StyleSheet native "*StyleSheet" {

  bool disabled;

  final String href;

  final _MediaListImpl media;

  final _NodeImpl ownerNode;

  final _StyleSheetImpl parentStyleSheet;

  final String title;

  final String type;
}

class _StyleSheetListImpl implements StyleSheetList native "*StyleSheetList" {

  final int length;

  _StyleSheetImpl operator[](int index) native "return this[index];";

  void operator[]=(int index, _StyleSheetImpl value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }
  // -- start List<StyleSheet> mixins.
  // StyleSheet is the element type.

  // From Iterable<StyleSheet>:

  Iterator<StyleSheet> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<StyleSheet>(this);
  }

  // From Collection<StyleSheet>:

  void add(StyleSheet value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(StyleSheet value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<StyleSheet> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(StyleSheet element)) => _Collections.forEach(this, f);

  Collection map(f(StyleSheet element)) => _Collections.map(this, [], f);

  Collection<StyleSheet> filter(bool f(StyleSheet element)) =>
     _Collections.filter(this, <StyleSheet>[], f);

  bool every(bool f(StyleSheet element)) => _Collections.every(this, f);

  bool some(bool f(StyleSheet element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<StyleSheet>:

  void sort(int compare(StyleSheet a, StyleSheet b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(StyleSheet element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(StyleSheet element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  StyleSheet last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<StyleSheet> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [StyleSheet initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<StyleSheet> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <StyleSheet>[]);

  // -- end List<StyleSheet> mixins.

  _StyleSheetImpl item(int index) native;
}

class _TableCaptionElementImpl extends _ElementImpl implements TableCaptionElement native "*HTMLTableCaptionElement" {

  String align;
}

class _TableCellElementImpl extends _ElementImpl implements TableCellElement native "*HTMLTableCellElement" {

  String abbr;

  String align;

  String axis;

  String bgColor;

  final int cellIndex;

  String ch;

  String chOff;

  int colSpan;

  String headers;

  String height;

  bool noWrap;

  int rowSpan;

  String scope;

  String vAlign;

  String width;
}

class _TableColElementImpl extends _ElementImpl implements TableColElement native "*HTMLTableColElement" {

  String align;

  String ch;

  String chOff;

  int span;

  String vAlign;

  String width;
}

class _TableElementImpl extends _ElementImpl implements TableElement native "*HTMLTableElement" {

  String align;

  String bgColor;

  String border;

  _TableCaptionElementImpl caption;

  String cellPadding;

  String cellSpacing;

  String frame;

  final _HTMLCollectionImpl rows;

  String rules;

  String summary;

  final _HTMLCollectionImpl tBodies;

  _TableSectionElementImpl tFoot;

  _TableSectionElementImpl tHead;

  String width;

  _ElementImpl createCaption() native;

  _ElementImpl createTFoot() native;

  _ElementImpl createTHead() native;

  void deleteCaption() native;

  void deleteRow(int index) native;

  void deleteTFoot() native;

  void deleteTHead() native;

  _ElementImpl insertRow(int index) native;
}

class _TableRowElementImpl extends _ElementImpl implements TableRowElement native "*HTMLTableRowElement" {

  String align;

  String bgColor;

  final _HTMLCollectionImpl cells;

  String ch;

  String chOff;

  final int rowIndex;

  final int sectionRowIndex;

  String vAlign;

  void deleteCell(int index) native;

  _ElementImpl insertCell(int index) native;
}

class _TableSectionElementImpl extends _ElementImpl implements TableSectionElement native "*HTMLTableSectionElement" {

  String align;

  String ch;

  String chOff;

  final _HTMLCollectionImpl rows;

  String vAlign;

  void deleteRow(int index) native;

  _ElementImpl insertRow(int index) native;
}

class _TextImpl extends _CharacterDataImpl implements Text native "*Text" {

  final String wholeText;

  _TextImpl replaceWholeText(String content) native;

  _TextImpl splitText(int offset) native;
}

class _TextAreaElementImpl extends _ElementImpl implements TextAreaElement native "*HTMLTextAreaElement" {

  bool autofocus;

  int cols;

  String defaultValue;

  bool disabled;

  final _FormElementImpl form;

  final _NodeListImpl labels;

  int maxLength;

  String name;

  String placeholder;

  bool readOnly;

  bool required;

  int rows;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  final int textLength;

  final String type;

  final String validationMessage;

  final _ValidityStateImpl validity;

  String value;

  final bool willValidate;

  String wrap;

  bool checkValidity() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;
}

class _TextEventImpl extends _UIEventImpl implements TextEvent native "*TextEvent" {

  final String data;

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, _WindowImpl viewArg, String dataArg) native;
}

class _TextMetricsImpl implements TextMetrics native "*TextMetrics" {

  final num width;
}

class _TextTrackImpl implements TextTrack native "*TextTrack" {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  final _TextTrackCueListImpl activeCues;

  final _TextTrackCueListImpl cues;

  final String kind;

  final String label;

  final String language;

  int mode;

  EventListener oncuechange;

  void addCue(_TextTrackCueImpl cue) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  void removeCue(_TextTrackCueImpl cue) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _TextTrackCueImpl implements TextTrackCue native "*TextTrackCue" {

  String align;

  num endTime;

  String id;

  int line;

  EventListener onenter;

  EventListener onexit;

  bool pauseOnExit;

  int position;

  int size;

  bool snapToLines;

  num startTime;

  String text;

  final _TextTrackImpl track;

  String vertical;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  _DocumentFragmentImpl getCueAsHTML() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _TextTrackCueListImpl implements TextTrackCueList native "*TextTrackCueList" {

  final int length;

  _TextTrackCueImpl getCueById(String id) native;

  _TextTrackCueImpl item(int index) native;
}

class _TextTrackListImpl implements TextTrackList native "*TextTrackList" {

  final int length;

  EventListener onaddtrack;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  _TextTrackImpl item(int index) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _TimeRangesImpl implements TimeRanges native "*TimeRanges" {

  final int length;

  num end(int index) native;

  num start(int index) native;
}

class _TitleElementImpl extends _ElementImpl implements TitleElement native "*HTMLTitleElement" {
}

class _TouchImpl implements Touch native "*Touch" {

  final int clientX;

  final int clientY;

  final int identifier;

  final int pageX;

  final int pageY;

  final int screenX;

  final int screenY;

  final _EventTargetImpl target;

  final num webkitForce;

  final int webkitRadiusX;

  final int webkitRadiusY;

  final num webkitRotationAngle;
}

class _TouchEventImpl extends _UIEventImpl implements TouchEvent native "*TouchEvent" {

  final bool altKey;

  final _TouchListImpl changedTouches;

  final bool ctrlKey;

  final bool metaKey;

  final bool shiftKey;

  final _TouchListImpl targetTouches;

  final _TouchListImpl touches;

  void initTouchEvent(_TouchListImpl touches, _TouchListImpl targetTouches, _TouchListImpl changedTouches, String type, _WindowImpl view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}

class _TouchListImpl implements TouchList native "*TouchList" {

  final int length;

  _TouchImpl operator[](int index) native "return this[index];";

  void operator[]=(int index, _TouchImpl value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }
  // -- start List<Touch> mixins.
  // Touch is the element type.

  // From Iterable<Touch>:

  Iterator<Touch> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<Touch>(this);
  }

  // From Collection<Touch>:

  void add(Touch value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(Touch value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<Touch> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(Touch element)) => _Collections.forEach(this, f);

  Collection map(f(Touch element)) => _Collections.map(this, [], f);

  Collection<Touch> filter(bool f(Touch element)) =>
     _Collections.filter(this, <Touch>[], f);

  bool every(bool f(Touch element)) => _Collections.every(this, f);

  bool some(bool f(Touch element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<Touch>:

  void sort(int compare(Touch a, Touch b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(Touch element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Touch element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  Touch last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<Touch> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [Touch initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<Touch> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <Touch>[]);

  // -- end List<Touch> mixins.

  _TouchImpl item(int index) native;
}

class _TrackElementImpl extends _ElementImpl implements TrackElement native "*HTMLTrackElement" {

  static final int ERROR = 3;

  static final int LOADED = 2;

  static final int LOADING = 1;

  static final int NONE = 0;

  bool get defaultValue() native "return this.default;";

  void set defaultValue(bool value) native "this.default = value;";

  String kind;

  String label;

  final int readyState;

  String src;

  String srclang;

  final _TextTrackImpl track;
}

class _TrackEventImpl extends _EventImpl implements TrackEvent native "*TrackEvent" {

  final Object track;
}

class _TransitionEventImpl extends _EventImpl implements TransitionEvent native "*WebKitTransitionEvent" {

  final num elapsedTime;

  final String propertyName;
}

class _TreeWalkerImpl implements TreeWalker native "*TreeWalker" {

  _NodeImpl currentNode;

  final bool expandEntityReferences;

  final _NodeFilterImpl filter;

  final _NodeImpl root;

  final int whatToShow;

  _NodeImpl firstChild() native;

  _NodeImpl lastChild() native;

  _NodeImpl nextNode() native;

  _NodeImpl nextSibling() native;

  _NodeImpl parentNode() native;

  _NodeImpl previousNode() native;

  _NodeImpl previousSibling() native;
}

class _UIEventImpl extends _EventImpl implements UIEvent native "*UIEvent" {

  final int charCode;

  final int detail;

  final int keyCode;

  final int layerX;

  final int layerY;

  final int pageX;

  final int pageY;

  final _WindowImpl view;

  final int which;

  void initUIEvent(String type, bool canBubble, bool cancelable, _WindowImpl view, int detail) native;
}

class _UListElementImpl extends _ElementImpl implements UListElement native "*HTMLUListElement" {

  bool compact;

  String type;
}

class _Uint16ArrayImpl extends _ArrayBufferViewImpl implements Uint16Array, List<int> native "*Uint16Array" {

  factory Uint16Array(int length) =>  _construct_Uint16Array(length);

  factory Uint16Array.fromList(List<int> list) => _construct_Uint16Array(list);

  factory Uint16Array.fromBuffer(ArrayBuffer buffer) => _construct_Uint16Array(buffer);

  static _construct_Uint16Array(arg) native 'return new Uint16Array(arg);';

  static final int BYTES_PER_ELEMENT = 2;

  final int length;

  int operator[](int index) native "return this[index];";

  void operator[]=(int index, int value) native "this[index] = value";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<int>:

  void sort(int compare(int a, int b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  int last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<int> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [int initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<int> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <int>[]);

  // -- end List<int> mixins.

  void setElements(Object array, [int offset = null]) native;

  _Uint16ArrayImpl subarray(int start, [int end = null]) native;
}

class _Uint32ArrayImpl extends _ArrayBufferViewImpl implements Uint32Array, List<int> native "*Uint32Array" {

  factory Uint32Array(int length) =>  _construct_Uint32Array(length);

  factory Uint32Array.fromList(List<int> list) => _construct_Uint32Array(list);

  factory Uint32Array.fromBuffer(ArrayBuffer buffer) => _construct_Uint32Array(buffer);

  static _construct_Uint32Array(arg) native 'return new Uint32Array(arg);';

  static final int BYTES_PER_ELEMENT = 4;

  final int length;

  int operator[](int index) native "return this[index];";

  void operator[]=(int index, int value) native "this[index] = value";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<int>:

  void sort(int compare(int a, int b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  int last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<int> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [int initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<int> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <int>[]);

  // -- end List<int> mixins.

  void setElements(Object array, [int offset = null]) native;

  _Uint32ArrayImpl subarray(int start, [int end = null]) native;
}

class _Uint8ArrayImpl extends _ArrayBufferViewImpl implements Uint8Array, List<int> native "*Uint8Array" {

  factory Uint8Array(int length) =>  _construct_Uint8Array(length);

  factory Uint8Array.fromList(List<int> list) => _construct_Uint8Array(list);

  factory Uint8Array.fromBuffer(ArrayBuffer buffer) => _construct_Uint8Array(buffer);

  static _construct_Uint8Array(arg) native 'return new Uint8Array(arg);';

  static final int BYTES_PER_ELEMENT = 1;

  final int length;

  int operator[](int index) native "return this[index];";

  void operator[]=(int index, int value) native "this[index] = value";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<int>:

  void sort(int compare(int a, int b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  int last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<int> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [int initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<int> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <int>[]);

  // -- end List<int> mixins.

  void setElements(Object array, [int offset = null]) native;

  _Uint8ArrayImpl subarray(int start, [int end = null]) native;
}

class _Uint8ClampedArrayImpl extends _Uint8ArrayImpl implements Uint8ClampedArray, List<int> native "*Uint8ClampedArray" {

  factory Uint8ClampedArray(int length) =>  _construct_Uint8ClampedArray(length);

  factory Uint8ClampedArray.fromList(List<int> list) => _construct_Uint8ClampedArray(list);

  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer) => _construct_Uint8ClampedArray(buffer);

  static _construct_Uint8ClampedArray(arg) native 'return new Uint8ClampedArray(arg);';

  // Use implementation from Uint8Array.
  // final int length;

  void setElements(Object array, [int offset = null]) native;

  _Uint8ClampedArrayImpl subarray(int start, [int end = null]) native;
}

class _UnknownElementImpl extends _ElementImpl implements UnknownElement native "*HTMLUnknownElement" {
}

class _ValidityStateImpl implements ValidityState native "*ValidityState" {

  final bool customError;

  final bool patternMismatch;

  final bool rangeOverflow;

  final bool rangeUnderflow;

  final bool stepMismatch;

  final bool tooLong;

  final bool typeMismatch;

  final bool valid;

  final bool valueMissing;
}

class _VideoElementImpl extends _MediaElementImpl implements VideoElement native "*HTMLVideoElement" {

  int height;

  String poster;

  final int videoHeight;

  final int videoWidth;

  final int webkitDecodedFrameCount;

  final bool webkitDisplayingFullscreen;

  final int webkitDroppedFrameCount;

  final bool webkitSupportsFullscreen;

  int width;

  void webkitEnterFullScreen() native;

  void webkitEnterFullscreen() native;

  void webkitExitFullScreen() native;

  void webkitExitFullscreen() native;
}

class _WaveShaperNodeImpl extends _AudioNodeImpl implements WaveShaperNode native "*WaveShaperNode" {

  _Float32ArrayImpl curve;
}

class _WebGLActiveInfoImpl implements WebGLActiveInfo native "*WebGLActiveInfo" {

  final String name;

  final int size;

  final int type;
}

class _WebGLBufferImpl implements WebGLBuffer native "*WebGLBuffer" {
}

class _WebGLCompressedTextureS3TCImpl implements WebGLCompressedTextureS3TC native "*WebGLCompressedTextureS3TC" {

  static final int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  static final int COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;

  static final int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  static final int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;
}

class _WebGLContextAttributesImpl implements WebGLContextAttributes native "*WebGLContextAttributes" {

  bool alpha;

  bool antialias;

  bool depth;

  bool premultipliedAlpha;

  bool preserveDrawingBuffer;

  bool stencil;
}

class _WebGLContextEventImpl extends _EventImpl implements WebGLContextEvent native "*WebGLContextEvent" {

  final String statusMessage;
}

class _WebGLDebugRendererInfoImpl implements WebGLDebugRendererInfo native "*WebGLDebugRendererInfo" {

  static final int UNMASKED_RENDERER_WEBGL = 0x9246;

  static final int UNMASKED_VENDOR_WEBGL = 0x9245;
}

class _WebGLDebugShadersImpl implements WebGLDebugShaders native "*WebGLDebugShaders" {

  String getTranslatedShaderSource(_WebGLShaderImpl shader) native;
}

class _WebGLFramebufferImpl implements WebGLFramebuffer native "*WebGLFramebuffer" {
}

class _WebGLLoseContextImpl implements WebGLLoseContext native "*WebGLLoseContext" {

  void loseContext() native;

  void restoreContext() native;
}

class _WebGLProgramImpl implements WebGLProgram native "*WebGLProgram" {
}

class _WebGLRenderbufferImpl implements WebGLRenderbuffer native "*WebGLRenderbuffer" {
}

class _WebGLRenderingContextImpl extends _CanvasRenderingContextImpl implements WebGLRenderingContext native "*WebGLRenderingContext" {

  static final int ACTIVE_ATTRIBUTES = 0x8B89;

  static final int ACTIVE_TEXTURE = 0x84E0;

  static final int ACTIVE_UNIFORMS = 0x8B86;

  static final int ALIASED_LINE_WIDTH_RANGE = 0x846E;

  static final int ALIASED_POINT_SIZE_RANGE = 0x846D;

  static final int ALPHA = 0x1906;

  static final int ALPHA_BITS = 0x0D55;

  static final int ALWAYS = 0x0207;

  static final int ARRAY_BUFFER = 0x8892;

  static final int ARRAY_BUFFER_BINDING = 0x8894;

  static final int ATTACHED_SHADERS = 0x8B85;

  static final int BACK = 0x0405;

  static final int BLEND = 0x0BE2;

  static final int BLEND_COLOR = 0x8005;

  static final int BLEND_DST_ALPHA = 0x80CA;

  static final int BLEND_DST_RGB = 0x80C8;

  static final int BLEND_EQUATION = 0x8009;

  static final int BLEND_EQUATION_ALPHA = 0x883D;

  static final int BLEND_EQUATION_RGB = 0x8009;

  static final int BLEND_SRC_ALPHA = 0x80CB;

  static final int BLEND_SRC_RGB = 0x80C9;

  static final int BLUE_BITS = 0x0D54;

  static final int BOOL = 0x8B56;

  static final int BOOL_VEC2 = 0x8B57;

  static final int BOOL_VEC3 = 0x8B58;

  static final int BOOL_VEC4 = 0x8B59;

  static final int BROWSER_DEFAULT_WEBGL = 0x9244;

  static final int BUFFER_SIZE = 0x8764;

  static final int BUFFER_USAGE = 0x8765;

  static final int BYTE = 0x1400;

  static final int CCW = 0x0901;

  static final int CLAMP_TO_EDGE = 0x812F;

  static final int COLOR_ATTACHMENT0 = 0x8CE0;

  static final int COLOR_BUFFER_BIT = 0x00004000;

  static final int COLOR_CLEAR_VALUE = 0x0C22;

  static final int COLOR_WRITEMASK = 0x0C23;

  static final int COMPILE_STATUS = 0x8B81;

  static final int COMPRESSED_TEXTURE_FORMATS = 0x86A3;

  static final int CONSTANT_ALPHA = 0x8003;

  static final int CONSTANT_COLOR = 0x8001;

  static final int CONTEXT_LOST_WEBGL = 0x9242;

  static final int CULL_FACE = 0x0B44;

  static final int CULL_FACE_MODE = 0x0B45;

  static final int CURRENT_PROGRAM = 0x8B8D;

  static final int CURRENT_VERTEX_ATTRIB = 0x8626;

  static final int CW = 0x0900;

  static final int DECR = 0x1E03;

  static final int DECR_WRAP = 0x8508;

  static final int DELETE_STATUS = 0x8B80;

  static final int DEPTH_ATTACHMENT = 0x8D00;

  static final int DEPTH_BITS = 0x0D56;

  static final int DEPTH_BUFFER_BIT = 0x00000100;

  static final int DEPTH_CLEAR_VALUE = 0x0B73;

  static final int DEPTH_COMPONENT = 0x1902;

  static final int DEPTH_COMPONENT16 = 0x81A5;

  static final int DEPTH_FUNC = 0x0B74;

  static final int DEPTH_RANGE = 0x0B70;

  static final int DEPTH_STENCIL = 0x84F9;

  static final int DEPTH_STENCIL_ATTACHMENT = 0x821A;

  static final int DEPTH_TEST = 0x0B71;

  static final int DEPTH_WRITEMASK = 0x0B72;

  static final int DITHER = 0x0BD0;

  static final int DONT_CARE = 0x1100;

  static final int DST_ALPHA = 0x0304;

  static final int DST_COLOR = 0x0306;

  static final int DYNAMIC_DRAW = 0x88E8;

  static final int ELEMENT_ARRAY_BUFFER = 0x8893;

  static final int ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;

  static final int EQUAL = 0x0202;

  static final int FASTEST = 0x1101;

  static final int FLOAT = 0x1406;

  static final int FLOAT_MAT2 = 0x8B5A;

  static final int FLOAT_MAT3 = 0x8B5B;

  static final int FLOAT_MAT4 = 0x8B5C;

  static final int FLOAT_VEC2 = 0x8B50;

  static final int FLOAT_VEC3 = 0x8B51;

  static final int FLOAT_VEC4 = 0x8B52;

  static final int FRAGMENT_SHADER = 0x8B30;

  static final int FRAMEBUFFER = 0x8D40;

  static final int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;

  static final int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;

  static final int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

  static final int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;

  static final int FRAMEBUFFER_BINDING = 0x8CA6;

  static final int FRAMEBUFFER_COMPLETE = 0x8CD5;

  static final int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;

  static final int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;

  static final int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;

  static final int FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

  static final int FRONT = 0x0404;

  static final int FRONT_AND_BACK = 0x0408;

  static final int FRONT_FACE = 0x0B46;

  static final int FUNC_ADD = 0x8006;

  static final int FUNC_REVERSE_SUBTRACT = 0x800B;

  static final int FUNC_SUBTRACT = 0x800A;

  static final int GENERATE_MIPMAP_HINT = 0x8192;

  static final int GEQUAL = 0x0206;

  static final int GREATER = 0x0204;

  static final int GREEN_BITS = 0x0D53;

  static final int HIGH_FLOAT = 0x8DF2;

  static final int HIGH_INT = 0x8DF5;

  static final int INCR = 0x1E02;

  static final int INCR_WRAP = 0x8507;

  static final int INT = 0x1404;

  static final int INT_VEC2 = 0x8B53;

  static final int INT_VEC3 = 0x8B54;

  static final int INT_VEC4 = 0x8B55;

  static final int INVALID_ENUM = 0x0500;

  static final int INVALID_FRAMEBUFFER_OPERATION = 0x0506;

  static final int INVALID_OPERATION = 0x0502;

  static final int INVALID_VALUE = 0x0501;

  static final int INVERT = 0x150A;

  static final int KEEP = 0x1E00;

  static final int LEQUAL = 0x0203;

  static final int LESS = 0x0201;

  static final int LINEAR = 0x2601;

  static final int LINEAR_MIPMAP_LINEAR = 0x2703;

  static final int LINEAR_MIPMAP_NEAREST = 0x2701;

  static final int LINES = 0x0001;

  static final int LINE_LOOP = 0x0002;

  static final int LINE_STRIP = 0x0003;

  static final int LINE_WIDTH = 0x0B21;

  static final int LINK_STATUS = 0x8B82;

  static final int LOW_FLOAT = 0x8DF0;

  static final int LOW_INT = 0x8DF3;

  static final int LUMINANCE = 0x1909;

  static final int LUMINANCE_ALPHA = 0x190A;

  static final int MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;

  static final int MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

  static final int MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;

  static final int MAX_RENDERBUFFER_SIZE = 0x84E8;

  static final int MAX_TEXTURE_IMAGE_UNITS = 0x8872;

  static final int MAX_TEXTURE_SIZE = 0x0D33;

  static final int MAX_VARYING_VECTORS = 0x8DFC;

  static final int MAX_VERTEX_ATTRIBS = 0x8869;

  static final int MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;

  static final int MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;

  static final int MAX_VIEWPORT_DIMS = 0x0D3A;

  static final int MEDIUM_FLOAT = 0x8DF1;

  static final int MEDIUM_INT = 0x8DF4;

  static final int MIRRORED_REPEAT = 0x8370;

  static final int NEAREST = 0x2600;

  static final int NEAREST_MIPMAP_LINEAR = 0x2702;

  static final int NEAREST_MIPMAP_NEAREST = 0x2700;

  static final int NEVER = 0x0200;

  static final int NICEST = 0x1102;

  static final int NONE = 0;

  static final int NOTEQUAL = 0x0205;

  static final int NO_ERROR = 0;

  static final int ONE = 1;

  static final int ONE_MINUS_CONSTANT_ALPHA = 0x8004;

  static final int ONE_MINUS_CONSTANT_COLOR = 0x8002;

  static final int ONE_MINUS_DST_ALPHA = 0x0305;

  static final int ONE_MINUS_DST_COLOR = 0x0307;

  static final int ONE_MINUS_SRC_ALPHA = 0x0303;

  static final int ONE_MINUS_SRC_COLOR = 0x0301;

  static final int OUT_OF_MEMORY = 0x0505;

  static final int PACK_ALIGNMENT = 0x0D05;

  static final int POINTS = 0x0000;

  static final int POLYGON_OFFSET_FACTOR = 0x8038;

  static final int POLYGON_OFFSET_FILL = 0x8037;

  static final int POLYGON_OFFSET_UNITS = 0x2A00;

  static final int RED_BITS = 0x0D52;

  static final int RENDERBUFFER = 0x8D41;

  static final int RENDERBUFFER_ALPHA_SIZE = 0x8D53;

  static final int RENDERBUFFER_BINDING = 0x8CA7;

  static final int RENDERBUFFER_BLUE_SIZE = 0x8D52;

  static final int RENDERBUFFER_DEPTH_SIZE = 0x8D54;

  static final int RENDERBUFFER_GREEN_SIZE = 0x8D51;

  static final int RENDERBUFFER_HEIGHT = 0x8D43;

  static final int RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;

  static final int RENDERBUFFER_RED_SIZE = 0x8D50;

  static final int RENDERBUFFER_STENCIL_SIZE = 0x8D55;

  static final int RENDERBUFFER_WIDTH = 0x8D42;

  static final int RENDERER = 0x1F01;

  static final int REPEAT = 0x2901;

  static final int REPLACE = 0x1E01;

  static final int RGB = 0x1907;

  static final int RGB565 = 0x8D62;

  static final int RGB5_A1 = 0x8057;

  static final int RGBA = 0x1908;

  static final int RGBA4 = 0x8056;

  static final int SAMPLER_2D = 0x8B5E;

  static final int SAMPLER_CUBE = 0x8B60;

  static final int SAMPLES = 0x80A9;

  static final int SAMPLE_ALPHA_TO_COVERAGE = 0x809E;

  static final int SAMPLE_BUFFERS = 0x80A8;

  static final int SAMPLE_COVERAGE = 0x80A0;

  static final int SAMPLE_COVERAGE_INVERT = 0x80AB;

  static final int SAMPLE_COVERAGE_VALUE = 0x80AA;

  static final int SCISSOR_BOX = 0x0C10;

  static final int SCISSOR_TEST = 0x0C11;

  static final int SHADER_COMPILER = 0x8DFA;

  static final int SHADER_TYPE = 0x8B4F;

  static final int SHADING_LANGUAGE_VERSION = 0x8B8C;

  static final int SHORT = 0x1402;

  static final int SRC_ALPHA = 0x0302;

  static final int SRC_ALPHA_SATURATE = 0x0308;

  static final int SRC_COLOR = 0x0300;

  static final int STATIC_DRAW = 0x88E4;

  static final int STENCIL_ATTACHMENT = 0x8D20;

  static final int STENCIL_BACK_FAIL = 0x8801;

  static final int STENCIL_BACK_FUNC = 0x8800;

  static final int STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;

  static final int STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;

  static final int STENCIL_BACK_REF = 0x8CA3;

  static final int STENCIL_BACK_VALUE_MASK = 0x8CA4;

  static final int STENCIL_BACK_WRITEMASK = 0x8CA5;

  static final int STENCIL_BITS = 0x0D57;

  static final int STENCIL_BUFFER_BIT = 0x00000400;

  static final int STENCIL_CLEAR_VALUE = 0x0B91;

  static final int STENCIL_FAIL = 0x0B94;

  static final int STENCIL_FUNC = 0x0B92;

  static final int STENCIL_INDEX = 0x1901;

  static final int STENCIL_INDEX8 = 0x8D48;

  static final int STENCIL_PASS_DEPTH_FAIL = 0x0B95;

  static final int STENCIL_PASS_DEPTH_PASS = 0x0B96;

  static final int STENCIL_REF = 0x0B97;

  static final int STENCIL_TEST = 0x0B90;

  static final int STENCIL_VALUE_MASK = 0x0B93;

  static final int STENCIL_WRITEMASK = 0x0B98;

  static final int STREAM_DRAW = 0x88E0;

  static final int SUBPIXEL_BITS = 0x0D50;

  static final int TEXTURE = 0x1702;

  static final int TEXTURE0 = 0x84C0;

  static final int TEXTURE1 = 0x84C1;

  static final int TEXTURE10 = 0x84CA;

  static final int TEXTURE11 = 0x84CB;

  static final int TEXTURE12 = 0x84CC;

  static final int TEXTURE13 = 0x84CD;

  static final int TEXTURE14 = 0x84CE;

  static final int TEXTURE15 = 0x84CF;

  static final int TEXTURE16 = 0x84D0;

  static final int TEXTURE17 = 0x84D1;

  static final int TEXTURE18 = 0x84D2;

  static final int TEXTURE19 = 0x84D3;

  static final int TEXTURE2 = 0x84C2;

  static final int TEXTURE20 = 0x84D4;

  static final int TEXTURE21 = 0x84D5;

  static final int TEXTURE22 = 0x84D6;

  static final int TEXTURE23 = 0x84D7;

  static final int TEXTURE24 = 0x84D8;

  static final int TEXTURE25 = 0x84D9;

  static final int TEXTURE26 = 0x84DA;

  static final int TEXTURE27 = 0x84DB;

  static final int TEXTURE28 = 0x84DC;

  static final int TEXTURE29 = 0x84DD;

  static final int TEXTURE3 = 0x84C3;

  static final int TEXTURE30 = 0x84DE;

  static final int TEXTURE31 = 0x84DF;

  static final int TEXTURE4 = 0x84C4;

  static final int TEXTURE5 = 0x84C5;

  static final int TEXTURE6 = 0x84C6;

  static final int TEXTURE7 = 0x84C7;

  static final int TEXTURE8 = 0x84C8;

  static final int TEXTURE9 = 0x84C9;

  static final int TEXTURE_2D = 0x0DE1;

  static final int TEXTURE_BINDING_2D = 0x8069;

  static final int TEXTURE_BINDING_CUBE_MAP = 0x8514;

  static final int TEXTURE_CUBE_MAP = 0x8513;

  static final int TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;

  static final int TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;

  static final int TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;

  static final int TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;

  static final int TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;

  static final int TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;

  static final int TEXTURE_MAG_FILTER = 0x2800;

  static final int TEXTURE_MIN_FILTER = 0x2801;

  static final int TEXTURE_WRAP_S = 0x2802;

  static final int TEXTURE_WRAP_T = 0x2803;

  static final int TRIANGLES = 0x0004;

  static final int TRIANGLE_FAN = 0x0006;

  static final int TRIANGLE_STRIP = 0x0005;

  static final int UNPACK_ALIGNMENT = 0x0CF5;

  static final int UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;

  static final int UNPACK_FLIP_Y_WEBGL = 0x9240;

  static final int UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;

  static final int UNSIGNED_BYTE = 0x1401;

  static final int UNSIGNED_INT = 0x1405;

  static final int UNSIGNED_SHORT = 0x1403;

  static final int UNSIGNED_SHORT_4_4_4_4 = 0x8033;

  static final int UNSIGNED_SHORT_5_5_5_1 = 0x8034;

  static final int UNSIGNED_SHORT_5_6_5 = 0x8363;

  static final int VALIDATE_STATUS = 0x8B83;

  static final int VENDOR = 0x1F00;

  static final int VERSION = 0x1F02;

  static final int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

  static final int VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;

  static final int VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;

  static final int VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;

  static final int VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;

  static final int VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;

  static final int VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;

  static final int VERTEX_SHADER = 0x8B31;

  static final int VIEWPORT = 0x0BA2;

  static final int ZERO = 0;

  final int drawingBufferHeight;

  final int drawingBufferWidth;

  void activeTexture(int texture) native;

  void attachShader(_WebGLProgramImpl program, _WebGLShaderImpl shader) native;

  void bindAttribLocation(_WebGLProgramImpl program, int index, String name) native;

  void bindBuffer(int target, _WebGLBufferImpl buffer) native;

  void bindFramebuffer(int target, _WebGLFramebufferImpl framebuffer) native;

  void bindRenderbuffer(int target, _WebGLRenderbufferImpl renderbuffer) native;

  void bindTexture(int target, _WebGLTextureImpl texture) native;

  void blendColor(num red, num green, num blue, num alpha) native;

  void blendEquation(int mode) native;

  void blendEquationSeparate(int modeRGB, int modeAlpha) native;

  void blendFunc(int sfactor, int dfactor) native;

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) native;

  void bufferData(int target, var data_OR_size, int usage) native;

  void bufferSubData(int target, int offset, var data) native;

  int checkFramebufferStatus(int target) native;

  void clear(int mask) native;

  void clearColor(num red, num green, num blue, num alpha) native;

  void clearDepth(num depth) native;

  void clearStencil(int s) native;

  void colorMask(bool red, bool green, bool blue, bool alpha) native;

  void compileShader(_WebGLShaderImpl shader) native;

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, _ArrayBufferViewImpl data) native;

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, _ArrayBufferViewImpl data) native;

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) native;

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) native;

  _WebGLBufferImpl createBuffer() native;

  _WebGLFramebufferImpl createFramebuffer() native;

  _WebGLProgramImpl createProgram() native;

  _WebGLRenderbufferImpl createRenderbuffer() native;

  _WebGLShaderImpl createShader(int type) native;

  _WebGLTextureImpl createTexture() native;

  void cullFace(int mode) native;

  void deleteBuffer(_WebGLBufferImpl buffer) native;

  void deleteFramebuffer(_WebGLFramebufferImpl framebuffer) native;

  void deleteProgram(_WebGLProgramImpl program) native;

  void deleteRenderbuffer(_WebGLRenderbufferImpl renderbuffer) native;

  void deleteShader(_WebGLShaderImpl shader) native;

  void deleteTexture(_WebGLTextureImpl texture) native;

  void depthFunc(int func) native;

  void depthMask(bool flag) native;

  void depthRange(num zNear, num zFar) native;

  void detachShader(_WebGLProgramImpl program, _WebGLShaderImpl shader) native;

  void disable(int cap) native;

  void disableVertexAttribArray(int index) native;

  void drawArrays(int mode, int first, int count) native;

  void drawElements(int mode, int count, int type, int offset) native;

  void enable(int cap) native;

  void enableVertexAttribArray(int index) native;

  void finish() native;

  void flush() native;

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, _WebGLRenderbufferImpl renderbuffer) native;

  void framebufferTexture2D(int target, int attachment, int textarget, _WebGLTextureImpl texture, int level) native;

  void frontFace(int mode) native;

  void generateMipmap(int target) native;

  _WebGLActiveInfoImpl getActiveAttrib(_WebGLProgramImpl program, int index) native;

  _WebGLActiveInfoImpl getActiveUniform(_WebGLProgramImpl program, int index) native;

  List getAttachedShaders(_WebGLProgramImpl program) native;

  int getAttribLocation(_WebGLProgramImpl program, String name) native;

  Object getBufferParameter(int target, int pname) native;

  _WebGLContextAttributesImpl getContextAttributes() native;

  int getError() native;

  Object getExtension(String name) native;

  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) native;

  Object getParameter(int pname) native;

  String getProgramInfoLog(_WebGLProgramImpl program) native;

  Object getProgramParameter(_WebGLProgramImpl program, int pname) native;

  Object getRenderbufferParameter(int target, int pname) native;

  String getShaderInfoLog(_WebGLShaderImpl shader) native;

  Object getShaderParameter(_WebGLShaderImpl shader, int pname) native;

  String getShaderSource(_WebGLShaderImpl shader) native;

  Object getTexParameter(int target, int pname) native;

  Object getUniform(_WebGLProgramImpl program, _WebGLUniformLocationImpl location) native;

  _WebGLUniformLocationImpl getUniformLocation(_WebGLProgramImpl program, String name) native;

  Object getVertexAttrib(int index, int pname) native;

  int getVertexAttribOffset(int index, int pname) native;

  void hint(int target, int mode) native;

  bool isBuffer(_WebGLBufferImpl buffer) native;

  bool isContextLost() native;

  bool isEnabled(int cap) native;

  bool isFramebuffer(_WebGLFramebufferImpl framebuffer) native;

  bool isProgram(_WebGLProgramImpl program) native;

  bool isRenderbuffer(_WebGLRenderbufferImpl renderbuffer) native;

  bool isShader(_WebGLShaderImpl shader) native;

  bool isTexture(_WebGLTextureImpl texture) native;

  void lineWidth(num width) native;

  void linkProgram(_WebGLProgramImpl program) native;

  void pixelStorei(int pname, int param) native;

  void polygonOffset(num factor, num units) native;

  void readPixels(int x, int y, int width, int height, int format, int type, _ArrayBufferViewImpl pixels) native;

  void releaseShaderCompiler() native;

  void renderbufferStorage(int target, int internalformat, int width, int height) native;

  void sampleCoverage(num value, bool invert) native;

  void scissor(int x, int y, int width, int height) native;

  void shaderSource(_WebGLShaderImpl shader, String string) native;

  void stencilFunc(int func, int ref, int mask) native;

  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  void stencilMask(int mask) native;

  void stencilMaskSeparate(int face, int mask) native;

  void stencilOp(int fail, int zfail, int zpass) native;

  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels_OR_video, [int format = null, int type = null, _ArrayBufferViewImpl pixels = null]) native;

  void texParameterf(int target, int pname, num param) native;

  void texParameteri(int target, int pname, int param) native;

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels_OR_video, [int type = null, _ArrayBufferViewImpl pixels = null]) native;

  void uniform1f(_WebGLUniformLocationImpl location, num x) native;

  void uniform1fv(_WebGLUniformLocationImpl location, _Float32ArrayImpl v) native;

  void uniform1i(_WebGLUniformLocationImpl location, int x) native;

  void uniform1iv(_WebGLUniformLocationImpl location, _Int32ArrayImpl v) native;

  void uniform2f(_WebGLUniformLocationImpl location, num x, num y) native;

  void uniform2fv(_WebGLUniformLocationImpl location, _Float32ArrayImpl v) native;

  void uniform2i(_WebGLUniformLocationImpl location, int x, int y) native;

  void uniform2iv(_WebGLUniformLocationImpl location, _Int32ArrayImpl v) native;

  void uniform3f(_WebGLUniformLocationImpl location, num x, num y, num z) native;

  void uniform3fv(_WebGLUniformLocationImpl location, _Float32ArrayImpl v) native;

  void uniform3i(_WebGLUniformLocationImpl location, int x, int y, int z) native;

  void uniform3iv(_WebGLUniformLocationImpl location, _Int32ArrayImpl v) native;

  void uniform4f(_WebGLUniformLocationImpl location, num x, num y, num z, num w) native;

  void uniform4fv(_WebGLUniformLocationImpl location, _Float32ArrayImpl v) native;

  void uniform4i(_WebGLUniformLocationImpl location, int x, int y, int z, int w) native;

  void uniform4iv(_WebGLUniformLocationImpl location, _Int32ArrayImpl v) native;

  void uniformMatrix2fv(_WebGLUniformLocationImpl location, bool transpose, _Float32ArrayImpl array) native;

  void uniformMatrix3fv(_WebGLUniformLocationImpl location, bool transpose, _Float32ArrayImpl array) native;

  void uniformMatrix4fv(_WebGLUniformLocationImpl location, bool transpose, _Float32ArrayImpl array) native;

  void useProgram(_WebGLProgramImpl program) native;

  void validateProgram(_WebGLProgramImpl program) native;

  void vertexAttrib1f(int indx, num x) native;

  void vertexAttrib1fv(int indx, _Float32ArrayImpl values) native;

  void vertexAttrib2f(int indx, num x, num y) native;

  void vertexAttrib2fv(int indx, _Float32ArrayImpl values) native;

  void vertexAttrib3f(int indx, num x, num y, num z) native;

  void vertexAttrib3fv(int indx, _Float32ArrayImpl values) native;

  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  void vertexAttrib4fv(int indx, _Float32ArrayImpl values) native;

  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) native;

  void viewport(int x, int y, int width, int height) native;
}

class _WebGLShaderImpl implements WebGLShader native "*WebGLShader" {
}

class _WebGLTextureImpl implements WebGLTexture native "*WebGLTexture" {
}

class _WebGLUniformLocationImpl implements WebGLUniformLocation native "*WebGLUniformLocation" {
}

class _WebGLVertexArrayObjectOESImpl implements WebGLVertexArrayObjectOES native "*WebGLVertexArrayObjectOES" {
}

class _WebKitCSSRegionRuleImpl extends _CSSRuleImpl implements WebKitCSSRegionRule native "*WebKitCSSRegionRule" {

  final _CSSRuleListImpl cssRules;
}

class _WebKitNamedFlowImpl implements WebKitNamedFlow native "*WebKitNamedFlow" {

  final bool overflow;

  _NodeListImpl getRegionsByContentNode(_NodeImpl contentNode) native;
}

class _WebSocketImpl extends _EventTargetImpl implements WebSocket native "*WebSocket" {

  _WebSocketEventsImpl get on() =>
    new _WebSocketEventsImpl(this);

  static final int CLOSED = 3;

  static final int CLOSING = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  final String URL;

  String binaryType;

  final int bufferedAmount;

  final String extensions;

  final String protocol;

  final int readyState;

  final String url;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  void close([int code = null, String reason = null]) native;

  bool $dom_dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

  bool send(String data) native;
}

class _WebSocketEventsImpl extends _EventsImpl implements WebSocketEvents {
  _WebSocketEventsImpl(_ptr) : super(_ptr);

  EventListenerList get close() => _get('close');

  EventListenerList get error() => _get('error');

  EventListenerList get message() => _get('message');

  EventListenerList get open() => _get('open');
}

class _WheelEventImpl extends _UIEventImpl implements WheelEvent native "*WheelEvent" {

  final bool altKey;

  final int clientX;

  final int clientY;

  final bool ctrlKey;

  final bool metaKey;

  final int offsetX;

  final int offsetY;

  final int screenX;

  final int screenY;

  final bool shiftKey;

  final bool webkitDirectionInvertedFromDevice;

  final int wheelDelta;

  final int wheelDeltaX;

  final int wheelDeltaY;

  final int x;

  final int y;

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, _WindowImpl view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _WindowImpl extends _EventTargetImpl implements Window native "@*DOMWindow" {

  _DocumentImpl get document() native "return this.document;";

  void requestLayoutFrame(TimeoutHandler callback) {
    _addMeasurementFrameCallback(callback);
  }


  _WindowEventsImpl get on() =>
    new _WindowEventsImpl(this);

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final _DOMApplicationCacheImpl applicationCache;

  final _NavigatorImpl clientInformation;

  final bool closed;

  final _ConsoleImpl console;

  final _CryptoImpl crypto;

  String defaultStatus;

  String defaultstatus;

  final num devicePixelRatio;

  final _EventImpl event;

  final _ElementImpl frameElement;

  final _WindowImpl frames;

  final _HistoryImpl history;

  final int innerHeight;

  final int innerWidth;

  final int length;

  final _StorageImpl localStorage;

  _LocationImpl location;

  final _BarInfoImpl locationbar;

  final _BarInfoImpl menubar;

  String name;

  final _NavigatorImpl navigator;

  final bool offscreenBuffering;

  final _WindowImpl opener;

  final int outerHeight;

  final int outerWidth;

  final int pageXOffset;

  final int pageYOffset;

  final _WindowImpl parent;

  final _PerformanceImpl performance;

  final _BarInfoImpl personalbar;

  final _ScreenImpl screen;

  final int screenLeft;

  final int screenTop;

  final int screenX;

  final int screenY;

  final int scrollX;

  final int scrollY;

  final _BarInfoImpl scrollbars;

  final _WindowImpl self;

  final _StorageImpl sessionStorage;

  String status;

  final _BarInfoImpl statusbar;

  final _StyleMediaImpl styleMedia;

  final _BarInfoImpl toolbar;

  final _WindowImpl top;

  final _IDBFactoryImpl webkitIndexedDB;

  final _NotificationCenterImpl webkitNotifications;

  final _StorageInfoImpl webkitStorageInfo;

  final _WindowImpl window;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  void alert(String message) native;

  String atob(String string) native;

  void blur() native;

  String btoa(String string) native;

  void captureEvents() native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool confirm(String message) native;

  bool $dom_dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  void focus() native;

  _CSSStyleDeclarationImpl $dom_getComputedStyle(_ElementImpl element, String pseudoElement) native "return this.getComputedStyle(element, pseudoElement);";

  _CSSRuleListImpl getMatchedCSSRules(_ElementImpl element, String pseudoElement) native;

  _DOMSelectionImpl getSelection() native;

  _MediaQueryListImpl matchMedia(String query) native;

  void moveBy(num x, num y) native;

  void moveTo(num x, num y) native;

  _WindowImpl open(String url, String name, [String options = null]) native;

  _DatabaseImpl openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void postMessage(Dynamic message, String targetOrigin, [List messagePorts = null]) native;

  void print() native;

  String prompt(String message, String defaultValue) native;

  void releaseEvents() native;

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

  void resizeBy(num x, num y) native;

  void resizeTo(num width, num height) native;

  void scroll(int x, int y) native;

  void scrollBy(int x, int y) native;

  void scrollTo(int x, int y) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  Object showModalDialog(String url, [Object dialogArgs = null, String featureArgs = null]) native;

  void stop() native;

  void webkitCancelAnimationFrame(int id) native;

  void webkitCancelRequestAnimationFrame(int id) native;

  _PointImpl webkitConvertPointFromNodeToPage(_NodeImpl node, _PointImpl p) native;

  _PointImpl webkitConvertPointFromPageToNode(_NodeImpl node, _PointImpl p) native;

  void webkitPostMessage(Dynamic message, String targetOrigin, [List transferList = null]) native;

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, _ElementImpl element) native;

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

}

class _WindowEventsImpl extends _EventsImpl implements WindowEvents {
  _WindowEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get animationEnd() => _get('webkitAnimationEnd');

  EventListenerList get animationIteration() => _get('webkitAnimationIteration');

  EventListenerList get animationStart() => _get('webkitAnimationStart');

  EventListenerList get beforeUnload() => _get('beforeunload');

  EventListenerList get blur() => _get('blur');

  EventListenerList get canPlay() => _get('canplay');

  EventListenerList get canPlayThrough() => _get('canplaythrough');

  EventListenerList get change() => _get('change');

  EventListenerList get click() => _get('click');

  EventListenerList get contentLoaded() => _get('DOMContentLoaded');

  EventListenerList get contextMenu() => _get('contextmenu');

  EventListenerList get deviceMotion() => _get('devicemotion');

  EventListenerList get deviceOrientation() => _get('deviceorientation');

  EventListenerList get doubleClick() => _get('dblclick');

  EventListenerList get drag() => _get('drag');

  EventListenerList get dragEnd() => _get('dragend');

  EventListenerList get dragEnter() => _get('dragenter');

  EventListenerList get dragLeave() => _get('dragleave');

  EventListenerList get dragOver() => _get('dragover');

  EventListenerList get dragStart() => _get('dragstart');

  EventListenerList get drop() => _get('drop');

  EventListenerList get durationChange() => _get('durationchange');

  EventListenerList get emptied() => _get('emptied');

  EventListenerList get ended() => _get('ended');

  EventListenerList get error() => _get('error');

  EventListenerList get focus() => _get('focus');

  EventListenerList get hashChange() => _get('hashchange');

  EventListenerList get input() => _get('input');

  EventListenerList get invalid() => _get('invalid');

  EventListenerList get keyDown() => _get('keydown');

  EventListenerList get keyPress() => _get('keypress');

  EventListenerList get keyUp() => _get('keyup');

  EventListenerList get load() => _get('load');

  EventListenerList get loadStart() => _get('loadstart');

  EventListenerList get loadedData() => _get('loadeddata');

  EventListenerList get loadedMetadata() => _get('loadedmetadata');

  EventListenerList get message() => _get('message');

  EventListenerList get mouseDown() => _get('mousedown');

  EventListenerList get mouseMove() => _get('mousemove');

  EventListenerList get mouseOut() => _get('mouseout');

  EventListenerList get mouseOver() => _get('mouseover');

  EventListenerList get mouseUp() => _get('mouseup');

  EventListenerList get mouseWheel() => _get('mousewheel');

  EventListenerList get offline() => _get('offline');

  EventListenerList get online() => _get('online');

  EventListenerList get pageHide() => _get('pagehide');

  EventListenerList get pageShow() => _get('pageshow');

  EventListenerList get pause() => _get('pause');

  EventListenerList get play() => _get('play');

  EventListenerList get playing() => _get('playing');

  EventListenerList get popState() => _get('popstate');

  EventListenerList get progress() => _get('progress');

  EventListenerList get rateChange() => _get('ratechange');

  EventListenerList get reset() => _get('reset');

  EventListenerList get resize() => _get('resize');

  EventListenerList get scroll() => _get('scroll');

  EventListenerList get search() => _get('search');

  EventListenerList get seeked() => _get('seeked');

  EventListenerList get seeking() => _get('seeking');

  EventListenerList get select() => _get('select');

  EventListenerList get stalled() => _get('stalled');

  EventListenerList get storage() => _get('storage');

  EventListenerList get submit() => _get('submit');

  EventListenerList get suspend() => _get('suspend');

  EventListenerList get timeUpdate() => _get('timeupdate');

  EventListenerList get touchCancel() => _get('touchcancel');

  EventListenerList get touchEnd() => _get('touchend');

  EventListenerList get touchMove() => _get('touchmove');

  EventListenerList get touchStart() => _get('touchstart');

  EventListenerList get transitionEnd() => _get('webkitTransitionEnd');

  EventListenerList get unload() => _get('unload');

  EventListenerList get volumeChange() => _get('volumechange');

  EventListenerList get waiting() => _get('waiting');
}

class _WorkerImpl extends _AbstractWorkerImpl implements Worker native "*Worker" {

  _WorkerEventsImpl get on() =>
    new _WorkerEventsImpl(this);

  void postMessage(Dynamic message, [List messagePorts = null]) native;

  void terminate() native;

  void webkitPostMessage(Dynamic message, [List messagePorts = null]) native;
}

class _WorkerEventsImpl extends _AbstractWorkerEventsImpl implements WorkerEvents {
  _WorkerEventsImpl(_ptr) : super(_ptr);

  EventListenerList get message() => _get('message');
}

class _WorkerContextImpl implements WorkerContext native "*WorkerContext" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final _WorkerLocationImpl location;

  final _WorkerNavigatorImpl navigator;

  EventListener onerror;

  final _WorkerContextImpl self;

  final _IDBFactoryImpl webkitIndexedDB;

  final _NotificationCenterImpl webkitNotifications;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool dispatchEvent(_EventImpl evt) native;

  void importScripts() native;

  _DatabaseImpl openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  _DatabaseSyncImpl openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  _DOMFileSystemSyncImpl webkitRequestFileSystemSync(int type, int size) native;

  _EntrySyncImpl webkitResolveLocalFileSystemSyncURL(String url) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;
}

class _WorkerLocationImpl implements WorkerLocation native "*WorkerLocation" {

  final String hash;

  final String host;

  final String hostname;

  final String href;

  final String pathname;

  final String port;

  final String protocol;

  final String search;

  String toString() native;
}

class _WorkerNavigatorImpl implements WorkerNavigator native "*WorkerNavigator" {

  final String appName;

  final String appVersion;

  final bool onLine;

  final String platform;

  final String userAgent;
}

class _XMLHttpRequestImpl extends _EventTargetImpl implements XMLHttpRequest native "*XMLHttpRequest" {

  _XMLHttpRequestEventsImpl get on() =>
    new _XMLHttpRequestEventsImpl(this);

  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  bool asBlob;

  final int readyState;

  final Object response;

  final _BlobImpl responseBlob;

  final String responseText;

  String responseType;

  final _DocumentImpl responseXML;

  final int status;

  final String statusText;

  final _XMLHttpRequestUploadImpl upload;

  bool withCredentials;

  void abort() native;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  bool $dom_dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  String getAllResponseHeaders() native;

  String getResponseHeader(String header) native;

  void open(String method, String url, [bool async = null, String user = null, String password = null]) native;

  void overrideMimeType(String override) native;

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

  void send([var data = null]) native;

  void setRequestHeader(String header, String value) native;
}

class _XMLHttpRequestEventsImpl extends _EventsImpl implements XMLHttpRequestEvents {
  _XMLHttpRequestEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get error() => _get('error');

  EventListenerList get load() => _get('load');

  EventListenerList get loadEnd() => _get('loadend');

  EventListenerList get loadStart() => _get('loadstart');

  EventListenerList get progress() => _get('progress');

  EventListenerList get readyStateChange() => _get('readystatechange');
}

class _XMLHttpRequestExceptionImpl implements XMLHttpRequestException native "*XMLHttpRequestException" {

  static final int ABORT_ERR = 102;

  static final int NETWORK_ERR = 101;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _XMLHttpRequestProgressEventImpl extends _ProgressEventImpl implements XMLHttpRequestProgressEvent native "*XMLHttpRequestProgressEvent" {

  final int position;

  final int totalSize;
}

class _XMLHttpRequestUploadImpl extends _EventTargetImpl implements XMLHttpRequestUpload native "*XMLHttpRequestUpload" {

  _XMLHttpRequestUploadEventsImpl get on() =>
    new _XMLHttpRequestUploadEventsImpl(this);

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  bool $dom_dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";
}

class _XMLHttpRequestUploadEventsImpl extends _EventsImpl implements XMLHttpRequestUploadEvents {
  _XMLHttpRequestUploadEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get error() => _get('error');

  EventListenerList get load() => _get('load');

  EventListenerList get loadEnd() => _get('loadend');

  EventListenerList get loadStart() => _get('loadstart');

  EventListenerList get progress() => _get('progress');
}

class _XMLSerializerImpl implements XMLSerializer native "*XMLSerializer" {

  String serializeToString(_NodeImpl node) native;
}

class _XPathEvaluatorImpl implements XPathEvaluator native "*XPathEvaluator" {

  _XPathExpressionImpl createExpression(String expression, _XPathNSResolverImpl resolver) native;

  _XPathNSResolverImpl createNSResolver(_NodeImpl nodeResolver) native;

  _XPathResultImpl evaluate(String expression, _NodeImpl contextNode, _XPathNSResolverImpl resolver, int type, _XPathResultImpl inResult) native;
}

class _XPathExceptionImpl implements XPathException native "*XPathException" {

  static final int INVALID_EXPRESSION_ERR = 51;

  static final int TYPE_ERR = 52;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _XPathExpressionImpl implements XPathExpression native "*XPathExpression" {

  _XPathResultImpl evaluate(_NodeImpl contextNode, int type, _XPathResultImpl inResult) native;
}

class _XPathNSResolverImpl implements XPathNSResolver native "*XPathNSResolver" {

  String lookupNamespaceURI(String prefix) native;
}

class _XPathResultImpl implements XPathResult native "*XPathResult" {

  static final int ANY_TYPE = 0;

  static final int ANY_UNORDERED_NODE_TYPE = 8;

  static final int BOOLEAN_TYPE = 3;

  static final int FIRST_ORDERED_NODE_TYPE = 9;

  static final int NUMBER_TYPE = 1;

  static final int ORDERED_NODE_ITERATOR_TYPE = 5;

  static final int ORDERED_NODE_SNAPSHOT_TYPE = 7;

  static final int STRING_TYPE = 2;

  static final int UNORDERED_NODE_ITERATOR_TYPE = 4;

  static final int UNORDERED_NODE_SNAPSHOT_TYPE = 6;

  final bool booleanValue;

  final bool invalidIteratorState;

  final num numberValue;

  final int resultType;

  final _NodeImpl singleNodeValue;

  final int snapshotLength;

  final String stringValue;

  _NodeImpl iterateNext() native;

  _NodeImpl snapshotItem(int index) native;
}

class _XSLTProcessorImpl implements XSLTProcessor native "*XSLTProcessor" {

  void clearParameters() native;

  String getParameter(String namespaceURI, String localName) native;

  void importStylesheet(_NodeImpl stylesheet) native;

  void removeParameter(String namespaceURI, String localName) native;

  void reset() native;

  void setParameter(String namespaceURI, String localName, String value) native;

  _DocumentImpl transformToDocument(_NodeImpl source) native;

  _DocumentFragmentImpl transformToFragment(_NodeImpl source, _DocumentImpl docVal) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AudioElementFactoryProvider {
  factory AudioElement([String src = null]) native '''
      if (src == null) return new Audio();
      return new Audio(src);
    ''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _BlobBuilderFactoryProvider {
  factory BlobBuilder() native
      '''return new BlobBuilder();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _CSSMatrixFactoryProvider {
  factory CSSMatrix([String cssValue = '']) native
      'return new WebKitCSSMatrix(cssValue);';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _DOMParserFactoryProvider {
  factory DOMParser() native
      '''return new DOMParser();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _DOMURLFactoryProvider {
  factory DOMURL() native
      '''return new DOMURL();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _DeprecatedPeerConnectionFactoryProvider {
  factory DeprecatedPeerConnection(String serverConfiguration, SignalingCallback signalingCallback) native
      '''return new DeprecatedPeerConnection(serverConfiguration, signalingCallback);''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _EventSourceFactoryProvider {
  factory EventSource(String scriptUrl) native
      '''return new EventSource(scriptUrl);''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _FileReaderFactoryProvider {
  factory FileReader() native
      '''return new FileReader();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _FileReaderSyncFactoryProvider {
  factory FileReaderSync() native
      '''return new FileReaderSync();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _IceCandidateFactoryProvider {
  factory IceCandidate(String label, String candidateLine) native
      '''return new IceCandidate(label, candidateLine);''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _MediaControllerFactoryProvider {
  factory MediaController() native
      '''return new MediaController();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _MediaStreamFactoryProvider {
  factory MediaStream(MediaStreamTrackList audioTracks, MediaStreamTrackList videoTracks) native
      '''return new MediaStream(audioTracks, videoTracks);''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _MessageChannelFactoryProvider {
  factory MessageChannel() native
      '''return new MessageChannel();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _OptionElementFactoryProvider {
  factory OptionElement([String data = null, String value = null,
                         bool defaultSelected = null, bool selected = null])
      native '''
          if (data == null) return new Option();
          if (value == null) return new Option(data);
          if (defaultSelected == null) return new Option(data, value);
          if (selected == null) return new Option(data, value, defaultSelected);
          return new Option(data, value, defaultSelected, selected);
      ''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _PeerConnection00FactoryProvider {
  factory PeerConnection00(String serverConfiguration, IceCallback iceCallback) native
      '''return new PeerConnection00(serverConfiguration, iceCallback);''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SessionDescriptionFactoryProvider {
  factory SessionDescription(String sdp) native
      '''return new SessionDescription(sdp);''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ShadowRootFactoryProvider {
  factory ShadowRoot(Element host) native
      '''return new ShadowRoot(host);''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SharedWorkerFactoryProvider {
  factory SharedWorker(String scriptURL, [String name]) native '''
      if (name == null) return new SharedWorker(scriptURL);
      return new SharedWorker(scriptURL, name);
    ''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SpeechGrammarFactoryProvider {
  factory SpeechGrammar() native
      '''return new SpeechGrammar();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SpeechGrammarListFactoryProvider {
  factory SpeechGrammarList() native
      '''return new SpeechGrammarList();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SpeechRecognitionFactoryProvider {
  factory SpeechRecognition() native
      '''return new SpeechRecognition();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _TextTrackCueFactoryProvider {
  factory TextTrackCue(String id, num startTime, num endTime, String text,
                       [String settings, bool pauseOnExit]) native '''
    if (settings == null)
      return new TextTrackCue(id, startTime, endTime, text);
    if (pauseOnExit == null)
      return new TextTrackCue(id, startTime, endTime, text, settings);
    return new TextTrackCue(id, startTime, endTime, text, settings, pauseOnExit);
  ''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _WorkerFactoryProvider {
  factory Worker(String scriptUrl) native
      '''return new Worker(scriptUrl);''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _XMLHttpRequestFactoryProvider {
  factory XMLHttpRequest() native 'return new XMLHttpRequest();';

  factory XMLHttpRequest.getTEMPNAME(String url,
                                     onSuccess(XMLHttpRequest request)) =>
      _XMLHttpRequestUtils.getTEMPNAME(url, onSuccess);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _XMLSerializerFactoryProvider {
  factory XMLSerializer() native
      '''return new XMLSerializer();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _XPathEvaluatorFactoryProvider {
  factory XPathEvaluator() native
      '''return new XPathEvaluator();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _XSLTProcessorFactoryProvider {
  factory XSLTProcessor() native
      '''return new XSLTProcessor();''';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AbstractWorker extends EventTarget {

  AbstractWorkerEvents get on();

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]);

  bool $dom_dispatchEvent(Event evt);

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]);
}

interface AbstractWorkerEvents extends Events {

  EventListenerList get error();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AnchorElement extends Element {

  String charset;

  String coords;

  String download;

  String hash;

  String host;

  String hostname;

  String href;

  String hreflang;

  String name;

  final String origin;

  String pathname;

  String ping;

  String port;

  String protocol;

  String rel;

  String rev;

  String search;

  String shape;

  String target;

  String type;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Animation {

  static final int DIRECTION_ALTERNATE = 1;

  static final int DIRECTION_NORMAL = 0;

  static final int FILL_BACKWARDS = 1;

  static final int FILL_BOTH = 3;

  static final int FILL_FORWARDS = 2;

  static final int FILL_NONE = 0;

  final num delay;

  final int direction;

  final num duration;

  num elapsedTime;

  final bool ended;

  final int fillMode;

  final int iterationCount;

  final String name;

  final bool paused;

  void pause();

  void play();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AnimationEvent extends Event {

  final String animationName;

  final num elapsedTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AnimationList {

  final int length;

  Animation item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AppletElement extends Element {

  String align;

  String alt;

  String archive;

  String code;

  String codeBase;

  String height;

  String hspace;

  String name;

  String object;

  String vspace;

  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AreaElement extends Element {

  String alt;

  String coords;

  final String hash;

  final String host;

  final String hostname;

  String href;

  bool noHref;

  final String pathname;

  String ping;

  final String port;

  final String protocol;

  final String search;

  String shape;

  String target;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ArrayBuffer {

  final int byteLength;

  ArrayBuffer slice(int begin, [int end]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ArrayBufferView {

  final ArrayBuffer buffer;

  final int byteLength;

  final int byteOffset;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Attr extends Node {

  final bool isId;

  final String name;

  final Element ownerElement;

  final bool specified;

  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioBuffer {

  final num duration;

  num gain;

  final int length;

  final int numberOfChannels;

  final num sampleRate;

  Float32Array getChannelData(int channelIndex);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool AudioBufferCallback(AudioBuffer audioBuffer);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioBufferSourceNode extends AudioSourceNode {

  static final int FINISHED_STATE = 3;

  static final int PLAYING_STATE = 2;

  static final int SCHEDULED_STATE = 1;

  static final int UNSCHEDULED_STATE = 0;

  AudioBuffer buffer;

  final AudioGain gain;

  bool loop;

  bool looping;

  final AudioParam playbackRate;

  final int playbackState;

  void noteGrainOn(num when, num grainOffset, num grainDuration);

  void noteOff(num when);

  void noteOn(num when);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioChannelMerger extends AudioNode {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioChannelSplitter extends AudioNode {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioContext {

  final int activeSourceCount;

  final num currentTime;

  final AudioDestinationNode destination;

  final AudioListener listener;

  EventListener oncomplete;

  final num sampleRate;

  RealtimeAnalyserNode createAnalyser();

  BiquadFilterNode createBiquadFilter();

  AudioBuffer createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate]);

  AudioBufferSourceNode createBufferSource();

  AudioChannelMerger createChannelMerger();

  AudioChannelSplitter createChannelSplitter();

  ConvolverNode createConvolver();

  DelayNode createDelayNode([num maxDelayTime]);

  DynamicsCompressorNode createDynamicsCompressor();

  AudioGainNode createGainNode();

  HighPass2FilterNode createHighPass2Filter();

  JavaScriptAudioNode createJavaScriptNode(int bufferSize);

  LowPass2FilterNode createLowPass2Filter();

  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement);

  AudioPannerNode createPanner();

  WaveShaperNode createWaveShaper();

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]);

  void startRendering();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioDestinationNode extends AudioNode {

  final int numberOfChannels;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioElement extends MediaElement default _AudioElementFactoryProvider {

  AudioElement([String src]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioGain extends AudioParam {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioGainNode extends AudioNode {

  final AudioGain gain;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioListener {

  num dopplerFactor;

  num speedOfSound;

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp);

  void setPosition(num x, num y, num z);

  void setVelocity(num x, num y, num z);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioNode {

  final AudioContext context;

  final int numberOfInputs;

  final int numberOfOutputs;

  void connect(AudioNode destination, int output, int input);

  void disconnect(int output);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioPannerNode extends AudioNode {

  static final int EQUALPOWER = 0;

  static final int EXPONENTIAL_DISTANCE = 2;

  static final int HRTF = 1;

  static final int INVERSE_DISTANCE = 1;

  static final int LINEAR_DISTANCE = 0;

  static final int SOUNDFIELD = 2;

  final AudioGain coneGain;

  num coneInnerAngle;

  num coneOuterAngle;

  num coneOuterGain;

  final AudioGain distanceGain;

  int distanceModel;

  num maxDistance;

  int panningModel;

  num refDistance;

  num rolloffFactor;

  void setOrientation(num x, num y, num z);

  void setPosition(num x, num y, num z);

  void setVelocity(num x, num y, num z);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioParam {

  final num defaultValue;

  final num maxValue;

  final num minValue;

  final String name;

  final int units;

  num value;

  void cancelScheduledValues(num startTime);

  void exponentialRampToValueAtTime(num value, num time);

  void linearRampToValueAtTime(num value, num time);

  void setTargetValueAtTime(num targetValue, num time, num timeConstant);

  void setValueAtTime(num value, num time);

  void setValueCurveAtTime(Float32Array values, num time, num duration);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioProcessingEvent extends Event {

  final AudioBuffer inputBuffer;

  final AudioBuffer outputBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioSourceNode extends AudioNode {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BRElement extends Element {

  String clear;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BarInfo {

  final bool visible;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BaseElement extends Element {

  String href;

  String target;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BaseFontElement extends Element {

  String color;

  String face;

  int size;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BeforeLoadEvent extends Event {

  final String url;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BiquadFilterNode extends AudioNode {

  static final int ALLPASS = 7;

  static final int BANDPASS = 2;

  static final int HIGHPASS = 1;

  static final int HIGHSHELF = 4;

  static final int LOWPASS = 0;

  static final int LOWSHELF = 3;

  static final int NOTCH = 6;

  static final int PEAKING = 5;

  final AudioParam Q;

  final AudioParam frequency;

  final AudioParam gain;

  int type;

  void getFrequencyResponse(Float32Array frequencyHz, Float32Array magResponse, Float32Array phaseResponse);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Blob {

  final int size;

  final String type;

  Blob webkitSlice([int start, int end, String contentType]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BlobBuilder default _BlobBuilderFactoryProvider {

  BlobBuilder();

  void append(var arrayBuffer_OR_blob_OR_value, [String endings]);

  Blob getBlob([String contentType]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BodyElement extends Element {

  BodyElementEvents get on();

  String aLink;

  String background;

  String bgColor;

  String link;

  String vLink;
}

interface BodyElementEvents extends ElementEvents {

  EventListenerList get beforeUnload();

  EventListenerList get blur();

  EventListenerList get error();

  EventListenerList get focus();

  EventListenerList get hashChange();

  EventListenerList get load();

  EventListenerList get message();

  EventListenerList get offline();

  EventListenerList get online();

  EventListenerList get popState();

  EventListenerList get resize();

  EventListenerList get storage();

  EventListenerList get unload();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ButtonElement extends Element {

  bool autofocus;

  bool disabled;

  final FormElement form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  final NodeList labels;

  String name;

  final String type;

  final String validationMessage;

  final ValidityState validity;

  String value;

  final bool willValidate;

  bool checkValidity();

  void setCustomValidity(String error);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CDATASection extends Text {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSCharsetRule extends CSSRule {

  String encoding;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSFontFaceRule extends CSSRule {

  final CSSStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSImportRule extends CSSRule {

  final String href;

  final MediaList media;

  final CSSStyleSheet styleSheet;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSKeyframeRule extends CSSRule {

  String keyText;

  final CSSStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSKeyframesRule extends CSSRule {

  final CSSRuleList cssRules;

  String name;

  void deleteRule(String key);

  CSSKeyframeRule findRule(String key);

  void insertRule(String rule);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSMatrix default _CSSMatrixFactoryProvider {

  CSSMatrix([String cssValue]);

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

  num m11;

  num m12;

  num m13;

  num m14;

  num m21;

  num m22;

  num m23;

  num m24;

  num m31;

  num m32;

  num m33;

  num m34;

  num m41;

  num m42;

  num m43;

  num m44;

  CSSMatrix inverse();

  CSSMatrix multiply(CSSMatrix secondMatrix);

  CSSMatrix rotate(num rotX, num rotY, num rotZ);

  CSSMatrix rotateAxisAngle(num x, num y, num z, num angle);

  CSSMatrix scale(num scaleX, num scaleY, num scaleZ);

  void setMatrixValue(String string);

  CSSMatrix skewX(num angle);

  CSSMatrix skewY(num angle);

  String toString();

  CSSMatrix translate(num x, num y, num z);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSMediaRule extends CSSRule {

  final CSSRuleList cssRules;

  final MediaList media;

  void deleteRule(int index);

  int insertRule(String rule, int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSPageRule extends CSSRule {

  String selectorText;

  final CSSStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSPrimitiveValue extends CSSValue {

  static final int CSS_ATTR = 22;

  static final int CSS_CM = 6;

  static final int CSS_COUNTER = 23;

  static final int CSS_DEG = 11;

  static final int CSS_DIMENSION = 18;

  static final int CSS_EMS = 3;

  static final int CSS_EXS = 4;

  static final int CSS_GRAD = 13;

  static final int CSS_HZ = 16;

  static final int CSS_IDENT = 21;

  static final int CSS_IN = 8;

  static final int CSS_KHZ = 17;

  static final int CSS_MM = 7;

  static final int CSS_MS = 14;

  static final int CSS_NUMBER = 1;

  static final int CSS_PC = 10;

  static final int CSS_PERCENTAGE = 2;

  static final int CSS_PT = 9;

  static final int CSS_PX = 5;

  static final int CSS_RAD = 12;

  static final int CSS_RECT = 24;

  static final int CSS_RGBCOLOR = 25;

  static final int CSS_S = 15;

  static final int CSS_STRING = 19;

  static final int CSS_UNKNOWN = 0;

  static final int CSS_URI = 20;

  final int primitiveType;

  Counter getCounterValue();

  num getFloatValue(int unitType);

  RGBColor getRGBColorValue();

  Rect getRectValue();

  String getStringValue();

  void setFloatValue(int unitType, num floatValue);

  void setStringValue(int stringType, String stringValue);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSRule {

  static final int CHARSET_RULE = 2;

  static final int FONT_FACE_RULE = 5;

  static final int IMPORT_RULE = 3;

  static final int MEDIA_RULE = 4;

  static final int PAGE_RULE = 6;

  static final int STYLE_RULE = 1;

  static final int UNKNOWN_RULE = 0;

  static final int WEBKIT_KEYFRAMES_RULE = 7;

  static final int WEBKIT_KEYFRAME_RULE = 8;

  static final int WEBKIT_REGION_RULE = 10;

  String cssText;

  final CSSRule parentRule;

  final CSSStyleSheet parentStyleSheet;

  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSRuleList {

  final int length;

  CSSRule item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSStyleDeclaration default _CSSStyleDeclarationFactoryProvider {
  CSSStyleDeclaration();
  CSSStyleDeclaration.css(String css);


  String cssText;

  final int length;

  final CSSRule parentRule;

  CSSValue getPropertyCSSValue(String propertyName);

  String getPropertyPriority(String propertyName);

  String getPropertyShorthand(String propertyName);

  String getPropertyValue(String propertyName);

  bool isPropertyImplicit(String propertyName);

  String item(int index);

  String removeProperty(String propertyName);

  void setProperty(String propertyName, String value, [String priority]);


  /** Gets the value of "animation" */
  String get animation();

  /** Sets the value of "animation" */
  void set animation(var value);

  /** Gets the value of "animation-delay" */
  String get animationDelay();

  /** Sets the value of "animation-delay" */
  void set animationDelay(var value);

  /** Gets the value of "animation-direction" */
  String get animationDirection();

  /** Sets the value of "animation-direction" */
  void set animationDirection(var value);

  /** Gets the value of "animation-duration" */
  String get animationDuration();

  /** Sets the value of "animation-duration" */
  void set animationDuration(var value);

  /** Gets the value of "animation-fill-mode" */
  String get animationFillMode();

  /** Sets the value of "animation-fill-mode" */
  void set animationFillMode(var value);

  /** Gets the value of "animation-iteration-count" */
  String get animationIterationCount();

  /** Sets the value of "animation-iteration-count" */
  void set animationIterationCount(var value);

  /** Gets the value of "animation-name" */
  String get animationName();

  /** Sets the value of "animation-name" */
  void set animationName(var value);

  /** Gets the value of "animation-play-state" */
  String get animationPlayState();

  /** Sets the value of "animation-play-state" */
  void set animationPlayState(var value);

  /** Gets the value of "animation-timing-function" */
  String get animationTimingFunction();

  /** Sets the value of "animation-timing-function" */
  void set animationTimingFunction(var value);

  /** Gets the value of "appearance" */
  String get appearance();

  /** Sets the value of "appearance" */
  void set appearance(var value);

  /** Gets the value of "backface-visibility" */
  String get backfaceVisibility();

  /** Sets the value of "backface-visibility" */
  void set backfaceVisibility(var value);

  /** Gets the value of "background" */
  String get background();

  /** Sets the value of "background" */
  void set background(var value);

  /** Gets the value of "background-attachment" */
  String get backgroundAttachment();

  /** Sets the value of "background-attachment" */
  void set backgroundAttachment(var value);

  /** Gets the value of "background-clip" */
  String get backgroundClip();

  /** Sets the value of "background-clip" */
  void set backgroundClip(var value);

  /** Gets the value of "background-color" */
  String get backgroundColor();

  /** Sets the value of "background-color" */
  void set backgroundColor(var value);

  /** Gets the value of "background-composite" */
  String get backgroundComposite();

  /** Sets the value of "background-composite" */
  void set backgroundComposite(var value);

  /** Gets the value of "background-image" */
  String get backgroundImage();

  /** Sets the value of "background-image" */
  void set backgroundImage(var value);

  /** Gets the value of "background-origin" */
  String get backgroundOrigin();

  /** Sets the value of "background-origin" */
  void set backgroundOrigin(var value);

  /** Gets the value of "background-position" */
  String get backgroundPosition();

  /** Sets the value of "background-position" */
  void set backgroundPosition(var value);

  /** Gets the value of "background-position-x" */
  String get backgroundPositionX();

  /** Sets the value of "background-position-x" */
  void set backgroundPositionX(var value);

  /** Gets the value of "background-position-y" */
  String get backgroundPositionY();

  /** Sets the value of "background-position-y" */
  void set backgroundPositionY(var value);

  /** Gets the value of "background-repeat" */
  String get backgroundRepeat();

  /** Sets the value of "background-repeat" */
  void set backgroundRepeat(var value);

  /** Gets the value of "background-repeat-x" */
  String get backgroundRepeatX();

  /** Sets the value of "background-repeat-x" */
  void set backgroundRepeatX(var value);

  /** Gets the value of "background-repeat-y" */
  String get backgroundRepeatY();

  /** Sets the value of "background-repeat-y" */
  void set backgroundRepeatY(var value);

  /** Gets the value of "background-size" */
  String get backgroundSize();

  /** Sets the value of "background-size" */
  void set backgroundSize(var value);

  /** Gets the value of "border" */
  String get border();

  /** Sets the value of "border" */
  void set border(var value);

  /** Gets the value of "border-after" */
  String get borderAfter();

  /** Sets the value of "border-after" */
  void set borderAfter(var value);

  /** Gets the value of "border-after-color" */
  String get borderAfterColor();

  /** Sets the value of "border-after-color" */
  void set borderAfterColor(var value);

  /** Gets the value of "border-after-style" */
  String get borderAfterStyle();

  /** Sets the value of "border-after-style" */
  void set borderAfterStyle(var value);

  /** Gets the value of "border-after-width" */
  String get borderAfterWidth();

  /** Sets the value of "border-after-width" */
  void set borderAfterWidth(var value);

  /** Gets the value of "border-before" */
  String get borderBefore();

  /** Sets the value of "border-before" */
  void set borderBefore(var value);

  /** Gets the value of "border-before-color" */
  String get borderBeforeColor();

  /** Sets the value of "border-before-color" */
  void set borderBeforeColor(var value);

  /** Gets the value of "border-before-style" */
  String get borderBeforeStyle();

  /** Sets the value of "border-before-style" */
  void set borderBeforeStyle(var value);

  /** Gets the value of "border-before-width" */
  String get borderBeforeWidth();

  /** Sets the value of "border-before-width" */
  void set borderBeforeWidth(var value);

  /** Gets the value of "border-bottom" */
  String get borderBottom();

  /** Sets the value of "border-bottom" */
  void set borderBottom(var value);

  /** Gets the value of "border-bottom-color" */
  String get borderBottomColor();

  /** Sets the value of "border-bottom-color" */
  void set borderBottomColor(var value);

  /** Gets the value of "border-bottom-left-radius" */
  String get borderBottomLeftRadius();

  /** Sets the value of "border-bottom-left-radius" */
  void set borderBottomLeftRadius(var value);

  /** Gets the value of "border-bottom-right-radius" */
  String get borderBottomRightRadius();

  /** Sets the value of "border-bottom-right-radius" */
  void set borderBottomRightRadius(var value);

  /** Gets the value of "border-bottom-style" */
  String get borderBottomStyle();

  /** Sets the value of "border-bottom-style" */
  void set borderBottomStyle(var value);

  /** Gets the value of "border-bottom-width" */
  String get borderBottomWidth();

  /** Sets the value of "border-bottom-width" */
  void set borderBottomWidth(var value);

  /** Gets the value of "border-collapse" */
  String get borderCollapse();

  /** Sets the value of "border-collapse" */
  void set borderCollapse(var value);

  /** Gets the value of "border-color" */
  String get borderColor();

  /** Sets the value of "border-color" */
  void set borderColor(var value);

  /** Gets the value of "border-end" */
  String get borderEnd();

  /** Sets the value of "border-end" */
  void set borderEnd(var value);

  /** Gets the value of "border-end-color" */
  String get borderEndColor();

  /** Sets the value of "border-end-color" */
  void set borderEndColor(var value);

  /** Gets the value of "border-end-style" */
  String get borderEndStyle();

  /** Sets the value of "border-end-style" */
  void set borderEndStyle(var value);

  /** Gets the value of "border-end-width" */
  String get borderEndWidth();

  /** Sets the value of "border-end-width" */
  void set borderEndWidth(var value);

  /** Gets the value of "border-fit" */
  String get borderFit();

  /** Sets the value of "border-fit" */
  void set borderFit(var value);

  /** Gets the value of "border-horizontal-spacing" */
  String get borderHorizontalSpacing();

  /** Sets the value of "border-horizontal-spacing" */
  void set borderHorizontalSpacing(var value);

  /** Gets the value of "border-image" */
  String get borderImage();

  /** Sets the value of "border-image" */
  void set borderImage(var value);

  /** Gets the value of "border-image-outset" */
  String get borderImageOutset();

  /** Sets the value of "border-image-outset" */
  void set borderImageOutset(var value);

  /** Gets the value of "border-image-repeat" */
  String get borderImageRepeat();

  /** Sets the value of "border-image-repeat" */
  void set borderImageRepeat(var value);

  /** Gets the value of "border-image-slice" */
  String get borderImageSlice();

  /** Sets the value of "border-image-slice" */
  void set borderImageSlice(var value);

  /** Gets the value of "border-image-source" */
  String get borderImageSource();

  /** Sets the value of "border-image-source" */
  void set borderImageSource(var value);

  /** Gets the value of "border-image-width" */
  String get borderImageWidth();

  /** Sets the value of "border-image-width" */
  void set borderImageWidth(var value);

  /** Gets the value of "border-left" */
  String get borderLeft();

  /** Sets the value of "border-left" */
  void set borderLeft(var value);

  /** Gets the value of "border-left-color" */
  String get borderLeftColor();

  /** Sets the value of "border-left-color" */
  void set borderLeftColor(var value);

  /** Gets the value of "border-left-style" */
  String get borderLeftStyle();

  /** Sets the value of "border-left-style" */
  void set borderLeftStyle(var value);

  /** Gets the value of "border-left-width" */
  String get borderLeftWidth();

  /** Sets the value of "border-left-width" */
  void set borderLeftWidth(var value);

  /** Gets the value of "border-radius" */
  String get borderRadius();

  /** Sets the value of "border-radius" */
  void set borderRadius(var value);

  /** Gets the value of "border-right" */
  String get borderRight();

  /** Sets the value of "border-right" */
  void set borderRight(var value);

  /** Gets the value of "border-right-color" */
  String get borderRightColor();

  /** Sets the value of "border-right-color" */
  void set borderRightColor(var value);

  /** Gets the value of "border-right-style" */
  String get borderRightStyle();

  /** Sets the value of "border-right-style" */
  void set borderRightStyle(var value);

  /** Gets the value of "border-right-width" */
  String get borderRightWidth();

  /** Sets the value of "border-right-width" */
  void set borderRightWidth(var value);

  /** Gets the value of "border-spacing" */
  String get borderSpacing();

  /** Sets the value of "border-spacing" */
  void set borderSpacing(var value);

  /** Gets the value of "border-start" */
  String get borderStart();

  /** Sets the value of "border-start" */
  void set borderStart(var value);

  /** Gets the value of "border-start-color" */
  String get borderStartColor();

  /** Sets the value of "border-start-color" */
  void set borderStartColor(var value);

  /** Gets the value of "border-start-style" */
  String get borderStartStyle();

  /** Sets the value of "border-start-style" */
  void set borderStartStyle(var value);

  /** Gets the value of "border-start-width" */
  String get borderStartWidth();

  /** Sets the value of "border-start-width" */
  void set borderStartWidth(var value);

  /** Gets the value of "border-style" */
  String get borderStyle();

  /** Sets the value of "border-style" */
  void set borderStyle(var value);

  /** Gets the value of "border-top" */
  String get borderTop();

  /** Sets the value of "border-top" */
  void set borderTop(var value);

  /** Gets the value of "border-top-color" */
  String get borderTopColor();

  /** Sets the value of "border-top-color" */
  void set borderTopColor(var value);

  /** Gets the value of "border-top-left-radius" */
  String get borderTopLeftRadius();

  /** Sets the value of "border-top-left-radius" */
  void set borderTopLeftRadius(var value);

  /** Gets the value of "border-top-right-radius" */
  String get borderTopRightRadius();

  /** Sets the value of "border-top-right-radius" */
  void set borderTopRightRadius(var value);

  /** Gets the value of "border-top-style" */
  String get borderTopStyle();

  /** Sets the value of "border-top-style" */
  void set borderTopStyle(var value);

  /** Gets the value of "border-top-width" */
  String get borderTopWidth();

  /** Sets the value of "border-top-width" */
  void set borderTopWidth(var value);

  /** Gets the value of "border-vertical-spacing" */
  String get borderVerticalSpacing();

  /** Sets the value of "border-vertical-spacing" */
  void set borderVerticalSpacing(var value);

  /** Gets the value of "border-width" */
  String get borderWidth();

  /** Sets the value of "border-width" */
  void set borderWidth(var value);

  /** Gets the value of "bottom" */
  String get bottom();

  /** Sets the value of "bottom" */
  void set bottom(var value);

  /** Gets the value of "box-align" */
  String get boxAlign();

  /** Sets the value of "box-align" */
  void set boxAlign(var value);

  /** Gets the value of "box-direction" */
  String get boxDirection();

  /** Sets the value of "box-direction" */
  void set boxDirection(var value);

  /** Gets the value of "box-flex" */
  String get boxFlex();

  /** Sets the value of "box-flex" */
  void set boxFlex(var value);

  /** Gets the value of "box-flex-group" */
  String get boxFlexGroup();

  /** Sets the value of "box-flex-group" */
  void set boxFlexGroup(var value);

  /** Gets the value of "box-lines" */
  String get boxLines();

  /** Sets the value of "box-lines" */
  void set boxLines(var value);

  /** Gets the value of "box-ordinal-group" */
  String get boxOrdinalGroup();

  /** Sets the value of "box-ordinal-group" */
  void set boxOrdinalGroup(var value);

  /** Gets the value of "box-orient" */
  String get boxOrient();

  /** Sets the value of "box-orient" */
  void set boxOrient(var value);

  /** Gets the value of "box-pack" */
  String get boxPack();

  /** Sets the value of "box-pack" */
  void set boxPack(var value);

  /** Gets the value of "box-reflect" */
  String get boxReflect();

  /** Sets the value of "box-reflect" */
  void set boxReflect(var value);

  /** Gets the value of "box-shadow" */
  String get boxShadow();

  /** Sets the value of "box-shadow" */
  void set boxShadow(var value);

  /** Gets the value of "box-sizing" */
  String get boxSizing();

  /** Sets the value of "box-sizing" */
  void set boxSizing(var value);

  /** Gets the value of "caption-side" */
  String get captionSide();

  /** Sets the value of "caption-side" */
  void set captionSide(var value);

  /** Gets the value of "clear" */
  String get clear();

  /** Sets the value of "clear" */
  void set clear(var value);

  /** Gets the value of "clip" */
  String get clip();

  /** Sets the value of "clip" */
  void set clip(var value);

  /** Gets the value of "color" */
  String get color();

  /** Sets the value of "color" */
  void set color(var value);

  /** Gets the value of "color-correction" */
  String get colorCorrection();

  /** Sets the value of "color-correction" */
  void set colorCorrection(var value);

  /** Gets the value of "column-break-after" */
  String get columnBreakAfter();

  /** Sets the value of "column-break-after" */
  void set columnBreakAfter(var value);

  /** Gets the value of "column-break-before" */
  String get columnBreakBefore();

  /** Sets the value of "column-break-before" */
  void set columnBreakBefore(var value);

  /** Gets the value of "column-break-inside" */
  String get columnBreakInside();

  /** Sets the value of "column-break-inside" */
  void set columnBreakInside(var value);

  /** Gets the value of "column-count" */
  String get columnCount();

  /** Sets the value of "column-count" */
  void set columnCount(var value);

  /** Gets the value of "column-gap" */
  String get columnGap();

  /** Sets the value of "column-gap" */
  void set columnGap(var value);

  /** Gets the value of "column-rule" */
  String get columnRule();

  /** Sets the value of "column-rule" */
  void set columnRule(var value);

  /** Gets the value of "column-rule-color" */
  String get columnRuleColor();

  /** Sets the value of "column-rule-color" */
  void set columnRuleColor(var value);

  /** Gets the value of "column-rule-style" */
  String get columnRuleStyle();

  /** Sets the value of "column-rule-style" */
  void set columnRuleStyle(var value);

  /** Gets the value of "column-rule-width" */
  String get columnRuleWidth();

  /** Sets the value of "column-rule-width" */
  void set columnRuleWidth(var value);

  /** Gets the value of "column-span" */
  String get columnSpan();

  /** Sets the value of "column-span" */
  void set columnSpan(var value);

  /** Gets the value of "column-width" */
  String get columnWidth();

  /** Sets the value of "column-width" */
  void set columnWidth(var value);

  /** Gets the value of "columns" */
  String get columns();

  /** Sets the value of "columns" */
  void set columns(var value);

  /** Gets the value of "content" */
  String get content();

  /** Sets the value of "content" */
  void set content(var value);

  /** Gets the value of "counter-increment" */
  String get counterIncrement();

  /** Sets the value of "counter-increment" */
  void set counterIncrement(var value);

  /** Gets the value of "counter-reset" */
  String get counterReset();

  /** Sets the value of "counter-reset" */
  void set counterReset(var value);

  /** Gets the value of "cursor" */
  String get cursor();

  /** Sets the value of "cursor" */
  void set cursor(var value);

  /** Gets the value of "direction" */
  String get direction();

  /** Sets the value of "direction" */
  void set direction(var value);

  /** Gets the value of "display" */
  String get display();

  /** Sets the value of "display" */
  void set display(var value);

  /** Gets the value of "empty-cells" */
  String get emptyCells();

  /** Sets the value of "empty-cells" */
  void set emptyCells(var value);

  /** Gets the value of "filter" */
  String get filter();

  /** Sets the value of "filter" */
  void set filter(var value);

  /** Gets the value of "flex-align" */
  String get flexAlign();

  /** Sets the value of "flex-align" */
  void set flexAlign(var value);

  /** Gets the value of "flex-flow" */
  String get flexFlow();

  /** Sets the value of "flex-flow" */
  void set flexFlow(var value);

  /** Gets the value of "flex-order" */
  String get flexOrder();

  /** Sets the value of "flex-order" */
  void set flexOrder(var value);

  /** Gets the value of "flex-pack" */
  String get flexPack();

  /** Sets the value of "flex-pack" */
  void set flexPack(var value);

  /** Gets the value of "float" */
  String get float();

  /** Sets the value of "float" */
  void set float(var value);

  /** Gets the value of "flow-from" */
  String get flowFrom();

  /** Sets the value of "flow-from" */
  void set flowFrom(var value);

  /** Gets the value of "flow-into" */
  String get flowInto();

  /** Sets the value of "flow-into" */
  void set flowInto(var value);

  /** Gets the value of "font" */
  String get font();

  /** Sets the value of "font" */
  void set font(var value);

  /** Gets the value of "font-family" */
  String get fontFamily();

  /** Sets the value of "font-family" */
  void set fontFamily(var value);

  /** Gets the value of "font-feature-settings" */
  String get fontFeatureSettings();

  /** Sets the value of "font-feature-settings" */
  void set fontFeatureSettings(var value);

  /** Gets the value of "font-size" */
  String get fontSize();

  /** Sets the value of "font-size" */
  void set fontSize(var value);

  /** Gets the value of "font-size-delta" */
  String get fontSizeDelta();

  /** Sets the value of "font-size-delta" */
  void set fontSizeDelta(var value);

  /** Gets the value of "font-smoothing" */
  String get fontSmoothing();

  /** Sets the value of "font-smoothing" */
  void set fontSmoothing(var value);

  /** Gets the value of "font-stretch" */
  String get fontStretch();

  /** Sets the value of "font-stretch" */
  void set fontStretch(var value);

  /** Gets the value of "font-style" */
  String get fontStyle();

  /** Sets the value of "font-style" */
  void set fontStyle(var value);

  /** Gets the value of "font-variant" */
  String get fontVariant();

  /** Sets the value of "font-variant" */
  void set fontVariant(var value);

  /** Gets the value of "font-weight" */
  String get fontWeight();

  /** Sets the value of "font-weight" */
  void set fontWeight(var value);

  /** Gets the value of "height" */
  String get height();

  /** Sets the value of "height" */
  void set height(var value);

  /** Gets the value of "highlight" */
  String get highlight();

  /** Sets the value of "highlight" */
  void set highlight(var value);

  /** Gets the value of "hyphenate-character" */
  String get hyphenateCharacter();

  /** Sets the value of "hyphenate-character" */
  void set hyphenateCharacter(var value);

  /** Gets the value of "hyphenate-limit-after" */
  String get hyphenateLimitAfter();

  /** Sets the value of "hyphenate-limit-after" */
  void set hyphenateLimitAfter(var value);

  /** Gets the value of "hyphenate-limit-before" */
  String get hyphenateLimitBefore();

  /** Sets the value of "hyphenate-limit-before" */
  void set hyphenateLimitBefore(var value);

  /** Gets the value of "hyphenate-limit-lines" */
  String get hyphenateLimitLines();

  /** Sets the value of "hyphenate-limit-lines" */
  void set hyphenateLimitLines(var value);

  /** Gets the value of "hyphens" */
  String get hyphens();

  /** Sets the value of "hyphens" */
  void set hyphens(var value);

  /** Gets the value of "image-rendering" */
  String get imageRendering();

  /** Sets the value of "image-rendering" */
  void set imageRendering(var value);

  /** Gets the value of "left" */
  String get left();

  /** Sets the value of "left" */
  void set left(var value);

  /** Gets the value of "letter-spacing" */
  String get letterSpacing();

  /** Sets the value of "letter-spacing" */
  void set letterSpacing(var value);

  /** Gets the value of "line-box-contain" */
  String get lineBoxContain();

  /** Sets the value of "line-box-contain" */
  void set lineBoxContain(var value);

  /** Gets the value of "line-break" */
  String get lineBreak();

  /** Sets the value of "line-break" */
  void set lineBreak(var value);

  /** Gets the value of "line-clamp" */
  String get lineClamp();

  /** Sets the value of "line-clamp" */
  void set lineClamp(var value);

  /** Gets the value of "line-height" */
  String get lineHeight();

  /** Sets the value of "line-height" */
  void set lineHeight(var value);

  /** Gets the value of "list-style" */
  String get listStyle();

  /** Sets the value of "list-style" */
  void set listStyle(var value);

  /** Gets the value of "list-style-image" */
  String get listStyleImage();

  /** Sets the value of "list-style-image" */
  void set listStyleImage(var value);

  /** Gets the value of "list-style-position" */
  String get listStylePosition();

  /** Sets the value of "list-style-position" */
  void set listStylePosition(var value);

  /** Gets the value of "list-style-type" */
  String get listStyleType();

  /** Sets the value of "list-style-type" */
  void set listStyleType(var value);

  /** Gets the value of "locale" */
  String get locale();

  /** Sets the value of "locale" */
  void set locale(var value);

  /** Gets the value of "logical-height" */
  String get logicalHeight();

  /** Sets the value of "logical-height" */
  void set logicalHeight(var value);

  /** Gets the value of "logical-width" */
  String get logicalWidth();

  /** Sets the value of "logical-width" */
  void set logicalWidth(var value);

  /** Gets the value of "margin" */
  String get margin();

  /** Sets the value of "margin" */
  void set margin(var value);

  /** Gets the value of "margin-after" */
  String get marginAfter();

  /** Sets the value of "margin-after" */
  void set marginAfter(var value);

  /** Gets the value of "margin-after-collapse" */
  String get marginAfterCollapse();

  /** Sets the value of "margin-after-collapse" */
  void set marginAfterCollapse(var value);

  /** Gets the value of "margin-before" */
  String get marginBefore();

  /** Sets the value of "margin-before" */
  void set marginBefore(var value);

  /** Gets the value of "margin-before-collapse" */
  String get marginBeforeCollapse();

  /** Sets the value of "margin-before-collapse" */
  void set marginBeforeCollapse(var value);

  /** Gets the value of "margin-bottom" */
  String get marginBottom();

  /** Sets the value of "margin-bottom" */
  void set marginBottom(var value);

  /** Gets the value of "margin-bottom-collapse" */
  String get marginBottomCollapse();

  /** Sets the value of "margin-bottom-collapse" */
  void set marginBottomCollapse(var value);

  /** Gets the value of "margin-collapse" */
  String get marginCollapse();

  /** Sets the value of "margin-collapse" */
  void set marginCollapse(var value);

  /** Gets the value of "margin-end" */
  String get marginEnd();

  /** Sets the value of "margin-end" */
  void set marginEnd(var value);

  /** Gets the value of "margin-left" */
  String get marginLeft();

  /** Sets the value of "margin-left" */
  void set marginLeft(var value);

  /** Gets the value of "margin-right" */
  String get marginRight();

  /** Sets the value of "margin-right" */
  void set marginRight(var value);

  /** Gets the value of "margin-start" */
  String get marginStart();

  /** Sets the value of "margin-start" */
  void set marginStart(var value);

  /** Gets the value of "margin-top" */
  String get marginTop();

  /** Sets the value of "margin-top" */
  void set marginTop(var value);

  /** Gets the value of "margin-top-collapse" */
  String get marginTopCollapse();

  /** Sets the value of "margin-top-collapse" */
  void set marginTopCollapse(var value);

  /** Gets the value of "marquee" */
  String get marquee();

  /** Sets the value of "marquee" */
  void set marquee(var value);

  /** Gets the value of "marquee-direction" */
  String get marqueeDirection();

  /** Sets the value of "marquee-direction" */
  void set marqueeDirection(var value);

  /** Gets the value of "marquee-increment" */
  String get marqueeIncrement();

  /** Sets the value of "marquee-increment" */
  void set marqueeIncrement(var value);

  /** Gets the value of "marquee-repetition" */
  String get marqueeRepetition();

  /** Sets the value of "marquee-repetition" */
  void set marqueeRepetition(var value);

  /** Gets the value of "marquee-speed" */
  String get marqueeSpeed();

  /** Sets the value of "marquee-speed" */
  void set marqueeSpeed(var value);

  /** Gets the value of "marquee-style" */
  String get marqueeStyle();

  /** Sets the value of "marquee-style" */
  void set marqueeStyle(var value);

  /** Gets the value of "mask" */
  String get mask();

  /** Sets the value of "mask" */
  void set mask(var value);

  /** Gets the value of "mask-attachment" */
  String get maskAttachment();

  /** Sets the value of "mask-attachment" */
  void set maskAttachment(var value);

  /** Gets the value of "mask-box-image" */
  String get maskBoxImage();

  /** Sets the value of "mask-box-image" */
  void set maskBoxImage(var value);

  /** Gets the value of "mask-box-image-outset" */
  String get maskBoxImageOutset();

  /** Sets the value of "mask-box-image-outset" */
  void set maskBoxImageOutset(var value);

  /** Gets the value of "mask-box-image-repeat" */
  String get maskBoxImageRepeat();

  /** Sets the value of "mask-box-image-repeat" */
  void set maskBoxImageRepeat(var value);

  /** Gets the value of "mask-box-image-slice" */
  String get maskBoxImageSlice();

  /** Sets the value of "mask-box-image-slice" */
  void set maskBoxImageSlice(var value);

  /** Gets the value of "mask-box-image-source" */
  String get maskBoxImageSource();

  /** Sets the value of "mask-box-image-source" */
  void set maskBoxImageSource(var value);

  /** Gets the value of "mask-box-image-width" */
  String get maskBoxImageWidth();

  /** Sets the value of "mask-box-image-width" */
  void set maskBoxImageWidth(var value);

  /** Gets the value of "mask-clip" */
  String get maskClip();

  /** Sets the value of "mask-clip" */
  void set maskClip(var value);

  /** Gets the value of "mask-composite" */
  String get maskComposite();

  /** Sets the value of "mask-composite" */
  void set maskComposite(var value);

  /** Gets the value of "mask-image" */
  String get maskImage();

  /** Sets the value of "mask-image" */
  void set maskImage(var value);

  /** Gets the value of "mask-origin" */
  String get maskOrigin();

  /** Sets the value of "mask-origin" */
  void set maskOrigin(var value);

  /** Gets the value of "mask-position" */
  String get maskPosition();

  /** Sets the value of "mask-position" */
  void set maskPosition(var value);

  /** Gets the value of "mask-position-x" */
  String get maskPositionX();

  /** Sets the value of "mask-position-x" */
  void set maskPositionX(var value);

  /** Gets the value of "mask-position-y" */
  String get maskPositionY();

  /** Sets the value of "mask-position-y" */
  void set maskPositionY(var value);

  /** Gets the value of "mask-repeat" */
  String get maskRepeat();

  /** Sets the value of "mask-repeat" */
  void set maskRepeat(var value);

  /** Gets the value of "mask-repeat-x" */
  String get maskRepeatX();

  /** Sets the value of "mask-repeat-x" */
  void set maskRepeatX(var value);

  /** Gets the value of "mask-repeat-y" */
  String get maskRepeatY();

  /** Sets the value of "mask-repeat-y" */
  void set maskRepeatY(var value);

  /** Gets the value of "mask-size" */
  String get maskSize();

  /** Sets the value of "mask-size" */
  void set maskSize(var value);

  /** Gets the value of "match-nearest-mail-blockquote-color" */
  String get matchNearestMailBlockquoteColor();

  /** Sets the value of "match-nearest-mail-blockquote-color" */
  void set matchNearestMailBlockquoteColor(var value);

  /** Gets the value of "max-height" */
  String get maxHeight();

  /** Sets the value of "max-height" */
  void set maxHeight(var value);

  /** Gets the value of "max-logical-height" */
  String get maxLogicalHeight();

  /** Sets the value of "max-logical-height" */
  void set maxLogicalHeight(var value);

  /** Gets the value of "max-logical-width" */
  String get maxLogicalWidth();

  /** Sets the value of "max-logical-width" */
  void set maxLogicalWidth(var value);

  /** Gets the value of "max-width" */
  String get maxWidth();

  /** Sets the value of "max-width" */
  void set maxWidth(var value);

  /** Gets the value of "min-height" */
  String get minHeight();

  /** Sets the value of "min-height" */
  void set minHeight(var value);

  /** Gets the value of "min-logical-height" */
  String get minLogicalHeight();

  /** Sets the value of "min-logical-height" */
  void set minLogicalHeight(var value);

  /** Gets the value of "min-logical-width" */
  String get minLogicalWidth();

  /** Sets the value of "min-logical-width" */
  void set minLogicalWidth(var value);

  /** Gets the value of "min-width" */
  String get minWidth();

  /** Sets the value of "min-width" */
  void set minWidth(var value);

  /** Gets the value of "nbsp-mode" */
  String get nbspMode();

  /** Sets the value of "nbsp-mode" */
  void set nbspMode(var value);

  /** Gets the value of "opacity" */
  String get opacity();

  /** Sets the value of "opacity" */
  void set opacity(var value);

  /** Gets the value of "orphans" */
  String get orphans();

  /** Sets the value of "orphans" */
  void set orphans(var value);

  /** Gets the value of "outline" */
  String get outline();

  /** Sets the value of "outline" */
  void set outline(var value);

  /** Gets the value of "outline-color" */
  String get outlineColor();

  /** Sets the value of "outline-color" */
  void set outlineColor(var value);

  /** Gets the value of "outline-offset" */
  String get outlineOffset();

  /** Sets the value of "outline-offset" */
  void set outlineOffset(var value);

  /** Gets the value of "outline-style" */
  String get outlineStyle();

  /** Sets the value of "outline-style" */
  void set outlineStyle(var value);

  /** Gets the value of "outline-width" */
  String get outlineWidth();

  /** Sets the value of "outline-width" */
  void set outlineWidth(var value);

  /** Gets the value of "overflow" */
  String get overflow();

  /** Sets the value of "overflow" */
  void set overflow(var value);

  /** Gets the value of "overflow-x" */
  String get overflowX();

  /** Sets the value of "overflow-x" */
  void set overflowX(var value);

  /** Gets the value of "overflow-y" */
  String get overflowY();

  /** Sets the value of "overflow-y" */
  void set overflowY(var value);

  /** Gets the value of "padding" */
  String get padding();

  /** Sets the value of "padding" */
  void set padding(var value);

  /** Gets the value of "padding-after" */
  String get paddingAfter();

  /** Sets the value of "padding-after" */
  void set paddingAfter(var value);

  /** Gets the value of "padding-before" */
  String get paddingBefore();

  /** Sets the value of "padding-before" */
  void set paddingBefore(var value);

  /** Gets the value of "padding-bottom" */
  String get paddingBottom();

  /** Sets the value of "padding-bottom" */
  void set paddingBottom(var value);

  /** Gets the value of "padding-end" */
  String get paddingEnd();

  /** Sets the value of "padding-end" */
  void set paddingEnd(var value);

  /** Gets the value of "padding-left" */
  String get paddingLeft();

  /** Sets the value of "padding-left" */
  void set paddingLeft(var value);

  /** Gets the value of "padding-right" */
  String get paddingRight();

  /** Sets the value of "padding-right" */
  void set paddingRight(var value);

  /** Gets the value of "padding-start" */
  String get paddingStart();

  /** Sets the value of "padding-start" */
  void set paddingStart(var value);

  /** Gets the value of "padding-top" */
  String get paddingTop();

  /** Sets the value of "padding-top" */
  void set paddingTop(var value);

  /** Gets the value of "page" */
  String get page();

  /** Sets the value of "page" */
  void set page(var value);

  /** Gets the value of "page-break-after" */
  String get pageBreakAfter();

  /** Sets the value of "page-break-after" */
  void set pageBreakAfter(var value);

  /** Gets the value of "page-break-before" */
  String get pageBreakBefore();

  /** Sets the value of "page-break-before" */
  void set pageBreakBefore(var value);

  /** Gets the value of "page-break-inside" */
  String get pageBreakInside();

  /** Sets the value of "page-break-inside" */
  void set pageBreakInside(var value);

  /** Gets the value of "perspective" */
  String get perspective();

  /** Sets the value of "perspective" */
  void set perspective(var value);

  /** Gets the value of "perspective-origin" */
  String get perspectiveOrigin();

  /** Sets the value of "perspective-origin" */
  void set perspectiveOrigin(var value);

  /** Gets the value of "perspective-origin-x" */
  String get perspectiveOriginX();

  /** Sets the value of "perspective-origin-x" */
  void set perspectiveOriginX(var value);

  /** Gets the value of "perspective-origin-y" */
  String get perspectiveOriginY();

  /** Sets the value of "perspective-origin-y" */
  void set perspectiveOriginY(var value);

  /** Gets the value of "pointer-events" */
  String get pointerEvents();

  /** Sets the value of "pointer-events" */
  void set pointerEvents(var value);

  /** Gets the value of "position" */
  String get position();

  /** Sets the value of "position" */
  void set position(var value);

  /** Gets the value of "quotes" */
  String get quotes();

  /** Sets the value of "quotes" */
  void set quotes(var value);

  /** Gets the value of "region-break-after" */
  String get regionBreakAfter();

  /** Sets the value of "region-break-after" */
  void set regionBreakAfter(var value);

  /** Gets the value of "region-break-before" */
  String get regionBreakBefore();

  /** Sets the value of "region-break-before" */
  void set regionBreakBefore(var value);

  /** Gets the value of "region-break-inside" */
  String get regionBreakInside();

  /** Sets the value of "region-break-inside" */
  void set regionBreakInside(var value);

  /** Gets the value of "region-overflow" */
  String get regionOverflow();

  /** Sets the value of "region-overflow" */
  void set regionOverflow(var value);

  /** Gets the value of "resize" */
  String get resize();

  /** Sets the value of "resize" */
  void set resize(var value);

  /** Gets the value of "right" */
  String get right();

  /** Sets the value of "right" */
  void set right(var value);

  /** Gets the value of "rtl-ordering" */
  String get rtlOrdering();

  /** Sets the value of "rtl-ordering" */
  void set rtlOrdering(var value);

  /** Gets the value of "size" */
  String get size();

  /** Sets the value of "size" */
  void set size(var value);

  /** Gets the value of "speak" */
  String get speak();

  /** Sets the value of "speak" */
  void set speak(var value);

  /** Gets the value of "src" */
  String get src();

  /** Sets the value of "src" */
  void set src(var value);

  /** Gets the value of "table-layout" */
  String get tableLayout();

  /** Sets the value of "table-layout" */
  void set tableLayout(var value);

  /** Gets the value of "tap-highlight-color" */
  String get tapHighlightColor();

  /** Sets the value of "tap-highlight-color" */
  void set tapHighlightColor(var value);

  /** Gets the value of "text-align" */
  String get textAlign();

  /** Sets the value of "text-align" */
  void set textAlign(var value);

  /** Gets the value of "text-combine" */
  String get textCombine();

  /** Sets the value of "text-combine" */
  void set textCombine(var value);

  /** Gets the value of "text-decoration" */
  String get textDecoration();

  /** Sets the value of "text-decoration" */
  void set textDecoration(var value);

  /** Gets the value of "text-decorations-in-effect" */
  String get textDecorationsInEffect();

  /** Sets the value of "text-decorations-in-effect" */
  void set textDecorationsInEffect(var value);

  /** Gets the value of "text-emphasis" */
  String get textEmphasis();

  /** Sets the value of "text-emphasis" */
  void set textEmphasis(var value);

  /** Gets the value of "text-emphasis-color" */
  String get textEmphasisColor();

  /** Sets the value of "text-emphasis-color" */
  void set textEmphasisColor(var value);

  /** Gets the value of "text-emphasis-position" */
  String get textEmphasisPosition();

  /** Sets the value of "text-emphasis-position" */
  void set textEmphasisPosition(var value);

  /** Gets the value of "text-emphasis-style" */
  String get textEmphasisStyle();

  /** Sets the value of "text-emphasis-style" */
  void set textEmphasisStyle(var value);

  /** Gets the value of "text-fill-color" */
  String get textFillColor();

  /** Sets the value of "text-fill-color" */
  void set textFillColor(var value);

  /** Gets the value of "text-indent" */
  String get textIndent();

  /** Sets the value of "text-indent" */
  void set textIndent(var value);

  /** Gets the value of "text-line-through" */
  String get textLineThrough();

  /** Sets the value of "text-line-through" */
  void set textLineThrough(var value);

  /** Gets the value of "text-line-through-color" */
  String get textLineThroughColor();

  /** Sets the value of "text-line-through-color" */
  void set textLineThroughColor(var value);

  /** Gets the value of "text-line-through-mode" */
  String get textLineThroughMode();

  /** Sets the value of "text-line-through-mode" */
  void set textLineThroughMode(var value);

  /** Gets the value of "text-line-through-style" */
  String get textLineThroughStyle();

  /** Sets the value of "text-line-through-style" */
  void set textLineThroughStyle(var value);

  /** Gets the value of "text-line-through-width" */
  String get textLineThroughWidth();

  /** Sets the value of "text-line-through-width" */
  void set textLineThroughWidth(var value);

  /** Gets the value of "text-orientation" */
  String get textOrientation();

  /** Sets the value of "text-orientation" */
  void set textOrientation(var value);

  /** Gets the value of "text-overflow" */
  String get textOverflow();

  /** Sets the value of "text-overflow" */
  void set textOverflow(var value);

  /** Gets the value of "text-overline" */
  String get textOverline();

  /** Sets the value of "text-overline" */
  void set textOverline(var value);

  /** Gets the value of "text-overline-color" */
  String get textOverlineColor();

  /** Sets the value of "text-overline-color" */
  void set textOverlineColor(var value);

  /** Gets the value of "text-overline-mode" */
  String get textOverlineMode();

  /** Sets the value of "text-overline-mode" */
  void set textOverlineMode(var value);

  /** Gets the value of "text-overline-style" */
  String get textOverlineStyle();

  /** Sets the value of "text-overline-style" */
  void set textOverlineStyle(var value);

  /** Gets the value of "text-overline-width" */
  String get textOverlineWidth();

  /** Sets the value of "text-overline-width" */
  void set textOverlineWidth(var value);

  /** Gets the value of "text-rendering" */
  String get textRendering();

  /** Sets the value of "text-rendering" */
  void set textRendering(var value);

  /** Gets the value of "text-security" */
  String get textSecurity();

  /** Sets the value of "text-security" */
  void set textSecurity(var value);

  /** Gets the value of "text-shadow" */
  String get textShadow();

  /** Sets the value of "text-shadow" */
  void set textShadow(var value);

  /** Gets the value of "text-size-adjust" */
  String get textSizeAdjust();

  /** Sets the value of "text-size-adjust" */
  void set textSizeAdjust(var value);

  /** Gets the value of "text-stroke" */
  String get textStroke();

  /** Sets the value of "text-stroke" */
  void set textStroke(var value);

  /** Gets the value of "text-stroke-color" */
  String get textStrokeColor();

  /** Sets the value of "text-stroke-color" */
  void set textStrokeColor(var value);

  /** Gets the value of "text-stroke-width" */
  String get textStrokeWidth();

  /** Sets the value of "text-stroke-width" */
  void set textStrokeWidth(var value);

  /** Gets the value of "text-transform" */
  String get textTransform();

  /** Sets the value of "text-transform" */
  void set textTransform(var value);

  /** Gets the value of "text-underline" */
  String get textUnderline();

  /** Sets the value of "text-underline" */
  void set textUnderline(var value);

  /** Gets the value of "text-underline-color" */
  String get textUnderlineColor();

  /** Sets the value of "text-underline-color" */
  void set textUnderlineColor(var value);

  /** Gets the value of "text-underline-mode" */
  String get textUnderlineMode();

  /** Sets the value of "text-underline-mode" */
  void set textUnderlineMode(var value);

  /** Gets the value of "text-underline-style" */
  String get textUnderlineStyle();

  /** Sets the value of "text-underline-style" */
  void set textUnderlineStyle(var value);

  /** Gets the value of "text-underline-width" */
  String get textUnderlineWidth();

  /** Sets the value of "text-underline-width" */
  void set textUnderlineWidth(var value);

  /** Gets the value of "top" */
  String get top();

  /** Sets the value of "top" */
  void set top(var value);

  /** Gets the value of "transform" */
  String get transform();

  /** Sets the value of "transform" */
  void set transform(var value);

  /** Gets the value of "transform-origin" */
  String get transformOrigin();

  /** Sets the value of "transform-origin" */
  void set transformOrigin(var value);

  /** Gets the value of "transform-origin-x" */
  String get transformOriginX();

  /** Sets the value of "transform-origin-x" */
  void set transformOriginX(var value);

  /** Gets the value of "transform-origin-y" */
  String get transformOriginY();

  /** Sets the value of "transform-origin-y" */
  void set transformOriginY(var value);

  /** Gets the value of "transform-origin-z" */
  String get transformOriginZ();

  /** Sets the value of "transform-origin-z" */
  void set transformOriginZ(var value);

  /** Gets the value of "transform-style" */
  String get transformStyle();

  /** Sets the value of "transform-style" */
  void set transformStyle(var value);

  /** Gets the value of "transition" */
  String get transition();

  /** Sets the value of "transition" */
  void set transition(var value);

  /** Gets the value of "transition-delay" */
  String get transitionDelay();

  /** Sets the value of "transition-delay" */
  void set transitionDelay(var value);

  /** Gets the value of "transition-duration" */
  String get transitionDuration();

  /** Sets the value of "transition-duration" */
  void set transitionDuration(var value);

  /** Gets the value of "transition-property" */
  String get transitionProperty();

  /** Sets the value of "transition-property" */
  void set transitionProperty(var value);

  /** Gets the value of "transition-timing-function" */
  String get transitionTimingFunction();

  /** Sets the value of "transition-timing-function" */
  void set transitionTimingFunction(var value);

  /** Gets the value of "unicode-bidi" */
  String get unicodeBidi();

  /** Sets the value of "unicode-bidi" */
  void set unicodeBidi(var value);

  /** Gets the value of "unicode-range" */
  String get unicodeRange();

  /** Sets the value of "unicode-range" */
  void set unicodeRange(var value);

  /** Gets the value of "user-drag" */
  String get userDrag();

  /** Sets the value of "user-drag" */
  void set userDrag(var value);

  /** Gets the value of "user-modify" */
  String get userModify();

  /** Sets the value of "user-modify" */
  void set userModify(var value);

  /** Gets the value of "user-select" */
  String get userSelect();

  /** Sets the value of "user-select" */
  void set userSelect(var value);

  /** Gets the value of "vertical-align" */
  String get verticalAlign();

  /** Sets the value of "vertical-align" */
  void set verticalAlign(var value);

  /** Gets the value of "visibility" */
  String get visibility();

  /** Sets the value of "visibility" */
  void set visibility(var value);

  /** Gets the value of "white-space" */
  String get whiteSpace();

  /** Sets the value of "white-space" */
  void set whiteSpace(var value);

  /** Gets the value of "widows" */
  String get widows();

  /** Sets the value of "widows" */
  void set widows(var value);

  /** Gets the value of "width" */
  String get width();

  /** Sets the value of "width" */
  void set width(var value);

  /** Gets the value of "word-break" */
  String get wordBreak();

  /** Sets the value of "word-break" */
  void set wordBreak(var value);

  /** Gets the value of "word-spacing" */
  String get wordSpacing();

  /** Sets the value of "word-spacing" */
  void set wordSpacing(var value);

  /** Gets the value of "word-wrap" */
  String get wordWrap();

  /** Sets the value of "word-wrap" */
  void set wordWrap(var value);

  /** Gets the value of "wrap-shape" */
  String get wrapShape();

  /** Sets the value of "wrap-shape" */
  void set wrapShape(var value);

  /** Gets the value of "writing-mode" */
  String get writingMode();

  /** Sets the value of "writing-mode" */
  void set writingMode(var value);

  /** Gets the value of "z-index" */
  String get zIndex();

  /** Sets the value of "z-index" */
  void set zIndex(var value);

  /** Gets the value of "zoom" */
  String get zoom();

  /** Sets the value of "zoom" */
  void set zoom(var value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSStyleRule extends CSSRule {

  String selectorText;

  final CSSStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSStyleSheet extends StyleSheet {

  final CSSRuleList cssRules;

  final CSSRule ownerRule;

  final CSSRuleList rules;

  int addRule(String selector, String style, [int index]);

  void deleteRule(int index);

  int insertRule(String rule, int index);

  void removeRule(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSTransformValue extends CSSValueList {

  static final int CSS_MATRIX = 11;

  static final int CSS_MATRIX3D = 21;

  static final int CSS_PERSPECTIVE = 20;

  static final int CSS_ROTATE = 4;

  static final int CSS_ROTATE3D = 17;

  static final int CSS_ROTATEX = 14;

  static final int CSS_ROTATEY = 15;

  static final int CSS_ROTATEZ = 16;

  static final int CSS_SCALE = 5;

  static final int CSS_SCALE3D = 19;

  static final int CSS_SCALEX = 6;

  static final int CSS_SCALEY = 7;

  static final int CSS_SCALEZ = 18;

  static final int CSS_SKEW = 8;

  static final int CSS_SKEWX = 9;

  static final int CSS_SKEWY = 10;

  static final int CSS_TRANSLATE = 1;

  static final int CSS_TRANSLATE3D = 13;

  static final int CSS_TRANSLATEX = 2;

  static final int CSS_TRANSLATEY = 3;

  static final int CSS_TRANSLATEZ = 12;

  final int operationType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSUnknownRule extends CSSRule {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSValue {

  static final int CSS_CUSTOM = 3;

  static final int CSS_INHERIT = 0;

  static final int CSS_PRIMITIVE_VALUE = 1;

  static final int CSS_VALUE_LIST = 2;

  String cssText;

  final int cssValueType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSValueList extends CSSValue {

  final int length;

  CSSValue item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasElement extends Element {

  int height;

  int width;

  Object getContext(String contextId);

  String toDataURL(String type);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasGradient {

  void addColorStop(num offset, String color);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasPattern {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasPixelArray extends List<int> {

  final int length;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasRenderingContext {

  final CanvasElement canvas;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasRenderingContext2D extends CanvasRenderingContext {

  Dynamic fillStyle;

  String font;

  num globalAlpha;

  String globalCompositeOperation;

  String lineCap;

  String lineJoin;

  num lineWidth;

  num miterLimit;

  num shadowBlur;

  String shadowColor;

  num shadowOffsetX;

  num shadowOffsetY;

  Dynamic strokeStyle;

  String textAlign;

  String textBaseline;

  List webkitLineDash;

  num webkitLineDashOffset;

  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise);

  void arcTo(num x1, num y1, num x2, num y2, num radius);

  void beginPath();

  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y);

  void clearRect(num x, num y, num width, num height);

  void clearShadow();

  void clip();

  void closePath();

  ImageData createImageData(var imagedata_OR_sw, [num sh]);

  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1);

  CanvasPattern createPattern(var canvas_OR_image, String repetitionType);

  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1);

  void drawImage(var canvas_OR_image_OR_video, num sx_OR_x, num sy_OR_y, [num sw_OR_width, num height_OR_sh, num dx, num dy, num dw, num dh]);

  void drawImageFromRect(ImageElement image, [num sx, num sy, num sw, num sh, num dx, num dy, num dw, num dh, String compositeOperation]);

  void fill();

  void fillRect(num x, num y, num width, num height);

  void fillText(String text, num x, num y, [num maxWidth]);

  ImageData getImageData(num sx, num sy, num sw, num sh);

  bool isPointInPath(num x, num y);

  void lineTo(num x, num y);

  TextMetrics measureText(String text);

  void moveTo(num x, num y);

  void putImageData(ImageData imagedata, num dx, num dy, [num dirtyX, num dirtyY, num dirtyWidth, num dirtyHeight]);

  void quadraticCurveTo(num cpx, num cpy, num x, num y);

  void rect(num x, num y, num width, num height);

  void restore();

  void rotate(num angle);

  void save();

  void scale(num sx, num sy);

  void setAlpha(num alpha);

  void setCompositeOperation(String compositeOperation);

  void setFillColor(var c_OR_color_OR_grayLevel_OR_r, [num alpha_OR_g_OR_m, num b_OR_y, num a_OR_k, num a]);

  void setLineCap(String cap);

  void setLineJoin(String join);

  void setLineWidth(num width);

  void setMiterLimit(num limit);

  void setShadow(num width, num height, num blur, [var c_OR_color_OR_grayLevel_OR_r, num alpha_OR_g_OR_m, num b_OR_y, num a_OR_k, num a]);

  void setStrokeColor(var c_OR_color_OR_grayLevel_OR_r, [num alpha_OR_g_OR_m, num b_OR_y, num a_OR_k, num a]);

  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy);

  void stroke();

  void strokeRect(num x, num y, num width, num height, [num lineWidth]);

  void strokeText(String text, num x, num y, [num maxWidth]);

  void transform(num m11, num m12, num m21, num m22, num dx, num dy);

  void translate(num tx, num ty);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CharacterData extends Node {

  String data;

  final int length;

  void appendData(String data);

  void deleteData(int offset, int length);

  void insertData(int offset, String data);

  void replaceData(int offset, int length, String data);

  String substringData(int offset, int length);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ClientRect {

  final num bottom;

  final num height;

  final num left;

  final num right;

  final num top;

  final num width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ClientRectList {

  final int length;

  ClientRect item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Clipboard {

  String dropEffect;

  String effectAllowed;

  final FileList files;

  final DataTransferItemList items;

  final List types;

  void clearData([String type]);

  String getData(String type);

  bool setData(String type, String data);

  void setDragImage(ImageElement image, int x, int y);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CloseEvent extends Event {

  final int code;

  final String reason;

  final bool wasClean;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Comment extends CharacterData {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CompositionEvent extends UIEvent {

  final String data;

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Window viewArg, String dataArg);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Console {

  final MemoryInfo memory;

  final List<ScriptProfile> profiles;

  void assertCondition(bool condition, Object arg);

  void count();

  void debug(Object arg);

  void dir();

  void dirxml();

  void error(Object arg);

  void group(Object arg);

  void groupCollapsed(Object arg);

  void groupEnd();

  void info(Object arg);

  void log(Object arg);

  void markTimeline();

  void profile(String title);

  void profileEnd(String title);

  void time(String title);

  void timeEnd(String title, Object arg);

  void timeStamp(Object arg);

  void trace(Object arg);

  void warn(Object arg);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ContentElement extends Element {

  String select;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ConvolverNode extends AudioNode {

  AudioBuffer buffer;

  bool normalize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Coordinates {

  final num accuracy;

  final num altitude;

  final num altitudeAccuracy;

  final num heading;

  final num latitude;

  final num longitude;

  final num speed;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Counter {

  final String identifier;

  final String listStyle;

  final String separator;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Crypto {

  void getRandomValues(ArrayBufferView array);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CustomEvent extends Event {

  final Object detail;

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DListElement extends Element {

  bool compact;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMApplicationCache extends EventTarget {

  DOMApplicationCacheEvents get on();

  static final int CHECKING = 2;

  static final int DOWNLOADING = 3;

  static final int IDLE = 1;

  static final int OBSOLETE = 5;

  static final int UNCACHED = 0;

  static final int UPDATEREADY = 4;

  final int status;

  void abort();

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]);

  bool $dom_dispatchEvent(Event evt);

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]);

  void swapCache();

  void update();
}

interface DOMApplicationCacheEvents extends Events {

  EventListenerList get cached();

  EventListenerList get checking();

  EventListenerList get downloading();

  EventListenerList get error();

  EventListenerList get noUpdate();

  EventListenerList get obsolete();

  EventListenerList get progress();

  EventListenerList get updateReady();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMException {

  static final int ABORT_ERR = 20;

  static final int DATA_CLONE_ERR = 25;

  static final int DOMSTRING_SIZE_ERR = 2;

  static final int HIERARCHY_REQUEST_ERR = 3;

  static final int INDEX_SIZE_ERR = 1;

  static final int INUSE_ATTRIBUTE_ERR = 10;

  static final int INVALID_ACCESS_ERR = 15;

  static final int INVALID_CHARACTER_ERR = 5;

  static final int INVALID_MODIFICATION_ERR = 13;

  static final int INVALID_NODE_TYPE_ERR = 24;

  static final int INVALID_STATE_ERR = 11;

  static final int NAMESPACE_ERR = 14;

  static final int NETWORK_ERR = 19;

  static final int NOT_FOUND_ERR = 8;

  static final int NOT_SUPPORTED_ERR = 9;

  static final int NO_DATA_ALLOWED_ERR = 6;

  static final int NO_MODIFICATION_ALLOWED_ERR = 7;

  static final int QUOTA_EXCEEDED_ERR = 22;

  static final int SECURITY_ERR = 18;

  static final int SYNTAX_ERR = 12;

  static final int TIMEOUT_ERR = 23;

  static final int TYPE_MISMATCH_ERR = 17;

  static final int URL_MISMATCH_ERR = 21;

  static final int VALIDATION_ERR = 16;

  static final int WRONG_DOCUMENT_ERR = 4;

  final int code;

  final String message;

  final String name;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMFileSystem {

  final String name;

  final DirectoryEntry root;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMFileSystemSync {

  final String name;

  final DirectoryEntrySync root;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMFormData {

  void append(String name, String value, String filename);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMImplementation {

  CSSStyleSheet createCSSStyleSheet(String title, String media);

  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype);

  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId);

  Document createHTMLDocument(String title);

  bool hasFeature(String feature, String version);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMMimeType {

  final String description;

  final DOMPlugin enabledPlugin;

  final String suffixes;

  final String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMMimeTypeArray {

  final int length;

  DOMMimeType item(int index);

  DOMMimeType namedItem(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMParser default _DOMParserFactoryProvider {

  DOMParser();

  Document parseFromString(String str, String contentType);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMPlugin {

  final String description;

  final String filename;

  final int length;

  final String name;

  DOMMimeType item(int index);

  DOMMimeType namedItem(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMPluginArray {

  final int length;

  DOMPlugin item(int index);

  DOMPlugin namedItem(String name);

  void refresh(bool reload);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMSelection {

  final Node anchorNode;

  final int anchorOffset;

  final Node baseNode;

  final int baseOffset;

  final Node extentNode;

  final int extentOffset;

  final Node focusNode;

  final int focusOffset;

  final bool isCollapsed;

  final int rangeCount;

  final String type;

  void addRange(Range range);

  void collapse(Node node, int index);

  void collapseToEnd();

  void collapseToStart();

  bool containsNode(Node node, bool allowPartial);

  void deleteFromDocument();

  void empty();

  void extend(Node node, int offset);

  Range getRangeAt(int index);

  void modify(String alter, String direction, String granularity);

  void removeAllRanges();

  void selectAllChildren(Node node);

  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset);

  void setPosition(Node node, int offset);

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMSettableTokenList extends DOMTokenList {

  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMTokenList {

  final int length;

  void add(String token);

  bool contains(String token);

  String item(int index);

  void remove(String token);

  String toString();

  bool toggle(String token);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMURL default _DOMURLFactoryProvider {

  DOMURL();

  String createObjectURL(var blob_OR_stream);

  void revokeObjectURL(String url);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DataTransferItem {

  final String kind;

  final String type;

  Blob getAsFile();

  void getAsString([StringCallback callback]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DataTransferItemList {

  final int length;

  void add(var data_OR_file, [String type]);

  void clear();

  DataTransferItem item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DataView extends ArrayBufferView {

  num getFloat32(int byteOffset, [bool littleEndian]);

  num getFloat64(int byteOffset, [bool littleEndian]);

  int getInt16(int byteOffset, [bool littleEndian]);

  int getInt32(int byteOffset, [bool littleEndian]);

  Object getInt8();

  int getUint16(int byteOffset, [bool littleEndian]);

  int getUint32(int byteOffset, [bool littleEndian]);

  Object getUint8();

  void setFloat32(int byteOffset, num value, [bool littleEndian]);

  void setFloat64(int byteOffset, num value, [bool littleEndian]);

  void setInt16(int byteOffset, int value, [bool littleEndian]);

  void setInt32(int byteOffset, int value, [bool littleEndian]);

  void setInt8();

  void setUint16(int byteOffset, int value, [bool littleEndian]);

  void setUint32(int byteOffset, int value, [bool littleEndian]);

  void setUint8();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Database {

  final String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback, SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]);

  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]);

  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool DatabaseCallback(var database);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DatabaseSync {

  final String lastErrorMessage;

  final String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback]);

  void readTransaction(SQLTransactionSyncCallback callback);

  void transaction(SQLTransactionSyncCallback callback);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DedicatedWorkerContext extends WorkerContext {

  EventListener onmessage;

  void postMessage(Object message, [List messagePorts]);

  void webkitPostMessage(Object message, [List transferList]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DelayNode extends AudioNode {

  final AudioParam delayTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DeprecatedPeerConnection default _DeprecatedPeerConnectionFactoryProvider {

  DeprecatedPeerConnection(String serverConfiguration, SignalingCallback signalingCallback);

  static final int ACTIVE = 2;

  static final int CLOSED = 3;

  static final int NEGOTIATING = 1;

  static final int NEW = 0;

  final MediaStreamList localStreams;

  EventListener onaddstream;

  EventListener onconnecting;

  EventListener onmessage;

  EventListener onopen;

  EventListener onremovestream;

  EventListener onstatechange;

  final int readyState;

  final MediaStreamList remoteStreams;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void addStream(MediaStream stream);

  void close();

  bool dispatchEvent(Event event);

  void processSignalingMessage(String message);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  void removeStream(MediaStream stream);

  void send(String text);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DetailsElement extends Element {

  bool open;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DeviceMotionEvent extends Event {

  final num interval;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DeviceOrientationEvent extends Event {

  final bool absolute;

  final num alpha;

  final num beta;

  final num gamma;

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryElement extends Element {

  bool compact;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryEntry extends Entry {

  DirectoryReader createReader();

  void getDirectory(String path, [Object flags, EntryCallback successCallback, ErrorCallback errorCallback]);

  void getFile(String path, [Object flags, EntryCallback successCallback, ErrorCallback errorCallback]);

  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryEntrySync extends EntrySync {

  DirectoryReaderSync createReader();

  DirectoryEntrySync getDirectory(String path, Object flags);

  FileEntrySync getFile(String path, Object flags);

  void removeRecursively();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryReader {

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryReaderSync {

  EntryArraySync readEntries();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DivElement extends Element {

  String align;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Document extends HtmlElement {


  DocumentEvents get on();

  final Element activeElement;

  Element body;

  String charset;

  String cookie;

  final Window window;

  final Element documentElement;

  final String domain;

  final HeadElement head;

  final String lastModified;

  final String preferredStylesheetSet;

  final String readyState;

  final String referrer;

  String selectedStylesheetSet;

  final StyleSheetList styleSheets;

  String title;

  final Element webkitCurrentFullScreenElement;

  final bool webkitFullScreenKeyboardInputAllowed;

  final Element webkitFullscreenElement;

  final bool webkitFullscreenEnabled;

  final bool webkitHidden;

  final bool webkitIsFullScreen;

  final String webkitVisibilityState;

  Range caretRangeFromPoint(int x, int y);

  CDATASection createCDATASection(String data);

  DocumentFragment createDocumentFragment();

  Element $dom_createElement(String tagName);

  Element $dom_createElementNS(String namespaceURI, String qualifiedName);

  Event $dom_createEvent(String eventType);

  Range createRange();

  Text $dom_createTextNode(String data);

  Touch createTouch(Window window, EventTarget target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce);

  TouchList $dom_createTouchList();

  Element elementFromPoint(int x, int y);

  bool execCommand(String command, bool userInterface, String value);

  CanvasRenderingContext getCSSCanvasContext(String contextId, String name, int width, int height);

  Element $dom_getElementById(String elementId);

  NodeList $dom_getElementsByClassName(String tagname);

  NodeList $dom_getElementsByName(String elementName);

  NodeList $dom_getElementsByTagName(String tagname);

  bool queryCommandEnabled(String command);

  bool queryCommandIndeterm(String command);

  bool queryCommandState(String command);

  bool queryCommandSupported(String command);

  String queryCommandValue(String command);

  Element query(String selectors);

  NodeList $dom_querySelectorAll(String selectors);

  void webkitCancelFullScreen();

  void webkitExitFullscreen();

  WebKitNamedFlow webkitGetFlowByName(String name);

}

interface DocumentEvents extends ElementEvents {

  EventListenerList get abort();

  EventListenerList get beforeCopy();

  EventListenerList get beforeCut();

  EventListenerList get beforePaste();

  EventListenerList get blur();

  EventListenerList get change();

  EventListenerList get click();

  EventListenerList get contextMenu();

  EventListenerList get copy();

  EventListenerList get cut();

  EventListenerList get doubleClick();

  EventListenerList get drag();

  EventListenerList get dragEnd();

  EventListenerList get dragEnter();

  EventListenerList get dragLeave();

  EventListenerList get dragOver();

  EventListenerList get dragStart();

  EventListenerList get drop();

  EventListenerList get error();

  EventListenerList get focus();

  EventListenerList get fullscreenChange();

  EventListenerList get fullscreenError();

  EventListenerList get input();

  EventListenerList get invalid();

  EventListenerList get keyDown();

  EventListenerList get keyPress();

  EventListenerList get keyUp();

  EventListenerList get load();

  EventListenerList get mouseDown();

  EventListenerList get mouseMove();

  EventListenerList get mouseOut();

  EventListenerList get mouseOver();

  EventListenerList get mouseUp();

  EventListenerList get mouseWheel();

  EventListenerList get paste();

  EventListenerList get readyStateChange();

  EventListenerList get reset();

  EventListenerList get scroll();

  EventListenerList get search();

  EventListenerList get select();

  EventListenerList get selectStart();

  EventListenerList get selectionChange();

  EventListenerList get submit();

  EventListenerList get touchCancel();

  EventListenerList get touchEnd();

  EventListenerList get touchMove();

  EventListenerList get touchStart();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DocumentFragment extends Element default _DocumentFragmentFactoryProvider {

  DocumentFragment();

  DocumentFragment.html(String html);

  // TODO(nweiz): enable this when XML is ported
  // /** WARNING: Currently this doesn't work on Dartium (issue 649). */
  // DocumentFragment.xml(String xml);

  DocumentFragment.svg(String svg);

  DocumentFragment clone(bool deep);


  ElementEvents get on();

  Element query(String selectors);

  NodeList $dom_querySelectorAll(String selectors);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DocumentType extends Node {

  final NamedNodeMap entities;

  final String internalSubset;

  final String name;

  final NamedNodeMap notations;

  final String publicId;

  final String systemId;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DynamicsCompressorNode extends AudioNode {

  final AudioParam knee;

  final AudioParam ratio;

  final AudioParam reduction;

  final AudioParam threshold;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EXTTextureFilterAnisotropic {

  static final int MAX_TEXTURE_MAX_ANISOTROPY_EXT = 0x84FF;

  static final int TEXTURE_MAX_ANISOTROPY_EXT = 0x84FE;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ElementList extends List<Element> {
  // TODO(jacobr): add element batch manipulation methods.
  ElementList filter(bool f(Element element));

  ElementList getRange(int start, int length);

  Element get first();
  // TODO(jacobr): add insertAt
}

/**
 * All your attribute manipulation needs in one place.
 * Extends the regular Map interface by automatically coercing non-string
 * values to strings.
 */
interface AttributeMap extends Map<String, String> {
  void operator []=(String key, value);
}

/**
 * All your element measurement needs in one place
 */
interface ElementRect {
  // Relative to offsetParent
  ClientRect get client();
  ClientRect get offset();
  ClientRect get scroll();
  // In global coords
  ClientRect get bounding();
  // In global coords
  List<ClientRect> get clientRects();
}

interface Element extends Node, NodeSelector default _ElementFactoryProvider {
// TODO(jacobr): switch back to:
// interface Element extends Node, NodeSelector, ElementTraversal default _ElementImpl {
  Element.html(String html);
  Element.tag(String tag);

  AttributeMap get attributes();
  void set attributes(Map<String, String> value);

  /**
   * @domName querySelectorAll, getElementsByClassName, getElementsByTagName,
   *   getElementsByTagNameNS
   */
  ElementList queryAll(String selectors);

  /**
   * @domName childElementCount, firstElementChild, lastElementChild,
   *   children, Node.nodes.add
   */
  ElementList get elements();

  void set elements(Collection<Element> value);

  /** @domName className, classList */
  Set<String> get classes();

  void set classes(Collection<String> value);

  AttributeMap get dataAttributes();
  void set dataAttributes(Map<String, String> value);

  /**
   * @domName getClientRects, getBoundingClientRect, clientHeight, clientWidth,
   * clientTop, clientLeft, offsetHeight, offsetWidth, offsetTop, offsetLeft,
   * scrollHeight, scrollWidth, scrollTop, scrollLeft
   */
  Future<ElementRect> get rect();

  /** @domName Window.getComputedStyle */
  Future<CSSStyleDeclaration> get computedStyle();

  /** @domName Window.getComputedStyle */
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement);

  Element clone(bool deep);

  Element get parent();


  ElementEvents get on();

  static final int ALLOW_KEYBOARD_INPUT = 1;

  final int $dom_childElementCount;

  final HTMLCollection $dom_children;

  String $dom_className;

  final int $dom_clientHeight;

  final int $dom_clientLeft;

  final int $dom_clientTop;

  final int $dom_clientWidth;

  String contentEditable;

  String dir;

  bool draggable;

  final Element $dom_firstElementChild;

  bool hidden;

  String id;

  String innerHTML;

  final bool isContentEditable;

  String lang;

  final Element $dom_lastElementChild;

  final Element nextElementSibling;

  final int $dom_offsetHeight;

  final int $dom_offsetLeft;

  final Element offsetParent;

  final int $dom_offsetTop;

  final int $dom_offsetWidth;

  final String outerHTML;

  final Element previousElementSibling;

  final int $dom_scrollHeight;

  int $dom_scrollLeft;

  int $dom_scrollTop;

  final int $dom_scrollWidth;

  bool spellcheck;

  final CSSStyleDeclaration style;

  int tabIndex;

  final String tagName;

  String title;

  bool translate;

  final String webkitRegionOverflow;

  String webkitdropzone;

  void blur();

  void click();

  void focus();

  String $dom_getAttribute(String name);

  ClientRect $dom_getBoundingClientRect();

  ClientRectList $dom_getClientRects();

  NodeList $dom_getElementsByClassName(String name);

  NodeList $dom_getElementsByTagName(String name);

  bool $dom_hasAttribute(String name);

  Element insertAdjacentElement(String where, Element element);

  void insertAdjacentHTML(String where, String html);

  void insertAdjacentText(String where, String text);

  Element query(String selectors);

  NodeList $dom_querySelectorAll(String selectors);

  void $dom_removeAttribute(String name);

  void scrollByLines(int lines);

  void scrollByPages(int pages);

  void scrollIntoView([bool centerIfNeeded]);

  void $dom_setAttribute(String name, String value);

  bool matchesSelector(String selectors);

  void webkitRequestFullScreen(int flags);

  void webkitRequestFullscreen();

}

interface ElementEvents extends Events {

  EventListenerList get abort();

  EventListenerList get beforeCopy();

  EventListenerList get beforeCut();

  EventListenerList get beforePaste();

  EventListenerList get blur();

  EventListenerList get change();

  EventListenerList get click();

  EventListenerList get contextMenu();

  EventListenerList get copy();

  EventListenerList get cut();

  EventListenerList get doubleClick();

  EventListenerList get drag();

  EventListenerList get dragEnd();

  EventListenerList get dragEnter();

  EventListenerList get dragLeave();

  EventListenerList get dragOver();

  EventListenerList get dragStart();

  EventListenerList get drop();

  EventListenerList get error();

  EventListenerList get focus();

  EventListenerList get fullscreenChange();

  EventListenerList get fullscreenError();

  EventListenerList get input();

  EventListenerList get invalid();

  EventListenerList get keyDown();

  EventListenerList get keyPress();

  EventListenerList get keyUp();

  EventListenerList get load();

  EventListenerList get mouseDown();

  EventListenerList get mouseMove();

  EventListenerList get mouseOut();

  EventListenerList get mouseOver();

  EventListenerList get mouseUp();

  EventListenerList get mouseWheel();

  EventListenerList get paste();

  EventListenerList get reset();

  EventListenerList get scroll();

  EventListenerList get search();

  EventListenerList get select();

  EventListenerList get selectStart();

  EventListenerList get submit();

  EventListenerList get touchCancel();

  EventListenerList get touchEnd();

  EventListenerList get touchLeave();

  EventListenerList get touchMove();

  EventListenerList get touchStart();

  EventListenerList get transitionEnd();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ElementTimeControl {

  void beginElement();

  void beginElementAt(num offset);

  void endElement();

  void endElementAt(num offset);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ElementTraversal {

  final int childElementCount;

  final Element firstElementChild;

  final Element lastElementChild;

  final Element nextElementSibling;

  final Element previousElementSibling;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EmbedElement extends Element {

  String align;

  String height;

  String name;

  String src;

  String type;

  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Entity extends Node {

  final String notationName;

  final String publicId;

  final String systemId;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EntityReference extends Node {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool EntriesCallback(EntryArray entries);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Entry {

  final DOMFileSystem filesystem;

  final String fullPath;

  final bool isDirectory;

  final bool isFile;

  final String name;

  void copyTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]);

  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback]);

  void getParent([EntryCallback successCallback, ErrorCallback errorCallback]);

  void moveTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]);

  void remove(VoidCallback successCallback, [ErrorCallback errorCallback]);

  String toURL();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EntryArray {

  final int length;

  Entry item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EntryArraySync {

  final int length;

  EntrySync item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool EntryCallback(Entry entry);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EntrySync {

  final DOMFileSystemSync filesystem;

  final String fullPath;

  final bool isDirectory;

  final bool isFile;

  final String name;

  EntrySync copyTo(DirectoryEntrySync parent, String name);

  Metadata getMetadata();

  DirectoryEntrySync getParent();

  EntrySync moveTo(DirectoryEntrySync parent, String name);

  void remove();

  String toURL();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool ErrorCallback(FileError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ErrorEvent extends Event {

  final String filename;

  final int lineno;

  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Event default _EventFactoryProvider {

  // In JS, canBubble and cancelable are technically required parameters to
  // init*Event. In practice, though, if they aren't provided they simply
  // default to false (since that's Boolean(undefined)).
  //
  // Contrary to JS, we default canBubble and cancelable to true, since that's
  // what people want most of the time anyway.
  Event(String type, [bool canBubble, bool cancelable]);

  static final int AT_TARGET = 2;

  static final int BLUR = 8192;

  static final int BUBBLING_PHASE = 3;

  static final int CAPTURING_PHASE = 1;

  static final int CHANGE = 32768;

  static final int CLICK = 64;

  static final int DBLCLICK = 128;

  static final int DRAGDROP = 2048;

  static final int FOCUS = 4096;

  static final int KEYDOWN = 256;

  static final int KEYPRESS = 1024;

  static final int KEYUP = 512;

  static final int MOUSEDOWN = 1;

  static final int MOUSEDRAG = 32;

  static final int MOUSEMOVE = 16;

  static final int MOUSEOUT = 8;

  static final int MOUSEOVER = 4;

  static final int MOUSEUP = 2;

  static final int SELECT = 16384;

  final bool bubbles;

  bool cancelBubble;

  final bool cancelable;

  final Clipboard clipboardData;

  final EventTarget currentTarget;

  final bool defaultPrevented;

  final int eventPhase;

  bool returnValue;

  final EventTarget srcElement;

  final EventTarget target;

  final int timeStamp;

  final String type;

  void $dom_initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg);

  void preventDefault();

  void stopImmediatePropagation();

  void stopPropagation();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EventException {

  static final int DISPATCH_REQUEST_ERR = 1;

  static final int UNSPECIFIED_EVENT_TYPE_ERR = 0;

  final int code;

  final String message;

  final String name;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EventSource extends EventTarget default _EventSourceFactoryProvider {

  EventSource(String scriptUrl);

  EventSourceEvents get on();

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  final String URL;

  final int readyState;

  final String url;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]);

  void close();

  bool $dom_dispatchEvent(Event evt);

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]);
}

interface EventSourceEvents extends Events {

  EventListenerList get error();

  EventListenerList get message();

  EventListenerList get open();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EventListenerList {
  EventListenerList add(EventListener handler, [bool useCapture]);

  EventListenerList remove(EventListener handler, [bool useCapture]);

  bool dispatch(Event evt);
}

interface Events {
  EventListenerList operator [](String type);
}

interface EventTarget {

  final Events on;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]);

  bool $dom_dispatchEvent(Event event);

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FieldSetElement extends Element {

  final FormElement form;

  String name;

  final String type;

  final String validationMessage;

  final ValidityState validity;

  final bool willValidate;

  bool checkValidity();

  void setCustomValidity(String error);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface File extends Blob {

  final Date lastModifiedDate;

  final String name;

  final String webkitRelativePath;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool FileCallback(File file);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileEntry extends Entry {

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback]);

  void file(FileCallback successCallback, [ErrorCallback errorCallback]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileEntrySync extends EntrySync {

  FileWriterSync createWriter();

  File file();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileError {

  static final int ABORT_ERR = 3;

  static final int ENCODING_ERR = 5;

  static final int INVALID_MODIFICATION_ERR = 9;

  static final int INVALID_STATE_ERR = 7;

  static final int NOT_FOUND_ERR = 1;

  static final int NOT_READABLE_ERR = 4;

  static final int NO_MODIFICATION_ALLOWED_ERR = 6;

  static final int PATH_EXISTS_ERR = 12;

  static final int QUOTA_EXCEEDED_ERR = 10;

  static final int SECURITY_ERR = 2;

  static final int SYNTAX_ERR = 8;

  static final int TYPE_MISMATCH_ERR = 11;

  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileException {

  static final int ABORT_ERR = 3;

  static final int ENCODING_ERR = 5;

  static final int INVALID_MODIFICATION_ERR = 9;

  static final int INVALID_STATE_ERR = 7;

  static final int NOT_FOUND_ERR = 1;

  static final int NOT_READABLE_ERR = 4;

  static final int NO_MODIFICATION_ALLOWED_ERR = 6;

  static final int PATH_EXISTS_ERR = 12;

  static final int QUOTA_EXCEEDED_ERR = 10;

  static final int SECURITY_ERR = 2;

  static final int SYNTAX_ERR = 8;

  static final int TYPE_MISMATCH_ERR = 11;

  final int code;

  final String message;

  final String name;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileList {

  final int length;

  File item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileReader default _FileReaderFactoryProvider {

  FileReader();

  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  final FileError error;

  EventListener onabort;

  EventListener onerror;

  EventListener onload;

  EventListener onloadend;

  EventListener onloadstart;

  EventListener onprogress;

  final int readyState;

  final Object result;

  void abort();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void readAsArrayBuffer(Blob blob);

  void readAsBinaryString(Blob blob);

  void readAsDataURL(Blob blob);

  void readAsText(Blob blob, [String encoding]);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileReaderSync default _FileReaderSyncFactoryProvider {

  FileReaderSync();

  ArrayBuffer readAsArrayBuffer(Blob blob);

  String readAsBinaryString(Blob blob);

  String readAsDataURL(Blob blob);

  String readAsText(Blob blob, [String encoding]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool FileSystemCallback(DOMFileSystem fileSystem);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileWriter {

  static final int DONE = 2;

  static final int INIT = 0;

  static final int WRITING = 1;

  final FileError error;

  final int length;

  EventListener onabort;

  EventListener onerror;

  EventListener onprogress;

  EventListener onwrite;

  EventListener onwriteend;

  EventListener onwritestart;

  final int position;

  final int readyState;

  void abort();

  void seek(int position);

  void truncate(int size);

  void write(Blob data);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool FileWriterCallback(FileWriter fileWriter);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileWriterSync {

  final int length;

  final int position;

  void seek(int position);

  void truncate(int size);

  void write(Blob data);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Float32Array extends ArrayBufferView, List<num> default _TypedArrayFactoryProvider {

  Float32Array(int length);

  Float32Array.fromList(List<num> list);

  Float32Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 4;

  final int length;

  void setElements(Object array, [int offset]);

  Float32Array subarray(int start, [int end]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Float64Array extends ArrayBufferView, List<num> default _TypedArrayFactoryProvider {

  Float64Array(int length);

  Float64Array.fromList(List<num> list);

  Float64Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 8;

  final int length;

  void setElements(Object array, [int offset]);

  Float64Array subarray(int start, [int end]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FontElement extends Element {

  String color;

  String face;

  String size;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FormElement extends Element {

  String acceptCharset;

  String action;

  String autocomplete;

  String encoding;

  String enctype;

  final int length;

  String method;

  String name;

  bool noValidate;

  String target;

  bool checkValidity();

  void reset();

  void submit();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FrameElement extends Element {

  final Document contentDocument;

  final Window contentWindow;

  String frameBorder;

  final int height;

  String location;

  String longDesc;

  String marginHeight;

  String marginWidth;

  String name;

  bool noResize;

  String scrolling;

  String src;

  final int width;

  SVGDocument getSVGDocument();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FrameSetElement extends Element {

  FrameSetElementEvents get on();

  String cols;

  String rows;
}

interface FrameSetElementEvents extends ElementEvents {

  EventListenerList get beforeUnload();

  EventListenerList get blur();

  EventListenerList get error();

  EventListenerList get focus();

  EventListenerList get hashChange();

  EventListenerList get load();

  EventListenerList get message();

  EventListenerList get offline();

  EventListenerList get online();

  EventListenerList get popState();

  EventListenerList get resize();

  EventListenerList get storage();

  EventListenerList get unload();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Geolocation {

  void clearWatch(int watchId);

  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback]);

  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Geoposition {

  final Coordinates coords;

  final int timestamp;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HRElement extends Element {

  String align;

  bool noShade;

  String size;

  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLAllCollection {

  final int length;

  Node item(int index);

  Node namedItem(String name);

  NodeList tags(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLCollection extends List<Node> {

  final int length;

  Node item(int index);

  Node namedItem(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLOptionsCollection extends HTMLCollection {

  int length;

  int selectedIndex;

  void remove(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HashChangeEvent extends Event {

  final String newURL;

  final String oldURL;

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HeadElement extends Element {

  String profile;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HeadingElement extends Element {

  String align;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HighPass2FilterNode extends AudioNode {

  final AudioParam cutoff;

  final AudioParam resonance;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface History {

  final int length;

  final Dynamic state;

  void back();

  void forward();

  void go(int distance);

  void pushState(Object data, String title, [String url]);

  void replaceState(Object data, String title, [String url]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HtmlElement extends Element {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBAny {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBCursor {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

  final int direction;

  final IDBKey key;

  final IDBKey primaryKey;

  final IDBAny source;

  void continueFunction([IDBKey key]);

  IDBRequest delete();

  IDBRequest update(Dynamic value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBCursorWithValue extends IDBCursor {

  final IDBAny value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBDatabase {

  final String name;

  final List<String> objectStoreNames;

  EventListener onabort;

  EventListener onerror;

  EventListener onversionchange;

  final String version;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void close();

  IDBObjectStore createObjectStore(String name);

  void deleteObjectStore(String name);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  IDBVersionChangeRequest setVersion(String version);

  IDBTransaction transaction(var storeName_OR_storeNames, [int mode]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBDatabaseError {

  int code;

  String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBDatabaseException {

  static final int ABORT_ERR = 8;

  static final int CONSTRAINT_ERR = 4;

  static final int DATA_ERR = 5;

  static final int NON_TRANSIENT_ERR = 2;

  static final int NOT_ALLOWED_ERR = 6;

  static final int NOT_FOUND_ERR = 3;

  static final int NO_ERR = 0;

  static final int QUOTA_ERR = 11;

  static final int READ_ONLY_ERR = 9;

  static final int TIMEOUT_ERR = 10;

  static final int TRANSACTION_INACTIVE_ERR = 7;

  static final int UNKNOWN_ERR = 1;

  static final int VER_ERR = 12;

  final int code;

  final String message;

  final String name;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBFactory {

  int cmp(IDBKey first, IDBKey second);

  IDBVersionChangeRequest deleteDatabase(String name);

  IDBRequest getDatabaseNames();

  IDBRequest open(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBIndex {

  final String keyPath;

  final bool multiEntry;

  final String name;

  final IDBObjectStore objectStore;

  final bool unique;

  IDBRequest count([var key_OR_range]);

  IDBRequest getObject(IDBKey key);

  IDBRequest getKey(IDBKey key);

  IDBRequest openCursor([IDBKeyRange range, int direction]);

  IDBRequest openKeyCursor([IDBKeyRange range, int direction]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBKey {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBKeyRange {

  final IDBKey lower;

  final bool lowerOpen;

  final IDBKey upper;

  final bool upperOpen;

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen, bool upperOpen]);

  IDBKeyRange lowerBound(IDBKey bound, [bool open]);

  IDBKeyRange only(IDBKey value);

  IDBKeyRange upperBound(IDBKey bound, [bool open]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBObjectStore {

  final List<String> indexNames;

  final String keyPath;

  final String name;

  final IDBTransaction transaction;

  IDBRequest add(Dynamic value, [IDBKey key]);

  IDBRequest clear();

  IDBRequest count([var key_OR_range]);

  IDBIndex createIndex(String name, String keyPath);

  IDBRequest delete(var key_OR_keyRange);

  void deleteIndex(String name);

  IDBRequest getObject(IDBKey key);

  IDBIndex index(String name);

  IDBRequest openCursor([IDBKeyRange range, int direction]);

  IDBRequest put(Dynamic value, [IDBKey key]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBRequest {

  static final int DONE = 2;

  static final int LOADING = 1;

  final int errorCode;

  EventListener onerror;

  EventListener onsuccess;

  final int readyState;

  final IDBAny result;

  final IDBAny source;

  final IDBTransaction transaction;

  final String webkitErrorMessage;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBTransaction {

  static final int READ_ONLY = 0;

  static final int READ_WRITE = 1;

  static final int VERSION_CHANGE = 2;

  final IDBDatabase db;

  final int mode;

  EventListener onabort;

  EventListener oncomplete;

  EventListener onerror;

  void abort();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  IDBObjectStore objectStore(String name);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBVersionChangeEvent extends Event {

  final String version;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBVersionChangeRequest extends IDBRequest {

  EventListener onblocked;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IFrameElement extends Element {

  String align;

  final Document contentDocument;

  final Window contentWindow;

  String frameBorder;

  String height;

  String longDesc;

  String marginHeight;

  String marginWidth;

  String name;

  String sandbox;

  String scrolling;

  String src;

  String width;

  SVGDocument getSVGDocument();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool IceCallback(IceCandidate candidate, bool moreToFollow, PeerConnection00 source);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IceCandidate default _IceCandidateFactoryProvider {

  IceCandidate(String label, String candidateLine);

  final String label;

  String toSdp();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ImageData {

  final CanvasPixelArray data;

  final int height;

  final int width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ImageElement extends Element {

  String align;

  String alt;

  String border;

  final bool complete;

  String crossOrigin;

  int height;

  int hspace;

  bool isMap;

  String longDesc;

  String lowsrc;

  String name;

  final int naturalHeight;

  final int naturalWidth;

  String src;

  String useMap;

  int vspace;

  int width;

  final int x;

  final int y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface InputElement extends Element {

  InputElementEvents get on();

  String accept;

  String align;

  String alt;

  String autocomplete;

  bool autofocus;

  bool checked;

  bool defaultChecked;

  String defaultValue;

  bool disabled;

  final FileList files;

  final FormElement form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  bool incremental;

  bool indeterminate;

  final NodeList labels;

  String max;

  int maxLength;

  String min;

  bool multiple;

  String name;

  String pattern;

  String placeholder;

  bool readOnly;

  bool required;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  int size;

  String src;

  String step;

  String type;

  String useMap;

  final String validationMessage;

  final ValidityState validity;

  String value;

  Date valueAsDate;

  num valueAsNumber;

  bool webkitGrammar;

  bool webkitSpeech;

  bool webkitdirectory;

  final bool willValidate;

  bool checkValidity();

  void select();

  void setCustomValidity(String error);

  void setSelectionRange(int start, int end, [String direction]);

  void stepDown([int n]);

  void stepUp([int n]);
}

interface InputElementEvents extends ElementEvents {

  EventListenerList get speechChange();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int16Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Int16Array(int length);

  Int16Array.fromList(List<int> list);

  Int16Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 2;

  final int length;

  void setElements(Object array, [int offset]);

  Int16Array subarray(int start, [int end]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int32Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Int32Array(int length);

  Int32Array.fromList(List<int> list);

  Int32Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 4;

  final int length;

  void setElements(Object array, [int offset]);

  Int32Array subarray(int start, [int end]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int8Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Int8Array(int length);

  Int8Array.fromList(List<int> list);

  Int8Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 1;

  final int length;

  void setElements(Object array, [int offset]);

  Int8Array subarray(int start, [int end]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface JavaScriptAudioNode extends AudioNode {

  final int bufferSize;

  EventListener onaudioprocess;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface JavaScriptCallFrame {

  static final int CATCH_SCOPE = 4;

  static final int CLOSURE_SCOPE = 3;

  static final int GLOBAL_SCOPE = 0;

  static final int LOCAL_SCOPE = 1;

  static final int WITH_SCOPE = 2;

  final JavaScriptCallFrame caller;

  final int column;

  final String functionName;

  final int line;

  final List scopeChain;

  final int sourceID;

  final Object thisObject;

  final String type;

  void evaluate(String script);

  int scopeType(int scopeIndex);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface KeyboardEvent extends UIEvent {

  final bool altGraphKey;

  final bool altKey;

  final bool ctrlKey;

  final String keyIdentifier;

  final int keyLocation;

  final bool metaKey;

  final bool shiftKey;

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, Window view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface KeygenElement extends Element {

  bool autofocus;

  String challenge;

  bool disabled;

  final FormElement form;

  String keytype;

  final NodeList labels;

  String name;

  final String type;

  final String validationMessage;

  final ValidityState validity;

  final bool willValidate;

  bool checkValidity();

  void setCustomValidity(String error);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LIElement extends Element {

  String type;

  int value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LabelElement extends Element {

  final Element control;

  final FormElement form;

  String htmlFor;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LegendElement extends Element {

  String align;

  final FormElement form;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LinkElement extends Element {

  String charset;

  bool disabled;

  String href;

  String hreflang;

  String media;

  String rel;

  String rev;

  final StyleSheet sheet;

  DOMSettableTokenList sizes;

  String target;

  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LocalMediaStream extends MediaStream {

  void stop();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Location {

  String hash;

  String host;

  String hostname;

  String href;

  final String origin;

  String pathname;

  String port;

  String protocol;

  String search;

  void assign(String url);

  void reload();

  void replace(String url);

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LowPass2FilterNode extends AudioNode {

  final AudioParam cutoff;

  final AudioParam resonance;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MapElement extends Element {

  final HTMLCollection areas;

  String name;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MarqueeElement extends Element {

  String behavior;

  String bgColor;

  String direction;

  String height;

  int hspace;

  int loop;

  int scrollAmount;

  int scrollDelay;

  bool trueSpeed;

  int vspace;

  String width;

  void start();

  void stop();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaController default _MediaControllerFactoryProvider {

  MediaController();

  final TimeRanges buffered;

  num currentTime;

  num defaultPlaybackRate;

  final num duration;

  bool muted;

  final bool paused;

  num playbackRate;

  final TimeRanges played;

  final TimeRanges seekable;

  num volume;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void pause();

  void play();

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaElement extends Element {

  static final int EOS_DECODE_ERR = 2;

  static final int EOS_NETWORK_ERR = 1;

  static final int EOS_NO_ERROR = 0;

  static final int HAVE_CURRENT_DATA = 2;

  static final int HAVE_ENOUGH_DATA = 4;

  static final int HAVE_FUTURE_DATA = 3;

  static final int HAVE_METADATA = 1;

  static final int HAVE_NOTHING = 0;

  static final int NETWORK_EMPTY = 0;

  static final int NETWORK_IDLE = 1;

  static final int NETWORK_LOADING = 2;

  static final int NETWORK_NO_SOURCE = 3;

  static final int SOURCE_CLOSED = 0;

  static final int SOURCE_ENDED = 2;

  static final int SOURCE_OPEN = 1;

  bool autoplay;

  final TimeRanges buffered;

  MediaController controller;

  bool controls;

  final String currentSrc;

  num currentTime;

  bool defaultMuted;

  num defaultPlaybackRate;

  final num duration;

  final bool ended;

  final MediaError error;

  final num initialTime;

  bool loop;

  String mediaGroup;

  bool muted;

  final int networkState;

  final bool paused;

  num playbackRate;

  final TimeRanges played;

  String preload;

  final int readyState;

  final TimeRanges seekable;

  final bool seeking;

  String src;

  final num startTime;

  final TextTrackList textTracks;

  num volume;

  final int webkitAudioDecodedByteCount;

  bool webkitClosedCaptionsVisible;

  final bool webkitHasClosedCaptions;

  final String webkitMediaSourceURL;

  bool webkitPreservesPitch;

  final int webkitSourceState;

  final int webkitVideoDecodedByteCount;

  TextTrack addTextTrack(String kind, [String label, String language]);

  String canPlayType(String type);

  void load();

  void pause();

  void play();

  void webkitSourceAppend(Uint8Array data);

  void webkitSourceEndOfStream(int status);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaElementAudioSourceNode extends AudioSourceNode {

  final MediaElement mediaElement;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaError {

  static final int MEDIA_ERR_ABORTED = 1;

  static final int MEDIA_ERR_DECODE = 3;

  static final int MEDIA_ERR_NETWORK = 2;

  static final int MEDIA_ERR_SRC_NOT_SUPPORTED = 4;

  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaList extends List<String> {

  final int length;

  String mediaText;

  void appendMedium(String newMedium);

  void deleteMedium(String oldMedium);

  String item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaQueryList {

  final bool matches;

  final String media;

  void addListener(MediaQueryListListener listener);

  void removeListener(MediaQueryListListener listener);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaQueryListListener {

  void queryChanged(MediaQueryList list);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaStream default _MediaStreamFactoryProvider {

  MediaStream(MediaStreamTrackList audioTracks, MediaStreamTrackList videoTracks);

  static final int ENDED = 2;

  static final int LIVE = 1;

  final MediaStreamTrackList audioTracks;

  final String label;

  EventListener onended;

  final int readyState;

  final MediaStreamTrackList videoTracks;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event event);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaStreamEvent extends Event {

  final MediaStream stream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaStreamList {

  final int length;

  MediaStream item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaStreamTrack {

  bool enabled;

  final String kind;

  final String label;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaStreamTrackList {

  final int length;

  MediaStreamTrack item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MemoryInfo {

  final int jsHeapSizeLimit;

  final int totalJSHeapSize;

  final int usedJSHeapSize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MenuElement extends Element {

  bool compact;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MessageChannel default _MessageChannelFactoryProvider {

  MessageChannel();

  final MessagePort port1;

  final MessagePort port2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MessageEvent extends Event {

  final Object data;

  final String lastEventId;

  final String origin;

  final List ports;

  final Window source;

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, Window sourceArg, List messagePorts);

  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, Window sourceArg, List transferables);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MessagePort extends EventTarget {

  MessagePortEvents get on();

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]);

  void close();

  bool $dom_dispatchEvent(Event evt);

  void postMessage(String message, [List messagePorts]);

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]);

  void start();

  void webkitPostMessage(String message, [List transfer]);
}

interface MessagePortEvents extends Events {

  EventListenerList get message();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MetaElement extends Element {

  String content;

  String httpEquiv;

  String name;

  String scheme;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Metadata {

  final Date modificationTime;

  final int size;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool MetadataCallback(Metadata metadata);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MeterElement extends Element {

  num high;

  final NodeList labels;

  num low;

  num max;

  num min;

  num optimum;

  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ModElement extends Element {

  String cite;

  String dateTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MouseEvent extends UIEvent default _MouseEventFactoryProvider {

  MouseEvent(String type, Window view, int detail, int screenX, int screenY,
      int clientX, int clientY, int button, [bool canBubble, bool cancelable,
      bool ctrlKey, bool altKey, bool shiftKey, bool metaKey,
      EventTarget relatedTarget]);


  final bool altKey;

  final int button;

  final int clientX;

  final int clientY;

  final bool ctrlKey;

  final Clipboard dataTransfer;

  final Node fromElement;

  final bool metaKey;

  final int offsetX;

  final int offsetY;

  final EventTarget relatedTarget;

  final int screenX;

  final int screenY;

  final bool shiftKey;

  final Node toElement;

  final int x;

  final int y;

  void $dom_initMouseEvent(String type, bool canBubble, bool cancelable, Window view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MutationEvent extends Event {

  static final int ADDITION = 2;

  static final int MODIFICATION = 1;

  static final int REMOVAL = 3;

  final int attrChange;

  final String attrName;

  final String newValue;

  final String prevValue;

  final Node relatedNode;

  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NamedNodeMap extends List<Node> {

  final int length;

  Node getNamedItem(String name);

  Node getNamedItemNS(String namespaceURI, String localName);

  Node item(int index);

  Node removeNamedItem(String name);

  Node removeNamedItemNS(String namespaceURI, String localName);

  Node setNamedItem(Node node);

  Node setNamedItemNS(Node node);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Navigator {

  final String appCodeName;

  final String appName;

  final String appVersion;

  final bool cookieEnabled;

  final Geolocation geolocation;

  final String language;

  final DOMMimeTypeArray mimeTypes;

  final bool onLine;

  final String platform;

  final DOMPluginArray plugins;

  final String product;

  final String productSub;

  final String userAgent;

  final String vendor;

  final String vendorSub;

  void getStorageUpdates();

  bool javaEnabled();

  void registerProtocolHandler(String scheme, String url, String title);

  void webkitGetUserMedia(String options, NavigatorUserMediaSuccessCallback successCallback, [NavigatorUserMediaErrorCallback errorCallback]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NavigatorUserMediaError {

  static final int PERMISSION_DENIED = 1;

  final int code;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool NavigatorUserMediaErrorCallback(NavigatorUserMediaError error);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool NavigatorUserMediaSuccessCallback(LocalMediaStream stream);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Node extends EventTarget {
  NodeList get nodes();

  void set nodes(Collection<Node> value);

  Node replaceWith(Node otherNode);

  Node remove();


  static final int ATTRIBUTE_NODE = 2;

  static final int CDATA_SECTION_NODE = 4;

  static final int COMMENT_NODE = 8;

  static final int DOCUMENT_FRAGMENT_NODE = 11;

  static final int DOCUMENT_NODE = 9;

  static final int DOCUMENT_POSITION_CONTAINED_BY = 0x10;

  static final int DOCUMENT_POSITION_CONTAINS = 0x08;

  static final int DOCUMENT_POSITION_DISCONNECTED = 0x01;

  static final int DOCUMENT_POSITION_FOLLOWING = 0x04;

  static final int DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20;

  static final int DOCUMENT_POSITION_PRECEDING = 0x02;

  static final int DOCUMENT_TYPE_NODE = 10;

  static final int ELEMENT_NODE = 1;

  static final int ENTITY_NODE = 6;

  static final int ENTITY_REFERENCE_NODE = 5;

  static final int NOTATION_NODE = 12;

  static final int PROCESSING_INSTRUCTION_NODE = 7;

  static final int TEXT_NODE = 3;

  final NamedNodeMap $dom_attributes;

  final NodeList $dom_childNodes;

  final Node $dom_firstChild;

  final Node $dom_lastChild;

  final Node nextNode;

  final int $dom_nodeType;

  final Document document;

  final Node parent;

  final Node previousNode;

  String text;

  Node $dom_appendChild(Node newChild);

  Node clone(bool deep);

  bool contains(Node other);

  bool hasChildNodes();

  Node insertBefore(Node newChild, Node refChild);

  Node $dom_removeChild(Node oldChild);

  Node $dom_replaceChild(Node newChild, Node oldChild);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NodeFilter {

  static final int FILTER_ACCEPT = 1;

  static final int FILTER_REJECT = 2;

  static final int FILTER_SKIP = 3;

  static final int SHOW_ALL = 0xFFFFFFFF;

  static final int SHOW_ATTRIBUTE = 0x00000002;

  static final int SHOW_CDATA_SECTION = 0x00000008;

  static final int SHOW_COMMENT = 0x00000080;

  static final int SHOW_DOCUMENT = 0x00000100;

  static final int SHOW_DOCUMENT_FRAGMENT = 0x00000400;

  static final int SHOW_DOCUMENT_TYPE = 0x00000200;

  static final int SHOW_ELEMENT = 0x00000001;

  static final int SHOW_ENTITY = 0x00000020;

  static final int SHOW_ENTITY_REFERENCE = 0x00000010;

  static final int SHOW_NOTATION = 0x00000800;

  static final int SHOW_PROCESSING_INSTRUCTION = 0x00000040;

  static final int SHOW_TEXT = 0x00000004;

  int acceptNode(Node n);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NodeIterator {

  final bool expandEntityReferences;

  final NodeFilter filter;

  final bool pointerBeforeReferenceNode;

  final Node referenceNode;

  final Node root;

  final int whatToShow;

  void detach();

  Node nextNode();

  Node previousNode();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NodeList extends List<Node> {

  NodeList filter(bool f(Node element));

  NodeList getRange(int start, int length);

  Node get first();


  final int length;

}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NodeSelector {

  // TODO(nweiz): add this back once DocumentFragment is ported.
  // ElementList queryAll(String selectors);


  Element query(String selectors);

  NodeList $dom_querySelectorAll(String selectors);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Notation extends Node {

  final String publicId;

  final String systemId;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Notification extends EventTarget {

  NotificationEvents get on();

  String dir;

  String replaceId;

  void cancel();

  void show();
}

interface NotificationEvents extends Events {

  EventListenerList get click();

  EventListenerList get close();

  EventListenerList get error();

  EventListenerList get show();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NotificationCenter {

  int checkPermission();

  Notification createHTMLNotification(String url);

  Notification createNotification(String iconUrl, String title, String body);

  void requestPermission(VoidCallback callback);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OESStandardDerivatives {

  static final int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OESTextureFloat {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OESVertexArrayObject {

  static final int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject);

  WebGLVertexArrayObjectOES createVertexArrayOES();

  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject);

  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OListElement extends Element {

  bool compact;

  bool reversed;

  int start;

  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ObjectElement extends Element {

  String align;

  String archive;

  String border;

  String code;

  String codeBase;

  String codeType;

  final Document contentDocument;

  String data;

  bool declare;

  final FormElement form;

  String height;

  int hspace;

  String name;

  String standby;

  String type;

  String useMap;

  final String validationMessage;

  final ValidityState validity;

  int vspace;

  String width;

  final bool willValidate;

  bool checkValidity();

  void setCustomValidity(String error);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OfflineAudioCompletionEvent extends Event {

  final AudioBuffer renderedBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OperationNotAllowedException {

  static final int NOT_ALLOWED_ERR = 1;

  final int code;

  final String message;

  final String name;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OptGroupElement extends Element {

  bool disabled;

  String label;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OptionElement extends Element default _OptionElementFactoryProvider {

  OptionElement([String data, String value, bool defaultSelected, bool selected]);

  bool defaultSelected;

  bool disabled;

  final FormElement form;

  final int index;

  String label;

  bool selected;

  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OutputElement extends Element {

  String defaultValue;

  final FormElement form;

  DOMSettableTokenList htmlFor;

  final NodeList labels;

  String name;

  final String type;

  final String validationMessage;

  final ValidityState validity;

  String value;

  final bool willValidate;

  bool checkValidity();

  void setCustomValidity(String error);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OverflowEvent extends Event {

  static final int BOTH = 2;

  static final int HORIZONTAL = 0;

  static final int VERTICAL = 1;

  final bool horizontalOverflow;

  final int orient;

  final bool verticalOverflow;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PageTransitionEvent extends Event {

  final bool persisted;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ParagraphElement extends Element {

  String align;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ParamElement extends Element {

  String name;

  String type;

  String value;

  String valueType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PeerConnection00 default _PeerConnection00FactoryProvider {

  PeerConnection00(String serverConfiguration, IceCallback iceCallback);

  static final int ACTIVE = 2;

  static final int CLOSED = 3;

  static final int ICE_CHECKING = 0x300;

  static final int ICE_CLOSED = 0x700;

  static final int ICE_COMPLETED = 0x500;

  static final int ICE_CONNECTED = 0x400;

  static final int ICE_FAILED = 0x600;

  static final int ICE_GATHERING = 0x100;

  static final int ICE_WAITING = 0x200;

  static final int NEGOTIATING = 1;

  static final int NEW = 0;

  static final int SDP_ANSWER = 0x300;

  static final int SDP_OFFER = 0x100;

  static final int SDP_PRANSWER = 0x200;

  final int iceState;

  final SessionDescription localDescription;

  final MediaStreamList localStreams;

  EventListener onaddstream;

  EventListener onconnecting;

  EventListener onopen;

  EventListener onremovestream;

  EventListener onstatechange;

  final int readyState;

  final SessionDescription remoteDescription;

  final MediaStreamList remoteStreams;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void addStream(MediaStream stream, [String mediaStreamHints]);

  void close();

  SessionDescription createAnswer(String offer, [String mediaHints]);

  SessionDescription createOffer([String mediaHints]);

  bool dispatchEvent(Event event);

  void processIceMessage(IceCandidate candidate);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  void removeStream(MediaStream stream);

  void setLocalDescription(int action, SessionDescription desc);

  void setRemoteDescription(int action, SessionDescription desc);

  void startIce([String iceOptions]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Performance {

  final MemoryInfo memory;

  final PerformanceNavigation navigation;

  final PerformanceTiming timing;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PerformanceNavigation {

  static final int TYPE_BACK_FORWARD = 2;

  static final int TYPE_NAVIGATE = 0;

  static final int TYPE_RELOAD = 1;

  static final int TYPE_RESERVED = 255;

  final int redirectCount;

  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PerformanceTiming {

  final int connectEnd;

  final int connectStart;

  final int domComplete;

  final int domContentLoadedEventEnd;

  final int domContentLoadedEventStart;

  final int domInteractive;

  final int domLoading;

  final int domainLookupEnd;

  final int domainLookupStart;

  final int fetchStart;

  final int loadEventEnd;

  final int loadEventStart;

  final int navigationStart;

  final int redirectEnd;

  final int redirectStart;

  final int requestStart;

  final int responseEnd;

  final int responseStart;

  final int secureConnectionStart;

  final int unloadEventEnd;

  final int unloadEventStart;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Point default _PointFactoryProvider {

  Point(num x, num y);

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PopStateEvent extends Event {

  final Object state;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool PositionCallback(Geoposition position);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PositionError {

  static final int PERMISSION_DENIED = 1;

  static final int POSITION_UNAVAILABLE = 2;

  static final int TIMEOUT = 3;

  final int code;

  final String message;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool PositionErrorCallback(PositionError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PreElement extends Element {

  int width;

  bool wrap;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ProcessingInstruction extends Node {

  String data;

  final StyleSheet sheet;

  final String target;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ProgressElement extends Element {

  final NodeList labels;

  num max;

  final num position;

  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ProgressEvent extends Event {

  final bool lengthComputable;

  final int loaded;

  final int total;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface QuoteElement extends Element {

  String cite;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface RGBColor {

  final CSSPrimitiveValue blue;

  final CSSPrimitiveValue green;

  final CSSPrimitiveValue red;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Range {

  static final int END_TO_END = 2;

  static final int END_TO_START = 3;

  static final int NODE_AFTER = 1;

  static final int NODE_BEFORE = 0;

  static final int NODE_BEFORE_AND_AFTER = 2;

  static final int NODE_INSIDE = 3;

  static final int START_TO_END = 1;

  static final int START_TO_START = 0;

  final bool collapsed;

  final Node commonAncestorContainer;

  final Node endContainer;

  final int endOffset;

  final Node startContainer;

  final int startOffset;

  DocumentFragment cloneContents();

  Range cloneRange();

  void collapse(bool toStart);

  int compareNode(Node refNode);

  int comparePoint(Node refNode, int offset);

  DocumentFragment createContextualFragment(String html);

  void deleteContents();

  void detach();

  void expand(String unit);

  DocumentFragment extractContents();

  ClientRect getBoundingClientRect();

  ClientRectList getClientRects();

  void insertNode(Node newNode);

  bool intersectsNode(Node refNode);

  bool isPointInRange(Node refNode, int offset);

  void selectNode(Node refNode);

  void selectNodeContents(Node refNode);

  void setEnd(Node refNode, int offset);

  void setEndAfter(Node refNode);

  void setEndBefore(Node refNode);

  void setStart(Node refNode, int offset);

  void setStartAfter(Node refNode);

  void setStartBefore(Node refNode);

  void surroundContents(Node newParent);

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface RangeException {

  static final int BAD_BOUNDARYPOINTS_ERR = 1;

  static final int INVALID_NODE_TYPE_ERR = 2;

  final int code;

  final String message;

  final String name;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface RealtimeAnalyserNode extends AudioNode {

  int fftSize;

  final int frequencyBinCount;

  num maxDecibels;

  num minDecibels;

  num smoothingTimeConstant;

  void getByteFrequencyData(Uint8Array array);

  void getByteTimeDomainData(Uint8Array array);

  void getFloatFrequencyData(Float32Array array);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Rect {

  final CSSPrimitiveValue bottom;

  final CSSPrimitiveValue left;

  final CSSPrimitiveValue right;

  final CSSPrimitiveValue top;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool RequestAnimationFrameCallback(int time);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SQLError {

  static final int CONSTRAINT_ERR = 6;

  static final int DATABASE_ERR = 1;

  static final int QUOTA_ERR = 4;

  static final int SYNTAX_ERR = 5;

  static final int TIMEOUT_ERR = 7;

  static final int TOO_LARGE_ERR = 3;

  static final int UNKNOWN_ERR = 0;

  static final int VERSION_ERR = 2;

  final int code;

  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SQLException {

  static final int CONSTRAINT_ERR = 6;

  static final int DATABASE_ERR = 1;

  static final int QUOTA_ERR = 4;

  static final int SYNTAX_ERR = 5;

  static final int TIMEOUT_ERR = 7;

  static final int TOO_LARGE_ERR = 3;

  static final int UNKNOWN_ERR = 0;

  static final int VERSION_ERR = 2;

  final int code;

  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SQLResultSet {

  final int insertId;

  final SQLResultSetRowList rows;

  final int rowsAffected;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SQLResultSetRowList {

  final int length;

  Object item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool SQLStatementCallback(SQLTransaction transaction, SQLResultSet resultSet);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool SQLStatementErrorCallback(SQLTransaction transaction, SQLError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SQLTransaction {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool SQLTransactionCallback(SQLTransaction transaction);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool SQLTransactionErrorCallback(SQLError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SQLTransactionSync {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool SQLTransactionSyncCallback(SQLTransactionSync transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAElement extends SVGElement, SVGURIReference, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGAnimatedString target;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAltGlyphDefElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAltGlyphElement extends SVGTextPositioningElement, SVGURIReference {

  String format;

  String glyphRef;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAltGlyphItemElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAngle {

  static final int SVG_ANGLETYPE_DEG = 2;

  static final int SVG_ANGLETYPE_GRAD = 4;

  static final int SVG_ANGLETYPE_RAD = 3;

  static final int SVG_ANGLETYPE_UNKNOWN = 0;

  static final int SVG_ANGLETYPE_UNSPECIFIED = 1;

  final int unitType;

  num value;

  String valueAsString;

  num valueInSpecifiedUnits;

  void convertToSpecifiedUnits(int unitType);

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimateColorElement extends SVGAnimationElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimateElement extends SVGAnimationElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimateMotionElement extends SVGAnimationElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimateTransformElement extends SVGAnimationElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedAngle {

  final SVGAngle animVal;

  final SVGAngle baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedBoolean {

  final bool animVal;

  bool baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedEnumeration {

  final int animVal;

  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedInteger {

  final int animVal;

  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedLength {

  final SVGLength animVal;

  final SVGLength baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedLengthList {

  final SVGLengthList animVal;

  final SVGLengthList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedNumber {

  final num animVal;

  num baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedNumberList {

  final SVGNumberList animVal;

  final SVGNumberList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedPreserveAspectRatio {

  final SVGPreserveAspectRatio animVal;

  final SVGPreserveAspectRatio baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedRect {

  final SVGRect animVal;

  final SVGRect baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedString {

  final String animVal;

  String baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedTransformList {

  final SVGTransformList animVal;

  final SVGTransformList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimationElement extends SVGElement, SVGTests, SVGExternalResourcesRequired, ElementTimeControl {

  final SVGElement targetElement;

  num getCurrentTime();

  num getSimpleDuration();

  num getStartTime();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGCircleElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGAnimatedLength cx;

  final SVGAnimatedLength cy;

  final SVGAnimatedLength r;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGClipPathElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGAnimatedEnumeration clipPathUnits;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGColor extends CSSValue {

  static final int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static final int SVG_COLORTYPE_RGBCOLOR = 1;

  static final int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static final int SVG_COLORTYPE_UNKNOWN = 0;

  final int colorType;

  final RGBColor rgbColor;

  void setColor(int colorType, String rgbColor, String iccColor);

  void setRGBColor(String rgbColor);

  void setRGBColorICCColor(String rgbColor, String iccColor);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGComponentTransferFunctionElement extends SVGElement {

  static final int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  final SVGAnimatedNumber amplitude;

  final SVGAnimatedNumber exponent;

  final SVGAnimatedNumber intercept;

  final SVGAnimatedNumber offset;

  final SVGAnimatedNumber slope;

  final SVGAnimatedNumberList tableValues;

  final SVGAnimatedEnumeration type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGCursorElement extends SVGElement, SVGURIReference, SVGTests, SVGExternalResourcesRequired {

  final SVGAnimatedLength x;

  final SVGAnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGDefsElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGDescElement extends SVGElement, SVGLangSpace, SVGStylable {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGDocument extends Document {

  final SVGSVGElement rootElement;

  Event $dom_createEvent(String eventType);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface SVGElement extends Element default _SVGElementFactoryProvider {

  SVGElement.tag(String tag);
  SVGElement.svg(String svg);

  SVGElement clone(bool deep);


  String id;

  final SVGSVGElement ownerSVGElement;

  final SVGElement viewportElement;

  String xmlbase;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGElementInstance extends EventTarget {

  SVGElementInstanceEvents get on();

  final SVGElementInstanceList childNodes;

  final SVGElement correspondingElement;

  final SVGUseElement correspondingUseElement;

  final SVGElementInstance firstChild;

  final SVGElementInstance lastChild;

  final SVGElementInstance nextSibling;

  final SVGElementInstance parentNode;

  final SVGElementInstance previousSibling;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]);

  bool $dom_dispatchEvent(Event event);

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]);
}

interface SVGElementInstanceEvents extends Events {

  EventListenerList get abort();

  EventListenerList get beforeCopy();

  EventListenerList get beforeCut();

  EventListenerList get beforePaste();

  EventListenerList get blur();

  EventListenerList get change();

  EventListenerList get click();

  EventListenerList get contextMenu();

  EventListenerList get copy();

  EventListenerList get cut();

  EventListenerList get doubleClick();

  EventListenerList get drag();

  EventListenerList get dragEnd();

  EventListenerList get dragEnter();

  EventListenerList get dragLeave();

  EventListenerList get dragOver();

  EventListenerList get dragStart();

  EventListenerList get drop();

  EventListenerList get error();

  EventListenerList get focus();

  EventListenerList get input();

  EventListenerList get keyDown();

  EventListenerList get keyPress();

  EventListenerList get keyUp();

  EventListenerList get load();

  EventListenerList get mouseDown();

  EventListenerList get mouseMove();

  EventListenerList get mouseOut();

  EventListenerList get mouseOver();

  EventListenerList get mouseUp();

  EventListenerList get mouseWheel();

  EventListenerList get paste();

  EventListenerList get reset();

  EventListenerList get resize();

  EventListenerList get scroll();

  EventListenerList get search();

  EventListenerList get select();

  EventListenerList get selectStart();

  EventListenerList get submit();

  EventListenerList get unload();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGElementInstanceList {

  final int length;

  SVGElementInstance item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGEllipseElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGAnimatedLength cx;

  final SVGAnimatedLength cy;

  final SVGAnimatedLength rx;

  final SVGAnimatedLength ry;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGException {

  static final int SVG_INVALID_VALUE_ERR = 1;

  static final int SVG_MATRIX_NOT_INVERTABLE = 2;

  static final int SVG_WRONG_TYPE_ERR = 0;

  final int code;

  final String message;

  final String name;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGExternalResourcesRequired {

  final SVGAnimatedBoolean externalResourcesRequired;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEBlendElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_FEBLEND_MODE_DARKEN = 4;

  static final int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static final int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static final int SVG_FEBLEND_MODE_NORMAL = 1;

  static final int SVG_FEBLEND_MODE_SCREEN = 3;

  static final int SVG_FEBLEND_MODE_UNKNOWN = 0;

  final SVGAnimatedString in1;

  final SVGAnimatedString in2;

  final SVGAnimatedEnumeration mode;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEColorMatrixElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static final int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static final int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static final int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static final int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  final SVGAnimatedString in1;

  final SVGAnimatedEnumeration type;

  final SVGAnimatedNumberList values;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEComponentTransferElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  final SVGAnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFECompositeElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static final int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static final int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static final int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static final int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static final int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static final int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  final SVGAnimatedString in1;

  final SVGAnimatedString in2;

  final SVGAnimatedNumber k1;

  final SVGAnimatedNumber k2;

  final SVGAnimatedNumber k3;

  final SVGAnimatedNumber k4;

  final SVGAnimatedEnumeration operator;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEConvolveMatrixElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  final SVGAnimatedNumber bias;

  final SVGAnimatedNumber divisor;

  final SVGAnimatedEnumeration edgeMode;

  final SVGAnimatedString in1;

  final SVGAnimatedNumberList kernelMatrix;

  final SVGAnimatedNumber kernelUnitLengthX;

  final SVGAnimatedNumber kernelUnitLengthY;

  final SVGAnimatedInteger orderX;

  final SVGAnimatedInteger orderY;

  final SVGAnimatedBoolean preserveAlpha;

  final SVGAnimatedInteger targetX;

  final SVGAnimatedInteger targetY;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEDiffuseLightingElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  final SVGAnimatedNumber diffuseConstant;

  final SVGAnimatedString in1;

  final SVGAnimatedNumber kernelUnitLengthX;

  final SVGAnimatedNumber kernelUnitLengthY;

  final SVGAnimatedNumber surfaceScale;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEDisplacementMapElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  final SVGAnimatedString in1;

  final SVGAnimatedString in2;

  final SVGAnimatedNumber scale;

  final SVGAnimatedEnumeration xChannelSelector;

  final SVGAnimatedEnumeration yChannelSelector;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEDistantLightElement extends SVGElement {

  final SVGAnimatedNumber azimuth;

  final SVGAnimatedNumber elevation;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEDropShadowElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  final SVGAnimatedNumber dx;

  final SVGAnimatedNumber dy;

  final SVGAnimatedString in1;

  final SVGAnimatedNumber stdDeviationX;

  final SVGAnimatedNumber stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEFloodElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEFuncAElement extends SVGComponentTransferFunctionElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEFuncBElement extends SVGComponentTransferFunctionElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEFuncGElement extends SVGComponentTransferFunctionElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEFuncRElement extends SVGComponentTransferFunctionElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEGaussianBlurElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  final SVGAnimatedString in1;

  final SVGAnimatedNumber stdDeviationX;

  final SVGAnimatedNumber stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEImageElement extends SVGElement, SVGURIReference, SVGLangSpace, SVGExternalResourcesRequired, SVGFilterPrimitiveStandardAttributes {

  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEMergeElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEMergeNodeElement extends SVGElement {

  final SVGAnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEMorphologyElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  final SVGAnimatedString in1;

  final SVGAnimatedEnumeration operator;

  final SVGAnimatedNumber radiusX;

  final SVGAnimatedNumber radiusY;

  void setRadius(num radiusX, num radiusY);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEOffsetElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  final SVGAnimatedNumber dx;

  final SVGAnimatedNumber dy;

  final SVGAnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEPointLightElement extends SVGElement {

  final SVGAnimatedNumber x;

  final SVGAnimatedNumber y;

  final SVGAnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFESpecularLightingElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  final SVGAnimatedString in1;

  final SVGAnimatedNumber specularConstant;

  final SVGAnimatedNumber specularExponent;

  final SVGAnimatedNumber surfaceScale;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFESpotLightElement extends SVGElement {

  final SVGAnimatedNumber limitingConeAngle;

  final SVGAnimatedNumber pointsAtX;

  final SVGAnimatedNumber pointsAtY;

  final SVGAnimatedNumber pointsAtZ;

  final SVGAnimatedNumber specularExponent;

  final SVGAnimatedNumber x;

  final SVGAnimatedNumber y;

  final SVGAnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFETileElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  final SVGAnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFETurbulenceElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_STITCHTYPE_NOSTITCH = 2;

  static final int SVG_STITCHTYPE_STITCH = 1;

  static final int SVG_STITCHTYPE_UNKNOWN = 0;

  static final int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static final int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static final int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  final SVGAnimatedNumber baseFrequencyX;

  final SVGAnimatedNumber baseFrequencyY;

  final SVGAnimatedInteger numOctaves;

  final SVGAnimatedNumber seed;

  final SVGAnimatedEnumeration stitchTiles;

  final SVGAnimatedEnumeration type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFilterElement extends SVGElement, SVGURIReference, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable {

  final SVGAnimatedInteger filterResX;

  final SVGAnimatedInteger filterResY;

  final SVGAnimatedEnumeration filterUnits;

  final SVGAnimatedLength height;

  final SVGAnimatedEnumeration primitiveUnits;

  final SVGAnimatedLength width;

  final SVGAnimatedLength x;

  final SVGAnimatedLength y;

  void setFilterRes(int filterResX, int filterResY);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFilterPrimitiveStandardAttributes extends SVGStylable {

  final SVGAnimatedLength height;

  final SVGAnimatedString result;

  final SVGAnimatedLength width;

  final SVGAnimatedLength x;

  final SVGAnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFitToViewBox {

  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  final SVGAnimatedRect viewBox;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontFaceElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontFaceFormatElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontFaceNameElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontFaceSrcElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontFaceUriElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGForeignObjectElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGAnimatedLength height;

  final SVGAnimatedLength width;

  final SVGAnimatedLength x;

  final SVGAnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGGElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGGlyphElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGGlyphRefElement extends SVGElement, SVGURIReference, SVGStylable {

  num dx;

  num dy;

  String format;

  String glyphRef;

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGGradientElement extends SVGElement, SVGURIReference, SVGExternalResourcesRequired, SVGStylable {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  final SVGAnimatedTransformList gradientTransform;

  final SVGAnimatedEnumeration gradientUnits;

  final SVGAnimatedEnumeration spreadMethod;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGHKernElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGImageElement extends SVGElement, SVGURIReference, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGAnimatedLength height;

  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  final SVGAnimatedLength width;

  final SVGAnimatedLength x;

  final SVGAnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLangSpace {

  String xmllang;

  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLength {

  static final int SVG_LENGTHTYPE_CM = 6;

  static final int SVG_LENGTHTYPE_EMS = 3;

  static final int SVG_LENGTHTYPE_EXS = 4;

  static final int SVG_LENGTHTYPE_IN = 8;

  static final int SVG_LENGTHTYPE_MM = 7;

  static final int SVG_LENGTHTYPE_NUMBER = 1;

  static final int SVG_LENGTHTYPE_PC = 10;

  static final int SVG_LENGTHTYPE_PERCENTAGE = 2;

  static final int SVG_LENGTHTYPE_PT = 9;

  static final int SVG_LENGTHTYPE_PX = 5;

  static final int SVG_LENGTHTYPE_UNKNOWN = 0;

  final int unitType;

  num value;

  String valueAsString;

  num valueInSpecifiedUnits;

  void convertToSpecifiedUnits(int unitType);

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLengthList {

  final int numberOfItems;

  SVGLength appendItem(SVGLength item);

  void clear();

  SVGLength getItem(int index);

  SVGLength initialize(SVGLength item);

  SVGLength insertItemBefore(SVGLength item, int index);

  SVGLength removeItem(int index);

  SVGLength replaceItem(SVGLength item, int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLineElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGAnimatedLength x1;

  final SVGAnimatedLength x2;

  final SVGAnimatedLength y1;

  final SVGAnimatedLength y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLinearGradientElement extends SVGGradientElement {

  final SVGAnimatedLength x1;

  final SVGAnimatedLength x2;

  final SVGAnimatedLength y1;

  final SVGAnimatedLength y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLocatable {

  final SVGElement farthestViewportElement;

  final SVGElement nearestViewportElement;

  SVGRect getBBox();

  SVGMatrix getCTM();

  SVGMatrix getScreenCTM();

  SVGMatrix getTransformToElement(SVGElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMPathElement extends SVGElement, SVGURIReference, SVGExternalResourcesRequired {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMarkerElement extends SVGElement, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGFitToViewBox {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  final SVGAnimatedLength markerHeight;

  final SVGAnimatedEnumeration markerUnits;

  final SVGAnimatedLength markerWidth;

  final SVGAnimatedAngle orientAngle;

  final SVGAnimatedEnumeration orientType;

  final SVGAnimatedLength refX;

  final SVGAnimatedLength refY;

  void setOrientToAngle(SVGAngle angle);

  void setOrientToAuto();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMaskElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable {

  final SVGAnimatedLength height;

  final SVGAnimatedEnumeration maskContentUnits;

  final SVGAnimatedEnumeration maskUnits;

  final SVGAnimatedLength width;

  final SVGAnimatedLength x;

  final SVGAnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMatrix {

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

  SVGMatrix flipX();

  SVGMatrix flipY();

  SVGMatrix inverse();

  SVGMatrix multiply(SVGMatrix secondMatrix);

  SVGMatrix rotate(num angle);

  SVGMatrix rotateFromVector(num x, num y);

  SVGMatrix scale(num scaleFactor);

  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY);

  SVGMatrix skewX(num angle);

  SVGMatrix skewY(num angle);

  SVGMatrix translate(num x, num y);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMetadataElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMissingGlyphElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGNumber {

  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGNumberList {

  final int numberOfItems;

  SVGNumber appendItem(SVGNumber item);

  void clear();

  SVGNumber getItem(int index);

  SVGNumber initialize(SVGNumber item);

  SVGNumber insertItemBefore(SVGNumber item, int index);

  SVGNumber removeItem(int index);

  SVGNumber replaceItem(SVGNumber item, int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPaint extends SVGColor {

  static final int SVG_PAINTTYPE_CURRENTCOLOR = 102;

  static final int SVG_PAINTTYPE_NONE = 101;

  static final int SVG_PAINTTYPE_RGBCOLOR = 1;

  static final int SVG_PAINTTYPE_RGBCOLOR_ICCCOLOR = 2;

  static final int SVG_PAINTTYPE_UNKNOWN = 0;

  static final int SVG_PAINTTYPE_URI = 107;

  static final int SVG_PAINTTYPE_URI_CURRENTCOLOR = 104;

  static final int SVG_PAINTTYPE_URI_NONE = 103;

  static final int SVG_PAINTTYPE_URI_RGBCOLOR = 105;

  static final int SVG_PAINTTYPE_URI_RGBCOLOR_ICCCOLOR = 106;

  final int paintType;

  final String uri;

  void setPaint(int paintType, String uri, String rgbColor, String iccColor);

  void setUri(String uri);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGPathSegList animatedNormalizedPathSegList;

  final SVGPathSegList animatedPathSegList;

  final SVGPathSegList normalizedPathSegList;

  final SVGAnimatedNumber pathLength;

  final SVGPathSegList pathSegList;

  SVGPathSegArcAbs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag);

  SVGPathSegArcRel createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag);

  SVGPathSegClosePath createSVGPathSegClosePath();

  SVGPathSegCurvetoCubicAbs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2);

  SVGPathSegCurvetoCubicRel createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2);

  SVGPathSegCurvetoCubicSmoothAbs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2);

  SVGPathSegCurvetoCubicSmoothRel createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2);

  SVGPathSegCurvetoQuadraticAbs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1);

  SVGPathSegCurvetoQuadraticRel createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1);

  SVGPathSegCurvetoQuadraticSmoothAbs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y);

  SVGPathSegCurvetoQuadraticSmoothRel createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y);

  SVGPathSegLinetoAbs createSVGPathSegLinetoAbs(num x, num y);

  SVGPathSegLinetoHorizontalAbs createSVGPathSegLinetoHorizontalAbs(num x);

  SVGPathSegLinetoHorizontalRel createSVGPathSegLinetoHorizontalRel(num x);

  SVGPathSegLinetoRel createSVGPathSegLinetoRel(num x, num y);

  SVGPathSegLinetoVerticalAbs createSVGPathSegLinetoVerticalAbs(num y);

  SVGPathSegLinetoVerticalRel createSVGPathSegLinetoVerticalRel(num y);

  SVGPathSegMovetoAbs createSVGPathSegMovetoAbs(num x, num y);

  SVGPathSegMovetoRel createSVGPathSegMovetoRel(num x, num y);

  int getPathSegAtLength(num distance);

  SVGPoint getPointAtLength(num distance);

  num getTotalLength();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSeg {

  static final int PATHSEG_ARC_ABS = 10;

  static final int PATHSEG_ARC_REL = 11;

  static final int PATHSEG_CLOSEPATH = 1;

  static final int PATHSEG_CURVETO_CUBIC_ABS = 6;

  static final int PATHSEG_CURVETO_CUBIC_REL = 7;

  static final int PATHSEG_CURVETO_CUBIC_SMOOTH_ABS = 16;

  static final int PATHSEG_CURVETO_CUBIC_SMOOTH_REL = 17;

  static final int PATHSEG_CURVETO_QUADRATIC_ABS = 8;

  static final int PATHSEG_CURVETO_QUADRATIC_REL = 9;

  static final int PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS = 18;

  static final int PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL = 19;

  static final int PATHSEG_LINETO_ABS = 4;

  static final int PATHSEG_LINETO_HORIZONTAL_ABS = 12;

  static final int PATHSEG_LINETO_HORIZONTAL_REL = 13;

  static final int PATHSEG_LINETO_REL = 5;

  static final int PATHSEG_LINETO_VERTICAL_ABS = 14;

  static final int PATHSEG_LINETO_VERTICAL_REL = 15;

  static final int PATHSEG_MOVETO_ABS = 2;

  static final int PATHSEG_MOVETO_REL = 3;

  static final int PATHSEG_UNKNOWN = 0;

  final int pathSegType;

  final String pathSegTypeAsLetter;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegArcAbs extends SVGPathSeg {

  num angle;

  bool largeArcFlag;

  num r1;

  num r2;

  bool sweepFlag;

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegArcRel extends SVGPathSeg {

  num angle;

  bool largeArcFlag;

  num r1;

  num r2;

  bool sweepFlag;

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegClosePath extends SVGPathSeg {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoCubicAbs extends SVGPathSeg {

  num x;

  num x1;

  num x2;

  num y;

  num y1;

  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoCubicRel extends SVGPathSeg {

  num x;

  num x1;

  num x2;

  num y;

  num y1;

  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoCubicSmoothAbs extends SVGPathSeg {

  num x;

  num x2;

  num y;

  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoCubicSmoothRel extends SVGPathSeg {

  num x;

  num x2;

  num y;

  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoQuadraticAbs extends SVGPathSeg {

  num x;

  num x1;

  num y;

  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoQuadraticRel extends SVGPathSeg {

  num x;

  num x1;

  num y;

  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoQuadraticSmoothAbs extends SVGPathSeg {

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoQuadraticSmoothRel extends SVGPathSeg {

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoAbs extends SVGPathSeg {

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoHorizontalAbs extends SVGPathSeg {

  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoHorizontalRel extends SVGPathSeg {

  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoRel extends SVGPathSeg {

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoVerticalAbs extends SVGPathSeg {

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoVerticalRel extends SVGPathSeg {

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegList {

  final int numberOfItems;

  SVGPathSeg appendItem(SVGPathSeg newItem);

  void clear();

  SVGPathSeg getItem(int index);

  SVGPathSeg initialize(SVGPathSeg newItem);

  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index);

  SVGPathSeg removeItem(int index);

  SVGPathSeg replaceItem(SVGPathSeg newItem, int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegMovetoAbs extends SVGPathSeg {

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegMovetoRel extends SVGPathSeg {

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPatternElement extends SVGElement, SVGURIReference, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGFitToViewBox {

  final SVGAnimatedLength height;

  final SVGAnimatedEnumeration patternContentUnits;

  final SVGAnimatedTransformList patternTransform;

  final SVGAnimatedEnumeration patternUnits;

  final SVGAnimatedLength width;

  final SVGAnimatedLength x;

  final SVGAnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPoint {

  num x;

  num y;

  SVGPoint matrixTransform(SVGMatrix matrix);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPointList {

  final int numberOfItems;

  SVGPoint appendItem(SVGPoint item);

  void clear();

  SVGPoint getItem(int index);

  SVGPoint initialize(SVGPoint item);

  SVGPoint insertItemBefore(SVGPoint item, int index);

  SVGPoint removeItem(int index);

  SVGPoint replaceItem(SVGPoint item, int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPolygonElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGPointList animatedPoints;

  final SVGPointList points;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPolylineElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGPointList animatedPoints;

  final SVGPointList points;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPreserveAspectRatio {

  static final int SVG_MEETORSLICE_MEET = 1;

  static final int SVG_MEETORSLICE_SLICE = 2;

  static final int SVG_MEETORSLICE_UNKNOWN = 0;

  static final int SVG_PRESERVEASPECTRATIO_NONE = 1;

  static final int SVG_PRESERVEASPECTRATIO_UNKNOWN = 0;

  static final int SVG_PRESERVEASPECTRATIO_XMAXYMAX = 10;

  static final int SVG_PRESERVEASPECTRATIO_XMAXYMID = 7;

  static final int SVG_PRESERVEASPECTRATIO_XMAXYMIN = 4;

  static final int SVG_PRESERVEASPECTRATIO_XMIDYMAX = 9;

  static final int SVG_PRESERVEASPECTRATIO_XMIDYMID = 6;

  static final int SVG_PRESERVEASPECTRATIO_XMIDYMIN = 3;

  static final int SVG_PRESERVEASPECTRATIO_XMINYMAX = 8;

  static final int SVG_PRESERVEASPECTRATIO_XMINYMID = 5;

  static final int SVG_PRESERVEASPECTRATIO_XMINYMIN = 2;

  int align;

  int meetOrSlice;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGRadialGradientElement extends SVGGradientElement {

  final SVGAnimatedLength cx;

  final SVGAnimatedLength cy;

  final SVGAnimatedLength fx;

  final SVGAnimatedLength fy;

  final SVGAnimatedLength r;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGRect {

  num height;

  num width;

  num x;

  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGRectElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGAnimatedLength height;

  final SVGAnimatedLength rx;

  final SVGAnimatedLength ry;

  final SVGAnimatedLength width;

  final SVGAnimatedLength x;

  final SVGAnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGRenderingIntent {

  static final int RENDERING_INTENT_ABSOLUTE_COLORIMETRIC = 5;

  static final int RENDERING_INTENT_AUTO = 1;

  static final int RENDERING_INTENT_PERCEPTUAL = 2;

  static final int RENDERING_INTENT_RELATIVE_COLORIMETRIC = 3;

  static final int RENDERING_INTENT_SATURATION = 4;

  static final int RENDERING_INTENT_UNKNOWN = 0;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface SVGSVGElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGLocatable, SVGFitToViewBox, SVGZoomAndPan
    default _SVGSVGElementFactoryProvider {
  SVGSVGElement();


  String contentScriptType;

  String contentStyleType;

  num currentScale;

  final SVGPoint currentTranslate;

  final SVGAnimatedLength height;

  final num pixelUnitToMillimeterX;

  final num pixelUnitToMillimeterY;

  final num screenPixelToMillimeterX;

  final num screenPixelToMillimeterY;

  bool useCurrentView;

  final SVGRect viewport;

  final SVGAnimatedLength width;

  final SVGAnimatedLength x;

  final SVGAnimatedLength y;

  bool animationsPaused();

  bool checkEnclosure(SVGElement element, SVGRect rect);

  bool checkIntersection(SVGElement element, SVGRect rect);

  SVGAngle createSVGAngle();

  SVGLength createSVGLength();

  SVGMatrix createSVGMatrix();

  SVGNumber createSVGNumber();

  SVGPoint createSVGPoint();

  SVGRect createSVGRect();

  SVGTransform createSVGTransform();

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix);

  void deselectAll();

  void forceRedraw();

  num getCurrentTime();

  Element getElementById(String elementId);

  NodeList getEnclosureList(SVGRect rect, SVGElement referenceElement);

  NodeList getIntersectionList(SVGRect rect, SVGElement referenceElement);

  void pauseAnimations();

  void setCurrentTime(num seconds);

  int suspendRedraw(int maxWaitMilliseconds);

  void unpauseAnimations();

  void unsuspendRedraw(int suspendHandleId);

  void unsuspendRedrawAll();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGScriptElement extends SVGElement, SVGURIReference, SVGExternalResourcesRequired {

  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGSetElement extends SVGAnimationElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGStopElement extends SVGElement, SVGStylable {

  final SVGAnimatedNumber offset;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGStringList {

  final int numberOfItems;

  String appendItem(String item);

  void clear();

  String getItem(int index);

  String initialize(String item);

  String insertItemBefore(String item, int index);

  String removeItem(int index);

  String replaceItem(String item, int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGStylable {

  final SVGAnimatedString $dom_svgClassName;

  final CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGStyleElement extends SVGElement, SVGLangSpace {

  bool disabled;

  String media;

  String title;

  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGSwitchElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGSymbolElement extends SVGElement, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGFitToViewBox {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTRefElement extends SVGTextPositioningElement, SVGURIReference {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTSpanElement extends SVGTextPositioningElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTests {

  final SVGStringList requiredExtensions;

  final SVGStringList requiredFeatures;

  final SVGStringList systemLanguage;

  bool hasExtension(String extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTextContentElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable {

  static final int LENGTHADJUST_SPACING = 1;

  static final int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static final int LENGTHADJUST_UNKNOWN = 0;

  final SVGAnimatedEnumeration lengthAdjust;

  final SVGAnimatedLength textLength;

  int getCharNumAtPosition(SVGPoint point);

  num getComputedTextLength();

  SVGPoint getEndPositionOfChar(int offset);

  SVGRect getExtentOfChar(int offset);

  int getNumberOfChars();

  num getRotationOfChar(int offset);

  SVGPoint getStartPositionOfChar(int offset);

  num getSubStringLength(int offset, int length);

  void selectSubString(int offset, int length);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTextElement extends SVGTextPositioningElement, SVGTransformable {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTextPathElement extends SVGTextContentElement, SVGURIReference {

  static final int TEXTPATH_METHODTYPE_ALIGN = 1;

  static final int TEXTPATH_METHODTYPE_STRETCH = 2;

  static final int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static final int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static final int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static final int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  final SVGAnimatedEnumeration method;

  final SVGAnimatedEnumeration spacing;

  final SVGAnimatedLength startOffset;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTextPositioningElement extends SVGTextContentElement {

  final SVGAnimatedLengthList dx;

  final SVGAnimatedLengthList dy;

  final SVGAnimatedNumberList rotate;

  final SVGAnimatedLengthList x;

  final SVGAnimatedLengthList y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTitleElement extends SVGElement, SVGLangSpace, SVGStylable {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTransform {

  static final int SVG_TRANSFORM_MATRIX = 1;

  static final int SVG_TRANSFORM_ROTATE = 4;

  static final int SVG_TRANSFORM_SCALE = 3;

  static final int SVG_TRANSFORM_SKEWX = 5;

  static final int SVG_TRANSFORM_SKEWY = 6;

  static final int SVG_TRANSFORM_TRANSLATE = 2;

  static final int SVG_TRANSFORM_UNKNOWN = 0;

  final num angle;

  final SVGMatrix matrix;

  final int type;

  void setMatrix(SVGMatrix matrix);

  void setRotate(num angle, num cx, num cy);

  void setScale(num sx, num sy);

  void setSkewX(num angle);

  void setSkewY(num angle);

  void setTranslate(num tx, num ty);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTransformList {

  final int numberOfItems;

  SVGTransform appendItem(SVGTransform item);

  void clear();

  SVGTransform consolidate();

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix);

  SVGTransform getItem(int index);

  SVGTransform initialize(SVGTransform item);

  SVGTransform insertItemBefore(SVGTransform item, int index);

  SVGTransform removeItem(int index);

  SVGTransform replaceItem(SVGTransform item, int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTransformable extends SVGLocatable {

  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGURIReference {

  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGUnitTypes {

  static final int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static final int SVG_UNIT_TYPE_UNKNOWN = 0;

  static final int SVG_UNIT_TYPE_USERSPACEONUSE = 1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGUseElement extends SVGElement, SVGURIReference, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  final SVGElementInstance animatedInstanceRoot;

  final SVGAnimatedLength height;

  final SVGElementInstance instanceRoot;

  final SVGAnimatedLength width;

  final SVGAnimatedLength x;

  final SVGAnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGVKernElement extends SVGElement {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGViewElement extends SVGElement, SVGExternalResourcesRequired, SVGFitToViewBox, SVGZoomAndPan {

  final SVGStringList viewTarget;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGViewSpec extends SVGZoomAndPan, SVGFitToViewBox {

  final String preserveAspectRatioString;

  final SVGTransformList transform;

  final String transformString;

  final String viewBoxString;

  final SVGElement viewTarget;

  final String viewTargetString;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGZoomAndPan {

  static final int SVG_ZOOMANDPAN_DISABLE = 1;

  static final int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static final int SVG_ZOOMANDPAN_UNKNOWN = 0;

  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGZoomEvent extends UIEvent {

  final num newScale;

  final SVGPoint newTranslate;

  final num previousScale;

  final SVGPoint previousTranslate;

  final SVGRect zoomRectScreen;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Screen {

  final int availHeight;

  final int availLeft;

  final int availTop;

  final int availWidth;

  final int colorDepth;

  final int height;

  final int pixelDepth;

  final int width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ScriptElement extends Element {

  bool async;

  String charset;

  String crossOrigin;

  bool defer;

  String event;

  String htmlFor;

  String src;

  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ScriptProfile {

  final ScriptProfileNode head;

  final String title;

  final int uid;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ScriptProfileNode {

  final int callUID;

  final List<ScriptProfileNode> children;

  final String functionName;

  final int lineNumber;

  final int numberOfCalls;

  final num selfTime;

  final num totalTime;

  final String url;

  final bool visible;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SelectElement extends Element {

  bool autofocus;

  bool disabled;

  final FormElement form;

  final NodeList labels;

  int length;

  bool multiple;

  String name;

  final HTMLOptionsCollection options;

  bool required;

  int selectedIndex;

  final HTMLCollection selectedOptions;

  int size;

  final String type;

  final String validationMessage;

  final ValidityState validity;

  String value;

  final bool willValidate;

  void add(Element element, Element before);

  bool checkValidity();

  Node item(int index);

  Node namedItem(String name);

  void setCustomValidity(String error);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SessionDescription default _SessionDescriptionFactoryProvider {

  SessionDescription(String sdp);

  void addCandidate(IceCandidate candidate);

  String toSdp();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ShadowElement extends Element {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ShadowRoot extends DocumentFragment default _ShadowRootFactoryProvider {

  ShadowRoot(Element host);

  final Element activeElement;

  final Element host;

  String innerHTML;

  Element getElementById(String elementId);

  NodeList getElementsByClassName(String className);

  NodeList getElementsByTagName(String tagName);

  NodeList getElementsByTagNameNS(String namespaceURI, String localName);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SharedWorker extends AbstractWorker default _SharedWorkerFactoryProvider {

  SharedWorker(String scriptURL, [String name]);

  final MessagePort port;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SharedWorkerContext extends WorkerContext {

  final String name;

  EventListener onconnect;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool SignalingCallback(String message, DeprecatedPeerConnection source);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SourceElement extends Element {

  String media;

  String src;

  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpanElement extends Element {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechGrammar default _SpeechGrammarFactoryProvider {

  SpeechGrammar();

  String src;

  num weight;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechGrammarList default _SpeechGrammarListFactoryProvider {

  SpeechGrammarList();

  final int length;

  void addFromString(String string, [num weight]);

  void addFromUri(String src, [num weight]);

  SpeechGrammar item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechInputEvent extends Event {

  final SpeechInputResultList results;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechInputResult {

  final num confidence;

  final String utterance;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechInputResultList {

  final int length;

  SpeechInputResult item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechRecognition default _SpeechRecognitionFactoryProvider {

  SpeechRecognition();

  bool continuous;

  SpeechGrammarList grammars;

  String lang;

  EventListener onaudioend;

  EventListener onaudiostart;

  EventListener onend;

  EventListener onerror;

  EventListener onnomatch;

  EventListener onresult;

  EventListener onresultdeleted;

  EventListener onsoundend;

  EventListener onsoundstart;

  EventListener onspeechend;

  EventListener onspeechstart;

  EventListener onstart;

  void abort();

  void start();

  void stop();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechRecognitionAlternative {

  final num confidence;

  final String transcript;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechRecognitionError {

  static final int ABORTED = 2;

  static final int AUDIO_CAPTURE = 3;

  static final int BAD_GRAMMAR = 7;

  static final int LANGUAGE_NOT_SUPPORTED = 8;

  static final int NETWORK = 4;

  static final int NOT_ALLOWED = 5;

  static final int NO_SPEECH = 1;

  static final int OTHER = 0;

  static final int SERVICE_NOT_ALLOWED = 6;

  final int code;

  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechRecognitionEvent extends Event {

  final SpeechRecognitionError error;

  final SpeechRecognitionResult result;

  final SpeechRecognitionResultList resultHistory;

  final int resultIndex;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechRecognitionResult {

  final bool finalValue;

  final int length;

  SpeechRecognitionAlternative item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechRecognitionResultList {

  final int length;

  SpeechRecognitionResult item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Storage {

  final int length;

  void clear();

  String getItem(String key);

  String key(int index);

  void removeItem(String key);

  void setItem(String key, String data);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StorageEvent extends Event {

  final String key;

  final String newValue;

  final String oldValue;

  final Storage storageArea;

  final String url;

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StorageInfo {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback, StorageInfoErrorCallback errorCallback]);

  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback, StorageInfoErrorCallback errorCallback]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool StorageInfoErrorCallback(DOMException error);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool StorageInfoQuotaCallback(int grantedQuotaInBytes);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool StorageInfoUsageCallback(int currentUsageInBytes, int currentQuotaInBytes);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool StringCallback(String data);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StyleElement extends Element {

  bool disabled;

  String media;

  final StyleSheet sheet;

  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StyleMedia {

  final String type;

  bool matchMedium(String mediaquery);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StyleSheet {

  bool disabled;

  final String href;

  final MediaList media;

  final Node ownerNode;

  final StyleSheet parentStyleSheet;

  final String title;

  final String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StyleSheetList extends List<StyleSheet> {

  final int length;

  StyleSheet item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableCaptionElement extends Element {

  String align;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableCellElement extends Element {

  String abbr;

  String align;

  String axis;

  String bgColor;

  final int cellIndex;

  String ch;

  String chOff;

  int colSpan;

  String headers;

  String height;

  bool noWrap;

  int rowSpan;

  String scope;

  String vAlign;

  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableColElement extends Element {

  String align;

  String ch;

  String chOff;

  int span;

  String vAlign;

  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableElement extends Element {

  String align;

  String bgColor;

  String border;

  TableCaptionElement caption;

  String cellPadding;

  String cellSpacing;

  String frame;

  final HTMLCollection rows;

  String rules;

  String summary;

  final HTMLCollection tBodies;

  TableSectionElement tFoot;

  TableSectionElement tHead;

  String width;

  Element createCaption();

  Element createTFoot();

  Element createTHead();

  void deleteCaption();

  void deleteRow(int index);

  void deleteTFoot();

  void deleteTHead();

  Element insertRow(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableRowElement extends Element {

  String align;

  String bgColor;

  final HTMLCollection cells;

  String ch;

  String chOff;

  final int rowIndex;

  final int sectionRowIndex;

  String vAlign;

  void deleteCell(int index);

  Element insertCell(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableSectionElement extends Element {

  String align;

  String ch;

  String chOff;

  final HTMLCollection rows;

  String vAlign;

  void deleteRow(int index);

  Element insertRow(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Text extends CharacterData default _TextFactoryProvider {

  Text(String data);

  final String wholeText;

  Text replaceWholeText(String content);

  Text splitText(int offset);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextAreaElement extends Element {

  bool autofocus;

  int cols;

  String defaultValue;

  bool disabled;

  final FormElement form;

  final NodeList labels;

  int maxLength;

  String name;

  String placeholder;

  bool readOnly;

  bool required;

  int rows;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  final int textLength;

  final String type;

  final String validationMessage;

  final ValidityState validity;

  String value;

  final bool willValidate;

  String wrap;

  bool checkValidity();

  void select();

  void setCustomValidity(String error);

  void setSelectionRange(int start, int end, [String direction]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextEvent extends UIEvent {

  final String data;

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Window viewArg, String dataArg);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextMetrics {

  final num width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrack {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  final TextTrackCueList activeCues;

  final TextTrackCueList cues;

  final String kind;

  final String label;

  final String language;

  int mode;

  EventListener oncuechange;

  void addCue(TextTrackCue cue);

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void removeCue(TextTrackCue cue);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrackCue default _TextTrackCueFactoryProvider {

  TextTrackCue(String id, num startTime, num endTime, String text, [String settings, bool pauseOnExit]);

  String align;

  num endTime;

  String id;

  int line;

  EventListener onenter;

  EventListener onexit;

  bool pauseOnExit;

  int position;

  int size;

  bool snapToLines;

  num startTime;

  String text;

  final TextTrack track;

  String vertical;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  DocumentFragment getCueAsHTML();

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrackCueList {

  final int length;

  TextTrackCue getCueById(String id);

  TextTrackCue item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrackList {

  final int length;

  EventListener onaddtrack;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  TextTrack item(int index);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TimeRanges {

  final int length;

  num end(int index);

  num start(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TitleElement extends Element {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Touch {

  final int clientX;

  final int clientY;

  final int identifier;

  final int pageX;

  final int pageY;

  final int screenX;

  final int screenY;

  final EventTarget target;

  final num webkitForce;

  final int webkitRadiusX;

  final int webkitRadiusY;

  final num webkitRotationAngle;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TouchEvent extends UIEvent {

  final bool altKey;

  final TouchList changedTouches;

  final bool ctrlKey;

  final bool metaKey;

  final bool shiftKey;

  final TouchList targetTouches;

  final TouchList touches;

  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TouchList extends List<Touch> {

  final int length;

  Touch item(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TrackElement extends Element {

  static final int ERROR = 3;

  static final int LOADED = 2;

  static final int LOADING = 1;

  static final int NONE = 0;

  bool defaultValue;

  String kind;

  String label;

  final int readyState;

  String src;

  String srclang;

  final TextTrack track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TrackEvent extends Event {

  final Object track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TransitionEvent extends Event {

  final num elapsedTime;

  final String propertyName;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TreeWalker {

  Node currentNode;

  final bool expandEntityReferences;

  final NodeFilter filter;

  final Node root;

  final int whatToShow;

  Node firstChild();

  Node lastChild();

  Node nextNode();

  Node nextSibling();

  Node parentNode();

  Node previousNode();

  Node previousSibling();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface UIEvent extends Event {

  final int charCode;

  final int detail;

  final int keyCode;

  final int layerX;

  final int layerY;

  final int pageX;

  final int pageY;

  final Window view;

  final int which;

  void initUIEvent(String type, bool canBubble, bool cancelable, Window view, int detail);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface UListElement extends Element {

  bool compact;

  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint16Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Uint16Array(int length);

  Uint16Array.fromList(List<int> list);

  Uint16Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 2;

  final int length;

  void setElements(Object array, [int offset]);

  Uint16Array subarray(int start, [int end]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint32Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Uint32Array(int length);

  Uint32Array.fromList(List<int> list);

  Uint32Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 4;

  final int length;

  void setElements(Object array, [int offset]);

  Uint32Array subarray(int start, [int end]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint8Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Uint8Array(int length);

  Uint8Array.fromList(List<int> list);

  Uint8Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 1;

  final int length;

  void setElements(Object array, [int offset]);

  Uint8Array subarray(int start, [int end]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint8ClampedArray extends Uint8Array default _TypedArrayFactoryProvider {

  Uint8ClampedArray(int length);

  Uint8ClampedArray.fromList(List<int> list);

  Uint8ClampedArray.fromBuffer(ArrayBuffer buffer);

  final int length;

  void setElements(Object array, [int offset]);

  Uint8ClampedArray subarray(int start, [int end]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface UnknownElement extends Element {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ValidityState {

  final bool customError;

  final bool patternMismatch;

  final bool rangeOverflow;

  final bool rangeUnderflow;

  final bool stepMismatch;

  final bool tooLong;

  final bool typeMismatch;

  final bool valid;

  final bool valueMissing;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface VideoElement extends MediaElement {

  int height;

  String poster;

  final int videoHeight;

  final int videoWidth;

  final int webkitDecodedFrameCount;

  final bool webkitDisplayingFullscreen;

  final int webkitDroppedFrameCount;

  final bool webkitSupportsFullscreen;

  int width;

  void webkitEnterFullScreen();

  void webkitEnterFullscreen();

  void webkitExitFullScreen();

  void webkitExitFullscreen();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef void VoidCallback();
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WaveShaperNode extends AudioNode {

  Float32Array curve;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLActiveInfo {

  final String name;

  final int size;

  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLBuffer {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLCompressedTextureS3TC {

  static final int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  static final int COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;

  static final int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  static final int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLContextAttributes {

  bool alpha;

  bool antialias;

  bool depth;

  bool premultipliedAlpha;

  bool preserveDrawingBuffer;

  bool stencil;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLContextEvent extends Event {

  final String statusMessage;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLDebugRendererInfo {

  static final int UNMASKED_RENDERER_WEBGL = 0x9246;

  static final int UNMASKED_VENDOR_WEBGL = 0x9245;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLDebugShaders {

  String getTranslatedShaderSource(WebGLShader shader);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLFramebuffer {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLLoseContext {

  void loseContext();

  void restoreContext();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLProgram {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLRenderbuffer {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLRenderingContext extends CanvasRenderingContext {

  static final int ACTIVE_ATTRIBUTES = 0x8B89;

  static final int ACTIVE_TEXTURE = 0x84E0;

  static final int ACTIVE_UNIFORMS = 0x8B86;

  static final int ALIASED_LINE_WIDTH_RANGE = 0x846E;

  static final int ALIASED_POINT_SIZE_RANGE = 0x846D;

  static final int ALPHA = 0x1906;

  static final int ALPHA_BITS = 0x0D55;

  static final int ALWAYS = 0x0207;

  static final int ARRAY_BUFFER = 0x8892;

  static final int ARRAY_BUFFER_BINDING = 0x8894;

  static final int ATTACHED_SHADERS = 0x8B85;

  static final int BACK = 0x0405;

  static final int BLEND = 0x0BE2;

  static final int BLEND_COLOR = 0x8005;

  static final int BLEND_DST_ALPHA = 0x80CA;

  static final int BLEND_DST_RGB = 0x80C8;

  static final int BLEND_EQUATION = 0x8009;

  static final int BLEND_EQUATION_ALPHA = 0x883D;

  static final int BLEND_EQUATION_RGB = 0x8009;

  static final int BLEND_SRC_ALPHA = 0x80CB;

  static final int BLEND_SRC_RGB = 0x80C9;

  static final int BLUE_BITS = 0x0D54;

  static final int BOOL = 0x8B56;

  static final int BOOL_VEC2 = 0x8B57;

  static final int BOOL_VEC3 = 0x8B58;

  static final int BOOL_VEC4 = 0x8B59;

  static final int BROWSER_DEFAULT_WEBGL = 0x9244;

  static final int BUFFER_SIZE = 0x8764;

  static final int BUFFER_USAGE = 0x8765;

  static final int BYTE = 0x1400;

  static final int CCW = 0x0901;

  static final int CLAMP_TO_EDGE = 0x812F;

  static final int COLOR_ATTACHMENT0 = 0x8CE0;

  static final int COLOR_BUFFER_BIT = 0x00004000;

  static final int COLOR_CLEAR_VALUE = 0x0C22;

  static final int COLOR_WRITEMASK = 0x0C23;

  static final int COMPILE_STATUS = 0x8B81;

  static final int COMPRESSED_TEXTURE_FORMATS = 0x86A3;

  static final int CONSTANT_ALPHA = 0x8003;

  static final int CONSTANT_COLOR = 0x8001;

  static final int CONTEXT_LOST_WEBGL = 0x9242;

  static final int CULL_FACE = 0x0B44;

  static final int CULL_FACE_MODE = 0x0B45;

  static final int CURRENT_PROGRAM = 0x8B8D;

  static final int CURRENT_VERTEX_ATTRIB = 0x8626;

  static final int CW = 0x0900;

  static final int DECR = 0x1E03;

  static final int DECR_WRAP = 0x8508;

  static final int DELETE_STATUS = 0x8B80;

  static final int DEPTH_ATTACHMENT = 0x8D00;

  static final int DEPTH_BITS = 0x0D56;

  static final int DEPTH_BUFFER_BIT = 0x00000100;

  static final int DEPTH_CLEAR_VALUE = 0x0B73;

  static final int DEPTH_COMPONENT = 0x1902;

  static final int DEPTH_COMPONENT16 = 0x81A5;

  static final int DEPTH_FUNC = 0x0B74;

  static final int DEPTH_RANGE = 0x0B70;

  static final int DEPTH_STENCIL = 0x84F9;

  static final int DEPTH_STENCIL_ATTACHMENT = 0x821A;

  static final int DEPTH_TEST = 0x0B71;

  static final int DEPTH_WRITEMASK = 0x0B72;

  static final int DITHER = 0x0BD0;

  static final int DONT_CARE = 0x1100;

  static final int DST_ALPHA = 0x0304;

  static final int DST_COLOR = 0x0306;

  static final int DYNAMIC_DRAW = 0x88E8;

  static final int ELEMENT_ARRAY_BUFFER = 0x8893;

  static final int ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;

  static final int EQUAL = 0x0202;

  static final int FASTEST = 0x1101;

  static final int FLOAT = 0x1406;

  static final int FLOAT_MAT2 = 0x8B5A;

  static final int FLOAT_MAT3 = 0x8B5B;

  static final int FLOAT_MAT4 = 0x8B5C;

  static final int FLOAT_VEC2 = 0x8B50;

  static final int FLOAT_VEC3 = 0x8B51;

  static final int FLOAT_VEC4 = 0x8B52;

  static final int FRAGMENT_SHADER = 0x8B30;

  static final int FRAMEBUFFER = 0x8D40;

  static final int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;

  static final int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;

  static final int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

  static final int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;

  static final int FRAMEBUFFER_BINDING = 0x8CA6;

  static final int FRAMEBUFFER_COMPLETE = 0x8CD5;

  static final int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;

  static final int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;

  static final int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;

  static final int FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

  static final int FRONT = 0x0404;

  static final int FRONT_AND_BACK = 0x0408;

  static final int FRONT_FACE = 0x0B46;

  static final int FUNC_ADD = 0x8006;

  static final int FUNC_REVERSE_SUBTRACT = 0x800B;

  static final int FUNC_SUBTRACT = 0x800A;

  static final int GENERATE_MIPMAP_HINT = 0x8192;

  static final int GEQUAL = 0x0206;

  static final int GREATER = 0x0204;

  static final int GREEN_BITS = 0x0D53;

  static final int HIGH_FLOAT = 0x8DF2;

  static final int HIGH_INT = 0x8DF5;

  static final int INCR = 0x1E02;

  static final int INCR_WRAP = 0x8507;

  static final int INT = 0x1404;

  static final int INT_VEC2 = 0x8B53;

  static final int INT_VEC3 = 0x8B54;

  static final int INT_VEC4 = 0x8B55;

  static final int INVALID_ENUM = 0x0500;

  static final int INVALID_FRAMEBUFFER_OPERATION = 0x0506;

  static final int INVALID_OPERATION = 0x0502;

  static final int INVALID_VALUE = 0x0501;

  static final int INVERT = 0x150A;

  static final int KEEP = 0x1E00;

  static final int LEQUAL = 0x0203;

  static final int LESS = 0x0201;

  static final int LINEAR = 0x2601;

  static final int LINEAR_MIPMAP_LINEAR = 0x2703;

  static final int LINEAR_MIPMAP_NEAREST = 0x2701;

  static final int LINES = 0x0001;

  static final int LINE_LOOP = 0x0002;

  static final int LINE_STRIP = 0x0003;

  static final int LINE_WIDTH = 0x0B21;

  static final int LINK_STATUS = 0x8B82;

  static final int LOW_FLOAT = 0x8DF0;

  static final int LOW_INT = 0x8DF3;

  static final int LUMINANCE = 0x1909;

  static final int LUMINANCE_ALPHA = 0x190A;

  static final int MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;

  static final int MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

  static final int MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;

  static final int MAX_RENDERBUFFER_SIZE = 0x84E8;

  static final int MAX_TEXTURE_IMAGE_UNITS = 0x8872;

  static final int MAX_TEXTURE_SIZE = 0x0D33;

  static final int MAX_VARYING_VECTORS = 0x8DFC;

  static final int MAX_VERTEX_ATTRIBS = 0x8869;

  static final int MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;

  static final int MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;

  static final int MAX_VIEWPORT_DIMS = 0x0D3A;

  static final int MEDIUM_FLOAT = 0x8DF1;

  static final int MEDIUM_INT = 0x8DF4;

  static final int MIRRORED_REPEAT = 0x8370;

  static final int NEAREST = 0x2600;

  static final int NEAREST_MIPMAP_LINEAR = 0x2702;

  static final int NEAREST_MIPMAP_NEAREST = 0x2700;

  static final int NEVER = 0x0200;

  static final int NICEST = 0x1102;

  static final int NONE = 0;

  static final int NOTEQUAL = 0x0205;

  static final int NO_ERROR = 0;

  static final int ONE = 1;

  static final int ONE_MINUS_CONSTANT_ALPHA = 0x8004;

  static final int ONE_MINUS_CONSTANT_COLOR = 0x8002;

  static final int ONE_MINUS_DST_ALPHA = 0x0305;

  static final int ONE_MINUS_DST_COLOR = 0x0307;

  static final int ONE_MINUS_SRC_ALPHA = 0x0303;

  static final int ONE_MINUS_SRC_COLOR = 0x0301;

  static final int OUT_OF_MEMORY = 0x0505;

  static final int PACK_ALIGNMENT = 0x0D05;

  static final int POINTS = 0x0000;

  static final int POLYGON_OFFSET_FACTOR = 0x8038;

  static final int POLYGON_OFFSET_FILL = 0x8037;

  static final int POLYGON_OFFSET_UNITS = 0x2A00;

  static final int RED_BITS = 0x0D52;

  static final int RENDERBUFFER = 0x8D41;

  static final int RENDERBUFFER_ALPHA_SIZE = 0x8D53;

  static final int RENDERBUFFER_BINDING = 0x8CA7;

  static final int RENDERBUFFER_BLUE_SIZE = 0x8D52;

  static final int RENDERBUFFER_DEPTH_SIZE = 0x8D54;

  static final int RENDERBUFFER_GREEN_SIZE = 0x8D51;

  static final int RENDERBUFFER_HEIGHT = 0x8D43;

  static final int RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;

  static final int RENDERBUFFER_RED_SIZE = 0x8D50;

  static final int RENDERBUFFER_STENCIL_SIZE = 0x8D55;

  static final int RENDERBUFFER_WIDTH = 0x8D42;

  static final int RENDERER = 0x1F01;

  static final int REPEAT = 0x2901;

  static final int REPLACE = 0x1E01;

  static final int RGB = 0x1907;

  static final int RGB565 = 0x8D62;

  static final int RGB5_A1 = 0x8057;

  static final int RGBA = 0x1908;

  static final int RGBA4 = 0x8056;

  static final int SAMPLER_2D = 0x8B5E;

  static final int SAMPLER_CUBE = 0x8B60;

  static final int SAMPLES = 0x80A9;

  static final int SAMPLE_ALPHA_TO_COVERAGE = 0x809E;

  static final int SAMPLE_BUFFERS = 0x80A8;

  static final int SAMPLE_COVERAGE = 0x80A0;

  static final int SAMPLE_COVERAGE_INVERT = 0x80AB;

  static final int SAMPLE_COVERAGE_VALUE = 0x80AA;

  static final int SCISSOR_BOX = 0x0C10;

  static final int SCISSOR_TEST = 0x0C11;

  static final int SHADER_COMPILER = 0x8DFA;

  static final int SHADER_TYPE = 0x8B4F;

  static final int SHADING_LANGUAGE_VERSION = 0x8B8C;

  static final int SHORT = 0x1402;

  static final int SRC_ALPHA = 0x0302;

  static final int SRC_ALPHA_SATURATE = 0x0308;

  static final int SRC_COLOR = 0x0300;

  static final int STATIC_DRAW = 0x88E4;

  static final int STENCIL_ATTACHMENT = 0x8D20;

  static final int STENCIL_BACK_FAIL = 0x8801;

  static final int STENCIL_BACK_FUNC = 0x8800;

  static final int STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;

  static final int STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;

  static final int STENCIL_BACK_REF = 0x8CA3;

  static final int STENCIL_BACK_VALUE_MASK = 0x8CA4;

  static final int STENCIL_BACK_WRITEMASK = 0x8CA5;

  static final int STENCIL_BITS = 0x0D57;

  static final int STENCIL_BUFFER_BIT = 0x00000400;

  static final int STENCIL_CLEAR_VALUE = 0x0B91;

  static final int STENCIL_FAIL = 0x0B94;

  static final int STENCIL_FUNC = 0x0B92;

  static final int STENCIL_INDEX = 0x1901;

  static final int STENCIL_INDEX8 = 0x8D48;

  static final int STENCIL_PASS_DEPTH_FAIL = 0x0B95;

  static final int STENCIL_PASS_DEPTH_PASS = 0x0B96;

  static final int STENCIL_REF = 0x0B97;

  static final int STENCIL_TEST = 0x0B90;

  static final int STENCIL_VALUE_MASK = 0x0B93;

  static final int STENCIL_WRITEMASK = 0x0B98;

  static final int STREAM_DRAW = 0x88E0;

  static final int SUBPIXEL_BITS = 0x0D50;

  static final int TEXTURE = 0x1702;

  static final int TEXTURE0 = 0x84C0;

  static final int TEXTURE1 = 0x84C1;

  static final int TEXTURE10 = 0x84CA;

  static final int TEXTURE11 = 0x84CB;

  static final int TEXTURE12 = 0x84CC;

  static final int TEXTURE13 = 0x84CD;

  static final int TEXTURE14 = 0x84CE;

  static final int TEXTURE15 = 0x84CF;

  static final int TEXTURE16 = 0x84D0;

  static final int TEXTURE17 = 0x84D1;

  static final int TEXTURE18 = 0x84D2;

  static final int TEXTURE19 = 0x84D3;

  static final int TEXTURE2 = 0x84C2;

  static final int TEXTURE20 = 0x84D4;

  static final int TEXTURE21 = 0x84D5;

  static final int TEXTURE22 = 0x84D6;

  static final int TEXTURE23 = 0x84D7;

  static final int TEXTURE24 = 0x84D8;

  static final int TEXTURE25 = 0x84D9;

  static final int TEXTURE26 = 0x84DA;

  static final int TEXTURE27 = 0x84DB;

  static final int TEXTURE28 = 0x84DC;

  static final int TEXTURE29 = 0x84DD;

  static final int TEXTURE3 = 0x84C3;

  static final int TEXTURE30 = 0x84DE;

  static final int TEXTURE31 = 0x84DF;

  static final int TEXTURE4 = 0x84C4;

  static final int TEXTURE5 = 0x84C5;

  static final int TEXTURE6 = 0x84C6;

  static final int TEXTURE7 = 0x84C7;

  static final int TEXTURE8 = 0x84C8;

  static final int TEXTURE9 = 0x84C9;

  static final int TEXTURE_2D = 0x0DE1;

  static final int TEXTURE_BINDING_2D = 0x8069;

  static final int TEXTURE_BINDING_CUBE_MAP = 0x8514;

  static final int TEXTURE_CUBE_MAP = 0x8513;

  static final int TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;

  static final int TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;

  static final int TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;

  static final int TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;

  static final int TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;

  static final int TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;

  static final int TEXTURE_MAG_FILTER = 0x2800;

  static final int TEXTURE_MIN_FILTER = 0x2801;

  static final int TEXTURE_WRAP_S = 0x2802;

  static final int TEXTURE_WRAP_T = 0x2803;

  static final int TRIANGLES = 0x0004;

  static final int TRIANGLE_FAN = 0x0006;

  static final int TRIANGLE_STRIP = 0x0005;

  static final int UNPACK_ALIGNMENT = 0x0CF5;

  static final int UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;

  static final int UNPACK_FLIP_Y_WEBGL = 0x9240;

  static final int UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;

  static final int UNSIGNED_BYTE = 0x1401;

  static final int UNSIGNED_INT = 0x1405;

  static final int UNSIGNED_SHORT = 0x1403;

  static final int UNSIGNED_SHORT_4_4_4_4 = 0x8033;

  static final int UNSIGNED_SHORT_5_5_5_1 = 0x8034;

  static final int UNSIGNED_SHORT_5_6_5 = 0x8363;

  static final int VALIDATE_STATUS = 0x8B83;

  static final int VENDOR = 0x1F00;

  static final int VERSION = 0x1F02;

  static final int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

  static final int VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;

  static final int VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;

  static final int VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;

  static final int VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;

  static final int VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;

  static final int VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;

  static final int VERTEX_SHADER = 0x8B31;

  static final int VIEWPORT = 0x0BA2;

  static final int ZERO = 0;

  final int drawingBufferHeight;

  final int drawingBufferWidth;

  void activeTexture(int texture);

  void attachShader(WebGLProgram program, WebGLShader shader);

  void bindAttribLocation(WebGLProgram program, int index, String name);

  void bindBuffer(int target, WebGLBuffer buffer);

  void bindFramebuffer(int target, WebGLFramebuffer framebuffer);

  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer);

  void bindTexture(int target, WebGLTexture texture);

  void blendColor(num red, num green, num blue, num alpha);

  void blendEquation(int mode);

  void blendEquationSeparate(int modeRGB, int modeAlpha);

  void blendFunc(int sfactor, int dfactor);

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha);

  void bufferData(int target, var data_OR_size, int usage);

  void bufferSubData(int target, int offset, var data);

  int checkFramebufferStatus(int target);

  void clear(int mask);

  void clearColor(num red, num green, num blue, num alpha);

  void clearDepth(num depth);

  void clearStencil(int s);

  void colorMask(bool red, bool green, bool blue, bool alpha);

  void compileShader(WebGLShader shader);

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, ArrayBufferView data);

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, ArrayBufferView data);

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border);

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height);

  WebGLBuffer createBuffer();

  WebGLFramebuffer createFramebuffer();

  WebGLProgram createProgram();

  WebGLRenderbuffer createRenderbuffer();

  WebGLShader createShader(int type);

  WebGLTexture createTexture();

  void cullFace(int mode);

  void deleteBuffer(WebGLBuffer buffer);

  void deleteFramebuffer(WebGLFramebuffer framebuffer);

  void deleteProgram(WebGLProgram program);

  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer);

  void deleteShader(WebGLShader shader);

  void deleteTexture(WebGLTexture texture);

  void depthFunc(int func);

  void depthMask(bool flag);

  void depthRange(num zNear, num zFar);

  void detachShader(WebGLProgram program, WebGLShader shader);

  void disable(int cap);

  void disableVertexAttribArray(int index);

  void drawArrays(int mode, int first, int count);

  void drawElements(int mode, int count, int type, int offset);

  void enable(int cap);

  void enableVertexAttribArray(int index);

  void finish();

  void flush();

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, WebGLRenderbuffer renderbuffer);

  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level);

  void frontFace(int mode);

  void generateMipmap(int target);

  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index);

  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index);

  List getAttachedShaders(WebGLProgram program);

  int getAttribLocation(WebGLProgram program, String name);

  Object getBufferParameter(int target, int pname);

  WebGLContextAttributes getContextAttributes();

  int getError();

  Object getExtension(String name);

  Object getFramebufferAttachmentParameter(int target, int attachment, int pname);

  Object getParameter(int pname);

  String getProgramInfoLog(WebGLProgram program);

  Object getProgramParameter(WebGLProgram program, int pname);

  Object getRenderbufferParameter(int target, int pname);

  String getShaderInfoLog(WebGLShader shader);

  Object getShaderParameter(WebGLShader shader, int pname);

  String getShaderSource(WebGLShader shader);

  Object getTexParameter(int target, int pname);

  Object getUniform(WebGLProgram program, WebGLUniformLocation location);

  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name);

  Object getVertexAttrib(int index, int pname);

  int getVertexAttribOffset(int index, int pname);

  void hint(int target, int mode);

  bool isBuffer(WebGLBuffer buffer);

  bool isContextLost();

  bool isEnabled(int cap);

  bool isFramebuffer(WebGLFramebuffer framebuffer);

  bool isProgram(WebGLProgram program);

  bool isRenderbuffer(WebGLRenderbuffer renderbuffer);

  bool isShader(WebGLShader shader);

  bool isTexture(WebGLTexture texture);

  void lineWidth(num width);

  void linkProgram(WebGLProgram program);

  void pixelStorei(int pname, int param);

  void polygonOffset(num factor, num units);

  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels);

  void releaseShaderCompiler();

  void renderbufferStorage(int target, int internalformat, int width, int height);

  void sampleCoverage(num value, bool invert);

  void scissor(int x, int y, int width, int height);

  void shaderSource(WebGLShader shader, String string);

  void stencilFunc(int func, int ref, int mask);

  void stencilFuncSeparate(int face, int func, int ref, int mask);

  void stencilMask(int mask);

  void stencilMaskSeparate(int face, int mask);

  void stencilOp(int fail, int zfail, int zpass);

  void stencilOpSeparate(int face, int fail, int zfail, int zpass);

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels_OR_video, [int format, int type, ArrayBufferView pixels]);

  void texParameterf(int target, int pname, num param);

  void texParameteri(int target, int pname, int param);

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels_OR_video, [int type, ArrayBufferView pixels]);

  void uniform1f(WebGLUniformLocation location, num x);

  void uniform1fv(WebGLUniformLocation location, Float32Array v);

  void uniform1i(WebGLUniformLocation location, int x);

  void uniform1iv(WebGLUniformLocation location, Int32Array v);

  void uniform2f(WebGLUniformLocation location, num x, num y);

  void uniform2fv(WebGLUniformLocation location, Float32Array v);

  void uniform2i(WebGLUniformLocation location, int x, int y);

  void uniform2iv(WebGLUniformLocation location, Int32Array v);

  void uniform3f(WebGLUniformLocation location, num x, num y, num z);

  void uniform3fv(WebGLUniformLocation location, Float32Array v);

  void uniform3i(WebGLUniformLocation location, int x, int y, int z);

  void uniform3iv(WebGLUniformLocation location, Int32Array v);

  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w);

  void uniform4fv(WebGLUniformLocation location, Float32Array v);

  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w);

  void uniform4iv(WebGLUniformLocation location, Int32Array v);

  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array);

  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array);

  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array);

  void useProgram(WebGLProgram program);

  void validateProgram(WebGLProgram program);

  void vertexAttrib1f(int indx, num x);

  void vertexAttrib1fv(int indx, Float32Array values);

  void vertexAttrib2f(int indx, num x, num y);

  void vertexAttrib2fv(int indx, Float32Array values);

  void vertexAttrib3f(int indx, num x, num y, num z);

  void vertexAttrib3fv(int indx, Float32Array values);

  void vertexAttrib4f(int indx, num x, num y, num z, num w);

  void vertexAttrib4fv(int indx, Float32Array values);

  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset);

  void viewport(int x, int y, int width, int height);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLShader {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLTexture {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLUniformLocation {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLVertexArrayObjectOES {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitCSSRegionRule extends CSSRule {

  final CSSRuleList cssRules;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitNamedFlow {

  final bool overflow;

  NodeList getRegionsByContentNode(Node contentNode);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebSocket extends EventTarget default _WebSocketFactoryProvider {

  WebSocket(String url);

  WebSocketEvents get on();

  static final int CLOSED = 3;

  static final int CLOSING = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  final String URL;

  String binaryType;

  final int bufferedAmount;

  final String extensions;

  final String protocol;

  final int readyState;

  final String url;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]);

  void close([int code, String reason]);

  bool $dom_dispatchEvent(Event evt);

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]);

  bool send(String data);
}

interface WebSocketEvents extends Events {

  EventListenerList get close();

  EventListenerList get error();

  EventListenerList get message();

  EventListenerList get open();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WheelEvent extends UIEvent {

  final bool altKey;

  final int clientX;

  final int clientY;

  final bool ctrlKey;

  final bool metaKey;

  final int offsetX;

  final int offsetY;

  final int screenX;

  final int screenY;

  final bool shiftKey;

  final bool webkitDirectionInvertedFromDevice;

  final int wheelDelta;

  final int wheelDeltaX;

  final int wheelDeltaY;

  final int x;

  final int y;

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Window extends EventTarget {

  final Document document;

  /**
   * Executes a [callback] after the next batch of browser layout measurements
   * has completed or would have completed if any browser layout measurements
   * had been scheduled.
   */
  void requestLayoutFrame(TimeoutHandler callback);


  WindowEvents get on();

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final DOMApplicationCache applicationCache;

  final Navigator clientInformation;

  final bool closed;

  final Console console;

  final Crypto crypto;

  String defaultStatus;

  String defaultstatus;

  final num devicePixelRatio;

  final Event event;

  final Element frameElement;

  final Window frames;

  final History history;

  final int innerHeight;

  final int innerWidth;

  final int length;

  final Storage localStorage;

  Location location;

  final BarInfo locationbar;

  final BarInfo menubar;

  String name;

  final Navigator navigator;

  final bool offscreenBuffering;

  final Window opener;

  final int outerHeight;

  final int outerWidth;

  final int pageXOffset;

  final int pageYOffset;

  final Window parent;

  final Performance performance;

  final BarInfo personalbar;

  final Screen screen;

  final int screenLeft;

  final int screenTop;

  final int screenX;

  final int screenY;

  final int scrollX;

  final int scrollY;

  final BarInfo scrollbars;

  final Window self;

  final Storage sessionStorage;

  String status;

  final BarInfo statusbar;

  final StyleMedia styleMedia;

  final BarInfo toolbar;

  final Window top;

  final IDBFactory webkitIndexedDB;

  final NotificationCenter webkitNotifications;

  final StorageInfo webkitStorageInfo;

  final Window window;

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]);

  void alert(String message);

  String atob(String string);

  void blur();

  String btoa(String string);

  void captureEvents();

  void clearInterval(int handle);

  void clearTimeout(int handle);

  void close();

  bool confirm(String message);

  bool $dom_dispatchEvent(Event evt);

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog);

  void focus();

  CSSStyleDeclaration $dom_getComputedStyle(Element element, String pseudoElement);

  CSSRuleList getMatchedCSSRules(Element element, String pseudoElement);

  DOMSelection getSelection();

  MediaQueryList matchMedia(String query);

  void moveBy(num x, num y);

  void moveTo(num x, num y);

  Window open(String url, String name, [String options]);

  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]);

  void postMessage(Dynamic message, String targetOrigin, [List messagePorts]);

  void print();

  String prompt(String message, String defaultValue);

  void releaseEvents();

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]);

  void resizeBy(num x, num y);

  void resizeTo(num width, num height);

  void scroll(int x, int y);

  void scrollBy(int x, int y);

  void scrollTo(int x, int y);

  int setInterval(TimeoutHandler handler, int timeout);

  int setTimeout(TimeoutHandler handler, int timeout);

  Object showModalDialog(String url, [Object dialogArgs, String featureArgs]);

  void stop();

  void webkitCancelAnimationFrame(int id);

  void webkitCancelRequestAnimationFrame(int id);

  Point webkitConvertPointFromNodeToPage(Node node, Point p);

  Point webkitConvertPointFromPageToNode(Node node, Point p);

  void webkitPostMessage(Dynamic message, String targetOrigin, [List transferList]);

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, Element element);

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback]);

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback, ErrorCallback errorCallback]);

}

interface WindowEvents extends Events {

  EventListenerList get abort();

  EventListenerList get animationEnd();

  EventListenerList get animationIteration();

  EventListenerList get animationStart();

  EventListenerList get beforeUnload();

  EventListenerList get blur();

  EventListenerList get canPlay();

  EventListenerList get canPlayThrough();

  EventListenerList get change();

  EventListenerList get click();

  EventListenerList get contentLoaded();

  EventListenerList get contextMenu();

  EventListenerList get deviceMotion();

  EventListenerList get deviceOrientation();

  EventListenerList get doubleClick();

  EventListenerList get drag();

  EventListenerList get dragEnd();

  EventListenerList get dragEnter();

  EventListenerList get dragLeave();

  EventListenerList get dragOver();

  EventListenerList get dragStart();

  EventListenerList get drop();

  EventListenerList get durationChange();

  EventListenerList get emptied();

  EventListenerList get ended();

  EventListenerList get error();

  EventListenerList get focus();

  EventListenerList get hashChange();

  EventListenerList get input();

  EventListenerList get invalid();

  EventListenerList get keyDown();

  EventListenerList get keyPress();

  EventListenerList get keyUp();

  EventListenerList get load();

  EventListenerList get loadStart();

  EventListenerList get loadedData();

  EventListenerList get loadedMetadata();

  EventListenerList get message();

  EventListenerList get mouseDown();

  EventListenerList get mouseMove();

  EventListenerList get mouseOut();

  EventListenerList get mouseOver();

  EventListenerList get mouseUp();

  EventListenerList get mouseWheel();

  EventListenerList get offline();

  EventListenerList get online();

  EventListenerList get pageHide();

  EventListenerList get pageShow();

  EventListenerList get pause();

  EventListenerList get play();

  EventListenerList get playing();

  EventListenerList get popState();

  EventListenerList get progress();

  EventListenerList get rateChange();

  EventListenerList get reset();

  EventListenerList get resize();

  EventListenerList get scroll();

  EventListenerList get search();

  EventListenerList get seeked();

  EventListenerList get seeking();

  EventListenerList get select();

  EventListenerList get stalled();

  EventListenerList get storage();

  EventListenerList get submit();

  EventListenerList get suspend();

  EventListenerList get timeUpdate();

  EventListenerList get touchCancel();

  EventListenerList get touchEnd();

  EventListenerList get touchMove();

  EventListenerList get touchStart();

  EventListenerList get transitionEnd();

  EventListenerList get unload();

  EventListenerList get volumeChange();

  EventListenerList get waiting();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Worker extends AbstractWorker default _WorkerFactoryProvider {

  Worker(String scriptUrl);

  WorkerEvents get on();

  void postMessage(Dynamic message, [List messagePorts]);

  void terminate();

  void webkitPostMessage(Dynamic message, [List messagePorts]);
}

interface WorkerEvents extends AbstractWorkerEvents {

  EventListenerList get message();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WorkerContext {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final WorkerLocation location;

  final WorkerNavigator navigator;

  EventListener onerror;

  final WorkerContext self;

  final IDBFactory webkitIndexedDB;

  final NotificationCenter webkitNotifications;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void clearInterval(int handle);

  void clearTimeout(int handle);

  void close();

  bool dispatchEvent(Event evt);

  void importScripts();

  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]);

  DatabaseSync openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  int setInterval(TimeoutHandler handler, int timeout);

  int setTimeout(TimeoutHandler handler, int timeout);

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback, ErrorCallback errorCallback]);

  DOMFileSystemSync webkitRequestFileSystemSync(int type, int size);

  EntrySync webkitResolveLocalFileSystemSyncURL(String url);

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback, ErrorCallback errorCallback]);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WorkerLocation {

  final String hash;

  final String host;

  final String hostname;

  final String href;

  final String pathname;

  final String port;

  final String protocol;

  final String search;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WorkerNavigator {

  final String appName;

  final String appVersion;

  final bool onLine;

  final String platform;

  final String userAgent;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequest extends EventTarget default _XMLHttpRequestFactoryProvider {
  // TODO(rnystrom): This name should just be "get" which is valid in Dart, but
  // not correctly implemented yet. (b/4970173)
  XMLHttpRequest.getTEMPNAME(String url, onSuccess(XMLHttpRequest request));

  XMLHttpRequest();

  XMLHttpRequestEvents get on();

  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  bool asBlob;

  final int readyState;

  final Object response;

  final Blob responseBlob;

  final String responseText;

  String responseType;

  final Document responseXML;

  final int status;

  final String statusText;

  final XMLHttpRequestUpload upload;

  bool withCredentials;

  void abort();

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]);

  bool $dom_dispatchEvent(Event evt);

  String getAllResponseHeaders();

  String getResponseHeader(String header);

  void open(String method, String url, [bool async, String user, String password]);

  void overrideMimeType(String override);

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]);

  void send([var data]);

  void setRequestHeader(String header, String value);
}

interface XMLHttpRequestEvents extends Events {

  EventListenerList get abort();

  EventListenerList get error();

  EventListenerList get load();

  EventListenerList get loadEnd();

  EventListenerList get loadStart();

  EventListenerList get progress();

  EventListenerList get readyStateChange();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequestException {

  static final int ABORT_ERR = 102;

  static final int NETWORK_ERR = 101;

  final int code;

  final String message;

  final String name;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequestProgressEvent extends ProgressEvent {

  final int position;

  final int totalSize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequestUpload extends EventTarget {

  XMLHttpRequestUploadEvents get on();

  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]);

  bool $dom_dispatchEvent(Event evt);

  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]);
}

interface XMLHttpRequestUploadEvents extends Events {

  EventListenerList get abort();

  EventListenerList get error();

  EventListenerList get load();

  EventListenerList get loadEnd();

  EventListenerList get loadStart();

  EventListenerList get progress();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLSerializer default _XMLSerializerFactoryProvider {

  XMLSerializer();

  String serializeToString(Node node);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XPathEvaluator default _XPathEvaluatorFactoryProvider {

  XPathEvaluator();

  XPathExpression createExpression(String expression, XPathNSResolver resolver);

  XPathNSResolver createNSResolver(Node nodeResolver);

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XPathException {

  static final int INVALID_EXPRESSION_ERR = 51;

  static final int TYPE_ERR = 52;

  final int code;

  final String message;

  final String name;

  String toString();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XPathExpression {

  XPathResult evaluate(Node contextNode, int type, XPathResult inResult);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XPathNSResolver {

  String lookupNamespaceURI(String prefix);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XPathResult {

  static final int ANY_TYPE = 0;

  static final int ANY_UNORDERED_NODE_TYPE = 8;

  static final int BOOLEAN_TYPE = 3;

  static final int FIRST_ORDERED_NODE_TYPE = 9;

  static final int NUMBER_TYPE = 1;

  static final int ORDERED_NODE_ITERATOR_TYPE = 5;

  static final int ORDERED_NODE_SNAPSHOT_TYPE = 7;

  static final int STRING_TYPE = 2;

  static final int UNORDERED_NODE_ITERATOR_TYPE = 4;

  static final int UNORDERED_NODE_SNAPSHOT_TYPE = 6;

  final bool booleanValue;

  final bool invalidIteratorState;

  final num numberValue;

  final int resultType;

  final Node singleNodeValue;

  final int snapshotLength;

  final String stringValue;

  Node iterateNext();

  Node snapshotItem(int index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XSLTProcessor default _XSLTProcessorFactoryProvider {

  XSLTProcessor();

  void clearParameters();

  String getParameter(String namespaceURI, String localName);

  void importStylesheet(Node stylesheet);

  void removeParameter(String namespaceURI, String localName);

  void reset();

  void setParameter(String namespaceURI, String localName, String value);

  Document transformToDocument(Node source);

  DocumentFragment transformToFragment(Node source, Document docVal);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void EventListener(Event event);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines the standard key locations returned by
 * KeyboardEvent.getKeyLocation.
 */
interface KeyLocation {

  /**
   * The event key is not distinguished as the left or right version
   * of the key, and did not originate from the numeric keypad (or did not
   * originate with a virtual key corresponding to the numeric keypad).
   */
  static final int STANDARD = 0;

  /**
   * The event key is in the left key location.
   */
  static final int LEFT = 1;

  /**
   * The event key is in the right key location.
   */
  static final int RIGHT = 2;

  /**
   * The event key originated on the numeric keypad or with a virtual key
   * corresponding to the numeric keypad.
   */
  static final int NUMPAD = 3;

  /**
   * The event key originated on a mobile device, either on a physical
   * keypad or a virtual keyboard.
   */
  static final int MOBILE = 4;

  /**
   * The event key originated on a game controller or a joystick on a mobile
   * device.
   */
  static final int JOYSTICK = 5;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines the standard keyboard identifier names for keys that are returned
 * by KeyEvent.getKeyboardIdentifier when the key does not have a direct
 * unicode mapping.
 */
interface KeyName {

  /** The Accept (Commit, OK) key */
  static final String ACCEPT = "Accept";

  /** The Add key */
  static final String ADD = "Add";

  /** The Again key */
  static final String AGAIN = "Again";

  /** The All Candidates key */
  static final String ALL_CANDIDATES = "AllCandidates";

  /** The Alphanumeric key */
  static final String ALPHANUMERIC = "Alphanumeric";

  /** The Alt (Menu) key */
  static final String ALT = "Alt";

  /** The Alt-Graph key */
  static final String ALT_GRAPH = "AltGraph";

  /** The Application key */
  static final String APPS = "Apps";

  /** The ATTN key */
  static final String ATTN = "Attn";

  /** The Browser Back key */
  static final String BROWSER_BACK = "BrowserBack";

  /** The Browser Favorites key */
  static final String BROWSER_FAVORTIES = "BrowserFavorites";

  /** The Browser Forward key */
  static final String BROWSER_FORWARD = "BrowserForward";

  /** The Browser Home key */
  static final String BROWSER_NAME = "BrowserHome";

  /** The Browser Refresh key */
  static final String BROWSER_REFRESH = "BrowserRefresh";

  /** The Browser Search key */
  static final String BROWSER_SEARCH = "BrowserSearch";

  /** The Browser Stop key */
  static final String BROWSER_STOP = "BrowserStop";

  /** The Camera key */
  static final String CAMERA = "Camera";

  /** The Caps Lock (Capital) key */
  static final String CAPS_LOCK = "CapsLock";

  /** The Clear key */
  static final String CLEAR = "Clear";

  /** The Code Input key */
  static final String CODE_INPUT = "CodeInput";

  /** The Compose key */
  static final String COMPOSE = "Compose";

  /** The Control (Ctrl) key */
  static final String CONTROL = "Control";

  /** The Crsel key */
  static final String CRSEL = "Crsel";

  /** The Convert key */
  static final String CONVERT = "Convert";

  /** The Copy key */
  static final String COPY = "Copy";

  /** The Cut key */
  static final String CUT = "Cut";

  /** The Decimal key */
  static final String DECIMAL = "Decimal";

  /** The Divide key */
  static final String DIVIDE = "Divide";

  /** The Down Arrow key */
  static final String DOWN = "Down";

  /** The diagonal Down-Left Arrow key */
  static final String DOWN_LEFT = "DownLeft";

  /** The diagonal Down-Right Arrow key */
  static final String DOWN_RIGHT = "DownRight";

  /** The Eject key */
  static final String EJECT = "Eject";

  /** The End key */
  static final String END = "End";

  /**
   * The Enter key. Note: This key value must also be used for the Return
   *  (Macintosh numpad) key
   */
  static final String ENTER = "Enter";

  /** The Erase EOF key */
  static final String ERASE_EOF= "EraseEof";

  /** The Execute key */
  static final String EXECUTE = "Execute";

  /** The Exsel key */
  static final String EXSEL = "Exsel";

  /** The Function switch key */
  static final String FN = "Fn";

  /** The F1 key */
  static final String F1 = "F1";

  /** The F2 key */
  static final String F2 = "F2";

  /** The F3 key */
  static final String F3 = "F3";

  /** The F4 key */
  static final String F4 = "F4";

  /** The F5 key */
  static final String F5 = "F5";

  /** The F6 key */
  static final String F6 = "F6";

  /** The F7 key */
  static final String F7 = "F7";

  /** The F8 key */
  static final String F8 = "F8";

  /** The F9 key */
  static final String F9 = "F9";

  /** The F10 key */
  static final String F10 = "F10";

  /** The F11 key */
  static final String F11 = "F11";

  /** The F12 key */
  static final String F12 = "F12";

  /** The F13 key */
  static final String F13 = "F13";

  /** The F14 key */
  static final String F14 = "F14";

  /** The F15 key */
  static final String F15 = "F15";

  /** The F16 key */
  static final String F16 = "F16";

  /** The F17 key */
  static final String F17 = "F17";

  /** The F18 key */
  static final String F18 = "F18";

  /** The F19 key */
  static final String F19 = "F19";

  /** The F20 key */
  static final String F20 = "F20";

  /** The F21 key */
  static final String F21 = "F21";

  /** The F22 key */
  static final String F22 = "F22";

  /** The F23 key */
  static final String F23 = "F23";

  /** The F24 key */
  static final String F24 = "F24";

  /** The Final Mode (Final) key used on some asian keyboards */
  static final String FINAL_MODE = "FinalMode";

  /** The Find key */
  static final String FIND = "Find";

  /** The Full-Width Characters key */
  static final String FULL_WIDTH = "FullWidth";

  /** The Half-Width Characters key */
  static final String HALF_WIDTH = "HalfWidth";

  /** The Hangul (Korean characters) Mode key */
  static final String HANGUL_MODE = "HangulMode";

  /** The Hanja (Korean characters) Mode key */
  static final String HANJA_MODE = "HanjaMode";

  /** The Help key */
  static final String HELP = "Help";

  /** The Hiragana (Japanese Kana characters) key */
  static final String HIRAGANA = "Hiragana";

  /** The Home key */
  static final String HOME = "Home";

  /** The Insert (Ins) key */
  static final String INSERT = "Insert";

  /** The Japanese-Hiragana key */
  static final String JAPANESE_HIRAGANA = "JapaneseHiragana";

  /** The Japanese-Katakana key */
  static final String JAPANESE_KATAKANA = "JapaneseKatakana";

  /** The Japanese-Romaji key */
  static final String JAPANESE_ROMAJI = "JapaneseRomaji";

  /** The Junja Mode key */
  static final String JUNJA_MODE = "JunjaMode";

  /** The Kana Mode (Kana Lock) key */
  static final String KANA_MODE = "KanaMode";

  /**
   * The Kanji (Japanese name for ideographic characters of Chinese origin)
   * Mode key
   */
  static final String KANJI_MODE = "KanjiMode";

  /** The Katakana (Japanese Kana characters) key */
  static final String KATAKANA = "Katakana";

  /** The Start Application One key */
  static final String LAUNCH_APPLICATION_1 = "LaunchApplication1";

  /** The Start Application Two key */
  static final String LAUNCH_APPLICATION_2 = "LaunchApplication2";

  /** The Start Mail key */
  static final String LAUNCH_MAIL = "LaunchMail";

  /** The Left Arrow key */
  static final String LEFT = "Left";

  /** The Menu key */
  static final String MENU = "Menu";

  /**
   * The Meta key. Note: This key value shall be also used for the Apple
   * Command key
   */
  static final String META = "Meta";

  /** The Media Next Track key */
  static final String MEDIA_NEXT_TRACK = "MediaNextTrack";

  /** The Media Play Pause key */
  static final String MEDIA_PAUSE_PLAY = "MediaPlayPause";

  /** The Media Previous Track key */
  static final String MEDIA_PREVIOUS_TRACK = "MediaPreviousTrack";

  /** The Media Stop key */
  static final String MEDIA_STOP = "MediaStop";

  /** The Mode Change key */
  static final String MODE_CHANGE = "ModeChange";

  /** The Next Candidate function key */
  static final String NEXT_CANDIDATE = "NextCandidate";

  /** The Nonconvert (Don't Convert) key */
  static final String NON_CONVERT = "Nonconvert";

  /** The Number Lock key */
  static final String NUM_LOCK = "NumLock";

  /** The Page Down (Next) key */
  static final String PAGE_DOWN = "PageDown";

  /** The Page Up key */
  static final String PAGE_UP = "PageUp";

  /** The Paste key */
  static final String PASTE = "Paste";

  /** The Pause key */
  static final String PAUSE = "Pause";

  /** The Play key */
  static final String PLAY = "Play";

  /**
   * The Power key. Note: Some devices may not expose this key to the
   * operating environment
   */
  static final String POWER = "Power";

  /** The Previous Candidate function key */
  static final String PREVIOUS_CANDIDATE = "PreviousCandidate";

  /** The Print Screen (PrintScrn, SnapShot) key */
  static final String PRINT_SCREEN = "PrintScreen";

  /** The Process key */
  static final String PROCESS = "Process";

  /** The Props key */
  static final String PROPS = "Props";

  /** The Right Arrow key */
  static final String RIGHT = "Right";

  /** The Roman Characters function key */
  static final String ROMAN_CHARACTERS = "RomanCharacters";

  /** The Scroll Lock key */
  static final String SCROLL = "Scroll";

  /** The Select key */
  static final String SELECT = "Select";

  /** The Select Media key */
  static final String SELECT_MEDIA = "SelectMedia";

  /** The Separator key */
  static final String SEPARATOR = "Separator";

  /** The Shift key */
  static final String SHIFT = "Shift";

  /** The Soft1 key */
  static final String SOFT_1 = "Soft1";

  /** The Soft2 key */
  static final String SOFT_2 = "Soft2";

  /** The Soft3 key */
  static final String SOFT_3 = "Soft3";

  /** The Soft4 key */
  static final String SOFT_4 = "Soft4";

  /** The Stop key */
  static final String STOP = "Stop";

  /** The Subtract key */
  static final String SUBTRACT = "Subtract";

  /** The Symbol Lock key */
  static final String SYMBOL_LOCK = "SymbolLock";

  /** The Up Arrow key */
  static final String UP = "Up";

  /** The diagonal Up-Left Arrow key */
  static final String UP_LEFT = "UpLeft";

  /** The diagonal Up-Right Arrow key */
  static final String UP_RIGHT = "UpRight";

  /** The Undo key */
  static final String UNDO = "Undo";

  /** The Volume Down key */
  static final String VOLUME_DOWN = "VolumeDown";

  /** The Volume Mute key */
  static final String VOLUMN_MUTE = "VolumeMute";

  /** The Volume Up key */
  static final String VOLUMN_UP = "VolumeUp";

  /** The Windows Logo key */
  static final String WIN = "Win";

  /** The Zoom key */
  static final String ZOOM = "Zoom";

  /**
   * The Backspace (Back) key. Note: This key value shall be also used for the
   * key labeled 'delete' MacOS keyboards when not modified by the 'Fn' key
   */
  static final String BACKSPACE = "Backspace";

  /** The Horizontal Tabulation (Tab) key */
  static final String TAB = "Tab";

  /** The Cancel key */
  static final String CANCEL = "Cancel";

  /** The Escape (Esc) key */
  static final String ESC = "Esc";

  /** The Space (Spacebar) key:   */
  static final String SPACEBAR = "Spacebar";

  /**
   * The Delete (Del) Key. Note: This key value shall be also used for the key
   * labeled 'delete' MacOS keyboards when modified by the 'Fn' key
   */
  static final String DEL = "Del";

  /** The Combining Grave Accent (Greek Varia, Dead Grave) key */
  static final String DEAD_GRAVE = "DeadGrave";

  /**
   * The Combining Acute Accent (Stress Mark, Greek Oxia, Tonos, Dead Eacute)
   * key
   */
  static final String DEAD_EACUTE = "DeadEacute";

  /** The Combining Circumflex Accent (Hat, Dead Circumflex) key */
  static final String DEAD_CIRCUMFLEX = "DeadCircumflex";

  /** The Combining Tilde (Dead Tilde) key */
  static final String DEAD_TILDE = "DeadTilde";

  /** The Combining Macron (Long, Dead Macron) key */
  static final String DEAD_MACRON = "DeadMacron";

  /** The Combining Breve (Short, Dead Breve) key */
  static final String DEAD_BREVE = "DeadBreve";

  /** The Combining Dot Above (Derivative, Dead Above Dot) key */
  static final String DEAD_ABOVE_DOT = "DeadAboveDot";

  /**
   * The Combining Diaeresis (Double Dot Abode, Umlaut, Greek Dialytika,
   * Double Derivative, Dead Diaeresis) key
   */
  static final String DEAD_UMLAUT = "DeadUmlaut";

  /** The Combining Ring Above (Dead Above Ring) key */
  static final String DEAD_ABOVE_RING = "DeadAboveRing";

  /** The Combining Double Acute Accent (Dead Doubleacute) key */
  static final String DEAD_DOUBLEACUTE = "DeadDoubleacute";

  /** The Combining Caron (Hacek, V Above, Dead Caron) key */
  static final String DEAD_CARON = "DeadCaron";

  /** The Combining Cedilla (Dead Cedilla) key */
  static final String DEAD_CEDILLA = "DeadCedilla";

  /** The Combining Ogonek (Nasal Hook, Dead Ogonek) key */
  static final String DEAD_OGONEK = "DeadOgonek";

  /**
   * The Combining Greek Ypogegrammeni (Greek Non-Spacing Iota Below, Iota
   * Subscript, Dead Iota) key
   */
  static final String DEAD_IOTA = "DeadIota";

  /**
   * The Combining Katakana-Hiragana Voiced Sound Mark (Dead Voiced Sound) key
   */
  static final String DEAD_VOICED_SOUND = "DeadVoicedSound";

  /**
   * The Combining Katakana-Hiragana Semi-Voiced Sound Mark (Dead Semivoiced
   * Sound) key
   */
  static final String DEC_SEMIVOICED_SOUND= "DeadSemivoicedSound";

  /**
   * Key value used when an implementation is unable to identify another key
   * value, due to either hardware, platform, or software constraints
   */
  static final String UNIDENTIFIED = "Unidentified";
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Contains the set of standard values returned by HTMLDocument.getReadyState.
 */
interface ReadyState {
  /**
   * Indicates the document is still loading and parsing.
   */
  static final String LOADING = "loading";

  /**
   * Indicates the document is finished parsing but is still loading
   * subresources.
   */
  static final String INTERACTIVE = "interactive";

  /**
   * Indicates the document and all subresources have been loaded.
   */
  static final String COMPLETE = "complete";
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void TimeoutHandler();
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The [Collections] class implements static methods useful when
 * writing a class that implements [Collection] and the [iterator]
 * method.
 */
class _Collections {
  static void forEach(Iterable<Object> iterable, void f(Object o)) {
    for (final e in iterable) {
      f(e);
    }
  }

  static List map(Iterable<Object> source,
                  List<Object> destination,
                  f(o)) {
    for (final e in source) {
      destination.add(f(e));
    }
    return destination;
  }

  static bool some(Iterable<Object> iterable, bool f(Object o)) {
    for (final e in iterable) {
      if (f(e)) return true;
    }
    return false;
  }

  static bool every(Iterable<Object> iterable, bool f(Object o)) {
    for (final e in iterable) {
      if (!f(e)) return false;
    }
    return true;
  }

  static List filter(Iterable<Object> source,
                     List<Object> destination,
                     bool f(o)) {
    for (final e in source) {
      if (f(e)) destination.add(e);
    }
    return destination;
  }

  static bool isEmpty(Iterable<Object> iterable) {
    return !iterable.iterator().hasNext();
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _XMLHttpRequestUtils {

  // Helper for factory XMLHttpRequest.getTEMPNAME
  static XMLHttpRequest getTEMPNAME(String url,
                                    onSuccess(XMLHttpRequest request)) {
    final request = new XMLHttpRequest();
    request.open('GET', url, true);

    // TODO(terry): Validate after client login added if necessary to forward
    //              cookies to server.
    request.withCredentials = true;

    // Status 0 is for local XHR request.
    request.on.readyStateChange.add((e) {
      if (request.readyState == XMLHttpRequest.DONE &&
          (request.status == 200 || request.status == 0)) {
        onSuccess(request);
      }
    });

    request.send();

    return request;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Object ComputeValue();

class _MeasurementRequest<T> {
  final ComputeValue computeValue;
  final Completer<T> completer;
  Object value;
  bool exception = false;
  _MeasurementRequest(this.computeValue, this.completer);
}

final _MEASUREMENT_MESSAGE = "DART-MEASURE";
List<_MeasurementRequest> _pendingRequests;
List<TimeoutHandler> _pendingMeasurementFrameCallbacks;
bool _nextMeasurementFrameScheduled = false;
bool _firstMeasurementRequest = true;

void _maybeScheduleMeasurementFrame() {
  if (_nextMeasurementFrameScheduled) return;

  _nextMeasurementFrameScheduled = true;
  // postMessage gives us a way to receive a callback after the current
  // event listener has unwound but before the browser has repainted.
  if (_firstMeasurementRequest) {
    // Messages from other windows do not cause a security risk as
    // all we care about is that _onCompleteMeasurementRequests is called
    // after the current event loop is unwound and calling the function is
    // a noop when zero requests are pending.
    window.on.message.add((e) => _completeMeasurementFutures());
    _firstMeasurementRequest = false;
  }

  // TODO(jacobr): other mechanisms such as setImmediate and
  // requestAnimationFrame may work better of platforms that support them.
  // The key is we need a way to execute code immediately after the current
  // event listener queue unwinds.
  window.postMessage(_MEASUREMENT_MESSAGE, "*");
}

/**
 * Registers a [callback] which is called after the next batch of measurements
 * completes. Even if no measurements completed, the callback is triggered
 * when they would have completed to avoid confusing bugs if it happened that
 * no measurements were actually requested.
 */
void _addMeasurementFrameCallback(TimeoutHandler callback) {
  if (_pendingMeasurementFrameCallbacks === null) {
    _pendingMeasurementFrameCallbacks = <TimeoutHandler>[];
    _maybeScheduleMeasurementFrame();
  }
  _pendingMeasurementFrameCallbacks.add(callback);
}

/**
 * Returns a [Future] whose value will be the result of evaluating
 * [computeValue] during the next safe measurement interval.
 * The next safe measurement interval is after the current event loop has
 * unwound but before the browser has rendered the page.
 * It is important that the [computeValue] function only queries the html
 * layout and html in any way.
 */
Future _createMeasurementFuture(ComputeValue computeValue,
                                Completer completer) {
  if (_pendingRequests === null) {
    _pendingRequests = <_MeasurementRequest>[];
    _maybeScheduleMeasurementFrame();
  }
  _pendingRequests.add(new _MeasurementRequest(computeValue, completer));
  return completer.future;
}

/**
 * Complete all pending measurement futures evaluating them in a single batch
 * so that the the browser is guaranteed to avoid multiple layouts.
 */
void _completeMeasurementFutures() {
  if (_nextMeasurementFrameScheduled == false) {
    // Ignore spurious call to this function.
    return;
  }

  _nextMeasurementFrameScheduled = false;
  // We must compute all new values before fulfilling the futures as
  // the onComplete callbacks for the futures could modify the DOM making
  // subsequent measurement calculations expensive to compute.
  if (_pendingRequests !== null) {
    for (_MeasurementRequest request in _pendingRequests) {
      try {
        request.value = request.computeValue();
      } catch(var e) {
        request.value = e;
        request.exception = true;
      }
    }
  }

  final completedRequests = _pendingRequests;
  final readyMeasurementFrameCallbacks = _pendingMeasurementFrameCallbacks;
  _pendingRequests = null;
  _pendingMeasurementFrameCallbacks = null;
  if (completedRequests !== null) {
    for (_MeasurementRequest request in completedRequests) {
      if (request.exception) {
        request.completer.completeException(request.value);
      } else {
        request.completer.complete(request.value);
      }
    }
  }

  if (readyMeasurementFrameCallbacks !== null) {
    for (TimeoutHandler handler in readyMeasurementFrameCallbacks) {
      // TODO(jacobr): wrap each call to a handler in a try-catch block.
      handler();
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _EventFactoryProvider {
  factory Event(String type, [bool canBubble = true,
      bool cancelable = true]) {
    final _EventImpl e = _document.$dom_createEvent("Event");
    e.$dom_initEvent(type, canBubble, cancelable);
    return e;
  }
}

class _MouseEventFactoryProvider {
  factory MouseEvent(String type, Window view, int detail,
      int screenX, int screenY, int clientX, int clientY, int button,
      [bool canBubble = true, bool cancelable = true, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) {
    final e = _document.$dom_createEvent("MouseEvent");
    e.$dom_initMouseEvent(type, canBubble, cancelable, view, detail,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey,
        button, relatedTarget);
    return e;
  }
}

class _CSSStyleDeclarationFactoryProvider {
  factory CSSStyleDeclaration.css(String css) {
    final style = new Element.tag('div').style;
    style.cssText = css;
    return style;
  } 

  factory CSSStyleDeclaration() {
    return new CSSStyleDeclaration.css('');
  }
}

class _DocumentFragmentFactoryProvider {
  /** @domName Document.createDocumentFragment */
  factory DocumentFragment() => document.createDocumentFragment();

  factory DocumentFragment.html(String html) {
    final fragment = new DocumentFragment();
    fragment.innerHTML = html;
    return fragment;
  }

  // TODO(nweiz): enable this when XML is ported.
  // factory DocumentFragment.xml(String xml) {
  //   final fragment = new DocumentFragment();
  //   final e = new XMLElement.tag("xml");
  //   e.innerHTML = xml;
  //
  //   // Copy list first since we don't want liveness during iteration.
  //   final List nodes = new List.from(e.nodes);
  //   fragment.nodes.addAll(nodes);
  //   return fragment;
  // }

  factory DocumentFragment.svg(String svg) {
    final fragment = new DocumentFragment();
    final e = new SVGSVGElement();
    e.innerHTML = svg;

    // Copy list first since we don't want liveness during iteration.
    final List nodes = new List.from(e.nodes);
    fragment.nodes.addAll(nodes);
    return fragment;
  }
}

class _SVGElementFactoryProvider {
  factory SVGElement.tag(String tag) {
    final Element temp =
      _document.$dom_createElementNS("http://www.w3.org/2000/svg", tag);
    return temp;
  }

  factory SVGElement.svg(String svg) {
    Element parentTag;
    final match = _START_TAG_REGEXP.firstMatch(svg);
    if (match != null && match.group(1).toLowerCase() == 'svg') {
      parentTag = new Element.tag('div');
    } else {
      parentTag = new SVGSVGElement();
    }

    parentTag.innerHTML = svg;
    if (parentTag.elements.length == 1) return parentTag.nodes.removeLast();

    throw new IllegalArgumentException('SVG had ${parentTag.elements.length} ' +
        'top-level elements but 1 expected');
  }
}

class _SVGSVGElementFactoryProvider {
  factory SVGSVGElement() {
    final el = new SVGElement.tag("svg");
    // The SVG spec requires the version attribute to match the spec version
    el.attributes['version'] = "1.1";
    return el;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AudioContextFactoryProvider {

  factory AudioContext() native '''
    var constructor = window.AudioContext || window.webkitAudioContext;
    return new constructor();
''';
}

class _TypedArrayFactoryProvider {

  factory Float32Array(int length) => _F32(length);
  factory Float32Array.fromList(List<num> list) => _F32(ensureNative(list));
  factory Float32Array.fromBuffer(ArrayBuffer buffer) => _F32(buffer);

  factory Float64Array(int length) => _F64(length);
  factory Float64Array.fromList(List<num> list) => _F64(ensureNative(list));
  factory Float64Array.fromBuffer(ArrayBuffer buffer) => _F64(buffer);

  factory Int8Array(int length) => _I8(length);
  factory Int8Array.fromList(List<num> list) => _I8(ensureNative(list));
  factory Int8Array.fromBuffer(ArrayBuffer buffer) => _I8(buffer);

  factory Int16Array(int length) => _I16(length);
  factory Int16Array.fromList(List<num> list) => _I16(ensureNative(list));
  factory Int16Array.fromBuffer(ArrayBuffer buffer) => _I16(buffer);

  factory Int32Array(int length) => _I32(length);
  factory Int32Array.fromList(List<num> list) => _I32(ensureNative(list));
  factory Int32Array.fromBuffer(ArrayBuffer buffer) => _I32(buffer);

  factory Uint8Array(int length) => _U8(length);
  factory Uint8Array.fromList(List<num> list) => _U8(ensureNative(list));
  factory Uint8Array.fromBuffer(ArrayBuffer buffer) => _U8(buffer);

  factory Uint16Array(int length) => _U16(length);
  factory Uint16Array.fromList(List<num> list) => _U16(ensureNative(list));
  factory Uint16Array.fromBuffer(ArrayBuffer buffer) => _U16(buffer);

  factory Uint32Array(int length) => _U32(length);
  factory Uint32Array.fromList(List<num> list) => _U32(ensureNative(list));
  factory Uint32Array.fromBuffer(ArrayBuffer buffer) => _U32(buffer);

  factory Uint8ClampedArray(int length) => _U8C(length);
  factory Uint8ClampedArray.fromList(List<num> list) => _U8C(ensureNative(list));
  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer) => _U8C(buffer);

  static Float32Array _F32(arg) native 'return new Float32Array(arg);';
  static Float64Array _F64(arg) native 'return new Float64Array(arg);';
  static Int8Array _I8(arg) native 'return new Int8Array(arg);';
  static Int16Array _I16(arg) native 'return new Int16Array(arg);';
  static Int32Array _I32(arg) native 'return new Int32Array(arg);';
  static Uint8Array _U8(arg) native 'return new Uint8Array(arg);';
  static Uint16Array _U16(arg) native 'return new Uint16Array(arg);';
  static Uint32Array _U32(arg) native 'return new Uint32Array(arg);';
  static Uint8ClampedArray _U8C(arg) native 'return new Uint8ClampedArray(arg);';

  static ensureNative(List list) => list;  // TODO: make sure.
}

class _PointFactoryProvider {

  factory Point(num x, num y) native 'return new WebKitPoint(x, y);';
}

class _WebSocketFactoryProvider {

  factory WebSocket(String url) native '''return new WebSocket(url);''';
}

class _TextFactoryProvider {
  factory Text(String data) native "return document.createTextNode(data);";
}// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(rnystrom): add a way to supress public classes from DartDoc output.
// TODO(jacobr): we can remove this class now that we are using the $dom_
// convention for deprecated methods rather than truly private methods.
/**
 * This class is intended for testing purposes only.
 */
class Testing {
  static void addEventListener(EventTarget target, String type, EventListener listener, bool useCapture) {
    final _EventTargetImpl targetImpl = target;
    targetImpl.$dom_addEventListener(type, listener, useCapture);
  }
  static void removeEventListener(EventTarget target, String type, EventListener listener, bool useCapture) {
    final _EventTargetImpl targetImpl = target;
    targetImpl.$dom_removeEventListener(type, listener, useCapture);
  }

}// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Utils for device detection.
 */
class _Device {
  /**
   * Gets the browser's user agent. Using this function allows tests to inject
   * the user agent.
   * Returns the user agent.
   */
  static String get userAgent() => window.navigator.userAgent;

  /**
   * Determines if the current device is running Firefox.
   */
  static bool get isFirefox() => userAgent.contains("Firefox", 0);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Iterator for arrays with fixed size.
class _FixedSizeListIterator<T> extends _VariableSizeListIterator<T> {
  _FixedSizeListIterator(List<T> array)
      : super(array),
        _length = array.length;

  bool hasNext() => _length > _pos;

  final int _length;  // Cache array length for faster access.
}

// Iterator for arrays with variable size.
class _VariableSizeListIterator<T> implements Iterator<T> {
  _VariableSizeListIterator(List<T> array)
      : _array = array,
        _pos = 0;

  bool hasNext() => _array.length > _pos;

  T next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _array[_pos++];
  }

  final List<T> _array;
  int _pos;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Lists {

  /**
   * Returns the index in the array [a] of the given [element], starting
   * the search at index [startIndex] to [endIndex] (exclusive).
   * Returns -1 if [element] is not found.
   */
  static int indexOf(List a,
                     Object element,
                     int startIndex,
                     int endIndex) {
    if (startIndex >= a.length) {
      return -1;
    }
    if (startIndex < 0) {
      startIndex = 0;
    }
    for (int i = startIndex; i < endIndex; i++) {
      if (a[i] == element) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Returns the last index in the array [a] of the given [element], starting
   * the search at index [startIndex] to 0.
   * Returns -1 if [element] is not found.
   */
  static int lastIndexOf(List a, Object element, int startIndex) {
    if (startIndex < 0) {
      return -1;
    }
    if (startIndex >= a.length) {
      startIndex = a.length - 1;
    }
    for (int i = startIndex; i >= 0; i--) {
      if (a[i] == element) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Returns a sub list copy of this list, from [start] to
   * [:start + length:].
   * Returns an empty list if [length] is 0.
   * Throws an [IllegalArgumentException] if [length] is negative.
   * Throws an [IndexOutOfRangeException] if [start] or
   * [:start + length:] are out of range.
   */
  static List getRange(List a, int start, int length, List accumulator) {
    if (length < 0) throw new IllegalArgumentException('length');
    if (start < 0) throw new IndexOutOfRangeException(start);
    int end = start + length;
    if (end > a.length) throw new IndexOutOfRangeException(end);
    for (int i = start; i < end; i++) {
      accumulator.add(a[i]);
    }
    return accumulator;
  }
}
