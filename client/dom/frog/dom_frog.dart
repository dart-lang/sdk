#library('dom');

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated Dart DOM library.



// #source('src/_FactoryProviders.dart');

// TODO(jmesserly): 'native' here is aWork-around for Frog bug.  Frog needs to
// be smarter about inheriting from a hidden native type (in this case
// DOMWindow)
class Window extends DOMWindow native "*Window" {}
DOMWindow get window() native "return window;";
// TODO(vsm): Revert to Dart method when 508 is fixed.
HTMLDocument get document() native "return window.document;";

class AbstractWorker native "*AbstractWorker" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ArrayBuffer native "*ArrayBuffer" {

  int get byteLength() native "return this.byteLength;";

  ArrayBuffer slice(int begin, [int end = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ArrayBufferView native "*ArrayBufferView" {

  ArrayBuffer get buffer() native "return this.buffer;";

  int get byteLength() native "return this.byteLength;";

  int get byteOffset() native "return this.byteOffset;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Attr extends Node native "*Attr" {

  bool get isId() native "return this.isId;";

  String get name() native "return this.name;";

  Element get ownerElement() native "return this.ownerElement;";

  bool get specified() native "return this.specified;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";
}

class AudioBuffer native "*AudioBuffer" {

  num get duration() native "return this.duration;";

  num get gain() native "return this.gain;";

  void set gain(num value) native "this.gain = value;";

  int get length() native "return this.length;";

  int get numberOfChannels() native "return this.numberOfChannels;";

  num get sampleRate() native "return this.sampleRate;";

  Float32Array getChannelData(int channelIndex) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool AudioBufferCallback(AudioBuffer audioBuffer);

class AudioBufferSourceNode extends AudioSourceNode native "*AudioBufferSourceNode" {

  AudioBuffer get buffer() native "return this.buffer;";

  void set buffer(AudioBuffer value) native "this.buffer = value;";

  AudioGain get gain() native "return this.gain;";

  bool get loop() native "return this.loop;";

  void set loop(bool value) native "this.loop = value;";

  bool get looping() native "return this.looping;";

  void set looping(bool value) native "this.looping = value;";

  AudioParam get playbackRate() native "return this.playbackRate;";

  void noteGrainOn(num when, num grainOffset, num grainDuration) native;

  void noteOff(num when) native;

  void noteOn(num when) native;
}

class AudioChannelMerger extends AudioNode native "*AudioChannelMerger" {
}

class AudioChannelSplitter extends AudioNode native "*AudioChannelSplitter" {
}

class AudioContext native "*AudioContext" {
  AudioContext() native;


  num get currentTime() native "return this.currentTime;";

  AudioDestinationNode get destination() native "return this.destination;";

  AudioListener get listener() native "return this.listener;";

  EventListener get oncomplete() native "return this.oncomplete;";

  void set oncomplete(EventListener value) native "this.oncomplete = value;";

  num get sampleRate() native "return this.sampleRate;";

  RealtimeAnalyserNode createAnalyser() native;

  BiquadFilterNode createBiquadFilter() native;

  AudioBuffer createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate = null]) native;

  AudioBufferSourceNode createBufferSource() native;

  AudioChannelMerger createChannelMerger() native;

  AudioChannelSplitter createChannelSplitter() native;

  ConvolverNode createConvolver() native;

  DelayNode createDelayNode() native;

  DynamicsCompressorNode createDynamicsCompressor() native;

  AudioGainNode createGainNode() native;

  HighPass2FilterNode createHighPass2Filter() native;

  JavaScriptAudioNode createJavaScriptNode(int bufferSize) native;

  LowPass2FilterNode createLowPass2Filter() native;

  MediaElementAudioSourceNode createMediaElementSource(HTMLMediaElement mediaElement) native;

  AudioPannerNode createPanner() native;

  WaveShaperNode createWaveShaper() native;

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) native;

  void startRendering() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class AudioDestinationNode extends AudioNode native "*AudioDestinationNode" {

  int get numberOfChannels() native "return this.numberOfChannels;";
}

class AudioGain extends AudioParam native "*AudioGain" {
}

class AudioGainNode extends AudioNode native "*AudioGainNode" {

  AudioGain get gain() native "return this.gain;";
}

class AudioListener native "*AudioListener" {

  num get dopplerFactor() native "return this.dopplerFactor;";

  void set dopplerFactor(num value) native "this.dopplerFactor = value;";

  num get speedOfSound() native "return this.speedOfSound;";

  void set speedOfSound(num value) native "this.speedOfSound = value;";

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class AudioNode native "*AudioNode" {

  AudioContext get context() native "return this.context;";

  int get numberOfInputs() native "return this.numberOfInputs;";

  int get numberOfOutputs() native "return this.numberOfOutputs;";

  void connect(AudioNode destination, int output, int input) native;

  void disconnect(int output) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class AudioPannerNode extends AudioNode native "*AudioPannerNode" {

  static final int EQUALPOWER = 0;

  static final int HRTF = 1;

  static final int SOUNDFIELD = 2;

  AudioGain get coneGain() native "return this.coneGain;";

  num get coneInnerAngle() native "return this.coneInnerAngle;";

  void set coneInnerAngle(num value) native "this.coneInnerAngle = value;";

  num get coneOuterAngle() native "return this.coneOuterAngle;";

  void set coneOuterAngle(num value) native "this.coneOuterAngle = value;";

  num get coneOuterGain() native "return this.coneOuterGain;";

  void set coneOuterGain(num value) native "this.coneOuterGain = value;";

  AudioGain get distanceGain() native "return this.distanceGain;";

  int get distanceModel() native "return this.distanceModel;";

  void set distanceModel(int value) native "this.distanceModel = value;";

  num get maxDistance() native "return this.maxDistance;";

  void set maxDistance(num value) native "this.maxDistance = value;";

  int get panningModel() native "return this.panningModel;";

  void set panningModel(int value) native "this.panningModel = value;";

  num get refDistance() native "return this.refDistance;";

  void set refDistance(num value) native "this.refDistance = value;";

  num get rolloffFactor() native "return this.rolloffFactor;";

  void set rolloffFactor(num value) native "this.rolloffFactor = value;";

  void setOrientation(num x, num y, num z) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;
}

class AudioParam native "*AudioParam" {

  num get defaultValue() native "return this.defaultValue;";

  num get maxValue() native "return this.maxValue;";

  num get minValue() native "return this.minValue;";

  String get name() native "return this.name;";

  int get units() native "return this.units;";

  num get value() native "return this.value;";

  void set value(num value) native "this.value = value;";

  void cancelScheduledValues(num startTime) native;

  void exponentialRampToValueAtTime(num value, num time) native;

  void linearRampToValueAtTime(num value, num time) native;

  void setTargetValueAtTime(num targetValue, num time, num timeConstant) native;

  void setValueAtTime(num value, num time) native;

  void setValueCurveAtTime(Float32Array values, num time, num duration) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class AudioProcessingEvent extends Event native "*AudioProcessingEvent" {

  AudioBuffer get inputBuffer() native "return this.inputBuffer;";

  AudioBuffer get outputBuffer() native "return this.outputBuffer;";
}

class AudioSourceNode extends AudioNode native "*AudioSourceNode" {
}

class BarInfo native "*BarInfo" {

  bool get visible() native "return this.visible;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class BeforeLoadEvent extends Event native "*BeforeLoadEvent" {

  String get url() native "return this.url;";
}

class BiquadFilterNode extends AudioNode native "*BiquadFilterNode" {

  static final int ALLPASS = 7;

  static final int BANDPASS = 2;

  static final int HIGHPASS = 1;

  static final int HIGHSHELF = 4;

  static final int LOWPASS = 0;

  static final int LOWSHELF = 3;

  static final int NOTCH = 6;

  static final int PEAKING = 5;

  AudioParam get Q() native "return this.Q;";

  AudioParam get frequency() native "return this.frequency;";

  AudioParam get gain() native "return this.gain;";

  int get type() native "return this.type;";

  void set type(int value) native "this.type = value;";

  void getFrequencyResponse(Float32Array frequencyHz, Float32Array magResponse, Float32Array phaseResponse) native;
}

class Blob native "*Blob" {

  int get size() native "return this.size;";

  String get type() native "return this.type;";

  Blob webkitSlice([int start = null, int end = null, String contentType = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CDATASection extends Text native "*CDATASection" {
}

class CSSCharsetRule extends CSSRule native "*CSSCharsetRule" {

  String get encoding() native "return this.encoding;";

  void set encoding(String value) native "this.encoding = value;";
}

class CSSFontFaceRule extends CSSRule native "*CSSFontFaceRule" {

  CSSStyleDeclaration get style() native "return this.style;";
}

class CSSImportRule extends CSSRule native "*CSSImportRule" {

  String get href() native "return this.href;";

  MediaList get media() native "return this.media;";

  CSSStyleSheet get styleSheet() native "return this.styleSheet;";
}

class CSSMediaRule extends CSSRule native "*CSSMediaRule" {

  CSSRuleList get cssRules() native "return this.cssRules;";

  MediaList get media() native "return this.media;";

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

class CSSPageRule extends CSSRule native "*CSSPageRule" {

  String get selectorText() native "return this.selectorText;";

  void set selectorText(String value) native "this.selectorText = value;";

  CSSStyleDeclaration get style() native "return this.style;";
}

class CSSPrimitiveValue extends CSSValue native "*CSSPrimitiveValue" {

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

  int get primitiveType() native "return this.primitiveType;";

  Counter getCounterValue() native;

  num getFloatValue(int unitType) native;

  RGBColor getRGBColorValue() native;

  Rect getRectValue() native;

  String getStringValue() native;

  void setFloatValue(int unitType, num floatValue) native;

  void setStringValue(int stringType, String stringValue) native;
}

class CSSRule native "*CSSRule" {

  static final int CHARSET_RULE = 2;

  static final int FONT_FACE_RULE = 5;

  static final int IMPORT_RULE = 3;

  static final int MEDIA_RULE = 4;

  static final int PAGE_RULE = 6;

  static final int STYLE_RULE = 1;

  static final int UNKNOWN_RULE = 0;

  static final int WEBKIT_KEYFRAMES_RULE = 8;

  static final int WEBKIT_KEYFRAME_RULE = 9;

  static final int WEBKIT_REGION_RULE = 10;

  String get cssText() native "return this.cssText;";

  void set cssText(String value) native "this.cssText = value;";

  CSSRule get parentRule() native "return this.parentRule;";

  CSSStyleSheet get parentStyleSheet() native "return this.parentStyleSheet;";

  int get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CSSRuleList native "*CSSRuleList" {

  int get length() native "return this.length;";

  CSSRule item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CSSStyleDeclaration native "*CSSStyleDeclaration" {

  String get cssText() native "return this.cssText;";

  void set cssText(String value) native "this.cssText = value;";

  int get length() native "return this.length;";

  CSSRule get parentRule() native "return this.parentRule;";

  CSSValue getPropertyCSSValue(String propertyName) native;

  String getPropertyPriority(String propertyName) native;

  String getPropertyShorthand(String propertyName) native;

  String getPropertyValue(String propertyName) native;

  bool isPropertyImplicit(String propertyName) native;

  String item(int index) native;

  String removeProperty(String propertyName) native;

  void setProperty(String propertyName, String value, [String priority = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CSSStyleRule extends CSSRule native "*CSSStyleRule" {

  String get selectorText() native "return this.selectorText;";

  void set selectorText(String value) native "this.selectorText = value;";

  CSSStyleDeclaration get style() native "return this.style;";
}

class CSSStyleSheet extends StyleSheet native "*CSSStyleSheet" {

  CSSRuleList get cssRules() native "return this.cssRules;";

  CSSRule get ownerRule() native "return this.ownerRule;";

  CSSRuleList get rules() native "return this.rules;";

  int addRule(String selector, String style, [int index = null]) native;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;

  void removeRule(int index) native;
}

class CSSUnknownRule extends CSSRule native "*CSSUnknownRule" {
}

class CSSValue native "*CSSValue" {

  static final int CSS_CUSTOM = 3;

  static final int CSS_INHERIT = 0;

  static final int CSS_PRIMITIVE_VALUE = 1;

  static final int CSS_VALUE_LIST = 2;

  String get cssText() native "return this.cssText;";

  void set cssText(String value) native "this.cssText = value;";

  int get cssValueType() native "return this.cssValueType;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CSSValueList extends CSSValue native "*CSSValueList" {

  int get length() native "return this.length;";

  CSSValue item(int index) native;
}

class CanvasGradient native "*CanvasGradient" {

  void addColorStop(num offset, String color) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CanvasPattern native "*CanvasPattern" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CanvasPixelArray native "*CanvasPixelArray" {

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CanvasRenderingContext native "*CanvasRenderingContext" {

  HTMLCanvasElement get canvas() native "return this.canvas;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CanvasRenderingContext2D extends CanvasRenderingContext native "*CanvasRenderingContext2D" {

  Dynamic get fillStyle() native "return this.fillStyle;";

  void set fillStyle(Dynamic value) native "this.fillStyle = value;";

  String get font() native "return this.font;";

  void set font(String value) native "this.font = value;";

  num get globalAlpha() native "return this.globalAlpha;";

  void set globalAlpha(num value) native "this.globalAlpha = value;";

  String get globalCompositeOperation() native "return this.globalCompositeOperation;";

  void set globalCompositeOperation(String value) native "this.globalCompositeOperation = value;";

  String get lineCap() native "return this.lineCap;";

  void set lineCap(String value) native "this.lineCap = value;";

  String get lineJoin() native "return this.lineJoin;";

  void set lineJoin(String value) native "this.lineJoin = value;";

  num get lineWidth() native "return this.lineWidth;";

  void set lineWidth(num value) native "this.lineWidth = value;";

  num get miterLimit() native "return this.miterLimit;";

  void set miterLimit(num value) native "this.miterLimit = value;";

  num get shadowBlur() native "return this.shadowBlur;";

  void set shadowBlur(num value) native "this.shadowBlur = value;";

  String get shadowColor() native "return this.shadowColor;";

  void set shadowColor(String value) native "this.shadowColor = value;";

  num get shadowOffsetX() native "return this.shadowOffsetX;";

  void set shadowOffsetX(num value) native "this.shadowOffsetX = value;";

  num get shadowOffsetY() native "return this.shadowOffsetY;";

  void set shadowOffsetY(num value) native "this.shadowOffsetY = value;";

  Dynamic get strokeStyle() native "return this.strokeStyle;";

  void set strokeStyle(Dynamic value) native "this.strokeStyle = value;";

  String get textAlign() native "return this.textAlign;";

  void set textAlign(String value) native "this.textAlign = value;";

  String get textBaseline() native "return this.textBaseline;";

  void set textBaseline(String value) native "this.textBaseline = value;";

  List get webkitLineDash() native "return this.webkitLineDash;";

  void set webkitLineDash(List value) native "this.webkitLineDash = value;";

  num get webkitLineDashOffset() native "return this.webkitLineDashOffset;";

  void set webkitLineDashOffset(num value) native "this.webkitLineDashOffset = value;";

  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise) native;

  void arcTo(num x1, num y1, num x2, num y2, num radius) native;

  void beginPath() native;

  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) native;

  void clearRect(num x, num y, num width, num height) native;

  void clearShadow() native;

  void clip() native;

  void closePath() native;

  ImageData createImageData(var imagedata_OR_sw, [num sh = null]) native;

  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) native;

  CanvasPattern createPattern(var canvas_OR_image, String repetitionType) native;

  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) native;

  void drawImage(var canvas_OR_image_OR_video, num sx_OR_x, num sy_OR_y, [num sw_OR_width = null, num height_OR_sh = null, num dx = null, num dy = null, num dw = null, num dh = null]) native;

  void drawImageFromRect(HTMLImageElement image, [num sx = null, num sy = null, num sw = null, num sh = null, num dx = null, num dy = null, num dw = null, num dh = null, String compositeOperation = null]) native;

  void fill() native;

  void fillRect(num x, num y, num width, num height) native;

  void fillText(String text, num x, num y, [num maxWidth = null]) native;

  ImageData getImageData(num sx, num sy, num sw, num sh) native;

  bool isPointInPath(num x, num y) native;

  void lineTo(num x, num y) native;

  TextMetrics measureText(String text) native;

  void moveTo(num x, num y) native;

  void putImageData(ImageData imagedata, num dx, num dy, [num dirtyX = null, num dirtyY = null, num dirtyWidth = null, num dirtyHeight = null]) native;

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

class CharacterData extends Node native "*CharacterData" {

  String get data() native "return this.data;";

  void set data(String value) native "this.data = value;";

  int get length() native "return this.length;";

  void appendData(String data) native;

  void deleteData(int offset, int length) native;

  void insertData(int offset, String data) native;

  void replaceData(int offset, int length, String data) native;

  String substringData(int offset, int length) native;
}

class ClientRect native "*ClientRect" {

  num get bottom() native "return this.bottom;";

  num get height() native "return this.height;";

  num get left() native "return this.left;";

  num get right() native "return this.right;";

  num get top() native "return this.top;";

  num get width() native "return this.width;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ClientRectList native "*ClientRectList" {

  int get length() native "return this.length;";

  ClientRect item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Clipboard native "*Clipboard" {

  String get dropEffect() native "return this.dropEffect;";

  void set dropEffect(String value) native "this.dropEffect = value;";

  String get effectAllowed() native "return this.effectAllowed;";

  void set effectAllowed(String value) native "this.effectAllowed = value;";

  FileList get files() native "return this.files;";

  DataTransferItemList get items() native "return this.items;";

  List get types() native "return this.types;";

  void clearData([String type = null]) native;

  void getData(String type) native;

  bool setData(String type, String data) native;

  void setDragImage(HTMLImageElement image, int x, int y) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CloseEvent extends Event native "*CloseEvent" {

  int get code() native "return this.code;";

  String get reason() native "return this.reason;";

  bool get wasClean() native "return this.wasClean;";
}

class Comment extends CharacterData native "*Comment" {
}

class CompositionEvent extends UIEvent native "*CompositionEvent" {

  String get data() native "return this.data;";

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindow viewArg, String dataArg) native;
}

class Console native "=(typeof console == 'undefined' ? {} : console)" {

  MemoryInfo get memory() native "return this.memory;";

  List get profiles() native "return this.profiles;";

  void assertCondition(bool condition) native;

  void count() native;

  void debug(Object arg) native;

  void dir() native;

  void dirxml() native;

  void error(Object arg) native;

  void group() native;

  void groupCollapsed() native;

  void groupEnd() native;

  void info(Object arg) native;

  void log(Object arg) native;

  void markTimeline() native;

  void profile(String title) native;

  void profileEnd(String title) native;

  void time(String title) native;

  void timeEnd(String title) native;

  void timeStamp() native;

  void trace(Object arg) native;

  void warn(Object arg) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ConvolverNode extends AudioNode native "*ConvolverNode" {

  AudioBuffer get buffer() native "return this.buffer;";

  void set buffer(AudioBuffer value) native "this.buffer = value;";

  bool get normalize() native "return this.normalize;";

  void set normalize(bool value) native "this.normalize = value;";
}

class Coordinates native "*Coordinates" {

  num get accuracy() native "return this.accuracy;";

  num get altitude() native "return this.altitude;";

  num get altitudeAccuracy() native "return this.altitudeAccuracy;";

  num get heading() native "return this.heading;";

  num get latitude() native "return this.latitude;";

  num get longitude() native "return this.longitude;";

  num get speed() native "return this.speed;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Counter native "*Counter" {

  String get identifier() native "return this.identifier;";

  String get listStyle() native "return this.listStyle;";

  String get separator() native "return this.separator;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Crypto native "*Crypto" {

  void getRandomValues(ArrayBufferView array) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CustomEvent extends Event native "*CustomEvent" {

  Object get detail() native "return this.detail;";

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) native;
}

class DOMApplicationCache native "*DOMApplicationCache" {

  static final int CHECKING = 2;

  static final int DOWNLOADING = 3;

  static final int IDLE = 1;

  static final int OBSOLETE = 5;

  static final int UNCACHED = 0;

  static final int UPDATEREADY = 4;

  int get status() native "return this.status;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void swapCache() native;

  void update() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMException native "*DOMException" {

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

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMFileSystem native "*DOMFileSystem" {

  String get name() native "return this.name;";

  DirectoryEntry get root() native "return this.root;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMFileSystemSync native "*DOMFileSystemSync" {

  String get name() native "return this.name;";

  DirectoryEntrySync get root() native "return this.root;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMFormData native "*DOMFormData" {

  void append(String name, String value, String filename) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMImplementation native "*DOMImplementation" {

  CSSStyleSheet createCSSStyleSheet(String title, String media) native;

  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype) native;

  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId) native;

  HTMLDocument createHTMLDocument(String title) native;

  bool hasFeature(String feature, String version) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMMimeType native "*DOMMimeType" {

  String get description() native "return this.description;";

  DOMPlugin get enabledPlugin() native "return this.enabledPlugin;";

  String get suffixes() native "return this.suffixes;";

  String get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMMimeTypeArray native "*DOMMimeTypeArray" {

  int get length() native "return this.length;";

  DOMMimeType item(int index) native;

  DOMMimeType namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMParser native "*DOMParser" {

  Document parseFromString(String str, String contentType) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMPlugin native "*DOMPlugin" {

  String get description() native "return this.description;";

  String get filename() native "return this.filename;";

  int get length() native "return this.length;";

  String get name() native "return this.name;";

  DOMMimeType item(int index) native;

  DOMMimeType namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMPluginArray native "*DOMPluginArray" {

  int get length() native "return this.length;";

  DOMPlugin item(int index) native;

  DOMPlugin namedItem(String name) native;

  void refresh(bool reload) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMSelection native "*DOMSelection" {

  Node get anchorNode() native "return this.anchorNode;";

  int get anchorOffset() native "return this.anchorOffset;";

  Node get baseNode() native "return this.baseNode;";

  int get baseOffset() native "return this.baseOffset;";

  Node get extentNode() native "return this.extentNode;";

  int get extentOffset() native "return this.extentOffset;";

  Node get focusNode() native "return this.focusNode;";

  int get focusOffset() native "return this.focusOffset;";

  bool get isCollapsed() native "return this.isCollapsed;";

  int get rangeCount() native "return this.rangeCount;";

  String get type() native "return this.type;";

  void addRange(Range range) native;

  void collapse(Node node, int index) native;

  void collapseToEnd() native;

  void collapseToStart() native;

  bool containsNode(Node node, bool allowPartial) native;

  void deleteFromDocument() native;

  void empty() native;

  void extend(Node node, int offset) native;

  Range getRangeAt(int index) native;

  void modify(String alter, String direction, String granularity) native;

  void removeAllRanges() native;

  void selectAllChildren(Node node) native;

  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset) native;

  void setPosition(Node node, int offset) native;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMSettableTokenList extends DOMTokenList native "*DOMSettableTokenList" {

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";
}

class DOMTokenList native "*DOMTokenList" {

  int get length() native "return this.length;";

  void add(String token) native;

  bool contains(String token) native;

  String item(int index) native;

  void remove(String token) native;

  String toString() native;

  bool toggle(String token) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMURL native "*DOMURL" {

  String createObjectURL(Blob blob) native;

  void revokeObjectURL(String url) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMWindow native "@*DOMWindow" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  DOMApplicationCache get applicationCache() native "return this.applicationCache;";

  Navigator get clientInformation() native "return this.clientInformation;";

  void set clientInformation(Navigator value) native "this.clientInformation = value;";

  bool get closed() native "return this.closed;";

  Console get console() native "return this.console;";

  void set console(Console value) native "this.console = value;";

  Crypto get crypto() native "return this.crypto;";

  String get defaultStatus() native "return this.defaultStatus;";

  void set defaultStatus(String value) native "this.defaultStatus = value;";

  String get defaultstatus() native "return this.defaultstatus;";

  void set defaultstatus(String value) native "this.defaultstatus = value;";

  num get devicePixelRatio() native "return this.devicePixelRatio;";

  void set devicePixelRatio(num value) native "this.devicePixelRatio = value;";

  Document get document() native "return this.document;";

  Event get event() native "return this.event;";

  void set event(Event value) native "this.event = value;";

  Element get frameElement() native "return this.frameElement;";

  DOMWindow get frames() native "return this.frames;";

  void set frames(DOMWindow value) native "this.frames = value;";

  History get history() native "return this.history;";

  void set history(History value) native "this.history = value;";

  int get innerHeight() native "return this.innerHeight;";

  void set innerHeight(int value) native "this.innerHeight = value;";

  int get innerWidth() native "return this.innerWidth;";

  void set innerWidth(int value) native "this.innerWidth = value;";

  int get length() native "return this.length;";

  void set length(int value) native "this.length = value;";

  Storage get localStorage() native "return this.localStorage;";

  Location get location() native "return this.location;";

  void set location(Location value) native "this.location = value;";

  BarInfo get locationbar() native "return this.locationbar;";

  void set locationbar(BarInfo value) native "this.locationbar = value;";

  BarInfo get menubar() native "return this.menubar;";

  void set menubar(BarInfo value) native "this.menubar = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  Navigator get navigator() native "return this.navigator;";

  void set navigator(Navigator value) native "this.navigator = value;";

  bool get offscreenBuffering() native "return this.offscreenBuffering;";

  void set offscreenBuffering(bool value) native "this.offscreenBuffering = value;";

  DOMWindow get opener() native "return this.opener;";

  void set opener(DOMWindow value) native "this.opener = value;";

  int get outerHeight() native "return this.outerHeight;";

  void set outerHeight(int value) native "this.outerHeight = value;";

  int get outerWidth() native "return this.outerWidth;";

  void set outerWidth(int value) native "this.outerWidth = value;";

  int get pageXOffset() native "return this.pageXOffset;";

  int get pageYOffset() native "return this.pageYOffset;";

  DOMWindow get parent() native "return this.parent;";

  void set parent(DOMWindow value) native "this.parent = value;";

  Performance get performance() native "return this.performance;";

  void set performance(Performance value) native "this.performance = value;";

  BarInfo get personalbar() native "return this.personalbar;";

  void set personalbar(BarInfo value) native "this.personalbar = value;";

  Screen get screen() native "return this.screen;";

  void set screen(Screen value) native "this.screen = value;";

  int get screenLeft() native "return this.screenLeft;";

  void set screenLeft(int value) native "this.screenLeft = value;";

  int get screenTop() native "return this.screenTop;";

  void set screenTop(int value) native "this.screenTop = value;";

  int get screenX() native "return this.screenX;";

  void set screenX(int value) native "this.screenX = value;";

  int get screenY() native "return this.screenY;";

  void set screenY(int value) native "this.screenY = value;";

  int get scrollX() native "return this.scrollX;";

  void set scrollX(int value) native "this.scrollX = value;";

  int get scrollY() native "return this.scrollY;";

  void set scrollY(int value) native "this.scrollY = value;";

  BarInfo get scrollbars() native "return this.scrollbars;";

  void set scrollbars(BarInfo value) native "this.scrollbars = value;";

  DOMWindow get self() native "return this.self;";

  void set self(DOMWindow value) native "this.self = value;";

  Storage get sessionStorage() native "return this.sessionStorage;";

  String get status() native "return this.status;";

  void set status(String value) native "this.status = value;";

  BarInfo get statusbar() native "return this.statusbar;";

  void set statusbar(BarInfo value) native "this.statusbar = value;";

  StyleMedia get styleMedia() native "return this.styleMedia;";

  BarInfo get toolbar() native "return this.toolbar;";

  void set toolbar(BarInfo value) native "this.toolbar = value;";

  DOMWindow get top() native "return this.top;";

  void set top(DOMWindow value) native "this.top = value;";

  IDBFactory get webkitIndexedDB() native "return this.webkitIndexedDB;";

  NotificationCenter get webkitNotifications() native "return this.webkitNotifications;";

  StorageInfo get webkitStorageInfo() native "return this.webkitStorageInfo;";

  DOMURL get webkitURL() native "return this.webkitURL;";

  DOMWindow get window() native "return this.window;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void alert(String message) native;

  String atob(String string) native;

  void blur() native;

  String btoa(String string) native;

  void captureEvents() native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool confirm(String message) native;

  bool dispatchEvent(Event evt) native;

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  void focus() native;

  CSSStyleDeclaration getComputedStyle(Element element, String pseudoElement) native;

  CSSRuleList getMatchedCSSRules(Element element, String pseudoElement) native;

  DOMSelection getSelection() native;

  MediaQueryList matchMedia(String query) native;

  void moveBy(num x, num y) native;

  void moveTo(num x, num y) native;

  DOMWindow open(String url, String name, [String options = null]) native;

  void postMessage(String message, String targetOrigin, [List messagePorts = null]) native;

  void print() native;

  String prompt(String message, String defaultValue) native;

  void releaseEvents() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

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

  WebKitPoint webkitConvertPointFromNodeToPage(Node node, WebKitPoint p) native;

  WebKitPoint webkitConvertPointFromPageToNode(Node node, WebKitPoint p) native;

  void webkitPostMessage(String message, String targetOrigin, [List transferList = null]) native;

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, Element element) native;

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DataTransferItem native "*DataTransferItem" {

  String get kind() native "return this.kind;";

  String get type() native "return this.type;";

  Blob getAsFile() native;

  void getAsString(StringCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DataTransferItemList native "*DataTransferItemList" {

  int get length() native "return this.length;";

  void add(String data, String type) native;

  void clear() native;

  DataTransferItem item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DataView extends ArrayBufferView native "*DataView" {

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

class Database native "*Database" {

  String get version() native "return this.version;";

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback = null, SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool DatabaseCallback(var database);

class DatabaseSync native "*DatabaseSync" {

  String get lastErrorMessage() native "return this.lastErrorMessage;";

  String get version() native "return this.version;";

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback = null]) native;

  void readTransaction(SQLTransactionSyncCallback callback) native;

  void transaction(SQLTransactionSyncCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DedicatedWorkerContext extends WorkerContext native "*DedicatedWorkerContext" {

  EventListener get onmessage() native "return this.onmessage;";

  void set onmessage(EventListener value) native "this.onmessage = value;";

  void postMessage(Object message, [List messagePorts = null]) native;

  void webkitPostMessage(Object message, [List transferList = null]) native;
}

class DelayNode extends AudioNode native "*DelayNode" {

  AudioParam get delayTime() native "return this.delayTime;";
}

class DeviceMotionEvent extends Event native "*DeviceMotionEvent" {

  num get interval() native "return this.interval;";
}

class DeviceOrientationEvent extends Event native "*DeviceOrientationEvent" {

  num get alpha() native "return this.alpha;";

  num get beta() native "return this.beta;";

  num get gamma() native "return this.gamma;";

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma) native;
}

class DirectoryEntry extends Entry native "*DirectoryEntry" {

  DirectoryReader createReader() native;

  void getDirectory(String path, [Object flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getFile(String path, [Object flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback = null]) native;
}

class DirectoryEntrySync extends EntrySync native "*DirectoryEntrySync" {

  DirectoryReaderSync createReader() native;

  DirectoryEntrySync getDirectory(String path, Object flags) native;

  FileEntrySync getFile(String path, Object flags) native;

  void removeRecursively() native;
}

class DirectoryReader native "*DirectoryReader" {

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DirectoryReaderSync native "*DirectoryReaderSync" {

  EntryArraySync readEntries() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Document extends Node native "*Document" {

  String get URL() native "return this.URL;";

  HTMLCollection get anchors() native "return this.anchors;";

  HTMLCollection get applets() native "return this.applets;";

  HTMLElement get body() native "return this.body;";

  void set body(HTMLElement value) native "this.body = value;";

  String get characterSet() native "return this.characterSet;";

  String get charset() native "return this.charset;";

  void set charset(String value) native "this.charset = value;";

  String get compatMode() native "return this.compatMode;";

  String get cookie() native "return this.cookie;";

  void set cookie(String value) native "this.cookie = value;";

  String get defaultCharset() native "return this.defaultCharset;";

  DOMWindow get defaultView() native "return this.defaultView;";

  DocumentType get doctype() native "return this.doctype;";

  Element get documentElement() native "return this.documentElement;";

  String get documentURI() native "return this.documentURI;";

  void set documentURI(String value) native "this.documentURI = value;";

  String get domain() native "return this.domain;";

  void set domain(String value) native "this.domain = value;";

  HTMLCollection get forms() native "return this.forms;";

  HTMLHeadElement get head() native "return this.head;";

  HTMLCollection get images() native "return this.images;";

  DOMImplementation get implementation() native "return this.implementation;";

  String get inputEncoding() native "return this.inputEncoding;";

  String get lastModified() native "return this.lastModified;";

  HTMLCollection get links() native "return this.links;";

  Location get location() native "return this.location;";

  void set location(Location value) native "this.location = value;";

  String get preferredStylesheetSet() native "return this.preferredStylesheetSet;";

  String get readyState() native "return this.readyState;";

  String get referrer() native "return this.referrer;";

  String get selectedStylesheetSet() native "return this.selectedStylesheetSet;";

  void set selectedStylesheetSet(String value) native "this.selectedStylesheetSet = value;";

  StyleSheetList get styleSheets() native "return this.styleSheets;";

  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  Element get webkitCurrentFullScreenElement() native "return this.webkitCurrentFullScreenElement;";

  bool get webkitFullScreenKeyboardInputAllowed() native "return this.webkitFullScreenKeyboardInputAllowed;";

  bool get webkitHidden() native "return this.webkitHidden;";

  bool get webkitIsFullScreen() native "return this.webkitIsFullScreen;";

  String get webkitVisibilityState() native "return this.webkitVisibilityState;";

  String get xmlEncoding() native "return this.xmlEncoding;";

  bool get xmlStandalone() native "return this.xmlStandalone;";

  void set xmlStandalone(bool value) native "this.xmlStandalone = value;";

  String get xmlVersion() native "return this.xmlVersion;";

  void set xmlVersion(String value) native "this.xmlVersion = value;";

  Node adoptNode(Node source) native;

  Range caretRangeFromPoint(int x, int y) native;

  Attr createAttribute(String name) native;

  Attr createAttributeNS(String namespaceURI, String qualifiedName) native;

  CDATASection createCDATASection(String data) native;

  Comment createComment(String data) native;

  DocumentFragment createDocumentFragment() native;

  Element createElement(String tagName) native;

  Element createElementNS(String namespaceURI, String qualifiedName) native;

  EntityReference createEntityReference(String name) native;

  Event createEvent(String eventType) native;

  XPathExpression createExpression(String expression, XPathNSResolver resolver) native;

  XPathNSResolver createNSResolver(Node nodeResolver) native;

  NodeIterator createNodeIterator(Node root, int whatToShow, NodeFilter filter, bool expandEntityReferences) native;

  ProcessingInstruction createProcessingInstruction(String target, String data) native;

  Range createRange() native;

  Text createTextNode(String data) native;

  Touch createTouch(DOMWindow window, EventTarget target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) native;

  TouchList createTouchList() native;

  TreeWalker createTreeWalker(Node root, int whatToShow, NodeFilter filter, bool expandEntityReferences) native;

  Element elementFromPoint(int x, int y) native;

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult) native;

  bool execCommand(String command, bool userInterface, String value) native;

  Object getCSSCanvasContext(String contextId, String name, int width, int height) native;

  Element getElementById(String elementId) native;

  NodeList getElementsByClassName(String tagname) native;

  NodeList getElementsByName(String elementName) native;

  NodeList getElementsByTagName(String tagname) native;

  NodeList getElementsByTagNameNS(String namespaceURI, String localName) native;

  CSSStyleDeclaration getOverrideStyle(Element element, String pseudoElement) native;

  DOMSelection getSelection() native;

  Node importNode(Node importedNode, [bool deep = null]) native;

  bool queryCommandEnabled(String command) native;

  bool queryCommandIndeterm(String command) native;

  bool queryCommandState(String command) native;

  bool queryCommandSupported(String command) native;

  String queryCommandValue(String command) native;

  Element querySelector(String selectors) native;

  NodeList querySelectorAll(String selectors) native;

  void webkitCancelFullScreen() native;

  WebKitNamedFlow webkitGetFlowByName(String name) native;
}

class DocumentFragment extends Node native "*DocumentFragment" {

  Element querySelector(String selectors) native;

  NodeList querySelectorAll(String selectors) native;
}

class DocumentType extends Node native "*DocumentType" {

  NamedNodeMap get entities() native "return this.entities;";

  String get internalSubset() native "return this.internalSubset;";

  String get name() native "return this.name;";

  NamedNodeMap get notations() native "return this.notations;";

  String get publicId() native "return this.publicId;";

  String get systemId() native "return this.systemId;";
}

class DynamicsCompressorNode extends AudioNode native "*DynamicsCompressorNode" {
}

class Element extends Node native "*Element" {

  static final int ALLOW_KEYBOARD_INPUT = 1;

  int get childElementCount() native "return this.childElementCount;";

  int get clientHeight() native "return this.clientHeight;";

  int get clientLeft() native "return this.clientLeft;";

  int get clientTop() native "return this.clientTop;";

  int get clientWidth() native "return this.clientWidth;";

  Element get firstElementChild() native "return this.firstElementChild;";

  Element get lastElementChild() native "return this.lastElementChild;";

  Element get nextElementSibling() native "return this.nextElementSibling;";

  int get offsetHeight() native "return this.offsetHeight;";

  int get offsetLeft() native "return this.offsetLeft;";

  Element get offsetParent() native "return this.offsetParent;";

  int get offsetTop() native "return this.offsetTop;";

  int get offsetWidth() native "return this.offsetWidth;";

  Element get previousElementSibling() native "return this.previousElementSibling;";

  int get scrollHeight() native "return this.scrollHeight;";

  int get scrollLeft() native "return this.scrollLeft;";

  void set scrollLeft(int value) native "this.scrollLeft = value;";

  int get scrollTop() native "return this.scrollTop;";

  void set scrollTop(int value) native "this.scrollTop = value;";

  int get scrollWidth() native "return this.scrollWidth;";

  CSSStyleDeclaration get style() native "return this.style;";

  String get tagName() native "return this.tagName;";

  void blur() native;

  void focus() native;

  String getAttribute(String name) native;

  String getAttributeNS(String namespaceURI, String localName) native;

  Attr getAttributeNode(String name) native;

  Attr getAttributeNodeNS(String namespaceURI, String localName) native;

  ClientRect getBoundingClientRect() native;

  ClientRectList getClientRects() native;

  NodeList getElementsByClassName(String name) native;

  NodeList getElementsByTagName(String name) native;

  NodeList getElementsByTagNameNS(String namespaceURI, String localName) native;

  bool hasAttribute(String name) native;

  bool hasAttributeNS(String namespaceURI, String localName) native;

  Element querySelector(String selectors) native;

  NodeList querySelectorAll(String selectors) native;

  void removeAttribute(String name) native;

  void removeAttributeNS(String namespaceURI, String localName) native;

  Attr removeAttributeNode(Attr oldAttr) native;

  void scrollByLines(int lines) native;

  void scrollByPages(int pages) native;

  void scrollIntoView([bool alignWithTop = null]) native;

  void scrollIntoViewIfNeeded([bool centerIfNeeded = null]) native;

  void setAttribute(String name, String value) native;

  void setAttributeNS(String namespaceURI, String qualifiedName, String value) native;

  Attr setAttributeNode(Attr newAttr) native;

  Attr setAttributeNodeNS(Attr newAttr) native;

  bool webkitMatchesSelector(String selectors) native;

  void webkitRequestFullScreen(int flags) native;
}

class ElementTimeControl native "*ElementTimeControl" {

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ElementTraversal native "*ElementTraversal" {

  int get childElementCount() native "return this.childElementCount;";

  Element get firstElementChild() native "return this.firstElementChild;";

  Element get lastElementChild() native "return this.lastElementChild;";

  Element get nextElementSibling() native "return this.nextElementSibling;";

  Element get previousElementSibling() native "return this.previousElementSibling;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Entity extends Node native "*Entity" {

  String get notationName() native "return this.notationName;";

  String get publicId() native "return this.publicId;";

  String get systemId() native "return this.systemId;";
}

class EntityReference extends Node native "*EntityReference" {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool EntriesCallback(EntryArray entries);

class Entry native "*Entry" {

  DOMFileSystem get filesystem() native "return this.filesystem;";

  String get fullPath() native "return this.fullPath;";

  bool get isDirectory() native "return this.isDirectory;";

  bool get isFile() native "return this.isFile;";

  String get name() native "return this.name;";

  void copyTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void getParent([EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void moveTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void remove(VoidCallback successCallback, [ErrorCallback errorCallback = null]) native;

  String toURL() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EntryArray native "*EntryArray" {

  int get length() native "return this.length;";

  Entry item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EntryArraySync native "*EntryArraySync" {

  int get length() native "return this.length;";

  EntrySync item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool EntryCallback(Entry entry);

class EntrySync native "*EntrySync" {

  DOMFileSystemSync get filesystem() native "return this.filesystem;";

  String get fullPath() native "return this.fullPath;";

  bool get isDirectory() native "return this.isDirectory;";

  bool get isFile() native "return this.isFile;";

  String get name() native "return this.name;";

  EntrySync copyTo(DirectoryEntrySync parent, String name) native;

  Metadata getMetadata() native;

  DirectoryEntrySync getParent() native;

  EntrySync moveTo(DirectoryEntrySync parent, String name) native;

  void remove() native;

  String toURL() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool ErrorCallback(FileError error);

class ErrorEvent extends Event native "*ErrorEvent" {

  String get filename() native "return this.filename;";

  int get lineno() native "return this.lineno;";

  String get message() native "return this.message;";
}

class Event native "*Event" {

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

  bool get bubbles() native "return this.bubbles;";

  bool get cancelBubble() native "return this.cancelBubble;";

  void set cancelBubble(bool value) native "this.cancelBubble = value;";

  bool get cancelable() native "return this.cancelable;";

  Clipboard get clipboardData() native "return this.clipboardData;";

  EventTarget get currentTarget() native "return this.currentTarget;";

  bool get defaultPrevented() native "return this.defaultPrevented;";

  int get eventPhase() native "return this.eventPhase;";

  bool get returnValue() native "return this.returnValue;";

  void set returnValue(bool value) native "this.returnValue = value;";

  EventTarget get srcElement() native "return this.srcElement;";

  EventTarget get target() native "return this.target;";

  int get timeStamp() native "return this.timeStamp;";

  String get type() native "return this.type;";

  void initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) native;

  void preventDefault() native;

  void stopImmediatePropagation() native;

  void stopPropagation() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EventException native "*EventException" {

  static final int DISPATCH_REQUEST_ERR = 1;

  static final int UNSPECIFIED_EVENT_TYPE_ERR = 0;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EventSource native "*EventSource" {

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String get URL() native "return this.URL;";

  int get readyState() native "return this.readyState;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EventTarget native "*EventTarget" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class File extends Blob native "*File" {

  String get fileName() native "return this.fileName;";

  int get fileSize() native "return this.fileSize;";

  Date get lastModifiedDate() native "return this.lastModifiedDate;";

  String get name() native "return this.name;";

  String get webkitRelativePath() native "return this.webkitRelativePath;";
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool FileCallback(File file);

class FileEntry extends Entry native "*FileEntry" {

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void file(FileCallback successCallback, [ErrorCallback errorCallback = null]) native;
}

class FileEntrySync extends EntrySync native "*FileEntrySync" {

  FileWriterSync createWriter() native;

  File file() native;
}

class FileError native "*FileError" {

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

  int get code() native "return this.code;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class FileException native "*FileException" {

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

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class FileList native "*FileList" {

  int get length() native "return this.length;";

  File item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class FileReader native "*FileReader" {
  FileReader() native;


  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  FileError get error() native "return this.error;";

  EventListener get onabort() native "return this.onabort;";

  void set onabort(EventListener value) native "this.onabort = value;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  EventListener get onload() native "return this.onload;";

  void set onload(EventListener value) native "this.onload = value;";

  EventListener get onloadend() native "return this.onloadend;";

  void set onloadend(EventListener value) native "this.onloadend = value;";

  EventListener get onloadstart() native "return this.onloadstart;";

  void set onloadstart(EventListener value) native "this.onloadstart = value;";

  EventListener get onprogress() native "return this.onprogress;";

  void set onprogress(EventListener value) native "this.onprogress = value;";

  int get readyState() native "return this.readyState;";

  Object get result() native "return this.result;";

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void readAsArrayBuffer(Blob blob) native;

  void readAsBinaryString(Blob blob) native;

  void readAsDataURL(Blob blob) native;

  void readAsText(Blob blob, [String encoding = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class FileReaderSync native "*FileReaderSync" {

  ArrayBuffer readAsArrayBuffer(Blob blob) native;

  String readAsBinaryString(Blob blob) native;

  String readAsDataURL(Blob blob) native;

  String readAsText(Blob blob, [String encoding = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool FileSystemCallback(DOMFileSystem fileSystem);

class FileWriter native "*FileWriter" {

  static final int DONE = 2;

  static final int INIT = 0;

  static final int WRITING = 1;

  FileError get error() native "return this.error;";

  int get length() native "return this.length;";

  EventListener get onabort() native "return this.onabort;";

  void set onabort(EventListener value) native "this.onabort = value;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  EventListener get onprogress() native "return this.onprogress;";

  void set onprogress(EventListener value) native "this.onprogress = value;";

  EventListener get onwrite() native "return this.onwrite;";

  void set onwrite(EventListener value) native "this.onwrite = value;";

  EventListener get onwriteend() native "return this.onwriteend;";

  void set onwriteend(EventListener value) native "this.onwriteend = value;";

  EventListener get onwritestart() native "return this.onwritestart;";

  void set onwritestart(EventListener value) native "this.onwritestart = value;";

  int get position() native "return this.position;";

  int get readyState() native "return this.readyState;";

  void abort() native;

  void seek(int position) native;

  void truncate(int size) native;

  void write(Blob data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool FileWriterCallback(FileWriter fileWriter);

class FileWriterSync native "*FileWriterSync" {

  int get length() native "return this.length;";

  int get position() native "return this.position;";

  void seek(int position) native;

  void truncate(int size) native;

  void write(Blob data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Float32Array extends ArrayBufferView implements List<num> native "*Float32Array" {

  factory Float32Array(int length) =>  _construct(length);

  factory Float32Array.fromList(List<num> list) => _construct(list);

  factory Float32Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Float32Array(arg);';

  static final int BYTES_PER_ELEMENT = 4;

  int get length() native "return this.length;";

  num operator[](int index) native;

  void operator[]=(int index, num value) native;

  Float32Array subarray(int start, [int end = null]) native;
}

class Float64Array extends ArrayBufferView implements List<num> native "*Float64Array" {

  factory Float64Array(int length) =>  _construct(length);

  factory Float64Array.fromList(List<num> list) => _construct(list);

  factory Float64Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Float64Array(arg);';

  static final int BYTES_PER_ELEMENT = 8;

  int get length() native "return this.length;";

  num operator[](int index) native;

  void operator[]=(int index, num value) native;

  Float64Array subarray(int start, [int end = null]) native;
}

class Geolocation native "*Geolocation" {

  void clearWatch(int watchId) native;

  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) native;

  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Geoposition native "*Geoposition" {

  Coordinates get coords() native "return this.coords;";

  int get timestamp() native "return this.timestamp;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class HTMLAllCollection native "*HTMLAllCollection" {

  int get length() native "return this.length;";

  Node item(int index) native;

  Node namedItem(String name) native;

  NodeList tags(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class HTMLAnchorElement extends HTMLElement native "*HTMLAnchorElement" {

  String get charset() native "return this.charset;";

  void set charset(String value) native "this.charset = value;";

  String get coords() native "return this.coords;";

  void set coords(String value) native "this.coords = value;";

  String get download() native "return this.download;";

  void set download(String value) native "this.download = value;";

  String get hash() native "return this.hash;";

  void set hash(String value) native "this.hash = value;";

  String get host() native "return this.host;";

  void set host(String value) native "this.host = value;";

  String get hostname() native "return this.hostname;";

  void set hostname(String value) native "this.hostname = value;";

  String get href() native "return this.href;";

  void set href(String value) native "this.href = value;";

  String get hreflang() native "return this.hreflang;";

  void set hreflang(String value) native "this.hreflang = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get origin() native "return this.origin;";

  String get pathname() native "return this.pathname;";

  void set pathname(String value) native "this.pathname = value;";

  String get ping() native "return this.ping;";

  void set ping(String value) native "this.ping = value;";

  String get port() native "return this.port;";

  void set port(String value) native "this.port = value;";

  String get protocol() native "return this.protocol;";

  void set protocol(String value) native "this.protocol = value;";

  String get rel() native "return this.rel;";

  void set rel(String value) native "this.rel = value;";

  String get rev() native "return this.rev;";

  void set rev(String value) native "this.rev = value;";

  String get search() native "return this.search;";

  void set search(String value) native "this.search = value;";

  String get shape() native "return this.shape;";

  void set shape(String value) native "this.shape = value;";

  String get target() native "return this.target;";

  void set target(String value) native "this.target = value;";

  String get text() native "return this.text;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  String toString() native;
}

class HTMLAppletElement extends HTMLElement native "*HTMLAppletElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get alt() native "return this.alt;";

  void set alt(String value) native "this.alt = value;";

  String get archive() native "return this.archive;";

  void set archive(String value) native "this.archive = value;";

  String get code() native "return this.code;";

  void set code(String value) native "this.code = value;";

  String get codeBase() native "return this.codeBase;";

  void set codeBase(String value) native "this.codeBase = value;";

  String get height() native "return this.height;";

  void set height(String value) native "this.height = value;";

  String get hspace() native "return this.hspace;";

  void set hspace(String value) native "this.hspace = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get object() native "return this.object;";

  void set object(String value) native "this.object = value;";

  String get vspace() native "return this.vspace;";

  void set vspace(String value) native "this.vspace = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";
}

class HTMLAreaElement extends HTMLElement native "*HTMLAreaElement" {

  String get alt() native "return this.alt;";

  void set alt(String value) native "this.alt = value;";

  String get coords() native "return this.coords;";

  void set coords(String value) native "this.coords = value;";

  String get hash() native "return this.hash;";

  String get host() native "return this.host;";

  String get hostname() native "return this.hostname;";

  String get href() native "return this.href;";

  void set href(String value) native "this.href = value;";

  bool get noHref() native "return this.noHref;";

  void set noHref(bool value) native "this.noHref = value;";

  String get pathname() native "return this.pathname;";

  String get ping() native "return this.ping;";

  void set ping(String value) native "this.ping = value;";

  String get port() native "return this.port;";

  String get protocol() native "return this.protocol;";

  String get search() native "return this.search;";

  String get shape() native "return this.shape;";

  void set shape(String value) native "this.shape = value;";

  String get target() native "return this.target;";

  void set target(String value) native "this.target = value;";
}

class HTMLAudioElement extends HTMLMediaElement native "*HTMLAudioElement" {
}

class HTMLBRElement extends HTMLElement native "*HTMLBRElement" {

  String get clear() native "return this.clear;";

  void set clear(String value) native "this.clear = value;";
}

class HTMLBaseElement extends HTMLElement native "*HTMLBaseElement" {

  String get href() native "return this.href;";

  void set href(String value) native "this.href = value;";

  String get target() native "return this.target;";

  void set target(String value) native "this.target = value;";
}

class HTMLBaseFontElement extends HTMLElement native "*HTMLBaseFontElement" {

  String get color() native "return this.color;";

  void set color(String value) native "this.color = value;";

  String get face() native "return this.face;";

  void set face(String value) native "this.face = value;";

  int get size() native "return this.size;";

  void set size(int value) native "this.size = value;";
}

class HTMLBodyElement extends HTMLElement native "*HTMLBodyElement" {

  String get aLink() native "return this.aLink;";

  void set aLink(String value) native "this.aLink = value;";

  String get background() native "return this.background;";

  void set background(String value) native "this.background = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  String get link() native "return this.link;";

  void set link(String value) native "this.link = value;";

  String get text() native "return this.text;";

  void set text(String value) native "this.text = value;";

  String get vLink() native "return this.vLink;";

  void set vLink(String value) native "this.vLink = value;";
}

class HTMLButtonElement extends HTMLElement native "*HTMLButtonElement" {

  bool get autofocus() native "return this.autofocus;";

  void set autofocus(bool value) native "this.autofocus = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  HTMLFormElement get form() native "return this.form;";

  String get formAction() native "return this.formAction;";

  void set formAction(String value) native "this.formAction = value;";

  String get formEnctype() native "return this.formEnctype;";

  void set formEnctype(String value) native "this.formEnctype = value;";

  String get formMethod() native "return this.formMethod;";

  void set formMethod(String value) native "this.formMethod = value;";

  bool get formNoValidate() native "return this.formNoValidate;";

  void set formNoValidate(bool value) native "this.formNoValidate = value;";

  String get formTarget() native "return this.formTarget;";

  void set formTarget(String value) native "this.formTarget = value;";

  NodeList get labels() native "return this.labels;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get type() native "return this.type;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityState get validity() native "return this.validity;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void click() native;

  void setCustomValidity(String error) native;
}

class HTMLCanvasElement extends HTMLElement native "*HTMLCanvasElement" {

  int get height() native "return this.height;";

  void set height(int value) native "this.height = value;";

  int get width() native "return this.width;";

  void set width(int value) native "this.width = value;";

  Object getContext(String contextId) native;

  String toDataURL(String type) native;
}

class HTMLCollection native "*HTMLCollection" {

  int get length() native "return this.length;";

  Node operator[](int index) native;

  void operator[]=(int index, Node value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  Node item(int index) native;

  Node namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class HTMLDListElement extends HTMLElement native "*HTMLDListElement" {

  bool get compact() native "return this.compact;";

  void set compact(bool value) native "this.compact = value;";
}

class HTMLDataListElement extends HTMLElement native "*HTMLDataListElement" {

  HTMLCollection get options() native "return this.options;";
}

class HTMLDetailsElement extends HTMLElement native "*HTMLDetailsElement" {

  bool get open() native "return this.open;";

  void set open(bool value) native "this.open = value;";
}

class HTMLDirectoryElement extends HTMLElement native "*HTMLDirectoryElement" {

  bool get compact() native "return this.compact;";

  void set compact(bool value) native "this.compact = value;";
}

class HTMLDivElement extends HTMLElement native "*HTMLDivElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";
}

class HTMLDocument extends Document native "*HTMLDocument" {

  Element get activeElement() native "return this.activeElement;";

  String get alinkColor() native "return this.alinkColor;";

  void set alinkColor(String value) native "this.alinkColor = value;";

  HTMLAllCollection get all() native "return this.all;";

  void set all(HTMLAllCollection value) native "this.all = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  String get compatMode() native "return this.compatMode;";

  String get designMode() native "return this.designMode;";

  void set designMode(String value) native "this.designMode = value;";

  String get dir() native "return this.dir;";

  void set dir(String value) native "this.dir = value;";

  HTMLCollection get embeds() native "return this.embeds;";

  String get fgColor() native "return this.fgColor;";

  void set fgColor(String value) native "this.fgColor = value;";

  String get linkColor() native "return this.linkColor;";

  void set linkColor(String value) native "this.linkColor = value;";

  HTMLCollection get plugins() native "return this.plugins;";

  HTMLCollection get scripts() native "return this.scripts;";

  String get vlinkColor() native "return this.vlinkColor;";

  void set vlinkColor(String value) native "this.vlinkColor = value;";

  void captureEvents() native;

  void clear() native;

  void close() native;

  bool hasFocus() native;

  void open() native;

  void releaseEvents() native;

  void write(String text) native;

  void writeln(String text) native;
}

class HTMLElement extends Element native "*HTMLElement" {

  String get accessKey() native "return this.accessKey;";

  void set accessKey(String value) native "this.accessKey = value;";

  HTMLCollection get children() native "return this.children;";

  DOMTokenList get classList() native "return this.classList;";

  String get className() native "return this.className;";

  void set className(String value) native "this.className = value;";

  String get contentEditable() native "return this.contentEditable;";

  void set contentEditable(String value) native "this.contentEditable = value;";

  String get dir() native "return this.dir;";

  void set dir(String value) native "this.dir = value;";

  bool get draggable() native "return this.draggable;";

  void set draggable(bool value) native "this.draggable = value;";

  bool get hidden() native "return this.hidden;";

  void set hidden(bool value) native "this.hidden = value;";

  String get id() native "return this.id;";

  void set id(String value) native "this.id = value;";

  String get innerHTML() native "return this.innerHTML;";

  void set innerHTML(String value) native "this.innerHTML = value;";

  String get innerText() native "return this.innerText;";

  void set innerText(String value) native "this.innerText = value;";

  bool get isContentEditable() native "return this.isContentEditable;";

  String get itemId() native "return this.itemId;";

  void set itemId(String value) native "this.itemId = value;";

  DOMSettableTokenList get itemProp() native "return this.itemProp;";

  DOMSettableTokenList get itemRef() native "return this.itemRef;";

  bool get itemScope() native "return this.itemScope;";

  void set itemScope(bool value) native "this.itemScope = value;";

  DOMSettableTokenList get itemType() native "return this.itemType;";

  Object get itemValue() native "return this.itemValue;";

  void set itemValue(Object value) native "this.itemValue = value;";

  String get lang() native "return this.lang;";

  void set lang(String value) native "this.lang = value;";

  String get outerHTML() native "return this.outerHTML;";

  void set outerHTML(String value) native "this.outerHTML = value;";

  String get outerText() native "return this.outerText;";

  void set outerText(String value) native "this.outerText = value;";

  bool get spellcheck() native "return this.spellcheck;";

  void set spellcheck(bool value) native "this.spellcheck = value;";

  int get tabIndex() native "return this.tabIndex;";

  void set tabIndex(int value) native "this.tabIndex = value;";

  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  String get webkitdropzone() native "return this.webkitdropzone;";

  void set webkitdropzone(String value) native "this.webkitdropzone = value;";

  Element insertAdjacentElement(String where, Element element) native;

  void insertAdjacentHTML(String where, String html) native;

  void insertAdjacentText(String where, String text) native;
}

class HTMLEmbedElement extends HTMLElement native "*HTMLEmbedElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get height() native "return this.height;";

  void set height(String value) native "this.height = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  SVGDocument getSVGDocument() native;
}

class HTMLFieldSetElement extends HTMLElement native "*HTMLFieldSetElement" {

  HTMLFormElement get form() native "return this.form;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityState get validity() native "return this.validity;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class HTMLFontElement extends HTMLElement native "*HTMLFontElement" {

  String get color() native "return this.color;";

  void set color(String value) native "this.color = value;";

  String get face() native "return this.face;";

  void set face(String value) native "this.face = value;";

  String get size() native "return this.size;";

  void set size(String value) native "this.size = value;";
}

class HTMLFormElement extends HTMLElement native "*HTMLFormElement" {

  String get acceptCharset() native "return this.acceptCharset;";

  void set acceptCharset(String value) native "this.acceptCharset = value;";

  String get action() native "return this.action;";

  void set action(String value) native "this.action = value;";

  String get autocomplete() native "return this.autocomplete;";

  void set autocomplete(String value) native "this.autocomplete = value;";

  HTMLCollection get elements() native "return this.elements;";

  String get encoding() native "return this.encoding;";

  void set encoding(String value) native "this.encoding = value;";

  String get enctype() native "return this.enctype;";

  void set enctype(String value) native "this.enctype = value;";

  int get length() native "return this.length;";

  String get method() native "return this.method;";

  void set method(String value) native "this.method = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  bool get noValidate() native "return this.noValidate;";

  void set noValidate(bool value) native "this.noValidate = value;";

  String get target() native "return this.target;";

  void set target(String value) native "this.target = value;";

  bool checkValidity() native;

  void reset() native;

  void submit() native;
}

class HTMLFrameElement extends HTMLElement native "*HTMLFrameElement" {

  Document get contentDocument() native "return this.contentDocument;";

  DOMWindow get contentWindow() native "return this.contentWindow;";

  String get frameBorder() native "return this.frameBorder;";

  void set frameBorder(String value) native "this.frameBorder = value;";

  int get height() native "return this.height;";

  String get location() native "return this.location;";

  void set location(String value) native "this.location = value;";

  String get longDesc() native "return this.longDesc;";

  void set longDesc(String value) native "this.longDesc = value;";

  String get marginHeight() native "return this.marginHeight;";

  void set marginHeight(String value) native "this.marginHeight = value;";

  String get marginWidth() native "return this.marginWidth;";

  void set marginWidth(String value) native "this.marginWidth = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  bool get noResize() native "return this.noResize;";

  void set noResize(bool value) native "this.noResize = value;";

  String get scrolling() native "return this.scrolling;";

  void set scrolling(String value) native "this.scrolling = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  int get width() native "return this.width;";

  SVGDocument getSVGDocument() native;
}

class HTMLFrameSetElement extends HTMLElement native "*HTMLFrameSetElement" {

  String get cols() native "return this.cols;";

  void set cols(String value) native "this.cols = value;";

  String get rows() native "return this.rows;";

  void set rows(String value) native "this.rows = value;";
}

class HTMLHRElement extends HTMLElement native "*HTMLHRElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  bool get noShade() native "return this.noShade;";

  void set noShade(bool value) native "this.noShade = value;";

  String get size() native "return this.size;";

  void set size(String value) native "this.size = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";
}

class HTMLHeadElement extends HTMLElement native "*HTMLHeadElement" {

  String get profile() native "return this.profile;";

  void set profile(String value) native "this.profile = value;";
}

class HTMLHeadingElement extends HTMLElement native "*HTMLHeadingElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";
}

class HTMLHtmlElement extends HTMLElement native "*HTMLHtmlElement" {

  String get manifest() native "return this.manifest;";

  void set manifest(String value) native "this.manifest = value;";

  String get version() native "return this.version;";

  void set version(String value) native "this.version = value;";
}

class HTMLIFrameElement extends HTMLElement native "*HTMLIFrameElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  Document get contentDocument() native "return this.contentDocument;";

  DOMWindow get contentWindow() native "return this.contentWindow;";

  String get frameBorder() native "return this.frameBorder;";

  void set frameBorder(String value) native "this.frameBorder = value;";

  String get height() native "return this.height;";

  void set height(String value) native "this.height = value;";

  String get longDesc() native "return this.longDesc;";

  void set longDesc(String value) native "this.longDesc = value;";

  String get marginHeight() native "return this.marginHeight;";

  void set marginHeight(String value) native "this.marginHeight = value;";

  String get marginWidth() native "return this.marginWidth;";

  void set marginWidth(String value) native "this.marginWidth = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get sandbox() native "return this.sandbox;";

  void set sandbox(String value) native "this.sandbox = value;";

  String get scrolling() native "return this.scrolling;";

  void set scrolling(String value) native "this.scrolling = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  SVGDocument getSVGDocument() native;
}

class HTMLImageElement extends HTMLElement native "*HTMLImageElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get alt() native "return this.alt;";

  void set alt(String value) native "this.alt = value;";

  String get border() native "return this.border;";

  void set border(String value) native "this.border = value;";

  bool get complete() native "return this.complete;";

  String get crossOrigin() native "return this.crossOrigin;";

  void set crossOrigin(String value) native "this.crossOrigin = value;";

  int get height() native "return this.height;";

  void set height(int value) native "this.height = value;";

  int get hspace() native "return this.hspace;";

  void set hspace(int value) native "this.hspace = value;";

  bool get isMap() native "return this.isMap;";

  void set isMap(bool value) native "this.isMap = value;";

  String get longDesc() native "return this.longDesc;";

  void set longDesc(String value) native "this.longDesc = value;";

  String get lowsrc() native "return this.lowsrc;";

  void set lowsrc(String value) native "this.lowsrc = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  int get naturalHeight() native "return this.naturalHeight;";

  int get naturalWidth() native "return this.naturalWidth;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get useMap() native "return this.useMap;";

  void set useMap(String value) native "this.useMap = value;";

  int get vspace() native "return this.vspace;";

  void set vspace(int value) native "this.vspace = value;";

  int get width() native "return this.width;";

  void set width(int value) native "this.width = value;";

  int get x() native "return this.x;";

  int get y() native "return this.y;";
}

class HTMLInputElement extends HTMLElement native "*HTMLInputElement" {

  String get accept() native "return this.accept;";

  void set accept(String value) native "this.accept = value;";

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get alt() native "return this.alt;";

  void set alt(String value) native "this.alt = value;";

  String get autocomplete() native "return this.autocomplete;";

  void set autocomplete(String value) native "this.autocomplete = value;";

  bool get autofocus() native "return this.autofocus;";

  void set autofocus(bool value) native "this.autofocus = value;";

  bool get checked() native "return this.checked;";

  void set checked(bool value) native "this.checked = value;";

  bool get defaultChecked() native "return this.defaultChecked;";

  void set defaultChecked(bool value) native "this.defaultChecked = value;";

  String get defaultValue() native "return this.defaultValue;";

  void set defaultValue(String value) native "this.defaultValue = value;";

  String get dirName() native "return this.dirName;";

  void set dirName(String value) native "this.dirName = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  FileList get files() native "return this.files;";

  HTMLFormElement get form() native "return this.form;";

  String get formAction() native "return this.formAction;";

  void set formAction(String value) native "this.formAction = value;";

  String get formEnctype() native "return this.formEnctype;";

  void set formEnctype(String value) native "this.formEnctype = value;";

  String get formMethod() native "return this.formMethod;";

  void set formMethod(String value) native "this.formMethod = value;";

  bool get formNoValidate() native "return this.formNoValidate;";

  void set formNoValidate(bool value) native "this.formNoValidate = value;";

  String get formTarget() native "return this.formTarget;";

  void set formTarget(String value) native "this.formTarget = value;";

  bool get incremental() native "return this.incremental;";

  void set incremental(bool value) native "this.incremental = value;";

  bool get indeterminate() native "return this.indeterminate;";

  void set indeterminate(bool value) native "this.indeterminate = value;";

  NodeList get labels() native "return this.labels;";

  HTMLElement get list() native "return this.list;";

  String get max() native "return this.max;";

  void set max(String value) native "this.max = value;";

  int get maxLength() native "return this.maxLength;";

  void set maxLength(int value) native "this.maxLength = value;";

  String get min() native "return this.min;";

  void set min(String value) native "this.min = value;";

  bool get multiple() native "return this.multiple;";

  void set multiple(bool value) native "this.multiple = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get pattern() native "return this.pattern;";

  void set pattern(String value) native "this.pattern = value;";

  String get placeholder() native "return this.placeholder;";

  void set placeholder(String value) native "this.placeholder = value;";

  bool get readOnly() native "return this.readOnly;";

  void set readOnly(bool value) native "this.readOnly = value;";

  bool get required() native "return this.required;";

  void set required(bool value) native "this.required = value;";

  HTMLOptionElement get selectedOption() native "return this.selectedOption;";

  String get selectionDirection() native "return this.selectionDirection;";

  void set selectionDirection(String value) native "this.selectionDirection = value;";

  int get selectionEnd() native "return this.selectionEnd;";

  void set selectionEnd(int value) native "this.selectionEnd = value;";

  int get selectionStart() native "return this.selectionStart;";

  void set selectionStart(int value) native "this.selectionStart = value;";

  int get size() native "return this.size;";

  void set size(int value) native "this.size = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get step() native "return this.step;";

  void set step(String value) native "this.step = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  String get useMap() native "return this.useMap;";

  void set useMap(String value) native "this.useMap = value;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityState get validity() native "return this.validity;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  Date get valueAsDate() native "return this.valueAsDate;";

  void set valueAsDate(Date value) native "this.valueAsDate = value;";

  num get valueAsNumber() native "return this.valueAsNumber;";

  void set valueAsNumber(num value) native "this.valueAsNumber = value;";

  bool get webkitGrammar() native "return this.webkitGrammar;";

  void set webkitGrammar(bool value) native "this.webkitGrammar = value;";

  bool get webkitSpeech() native "return this.webkitSpeech;";

  void set webkitSpeech(bool value) native "this.webkitSpeech = value;";

  bool get webkitdirectory() native "return this.webkitdirectory;";

  void set webkitdirectory(bool value) native "this.webkitdirectory = value;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void click() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;

  void stepDown([int n = null]) native;

  void stepUp([int n = null]) native;
}

class HTMLIsIndexElement extends HTMLInputElement native "*HTMLIsIndexElement" {

  HTMLFormElement get form() native "return this.form;";

  String get prompt() native "return this.prompt;";

  void set prompt(String value) native "this.prompt = value;";
}

class HTMLKeygenElement extends HTMLElement native "*HTMLKeygenElement" {

  bool get autofocus() native "return this.autofocus;";

  void set autofocus(bool value) native "this.autofocus = value;";

  String get challenge() native "return this.challenge;";

  void set challenge(String value) native "this.challenge = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  HTMLFormElement get form() native "return this.form;";

  String get keytype() native "return this.keytype;";

  void set keytype(String value) native "this.keytype = value;";

  NodeList get labels() native "return this.labels;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get type() native "return this.type;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityState get validity() native "return this.validity;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class HTMLLIElement extends HTMLElement native "*HTMLLIElement" {

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  int get value() native "return this.value;";

  void set value(int value) native "this.value = value;";
}

class HTMLLabelElement extends HTMLElement native "*HTMLLabelElement" {

  HTMLElement get control() native "return this.control;";

  HTMLFormElement get form() native "return this.form;";

  String get htmlFor() native "return this.htmlFor;";

  void set htmlFor(String value) native "this.htmlFor = value;";
}

class HTMLLegendElement extends HTMLElement native "*HTMLLegendElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  HTMLFormElement get form() native "return this.form;";
}

class HTMLLinkElement extends HTMLElement native "*HTMLLinkElement" {

  String get charset() native "return this.charset;";

  void set charset(String value) native "this.charset = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  String get href() native "return this.href;";

  void set href(String value) native "this.href = value;";

  String get hreflang() native "return this.hreflang;";

  void set hreflang(String value) native "this.hreflang = value;";

  String get media() native "return this.media;";

  void set media(String value) native "this.media = value;";

  String get rel() native "return this.rel;";

  void set rel(String value) native "this.rel = value;";

  String get rev() native "return this.rev;";

  void set rev(String value) native "this.rev = value;";

  StyleSheet get sheet() native "return this.sheet;";

  DOMSettableTokenList get sizes() native "return this.sizes;";

  void set sizes(DOMSettableTokenList value) native "this.sizes = value;";

  String get target() native "return this.target;";

  void set target(String value) native "this.target = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}

class HTMLMapElement extends HTMLElement native "*HTMLMapElement" {

  HTMLCollection get areas() native "return this.areas;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";
}

class HTMLMarqueeElement extends HTMLElement native "*HTMLMarqueeElement" {

  String get behavior() native "return this.behavior;";

  void set behavior(String value) native "this.behavior = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  String get direction() native "return this.direction;";

  void set direction(String value) native "this.direction = value;";

  String get height() native "return this.height;";

  void set height(String value) native "this.height = value;";

  int get hspace() native "return this.hspace;";

  void set hspace(int value) native "this.hspace = value;";

  int get loop() native "return this.loop;";

  void set loop(int value) native "this.loop = value;";

  int get scrollAmount() native "return this.scrollAmount;";

  void set scrollAmount(int value) native "this.scrollAmount = value;";

  int get scrollDelay() native "return this.scrollDelay;";

  void set scrollDelay(int value) native "this.scrollDelay = value;";

  bool get trueSpeed() native "return this.trueSpeed;";

  void set trueSpeed(bool value) native "this.trueSpeed = value;";

  int get vspace() native "return this.vspace;";

  void set vspace(int value) native "this.vspace = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  void start() native;

  void stop() native;
}

class HTMLMediaElement extends HTMLElement native "*HTMLMediaElement" {

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

  bool get autoplay() native "return this.autoplay;";

  void set autoplay(bool value) native "this.autoplay = value;";

  TimeRanges get buffered() native "return this.buffered;";

  MediaController get controller() native "return this.controller;";

  void set controller(MediaController value) native "this.controller = value;";

  bool get controls() native "return this.controls;";

  void set controls(bool value) native "this.controls = value;";

  String get currentSrc() native "return this.currentSrc;";

  num get currentTime() native "return this.currentTime;";

  void set currentTime(num value) native "this.currentTime = value;";

  bool get defaultMuted() native "return this.defaultMuted;";

  void set defaultMuted(bool value) native "this.defaultMuted = value;";

  num get defaultPlaybackRate() native "return this.defaultPlaybackRate;";

  void set defaultPlaybackRate(num value) native "this.defaultPlaybackRate = value;";

  num get duration() native "return this.duration;";

  bool get ended() native "return this.ended;";

  MediaError get error() native "return this.error;";

  num get initialTime() native "return this.initialTime;";

  bool get loop() native "return this.loop;";

  void set loop(bool value) native "this.loop = value;";

  String get mediaGroup() native "return this.mediaGroup;";

  void set mediaGroup(String value) native "this.mediaGroup = value;";

  bool get muted() native "return this.muted;";

  void set muted(bool value) native "this.muted = value;";

  int get networkState() native "return this.networkState;";

  bool get paused() native "return this.paused;";

  num get playbackRate() native "return this.playbackRate;";

  void set playbackRate(num value) native "this.playbackRate = value;";

  TimeRanges get played() native "return this.played;";

  String get preload() native "return this.preload;";

  void set preload(String value) native "this.preload = value;";

  int get readyState() native "return this.readyState;";

  TimeRanges get seekable() native "return this.seekable;";

  bool get seeking() native "return this.seeking;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  num get startTime() native "return this.startTime;";

  TextTrackList get textTracks() native "return this.textTracks;";

  num get volume() native "return this.volume;";

  void set volume(num value) native "this.volume = value;";

  int get webkitAudioDecodedByteCount() native "return this.webkitAudioDecodedByteCount;";

  bool get webkitClosedCaptionsVisible() native "return this.webkitClosedCaptionsVisible;";

  void set webkitClosedCaptionsVisible(bool value) native "this.webkitClosedCaptionsVisible = value;";

  bool get webkitHasClosedCaptions() native "return this.webkitHasClosedCaptions;";

  String get webkitMediaSourceURL() native "return this.webkitMediaSourceURL;";

  bool get webkitPreservesPitch() native "return this.webkitPreservesPitch;";

  void set webkitPreservesPitch(bool value) native "this.webkitPreservesPitch = value;";

  int get webkitSourceState() native "return this.webkitSourceState;";

  int get webkitVideoDecodedByteCount() native "return this.webkitVideoDecodedByteCount;";

  TextTrack addTrack(String kind, [String label = null, String language = null]) native;

  String canPlayType(String type) native;

  void load() native;

  void pause() native;

  void play() native;

  void webkitSourceAppend(Uint8Array data) native;

  void webkitSourceEndOfStream(int status) native;
}

class HTMLMenuElement extends HTMLElement native "*HTMLMenuElement" {

  bool get compact() native "return this.compact;";

  void set compact(bool value) native "this.compact = value;";
}

class HTMLMetaElement extends HTMLElement native "*HTMLMetaElement" {

  String get content() native "return this.content;";

  void set content(String value) native "this.content = value;";

  String get httpEquiv() native "return this.httpEquiv;";

  void set httpEquiv(String value) native "this.httpEquiv = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get scheme() native "return this.scheme;";

  void set scheme(String value) native "this.scheme = value;";
}

class HTMLMeterElement extends HTMLElement native "*HTMLMeterElement" {

  HTMLFormElement get form() native "return this.form;";

  num get high() native "return this.high;";

  void set high(num value) native "this.high = value;";

  NodeList get labels() native "return this.labels;";

  num get low() native "return this.low;";

  void set low(num value) native "this.low = value;";

  num get max() native "return this.max;";

  void set max(num value) native "this.max = value;";

  num get min() native "return this.min;";

  void set min(num value) native "this.min = value;";

  num get optimum() native "return this.optimum;";

  void set optimum(num value) native "this.optimum = value;";

  num get value() native "return this.value;";

  void set value(num value) native "this.value = value;";
}

class HTMLModElement extends HTMLElement native "*HTMLModElement" {

  String get cite() native "return this.cite;";

  void set cite(String value) native "this.cite = value;";

  String get dateTime() native "return this.dateTime;";

  void set dateTime(String value) native "this.dateTime = value;";
}

class HTMLOListElement extends HTMLElement native "*HTMLOListElement" {

  bool get compact() native "return this.compact;";

  void set compact(bool value) native "this.compact = value;";

  bool get reversed() native "return this.reversed;";

  void set reversed(bool value) native "this.reversed = value;";

  int get start() native "return this.start;";

  void set start(int value) native "this.start = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}

class HTMLObjectElement extends HTMLElement native "*HTMLObjectElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get archive() native "return this.archive;";

  void set archive(String value) native "this.archive = value;";

  String get border() native "return this.border;";

  void set border(String value) native "this.border = value;";

  String get code() native "return this.code;";

  void set code(String value) native "this.code = value;";

  String get codeBase() native "return this.codeBase;";

  void set codeBase(String value) native "this.codeBase = value;";

  String get codeType() native "return this.codeType;";

  void set codeType(String value) native "this.codeType = value;";

  Document get contentDocument() native "return this.contentDocument;";

  String get data() native "return this.data;";

  void set data(String value) native "this.data = value;";

  bool get declare() native "return this.declare;";

  void set declare(bool value) native "this.declare = value;";

  HTMLFormElement get form() native "return this.form;";

  String get height() native "return this.height;";

  void set height(String value) native "this.height = value;";

  int get hspace() native "return this.hspace;";

  void set hspace(int value) native "this.hspace = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get standby() native "return this.standby;";

  void set standby(String value) native "this.standby = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  String get useMap() native "return this.useMap;";

  void set useMap(String value) native "this.useMap = value;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityState get validity() native "return this.validity;";

  int get vspace() native "return this.vspace;";

  void set vspace(int value) native "this.vspace = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  SVGDocument getSVGDocument() native;

  void setCustomValidity(String error) native;
}

class HTMLOptGroupElement extends HTMLElement native "*HTMLOptGroupElement" {

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  String get label() native "return this.label;";

  void set label(String value) native "this.label = value;";
}

class HTMLOptionElement extends HTMLElement native "*HTMLOptionElement" {

  bool get defaultSelected() native "return this.defaultSelected;";

  void set defaultSelected(bool value) native "this.defaultSelected = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  HTMLFormElement get form() native "return this.form;";

  int get index() native "return this.index;";

  String get label() native "return this.label;";

  void set label(String value) native "this.label = value;";

  bool get selected() native "return this.selected;";

  void set selected(bool value) native "this.selected = value;";

  String get text() native "return this.text;";

  void set text(String value) native "this.text = value;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";
}

class HTMLOptionsCollection extends HTMLCollection native "*HTMLOptionsCollection" {

  int get length() native "return this.length;";

  void set length(int value) native "this.length = value;";

  int get selectedIndex() native "return this.selectedIndex;";

  void set selectedIndex(int value) native "this.selectedIndex = value;";

  void remove(int index) native;
}

class HTMLOutputElement extends HTMLElement native "*HTMLOutputElement" {

  String get defaultValue() native "return this.defaultValue;";

  void set defaultValue(String value) native "this.defaultValue = value;";

  HTMLFormElement get form() native "return this.form;";

  DOMSettableTokenList get htmlFor() native "return this.htmlFor;";

  void set htmlFor(DOMSettableTokenList value) native "this.htmlFor = value;";

  NodeList get labels() native "return this.labels;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get type() native "return this.type;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityState get validity() native "return this.validity;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  bool get willValidate() native "return this.willValidate;";

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class HTMLParagraphElement extends HTMLElement native "*HTMLParagraphElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";
}

class HTMLParamElement extends HTMLElement native "*HTMLParamElement" {

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  String get valueType() native "return this.valueType;";

  void set valueType(String value) native "this.valueType = value;";
}

class HTMLPreElement extends HTMLElement native "*HTMLPreElement" {

  int get width() native "return this.width;";

  void set width(int value) native "this.width = value;";

  bool get wrap() native "return this.wrap;";

  void set wrap(bool value) native "this.wrap = value;";
}

class HTMLProgressElement extends HTMLElement native "*HTMLProgressElement" {

  HTMLFormElement get form() native "return this.form;";

  NodeList get labels() native "return this.labels;";

  num get max() native "return this.max;";

  void set max(num value) native "this.max = value;";

  num get position() native "return this.position;";

  num get value() native "return this.value;";

  void set value(num value) native "this.value = value;";
}

class HTMLPropertiesCollection extends HTMLCollection native "*HTMLPropertiesCollection" {

  int get length() native "return this.length;";

  Node item(int index) native;
}

class HTMLQuoteElement extends HTMLElement native "*HTMLQuoteElement" {

  String get cite() native "return this.cite;";

  void set cite(String value) native "this.cite = value;";
}

class HTMLScriptElement extends HTMLElement native "*HTMLScriptElement" {

  bool get async() native "return this.async;";

  void set async(bool value) native "this.async = value;";

  String get charset() native "return this.charset;";

  void set charset(String value) native "this.charset = value;";

  bool get defer() native "return this.defer;";

  void set defer(bool value) native "this.defer = value;";

  String get event() native "return this.event;";

  void set event(String value) native "this.event = value;";

  String get htmlFor() native "return this.htmlFor;";

  void set htmlFor(String value) native "this.htmlFor = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get text() native "return this.text;";

  void set text(String value) native "this.text = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}

class HTMLSelectElement extends HTMLElement native "*HTMLSelectElement" {

  bool get autofocus() native "return this.autofocus;";

  void set autofocus(bool value) native "this.autofocus = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  HTMLFormElement get form() native "return this.form;";

  NodeList get labels() native "return this.labels;";

  int get length() native "return this.length;";

  void set length(int value) native "this.length = value;";

  bool get multiple() native "return this.multiple;";

  void set multiple(bool value) native "this.multiple = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  HTMLOptionsCollection get options() native "return this.options;";

  bool get required() native "return this.required;";

  void set required(bool value) native "this.required = value;";

  int get selectedIndex() native "return this.selectedIndex;";

  void set selectedIndex(int value) native "this.selectedIndex = value;";

  int get size() native "return this.size;";

  void set size(int value) native "this.size = value;";

  String get type() native "return this.type;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityState get validity() native "return this.validity;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  bool get willValidate() native "return this.willValidate;";

  void add(HTMLElement element, HTMLElement before) native;

  bool checkValidity() native;

  Node item(int index) native;

  Node namedItem(String name) native;

  void remove(var index_OR_option) native;

  void setCustomValidity(String error) native;
}

class HTMLSourceElement extends HTMLElement native "*HTMLSourceElement" {

  String get media() native "return this.media;";

  void set media(String value) native "this.media = value;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}

class HTMLSpanElement extends HTMLElement native "*HTMLSpanElement" {
}

class HTMLStyleElement extends HTMLElement native "*HTMLStyleElement" {

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  String get media() native "return this.media;";

  void set media(String value) native "this.media = value;";

  bool get scoped() native "return this.scoped;";

  void set scoped(bool value) native "this.scoped = value;";

  StyleSheet get sheet() native "return this.sheet;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}

class HTMLTableCaptionElement extends HTMLElement native "*HTMLTableCaptionElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";
}

class HTMLTableCellElement extends HTMLElement native "*HTMLTableCellElement" {

  String get abbr() native "return this.abbr;";

  void set abbr(String value) native "this.abbr = value;";

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get axis() native "return this.axis;";

  void set axis(String value) native "this.axis = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  int get cellIndex() native "return this.cellIndex;";

  String get ch() native "return this.ch;";

  void set ch(String value) native "this.ch = value;";

  String get chOff() native "return this.chOff;";

  void set chOff(String value) native "this.chOff = value;";

  int get colSpan() native "return this.colSpan;";

  void set colSpan(int value) native "this.colSpan = value;";

  String get headers() native "return this.headers;";

  void set headers(String value) native "this.headers = value;";

  String get height() native "return this.height;";

  void set height(String value) native "this.height = value;";

  bool get noWrap() native "return this.noWrap;";

  void set noWrap(bool value) native "this.noWrap = value;";

  int get rowSpan() native "return this.rowSpan;";

  void set rowSpan(int value) native "this.rowSpan = value;";

  String get scope() native "return this.scope;";

  void set scope(String value) native "this.scope = value;";

  String get vAlign() native "return this.vAlign;";

  void set vAlign(String value) native "this.vAlign = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";
}

class HTMLTableColElement extends HTMLElement native "*HTMLTableColElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get ch() native "return this.ch;";

  void set ch(String value) native "this.ch = value;";

  String get chOff() native "return this.chOff;";

  void set chOff(String value) native "this.chOff = value;";

  int get span() native "return this.span;";

  void set span(int value) native "this.span = value;";

  String get vAlign() native "return this.vAlign;";

  void set vAlign(String value) native "this.vAlign = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";
}

class HTMLTableElement extends HTMLElement native "*HTMLTableElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  String get border() native "return this.border;";

  void set border(String value) native "this.border = value;";

  HTMLTableCaptionElement get caption() native "return this.caption;";

  void set caption(HTMLTableCaptionElement value) native "this.caption = value;";

  String get cellPadding() native "return this.cellPadding;";

  void set cellPadding(String value) native "this.cellPadding = value;";

  String get cellSpacing() native "return this.cellSpacing;";

  void set cellSpacing(String value) native "this.cellSpacing = value;";

  String get frame() native "return this.frame;";

  void set frame(String value) native "this.frame = value;";

  HTMLCollection get rows() native "return this.rows;";

  String get rules() native "return this.rules;";

  void set rules(String value) native "this.rules = value;";

  String get summary() native "return this.summary;";

  void set summary(String value) native "this.summary = value;";

  HTMLCollection get tBodies() native "return this.tBodies;";

  HTMLTableSectionElement get tFoot() native "return this.tFoot;";

  void set tFoot(HTMLTableSectionElement value) native "this.tFoot = value;";

  HTMLTableSectionElement get tHead() native "return this.tHead;";

  void set tHead(HTMLTableSectionElement value) native "this.tHead = value;";

  String get width() native "return this.width;";

  void set width(String value) native "this.width = value;";

  HTMLElement createCaption() native;

  HTMLElement createTFoot() native;

  HTMLElement createTHead() native;

  void deleteCaption() native;

  void deleteRow(int index) native;

  void deleteTFoot() native;

  void deleteTHead() native;

  HTMLElement insertRow(int index) native;
}

class HTMLTableRowElement extends HTMLElement native "*HTMLTableRowElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get bgColor() native "return this.bgColor;";

  void set bgColor(String value) native "this.bgColor = value;";

  HTMLCollection get cells() native "return this.cells;";

  String get ch() native "return this.ch;";

  void set ch(String value) native "this.ch = value;";

  String get chOff() native "return this.chOff;";

  void set chOff(String value) native "this.chOff = value;";

  int get rowIndex() native "return this.rowIndex;";

  int get sectionRowIndex() native "return this.sectionRowIndex;";

  String get vAlign() native "return this.vAlign;";

  void set vAlign(String value) native "this.vAlign = value;";

  void deleteCell(int index) native;

  HTMLElement insertCell(int index) native;
}

class HTMLTableSectionElement extends HTMLElement native "*HTMLTableSectionElement" {

  String get align() native "return this.align;";

  void set align(String value) native "this.align = value;";

  String get ch() native "return this.ch;";

  void set ch(String value) native "this.ch = value;";

  String get chOff() native "return this.chOff;";

  void set chOff(String value) native "this.chOff = value;";

  HTMLCollection get rows() native "return this.rows;";

  String get vAlign() native "return this.vAlign;";

  void set vAlign(String value) native "this.vAlign = value;";

  void deleteRow(int index) native;

  HTMLElement insertRow(int index) native;
}

class HTMLTextAreaElement extends HTMLElement native "*HTMLTextAreaElement" {

  bool get autofocus() native "return this.autofocus;";

  void set autofocus(bool value) native "this.autofocus = value;";

  int get cols() native "return this.cols;";

  void set cols(int value) native "this.cols = value;";

  String get defaultValue() native "return this.defaultValue;";

  void set defaultValue(String value) native "this.defaultValue = value;";

  String get dirName() native "return this.dirName;";

  void set dirName(String value) native "this.dirName = value;";

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  HTMLFormElement get form() native "return this.form;";

  NodeList get labels() native "return this.labels;";

  int get maxLength() native "return this.maxLength;";

  void set maxLength(int value) native "this.maxLength = value;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  String get placeholder() native "return this.placeholder;";

  void set placeholder(String value) native "this.placeholder = value;";

  bool get readOnly() native "return this.readOnly;";

  void set readOnly(bool value) native "this.readOnly = value;";

  bool get required() native "return this.required;";

  void set required(bool value) native "this.required = value;";

  int get rows() native "return this.rows;";

  void set rows(int value) native "this.rows = value;";

  String get selectionDirection() native "return this.selectionDirection;";

  void set selectionDirection(String value) native "this.selectionDirection = value;";

  int get selectionEnd() native "return this.selectionEnd;";

  void set selectionEnd(int value) native "this.selectionEnd = value;";

  int get selectionStart() native "return this.selectionStart;";

  void set selectionStart(int value) native "this.selectionStart = value;";

  int get textLength() native "return this.textLength;";

  String get type() native "return this.type;";

  String get validationMessage() native "return this.validationMessage;";

  ValidityState get validity() native "return this.validity;";

  String get value() native "return this.value;";

  void set value(String value) native "this.value = value;";

  bool get willValidate() native "return this.willValidate;";

  String get wrap() native "return this.wrap;";

  void set wrap(String value) native "this.wrap = value;";

  bool checkValidity() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;
}

class HTMLTitleElement extends HTMLElement native "*HTMLTitleElement" {

  String get text() native "return this.text;";

  void set text(String value) native "this.text = value;";
}

class HTMLTrackElement extends HTMLElement native "*HTMLTrackElement" {

  static final int ERROR = 3;

  static final int LOADED = 2;

  static final int LOADING = 1;

  static final int NONE = 0;

  bool get isDefault() native "return this.isDefault;";

  void set isDefault(bool value) native "this.isDefault = value;";

  String get kind() native "return this.kind;";

  void set kind(String value) native "this.kind = value;";

  String get label() native "return this.label;";

  void set label(String value) native "this.label = value;";

  int get readyState() native "return this.readyState;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  String get srclang() native "return this.srclang;";

  void set srclang(String value) native "this.srclang = value;";

  TextTrack get track() native "return this.track;";
}

class HTMLUListElement extends HTMLElement native "*HTMLUListElement" {

  bool get compact() native "return this.compact;";

  void set compact(bool value) native "this.compact = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}

class HTMLUnknownElement extends HTMLElement native "*HTMLUnknownElement" {
}

class HTMLVideoElement extends HTMLMediaElement native "*HTMLVideoElement" {

  int get height() native "return this.height;";

  void set height(int value) native "this.height = value;";

  String get poster() native "return this.poster;";

  void set poster(String value) native "this.poster = value;";

  int get videoHeight() native "return this.videoHeight;";

  int get videoWidth() native "return this.videoWidth;";

  int get webkitDecodedFrameCount() native "return this.webkitDecodedFrameCount;";

  bool get webkitDisplayingFullscreen() native "return this.webkitDisplayingFullscreen;";

  int get webkitDroppedFrameCount() native "return this.webkitDroppedFrameCount;";

  bool get webkitSupportsFullscreen() native "return this.webkitSupportsFullscreen;";

  int get width() native "return this.width;";

  void set width(int value) native "this.width = value;";

  void webkitEnterFullScreen() native;

  void webkitEnterFullscreen() native;

  void webkitExitFullScreen() native;

  void webkitExitFullscreen() native;
}

class HashChangeEvent extends Event native "*HashChangeEvent" {

  String get newURL() native "return this.newURL;";

  String get oldURL() native "return this.oldURL;";

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native;
}

class HighPass2FilterNode extends AudioNode native "*HighPass2FilterNode" {

  AudioParam get cutoff() native "return this.cutoff;";

  AudioParam get resonance() native "return this.resonance;";
}

class History native "*History" {

  int get length() native "return this.length;";

  void back() native;

  void forward() native;

  void go(int distance) native;

  void pushState(Object data, String title, [String url = null]) native;

  void replaceState(Object data, String title, [String url = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBAny native "*IDBAny" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBCursor native "*IDBCursor" {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

  int get direction() native "return this.direction;";

  IDBKey get key() native "return this.key;";

  IDBKey get primaryKey() native "return this.primaryKey;";

  IDBAny get source() native "return this.source;";

  void continueFunction([IDBKey key = null]) native;

  IDBRequest delete() native;

  IDBRequest update(String value) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBCursorWithValue extends IDBCursor native "*IDBCursorWithValue" {

  IDBAny get value() native "return this.value;";
}

class IDBDatabase native "*IDBDatabase" {

  String get name() native "return this.name;";

  EventListener get onabort() native "return this.onabort;";

  void set onabort(EventListener value) native "this.onabort = value;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  EventListener get onversionchange() native "return this.onversionchange;";

  void set onversionchange(EventListener value) native "this.onversionchange = value;";

  String get version() native "return this.version;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  IDBObjectStore createObjectStore(String name) native;

  void deleteObjectStore(String name) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  IDBVersionChangeRequest setVersion(String version) native;

  IDBTransaction transaction(String storeName, int mode) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBDatabaseError native "*IDBDatabaseError" {

  int get code() native "return this.code;";

  void set code(int value) native "this.code = value;";

  String get message() native "return this.message;";

  void set message(String value) native "this.message = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBDatabaseException native "*IDBDatabaseException" {

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

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBFactory native "*IDBFactory" {

  int cmp(IDBKey first, IDBKey second) native;

  IDBVersionChangeRequest deleteDatabase(String name) native;

  IDBRequest getDatabaseNames() native;

  IDBRequest open(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBIndex native "*IDBIndex" {

  String get keyPath() native "return this.keyPath;";

  bool get multiEntry() native "return this.multiEntry;";

  String get name() native "return this.name;";

  IDBObjectStore get objectStore() native "return this.objectStore;";

  bool get unique() native "return this.unique;";

  IDBRequest count([IDBKeyRange range = null]) native;

  IDBRequest getObject(IDBKey key) native;

  IDBRequest getKey(IDBKey key) native;

  IDBRequest openCursor([IDBKeyRange range = null, int direction = null]) native;

  IDBRequest openKeyCursor([IDBKeyRange range = null, int direction = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBKey native "*IDBKey" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBKeyRange native "*IDBKeyRange" {

  IDBKey get lower() native "return this.lower;";

  bool get lowerOpen() native "return this.lowerOpen;";

  IDBKey get upper() native "return this.upper;";

  bool get upperOpen() native "return this.upperOpen;";

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  IDBKeyRange lowerBound(IDBKey bound, [bool open = null]) native;

  IDBKeyRange only(IDBKey value) native;

  IDBKeyRange upperBound(IDBKey bound, [bool open = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBObjectStore native "*IDBObjectStore" {

  String get keyPath() native "return this.keyPath;";

  String get name() native "return this.name;";

  IDBTransaction get transaction() native "return this.transaction;";

  IDBRequest add(String value, [IDBKey key = null]) native;

  IDBRequest clear() native;

  IDBRequest count([IDBKeyRange range = null]) native;

  IDBIndex createIndex(String name, String keyPath) native;

  IDBRequest delete(IDBKey key) native;

  void deleteIndex(String name) native;

  IDBRequest getObject(IDBKey key) native;

  IDBIndex index(String name) native;

  IDBRequest openCursor([IDBKeyRange range = null, int direction = null]) native;

  IDBRequest put(String value, [IDBKey key = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBRequest native "*IDBRequest" {

  static final int DONE = 2;

  static final int LOADING = 1;

  int get errorCode() native "return this.errorCode;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  EventListener get onsuccess() native "return this.onsuccess;";

  void set onsuccess(EventListener value) native "this.onsuccess = value;";

  int get readyState() native "return this.readyState;";

  IDBAny get result() native "return this.result;";

  IDBAny get source() native "return this.source;";

  IDBTransaction get transaction() native "return this.transaction;";

  String get webkitErrorMessage() native "return this.webkitErrorMessage;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBTransaction native "*IDBTransaction" {

  static final int READ_ONLY = 0;

  static final int READ_WRITE = 1;

  static final int VERSION_CHANGE = 2;

  IDBDatabase get db() native "return this.db;";

  int get mode() native "return this.mode;";

  EventListener get onabort() native "return this.onabort;";

  void set onabort(EventListener value) native "this.onabort = value;";

  EventListener get oncomplete() native "return this.oncomplete;";

  void set oncomplete(EventListener value) native "this.oncomplete = value;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  IDBObjectStore objectStore(String name) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBVersionChangeEvent extends Event native "*IDBVersionChangeEvent" {

  String get version() native "return this.version;";
}

class IDBVersionChangeRequest extends IDBRequest native "*IDBVersionChangeRequest" {

  EventListener get onblocked() native "return this.onblocked;";

  void set onblocked(EventListener value) native "this.onblocked = value;";
}

class ImageData native "*ImageData" {

  CanvasPixelArray get data() native "return this.data;";

  int get height() native "return this.height;";

  int get width() native "return this.width;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class InjectedScriptHost native "*InjectedScriptHost" {

  void clearConsoleMessages() native;

  void copyText(String text) native;

  int databaseId(Object database) native;

  void didCreateWorker(int id, String url, bool isFakeWorker) native;

  void didDestroyWorker(int id) native;

  Object evaluate(String text) native;

  Object functionLocation(Object object) native;

  void inspect(Object objectId, Object hints) native;

  Object inspectedNode(int num) native;

  Object internalConstructorName(Object object) native;

  bool isHTMLAllCollection(Object object) native;

  int nextWorkerId() native;

  int storageId(Object storage) native;

  String type(Object object) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class InspectorFrontendHost native "*InspectorFrontendHost" {

  void bringToFront() native;

  bool canSaveAs() native;

  void closeWindow() native;

  void copyText(String text) native;

  String hiddenPanels() native;

  void inspectedURLChanged(String newURL) native;

  String loadResourceSynchronously(String url) native;

  void loaded() native;

  String localizedStringsURL() native;

  void moveWindowBy(num x, num y) native;

  String platform() native;

  String port() native;

  void recordActionTaken(int actionCode) native;

  void recordPanelShown(int panelCode) native;

  void recordSettingChanged(int settingChanged) native;

  void requestAttachWindow() native;

  void requestDetachWindow() native;

  void requestSetDockSide(String side) native;

  void saveAs(String fileName, String content) native;

  void sendMessageToBackend(String message) native;

  void setAttachedWindowHeight(int height) native;

  void setInjectedScriptForOrigin(String origin, String script) native;

  void showContextMenu(MouseEvent event, Object items) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Int16Array extends ArrayBufferView implements List<int> native "*Int16Array" {

  factory Int16Array(int length) =>  _construct(length);

  factory Int16Array.fromList(List<int> list) => _construct(list);

  factory Int16Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Int16Array(arg);';

  static final int BYTES_PER_ELEMENT = 2;

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  Int16Array subarray(int start, [int end = null]) native;
}

class Int32Array extends ArrayBufferView implements List<int> native "*Int32Array" {

  factory Int32Array(int length) =>  _construct(length);

  factory Int32Array.fromList(List<int> list) => _construct(list);

  factory Int32Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Int32Array(arg);';

  static final int BYTES_PER_ELEMENT = 4;

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  Int32Array subarray(int start, [int end = null]) native;
}

class Int8Array extends ArrayBufferView implements List<int> native "*Int8Array" {

  factory Int8Array(int length) =>  _construct(length);

  factory Int8Array.fromList(List<int> list) => _construct(list);

  factory Int8Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Int8Array(arg);';

  static final int BYTES_PER_ELEMENT = 1;

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  Int8Array subarray(int start, [int end = null]) native;
}

class JavaScriptAudioNode extends AudioNode native "*JavaScriptAudioNode" {

  int get bufferSize() native "return this.bufferSize;";

  EventListener get onaudioprocess() native "return this.onaudioprocess;";

  void set onaudioprocess(EventListener value) native "this.onaudioprocess = value;";
}

class JavaScriptCallFrame native "*JavaScriptCallFrame" {

  static final int CATCH_SCOPE = 4;

  static final int CLOSURE_SCOPE = 3;

  static final int GLOBAL_SCOPE = 0;

  static final int LOCAL_SCOPE = 1;

  static final int WITH_SCOPE = 2;

  JavaScriptCallFrame get caller() native "return this.caller;";

  int get column() native "return this.column;";

  String get functionName() native "return this.functionName;";

  int get line() native "return this.line;";

  List get scopeChain() native "return this.scopeChain;";

  int get sourceID() native "return this.sourceID;";

  String get type() native "return this.type;";

  void evaluate(String script) native;

  int scopeType(int scopeIndex) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class KeyboardEvent extends UIEvent native "*KeyboardEvent" {

  bool get altGraphKey() native "return this.altGraphKey;";

  bool get altKey() native "return this.altKey;";

  bool get ctrlKey() native "return this.ctrlKey;";

  String get keyIdentifier() native "return this.keyIdentifier;";

  int get keyLocation() native "return this.keyLocation;";

  bool get metaKey() native "return this.metaKey;";

  bool get shiftKey() native "return this.shiftKey;";

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, DOMWindow view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) native;
}

class Location native "*Location" {

  String get hash() native "return this.hash;";

  void set hash(String value) native "this.hash = value;";

  String get host() native "return this.host;";

  void set host(String value) native "this.host = value;";

  String get hostname() native "return this.hostname;";

  void set hostname(String value) native "this.hostname = value;";

  String get href() native "return this.href;";

  void set href(String value) native "this.href = value;";

  String get origin() native "return this.origin;";

  String get pathname() native "return this.pathname;";

  void set pathname(String value) native "this.pathname = value;";

  String get port() native "return this.port;";

  void set port(String value) native "this.port = value;";

  String get protocol() native "return this.protocol;";

  void set protocol(String value) native "this.protocol = value;";

  String get search() native "return this.search;";

  void set search(String value) native "this.search = value;";

  void assign(String url) native;

  void reload() native;

  void replace(String url) native;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class LowPass2FilterNode extends AudioNode native "*LowPass2FilterNode" {

  AudioParam get cutoff() native "return this.cutoff;";

  AudioParam get resonance() native "return this.resonance;";
}

class MediaController native "*MediaController" {

  TimeRanges get buffered() native "return this.buffered;";

  num get currentTime() native "return this.currentTime;";

  void set currentTime(num value) native "this.currentTime = value;";

  num get defaultPlaybackRate() native "return this.defaultPlaybackRate;";

  void set defaultPlaybackRate(num value) native "this.defaultPlaybackRate = value;";

  num get duration() native "return this.duration;";

  bool get muted() native "return this.muted;";

  void set muted(bool value) native "this.muted = value;";

  bool get paused() native "return this.paused;";

  num get playbackRate() native "return this.playbackRate;";

  void set playbackRate(num value) native "this.playbackRate = value;";

  TimeRanges get played() native "return this.played;";

  TimeRanges get seekable() native "return this.seekable;";

  num get volume() native "return this.volume;";

  void set volume(num value) native "this.volume = value;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void pause() native;

  void play() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MediaElementAudioSourceNode extends AudioSourceNode native "*MediaElementAudioSourceNode" {

  HTMLMediaElement get mediaElement() native "return this.mediaElement;";
}

class MediaError native "*MediaError" {

  static final int MEDIA_ERR_ABORTED = 1;

  static final int MEDIA_ERR_DECODE = 3;

  static final int MEDIA_ERR_NETWORK = 2;

  static final int MEDIA_ERR_SRC_NOT_SUPPORTED = 4;

  int get code() native "return this.code;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MediaList native "*MediaList" {

  int get length() native "return this.length;";

  String get mediaText() native "return this.mediaText;";

  void set mediaText(String value) native "this.mediaText = value;";

  String operator[](int index) native;

  void operator[]=(int index, String value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void appendMedium(String newMedium) native;

  void deleteMedium(String oldMedium) native;

  String item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MediaQueryList native "*MediaQueryList" {

  bool get matches() native "return this.matches;";

  String get media() native "return this.media;";

  void addListener(MediaQueryListListener listener) native;

  void removeListener(MediaQueryListListener listener) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MediaQueryListListener native "*MediaQueryListListener" {

  void queryChanged(MediaQueryList list) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MemoryInfo native "*MemoryInfo" {

  int get jsHeapSizeLimit() native "return this.jsHeapSizeLimit;";

  int get totalJSHeapSize() native "return this.totalJSHeapSize;";

  int get usedJSHeapSize() native "return this.usedJSHeapSize;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MessageChannel native "*MessageChannel" {

  MessagePort get port1() native "return this.port1;";

  MessagePort get port2() native "return this.port2;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MessageEvent extends Event native "*MessageEvent" {

  Object get data() native "return this.data;";

  String get lastEventId() native "return this.lastEventId;";

  String get origin() native "return this.origin;";

  List get ports() native "return this.ports;";

  DOMWindow get source() native "return this.source;";

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, DOMWindow sourceArg, List messagePorts) native;

  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, DOMWindow sourceArg, List transferables) native;
}

class MessagePort native "*MessagePort" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  bool dispatchEvent(Event evt) native;

  void postMessage(String message, [List messagePorts = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void start() native;

  void webkitPostMessage(String message, [List transfer = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Metadata native "*Metadata" {

  Date get modificationTime() native "return this.modificationTime;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool MetadataCallback(Metadata metadata);

class MouseEvent extends UIEvent native "*MouseEvent" {

  bool get altKey() native "return this.altKey;";

  int get button() native "return this.button;";

  int get clientX() native "return this.clientX;";

  int get clientY() native "return this.clientY;";

  bool get ctrlKey() native "return this.ctrlKey;";

  Clipboard get dataTransfer() native "return this.dataTransfer;";

  Node get fromElement() native "return this.fromElement;";

  bool get metaKey() native "return this.metaKey;";

  int get offsetX() native "return this.offsetX;";

  int get offsetY() native "return this.offsetY;";

  EventTarget get relatedTarget() native "return this.relatedTarget;";

  int get screenX() native "return this.screenX;";

  int get screenY() native "return this.screenY;";

  bool get shiftKey() native "return this.shiftKey;";

  Node get toElement() native "return this.toElement;";

  int get webkitMovementX() native "return this.webkitMovementX;";

  int get webkitMovementY() native "return this.webkitMovementY;";

  int get x() native "return this.x;";

  int get y() native "return this.y;";

  void initMouseEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) native;
}

class MutationCallback native "*MutationCallback" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MutationEvent extends Event native "*MutationEvent" {

  static final int ADDITION = 2;

  static final int MODIFICATION = 1;

  static final int REMOVAL = 3;

  int get attrChange() native "return this.attrChange;";

  String get attrName() native "return this.attrName;";

  String get newValue() native "return this.newValue;";

  String get prevValue() native "return this.prevValue;";

  Node get relatedNode() native "return this.relatedNode;";

  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange) native;
}

class MutationRecord native "*MutationRecord" {

  NodeList get addedNodes() native "return this.addedNodes;";

  String get attributeName() native "return this.attributeName;";

  String get attributeNamespace() native "return this.attributeNamespace;";

  Node get nextSibling() native "return this.nextSibling;";

  String get oldValue() native "return this.oldValue;";

  Node get previousSibling() native "return this.previousSibling;";

  NodeList get removedNodes() native "return this.removedNodes;";

  Node get target() native "return this.target;";

  String get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NamedNodeMap native "*NamedNodeMap" {

  int get length() native "return this.length;";

  Node operator[](int index) native;

  void operator[]=(int index, Node value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  Node getNamedItem(String name) native;

  Node getNamedItemNS(String namespaceURI, String localName) native;

  Node item(int index) native;

  Node removeNamedItem(String name) native;

  Node removeNamedItemNS(String namespaceURI, String localName) native;

  Node setNamedItem(Node node) native;

  Node setNamedItemNS(Node node) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Navigator native "*Navigator" {

  String get appCodeName() native "return this.appCodeName;";

  String get appName() native "return this.appName;";

  String get appVersion() native "return this.appVersion;";

  bool get cookieEnabled() native "return this.cookieEnabled;";

  Geolocation get geolocation() native "return this.geolocation;";

  String get language() native "return this.language;";

  DOMMimeTypeArray get mimeTypes() native "return this.mimeTypes;";

  bool get onLine() native "return this.onLine;";

  String get platform() native "return this.platform;";

  DOMPluginArray get plugins() native "return this.plugins;";

  String get product() native "return this.product;";

  String get productSub() native "return this.productSub;";

  String get userAgent() native "return this.userAgent;";

  String get vendor() native "return this.vendor;";

  String get vendorSub() native "return this.vendorSub;";

  void getStorageUpdates() native;

  bool javaEnabled() native;

  void registerProtocolHandler(String scheme, String url, String title) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Node native "*Node" {

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

  NamedNodeMap get attributes() native "return this.attributes;";

  String get baseURI() native "return this.baseURI;";

  NodeList get childNodes() native "return this.childNodes;";

  Node get firstChild() native "return this.firstChild;";

  Node get lastChild() native "return this.lastChild;";

  String get localName() native "return this.localName;";

  String get namespaceURI() native "return this.namespaceURI;";

  Node get nextSibling() native "return this.nextSibling;";

  String get nodeName() native "return this.nodeName;";

  int get nodeType() native "return this.nodeType;";

  String get nodeValue() native "return this.nodeValue;";

  void set nodeValue(String value) native "this.nodeValue = value;";

  Document get ownerDocument() native "return this.ownerDocument;";

  Element get parentElement() native "return this.parentElement;";

  Node get parentNode() native "return this.parentNode;";

  String get prefix() native "return this.prefix;";

  void set prefix(String value) native "this.prefix = value;";

  Node get previousSibling() native "return this.previousSibling;";

  String get textContent() native "return this.textContent;";

  void set textContent(String value) native "this.textContent = value;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  Node appendChild(Node newChild) native;

  Node cloneNode(bool deep) native;

  int compareDocumentPosition(Node other) native;

  bool contains(Node other) native;

  bool dispatchEvent(Event event) native;

  bool hasAttributes() native;

  bool hasChildNodes() native;

  Node insertBefore(Node newChild, Node refChild) native;

  bool isDefaultNamespace(String namespaceURI) native;

  bool isEqualNode(Node other) native;

  bool isSameNode(Node other) native;

  bool isSupported(String feature, String version) native;

  String lookupNamespaceURI(String prefix) native;

  String lookupPrefix(String namespaceURI) native;

  void normalize() native;

  Node removeChild(Node oldChild) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  Node replaceChild(Node newChild, Node oldChild) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NodeFilter native "*NodeFilter" {

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

  int acceptNode(Node n) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NodeIterator native "*NodeIterator" {

  bool get expandEntityReferences() native "return this.expandEntityReferences;";

  NodeFilter get filter() native "return this.filter;";

  bool get pointerBeforeReferenceNode() native "return this.pointerBeforeReferenceNode;";

  Node get referenceNode() native "return this.referenceNode;";

  Node get root() native "return this.root;";

  int get whatToShow() native "return this.whatToShow;";

  void detach() native;

  Node nextNode() native;

  Node previousNode() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NodeList native "*NodeList" {

  int get length() native "return this.length;";

  Node operator[](int index) native;

  void operator[]=(int index, Node value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  Node item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NodeSelector native "*NodeSelector" {

  Element querySelector(String selectors) native;

  NodeList querySelectorAll(String selectors) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Notation extends Node native "*Notation" {

  String get publicId() native "return this.publicId;";

  String get systemId() native "return this.systemId;";
}

class Notification native "*Notification" {

  String get dir() native "return this.dir;";

  void set dir(String value) native "this.dir = value;";

  String get replaceId() native "return this.replaceId;";

  void set replaceId(String value) native "this.replaceId = value;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void cancel() native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void show() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NotificationCenter native "*NotificationCenter" {

  int checkPermission() native;

  Notification createHTMLNotification(String url) native;

  Notification createNotification(String iconUrl, String title, String body) native;

  void requestPermission(VoidCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class OESStandardDerivatives native "*OESStandardDerivatives" {

  static final int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class OESTextureFloat native "*OESTextureFloat" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class OESVertexArrayObject native "*OESVertexArrayObject" {

  static final int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  WebGLVertexArrayObjectOES createVertexArrayOES() native;

  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class OfflineAudioCompletionEvent extends Event native "*OfflineAudioCompletionEvent" {

  AudioBuffer get renderedBuffer() native "return this.renderedBuffer;";
}

class OperationNotAllowedException native "*OperationNotAllowedException" {

  static final int NOT_ALLOWED_ERR = 1;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class OverflowEvent extends Event native "*OverflowEvent" {

  static final int BOTH = 2;

  static final int HORIZONTAL = 0;

  static final int VERTICAL = 1;

  bool get horizontalOverflow() native "return this.horizontalOverflow;";

  int get orient() native "return this.orient;";

  bool get verticalOverflow() native "return this.verticalOverflow;";
}

class PageTransitionEvent extends Event native "*PageTransitionEvent" {

  bool get persisted() native "return this.persisted;";
}

class Performance native "*Performance" {

  MemoryInfo get memory() native "return this.memory;";

  PerformanceNavigation get navigation() native "return this.navigation;";

  PerformanceTiming get timing() native "return this.timing;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class PerformanceNavigation native "*PerformanceNavigation" {

  static final int TYPE_BACK_FORWARD = 2;

  static final int TYPE_NAVIGATE = 0;

  static final int TYPE_RELOAD = 1;

  static final int TYPE_RESERVED = 255;

  int get redirectCount() native "return this.redirectCount;";

  int get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class PerformanceTiming native "*PerformanceTiming" {

  int get connectEnd() native "return this.connectEnd;";

  int get connectStart() native "return this.connectStart;";

  int get domComplete() native "return this.domComplete;";

  int get domContentLoadedEventEnd() native "return this.domContentLoadedEventEnd;";

  int get domContentLoadedEventStart() native "return this.domContentLoadedEventStart;";

  int get domInteractive() native "return this.domInteractive;";

  int get domLoading() native "return this.domLoading;";

  int get domainLookupEnd() native "return this.domainLookupEnd;";

  int get domainLookupStart() native "return this.domainLookupStart;";

  int get fetchStart() native "return this.fetchStart;";

  int get loadEventEnd() native "return this.loadEventEnd;";

  int get loadEventStart() native "return this.loadEventStart;";

  int get navigationStart() native "return this.navigationStart;";

  int get redirectEnd() native "return this.redirectEnd;";

  int get redirectStart() native "return this.redirectStart;";

  int get requestStart() native "return this.requestStart;";

  int get responseEnd() native "return this.responseEnd;";

  int get responseStart() native "return this.responseStart;";

  int get secureConnectionStart() native "return this.secureConnectionStart;";

  int get unloadEventEnd() native "return this.unloadEventEnd;";

  int get unloadEventStart() native "return this.unloadEventStart;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class PointerLock native "*PointerLock" {

  bool get isLocked() native "return this.isLocked;";

  void lock(Element target, [VoidCallback successCallback = null, VoidCallback failureCallback = null]) native;

  void unlock() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class PopStateEvent extends Event native "*PopStateEvent" {

  Object get state() native "return this.state;";
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool PositionCallback(Geoposition position);

class PositionError native "*PositionError" {

  static final int PERMISSION_DENIED = 1;

  static final int POSITION_UNAVAILABLE = 2;

  static final int TIMEOUT = 3;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool PositionErrorCallback(PositionError error);

class ProcessingInstruction extends Node native "*ProcessingInstruction" {

  String get data() native "return this.data;";

  void set data(String value) native "this.data = value;";

  StyleSheet get sheet() native "return this.sheet;";

  String get target() native "return this.target;";
}

class ProgressEvent extends Event native "*ProgressEvent" {

  bool get lengthComputable() native "return this.lengthComputable;";

  int get loaded() native "return this.loaded;";

  int get total() native "return this.total;";
}

class RGBColor native "*RGBColor" {

  CSSPrimitiveValue get blue() native "return this.blue;";

  CSSPrimitiveValue get green() native "return this.green;";

  CSSPrimitiveValue get red() native "return this.red;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Range native "*Range" {

  static final int END_TO_END = 2;

  static final int END_TO_START = 3;

  static final int NODE_AFTER = 1;

  static final int NODE_BEFORE = 0;

  static final int NODE_BEFORE_AND_AFTER = 2;

  static final int NODE_INSIDE = 3;

  static final int START_TO_END = 1;

  static final int START_TO_START = 0;

  bool get collapsed() native "return this.collapsed;";

  Node get commonAncestorContainer() native "return this.commonAncestorContainer;";

  Node get endContainer() native "return this.endContainer;";

  int get endOffset() native "return this.endOffset;";

  Node get startContainer() native "return this.startContainer;";

  int get startOffset() native "return this.startOffset;";

  DocumentFragment cloneContents() native;

  Range cloneRange() native;

  void collapse(bool toStart) native;

  int compareNode(Node refNode) native;

  int comparePoint(Node refNode, int offset) native;

  DocumentFragment createContextualFragment(String html) native;

  void deleteContents() native;

  void detach() native;

  void expand(String unit) native;

  DocumentFragment extractContents() native;

  ClientRect getBoundingClientRect() native;

  ClientRectList getClientRects() native;

  void insertNode(Node newNode) native;

  bool intersectsNode(Node refNode) native;

  bool isPointInRange(Node refNode, int offset) native;

  void selectNode(Node refNode) native;

  void selectNodeContents(Node refNode) native;

  void setEnd(Node refNode, int offset) native;

  void setEndAfter(Node refNode) native;

  void setEndBefore(Node refNode) native;

  void setStart(Node refNode, int offset) native;

  void setStartAfter(Node refNode) native;

  void setStartBefore(Node refNode) native;

  void surroundContents(Node newParent) native;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class RangeException native "*RangeException" {

  static final int BAD_BOUNDARYPOINTS_ERR = 1;

  static final int INVALID_NODE_TYPE_ERR = 2;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class RealtimeAnalyserNode extends AudioNode native "*RealtimeAnalyserNode" {

  int get fftSize() native "return this.fftSize;";

  void set fftSize(int value) native "this.fftSize = value;";

  int get frequencyBinCount() native "return this.frequencyBinCount;";

  num get maxDecibels() native "return this.maxDecibels;";

  void set maxDecibels(num value) native "this.maxDecibels = value;";

  num get minDecibels() native "return this.minDecibels;";

  void set minDecibels(num value) native "this.minDecibels = value;";

  num get smoothingTimeConstant() native "return this.smoothingTimeConstant;";

  void set smoothingTimeConstant(num value) native "this.smoothingTimeConstant = value;";

  void getByteFrequencyData(Uint8Array array) native;

  void getByteTimeDomainData(Uint8Array array) native;

  void getFloatFrequencyData(Float32Array array) native;
}

class Rect native "*Rect" {

  CSSPrimitiveValue get bottom() native "return this.bottom;";

  CSSPrimitiveValue get left() native "return this.left;";

  CSSPrimitiveValue get right() native "return this.right;";

  CSSPrimitiveValue get top() native "return this.top;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLError native "*SQLError" {

  static final int CONSTRAINT_ERR = 6;

  static final int DATABASE_ERR = 1;

  static final int QUOTA_ERR = 4;

  static final int SYNTAX_ERR = 5;

  static final int TIMEOUT_ERR = 7;

  static final int TOO_LARGE_ERR = 3;

  static final int UNKNOWN_ERR = 0;

  static final int VERSION_ERR = 2;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLException native "*SQLException" {

  static final int CONSTRAINT_ERR = 6;

  static final int DATABASE_ERR = 1;

  static final int QUOTA_ERR = 4;

  static final int SYNTAX_ERR = 5;

  static final int TIMEOUT_ERR = 7;

  static final int TOO_LARGE_ERR = 3;

  static final int UNKNOWN_ERR = 0;

  static final int VERSION_ERR = 2;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLResultSet native "*SQLResultSet" {

  int get insertId() native "return this.insertId;";

  SQLResultSetRowList get rows() native "return this.rows;";

  int get rowsAffected() native "return this.rowsAffected;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLResultSetRowList native "*SQLResultSetRowList" {

  int get length() native "return this.length;";

  Object item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
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

class SQLTransaction native "*SQLTransaction" {

  var dartObjectLocalStorage;

  String get typeName() native;
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

class SQLTransactionSync native "*SQLTransactionSync" {

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool SQLTransactionSyncCallback(SQLTransactionSync transaction);

class SVGAElement extends SVGElement native "*SVGAElement" {

  SVGAnimatedString get target() native "return this.target;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGAltGlyphDefElement extends SVGElement native "*SVGAltGlyphDefElement" {
}

class SVGAltGlyphElement extends SVGTextPositioningElement native "*SVGAltGlyphElement" {

  String get format() native "return this.format;";

  void set format(String value) native "this.format = value;";

  String get glyphRef() native "return this.glyphRef;";

  void set glyphRef(String value) native "this.glyphRef = value;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";
}

class SVGAltGlyphItemElement extends SVGElement native "*SVGAltGlyphItemElement" {
}

class SVGAngle native "*SVGAngle" {

  static final int SVG_ANGLETYPE_DEG = 2;

  static final int SVG_ANGLETYPE_GRAD = 4;

  static final int SVG_ANGLETYPE_RAD = 3;

  static final int SVG_ANGLETYPE_UNKNOWN = 0;

  static final int SVG_ANGLETYPE_UNSPECIFIED = 1;

  int get unitType() native "return this.unitType;";

  num get value() native "return this.value;";

  void set value(num value) native "this.value = value;";

  String get valueAsString() native "return this.valueAsString;";

  void set valueAsString(String value) native "this.valueAsString = value;";

  num get valueInSpecifiedUnits() native "return this.valueInSpecifiedUnits;";

  void set valueInSpecifiedUnits(num value) native "this.valueInSpecifiedUnits = value;";

  void convertToSpecifiedUnits(int unitType) native;

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimateColorElement extends SVGAnimationElement native "*SVGAnimateColorElement" {
}

class SVGAnimateElement extends SVGAnimationElement native "*SVGAnimateElement" {
}

class SVGAnimateMotionElement extends SVGAnimationElement native "*SVGAnimateMotionElement" {
}

class SVGAnimateTransformElement extends SVGAnimationElement native "*SVGAnimateTransformElement" {
}

class SVGAnimatedAngle native "*SVGAnimatedAngle" {

  SVGAngle get animVal() native "return this.animVal;";

  SVGAngle get baseVal() native "return this.baseVal;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedBoolean native "*SVGAnimatedBoolean" {

  bool get animVal() native "return this.animVal;";

  bool get baseVal() native "return this.baseVal;";

  void set baseVal(bool value) native "this.baseVal = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedEnumeration native "*SVGAnimatedEnumeration" {

  int get animVal() native "return this.animVal;";

  int get baseVal() native "return this.baseVal;";

  void set baseVal(int value) native "this.baseVal = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedInteger native "*SVGAnimatedInteger" {

  int get animVal() native "return this.animVal;";

  int get baseVal() native "return this.baseVal;";

  void set baseVal(int value) native "this.baseVal = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedLength native "*SVGAnimatedLength" {

  SVGLength get animVal() native "return this.animVal;";

  SVGLength get baseVal() native "return this.baseVal;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedLengthList native "*SVGAnimatedLengthList" {

  SVGLengthList get animVal() native "return this.animVal;";

  SVGLengthList get baseVal() native "return this.baseVal;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedNumber native "*SVGAnimatedNumber" {

  num get animVal() native "return this.animVal;";

  num get baseVal() native "return this.baseVal;";

  void set baseVal(num value) native "this.baseVal = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedNumberList native "*SVGAnimatedNumberList" {

  SVGNumberList get animVal() native "return this.animVal;";

  SVGNumberList get baseVal() native "return this.baseVal;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedPreserveAspectRatio native "*SVGAnimatedPreserveAspectRatio" {

  SVGPreserveAspectRatio get animVal() native "return this.animVal;";

  SVGPreserveAspectRatio get baseVal() native "return this.baseVal;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedRect native "*SVGAnimatedRect" {

  SVGRect get animVal() native "return this.animVal;";

  SVGRect get baseVal() native "return this.baseVal;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedString native "*SVGAnimatedString" {

  String get animVal() native "return this.animVal;";

  String get baseVal() native "return this.baseVal;";

  void set baseVal(String value) native "this.baseVal = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedTransformList native "*SVGAnimatedTransformList" {

  SVGTransformList get animVal() native "return this.animVal;";

  SVGTransformList get baseVal() native "return this.baseVal;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimationElement extends SVGElement native "*SVGAnimationElement" {

  SVGElement get targetElement() native "return this.targetElement;";

  num getCurrentTime() native;

  num getSimpleDuration() native;

  num getStartTime() native;

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From ElementTimeControl

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;
}

class SVGCircleElement extends SVGElement native "*SVGCircleElement" {

  SVGAnimatedLength get cx() native "return this.cx;";

  SVGAnimatedLength get cy() native "return this.cy;";

  SVGAnimatedLength get r() native "return this.r;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGClipPathElement extends SVGElement native "*SVGClipPathElement" {

  SVGAnimatedEnumeration get clipPathUnits() native "return this.clipPathUnits;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGColor extends CSSValue native "*SVGColor" {

  static final int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static final int SVG_COLORTYPE_RGBCOLOR = 1;

  static final int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static final int SVG_COLORTYPE_UNKNOWN = 0;

  int get colorType() native "return this.colorType;";

  RGBColor get rgbColor() native "return this.rgbColor;";

  void setColor(int colorType, String rgbColor, String iccColor) native;

  void setRGBColor(String rgbColor) native;

  void setRGBColorICCColor(String rgbColor, String iccColor) native;
}

class SVGComponentTransferFunctionElement extends SVGElement native "*SVGComponentTransferFunctionElement" {

  static final int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  SVGAnimatedNumber get amplitude() native "return this.amplitude;";

  SVGAnimatedNumber get exponent() native "return this.exponent;";

  SVGAnimatedNumber get intercept() native "return this.intercept;";

  SVGAnimatedNumber get offset() native "return this.offset;";

  SVGAnimatedNumber get slope() native "return this.slope;";

  SVGAnimatedNumberList get tableValues() native "return this.tableValues;";

  SVGAnimatedEnumeration get type() native "return this.type;";
}

class SVGCursorElement extends SVGElement native "*SVGCursorElement" {

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";
}

class SVGDefsElement extends SVGElement native "*SVGDefsElement" {

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGDescElement extends SVGElement native "*SVGDescElement" {

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGDocument extends Document native "*SVGDocument" {

  SVGSVGElement get rootElement() native "return this.rootElement;";

  Event createEvent(String eventType) native;
}

class SVGElement extends Element native "*SVGElement" {

  String get id() native "return this.id;";

  void set id(String value) native "this.id = value;";

  SVGSVGElement get ownerSVGElement() native "return this.ownerSVGElement;";

  SVGElement get viewportElement() native "return this.viewportElement;";

  String get xmlbase() native "return this.xmlbase;";

  void set xmlbase(String value) native "this.xmlbase = value;";
}

class SVGElementInstance native "*SVGElementInstance" {

  SVGElementInstanceList get childNodes() native "return this.childNodes;";

  SVGElement get correspondingElement() native "return this.correspondingElement;";

  SVGUseElement get correspondingUseElement() native "return this.correspondingUseElement;";

  SVGElementInstance get firstChild() native "return this.firstChild;";

  SVGElementInstance get lastChild() native "return this.lastChild;";

  SVGElementInstance get nextSibling() native "return this.nextSibling;";

  SVGElementInstance get parentNode() native "return this.parentNode;";

  SVGElementInstance get previousSibling() native "return this.previousSibling;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGElementInstanceList native "*SVGElementInstanceList" {

  int get length() native "return this.length;";

  SVGElementInstance item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGEllipseElement extends SVGElement native "*SVGEllipseElement" {

  SVGAnimatedLength get cx() native "return this.cx;";

  SVGAnimatedLength get cy() native "return this.cy;";

  SVGAnimatedLength get rx() native "return this.rx;";

  SVGAnimatedLength get ry() native "return this.ry;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGException native "*SVGException" {

  static final int SVG_INVALID_VALUE_ERR = 1;

  static final int SVG_MATRIX_NOT_INVERTABLE = 2;

  static final int SVG_WRONG_TYPE_ERR = 0;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGExternalResourcesRequired native "*SVGExternalResourcesRequired" {

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGFEBlendElement extends SVGElement native "*SVGFEBlendElement" {

  static final int SVG_FEBLEND_MODE_DARKEN = 4;

  static final int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static final int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static final int SVG_FEBLEND_MODE_NORMAL = 1;

  static final int SVG_FEBLEND_MODE_SCREEN = 3;

  static final int SVG_FEBLEND_MODE_UNKNOWN = 0;

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedString get in2() native "return this.in2;";

  SVGAnimatedEnumeration get mode() native "return this.mode;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEColorMatrixElement extends SVGElement native "*SVGFEColorMatrixElement" {

  static final int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static final int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static final int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static final int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static final int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedEnumeration get type() native "return this.type;";

  SVGAnimatedNumberList get values() native "return this.values;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEComponentTransferElement extends SVGElement native "*SVGFEComponentTransferElement" {

  SVGAnimatedString get in1() native "return this.in1;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFECompositeElement extends SVGElement native "*SVGFECompositeElement" {

  static final int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static final int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static final int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static final int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static final int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static final int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static final int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedString get in2() native "return this.in2;";

  SVGAnimatedNumber get k1() native "return this.k1;";

  SVGAnimatedNumber get k2() native "return this.k2;";

  SVGAnimatedNumber get k3() native "return this.k3;";

  SVGAnimatedNumber get k4() native "return this.k4;";

  SVGAnimatedEnumeration get operator() native "return this.operator;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEConvolveMatrixElement extends SVGElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  SVGAnimatedNumber get bias() native "return this.bias;";

  SVGAnimatedNumber get divisor() native "return this.divisor;";

  SVGAnimatedEnumeration get edgeMode() native "return this.edgeMode;";

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedNumberList get kernelMatrix() native "return this.kernelMatrix;";

  SVGAnimatedNumber get kernelUnitLengthX() native "return this.kernelUnitLengthX;";

  SVGAnimatedNumber get kernelUnitLengthY() native "return this.kernelUnitLengthY;";

  SVGAnimatedInteger get orderX() native "return this.orderX;";

  SVGAnimatedInteger get orderY() native "return this.orderY;";

  SVGAnimatedBoolean get preserveAlpha() native "return this.preserveAlpha;";

  SVGAnimatedInteger get targetX() native "return this.targetX;";

  SVGAnimatedInteger get targetY() native "return this.targetY;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEDiffuseLightingElement extends SVGElement native "*SVGFEDiffuseLightingElement" {

  SVGAnimatedNumber get diffuseConstant() native "return this.diffuseConstant;";

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedNumber get kernelUnitLengthX() native "return this.kernelUnitLengthX;";

  SVGAnimatedNumber get kernelUnitLengthY() native "return this.kernelUnitLengthY;";

  SVGAnimatedNumber get surfaceScale() native "return this.surfaceScale;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEDisplacementMapElement extends SVGElement native "*SVGFEDisplacementMapElement" {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedString get in2() native "return this.in2;";

  SVGAnimatedNumber get scale() native "return this.scale;";

  SVGAnimatedEnumeration get xChannelSelector() native "return this.xChannelSelector;";

  SVGAnimatedEnumeration get yChannelSelector() native "return this.yChannelSelector;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEDistantLightElement extends SVGElement native "*SVGFEDistantLightElement" {

  SVGAnimatedNumber get azimuth() native "return this.azimuth;";

  SVGAnimatedNumber get elevation() native "return this.elevation;";
}

class SVGFEDropShadowElement extends SVGElement native "*SVGFEDropShadowElement" {

  SVGAnimatedNumber get dx() native "return this.dx;";

  SVGAnimatedNumber get dy() native "return this.dy;";

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedNumber get stdDeviationX() native "return this.stdDeviationX;";

  SVGAnimatedNumber get stdDeviationY() native "return this.stdDeviationY;";

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEFloodElement extends SVGElement native "*SVGFEFloodElement" {

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEFuncAElement extends SVGComponentTransferFunctionElement native "*SVGFEFuncAElement" {
}

class SVGFEFuncBElement extends SVGComponentTransferFunctionElement native "*SVGFEFuncBElement" {
}

class SVGFEFuncGElement extends SVGComponentTransferFunctionElement native "*SVGFEFuncGElement" {
}

class SVGFEFuncRElement extends SVGComponentTransferFunctionElement native "*SVGFEFuncRElement" {
}

class SVGFEGaussianBlurElement extends SVGElement native "*SVGFEGaussianBlurElement" {

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedNumber get stdDeviationX() native "return this.stdDeviationX;";

  SVGAnimatedNumber get stdDeviationY() native "return this.stdDeviationY;";

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEImageElement extends SVGElement native "*SVGFEImageElement" {

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEMergeElement extends SVGElement native "*SVGFEMergeElement" {

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEMergeNodeElement extends SVGElement native "*SVGFEMergeNodeElement" {

  SVGAnimatedString get in1() native "return this.in1;";
}

class SVGFEMorphologyElement extends SVGElement native "*SVGFEMorphologyElement" {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedEnumeration get operator() native "return this.operator;";

  SVGAnimatedNumber get radiusX() native "return this.radiusX;";

  SVGAnimatedNumber get radiusY() native "return this.radiusY;";

  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEOffsetElement extends SVGElement native "*SVGFEOffsetElement" {

  SVGAnimatedNumber get dx() native "return this.dx;";

  SVGAnimatedNumber get dy() native "return this.dy;";

  SVGAnimatedString get in1() native "return this.in1;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEPointLightElement extends SVGElement native "*SVGFEPointLightElement" {

  SVGAnimatedNumber get x() native "return this.x;";

  SVGAnimatedNumber get y() native "return this.y;";

  SVGAnimatedNumber get z() native "return this.z;";
}

class SVGFESpecularLightingElement extends SVGElement native "*SVGFESpecularLightingElement" {

  SVGAnimatedString get in1() native "return this.in1;";

  SVGAnimatedNumber get specularConstant() native "return this.specularConstant;";

  SVGAnimatedNumber get specularExponent() native "return this.specularExponent;";

  SVGAnimatedNumber get surfaceScale() native "return this.surfaceScale;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFESpotLightElement extends SVGElement native "*SVGFESpotLightElement" {

  SVGAnimatedNumber get limitingConeAngle() native "return this.limitingConeAngle;";

  SVGAnimatedNumber get pointsAtX() native "return this.pointsAtX;";

  SVGAnimatedNumber get pointsAtY() native "return this.pointsAtY;";

  SVGAnimatedNumber get pointsAtZ() native "return this.pointsAtZ;";

  SVGAnimatedNumber get specularExponent() native "return this.specularExponent;";

  SVGAnimatedNumber get x() native "return this.x;";

  SVGAnimatedNumber get y() native "return this.y;";

  SVGAnimatedNumber get z() native "return this.z;";
}

class SVGFETileElement extends SVGElement native "*SVGFETileElement" {

  SVGAnimatedString get in1() native "return this.in1;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFETurbulenceElement extends SVGElement native "*SVGFETurbulenceElement" {

  static final int SVG_STITCHTYPE_NOSTITCH = 2;

  static final int SVG_STITCHTYPE_STITCH = 1;

  static final int SVG_STITCHTYPE_UNKNOWN = 0;

  static final int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static final int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static final int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  SVGAnimatedNumber get baseFrequencyX() native "return this.baseFrequencyX;";

  SVGAnimatedNumber get baseFrequencyY() native "return this.baseFrequencyY;";

  SVGAnimatedInteger get numOctaves() native "return this.numOctaves;";

  SVGAnimatedNumber get seed() native "return this.seed;";

  SVGAnimatedEnumeration get stitchTiles() native "return this.stitchTiles;";

  SVGAnimatedEnumeration get type() native "return this.type;";

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFilterElement extends SVGElement native "*SVGFilterElement" {

  SVGAnimatedInteger get filterResX() native "return this.filterResX;";

  SVGAnimatedInteger get filterResY() native "return this.filterResY;";

  SVGAnimatedEnumeration get filterUnits() native "return this.filterUnits;";

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedEnumeration get primitiveUnits() native "return this.primitiveUnits;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFilterPrimitiveStandardAttributes extends SVGStylable native "*SVGFilterPrimitiveStandardAttributes" {

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedString get result() native "return this.result;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";
}

class SVGFitToViewBox native "*SVGFitToViewBox" {

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGFontElement extends SVGElement native "*SVGFontElement" {
}

class SVGFontFaceElement extends SVGElement native "*SVGFontFaceElement" {
}

class SVGFontFaceFormatElement extends SVGElement native "*SVGFontFaceFormatElement" {
}

class SVGFontFaceNameElement extends SVGElement native "*SVGFontFaceNameElement" {
}

class SVGFontFaceSrcElement extends SVGElement native "*SVGFontFaceSrcElement" {
}

class SVGFontFaceUriElement extends SVGElement native "*SVGFontFaceUriElement" {
}

class SVGForeignObjectElement extends SVGElement native "*SVGForeignObjectElement" {

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGGElement extends SVGElement native "*SVGGElement" {

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGGlyphElement extends SVGElement native "*SVGGlyphElement" {
}

class SVGGlyphRefElement extends SVGElement native "*SVGGlyphRefElement" {

  num get dx() native "return this.dx;";

  void set dx(num value) native "this.dx = value;";

  num get dy() native "return this.dy;";

  void set dy(num value) native "this.dy = value;";

  String get format() native "return this.format;";

  void set format(String value) native "this.format = value;";

  String get glyphRef() native "return this.glyphRef;";

  void set glyphRef(String value) native "this.glyphRef = value;";

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGGradientElement extends SVGElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  SVGAnimatedTransformList get gradientTransform() native "return this.gradientTransform;";

  SVGAnimatedEnumeration get gradientUnits() native "return this.gradientUnits;";

  SVGAnimatedEnumeration get spreadMethod() native "return this.spreadMethod;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGHKernElement extends SVGElement native "*SVGHKernElement" {
}

class SVGImageElement extends SVGElement native "*SVGImageElement" {

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGLangSpace native "*SVGLangSpace" {

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGLength native "*SVGLength" {

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

  int get unitType() native "return this.unitType;";

  num get value() native "return this.value;";

  void set value(num value) native "this.value = value;";

  String get valueAsString() native "return this.valueAsString;";

  void set valueAsString(String value) native "this.valueAsString = value;";

  num get valueInSpecifiedUnits() native "return this.valueInSpecifiedUnits;";

  void set valueInSpecifiedUnits(num value) native "this.valueInSpecifiedUnits = value;";

  void convertToSpecifiedUnits(int unitType) native;

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGLengthList native "*SVGLengthList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGLength appendItem(SVGLength item) native;

  void clear() native;

  SVGLength getItem(int index) native;

  SVGLength initialize(SVGLength item) native;

  SVGLength insertItemBefore(SVGLength item, int index) native;

  SVGLength removeItem(int index) native;

  SVGLength replaceItem(SVGLength item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGLineElement extends SVGElement native "*SVGLineElement" {

  SVGAnimatedLength get x1() native "return this.x1;";

  SVGAnimatedLength get x2() native "return this.x2;";

  SVGAnimatedLength get y1() native "return this.y1;";

  SVGAnimatedLength get y2() native "return this.y2;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGLinearGradientElement extends SVGGradientElement native "*SVGLinearGradientElement" {

  SVGAnimatedLength get x1() native "return this.x1;";

  SVGAnimatedLength get x2() native "return this.x2;";

  SVGAnimatedLength get y1() native "return this.y1;";

  SVGAnimatedLength get y2() native "return this.y2;";
}

class SVGLocatable native "*SVGLocatable" {

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGMPathElement extends SVGElement native "*SVGMPathElement" {

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";
}

class SVGMarkerElement extends SVGElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  SVGAnimatedLength get markerHeight() native "return this.markerHeight;";

  SVGAnimatedEnumeration get markerUnits() native "return this.markerUnits;";

  SVGAnimatedLength get markerWidth() native "return this.markerWidth;";

  SVGAnimatedAngle get orientAngle() native "return this.orientAngle;";

  SVGAnimatedEnumeration get orientType() native "return this.orientType;";

  SVGAnimatedLength get refX() native "return this.refX;";

  SVGAnimatedLength get refY() native "return this.refY;";

  void setOrientToAngle(SVGAngle angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";
}

class SVGMaskElement extends SVGElement native "*SVGMaskElement" {

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedEnumeration get maskContentUnits() native "return this.maskContentUnits;";

  SVGAnimatedEnumeration get maskUnits() native "return this.maskUnits;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGMatrix native "*SVGMatrix" {

  num get a() native "return this.a;";

  void set a(num value) native "this.a = value;";

  num get b() native "return this.b;";

  void set b(num value) native "this.b = value;";

  num get c() native "return this.c;";

  void set c(num value) native "this.c = value;";

  num get d() native "return this.d;";

  void set d(num value) native "this.d = value;";

  num get e() native "return this.e;";

  void set e(num value) native "this.e = value;";

  num get f() native "return this.f;";

  void set f(num value) native "this.f = value;";

  SVGMatrix flipX() native;

  SVGMatrix flipY() native;

  SVGMatrix inverse() native;

  SVGMatrix multiply(SVGMatrix secondMatrix) native;

  SVGMatrix rotate(num angle) native;

  SVGMatrix rotateFromVector(num x, num y) native;

  SVGMatrix scale(num scaleFactor) native;

  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  SVGMatrix skewX(num angle) native;

  SVGMatrix skewY(num angle) native;

  SVGMatrix translate(num x, num y) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGMetadataElement extends SVGElement native "*SVGMetadataElement" {
}

class SVGMissingGlyphElement extends SVGElement native "*SVGMissingGlyphElement" {
}

class SVGNumber native "*SVGNumber" {

  num get value() native "return this.value;";

  void set value(num value) native "this.value = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGNumberList native "*SVGNumberList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGNumber appendItem(SVGNumber item) native;

  void clear() native;

  SVGNumber getItem(int index) native;

  SVGNumber initialize(SVGNumber item) native;

  SVGNumber insertItemBefore(SVGNumber item, int index) native;

  SVGNumber removeItem(int index) native;

  SVGNumber replaceItem(SVGNumber item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGPaint extends SVGColor native "*SVGPaint" {

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

  int get paintType() native "return this.paintType;";

  String get uri() native "return this.uri;";

  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native;

  void setUri(String uri) native;
}

class SVGPathElement extends SVGElement native "*SVGPathElement" {

  SVGPathSegList get animatedNormalizedPathSegList() native "return this.animatedNormalizedPathSegList;";

  SVGPathSegList get animatedPathSegList() native "return this.animatedPathSegList;";

  SVGPathSegList get normalizedPathSegList() native "return this.normalizedPathSegList;";

  SVGAnimatedNumber get pathLength() native "return this.pathLength;";

  SVGPathSegList get pathSegList() native "return this.pathSegList;";

  SVGPathSegArcAbs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  SVGPathSegArcRel createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  SVGPathSegClosePath createSVGPathSegClosePath() native;

  SVGPathSegCurvetoCubicAbs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  SVGPathSegCurvetoCubicRel createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  SVGPathSegCurvetoCubicSmoothAbs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  SVGPathSegCurvetoCubicSmoothRel createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  SVGPathSegCurvetoQuadraticAbs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  SVGPathSegCurvetoQuadraticRel createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  SVGPathSegCurvetoQuadraticSmoothAbs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  SVGPathSegCurvetoQuadraticSmoothRel createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  SVGPathSegLinetoAbs createSVGPathSegLinetoAbs(num x, num y) native;

  SVGPathSegLinetoHorizontalAbs createSVGPathSegLinetoHorizontalAbs(num x) native;

  SVGPathSegLinetoHorizontalRel createSVGPathSegLinetoHorizontalRel(num x) native;

  SVGPathSegLinetoRel createSVGPathSegLinetoRel(num x, num y) native;

  SVGPathSegLinetoVerticalAbs createSVGPathSegLinetoVerticalAbs(num y) native;

  SVGPathSegLinetoVerticalRel createSVGPathSegLinetoVerticalRel(num y) native;

  SVGPathSegMovetoAbs createSVGPathSegMovetoAbs(num x, num y) native;

  SVGPathSegMovetoRel createSVGPathSegMovetoRel(num x, num y) native;

  int getPathSegAtLength(num distance) native;

  SVGPoint getPointAtLength(num distance) native;

  num getTotalLength() native;

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGPathSeg native "*SVGPathSeg" {

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

  int get pathSegType() native "return this.pathSegType;";

  String get pathSegTypeAsLetter() native "return this.pathSegTypeAsLetter;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGPathSegArcAbs extends SVGPathSeg native "*SVGPathSegArcAbs" {

  num get angle() native "return this.angle;";

  void set angle(num value) native "this.angle = value;";

  bool get largeArcFlag() native "return this.largeArcFlag;";

  void set largeArcFlag(bool value) native "this.largeArcFlag = value;";

  num get r1() native "return this.r1;";

  void set r1(num value) native "this.r1 = value;";

  num get r2() native "return this.r2;";

  void set r2(num value) native "this.r2 = value;";

  bool get sweepFlag() native "return this.sweepFlag;";

  void set sweepFlag(bool value) native "this.sweepFlag = value;";

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";
}

class SVGPathSegArcRel extends SVGPathSeg native "*SVGPathSegArcRel" {

  num get angle() native "return this.angle;";

  void set angle(num value) native "this.angle = value;";

  bool get largeArcFlag() native "return this.largeArcFlag;";

  void set largeArcFlag(bool value) native "this.largeArcFlag = value;";

  num get r1() native "return this.r1;";

  void set r1(num value) native "this.r1 = value;";

  num get r2() native "return this.r2;";

  void set r2(num value) native "this.r2 = value;";

  bool get sweepFlag() native "return this.sweepFlag;";

  void set sweepFlag(bool value) native "this.sweepFlag = value;";

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";
}

class SVGPathSegClosePath extends SVGPathSeg native "*SVGPathSegClosePath" {
}

class SVGPathSegCurvetoCubicAbs extends SVGPathSeg native "*SVGPathSegCurvetoCubicAbs" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get x1() native "return this.x1;";

  void set x1(num value) native "this.x1 = value;";

  num get x2() native "return this.x2;";

  void set x2(num value) native "this.x2 = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  num get y1() native "return this.y1;";

  void set y1(num value) native "this.y1 = value;";

  num get y2() native "return this.y2;";

  void set y2(num value) native "this.y2 = value;";
}

class SVGPathSegCurvetoCubicRel extends SVGPathSeg native "*SVGPathSegCurvetoCubicRel" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get x1() native "return this.x1;";

  void set x1(num value) native "this.x1 = value;";

  num get x2() native "return this.x2;";

  void set x2(num value) native "this.x2 = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  num get y1() native "return this.y1;";

  void set y1(num value) native "this.y1 = value;";

  num get y2() native "return this.y2;";

  void set y2(num value) native "this.y2 = value;";
}

class SVGPathSegCurvetoCubicSmoothAbs extends SVGPathSeg native "*SVGPathSegCurvetoCubicSmoothAbs" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get x2() native "return this.x2;";

  void set x2(num value) native "this.x2 = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  num get y2() native "return this.y2;";

  void set y2(num value) native "this.y2 = value;";
}

class SVGPathSegCurvetoCubicSmoothRel extends SVGPathSeg native "*SVGPathSegCurvetoCubicSmoothRel" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get x2() native "return this.x2;";

  void set x2(num value) native "this.x2 = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  num get y2() native "return this.y2;";

  void set y2(num value) native "this.y2 = value;";
}

class SVGPathSegCurvetoQuadraticAbs extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticAbs" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get x1() native "return this.x1;";

  void set x1(num value) native "this.x1 = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  num get y1() native "return this.y1;";

  void set y1(num value) native "this.y1 = value;";
}

class SVGPathSegCurvetoQuadraticRel extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticRel" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get x1() native "return this.x1;";

  void set x1(num value) native "this.x1 = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  num get y1() native "return this.y1;";

  void set y1(num value) native "this.y1 = value;";
}

class SVGPathSegCurvetoQuadraticSmoothAbs extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticSmoothAbs" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";
}

class SVGPathSegCurvetoQuadraticSmoothRel extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticSmoothRel" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";
}

class SVGPathSegLinetoAbs extends SVGPathSeg native "*SVGPathSegLinetoAbs" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";
}

class SVGPathSegLinetoHorizontalAbs extends SVGPathSeg native "*SVGPathSegLinetoHorizontalAbs" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";
}

class SVGPathSegLinetoHorizontalRel extends SVGPathSeg native "*SVGPathSegLinetoHorizontalRel" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";
}

class SVGPathSegLinetoRel extends SVGPathSeg native "*SVGPathSegLinetoRel" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";
}

class SVGPathSegLinetoVerticalAbs extends SVGPathSeg native "*SVGPathSegLinetoVerticalAbs" {

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";
}

class SVGPathSegLinetoVerticalRel extends SVGPathSeg native "*SVGPathSegLinetoVerticalRel" {

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";
}

class SVGPathSegList native "*SVGPathSegList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGPathSeg appendItem(SVGPathSeg newItem) native;

  void clear() native;

  SVGPathSeg getItem(int index) native;

  SVGPathSeg initialize(SVGPathSeg newItem) native;

  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index) native;

  SVGPathSeg removeItem(int index) native;

  SVGPathSeg replaceItem(SVGPathSeg newItem, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGPathSegMovetoAbs extends SVGPathSeg native "*SVGPathSegMovetoAbs" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";
}

class SVGPathSegMovetoRel extends SVGPathSeg native "*SVGPathSegMovetoRel" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";
}

class SVGPatternElement extends SVGElement native "*SVGPatternElement" {

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedEnumeration get patternContentUnits() native "return this.patternContentUnits;";

  SVGAnimatedTransformList get patternTransform() native "return this.patternTransform;";

  SVGAnimatedEnumeration get patternUnits() native "return this.patternUnits;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";
}

class SVGPoint native "*SVGPoint" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  SVGPoint matrixTransform(SVGMatrix matrix) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGPointList native "*SVGPointList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGPoint appendItem(SVGPoint item) native;

  void clear() native;

  SVGPoint getItem(int index) native;

  SVGPoint initialize(SVGPoint item) native;

  SVGPoint insertItemBefore(SVGPoint item, int index) native;

  SVGPoint removeItem(int index) native;

  SVGPoint replaceItem(SVGPoint item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGPolygonElement extends SVGElement native "*SVGPolygonElement" {

  SVGPointList get animatedPoints() native "return this.animatedPoints;";

  SVGPointList get points() native "return this.points;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGPolylineElement extends SVGElement native "*SVGPolylineElement" {

  SVGPointList get animatedPoints() native "return this.animatedPoints;";

  SVGPointList get points() native "return this.points;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGPreserveAspectRatio native "*SVGPreserveAspectRatio" {

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

  int get align() native "return this.align;";

  void set align(int value) native "this.align = value;";

  int get meetOrSlice() native "return this.meetOrSlice;";

  void set meetOrSlice(int value) native "this.meetOrSlice = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGRadialGradientElement extends SVGGradientElement native "*SVGRadialGradientElement" {

  SVGAnimatedLength get cx() native "return this.cx;";

  SVGAnimatedLength get cy() native "return this.cy;";

  SVGAnimatedLength get fx() native "return this.fx;";

  SVGAnimatedLength get fy() native "return this.fy;";

  SVGAnimatedLength get r() native "return this.r;";
}

class SVGRect native "*SVGRect" {

  num get height() native "return this.height;";

  void set height(num value) native "this.height = value;";

  num get width() native "return this.width;";

  void set width(num value) native "this.width = value;";

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGRectElement extends SVGElement native "*SVGRectElement" {

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedLength get rx() native "return this.rx;";

  SVGAnimatedLength get ry() native "return this.ry;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGRenderingIntent native "*SVGRenderingIntent" {

  static final int RENDERING_INTENT_ABSOLUTE_COLORIMETRIC = 5;

  static final int RENDERING_INTENT_AUTO = 1;

  static final int RENDERING_INTENT_PERCEPTUAL = 2;

  static final int RENDERING_INTENT_RELATIVE_COLORIMETRIC = 3;

  static final int RENDERING_INTENT_SATURATION = 4;

  static final int RENDERING_INTENT_UNKNOWN = 0;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGSVGElement extends SVGElement native "*SVGSVGElement" {

  String get contentScriptType() native "return this.contentScriptType;";

  void set contentScriptType(String value) native "this.contentScriptType = value;";

  String get contentStyleType() native "return this.contentStyleType;";

  void set contentStyleType(String value) native "this.contentStyleType = value;";

  num get currentScale() native "return this.currentScale;";

  void set currentScale(num value) native "this.currentScale = value;";

  SVGPoint get currentTranslate() native "return this.currentTranslate;";

  SVGAnimatedLength get height() native "return this.height;";

  num get pixelUnitToMillimeterX() native "return this.pixelUnitToMillimeterX;";

  num get pixelUnitToMillimeterY() native "return this.pixelUnitToMillimeterY;";

  num get screenPixelToMillimeterX() native "return this.screenPixelToMillimeterX;";

  num get screenPixelToMillimeterY() native "return this.screenPixelToMillimeterY;";

  bool get useCurrentView() native "return this.useCurrentView;";

  void set useCurrentView(bool value) native "this.useCurrentView = value;";

  SVGRect get viewport() native "return this.viewport;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  bool animationsPaused() native;

  bool checkEnclosure(SVGElement element, SVGRect rect) native;

  bool checkIntersection(SVGElement element, SVGRect rect) native;

  SVGAngle createSVGAngle() native;

  SVGLength createSVGLength() native;

  SVGMatrix createSVGMatrix() native;

  SVGNumber createSVGNumber() native;

  SVGPoint createSVGPoint() native;

  SVGRect createSVGRect() native;

  SVGTransform createSVGTransform() native;

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) native;

  void deselectAll() native;

  void forceRedraw() native;

  num getCurrentTime() native;

  Element getElementById(String elementId) native;

  NodeList getEnclosureList(SVGRect rect, SVGElement referenceElement) native;

  NodeList getIntersectionList(SVGRect rect, SVGElement referenceElement) native;

  void pauseAnimations() native;

  void setCurrentTime(num seconds) native;

  int suspendRedraw(int maxWaitMilliseconds) native;

  void unpauseAnimations() native;

  void unsuspendRedraw(int suspendHandleId) native;

  void unsuspendRedrawAll() native;

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";

  // From SVGZoomAndPan

  int get zoomAndPan() native "return this.zoomAndPan;";

  void set zoomAndPan(int value) native "this.zoomAndPan = value;";
}

class SVGScriptElement extends SVGElement native "*SVGScriptElement" {

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";
}

class SVGSetElement extends SVGAnimationElement native "*SVGSetElement" {
}

class SVGStopElement extends SVGElement native "*SVGStopElement" {

  SVGAnimatedNumber get offset() native "return this.offset;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGStringList native "*SVGStringList" {

  int get numberOfItems() native "return this.numberOfItems;";

  String appendItem(String item) native;

  void clear() native;

  String getItem(int index) native;

  String initialize(String item) native;

  String insertItemBefore(String item, int index) native;

  String removeItem(int index) native;

  String replaceItem(String item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGStylable native "*SVGStylable" {

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGStyleElement extends SVGElement native "*SVGStyleElement" {

  String get media() native "return this.media;";

  void set media(String value) native "this.media = value;";

  String get title() native "return this.title;";

  void set title(String value) native "this.title = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";
}

class SVGSwitchElement extends SVGElement native "*SVGSwitchElement" {

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGSymbolElement extends SVGElement native "*SVGSymbolElement" {

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";
}

class SVGTRefElement extends SVGTextPositioningElement native "*SVGTRefElement" {

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";
}

class SVGTSpanElement extends SVGTextPositioningElement native "*SVGTSpanElement" {
}

class SVGTests native "*SVGTests" {

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGTextContentElement extends SVGElement native "*SVGTextContentElement" {

  static final int LENGTHADJUST_SPACING = 1;

  static final int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static final int LENGTHADJUST_UNKNOWN = 0;

  SVGAnimatedEnumeration get lengthAdjust() native "return this.lengthAdjust;";

  SVGAnimatedLength get textLength() native "return this.textLength;";

  int getCharNumAtPosition(SVGPoint point) native;

  num getComputedTextLength() native;

  SVGPoint getEndPositionOfChar(int offset) native;

  SVGRect getExtentOfChar(int offset) native;

  int getNumberOfChars() native;

  num getRotationOfChar(int offset) native;

  SVGPoint getStartPositionOfChar(int offset) native;

  num getSubStringLength(int offset, int length) native;

  void selectSubString(int offset, int length) native;

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGTextElement extends SVGTextPositioningElement native "*SVGTextElement" {

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGTextPathElement extends SVGTextContentElement native "*SVGTextPathElement" {

  static final int TEXTPATH_METHODTYPE_ALIGN = 1;

  static final int TEXTPATH_METHODTYPE_STRETCH = 2;

  static final int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static final int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static final int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static final int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  SVGAnimatedEnumeration get method() native "return this.method;";

  SVGAnimatedEnumeration get spacing() native "return this.spacing;";

  SVGAnimatedLength get startOffset() native "return this.startOffset;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";
}

class SVGTextPositioningElement extends SVGTextContentElement native "*SVGTextPositioningElement" {

  SVGAnimatedLengthList get dx() native "return this.dx;";

  SVGAnimatedLengthList get dy() native "return this.dy;";

  SVGAnimatedNumberList get rotate() native "return this.rotate;";

  SVGAnimatedLengthList get x() native "return this.x;";

  SVGAnimatedLengthList get y() native "return this.y;";
}

class SVGTitleElement extends SVGElement native "*SVGTitleElement" {

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;
}

class SVGTransform native "*SVGTransform" {

  static final int SVG_TRANSFORM_MATRIX = 1;

  static final int SVG_TRANSFORM_ROTATE = 4;

  static final int SVG_TRANSFORM_SCALE = 3;

  static final int SVG_TRANSFORM_SKEWX = 5;

  static final int SVG_TRANSFORM_SKEWY = 6;

  static final int SVG_TRANSFORM_TRANSLATE = 2;

  static final int SVG_TRANSFORM_UNKNOWN = 0;

  num get angle() native "return this.angle;";

  SVGMatrix get matrix() native "return this.matrix;";

  int get type() native "return this.type;";

  void setMatrix(SVGMatrix matrix) native;

  void setRotate(num angle, num cx, num cy) native;

  void setScale(num sx, num sy) native;

  void setSkewX(num angle) native;

  void setSkewY(num angle) native;

  void setTranslate(num tx, num ty) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGTransformList native "*SVGTransformList" {

  int get numberOfItems() native "return this.numberOfItems;";

  SVGTransform appendItem(SVGTransform item) native;

  void clear() native;

  SVGTransform consolidate() native;

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) native;

  SVGTransform getItem(int index) native;

  SVGTransform initialize(SVGTransform item) native;

  SVGTransform insertItemBefore(SVGTransform item, int index) native;

  SVGTransform removeItem(int index) native;

  SVGTransform replaceItem(SVGTransform item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGTransformable extends SVGLocatable native "*SVGTransformable" {

  SVGAnimatedTransformList get transform() native "return this.transform;";
}

class SVGURIReference native "*SVGURIReference" {

  SVGAnimatedString get href() native "return this.href;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGUnitTypes native "*SVGUnitTypes" {

  static final int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static final int SVG_UNIT_TYPE_UNKNOWN = 0;

  static final int SVG_UNIT_TYPE_USERSPACEONUSE = 1;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGUseElement extends SVGElement native "*SVGUseElement" {

  SVGElementInstance get animatedInstanceRoot() native "return this.animatedInstanceRoot;";

  SVGAnimatedLength get height() native "return this.height;";

  SVGElementInstance get instanceRoot() native "return this.instanceRoot;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGVKernElement extends SVGElement native "*SVGVKernElement" {
}

class SVGViewElement extends SVGElement native "*SVGViewElement" {

  SVGStringList get viewTarget() native "return this.viewTarget;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";

  // From SVGZoomAndPan

  int get zoomAndPan() native "return this.zoomAndPan;";

  void set zoomAndPan(int value) native "this.zoomAndPan = value;";
}

class SVGViewSpec extends SVGZoomAndPan native "*SVGViewSpec" {

  String get preserveAspectRatioString() native "return this.preserveAspectRatioString;";

  SVGTransformList get transform() native "return this.transform;";

  String get transformString() native "return this.transformString;";

  String get viewBoxString() native "return this.viewBoxString;";

  SVGElement get viewTarget() native "return this.viewTarget;";

  String get viewTargetString() native "return this.viewTargetString;";

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";
}

class SVGZoomAndPan native "*SVGZoomAndPan" {

  static final int SVG_ZOOMANDPAN_DISABLE = 1;

  static final int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static final int SVG_ZOOMANDPAN_UNKNOWN = 0;

  int get zoomAndPan() native "return this.zoomAndPan;";

  void set zoomAndPan(int value) native "this.zoomAndPan = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGZoomEvent extends UIEvent native "*SVGZoomEvent" {

  num get newScale() native "return this.newScale;";

  SVGPoint get newTranslate() native "return this.newTranslate;";

  num get previousScale() native "return this.previousScale;";

  SVGPoint get previousTranslate() native "return this.previousTranslate;";

  SVGRect get zoomRectScreen() native "return this.zoomRectScreen;";
}

class Screen native "*Screen" {

  int get availHeight() native "return this.availHeight;";

  int get availLeft() native "return this.availLeft;";

  int get availTop() native "return this.availTop;";

  int get availWidth() native "return this.availWidth;";

  int get colorDepth() native "return this.colorDepth;";

  int get height() native "return this.height;";

  int get pixelDepth() native "return this.pixelDepth;";

  int get width() native "return this.width;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ScriptProfile native "*ScriptProfile" {

  ScriptProfileNode get head() native "return this.head;";

  String get title() native "return this.title;";

  int get uid() native "return this.uid;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ScriptProfileNode native "*ScriptProfileNode" {

  int get callUID() native "return this.callUID;";

  List get children() native "return this.children;";

  String get functionName() native "return this.functionName;";

  int get lineNumber() native "return this.lineNumber;";

  int get numberOfCalls() native "return this.numberOfCalls;";

  num get selfTime() native "return this.selfTime;";

  num get totalTime() native "return this.totalTime;";

  String get url() native "return this.url;";

  bool get visible() native "return this.visible;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SharedWorker extends AbstractWorker native "*SharedWorker" {

  MessagePort get port() native "return this.port;";
}

class SharedWorkerContext extends WorkerContext native "*SharedWorkerContext" {

  String get name() native "return this.name;";

  EventListener get onconnect() native "return this.onconnect;";

  void set onconnect(EventListener value) native "this.onconnect = value;";
}

class SpeechInputEvent extends Event native "*SpeechInputEvent" {

  SpeechInputResultList get results() native "return this.results;";
}

class SpeechInputResult native "*SpeechInputResult" {

  num get confidence() native "return this.confidence;";

  String get utterance() native "return this.utterance;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SpeechInputResultList native "*SpeechInputResultList" {

  int get length() native "return this.length;";

  SpeechInputResult item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Storage native "*Storage" {

  int get length() native "return this.length;";

  void clear() native;

  String getItem(String key) native;

  String key(int index) native;

  void removeItem(String key) native;

  void setItem(String key, String data) native;

  var get dartObjectLocalStorage() native """

    if (this === window.localStorage)
      return window._dartLocalStorageLocalStorage;
    else if (this === window.sessionStorage)
      return window._dartSessionStorageLocalStorage;
    else
      throw new UnsupportedOperationException('Cannot dartObjectLocalStorage for unknown Storage object.');

""" {
    throw new UnsupportedOperationException('');
  }

  void set dartObjectLocalStorage(var value) native """

    if (this === window.localStorage)
      window._dartLocalStorageLocalStorage = value;
    else if (this === window.sessionStorage)
      window._dartSessionStorageLocalStorage = value;
    else
      throw new UnsupportedOperationException('Cannot dartObjectLocalStorage for unknown Storage object.');

""" {
    throw new UnsupportedOperationException('');
  }

  String get typeName() native;
}

class StorageEvent extends Event native "*StorageEvent" {

  String get key() native "return this.key;";

  String get newValue() native "return this.newValue;";

  String get oldValue() native "return this.oldValue;";

  Storage get storageArea() native "return this.storageArea;";

  String get url() native "return this.url;";

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg) native;
}

class StorageInfo native "*StorageInfo" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback = null, StorageInfoErrorCallback errorCallback = null]) native;

  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback = null, StorageInfoErrorCallback errorCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
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

class StyleMedia native "*StyleMedia" {

  String get type() native "return this.type;";

  bool matchMedium(String mediaquery) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class StyleSheet native "*StyleSheet" {

  bool get disabled() native "return this.disabled;";

  void set disabled(bool value) native "this.disabled = value;";

  String get href() native "return this.href;";

  MediaList get media() native "return this.media;";

  Node get ownerNode() native "return this.ownerNode;";

  StyleSheet get parentStyleSheet() native "return this.parentStyleSheet;";

  String get title() native "return this.title;";

  String get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class StyleSheetList native "*StyleSheetList" {

  int get length() native "return this.length;";

  StyleSheet operator[](int index) native;

  void operator[]=(int index, StyleSheet value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  StyleSheet item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Text extends CharacterData native "*Text" {

  String get wholeText() native "return this.wholeText;";

  Text replaceWholeText(String content) native;

  Text splitText(int offset) native;
}

class TextEvent extends UIEvent native "*TextEvent" {

  String get data() native "return this.data;";

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindow viewArg, String dataArg) native;
}

class TextMetrics native "*TextMetrics" {

  num get width() native "return this.width;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TextTrack native "*TextTrack" {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  TextTrackCueList get activeCues() native "return this.activeCues;";

  TextTrackCueList get cues() native "return this.cues;";

  String get kind() native "return this.kind;";

  String get label() native "return this.label;";

  String get language() native "return this.language;";

  int get mode() native "return this.mode;";

  void set mode(int value) native "this.mode = value;";

  EventListener get oncuechange() native "return this.oncuechange;";

  void set oncuechange(EventListener value) native "this.oncuechange = value;";

  void addCue(TextTrackCue cue) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeCue(TextTrackCue cue) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TextTrackCue native "*TextTrackCue" {

  String get alignment() native "return this.alignment;";

  void set alignment(String value) native "this.alignment = value;";

  String get direction() native "return this.direction;";

  void set direction(String value) native "this.direction = value;";

  num get endTime() native "return this.endTime;";

  void set endTime(num value) native "this.endTime = value;";

  String get id() native "return this.id;";

  void set id(String value) native "this.id = value;";

  int get linePosition() native "return this.linePosition;";

  void set linePosition(int value) native "this.linePosition = value;";

  EventListener get onenter() native "return this.onenter;";

  void set onenter(EventListener value) native "this.onenter = value;";

  EventListener get onexit() native "return this.onexit;";

  void set onexit(EventListener value) native "this.onexit = value;";

  bool get pauseOnExit() native "return this.pauseOnExit;";

  void set pauseOnExit(bool value) native "this.pauseOnExit = value;";

  int get size() native "return this.size;";

  void set size(int value) native "this.size = value;";

  bool get snapToLines() native "return this.snapToLines;";

  void set snapToLines(bool value) native "this.snapToLines = value;";

  num get startTime() native "return this.startTime;";

  void set startTime(num value) native "this.startTime = value;";

  String get text() native "return this.text;";

  void set text(String value) native "this.text = value;";

  int get textPosition() native "return this.textPosition;";

  void set textPosition(int value) native "this.textPosition = value;";

  TextTrack get track() native "return this.track;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  DocumentFragment getCueAsHTML() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TextTrackCueList native "*TextTrackCueList" {

  int get length() native "return this.length;";

  TextTrackCue getCueById(String id) native;

  TextTrackCue item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TextTrackList native "*TextTrackList" {

  int get length() native "return this.length;";

  EventListener get onaddtrack() native "return this.onaddtrack;";

  void set onaddtrack(EventListener value) native "this.onaddtrack = value;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  TextTrack item(int index) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TimeRanges native "*TimeRanges" {

  int get length() native "return this.length;";

  num end(int index) native;

  num start(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Touch native "*Touch" {

  int get clientX() native "return this.clientX;";

  int get clientY() native "return this.clientY;";

  int get identifier() native "return this.identifier;";

  int get pageX() native "return this.pageX;";

  int get pageY() native "return this.pageY;";

  int get screenX() native "return this.screenX;";

  int get screenY() native "return this.screenY;";

  EventTarget get target() native "return this.target;";

  num get webkitForce() native "return this.webkitForce;";

  int get webkitRadiusX() native "return this.webkitRadiusX;";

  int get webkitRadiusY() native "return this.webkitRadiusY;";

  num get webkitRotationAngle() native "return this.webkitRotationAngle;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TouchEvent extends UIEvent native "*TouchEvent" {

  bool get altKey() native "return this.altKey;";

  TouchList get changedTouches() native "return this.changedTouches;";

  bool get ctrlKey() native "return this.ctrlKey;";

  bool get metaKey() native "return this.metaKey;";

  bool get shiftKey() native "return this.shiftKey;";

  TouchList get targetTouches() native "return this.targetTouches;";

  TouchList get touches() native "return this.touches;";

  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}

class TouchList native "*TouchList" {

  int get length() native "return this.length;";

  Touch operator[](int index) native;

  void operator[]=(int index, Touch value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  Touch item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TrackEvent extends Event native "*TrackEvent" {

  Object get track() native "return this.track;";
}

class TreeWalker native "*TreeWalker" {

  Node get currentNode() native "return this.currentNode;";

  void set currentNode(Node value) native "this.currentNode = value;";

  bool get expandEntityReferences() native "return this.expandEntityReferences;";

  NodeFilter get filter() native "return this.filter;";

  Node get root() native "return this.root;";

  int get whatToShow() native "return this.whatToShow;";

  Node firstChild() native;

  Node lastChild() native;

  Node nextNode() native;

  Node nextSibling() native;

  Node parentNode() native;

  Node previousNode() native;

  Node previousSibling() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class UIEvent extends Event native "*UIEvent" {

  int get charCode() native "return this.charCode;";

  int get detail() native "return this.detail;";

  int get keyCode() native "return this.keyCode;";

  int get layerX() native "return this.layerX;";

  int get layerY() native "return this.layerY;";

  int get pageX() native "return this.pageX;";

  int get pageY() native "return this.pageY;";

  DOMWindow get view() native "return this.view;";

  int get which() native "return this.which;";

  void initUIEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail) native;
}

class Uint16Array extends ArrayBufferView implements List<int> native "*Uint16Array" {

  factory Uint16Array(int length) =>  _construct(length);

  factory Uint16Array.fromList(List<int> list) => _construct(list);

  factory Uint16Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Uint16Array(arg);';

  static final int BYTES_PER_ELEMENT = 2;

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  Uint16Array subarray(int start, [int end = null]) native;
}

class Uint32Array extends ArrayBufferView implements List<int> native "*Uint32Array" {

  factory Uint32Array(int length) =>  _construct(length);

  factory Uint32Array.fromList(List<int> list) => _construct(list);

  factory Uint32Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Uint32Array(arg);';

  static final int BYTES_PER_ELEMENT = 4;

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  Uint32Array subarray(int start, [int end = null]) native;
}

class Uint8Array extends ArrayBufferView implements List<int> native "*Uint8Array" {

  factory Uint8Array(int length) =>  _construct(length);

  factory Uint8Array.fromList(List<int> list) => _construct(list);

  factory Uint8Array.fromBuffer(ArrayBuffer buffer) => _construct(buffer);

  static _construct(arg) native 'return new Uint8Array(arg);';

  static final int BYTES_PER_ELEMENT = 1;

  int get length() native "return this.length;";

  int operator[](int index) native;

  void operator[]=(int index, int value) native;

  Uint8Array subarray(int start, [int end = null]) native;
}

class ValidityState native "*ValidityState" {

  bool get customError() native "return this.customError;";

  bool get patternMismatch() native "return this.patternMismatch;";

  bool get rangeOverflow() native "return this.rangeOverflow;";

  bool get rangeUnderflow() native "return this.rangeUnderflow;";

  bool get stepMismatch() native "return this.stepMismatch;";

  bool get tooLong() native "return this.tooLong;";

  bool get typeMismatch() native "return this.typeMismatch;";

  bool get valid() native "return this.valid;";

  bool get valueMissing() native "return this.valueMissing;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef void VoidCallback();

class WaveShaperNode extends AudioNode native "*WaveShaperNode" {

  Float32Array get curve() native "return this.curve;";

  void set curve(Float32Array value) native "this.curve = value;";
}

class WebGLActiveInfo native "*WebGLActiveInfo" {

  String get name() native "return this.name;";

  int get size() native "return this.size;";

  int get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLBuffer native "*WebGLBuffer" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLCompressedTextures native "*WebGLCompressedTextures" {

  static final int COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;

  static final int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  static final int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  static final int COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;

  static final int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;

  static final int ETC1_RGB8_OES = 0x8D64;

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, ArrayBufferView data) native;

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, ArrayBufferView data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLContextAttributes native "*WebGLContextAttributes" {

  bool get alpha() native "return this.alpha;";

  void set alpha(bool value) native "this.alpha = value;";

  bool get antialias() native "return this.antialias;";

  void set antialias(bool value) native "this.antialias = value;";

  bool get depth() native "return this.depth;";

  void set depth(bool value) native "this.depth = value;";

  bool get premultipliedAlpha() native "return this.premultipliedAlpha;";

  void set premultipliedAlpha(bool value) native "this.premultipliedAlpha = value;";

  bool get preserveDrawingBuffer() native "return this.preserveDrawingBuffer;";

  void set preserveDrawingBuffer(bool value) native "this.preserveDrawingBuffer = value;";

  bool get stencil() native "return this.stencil;";

  void set stencil(bool value) native "this.stencil = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLContextEvent extends Event native "*WebGLContextEvent" {

  String get statusMessage() native "return this.statusMessage;";
}

class WebGLDebugRendererInfo native "*WebGLDebugRendererInfo" {

  static final int UNMASKED_RENDERER_WEBGL = 0x9246;

  static final int UNMASKED_VENDOR_WEBGL = 0x9245;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLDebugShaders native "*WebGLDebugShaders" {

  String getTranslatedShaderSource(WebGLShader shader) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLFramebuffer native "*WebGLFramebuffer" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLLoseContext native "*WebGLLoseContext" {

  void loseContext() native;

  void restoreContext() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLProgram native "*WebGLProgram" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLRenderbuffer native "*WebGLRenderbuffer" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLRenderingContext extends CanvasRenderingContext native "*WebGLRenderingContext" {

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

  static final int NUM_COMPRESSED_TEXTURE_FORMATS = 0x86A2;

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

  int get drawingBufferHeight() native "return this.drawingBufferHeight;";

  int get drawingBufferWidth() native "return this.drawingBufferWidth;";

  void activeTexture(int texture) native;

  void attachShader(WebGLProgram program, WebGLShader shader) native;

  void bindAttribLocation(WebGLProgram program, int index, String name) native;

  void bindBuffer(int target, WebGLBuffer buffer) native;

  void bindFramebuffer(int target, WebGLFramebuffer framebuffer) native;

  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer) native;

  void bindTexture(int target, WebGLTexture texture) native;

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

  void compileShader(WebGLShader shader) native;

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) native;

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) native;

  WebGLBuffer createBuffer() native;

  WebGLFramebuffer createFramebuffer() native;

  WebGLProgram createProgram() native;

  WebGLRenderbuffer createRenderbuffer() native;

  WebGLShader createShader(int type) native;

  WebGLTexture createTexture() native;

  void cullFace(int mode) native;

  void deleteBuffer(WebGLBuffer buffer) native;

  void deleteFramebuffer(WebGLFramebuffer framebuffer) native;

  void deleteProgram(WebGLProgram program) native;

  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer) native;

  void deleteShader(WebGLShader shader) native;

  void deleteTexture(WebGLTexture texture) native;

  void depthFunc(int func) native;

  void depthMask(bool flag) native;

  void depthRange(num zNear, num zFar) native;

  void detachShader(WebGLProgram program, WebGLShader shader) native;

  void disable(int cap) native;

  void disableVertexAttribArray(int index) native;

  void drawArrays(int mode, int first, int count) native;

  void drawElements(int mode, int count, int type, int offset) native;

  void enable(int cap) native;

  void enableVertexAttribArray(int index) native;

  void finish() native;

  void flush() native;

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, WebGLRenderbuffer renderbuffer) native;

  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level) native;

  void frontFace(int mode) native;

  void generateMipmap(int target) native;

  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index) native;

  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index) native;

  void getAttachedShaders(WebGLProgram program) native;

  int getAttribLocation(WebGLProgram program, String name) native;

  Object getBufferParameter(int target, int pname) native;

  WebGLContextAttributes getContextAttributes() native;

  int getError() native;

  Object getExtension(String name) native;

  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) native;

  Object getParameter(int pname) native;

  String getProgramInfoLog(WebGLProgram program) native;

  Object getProgramParameter(WebGLProgram program, int pname) native;

  Object getRenderbufferParameter(int target, int pname) native;

  String getShaderInfoLog(WebGLShader shader) native;

  Object getShaderParameter(WebGLShader shader, int pname) native;

  String getShaderSource(WebGLShader shader) native;

  Object getTexParameter(int target, int pname) native;

  Object getUniform(WebGLProgram program, WebGLUniformLocation location) native;

  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) native;

  Object getVertexAttrib(int index, int pname) native;

  int getVertexAttribOffset(int index, int pname) native;

  void hint(int target, int mode) native;

  bool isBuffer(WebGLBuffer buffer) native;

  bool isContextLost() native;

  bool isEnabled(int cap) native;

  bool isFramebuffer(WebGLFramebuffer framebuffer) native;

  bool isProgram(WebGLProgram program) native;

  bool isRenderbuffer(WebGLRenderbuffer renderbuffer) native;

  bool isShader(WebGLShader shader) native;

  bool isTexture(WebGLTexture texture) native;

  void lineWidth(num width) native;

  void linkProgram(WebGLProgram program) native;

  void pixelStorei(int pname, int param) native;

  void polygonOffset(num factor, num units) native;

  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels) native;

  void releaseShaderCompiler() native;

  void renderbufferStorage(int target, int internalformat, int width, int height) native;

  void sampleCoverage(num value, bool invert) native;

  void scissor(int x, int y, int width, int height) native;

  void shaderSource(WebGLShader shader, String string) native;

  void stencilFunc(int func, int ref, int mask) native;

  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  void stencilMask(int mask) native;

  void stencilMaskSeparate(int face, int mask) native;

  void stencilOp(int fail, int zfail, int zpass) native;

  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels_OR_video, [int format = null, int type = null, ArrayBufferView pixels = null]) native;

  void texParameterf(int target, int pname, num param) native;

  void texParameteri(int target, int pname, int param) native;

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels_OR_video, [int type = null, ArrayBufferView pixels = null]) native;

  void uniform1f(WebGLUniformLocation location, num x) native;

  void uniform1fv(WebGLUniformLocation location, Float32Array v) native;

  void uniform1i(WebGLUniformLocation location, int x) native;

  void uniform1iv(WebGLUniformLocation location, Int32Array v) native;

  void uniform2f(WebGLUniformLocation location, num x, num y) native;

  void uniform2fv(WebGLUniformLocation location, Float32Array v) native;

  void uniform2i(WebGLUniformLocation location, int x, int y) native;

  void uniform2iv(WebGLUniformLocation location, Int32Array v) native;

  void uniform3f(WebGLUniformLocation location, num x, num y, num z) native;

  void uniform3fv(WebGLUniformLocation location, Float32Array v) native;

  void uniform3i(WebGLUniformLocation location, int x, int y, int z) native;

  void uniform3iv(WebGLUniformLocation location, Int32Array v) native;

  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w) native;

  void uniform4fv(WebGLUniformLocation location, Float32Array v) native;

  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w) native;

  void uniform4iv(WebGLUniformLocation location, Int32Array v) native;

  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  void useProgram(WebGLProgram program) native;

  void validateProgram(WebGLProgram program) native;

  void vertexAttrib1f(int indx, num x) native;

  void vertexAttrib1fv(int indx, Float32Array values) native;

  void vertexAttrib2f(int indx, num x, num y) native;

  void vertexAttrib2fv(int indx, Float32Array values) native;

  void vertexAttrib3f(int indx, num x, num y, num z) native;

  void vertexAttrib3fv(int indx, Float32Array values) native;

  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  void vertexAttrib4fv(int indx, Float32Array values) native;

  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) native;

  void viewport(int x, int y, int width, int height) native;
}

class WebGLShader native "*WebGLShader" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLTexture native "*WebGLTexture" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLUniformLocation native "*WebGLUniformLocation" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLVertexArrayObjectOES native "*WebGLVertexArrayObjectOES" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitAnimation native "*WebKitAnimation" {

  static final int DIRECTION_ALTERNATE = 1;

  static final int DIRECTION_NORMAL = 0;

  static final int FILL_BACKWARDS = 1;

  static final int FILL_BOTH = 3;

  static final int FILL_FORWARDS = 2;

  static final int FILL_NONE = 0;

  num get delay() native "return this.delay;";

  int get direction() native "return this.direction;";

  num get duration() native "return this.duration;";

  num get elapsedTime() native "return this.elapsedTime;";

  void set elapsedTime(num value) native "this.elapsedTime = value;";

  bool get ended() native "return this.ended;";

  int get fillMode() native "return this.fillMode;";

  int get iterationCount() native "return this.iterationCount;";

  String get name() native "return this.name;";

  bool get paused() native "return this.paused;";

  void pause() native;

  void play() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitAnimationEvent extends Event native "*WebKitAnimationEvent" {

  String get animationName() native "return this.animationName;";

  num get elapsedTime() native "return this.elapsedTime;";
}

class WebKitAnimationList native "*WebKitAnimationList" {

  int get length() native "return this.length;";

  WebKitAnimation item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitBlobBuilder native "*WebKitBlobBuilder" {

  void append(var arrayBuffer_OR_blob_OR_value, [String endings = null]) native;

  Blob getBlob([String contentType = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitCSSFilterValue extends CSSValueList native "*WebKitCSSFilterValue" {

  static final int CSS_FILTER_BLUR = 10;

  static final int CSS_FILTER_BRIGHTNESS = 8;

  static final int CSS_FILTER_CONTRAST = 9;

  static final int CSS_FILTER_DROP_SHADOW = 11;

  static final int CSS_FILTER_GRAYSCALE = 2;

  static final int CSS_FILTER_HUE_ROTATE = 5;

  static final int CSS_FILTER_INVERT = 6;

  static final int CSS_FILTER_OPACITY = 7;

  static final int CSS_FILTER_REFERENCE = 1;

  static final int CSS_FILTER_SATURATE = 4;

  static final int CSS_FILTER_SEPIA = 3;

  int get operationType() native "return this.operationType;";
}

class WebKitCSSKeyframeRule extends CSSRule native "*WebKitCSSKeyframeRule" {

  String get keyText() native "return this.keyText;";

  void set keyText(String value) native "this.keyText = value;";

  CSSStyleDeclaration get style() native "return this.style;";
}

class WebKitCSSKeyframesRule extends CSSRule native "*WebKitCSSKeyframesRule" {

  CSSRuleList get cssRules() native "return this.cssRules;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";

  void deleteRule(String key) native;

  WebKitCSSKeyframeRule findRule(String key) native;

  void insertRule(String rule) native;
}

class WebKitCSSMatrix native "*WebKitCSSMatrix" {
  WebKitCSSMatrix([String spec]) native;


  num get a() native "return this.a;";

  void set a(num value) native "this.a = value;";

  num get b() native "return this.b;";

  void set b(num value) native "this.b = value;";

  num get c() native "return this.c;";

  void set c(num value) native "this.c = value;";

  num get d() native "return this.d;";

  void set d(num value) native "this.d = value;";

  num get e() native "return this.e;";

  void set e(num value) native "this.e = value;";

  num get f() native "return this.f;";

  void set f(num value) native "this.f = value;";

  num get m11() native "return this.m11;";

  void set m11(num value) native "this.m11 = value;";

  num get m12() native "return this.m12;";

  void set m12(num value) native "this.m12 = value;";

  num get m13() native "return this.m13;";

  void set m13(num value) native "this.m13 = value;";

  num get m14() native "return this.m14;";

  void set m14(num value) native "this.m14 = value;";

  num get m21() native "return this.m21;";

  void set m21(num value) native "this.m21 = value;";

  num get m22() native "return this.m22;";

  void set m22(num value) native "this.m22 = value;";

  num get m23() native "return this.m23;";

  void set m23(num value) native "this.m23 = value;";

  num get m24() native "return this.m24;";

  void set m24(num value) native "this.m24 = value;";

  num get m31() native "return this.m31;";

  void set m31(num value) native "this.m31 = value;";

  num get m32() native "return this.m32;";

  void set m32(num value) native "this.m32 = value;";

  num get m33() native "return this.m33;";

  void set m33(num value) native "this.m33 = value;";

  num get m34() native "return this.m34;";

  void set m34(num value) native "this.m34 = value;";

  num get m41() native "return this.m41;";

  void set m41(num value) native "this.m41 = value;";

  num get m42() native "return this.m42;";

  void set m42(num value) native "this.m42 = value;";

  num get m43() native "return this.m43;";

  void set m43(num value) native "this.m43 = value;";

  num get m44() native "return this.m44;";

  void set m44(num value) native "this.m44 = value;";

  WebKitCSSMatrix inverse() native;

  WebKitCSSMatrix multiply(WebKitCSSMatrix secondMatrix) native;

  WebKitCSSMatrix rotate(num rotX, num rotY, num rotZ) native;

  WebKitCSSMatrix rotateAxisAngle(num x, num y, num z, num angle) native;

  WebKitCSSMatrix scale(num scaleX, num scaleY, num scaleZ) native;

  void setMatrixValue(String string) native;

  WebKitCSSMatrix skewX(num angle) native;

  WebKitCSSMatrix skewY(num angle) native;

  String toString() native;

  WebKitCSSMatrix translate(num x, num y, num z) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitCSSTransformValue extends CSSValueList native "*WebKitCSSTransformValue" {

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

  int get operationType() native "return this.operationType;";
}

class WebKitMutationObserver native "*WebKitMutationObserver" {

  void disconnect() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitNamedFlow native "*WebKitNamedFlow" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitPoint native "*WebKitPoint" {
  WebKitPoint(num x, num y) native;


  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitTransitionEvent extends Event native "*WebKitTransitionEvent" {

  num get elapsedTime() native "return this.elapsedTime;";

  String get propertyName() native "return this.propertyName;";
}

class WebSocket native "*WebSocket" {
  WebSocket(String url) native;


  static final int CLOSED = 3;

  static final int CLOSING = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String get URL() native "return this.URL;";

  String get binaryType() native "return this.binaryType;";

  void set binaryType(String value) native "this.binaryType = value;";

  int get bufferedAmount() native "return this.bufferedAmount;";

  String get extensions() native "return this.extensions;";

  String get protocol() native "return this.protocol;";

  int get readyState() native "return this.readyState;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close([int code = null, String reason = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool send(String data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WheelEvent extends UIEvent native "*WheelEvent" {

  bool get altKey() native "return this.altKey;";

  int get clientX() native "return this.clientX;";

  int get clientY() native "return this.clientY;";

  bool get ctrlKey() native "return this.ctrlKey;";

  bool get metaKey() native "return this.metaKey;";

  int get offsetX() native "return this.offsetX;";

  int get offsetY() native "return this.offsetY;";

  int get screenX() native "return this.screenX;";

  int get screenY() native "return this.screenY;";

  bool get shiftKey() native "return this.shiftKey;";

  bool get webkitDirectionInvertedFromDevice() native "return this.webkitDirectionInvertedFromDevice;";

  int get wheelDelta() native "return this.wheelDelta;";

  int get wheelDeltaX() native "return this.wheelDeltaX;";

  int get wheelDeltaY() native "return this.wheelDeltaY;";

  int get x() native "return this.x;";

  int get y() native "return this.y;";

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}

class Worker extends AbstractWorker native "*Worker" {

  void postMessage(String message, [List messagePorts = null]) native;

  void terminate() native;

  void webkitPostMessage(String message, [List messagePorts = null]) native;
}

class WorkerContext native "*WorkerContext" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  WorkerLocation get location() native "return this.location;";

  void set location(WorkerLocation value) native "this.location = value;";

  WorkerNavigator get navigator() native "return this.navigator;";

  void set navigator(WorkerNavigator value) native "this.navigator = value;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  WorkerContext get self() native "return this.self;";

  void set self(WorkerContext value) native "this.self = value;";

  IDBFactory get webkitIndexedDB() native "return this.webkitIndexedDB;";

  NotificationCenter get webkitNotifications() native "return this.webkitNotifications;";

  DOMURL get webkitURL() native "return this.webkitURL;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool dispatchEvent(Event evt) native;

  void importScripts() native;

  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  DatabaseSync openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  DOMFileSystemSync webkitRequestFileSystemSync(int type, int size) native;

  EntrySync webkitResolveLocalFileSystemSyncURL(String url) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WorkerLocation native "*WorkerLocation" {

  String get hash() native "return this.hash;";

  String get host() native "return this.host;";

  String get hostname() native "return this.hostname;";

  String get href() native "return this.href;";

  String get pathname() native "return this.pathname;";

  String get port() native "return this.port;";

  String get protocol() native "return this.protocol;";

  String get search() native "return this.search;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WorkerNavigator native "*WorkerNavigator" {

  String get appName() native "return this.appName;";

  String get appVersion() native "return this.appVersion;";

  bool get onLine() native "return this.onLine;";

  String get platform() native "return this.platform;";

  String get userAgent() native "return this.userAgent;";

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XMLHttpRequest native "*XMLHttpRequest" {
  XMLHttpRequest() native;


  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  bool get asBlob() native "return this.asBlob;";

  void set asBlob(bool value) native "this.asBlob = value;";

  int get readyState() native "return this.readyState;";

  Blob get responseBlob() native "return this.responseBlob;";

  String get responseText() native "return this.responseText;";

  String get responseType() native "return this.responseType;";

  void set responseType(String value) native "this.responseType = value;";

  Document get responseXML() native "return this.responseXML;";

  int get status() native "return this.status;";

  String get statusText() native "return this.statusText;";

  XMLHttpRequestUpload get upload() native "return this.upload;";

  bool get withCredentials() native "return this.withCredentials;";

  void set withCredentials(bool value) native "this.withCredentials = value;";

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  String getAllResponseHeaders() native;

  String getResponseHeader(String header) native;

  void open(String method, String url, [bool async = null, String user = null, String password = null]) native;

  void overrideMimeType(String override) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void send([var data = null]) native;

  void setRequestHeader(String header, String value) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XMLHttpRequestException native "*XMLHttpRequestException" {

  static final int ABORT_ERR = 102;

  static final int NETWORK_ERR = 101;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XMLHttpRequestProgressEvent extends ProgressEvent native "*XMLHttpRequestProgressEvent" {

  int get position() native "return this.position;";

  int get totalSize() native "return this.totalSize;";
}

class XMLHttpRequestUpload native "*XMLHttpRequestUpload" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XMLSerializer native "*XMLSerializer" {

  String serializeToString(Node node) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XPathEvaluator native "*XPathEvaluator" {

  XPathExpression createExpression(String expression, XPathNSResolver resolver) native;

  XPathNSResolver createNSResolver(Node nodeResolver) native;

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XPathException native "*XPathException" {

  static final int INVALID_EXPRESSION_ERR = 51;

  static final int TYPE_ERR = 52;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XPathExpression native "*XPathExpression" {

  XPathResult evaluate(Node contextNode, int type, XPathResult inResult) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XPathNSResolver native "*XPathNSResolver" {

  String lookupNamespaceURI(String prefix) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XPathResult native "*XPathResult" {

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

  bool get booleanValue() native "return this.booleanValue;";

  bool get invalidIteratorState() native "return this.invalidIteratorState;";

  num get numberValue() native "return this.numberValue;";

  int get resultType() native "return this.resultType;";

  Node get singleNodeValue() native "return this.singleNodeValue;";

  int get snapshotLength() native "return this.snapshotLength;";

  String get stringValue() native "return this.stringValue;";

  Node iterateNext() native;

  Node snapshotItem(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XSLTProcessor native "*XSLTProcessor" {

  void clearParameters() native;

  String getParameter(String namespaceURI, String localName) native;

  void importStylesheet(Node stylesheet) native;

  void removeParameter(String namespaceURI, String localName) native;

  void reset() native;

  void setParameter(String namespaceURI, String localName, String value) native;

  Document transformToDocument(Node source) native;

  DocumentFragment transformToFragment(Node source, Document docVal) native;

  var dartObjectLocalStorage;

  String get typeName() native;
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

typedef bool RequestAnimationFrameCallback(int time);
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
}
