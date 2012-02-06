#library('dom');

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated Dart DOM library.




// TODO(sra): What 'window' do we get in a worker?  Perhaps this
// should return the interface type.
DOMWindow get window() native "return window;";

// TODO(vsm): Revert to Dart method when 508 is fixed.
HTMLDocument get document() native "return window.document;";

class _AbstractWorkerJs extends _DOMTypeJs implements AbstractWorker native "*AbstractWorker" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _ArrayBufferJs extends _DOMTypeJs implements ArrayBuffer native "*ArrayBuffer" {

  final int byteLength;

  _ArrayBufferJs slice(int begin, [int end = null]) native;
}

class _ArrayBufferViewJs extends _DOMTypeJs implements ArrayBufferView native "*ArrayBufferView" {

  final _ArrayBufferJs buffer;

  final int byteLength;

  final int byteOffset;
}

class _AttrJs extends _NodeJs implements Attr native "*Attr" {

  final bool isId;

  final String name;

  final _ElementJs ownerElement;

  final bool specified;

  String value;
}

class _AudioBufferJs extends _DOMTypeJs implements AudioBuffer native "*AudioBuffer" {

  final num duration;

  num gain;

  final int length;

  final int numberOfChannels;

  final num sampleRate;

  _Float32ArrayJs getChannelData(int channelIndex) native;
}

class _AudioBufferSourceNodeJs extends _AudioSourceNodeJs implements AudioBufferSourceNode native "*AudioBufferSourceNode" {

  _AudioBufferJs buffer;

  final _AudioGainJs gain;

  bool loop;

  bool looping;

  final _AudioParamJs playbackRate;

  void noteGrainOn(num when, num grainOffset, num grainDuration) native;

  void noteOff(num when) native;

  void noteOn(num when) native;
}

class _AudioChannelMergerJs extends _AudioNodeJs implements AudioChannelMerger native "*AudioChannelMerger" {
}

class _AudioChannelSplitterJs extends _AudioNodeJs implements AudioChannelSplitter native "*AudioChannelSplitter" {
}

class _AudioContextJs extends _DOMTypeJs implements AudioContext native "*AudioContext" {
  AudioContext() native;


  final num currentTime;

  final _AudioDestinationNodeJs destination;

  final _AudioListenerJs listener;

  EventListener oncomplete;

  final num sampleRate;

  _RealtimeAnalyserNodeJs createAnalyser() native;

  _BiquadFilterNodeJs createBiquadFilter() native;

  _AudioBufferJs createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate = null]) native;

  _AudioBufferSourceNodeJs createBufferSource() native;

  _AudioChannelMergerJs createChannelMerger() native;

  _AudioChannelSplitterJs createChannelSplitter() native;

  _ConvolverNodeJs createConvolver() native;

  _DelayNodeJs createDelayNode() native;

  _DynamicsCompressorNodeJs createDynamicsCompressor() native;

  _AudioGainNodeJs createGainNode() native;

  _HighPass2FilterNodeJs createHighPass2Filter() native;

  _JavaScriptAudioNodeJs createJavaScriptNode(int bufferSize) native;

  _LowPass2FilterNodeJs createLowPass2Filter() native;

  _MediaElementAudioSourceNodeJs createMediaElementSource(_HTMLMediaElementJs mediaElement) native;

  _AudioPannerNodeJs createPanner() native;

  _WaveShaperNodeJs createWaveShaper() native;

  void decodeAudioData(_ArrayBufferJs audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) native;

  void startRendering() native;
}

class _AudioDestinationNodeJs extends _AudioNodeJs implements AudioDestinationNode native "*AudioDestinationNode" {

  final int numberOfChannels;
}

class _AudioGainJs extends _AudioParamJs implements AudioGain native "*AudioGain" {
}

class _AudioGainNodeJs extends _AudioNodeJs implements AudioGainNode native "*AudioGainNode" {

  final _AudioGainJs gain;
}

class _AudioListenerJs extends _DOMTypeJs implements AudioListener native "*AudioListener" {

  num dopplerFactor;

  num speedOfSound;

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;
}

class _AudioNodeJs extends _DOMTypeJs implements AudioNode native "*AudioNode" {

  final _AudioContextJs context;

  final int numberOfInputs;

  final int numberOfOutputs;

  void connect(_AudioNodeJs destination, int output, int input) native;

  void disconnect(int output) native;
}

class _AudioPannerNodeJs extends _AudioNodeJs implements AudioPannerNode native "*AudioPannerNode" {

  static final int EQUALPOWER = 0;

  static final int HRTF = 1;

  static final int SOUNDFIELD = 2;

  final _AudioGainJs coneGain;

  num coneInnerAngle;

  num coneOuterAngle;

  num coneOuterGain;

  final _AudioGainJs distanceGain;

  int distanceModel;

  num maxDistance;

  int panningModel;

  num refDistance;

  num rolloffFactor;

  void setOrientation(num x, num y, num z) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;
}

class _AudioParamJs extends _DOMTypeJs implements AudioParam native "*AudioParam" {

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

  void setValueCurveAtTime(_Float32ArrayJs values, num time, num duration) native;
}

class _AudioProcessingEventJs extends _EventJs implements AudioProcessingEvent native "*AudioProcessingEvent" {

  final _AudioBufferJs inputBuffer;

  final _AudioBufferJs outputBuffer;
}

class _AudioSourceNodeJs extends _AudioNodeJs implements AudioSourceNode native "*AudioSourceNode" {
}

class _BarInfoJs extends _DOMTypeJs implements BarInfo native "*BarInfo" {

  final bool visible;
}

class _BeforeLoadEventJs extends _EventJs implements BeforeLoadEvent native "*BeforeLoadEvent" {

  final String url;
}

class _BiquadFilterNodeJs extends _AudioNodeJs implements BiquadFilterNode native "*BiquadFilterNode" {

  static final int ALLPASS = 7;

  static final int BANDPASS = 2;

  static final int HIGHPASS = 1;

  static final int HIGHSHELF = 4;

  static final int LOWPASS = 0;

  static final int LOWSHELF = 3;

  static final int NOTCH = 6;

  static final int PEAKING = 5;

  final _AudioParamJs Q;

  final _AudioParamJs frequency;

  final _AudioParamJs gain;

  int type;

  void getFrequencyResponse(_Float32ArrayJs frequencyHz, _Float32ArrayJs magResponse, _Float32ArrayJs phaseResponse) native;
}

class _BlobJs extends _DOMTypeJs implements Blob native "*Blob" {

  final int size;

  final String type;

  _BlobJs webkitSlice([int start = null, int end = null, String contentType = null]) native;
}

class _CDATASectionJs extends _TextJs implements CDATASection native "*CDATASection" {
}

class _CSSCharsetRuleJs extends _CSSRuleJs implements CSSCharsetRule native "*CSSCharsetRule" {

  String encoding;
}

class _CSSFontFaceRuleJs extends _CSSRuleJs implements CSSFontFaceRule native "*CSSFontFaceRule" {

  final _CSSStyleDeclarationJs style;
}

class _CSSImportRuleJs extends _CSSRuleJs implements CSSImportRule native "*CSSImportRule" {

  final String href;

  final _MediaListJs media;

  final _CSSStyleSheetJs styleSheet;
}

class _CSSMediaRuleJs extends _CSSRuleJs implements CSSMediaRule native "*CSSMediaRule" {

  final _CSSRuleListJs cssRules;

  final _MediaListJs media;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

class _CSSPageRuleJs extends _CSSRuleJs implements CSSPageRule native "*CSSPageRule" {

  String selectorText;

  final _CSSStyleDeclarationJs style;
}

class _CSSPrimitiveValueJs extends _CSSValueJs implements CSSPrimitiveValue native "*CSSPrimitiveValue" {

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

  _CounterJs getCounterValue() native;

  num getFloatValue(int unitType) native;

  _RGBColorJs getRGBColorValue() native;

  _RectJs getRectValue() native;

  String getStringValue() native;

  void setFloatValue(int unitType, num floatValue) native;

  void setStringValue(int stringType, String stringValue) native;
}

class _CSSRuleJs extends _DOMTypeJs implements CSSRule native "*CSSRule" {

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

  String cssText;

  final _CSSRuleJs parentRule;

  final _CSSStyleSheetJs parentStyleSheet;

  final int type;
}

class _CSSRuleListJs extends _DOMTypeJs implements CSSRuleList native "*CSSRuleList" {

  final int length;

  _CSSRuleJs item(int index) native;
}

class _CSSStyleDeclarationJs extends _DOMTypeJs implements CSSStyleDeclaration native "*CSSStyleDeclaration" {

  String cssText;

  final int length;

  final _CSSRuleJs parentRule;

  _CSSValueJs getPropertyCSSValue(String propertyName) native;

  String getPropertyPriority(String propertyName) native;

  String getPropertyShorthand(String propertyName) native;

  String getPropertyValue(String propertyName) native;

  bool isPropertyImplicit(String propertyName) native;

  String item(int index) native;

  String removeProperty(String propertyName) native;

  void setProperty(String propertyName, String value, [String priority = null]) native;
}

class _CSSStyleRuleJs extends _CSSRuleJs implements CSSStyleRule native "*CSSStyleRule" {

  String selectorText;

  final _CSSStyleDeclarationJs style;
}

class _CSSStyleSheetJs extends _StyleSheetJs implements CSSStyleSheet native "*CSSStyleSheet" {

  final _CSSRuleListJs cssRules;

  final _CSSRuleJs ownerRule;

  final _CSSRuleListJs rules;

  int addRule(String selector, String style, [int index = null]) native;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;

  void removeRule(int index) native;
}

class _CSSUnknownRuleJs extends _CSSRuleJs implements CSSUnknownRule native "*CSSUnknownRule" {
}

class _CSSValueJs extends _DOMTypeJs implements CSSValue native "*CSSValue" {

  static final int CSS_CUSTOM = 3;

  static final int CSS_INHERIT = 0;

  static final int CSS_PRIMITIVE_VALUE = 1;

  static final int CSS_VALUE_LIST = 2;

  String cssText;

  final int cssValueType;
}

class _CSSValueListJs extends _CSSValueJs implements CSSValueList native "*CSSValueList" {

  final int length;

  _CSSValueJs item(int index) native;
}

class _CanvasGradientJs extends _DOMTypeJs implements CanvasGradient native "*CanvasGradient" {

  void addColorStop(num offset, String color) native;
}

class _CanvasPatternJs extends _DOMTypeJs implements CanvasPattern native "*CanvasPattern" {
}

class _CanvasPixelArrayJs extends _DOMTypeJs implements CanvasPixelArray native "*CanvasPixelArray" {

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

class _CanvasRenderingContextJs extends _DOMTypeJs implements CanvasRenderingContext native "*CanvasRenderingContext" {

  final _HTMLCanvasElementJs canvas;
}

class _CanvasRenderingContext2DJs extends _CanvasRenderingContextJs implements CanvasRenderingContext2D native "*CanvasRenderingContext2D" {

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

  _ImageDataJs createImageData(var imagedata_OR_sw, [num sh = null]) native;

  _CanvasGradientJs createLinearGradient(num x0, num y0, num x1, num y1) native;

  _CanvasPatternJs createPattern(var canvas_OR_image, String repetitionType) native;

  _CanvasGradientJs createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) native;

  void drawImage(var canvas_OR_image_OR_video, num sx_OR_x, num sy_OR_y, [num sw_OR_width = null, num height_OR_sh = null, num dx = null, num dy = null, num dw = null, num dh = null]) native;

  void drawImageFromRect(_HTMLImageElementJs image, [num sx = null, num sy = null, num sw = null, num sh = null, num dx = null, num dy = null, num dw = null, num dh = null, String compositeOperation = null]) native;

  void fill() native;

  void fillRect(num x, num y, num width, num height) native;

  void fillText(String text, num x, num y, [num maxWidth = null]) native;

  _ImageDataJs getImageData(num sx, num sy, num sw, num sh) native;

  bool isPointInPath(num x, num y) native;

  void lineTo(num x, num y) native;

  _TextMetricsJs measureText(String text) native;

  void moveTo(num x, num y) native;

  void putImageData(_ImageDataJs imagedata, num dx, num dy, [num dirtyX = null, num dirtyY = null, num dirtyWidth = null, num dirtyHeight = null]) native;

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

class _CharacterDataJs extends _NodeJs implements CharacterData native "*CharacterData" {

  String data;

  final int length;

  void appendData(String data) native;

  void deleteData(int offset, int length) native;

  void insertData(int offset, String data) native;

  void replaceData(int offset, int length, String data) native;

  String substringData(int offset, int length) native;
}

class _ClientRectJs extends _DOMTypeJs implements ClientRect native "*ClientRect" {

  final num bottom;

  final num height;

  final num left;

  final num right;

  final num top;

  final num width;
}

class _ClientRectListJs extends _DOMTypeJs implements ClientRectList native "*ClientRectList" {

  final int length;

  _ClientRectJs item(int index) native;
}

class _ClipboardJs extends _DOMTypeJs implements Clipboard native "*Clipboard" {

  String dropEffect;

  String effectAllowed;

  final _FileListJs files;

  final _DataTransferItemListJs items;

  final List types;

  void clearData([String type = null]) native;

  void getData(String type) native;

  bool setData(String type, String data) native;

  void setDragImage(_HTMLImageElementJs image, int x, int y) native;
}

class _CloseEventJs extends _EventJs implements CloseEvent native "*CloseEvent" {

  final int code;

  final String reason;

  final bool wasClean;
}

class _CommentJs extends _CharacterDataJs implements Comment native "*Comment" {
}

class _CompositionEventJs extends _UIEventJs implements CompositionEvent native "*CompositionEvent" {

  final String data;

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, _DOMWindowJs viewArg, String dataArg) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ConsoleJs
    // Implement DOMType directly.  Console is sometimes a singleton
    // bag-of-properties without a prototype, so it can't inherit from
    // DOMTypeJs.
    implements Console, DOMType
    native "=(typeof console == 'undefined' ? {} : console)" {

  final _MemoryInfoJs memory;

  final List profiles;

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


  // Keep these in sync with frog_DOMTypeJs.dart.
  var dartObjectLocalStorage;
  String get typeName() native;
}

class _ConvolverNodeJs extends _AudioNodeJs implements ConvolverNode native "*ConvolverNode" {

  _AudioBufferJs buffer;

  bool normalize;
}

class _CoordinatesJs extends _DOMTypeJs implements Coordinates native "*Coordinates" {

  final num accuracy;

  final num altitude;

  final num altitudeAccuracy;

  final num heading;

  final num latitude;

  final num longitude;

  final num speed;
}

class _CounterJs extends _DOMTypeJs implements Counter native "*Counter" {

  final String identifier;

  final String listStyle;

  final String separator;
}

class _CryptoJs extends _DOMTypeJs implements Crypto native "*Crypto" {

  void getRandomValues(_ArrayBufferViewJs array) native;
}

class _CustomEventJs extends _EventJs implements CustomEvent native "*CustomEvent" {

  final Object detail;

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) native;
}

class _DOMApplicationCacheJs extends _DOMTypeJs implements DOMApplicationCache native "*DOMApplicationCache" {

  static final int CHECKING = 2;

  static final int DOWNLOADING = 3;

  static final int IDLE = 1;

  static final int OBSOLETE = 5;

  static final int UNCACHED = 0;

  static final int UPDATEREADY = 4;

  final int status;

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void swapCache() native;

  void update() native;
}

class _DOMExceptionJs extends _DOMTypeJs implements DOMException native "*DOMException" {

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

class _DOMFileSystemJs extends _DOMTypeJs implements DOMFileSystem native "*DOMFileSystem" {

  final String name;

  final _DirectoryEntryJs root;
}

class _DOMFileSystemSyncJs extends _DOMTypeJs implements DOMFileSystemSync native "*DOMFileSystemSync" {

  final String name;

  final _DirectoryEntrySyncJs root;
}

class _DOMFormDataJs extends _DOMTypeJs implements DOMFormData native "*DOMFormData" {

  void append(String name, String value, String filename) native;
}

class _DOMImplementationJs extends _DOMTypeJs implements DOMImplementation native "*DOMImplementation" {

  _CSSStyleSheetJs createCSSStyleSheet(String title, String media) native;

  _DocumentJs createDocument(String namespaceURI, String qualifiedName, _DocumentTypeJs doctype) native;

  _DocumentTypeJs createDocumentType(String qualifiedName, String publicId, String systemId) native;

  _HTMLDocumentJs createHTMLDocument(String title) native;

  bool hasFeature(String feature, String version) native;
}

class _DOMMimeTypeJs extends _DOMTypeJs implements DOMMimeType native "*DOMMimeType" {

  final String description;

  final _DOMPluginJs enabledPlugin;

  final String suffixes;

  final String type;
}

class _DOMMimeTypeArrayJs extends _DOMTypeJs implements DOMMimeTypeArray native "*DOMMimeTypeArray" {

  final int length;

  _DOMMimeTypeJs item(int index) native;

  _DOMMimeTypeJs namedItem(String name) native;
}

class _DOMParserJs extends _DOMTypeJs implements DOMParser native "*DOMParser" {
  DOMParser() native;

  _DocumentJs parseFromString(String str, String contentType) native;
}

class _DOMPluginJs extends _DOMTypeJs implements DOMPlugin native "*DOMPlugin" {

  final String description;

  final String filename;

  final int length;

  final String name;

  _DOMMimeTypeJs item(int index) native;

  _DOMMimeTypeJs namedItem(String name) native;
}

class _DOMPluginArrayJs extends _DOMTypeJs implements DOMPluginArray native "*DOMPluginArray" {

  final int length;

  _DOMPluginJs item(int index) native;

  _DOMPluginJs namedItem(String name) native;

  void refresh(bool reload) native;
}

class _DOMSelectionJs extends _DOMTypeJs implements DOMSelection native "*DOMSelection" {

  final _NodeJs anchorNode;

  final int anchorOffset;

  final _NodeJs baseNode;

  final int baseOffset;

  final _NodeJs extentNode;

  final int extentOffset;

  final _NodeJs focusNode;

  final int focusOffset;

  final bool isCollapsed;

  final int rangeCount;

  final String type;

  void addRange(_RangeJs range) native;

  void collapse(_NodeJs node, int index) native;

  void collapseToEnd() native;

  void collapseToStart() native;

  bool containsNode(_NodeJs node, bool allowPartial) native;

  void deleteFromDocument() native;

  void empty() native;

  void extend(_NodeJs node, int offset) native;

  _RangeJs getRangeAt(int index) native;

  void modify(String alter, String direction, String granularity) native;

  void removeAllRanges() native;

  void selectAllChildren(_NodeJs node) native;

  void setBaseAndExtent(_NodeJs baseNode, int baseOffset, _NodeJs extentNode, int extentOffset) native;

  void setPosition(_NodeJs node, int offset) native;

  String toString() native;
}

class _DOMSettableTokenListJs extends _DOMTokenListJs implements DOMSettableTokenList native "*DOMSettableTokenList" {

  String value;
}

class _DOMTokenListJs extends _DOMTypeJs implements DOMTokenList native "*DOMTokenList" {

  final int length;

  void add(String token) native;

  bool contains(String token) native;

  String item(int index) native;

  void remove(String token) native;

  String toString() native;

  bool toggle(String token) native;
}

class _DOMURLJs extends _DOMTypeJs implements DOMURL native "*DOMURL" {

  String createObjectURL(_BlobJs blob) native;

  void revokeObjectURL(String url) native;
}

class _DOMWindowJs extends _DOMTypeJs implements DOMWindow native "@*DOMWindow" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final _DOMApplicationCacheJs applicationCache;

  _NavigatorJs clientInformation;

  final bool closed;

  _ConsoleJs console;

  final _CryptoJs crypto;

  String defaultStatus;

  String defaultstatus;

  num devicePixelRatio;

  final _DocumentJs document;

  _EventJs event;

  final _ElementJs frameElement;

  _DOMWindowJs frames;

  _HistoryJs history;

  int innerHeight;

  int innerWidth;

  int length;

  final _StorageJs localStorage;

  _LocationJs location;

  _BarInfoJs locationbar;

  _BarInfoJs menubar;

  String name;

  _NavigatorJs navigator;

  bool offscreenBuffering;

  _DOMWindowJs opener;

  int outerHeight;

  int outerWidth;

  final int pageXOffset;

  final int pageYOffset;

  _DOMWindowJs parent;

  _PerformanceJs performance;

  _BarInfoJs personalbar;

  _ScreenJs screen;

  int screenLeft;

  int screenTop;

  int screenX;

  int screenY;

  int scrollX;

  int scrollY;

  _BarInfoJs scrollbars;

  _DOMWindowJs self;

  final _StorageJs sessionStorage;

  String status;

  _BarInfoJs statusbar;

  final _StyleMediaJs styleMedia;

  _BarInfoJs toolbar;

  _DOMWindowJs top;

  final _IDBFactoryJs webkitIndexedDB;

  final _NotificationCenterJs webkitNotifications;

  final _StorageInfoJs webkitStorageInfo;

  final _DOMURLJs webkitURL;

  final _DOMWindowJs window;

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

  bool dispatchEvent(_EventJs evt) native;

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  void focus() native;

  _CSSStyleDeclarationJs getComputedStyle(_ElementJs element, String pseudoElement) native;

  _CSSRuleListJs getMatchedCSSRules(_ElementJs element, String pseudoElement) native;

  _DOMSelectionJs getSelection() native;

  _MediaQueryListJs matchMedia(String query) native;

  void moveBy(num x, num y) native;

  void moveTo(num x, num y) native;

  _DOMWindowJs open(String url, String name, [String options = null]) native;

  _DatabaseJs openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void postMessage(Dynamic message, String targetOrigin, [List messagePorts = null]) native;

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

  _WebKitPointJs webkitConvertPointFromNodeToPage(_NodeJs node, _WebKitPointJs p) native;

  _WebKitPointJs webkitConvertPointFromPageToNode(_NodeJs node, _WebKitPointJs p) native;

  void webkitPostMessage(Dynamic message, String targetOrigin, [List transferList = null]) native;

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, _ElementJs element) native;

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;
}

class _DataTransferItemJs extends _DOMTypeJs implements DataTransferItem native "*DataTransferItem" {

  final String kind;

  final String type;

  _BlobJs getAsFile() native;

  void getAsString(StringCallback callback) native;
}

class _DataTransferItemListJs extends _DOMTypeJs implements DataTransferItemList native "*DataTransferItemList" {

  final int length;

  void add(var data_OR_file, [String type = null]) native;

  void clear() native;

  _DataTransferItemJs item(int index) native;
}

class _DataViewJs extends _ArrayBufferViewJs implements DataView native "*DataView" {

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

class _DatabaseJs extends _DOMTypeJs implements Database native "*Database" {

  final String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback = null, SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;
}

class _DatabaseSyncJs extends _DOMTypeJs implements DatabaseSync native "*DatabaseSync" {

  final String lastErrorMessage;

  final String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback = null]) native;

  void readTransaction(SQLTransactionSyncCallback callback) native;

  void transaction(SQLTransactionSyncCallback callback) native;
}

class _DedicatedWorkerContextJs extends _WorkerContextJs implements DedicatedWorkerContext native "*DedicatedWorkerContext" {

  EventListener onmessage;

  void postMessage(Object message, [List messagePorts = null]) native;

  void webkitPostMessage(Object message, [List transferList = null]) native;
}

class _DelayNodeJs extends _AudioNodeJs implements DelayNode native "*DelayNode" {

  final _AudioParamJs delayTime;
}

class _DeviceMotionEventJs extends _EventJs implements DeviceMotionEvent native "*DeviceMotionEvent" {

  final num interval;
}

class _DeviceOrientationEventJs extends _EventJs implements DeviceOrientationEvent native "*DeviceOrientationEvent" {

  final bool absolute;

  final num alpha;

  final num beta;

  final num gamma;

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute) native;
}

class _DirectoryEntryJs extends _EntryJs implements DirectoryEntry native "*DirectoryEntry" {

  _DirectoryReaderJs createReader() native;

  void getDirectory(String path, [Object flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getFile(String path, [Object flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback = null]) native;
}

class _DirectoryEntrySyncJs extends _EntrySyncJs implements DirectoryEntrySync native "*DirectoryEntrySync" {

  _DirectoryReaderSyncJs createReader() native;

  _DirectoryEntrySyncJs getDirectory(String path, Object flags) native;

  _FileEntrySyncJs getFile(String path, Object flags) native;

  void removeRecursively() native;
}

class _DirectoryReaderJs extends _DOMTypeJs implements DirectoryReader native "*DirectoryReader" {

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback = null]) native;
}

class _DirectoryReaderSyncJs extends _DOMTypeJs implements DirectoryReaderSync native "*DirectoryReaderSync" {

  _EntryArraySyncJs readEntries() native;
}

class _DocumentJs extends _NodeJs implements Document native "*Document" {

  final String URL;

  final _HTMLCollectionJs anchors;

  final _HTMLCollectionJs applets;

  _HTMLElementJs body;

  final String characterSet;

  String charset;

  final String compatMode;

  String cookie;

  final String defaultCharset;

  final _DOMWindowJs defaultView;

  final _DocumentTypeJs doctype;

  final _ElementJs documentElement;

  String documentURI;

  String domain;

  final _HTMLCollectionJs forms;

  final _HTMLHeadElementJs head;

  final _HTMLCollectionJs images;

  final _DOMImplementationJs implementation;

  final String inputEncoding;

  final String lastModified;

  final _HTMLCollectionJs links;

  _LocationJs location;

  final String preferredStylesheetSet;

  final String readyState;

  final String referrer;

  String selectedStylesheetSet;

  final _StyleSheetListJs styleSheets;

  String title;

  final _ElementJs webkitCurrentFullScreenElement;

  final bool webkitFullScreenKeyboardInputAllowed;

  final bool webkitHidden;

  final bool webkitIsFullScreen;

  final String webkitVisibilityState;

  final String xmlEncoding;

  bool xmlStandalone;

  String xmlVersion;

  _NodeJs adoptNode(_NodeJs source) native;

  _RangeJs caretRangeFromPoint(int x, int y) native;

  _AttrJs createAttribute(String name) native;

  _AttrJs createAttributeNS(String namespaceURI, String qualifiedName) native;

  _CDATASectionJs createCDATASection(String data) native;

  _CommentJs createComment(String data) native;

  _DocumentFragmentJs createDocumentFragment() native;

  _ElementJs createElement(String tagName) native;

  _ElementJs createElementNS(String namespaceURI, String qualifiedName) native;

  _EntityReferenceJs createEntityReference(String name) native;

  _EventJs createEvent(String eventType) native;

  _XPathExpressionJs createExpression(String expression, _XPathNSResolverJs resolver) native;

  _XPathNSResolverJs createNSResolver(_NodeJs nodeResolver) native;

  _NodeIteratorJs createNodeIterator(_NodeJs root, int whatToShow, _NodeFilterJs filter, bool expandEntityReferences) native;

  _ProcessingInstructionJs createProcessingInstruction(String target, String data) native;

  _RangeJs createRange() native;

  _TextJs createTextNode(String data) native;

  _TouchJs createTouch(_DOMWindowJs window, _EventTargetJs target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) native;

  _TouchListJs createTouchList() native;

  _TreeWalkerJs createTreeWalker(_NodeJs root, int whatToShow, _NodeFilterJs filter, bool expandEntityReferences) native;

  _ElementJs elementFromPoint(int x, int y) native;

  _XPathResultJs evaluate(String expression, _NodeJs contextNode, _XPathNSResolverJs resolver, int type, _XPathResultJs inResult) native;

  bool execCommand(String command, bool userInterface, String value) native;

  Object getCSSCanvasContext(String contextId, String name, int width, int height) native;

  _ElementJs getElementById(String elementId) native;

  _NodeListJs getElementsByClassName(String tagname) native;

  _NodeListJs getElementsByName(String elementName) native;

  _NodeListJs getElementsByTagName(String tagname) native;

  _NodeListJs getElementsByTagNameNS(String namespaceURI, String localName) native;

  _CSSStyleDeclarationJs getOverrideStyle(_ElementJs element, String pseudoElement) native;

  _DOMSelectionJs getSelection() native;

  _NodeJs importNode(_NodeJs importedNode, [bool deep = null]) native;

  bool queryCommandEnabled(String command) native;

  bool queryCommandIndeterm(String command) native;

  bool queryCommandState(String command) native;

  bool queryCommandSupported(String command) native;

  String queryCommandValue(String command) native;

  _ElementJs querySelector(String selectors) native;

  _NodeListJs querySelectorAll(String selectors) native;

  void webkitCancelFullScreen() native;

  _WebKitNamedFlowJs webkitGetFlowByName(String name) native;
}

class _DocumentFragmentJs extends _NodeJs implements DocumentFragment native "*DocumentFragment" {

  _ElementJs querySelector(String selectors) native;

  _NodeListJs querySelectorAll(String selectors) native;
}

class _DocumentTypeJs extends _NodeJs implements DocumentType native "*DocumentType" {

  final _NamedNodeMapJs entities;

  final String internalSubset;

  final String name;

  final _NamedNodeMapJs notations;

  final String publicId;

  final String systemId;
}

class _DynamicsCompressorNodeJs extends _AudioNodeJs implements DynamicsCompressorNode native "*DynamicsCompressorNode" {
}

class _ElementJs extends _NodeJs implements Element native "*Element" {

  static final int ALLOW_KEYBOARD_INPUT = 1;

  final int childElementCount;

  final int clientHeight;

  final int clientLeft;

  final int clientTop;

  final int clientWidth;

  final _ElementJs firstElementChild;

  final _ElementJs lastElementChild;

  final _ElementJs nextElementSibling;

  final int offsetHeight;

  final int offsetLeft;

  final _ElementJs offsetParent;

  final int offsetTop;

  final int offsetWidth;

  final _ElementJs previousElementSibling;

  final int scrollHeight;

  int scrollLeft;

  int scrollTop;

  final int scrollWidth;

  final _CSSStyleDeclarationJs style;

  final String tagName;

  void blur() native;

  void focus() native;

  String getAttribute(String name) native;

  String getAttributeNS(String namespaceURI, String localName) native;

  _AttrJs getAttributeNode(String name) native;

  _AttrJs getAttributeNodeNS(String namespaceURI, String localName) native;

  _ClientRectJs getBoundingClientRect() native;

  _ClientRectListJs getClientRects() native;

  _NodeListJs getElementsByClassName(String name) native;

  _NodeListJs getElementsByTagName(String name) native;

  _NodeListJs getElementsByTagNameNS(String namespaceURI, String localName) native;

  bool hasAttribute(String name) native;

  bool hasAttributeNS(String namespaceURI, String localName) native;

  _ElementJs querySelector(String selectors) native;

  _NodeListJs querySelectorAll(String selectors) native;

  void removeAttribute(String name) native;

  void removeAttributeNS(String namespaceURI, String localName) native;

  _AttrJs removeAttributeNode(_AttrJs oldAttr) native;

  void scrollByLines(int lines) native;

  void scrollByPages(int pages) native;

  void scrollIntoView([bool alignWithTop = null]) native;

  void scrollIntoViewIfNeeded([bool centerIfNeeded = null]) native;

  void setAttribute(String name, String value) native;

  void setAttributeNS(String namespaceURI, String qualifiedName, String value) native;

  _AttrJs setAttributeNode(_AttrJs newAttr) native;

  _AttrJs setAttributeNodeNS(_AttrJs newAttr) native;

  bool webkitMatchesSelector(String selectors) native;

  void webkitRequestFullScreen(int flags) native;
}

class _ElementTimeControlJs extends _DOMTypeJs implements ElementTimeControl native "*ElementTimeControl" {

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;
}

class _ElementTraversalJs extends _DOMTypeJs implements ElementTraversal native "*ElementTraversal" {

  final int childElementCount;

  final _ElementJs firstElementChild;

  final _ElementJs lastElementChild;

  final _ElementJs nextElementSibling;

  final _ElementJs previousElementSibling;
}

class _EntityJs extends _NodeJs implements Entity native "*Entity" {

  final String notationName;

  final String publicId;

  final String systemId;
}

class _EntityReferenceJs extends _NodeJs implements EntityReference native "*EntityReference" {
}

class _EntryJs extends _DOMTypeJs implements Entry native "*Entry" {

  final _DOMFileSystemJs filesystem;

  final String fullPath;

  final bool isDirectory;

  final bool isFile;

  final String name;

  void copyTo(_DirectoryEntryJs parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void getParent([EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void moveTo(_DirectoryEntryJs parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void remove(VoidCallback successCallback, [ErrorCallback errorCallback = null]) native;

  String toURL() native;
}

class _EntryArrayJs extends _DOMTypeJs implements EntryArray native "*EntryArray" {

  final int length;

  _EntryJs item(int index) native;
}

class _EntryArraySyncJs extends _DOMTypeJs implements EntryArraySync native "*EntryArraySync" {

  final int length;

  _EntrySyncJs item(int index) native;
}

class _EntrySyncJs extends _DOMTypeJs implements EntrySync native "*EntrySync" {

  final _DOMFileSystemSyncJs filesystem;

  final String fullPath;

  final bool isDirectory;

  final bool isFile;

  final String name;

  _EntrySyncJs copyTo(_DirectoryEntrySyncJs parent, String name) native;

  _MetadataJs getMetadata() native;

  _DirectoryEntrySyncJs getParent() native;

  _EntrySyncJs moveTo(_DirectoryEntrySyncJs parent, String name) native;

  void remove() native;

  String toURL() native;
}

class _ErrorEventJs extends _EventJs implements ErrorEvent native "*ErrorEvent" {

  final String filename;

  final int lineno;

  final String message;
}

class _EventJs extends _DOMTypeJs implements Event native "*Event" {

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

  final _ClipboardJs clipboardData;

  final _EventTargetJs currentTarget;

  final bool defaultPrevented;

  final int eventPhase;

  bool returnValue;

  final _EventTargetJs srcElement;

  final _EventTargetJs target;

  final int timeStamp;

  final String type;

  void initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) native;

  void preventDefault() native;

  void stopImmediatePropagation() native;

  void stopPropagation() native;
}

class _EventExceptionJs extends _DOMTypeJs implements EventException native "*EventException" {

  static final int DISPATCH_REQUEST_ERR = 1;

  static final int UNSPECIFIED_EVENT_TYPE_ERR = 0;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _EventSourceJs extends _DOMTypeJs implements EventSource native "*EventSource" {

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  final String URL;

  final int readyState;

  final String url;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _EventTargetJs extends _DOMTypeJs implements EventTarget native "*EventTarget" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _FileJs extends _BlobJs implements File native "*File" {

  final String fileName;

  final int fileSize;

  final Date lastModifiedDate;

  final String name;

  final String webkitRelativePath;
}

class _FileEntryJs extends _EntryJs implements FileEntry native "*FileEntry" {

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void file(FileCallback successCallback, [ErrorCallback errorCallback = null]) native;
}

class _FileEntrySyncJs extends _EntrySyncJs implements FileEntrySync native "*FileEntrySync" {

  _FileWriterSyncJs createWriter() native;

  _FileJs file() native;
}

class _FileErrorJs extends _DOMTypeJs implements FileError native "*FileError" {

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

class _FileExceptionJs extends _DOMTypeJs implements FileException native "*FileException" {

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

class _FileListJs extends _DOMTypeJs implements FileList native "*FileList" {

  final int length;

  _FileJs item(int index) native;
}

class _FileReaderJs extends _DOMTypeJs implements FileReader native "*FileReader" {
  FileReader() native;


  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  final _FileErrorJs error;

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

  bool dispatchEvent(_EventJs evt) native;

  void readAsArrayBuffer(_BlobJs blob) native;

  void readAsBinaryString(_BlobJs blob) native;

  void readAsDataURL(_BlobJs blob) native;

  void readAsText(_BlobJs blob, [String encoding = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _FileReaderSyncJs extends _DOMTypeJs implements FileReaderSync native "*FileReaderSync" {

  _ArrayBufferJs readAsArrayBuffer(_BlobJs blob) native;

  String readAsBinaryString(_BlobJs blob) native;

  String readAsDataURL(_BlobJs blob) native;

  String readAsText(_BlobJs blob, [String encoding = null]) native;
}

class _FileWriterJs extends _DOMTypeJs implements FileWriter native "*FileWriter" {

  static final int DONE = 2;

  static final int INIT = 0;

  static final int WRITING = 1;

  final _FileErrorJs error;

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

  void write(_BlobJs data) native;
}

class _FileWriterSyncJs extends _DOMTypeJs implements FileWriterSync native "*FileWriterSync" {

  final int length;

  final int position;

  void seek(int position) native;

  void truncate(int size) native;

  void write(_BlobJs data) native;
}

class _Float32ArrayJs extends _ArrayBufferViewJs implements Float32Array, List<num> native "*Float32Array" {

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

  _Float32ArrayJs subarray(int start, [int end = null]) native;
}

class _Float64ArrayJs extends _ArrayBufferViewJs implements Float64Array, List<num> native "*Float64Array" {

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

  _Float64ArrayJs subarray(int start, [int end = null]) native;
}

class _GeolocationJs extends _DOMTypeJs implements Geolocation native "*Geolocation" {

  void clearWatch(int watchId) native;

  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) native;

  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) native;
}

class _GeopositionJs extends _DOMTypeJs implements Geoposition native "*Geoposition" {

  final _CoordinatesJs coords;

  final int timestamp;
}

class _HTMLAllCollectionJs extends _DOMTypeJs implements HTMLAllCollection native "*HTMLAllCollection" {

  final int length;

  _NodeJs item(int index) native;

  _NodeJs namedItem(String name) native;

  _NodeListJs tags(String name) native;
}

class _HTMLAnchorElementJs extends _HTMLElementJs implements HTMLAnchorElement native "*HTMLAnchorElement" {

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

  final String text;

  String type;

  String toString() native;
}

class _HTMLAppletElementJs extends _HTMLElementJs implements HTMLAppletElement native "*HTMLAppletElement" {

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

class _HTMLAreaElementJs extends _HTMLElementJs implements HTMLAreaElement native "*HTMLAreaElement" {

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

class _HTMLAudioElementJs extends _HTMLMediaElementJs implements HTMLAudioElement native "*HTMLAudioElement" {
}

class _HTMLBRElementJs extends _HTMLElementJs implements HTMLBRElement native "*HTMLBRElement" {

  String clear;
}

class _HTMLBaseElementJs extends _HTMLElementJs implements HTMLBaseElement native "*HTMLBaseElement" {

  String href;

  String target;
}

class _HTMLBaseFontElementJs extends _HTMLElementJs implements HTMLBaseFontElement native "*HTMLBaseFontElement" {

  String color;

  String face;

  int size;
}

class _HTMLBodyElementJs extends _HTMLElementJs implements HTMLBodyElement native "*HTMLBodyElement" {

  String aLink;

  String background;

  String bgColor;

  String link;

  String text;

  String vLink;
}

class _HTMLButtonElementJs extends _HTMLElementJs implements HTMLButtonElement native "*HTMLButtonElement" {

  bool autofocus;

  bool disabled;

  final _HTMLFormElementJs form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  final _NodeListJs labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateJs validity;

  String value;

  final bool willValidate;

  bool checkValidity() native;

  void click() native;

  void setCustomValidity(String error) native;
}

class _HTMLCanvasElementJs extends _HTMLElementJs implements HTMLCanvasElement native "*HTMLCanvasElement" {

  int height;

  int width;

  Object getContext(String contextId) native;

  String toDataURL(String type) native;
}

class _HTMLCollectionJs extends _DOMTypeJs implements HTMLCollection native "*HTMLCollection" {

  final int length;

  _NodeJs operator[](int index) native "return this[index];";

  void operator[]=(int index, _NodeJs value) {
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

  _NodeJs item(int index) native;

  _NodeJs namedItem(String name) native;
}

class _HTMLContentElementJs extends _HTMLElementJs implements HTMLContentElement native "*HTMLContentElement" {

  String select;
}

class _HTMLDListElementJs extends _HTMLElementJs implements HTMLDListElement native "*HTMLDListElement" {

  bool compact;
}

class _HTMLDataListElementJs extends _HTMLElementJs implements HTMLDataListElement native "*HTMLDataListElement" {

  final _HTMLCollectionJs options;
}

class _HTMLDetailsElementJs extends _HTMLElementJs implements HTMLDetailsElement native "*HTMLDetailsElement" {

  bool open;
}

class _HTMLDirectoryElementJs extends _HTMLElementJs implements HTMLDirectoryElement native "*HTMLDirectoryElement" {

  bool compact;
}

class _HTMLDivElementJs extends _HTMLElementJs implements HTMLDivElement native "*HTMLDivElement" {

  String align;
}

class _HTMLDocumentJs extends _DocumentJs implements HTMLDocument native "*HTMLDocument" {

  final _ElementJs activeElement;

  String alinkColor;

  _HTMLAllCollectionJs all;

  String bgColor;

  final String compatMode;

  String designMode;

  String dir;

  final _HTMLCollectionJs embeds;

  String fgColor;

  String linkColor;

  final _HTMLCollectionJs plugins;

  final _HTMLCollectionJs scripts;

  String vlinkColor;

  void captureEvents() native;

  void clear() native;

  void close() native;

  bool hasFocus() native;

  void open() native;

  void releaseEvents() native;

  void write(String text) native;

  void writeln(String text) native;
}

class _HTMLElementJs extends _ElementJs implements HTMLElement native "*HTMLElement" {

  String accessKey;

  final _HTMLCollectionJs children;

  final _DOMTokenListJs classList;

  String className;

  String contentEditable;

  String dir;

  bool draggable;

  bool hidden;

  String id;

  String innerHTML;

  String innerText;

  final bool isContentEditable;

  String itemId;

  final _DOMSettableTokenListJs itemProp;

  final _DOMSettableTokenListJs itemRef;

  bool itemScope;

  final _DOMSettableTokenListJs itemType;

  Object itemValue;

  String lang;

  String outerHTML;

  String outerText;

  bool spellcheck;

  int tabIndex;

  String title;

  String webkitdropzone;

  _ElementJs insertAdjacentElement(String where, _ElementJs element) native;

  void insertAdjacentHTML(String where, String html) native;

  void insertAdjacentText(String where, String text) native;
}

class _HTMLEmbedElementJs extends _HTMLElementJs implements HTMLEmbedElement native "*HTMLEmbedElement" {

  String align;

  String height;

  String name;

  String src;

  String type;

  String width;

  _SVGDocumentJs getSVGDocument() native;
}

class _HTMLFieldSetElementJs extends _HTMLElementJs implements HTMLFieldSetElement native "*HTMLFieldSetElement" {

  final _HTMLFormElementJs form;

  final String validationMessage;

  final _ValidityStateJs validity;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class _HTMLFontElementJs extends _HTMLElementJs implements HTMLFontElement native "*HTMLFontElement" {

  String color;

  String face;

  String size;
}

class _HTMLFormElementJs extends _HTMLElementJs implements HTMLFormElement native "*HTMLFormElement" {

  String acceptCharset;

  String action;

  String autocomplete;

  final _HTMLCollectionJs elements;

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

class _HTMLFrameElementJs extends _HTMLElementJs implements HTMLFrameElement native "*HTMLFrameElement" {

  final _DocumentJs contentDocument;

  final _DOMWindowJs contentWindow;

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

  _SVGDocumentJs getSVGDocument() native;
}

class _HTMLFrameSetElementJs extends _HTMLElementJs implements HTMLFrameSetElement native "*HTMLFrameSetElement" {

  String cols;

  String rows;
}

class _HTMLHRElementJs extends _HTMLElementJs implements HTMLHRElement native "*HTMLHRElement" {

  String align;

  bool noShade;

  String size;

  String width;
}

class _HTMLHeadElementJs extends _HTMLElementJs implements HTMLHeadElement native "*HTMLHeadElement" {

  String profile;
}

class _HTMLHeadingElementJs extends _HTMLElementJs implements HTMLHeadingElement native "*HTMLHeadingElement" {

  String align;
}

class _HTMLHtmlElementJs extends _HTMLElementJs implements HTMLHtmlElement native "*HTMLHtmlElement" {

  String manifest;

  String version;
}

class _HTMLIFrameElementJs extends _HTMLElementJs implements HTMLIFrameElement native "*HTMLIFrameElement" {

  String align;

  final _DocumentJs contentDocument;

  final _DOMWindowJs contentWindow;

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

  _SVGDocumentJs getSVGDocument() native;
}

class _HTMLImageElementJs extends _HTMLElementJs implements HTMLImageElement native "*HTMLImageElement" {

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

class _HTMLInputElementJs extends _HTMLElementJs implements HTMLInputElement native "*HTMLInputElement" {

  String accept;

  String align;

  String alt;

  String autocomplete;

  bool autofocus;

  bool checked;

  bool defaultChecked;

  String defaultValue;

  String dirName;

  bool disabled;

  final _FileListJs files;

  final _HTMLFormElementJs form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  bool incremental;

  bool indeterminate;

  final _NodeListJs labels;

  final _HTMLElementJs list;

  String max;

  int maxLength;

  String min;

  bool multiple;

  String name;

  String pattern;

  String placeholder;

  bool readOnly;

  bool required;

  final _HTMLOptionElementJs selectedOption;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  int size;

  String src;

  String step;

  String type;

  String useMap;

  final String validationMessage;

  final _ValidityStateJs validity;

  String value;

  Date valueAsDate;

  num valueAsNumber;

  bool webkitGrammar;

  bool webkitSpeech;

  bool webkitdirectory;

  final bool willValidate;

  bool checkValidity() native;

  void click() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;

  void stepDown([int n = null]) native;

  void stepUp([int n = null]) native;
}

class _HTMLIsIndexElementJs extends _HTMLInputElementJs implements HTMLIsIndexElement native "*HTMLIsIndexElement" {

  final _HTMLFormElementJs form;

  String prompt;
}

class _HTMLKeygenElementJs extends _HTMLElementJs implements HTMLKeygenElement native "*HTMLKeygenElement" {

  bool autofocus;

  String challenge;

  bool disabled;

  final _HTMLFormElementJs form;

  String keytype;

  final _NodeListJs labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateJs validity;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class _HTMLLIElementJs extends _HTMLElementJs implements HTMLLIElement native "*HTMLLIElement" {

  String type;

  int value;
}

class _HTMLLabelElementJs extends _HTMLElementJs implements HTMLLabelElement native "*HTMLLabelElement" {

  final _HTMLElementJs control;

  final _HTMLFormElementJs form;

  String htmlFor;
}

class _HTMLLegendElementJs extends _HTMLElementJs implements HTMLLegendElement native "*HTMLLegendElement" {

  String align;

  final _HTMLFormElementJs form;
}

class _HTMLLinkElementJs extends _HTMLElementJs implements HTMLLinkElement native "*HTMLLinkElement" {

  String charset;

  bool disabled;

  String href;

  String hreflang;

  String media;

  String rel;

  String rev;

  final _StyleSheetJs sheet;

  _DOMSettableTokenListJs sizes;

  String target;

  String type;
}

class _HTMLMapElementJs extends _HTMLElementJs implements HTMLMapElement native "*HTMLMapElement" {

  final _HTMLCollectionJs areas;

  String name;
}

class _HTMLMarqueeElementJs extends _HTMLElementJs implements HTMLMarqueeElement native "*HTMLMarqueeElement" {

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

class _HTMLMediaElementJs extends _HTMLElementJs implements HTMLMediaElement native "*HTMLMediaElement" {

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

  final _TimeRangesJs buffered;

  _MediaControllerJs controller;

  bool controls;

  final String currentSrc;

  num currentTime;

  bool defaultMuted;

  num defaultPlaybackRate;

  final num duration;

  final bool ended;

  final _MediaErrorJs error;

  final num initialTime;

  bool loop;

  String mediaGroup;

  bool muted;

  final int networkState;

  final bool paused;

  num playbackRate;

  final _TimeRangesJs played;

  String preload;

  final int readyState;

  final _TimeRangesJs seekable;

  final bool seeking;

  String src;

  final num startTime;

  final _TextTrackListJs textTracks;

  num volume;

  final int webkitAudioDecodedByteCount;

  bool webkitClosedCaptionsVisible;

  final bool webkitHasClosedCaptions;

  final String webkitMediaSourceURL;

  bool webkitPreservesPitch;

  final int webkitSourceState;

  final int webkitVideoDecodedByteCount;

  _TextTrackJs addTrack(String kind, [String label = null, String language = null]) native;

  String canPlayType(String type) native;

  void load() native;

  void pause() native;

  void play() native;

  void webkitSourceAppend(_Uint8ArrayJs data) native;

  void webkitSourceEndOfStream(int status) native;
}

class _HTMLMenuElementJs extends _HTMLElementJs implements HTMLMenuElement native "*HTMLMenuElement" {

  bool compact;
}

class _HTMLMetaElementJs extends _HTMLElementJs implements HTMLMetaElement native "*HTMLMetaElement" {

  String content;

  String httpEquiv;

  String name;

  String scheme;
}

class _HTMLMeterElementJs extends _HTMLElementJs implements HTMLMeterElement native "*HTMLMeterElement" {

  final _HTMLFormElementJs form;

  num high;

  final _NodeListJs labels;

  num low;

  num max;

  num min;

  num optimum;

  num value;
}

class _HTMLModElementJs extends _HTMLElementJs implements HTMLModElement native "*HTMLModElement" {

  String cite;

  String dateTime;
}

class _HTMLOListElementJs extends _HTMLElementJs implements HTMLOListElement native "*HTMLOListElement" {

  bool compact;

  bool reversed;

  int start;

  String type;
}

class _HTMLObjectElementJs extends _HTMLElementJs implements HTMLObjectElement native "*HTMLObjectElement" {

  String align;

  String archive;

  String border;

  String code;

  String codeBase;

  String codeType;

  final _DocumentJs contentDocument;

  String data;

  bool declare;

  final _HTMLFormElementJs form;

  String height;

  int hspace;

  String name;

  String standby;

  String type;

  String useMap;

  final String validationMessage;

  final _ValidityStateJs validity;

  int vspace;

  String width;

  final bool willValidate;

  bool checkValidity() native;

  _SVGDocumentJs getSVGDocument() native;

  void setCustomValidity(String error) native;
}

class _HTMLOptGroupElementJs extends _HTMLElementJs implements HTMLOptGroupElement native "*HTMLOptGroupElement" {

  bool disabled;

  String label;
}

class _HTMLOptionElementJs extends _HTMLElementJs implements HTMLOptionElement native "*HTMLOptionElement" {

  bool defaultSelected;

  bool disabled;

  final _HTMLFormElementJs form;

  final int index;

  String label;

  bool selected;

  String text;

  String value;
}

class _HTMLOptionsCollectionJs extends _HTMLCollectionJs implements HTMLOptionsCollection native "*HTMLOptionsCollection" {

  int length;

  int selectedIndex;

  void remove(int index) native;
}

class _HTMLOutputElementJs extends _HTMLElementJs implements HTMLOutputElement native "*HTMLOutputElement" {

  String defaultValue;

  final _HTMLFormElementJs form;

  _DOMSettableTokenListJs htmlFor;

  final _NodeListJs labels;

  String name;

  final String type;

  final String validationMessage;

  final _ValidityStateJs validity;

  String value;

  final bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class _HTMLParagraphElementJs extends _HTMLElementJs implements HTMLParagraphElement native "*HTMLParagraphElement" {

  String align;
}

class _HTMLParamElementJs extends _HTMLElementJs implements HTMLParamElement native "*HTMLParamElement" {

  String name;

  String type;

  String value;

  String valueType;
}

class _HTMLPreElementJs extends _HTMLElementJs implements HTMLPreElement native "*HTMLPreElement" {

  int width;

  bool wrap;
}

class _HTMLProgressElementJs extends _HTMLElementJs implements HTMLProgressElement native "*HTMLProgressElement" {

  final _HTMLFormElementJs form;

  final _NodeListJs labels;

  num max;

  final num position;

  num value;
}

class _HTMLPropertiesCollectionJs extends _HTMLCollectionJs implements HTMLPropertiesCollection native "*HTMLPropertiesCollection" {

  final int length;

  _NodeJs item(int index) native;
}

class _HTMLQuoteElementJs extends _HTMLElementJs implements HTMLQuoteElement native "*HTMLQuoteElement" {

  String cite;
}

class _HTMLScriptElementJs extends _HTMLElementJs implements HTMLScriptElement native "*HTMLScriptElement" {

  bool async;

  String charset;

  bool defer;

  String event;

  String htmlFor;

  String src;

  String text;

  String type;
}

class _HTMLSelectElementJs extends _HTMLElementJs implements HTMLSelectElement native "*HTMLSelectElement" {

  bool autofocus;

  bool disabled;

  final _HTMLFormElementJs form;

  final _NodeListJs labels;

  int length;

  bool multiple;

  String name;

  final _HTMLOptionsCollectionJs options;

  bool required;

  int selectedIndex;

  int size;

  final String type;

  final String validationMessage;

  final _ValidityStateJs validity;

  String value;

  final bool willValidate;

  void add(_HTMLElementJs element, _HTMLElementJs before) native;

  bool checkValidity() native;

  _NodeJs item(int index) native;

  _NodeJs namedItem(String name) native;

  void remove(var index_OR_option) native;

  void setCustomValidity(String error) native;
}

class _HTMLSourceElementJs extends _HTMLElementJs implements HTMLSourceElement native "*HTMLSourceElement" {

  String media;

  String src;

  String type;
}

class _HTMLSpanElementJs extends _HTMLElementJs implements HTMLSpanElement native "*HTMLSpanElement" {
}

class _HTMLStyleElementJs extends _HTMLElementJs implements HTMLStyleElement native "*HTMLStyleElement" {

  bool disabled;

  String media;

  bool scoped;

  final _StyleSheetJs sheet;

  String type;
}

class _HTMLTableCaptionElementJs extends _HTMLElementJs implements HTMLTableCaptionElement native "*HTMLTableCaptionElement" {

  String align;
}

class _HTMLTableCellElementJs extends _HTMLElementJs implements HTMLTableCellElement native "*HTMLTableCellElement" {

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

class _HTMLTableColElementJs extends _HTMLElementJs implements HTMLTableColElement native "*HTMLTableColElement" {

  String align;

  String ch;

  String chOff;

  int span;

  String vAlign;

  String width;
}

class _HTMLTableElementJs extends _HTMLElementJs implements HTMLTableElement native "*HTMLTableElement" {

  String align;

  String bgColor;

  String border;

  _HTMLTableCaptionElementJs caption;

  String cellPadding;

  String cellSpacing;

  String frame;

  final _HTMLCollectionJs rows;

  String rules;

  String summary;

  final _HTMLCollectionJs tBodies;

  _HTMLTableSectionElementJs tFoot;

  _HTMLTableSectionElementJs tHead;

  String width;

  _HTMLElementJs createCaption() native;

  _HTMLElementJs createTFoot() native;

  _HTMLElementJs createTHead() native;

  void deleteCaption() native;

  void deleteRow(int index) native;

  void deleteTFoot() native;

  void deleteTHead() native;

  _HTMLElementJs insertRow(int index) native;
}

class _HTMLTableRowElementJs extends _HTMLElementJs implements HTMLTableRowElement native "*HTMLTableRowElement" {

  String align;

  String bgColor;

  final _HTMLCollectionJs cells;

  String ch;

  String chOff;

  final int rowIndex;

  final int sectionRowIndex;

  String vAlign;

  void deleteCell(int index) native;

  _HTMLElementJs insertCell(int index) native;
}

class _HTMLTableSectionElementJs extends _HTMLElementJs implements HTMLTableSectionElement native "*HTMLTableSectionElement" {

  String align;

  String ch;

  String chOff;

  final _HTMLCollectionJs rows;

  String vAlign;

  void deleteRow(int index) native;

  _HTMLElementJs insertRow(int index) native;
}

class _HTMLTextAreaElementJs extends _HTMLElementJs implements HTMLTextAreaElement native "*HTMLTextAreaElement" {

  bool autofocus;

  int cols;

  String defaultValue;

  String dirName;

  bool disabled;

  final _HTMLFormElementJs form;

  final _NodeListJs labels;

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

  final _ValidityStateJs validity;

  String value;

  final bool willValidate;

  String wrap;

  bool checkValidity() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;
}

class _HTMLTitleElementJs extends _HTMLElementJs implements HTMLTitleElement native "*HTMLTitleElement" {

  String text;
}

class _HTMLTrackElementJs extends _HTMLElementJs implements HTMLTrackElement native "*HTMLTrackElement" {

  static final int ERROR = 3;

  static final int LOADED = 2;

  static final int LOADING = 1;

  static final int NONE = 0;

  bool isDefault;

  String kind;

  String label;

  final int readyState;

  String src;

  String srclang;

  final _TextTrackJs track;
}

class _HTMLUListElementJs extends _HTMLElementJs implements HTMLUListElement native "*HTMLUListElement" {

  bool compact;

  String type;
}

class _HTMLUnknownElementJs extends _HTMLElementJs implements HTMLUnknownElement native "*HTMLUnknownElement" {
}

class _HTMLVideoElementJs extends _HTMLMediaElementJs implements HTMLVideoElement native "*HTMLVideoElement" {

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

class _HashChangeEventJs extends _EventJs implements HashChangeEvent native "*HashChangeEvent" {

  final String newURL;

  final String oldURL;

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native;
}

class _HighPass2FilterNodeJs extends _AudioNodeJs implements HighPass2FilterNode native "*HighPass2FilterNode" {

  final _AudioParamJs cutoff;

  final _AudioParamJs resonance;
}

class _HistoryJs extends _DOMTypeJs implements History native "*History" {

  final int length;

  void back() native;

  void forward() native;

  void go(int distance) native;

  void pushState(Object data, String title, [String url = null]) native;

  void replaceState(Object data, String title, [String url = null]) native;
}

class _IDBAnyJs extends _DOMTypeJs implements IDBAny native "*IDBAny" {
}

class _IDBCursorJs extends _DOMTypeJs implements IDBCursor native "*IDBCursor" {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

  final int direction;

  final _IDBKeyJs key;

  final _IDBKeyJs primaryKey;

  final _IDBAnyJs source;

  void continueFunction([_IDBKeyJs key = null]) native;

  _IDBRequestJs delete() native;

  _IDBRequestJs update(Dynamic value) native;
}

class _IDBCursorWithValueJs extends _IDBCursorJs implements IDBCursorWithValue native "*IDBCursorWithValue" {

  final _IDBAnyJs value;
}

class _IDBDatabaseJs extends _DOMTypeJs implements IDBDatabase native "*IDBDatabase" {

  final String name;

  EventListener onabort;

  EventListener onerror;

  EventListener onversionchange;

  final String version;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  _IDBObjectStoreJs createObjectStore(String name) native;

  void deleteObjectStore(String name) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  _IDBVersionChangeRequestJs setVersion(String version) native;

  _IDBTransactionJs transaction(String storeName, int mode) native;
}

class _IDBDatabaseErrorJs extends _DOMTypeJs implements IDBDatabaseError native "*IDBDatabaseError" {

  int code;

  String message;
}

class _IDBDatabaseExceptionJs extends _DOMTypeJs implements IDBDatabaseException native "*IDBDatabaseException" {

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

class _IDBFactoryJs extends _DOMTypeJs implements IDBFactory native "*IDBFactory" {

  int cmp(_IDBKeyJs first, _IDBKeyJs second) native;

  _IDBVersionChangeRequestJs deleteDatabase(String name) native;

  _IDBRequestJs getDatabaseNames() native;

  _IDBRequestJs open(String name) native;
}

class _IDBIndexJs extends _DOMTypeJs implements IDBIndex native "*IDBIndex" {

  final String keyPath;

  final bool multiEntry;

  final String name;

  final _IDBObjectStoreJs objectStore;

  final bool unique;

  _IDBRequestJs count([_IDBKeyRangeJs range = null]) native;

  _IDBRequestJs getObject(_IDBKeyJs key) native;

  _IDBRequestJs getKey(_IDBKeyJs key) native;

  _IDBRequestJs openCursor([_IDBKeyRangeJs range = null, int direction = null]) native;

  _IDBRequestJs openKeyCursor([_IDBKeyRangeJs range = null, int direction = null]) native;
}

class _IDBKeyJs extends _DOMTypeJs implements IDBKey native "*IDBKey" {
}

class _IDBKeyRangeJs extends _DOMTypeJs implements IDBKeyRange native "*IDBKeyRange" {

  final _IDBKeyJs lower;

  final bool lowerOpen;

  final _IDBKeyJs upper;

  final bool upperOpen;

  _IDBKeyRangeJs bound(_IDBKeyJs lower, _IDBKeyJs upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  _IDBKeyRangeJs lowerBound(_IDBKeyJs bound, [bool open = null]) native;

  _IDBKeyRangeJs only(_IDBKeyJs value) native;

  _IDBKeyRangeJs upperBound(_IDBKeyJs bound, [bool open = null]) native;
}

class _IDBObjectStoreJs extends _DOMTypeJs implements IDBObjectStore native "*IDBObjectStore" {

  final String keyPath;

  final String name;

  final _IDBTransactionJs transaction;

  _IDBRequestJs add(Dynamic value, [_IDBKeyJs key = null]) native;

  _IDBRequestJs clear() native;

  _IDBRequestJs count([_IDBKeyRangeJs range = null]) native;

  _IDBIndexJs createIndex(String name, String keyPath) native;

  _IDBRequestJs delete(_IDBKeyJs key) native;

  void deleteIndex(String name) native;

  _IDBRequestJs getObject(_IDBKeyJs key) native;

  _IDBIndexJs index(String name) native;

  _IDBRequestJs openCursor([_IDBKeyRangeJs range = null, int direction = null]) native;

  _IDBRequestJs put(Dynamic value, [_IDBKeyJs key = null]) native;
}

class _IDBRequestJs extends _DOMTypeJs implements IDBRequest native "*IDBRequest" {

  static final int DONE = 2;

  static final int LOADING = 1;

  final int errorCode;

  EventListener onerror;

  EventListener onsuccess;

  final int readyState;

  final _IDBAnyJs result;

  final _IDBAnyJs source;

  final _IDBTransactionJs transaction;

  final String webkitErrorMessage;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _IDBTransactionJs extends _DOMTypeJs implements IDBTransaction native "*IDBTransaction" {

  static final int READ_ONLY = 0;

  static final int READ_WRITE = 1;

  static final int VERSION_CHANGE = 2;

  final _IDBDatabaseJs db;

  final int mode;

  EventListener onabort;

  EventListener oncomplete;

  EventListener onerror;

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  _IDBObjectStoreJs objectStore(String name) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _IDBVersionChangeEventJs extends _EventJs implements IDBVersionChangeEvent native "*IDBVersionChangeEvent" {

  final String version;
}

class _IDBVersionChangeRequestJs extends _IDBRequestJs implements IDBVersionChangeRequest native "*IDBVersionChangeRequest" {

  EventListener onblocked;
}

class _ImageDataJs extends _DOMTypeJs implements ImageData native "*ImageData" {

  final _CanvasPixelArrayJs data;

  final int height;

  final int width;
}

class _InjectedScriptHostJs extends _DOMTypeJs implements InjectedScriptHost native "*InjectedScriptHost" {

  void clearConsoleMessages() native;

  void copyText(String text) native;

  int databaseId(Object database) native;

  void didCreateWorker(int id, String url, bool isFakeWorker) native;

  void didDestroyWorker(int id) native;

  Object evaluate(String text) native;

  Object functionDetails(Object object) native;

  void inspect(Object objectId, Object hints) native;

  Object inspectedNode(int num) native;

  Object internalConstructorName(Object object) native;

  bool isHTMLAllCollection(Object object) native;

  int nextWorkerId() native;

  int storageId(Object storage) native;

  String type(Object object) native;
}

class _InspectorFrontendHostJs extends _DOMTypeJs implements InspectorFrontendHost native "*InspectorFrontendHost" {

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

  void openInNewTab(String url) native;

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

  void showContextMenu(_MouseEventJs event, Object items) native;
}

class _Int16ArrayJs extends _ArrayBufferViewJs implements Int16Array, List<int> native "*Int16Array" {

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

  _Int16ArrayJs subarray(int start, [int end = null]) native;
}

class _Int32ArrayJs extends _ArrayBufferViewJs implements Int32Array, List<int> native "*Int32Array" {

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

  _Int32ArrayJs subarray(int start, [int end = null]) native;
}

class _Int8ArrayJs extends _ArrayBufferViewJs implements Int8Array, List<int> native "*Int8Array" {

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

  _Int8ArrayJs subarray(int start, [int end = null]) native;
}

class _JavaScriptAudioNodeJs extends _AudioNodeJs implements JavaScriptAudioNode native "*JavaScriptAudioNode" {

  final int bufferSize;

  EventListener onaudioprocess;
}

class _JavaScriptCallFrameJs extends _DOMTypeJs implements JavaScriptCallFrame native "*JavaScriptCallFrame" {

  static final int CATCH_SCOPE = 4;

  static final int CLOSURE_SCOPE = 3;

  static final int GLOBAL_SCOPE = 0;

  static final int LOCAL_SCOPE = 1;

  static final int WITH_SCOPE = 2;

  final _JavaScriptCallFrameJs caller;

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

class _KeyboardEventJs extends _UIEventJs implements KeyboardEvent native "*KeyboardEvent" {

  final bool altGraphKey;

  final bool altKey;

  final bool ctrlKey;

  final String keyIdentifier;

  final int keyLocation;

  final bool metaKey;

  final bool shiftKey;

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, _DOMWindowJs view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) native;
}

class _LocationJs extends _DOMTypeJs implements Location native "*Location" {

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

class _LowPass2FilterNodeJs extends _AudioNodeJs implements LowPass2FilterNode native "*LowPass2FilterNode" {

  final _AudioParamJs cutoff;

  final _AudioParamJs resonance;
}

class _MediaControllerJs extends _DOMTypeJs implements MediaController native "*MediaController" {

  final _TimeRangesJs buffered;

  num currentTime;

  num defaultPlaybackRate;

  final num duration;

  bool muted;

  final bool paused;

  num playbackRate;

  final _TimeRangesJs played;

  final _TimeRangesJs seekable;

  num volume;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void pause() native;

  void play() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _MediaElementAudioSourceNodeJs extends _AudioSourceNodeJs implements MediaElementAudioSourceNode native "*MediaElementAudioSourceNode" {

  final _HTMLMediaElementJs mediaElement;
}

class _MediaErrorJs extends _DOMTypeJs implements MediaError native "*MediaError" {

  static final int MEDIA_ERR_ABORTED = 1;

  static final int MEDIA_ERR_DECODE = 3;

  static final int MEDIA_ERR_NETWORK = 2;

  static final int MEDIA_ERR_SRC_NOT_SUPPORTED = 4;

  final int code;
}

class _MediaListJs extends _DOMTypeJs implements MediaList native "*MediaList" {

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

class _MediaQueryListJs extends _DOMTypeJs implements MediaQueryList native "*MediaQueryList" {

  final bool matches;

  final String media;

  void addListener(_MediaQueryListListenerJs listener) native;

  void removeListener(_MediaQueryListListenerJs listener) native;
}

class _MediaQueryListListenerJs extends _DOMTypeJs implements MediaQueryListListener native "*MediaQueryListListener" {

  void queryChanged(_MediaQueryListJs list) native;
}

class _MemoryInfoJs extends _DOMTypeJs implements MemoryInfo native "*MemoryInfo" {

  final int jsHeapSizeLimit;

  final int totalJSHeapSize;

  final int usedJSHeapSize;
}

class _MessageChannelJs extends _DOMTypeJs implements MessageChannel native "*MessageChannel" {

  final _MessagePortJs port1;

  final _MessagePortJs port2;
}

class _MessageEventJs extends _EventJs implements MessageEvent native "*MessageEvent" {

  final Object data;

  final String lastEventId;

  final String origin;

  final List ports;

  final _DOMWindowJs source;

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, _DOMWindowJs sourceArg, List messagePorts) native;

  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, _DOMWindowJs sourceArg, List transferables) native;
}

class _MessagePortJs extends _DOMTypeJs implements MessagePort native "*MessagePort" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  bool dispatchEvent(_EventJs evt) native;

  void postMessage(String message, [List messagePorts = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void start() native;

  void webkitPostMessage(String message, [List transfer = null]) native;
}

class _MetadataJs extends _DOMTypeJs implements Metadata native "*Metadata" {

  final Date modificationTime;
}

class _MouseEventJs extends _UIEventJs implements MouseEvent native "*MouseEvent" {

  final bool altKey;

  final int button;

  final int clientX;

  final int clientY;

  final bool ctrlKey;

  final _ClipboardJs dataTransfer;

  final _NodeJs fromElement;

  final bool metaKey;

  final int offsetX;

  final int offsetY;

  final _EventTargetJs relatedTarget;

  final int screenX;

  final int screenY;

  final bool shiftKey;

  final _NodeJs toElement;

  final int webkitMovementX;

  final int webkitMovementY;

  final int x;

  final int y;

  void initMouseEvent(String type, bool canBubble, bool cancelable, _DOMWindowJs view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, _EventTargetJs relatedTarget) native;
}

class _MutationCallbackJs extends _DOMTypeJs implements MutationCallback native "*MutationCallback" {
}

class _MutationEventJs extends _EventJs implements MutationEvent native "*MutationEvent" {

  static final int ADDITION = 2;

  static final int MODIFICATION = 1;

  static final int REMOVAL = 3;

  final int attrChange;

  final String attrName;

  final String newValue;

  final String prevValue;

  final _NodeJs relatedNode;

  void initMutationEvent(String type, bool canBubble, bool cancelable, _NodeJs relatedNode, String prevValue, String newValue, String attrName, int attrChange) native;
}

class _MutationRecordJs extends _DOMTypeJs implements MutationRecord native "*MutationRecord" {

  final _NodeListJs addedNodes;

  final String attributeName;

  final String attributeNamespace;

  final _NodeJs nextSibling;

  final String oldValue;

  final _NodeJs previousSibling;

  final _NodeListJs removedNodes;

  final _NodeJs target;

  final String type;
}

class _NamedNodeMapJs extends _DOMTypeJs implements NamedNodeMap native "*NamedNodeMap" {

  final int length;

  _NodeJs operator[](int index) native "return this[index];";

  void operator[]=(int index, _NodeJs value) {
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

  _NodeJs getNamedItem(String name) native;

  _NodeJs getNamedItemNS(String namespaceURI, String localName) native;

  _NodeJs item(int index) native;

  _NodeJs removeNamedItem(String name) native;

  _NodeJs removeNamedItemNS(String namespaceURI, String localName) native;

  _NodeJs setNamedItem(_NodeJs node) native;

  _NodeJs setNamedItemNS(_NodeJs node) native;
}

class _NavigatorJs extends _DOMTypeJs implements Navigator native "*Navigator" {

  final String appCodeName;

  final String appName;

  final String appVersion;

  final bool cookieEnabled;

  final _GeolocationJs geolocation;

  final String language;

  final _DOMMimeTypeArrayJs mimeTypes;

  final bool onLine;

  final String platform;

  final _DOMPluginArrayJs plugins;

  final String product;

  final String productSub;

  final String userAgent;

  final String vendor;

  final String vendorSub;

  void getStorageUpdates() native;

  bool javaEnabled() native;

  void registerProtocolHandler(String scheme, String url, String title) native;
}

class _NodeJs extends _DOMTypeJs implements Node native "*Node" {

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

  final _NamedNodeMapJs attributes;

  final String baseURI;

  final _NodeListJs childNodes;

  final _NodeJs firstChild;

  final _NodeJs lastChild;

  final String localName;

  final String namespaceURI;

  final _NodeJs nextSibling;

  final String nodeName;

  final int nodeType;

  String nodeValue;

  final _DocumentJs ownerDocument;

  final _ElementJs parentElement;

  final _NodeJs parentNode;

  String prefix;

  final _NodeJs previousSibling;

  String textContent;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  _NodeJs appendChild(_NodeJs newChild) native;

  _NodeJs cloneNode(bool deep) native;

  int compareDocumentPosition(_NodeJs other) native;

  bool contains(_NodeJs other) native;

  bool dispatchEvent(_EventJs event) native;

  bool hasAttributes() native;

  bool hasChildNodes() native;

  _NodeJs insertBefore(_NodeJs newChild, _NodeJs refChild) native;

  bool isDefaultNamespace(String namespaceURI) native;

  bool isEqualNode(_NodeJs other) native;

  bool isSameNode(_NodeJs other) native;

  bool isSupported(String feature, String version) native;

  String lookupNamespaceURI(String prefix) native;

  String lookupPrefix(String namespaceURI) native;

  void normalize() native;

  _NodeJs removeChild(_NodeJs oldChild) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  _NodeJs replaceChild(_NodeJs newChild, _NodeJs oldChild) native;
}

class _NodeFilterJs extends _DOMTypeJs implements NodeFilter native "*NodeFilter" {

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

  int acceptNode(_NodeJs n) native;
}

class _NodeIteratorJs extends _DOMTypeJs implements NodeIterator native "*NodeIterator" {

  final bool expandEntityReferences;

  final _NodeFilterJs filter;

  final bool pointerBeforeReferenceNode;

  final _NodeJs referenceNode;

  final _NodeJs root;

  final int whatToShow;

  void detach() native;

  _NodeJs nextNode() native;

  _NodeJs previousNode() native;
}

class _NodeListJs extends _DOMTypeJs implements NodeList native "*NodeList" {

  final int length;

  _NodeJs operator[](int index) native "return this[index];";

  void operator[]=(int index, _NodeJs value) {
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

  _NodeJs item(int index) native;
}

class _NodeSelectorJs extends _DOMTypeJs implements NodeSelector native "*NodeSelector" {

  _ElementJs querySelector(String selectors) native;

  _NodeListJs querySelectorAll(String selectors) native;
}

class _NotationJs extends _NodeJs implements Notation native "*Notation" {

  final String publicId;

  final String systemId;
}

class _NotificationJs extends _DOMTypeJs implements Notification native "*Notification" {

  String dir;

  String replaceId;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void cancel() native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void show() native;
}

class _NotificationCenterJs extends _DOMTypeJs implements NotificationCenter native "*NotificationCenter" {

  int checkPermission() native;

  _NotificationJs createHTMLNotification(String url) native;

  _NotificationJs createNotification(String iconUrl, String title, String body) native;

  void requestPermission(VoidCallback callback) native;
}

class _OESStandardDerivativesJs extends _DOMTypeJs implements OESStandardDerivatives native "*OESStandardDerivatives" {

  static final int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;
}

class _OESTextureFloatJs extends _DOMTypeJs implements OESTextureFloat native "*OESTextureFloat" {
}

class _OESVertexArrayObjectJs extends _DOMTypeJs implements OESVertexArrayObject native "*OESVertexArrayObject" {

  static final int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  void bindVertexArrayOES(_WebGLVertexArrayObjectOESJs arrayObject) native;

  _WebGLVertexArrayObjectOESJs createVertexArrayOES() native;

  void deleteVertexArrayOES(_WebGLVertexArrayObjectOESJs arrayObject) native;

  bool isVertexArrayOES(_WebGLVertexArrayObjectOESJs arrayObject) native;
}

class _OfflineAudioCompletionEventJs extends _EventJs implements OfflineAudioCompletionEvent native "*OfflineAudioCompletionEvent" {

  final _AudioBufferJs renderedBuffer;
}

class _OperationNotAllowedExceptionJs extends _DOMTypeJs implements OperationNotAllowedException native "*OperationNotAllowedException" {

  static final int NOT_ALLOWED_ERR = 1;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _OverflowEventJs extends _EventJs implements OverflowEvent native "*OverflowEvent" {

  static final int BOTH = 2;

  static final int HORIZONTAL = 0;

  static final int VERTICAL = 1;

  final bool horizontalOverflow;

  final int orient;

  final bool verticalOverflow;
}

class _PageTransitionEventJs extends _EventJs implements PageTransitionEvent native "*PageTransitionEvent" {

  final bool persisted;
}

class _PerformanceJs extends _DOMTypeJs implements Performance native "*Performance" {

  final _MemoryInfoJs memory;

  final _PerformanceNavigationJs navigation;

  final _PerformanceTimingJs timing;
}

class _PerformanceNavigationJs extends _DOMTypeJs implements PerformanceNavigation native "*PerformanceNavigation" {

  static final int TYPE_BACK_FORWARD = 2;

  static final int TYPE_NAVIGATE = 0;

  static final int TYPE_RELOAD = 1;

  static final int TYPE_RESERVED = 255;

  final int redirectCount;

  final int type;
}

class _PerformanceTimingJs extends _DOMTypeJs implements PerformanceTiming native "*PerformanceTiming" {

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

class _PointerLockJs extends _DOMTypeJs implements PointerLock native "*PointerLock" {

  final bool isLocked;

  void lock(_ElementJs target, [VoidCallback successCallback = null, VoidCallback failureCallback = null]) native;

  void unlock() native;
}

class _PopStateEventJs extends _EventJs implements PopStateEvent native "*PopStateEvent" {

  final Object state;
}

class _PositionErrorJs extends _DOMTypeJs implements PositionError native "*PositionError" {

  static final int PERMISSION_DENIED = 1;

  static final int POSITION_UNAVAILABLE = 2;

  static final int TIMEOUT = 3;

  final int code;

  final String message;
}

class _ProcessingInstructionJs extends _NodeJs implements ProcessingInstruction native "*ProcessingInstruction" {

  String data;

  final _StyleSheetJs sheet;

  final String target;
}

class _ProgressEventJs extends _EventJs implements ProgressEvent native "*ProgressEvent" {

  final bool lengthComputable;

  final int loaded;

  final int total;
}

class _RGBColorJs extends _DOMTypeJs implements RGBColor native "*RGBColor" {

  final _CSSPrimitiveValueJs blue;

  final _CSSPrimitiveValueJs green;

  final _CSSPrimitiveValueJs red;
}

class _RangeJs extends _DOMTypeJs implements Range native "*Range" {

  static final int END_TO_END = 2;

  static final int END_TO_START = 3;

  static final int NODE_AFTER = 1;

  static final int NODE_BEFORE = 0;

  static final int NODE_BEFORE_AND_AFTER = 2;

  static final int NODE_INSIDE = 3;

  static final int START_TO_END = 1;

  static final int START_TO_START = 0;

  final bool collapsed;

  final _NodeJs commonAncestorContainer;

  final _NodeJs endContainer;

  final int endOffset;

  final _NodeJs startContainer;

  final int startOffset;

  _DocumentFragmentJs cloneContents() native;

  _RangeJs cloneRange() native;

  void collapse(bool toStart) native;

  int compareNode(_NodeJs refNode) native;

  int comparePoint(_NodeJs refNode, int offset) native;

  _DocumentFragmentJs createContextualFragment(String html) native;

  void deleteContents() native;

  void detach() native;

  void expand(String unit) native;

  _DocumentFragmentJs extractContents() native;

  _ClientRectJs getBoundingClientRect() native;

  _ClientRectListJs getClientRects() native;

  void insertNode(_NodeJs newNode) native;

  bool intersectsNode(_NodeJs refNode) native;

  bool isPointInRange(_NodeJs refNode, int offset) native;

  void selectNode(_NodeJs refNode) native;

  void selectNodeContents(_NodeJs refNode) native;

  void setEnd(_NodeJs refNode, int offset) native;

  void setEndAfter(_NodeJs refNode) native;

  void setEndBefore(_NodeJs refNode) native;

  void setStart(_NodeJs refNode, int offset) native;

  void setStartAfter(_NodeJs refNode) native;

  void setStartBefore(_NodeJs refNode) native;

  void surroundContents(_NodeJs newParent) native;

  String toString() native;
}

class _RangeExceptionJs extends _DOMTypeJs implements RangeException native "*RangeException" {

  static final int BAD_BOUNDARYPOINTS_ERR = 1;

  static final int INVALID_NODE_TYPE_ERR = 2;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _RealtimeAnalyserNodeJs extends _AudioNodeJs implements RealtimeAnalyserNode native "*RealtimeAnalyserNode" {

  int fftSize;

  final int frequencyBinCount;

  num maxDecibels;

  num minDecibels;

  num smoothingTimeConstant;

  void getByteFrequencyData(_Uint8ArrayJs array) native;

  void getByteTimeDomainData(_Uint8ArrayJs array) native;

  void getFloatFrequencyData(_Float32ArrayJs array) native;
}

class _RectJs extends _DOMTypeJs implements Rect native "*Rect" {

  final _CSSPrimitiveValueJs bottom;

  final _CSSPrimitiveValueJs left;

  final _CSSPrimitiveValueJs right;

  final _CSSPrimitiveValueJs top;
}

class _SQLErrorJs extends _DOMTypeJs implements SQLError native "*SQLError" {

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

class _SQLExceptionJs extends _DOMTypeJs implements SQLException native "*SQLException" {

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

class _SQLResultSetJs extends _DOMTypeJs implements SQLResultSet native "*SQLResultSet" {

  final int insertId;

  final _SQLResultSetRowListJs rows;

  final int rowsAffected;
}

class _SQLResultSetRowListJs extends _DOMTypeJs implements SQLResultSetRowList native "*SQLResultSetRowList" {

  final int length;

  Object item(int index) native;
}

class _SQLTransactionJs extends _DOMTypeJs implements SQLTransaction native "*SQLTransaction" {
}

class _SQLTransactionSyncJs extends _DOMTypeJs implements SQLTransactionSync native "*SQLTransactionSync" {
}

class _SVGAElementJs extends _SVGElementJs implements SVGAElement native "*SVGAElement" {

  final _SVGAnimatedStringJs target;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGAltGlyphDefElementJs extends _SVGElementJs implements SVGAltGlyphDefElement native "*SVGAltGlyphDefElement" {
}

class _SVGAltGlyphElementJs extends _SVGTextPositioningElementJs implements SVGAltGlyphElement native "*SVGAltGlyphElement" {

  String format;

  String glyphRef;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;
}

class _SVGAltGlyphItemElementJs extends _SVGElementJs implements SVGAltGlyphItemElement native "*SVGAltGlyphItemElement" {
}

class _SVGAngleJs extends _DOMTypeJs implements SVGAngle native "*SVGAngle" {

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

class _SVGAnimateColorElementJs extends _SVGAnimationElementJs implements SVGAnimateColorElement native "*SVGAnimateColorElement" {
}

class _SVGAnimateElementJs extends _SVGAnimationElementJs implements SVGAnimateElement native "*SVGAnimateElement" {
}

class _SVGAnimateMotionElementJs extends _SVGAnimationElementJs implements SVGAnimateMotionElement native "*SVGAnimateMotionElement" {
}

class _SVGAnimateTransformElementJs extends _SVGAnimationElementJs implements SVGAnimateTransformElement native "*SVGAnimateTransformElement" {
}

class _SVGAnimatedAngleJs extends _DOMTypeJs implements SVGAnimatedAngle native "*SVGAnimatedAngle" {

  final _SVGAngleJs animVal;

  final _SVGAngleJs baseVal;
}

class _SVGAnimatedBooleanJs extends _DOMTypeJs implements SVGAnimatedBoolean native "*SVGAnimatedBoolean" {

  final bool animVal;

  bool baseVal;
}

class _SVGAnimatedEnumerationJs extends _DOMTypeJs implements SVGAnimatedEnumeration native "*SVGAnimatedEnumeration" {

  final int animVal;

  int baseVal;
}

class _SVGAnimatedIntegerJs extends _DOMTypeJs implements SVGAnimatedInteger native "*SVGAnimatedInteger" {

  final int animVal;

  int baseVal;
}

class _SVGAnimatedLengthJs extends _DOMTypeJs implements SVGAnimatedLength native "*SVGAnimatedLength" {

  final _SVGLengthJs animVal;

  final _SVGLengthJs baseVal;
}

class _SVGAnimatedLengthListJs extends _DOMTypeJs implements SVGAnimatedLengthList native "*SVGAnimatedLengthList" {

  final _SVGLengthListJs animVal;

  final _SVGLengthListJs baseVal;
}

class _SVGAnimatedNumberJs extends _DOMTypeJs implements SVGAnimatedNumber native "*SVGAnimatedNumber" {

  final num animVal;

  num baseVal;
}

class _SVGAnimatedNumberListJs extends _DOMTypeJs implements SVGAnimatedNumberList native "*SVGAnimatedNumberList" {

  final _SVGNumberListJs animVal;

  final _SVGNumberListJs baseVal;
}

class _SVGAnimatedPreserveAspectRatioJs extends _DOMTypeJs implements SVGAnimatedPreserveAspectRatio native "*SVGAnimatedPreserveAspectRatio" {

  final _SVGPreserveAspectRatioJs animVal;

  final _SVGPreserveAspectRatioJs baseVal;
}

class _SVGAnimatedRectJs extends _DOMTypeJs implements SVGAnimatedRect native "*SVGAnimatedRect" {

  final _SVGRectJs animVal;

  final _SVGRectJs baseVal;
}

class _SVGAnimatedStringJs extends _DOMTypeJs implements SVGAnimatedString native "*SVGAnimatedString" {

  final String animVal;

  String baseVal;
}

class _SVGAnimatedTransformListJs extends _DOMTypeJs implements SVGAnimatedTransformList native "*SVGAnimatedTransformList" {

  final _SVGTransformListJs animVal;

  final _SVGTransformListJs baseVal;
}

class _SVGAnimationElementJs extends _SVGElementJs implements SVGAnimationElement native "*SVGAnimationElement" {

  final _SVGElementJs targetElement;

  num getCurrentTime() native;

  num getSimpleDuration() native;

  num getStartTime() native;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From ElementTimeControl

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;
}

class _SVGCircleElementJs extends _SVGElementJs implements SVGCircleElement native "*SVGCircleElement" {

  final _SVGAnimatedLengthJs cx;

  final _SVGAnimatedLengthJs cy;

  final _SVGAnimatedLengthJs r;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGClipPathElementJs extends _SVGElementJs implements SVGClipPathElement native "*SVGClipPathElement" {

  final _SVGAnimatedEnumerationJs clipPathUnits;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGColorJs extends _CSSValueJs implements SVGColor native "*SVGColor" {

  static final int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static final int SVG_COLORTYPE_RGBCOLOR = 1;

  static final int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static final int SVG_COLORTYPE_UNKNOWN = 0;

  final int colorType;

  final _RGBColorJs rgbColor;

  void setColor(int colorType, String rgbColor, String iccColor) native;

  void setRGBColor(String rgbColor) native;

  void setRGBColorICCColor(String rgbColor, String iccColor) native;
}

class _SVGComponentTransferFunctionElementJs extends _SVGElementJs implements SVGComponentTransferFunctionElement native "*SVGComponentTransferFunctionElement" {

  static final int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static final int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  final _SVGAnimatedNumberJs amplitude;

  final _SVGAnimatedNumberJs exponent;

  final _SVGAnimatedNumberJs intercept;

  final _SVGAnimatedNumberJs offset;

  final _SVGAnimatedNumberJs slope;

  final _SVGAnimatedNumberListJs tableValues;

  final _SVGAnimatedEnumerationJs type;
}

class _SVGCursorElementJs extends _SVGElementJs implements SVGCursorElement native "*SVGCursorElement" {

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;
}

class _SVGDefsElementJs extends _SVGElementJs implements SVGDefsElement native "*SVGDefsElement" {

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGDescElementJs extends _SVGElementJs implements SVGDescElement native "*SVGDescElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGDocumentJs extends _DocumentJs implements SVGDocument native "*SVGDocument" {

  final _SVGSVGElementJs rootElement;

  _EventJs createEvent(String eventType) native;
}

class _SVGElementJs extends _ElementJs implements SVGElement native "*SVGElement" {

  String id;

  final _SVGSVGElementJs ownerSVGElement;

  final _SVGElementJs viewportElement;

  String xmlbase;
}

class _SVGElementInstanceJs extends _DOMTypeJs implements SVGElementInstance native "*SVGElementInstance" {

  final _SVGElementInstanceListJs childNodes;

  final _SVGElementJs correspondingElement;

  final _SVGUseElementJs correspondingUseElement;

  final _SVGElementInstanceJs firstChild;

  final _SVGElementInstanceJs lastChild;

  final _SVGElementInstanceJs nextSibling;

  final _SVGElementInstanceJs parentNode;

  final _SVGElementInstanceJs previousSibling;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _SVGElementInstanceListJs extends _DOMTypeJs implements SVGElementInstanceList native "*SVGElementInstanceList" {

  final int length;

  _SVGElementInstanceJs item(int index) native;
}

class _SVGEllipseElementJs extends _SVGElementJs implements SVGEllipseElement native "*SVGEllipseElement" {

  final _SVGAnimatedLengthJs cx;

  final _SVGAnimatedLengthJs cy;

  final _SVGAnimatedLengthJs rx;

  final _SVGAnimatedLengthJs ry;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGExceptionJs extends _DOMTypeJs implements SVGException native "*SVGException" {

  static final int SVG_INVALID_VALUE_ERR = 1;

  static final int SVG_MATRIX_NOT_INVERTABLE = 2;

  static final int SVG_WRONG_TYPE_ERR = 0;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _SVGExternalResourcesRequiredJs extends _DOMTypeJs implements SVGExternalResourcesRequired native "*SVGExternalResourcesRequired" {

  final _SVGAnimatedBooleanJs externalResourcesRequired;
}

class _SVGFEBlendElementJs extends _SVGElementJs implements SVGFEBlendElement native "*SVGFEBlendElement" {

  static final int SVG_FEBLEND_MODE_DARKEN = 4;

  static final int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static final int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static final int SVG_FEBLEND_MODE_NORMAL = 1;

  static final int SVG_FEBLEND_MODE_SCREEN = 3;

  static final int SVG_FEBLEND_MODE_UNKNOWN = 0;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedStringJs in2;

  final _SVGAnimatedEnumerationJs mode;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEColorMatrixElementJs extends _SVGElementJs implements SVGFEColorMatrixElement native "*SVGFEColorMatrixElement" {

  static final int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static final int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static final int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static final int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static final int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedEnumerationJs type;

  final _SVGAnimatedNumberListJs values;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEComponentTransferElementJs extends _SVGElementJs implements SVGFEComponentTransferElement native "*SVGFEComponentTransferElement" {

  final _SVGAnimatedStringJs in1;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFECompositeElementJs extends _SVGElementJs implements SVGFECompositeElement native "*SVGFECompositeElement" {

  static final int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static final int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static final int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static final int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static final int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static final int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static final int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedStringJs in2;

  final _SVGAnimatedNumberJs k1;

  final _SVGAnimatedNumberJs k2;

  final _SVGAnimatedNumberJs k3;

  final _SVGAnimatedNumberJs k4;

  final _SVGAnimatedEnumerationJs operator;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEConvolveMatrixElementJs extends _SVGElementJs implements SVGFEConvolveMatrixElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  final _SVGAnimatedNumberJs bias;

  final _SVGAnimatedNumberJs divisor;

  final _SVGAnimatedEnumerationJs edgeMode;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedNumberListJs kernelMatrix;

  final _SVGAnimatedNumberJs kernelUnitLengthX;

  final _SVGAnimatedNumberJs kernelUnitLengthY;

  final _SVGAnimatedIntegerJs orderX;

  final _SVGAnimatedIntegerJs orderY;

  final _SVGAnimatedBooleanJs preserveAlpha;

  final _SVGAnimatedIntegerJs targetX;

  final _SVGAnimatedIntegerJs targetY;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEDiffuseLightingElementJs extends _SVGElementJs implements SVGFEDiffuseLightingElement native "*SVGFEDiffuseLightingElement" {

  final _SVGAnimatedNumberJs diffuseConstant;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedNumberJs kernelUnitLengthX;

  final _SVGAnimatedNumberJs kernelUnitLengthY;

  final _SVGAnimatedNumberJs surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEDisplacementMapElementJs extends _SVGElementJs implements SVGFEDisplacementMapElement native "*SVGFEDisplacementMapElement" {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedStringJs in2;

  final _SVGAnimatedNumberJs scale;

  final _SVGAnimatedEnumerationJs xChannelSelector;

  final _SVGAnimatedEnumerationJs yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEDistantLightElementJs extends _SVGElementJs implements SVGFEDistantLightElement native "*SVGFEDistantLightElement" {

  final _SVGAnimatedNumberJs azimuth;

  final _SVGAnimatedNumberJs elevation;
}

class _SVGFEDropShadowElementJs extends _SVGElementJs implements SVGFEDropShadowElement native "*SVGFEDropShadowElement" {

  final _SVGAnimatedNumberJs dx;

  final _SVGAnimatedNumberJs dy;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedNumberJs stdDeviationX;

  final _SVGAnimatedNumberJs stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEFloodElementJs extends _SVGElementJs implements SVGFEFloodElement native "*SVGFEFloodElement" {

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEFuncAElementJs extends _SVGComponentTransferFunctionElementJs implements SVGFEFuncAElement native "*SVGFEFuncAElement" {
}

class _SVGFEFuncBElementJs extends _SVGComponentTransferFunctionElementJs implements SVGFEFuncBElement native "*SVGFEFuncBElement" {
}

class _SVGFEFuncGElementJs extends _SVGComponentTransferFunctionElementJs implements SVGFEFuncGElement native "*SVGFEFuncGElement" {
}

class _SVGFEFuncRElementJs extends _SVGComponentTransferFunctionElementJs implements SVGFEFuncRElement native "*SVGFEFuncRElement" {
}

class _SVGFEGaussianBlurElementJs extends _SVGElementJs implements SVGFEGaussianBlurElement native "*SVGFEGaussianBlurElement" {

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedNumberJs stdDeviationX;

  final _SVGAnimatedNumberJs stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEImageElementJs extends _SVGElementJs implements SVGFEImageElement native "*SVGFEImageElement" {

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEMergeElementJs extends _SVGElementJs implements SVGFEMergeElement native "*SVGFEMergeElement" {

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEMergeNodeElementJs extends _SVGElementJs implements SVGFEMergeNodeElement native "*SVGFEMergeNodeElement" {

  final _SVGAnimatedStringJs in1;
}

class _SVGFEMorphologyElementJs extends _SVGElementJs implements SVGFEMorphologyElement native "*SVGFEMorphologyElement" {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedEnumerationJs operator;

  final _SVGAnimatedNumberJs radiusX;

  final _SVGAnimatedNumberJs radiusY;

  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEOffsetElementJs extends _SVGElementJs implements SVGFEOffsetElement native "*SVGFEOffsetElement" {

  final _SVGAnimatedNumberJs dx;

  final _SVGAnimatedNumberJs dy;

  final _SVGAnimatedStringJs in1;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFEPointLightElementJs extends _SVGElementJs implements SVGFEPointLightElement native "*SVGFEPointLightElement" {

  final _SVGAnimatedNumberJs x;

  final _SVGAnimatedNumberJs y;

  final _SVGAnimatedNumberJs z;
}

class _SVGFESpecularLightingElementJs extends _SVGElementJs implements SVGFESpecularLightingElement native "*SVGFESpecularLightingElement" {

  final _SVGAnimatedStringJs in1;

  final _SVGAnimatedNumberJs specularConstant;

  final _SVGAnimatedNumberJs specularExponent;

  final _SVGAnimatedNumberJs surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFESpotLightElementJs extends _SVGElementJs implements SVGFESpotLightElement native "*SVGFESpotLightElement" {

  final _SVGAnimatedNumberJs limitingConeAngle;

  final _SVGAnimatedNumberJs pointsAtX;

  final _SVGAnimatedNumberJs pointsAtY;

  final _SVGAnimatedNumberJs pointsAtZ;

  final _SVGAnimatedNumberJs specularExponent;

  final _SVGAnimatedNumberJs x;

  final _SVGAnimatedNumberJs y;

  final _SVGAnimatedNumberJs z;
}

class _SVGFETileElementJs extends _SVGElementJs implements SVGFETileElement native "*SVGFETileElement" {

  final _SVGAnimatedStringJs in1;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFETurbulenceElementJs extends _SVGElementJs implements SVGFETurbulenceElement native "*SVGFETurbulenceElement" {

  static final int SVG_STITCHTYPE_NOSTITCH = 2;

  static final int SVG_STITCHTYPE_STITCH = 1;

  static final int SVG_STITCHTYPE_UNKNOWN = 0;

  static final int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static final int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static final int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  final _SVGAnimatedNumberJs baseFrequencyX;

  final _SVGAnimatedNumberJs baseFrequencyY;

  final _SVGAnimatedIntegerJs numOctaves;

  final _SVGAnimatedNumberJs seed;

  final _SVGAnimatedEnumerationJs stitchTiles;

  final _SVGAnimatedEnumerationJs type;

  // From SVGFilterPrimitiveStandardAttributes

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFilterElementJs extends _SVGElementJs implements SVGFilterElement native "*SVGFilterElement" {

  final _SVGAnimatedIntegerJs filterResX;

  final _SVGAnimatedIntegerJs filterResY;

  final _SVGAnimatedEnumerationJs filterUnits;

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedEnumerationJs primitiveUnits;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGFilterPrimitiveStandardAttributesJs extends _SVGStylableJs implements SVGFilterPrimitiveStandardAttributes native "*SVGFilterPrimitiveStandardAttributes" {

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedStringJs result;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;
}

class _SVGFitToViewBoxJs extends _DOMTypeJs implements SVGFitToViewBox native "*SVGFitToViewBox" {

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedRectJs viewBox;
}

class _SVGFontElementJs extends _SVGElementJs implements SVGFontElement native "*SVGFontElement" {
}

class _SVGFontFaceElementJs extends _SVGElementJs implements SVGFontFaceElement native "*SVGFontFaceElement" {
}

class _SVGFontFaceFormatElementJs extends _SVGElementJs implements SVGFontFaceFormatElement native "*SVGFontFaceFormatElement" {
}

class _SVGFontFaceNameElementJs extends _SVGElementJs implements SVGFontFaceNameElement native "*SVGFontFaceNameElement" {
}

class _SVGFontFaceSrcElementJs extends _SVGElementJs implements SVGFontFaceSrcElement native "*SVGFontFaceSrcElement" {
}

class _SVGFontFaceUriElementJs extends _SVGElementJs implements SVGFontFaceUriElement native "*SVGFontFaceUriElement" {
}

class _SVGForeignObjectElementJs extends _SVGElementJs implements SVGForeignObjectElement native "*SVGForeignObjectElement" {

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGGElementJs extends _SVGElementJs implements SVGGElement native "*SVGGElement" {

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGGlyphElementJs extends _SVGElementJs implements SVGGlyphElement native "*SVGGlyphElement" {
}

class _SVGGlyphRefElementJs extends _SVGElementJs implements SVGGlyphRefElement native "*SVGGlyphRefElement" {

  num dx;

  num dy;

  String format;

  String glyphRef;

  num x;

  num y;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGGradientElementJs extends _SVGElementJs implements SVGGradientElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  final _SVGAnimatedTransformListJs gradientTransform;

  final _SVGAnimatedEnumerationJs gradientUnits;

  final _SVGAnimatedEnumerationJs spreadMethod;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGHKernElementJs extends _SVGElementJs implements SVGHKernElement native "*SVGHKernElement" {
}

class _SVGImageElementJs extends _SVGElementJs implements SVGImageElement native "*SVGImageElement" {

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGLangSpaceJs extends _DOMTypeJs implements SVGLangSpace native "*SVGLangSpace" {

  String xmllang;

  String xmlspace;
}

class _SVGLengthJs extends _DOMTypeJs implements SVGLength native "*SVGLength" {

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

class _SVGLengthListJs extends _DOMTypeJs implements SVGLengthList native "*SVGLengthList" {

  final int numberOfItems;

  _SVGLengthJs appendItem(_SVGLengthJs item) native;

  void clear() native;

  _SVGLengthJs getItem(int index) native;

  _SVGLengthJs initialize(_SVGLengthJs item) native;

  _SVGLengthJs insertItemBefore(_SVGLengthJs item, int index) native;

  _SVGLengthJs removeItem(int index) native;

  _SVGLengthJs replaceItem(_SVGLengthJs item, int index) native;
}

class _SVGLineElementJs extends _SVGElementJs implements SVGLineElement native "*SVGLineElement" {

  final _SVGAnimatedLengthJs x1;

  final _SVGAnimatedLengthJs x2;

  final _SVGAnimatedLengthJs y1;

  final _SVGAnimatedLengthJs y2;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGLinearGradientElementJs extends _SVGGradientElementJs implements SVGLinearGradientElement native "*SVGLinearGradientElement" {

  final _SVGAnimatedLengthJs x1;

  final _SVGAnimatedLengthJs x2;

  final _SVGAnimatedLengthJs y1;

  final _SVGAnimatedLengthJs y2;
}

class _SVGLocatableJs extends _DOMTypeJs implements SVGLocatable native "*SVGLocatable" {

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGMPathElementJs extends _SVGElementJs implements SVGMPathElement native "*SVGMPathElement" {

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;
}

class _SVGMarkerElementJs extends _SVGElementJs implements SVGMarkerElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  final _SVGAnimatedLengthJs markerHeight;

  final _SVGAnimatedEnumerationJs markerUnits;

  final _SVGAnimatedLengthJs markerWidth;

  final _SVGAnimatedAngleJs orientAngle;

  final _SVGAnimatedEnumerationJs orientType;

  final _SVGAnimatedLengthJs refX;

  final _SVGAnimatedLengthJs refY;

  void setOrientToAngle(_SVGAngleJs angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedRectJs viewBox;
}

class _SVGMaskElementJs extends _SVGElementJs implements SVGMaskElement native "*SVGMaskElement" {

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedEnumerationJs maskContentUnits;

  final _SVGAnimatedEnumerationJs maskUnits;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGMatrixJs extends _DOMTypeJs implements SVGMatrix native "*SVGMatrix" {

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

  _SVGMatrixJs flipX() native;

  _SVGMatrixJs flipY() native;

  _SVGMatrixJs inverse() native;

  _SVGMatrixJs multiply(_SVGMatrixJs secondMatrix) native;

  _SVGMatrixJs rotate(num angle) native;

  _SVGMatrixJs rotateFromVector(num x, num y) native;

  _SVGMatrixJs scale(num scaleFactor) native;

  _SVGMatrixJs scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  _SVGMatrixJs skewX(num angle) native;

  _SVGMatrixJs skewY(num angle) native;

  _SVGMatrixJs translate(num x, num y) native;
}

class _SVGMetadataElementJs extends _SVGElementJs implements SVGMetadataElement native "*SVGMetadataElement" {
}

class _SVGMissingGlyphElementJs extends _SVGElementJs implements SVGMissingGlyphElement native "*SVGMissingGlyphElement" {
}

class _SVGNumberJs extends _DOMTypeJs implements SVGNumber native "*SVGNumber" {

  num value;
}

class _SVGNumberListJs extends _DOMTypeJs implements SVGNumberList native "*SVGNumberList" {

  final int numberOfItems;

  _SVGNumberJs appendItem(_SVGNumberJs item) native;

  void clear() native;

  _SVGNumberJs getItem(int index) native;

  _SVGNumberJs initialize(_SVGNumberJs item) native;

  _SVGNumberJs insertItemBefore(_SVGNumberJs item, int index) native;

  _SVGNumberJs removeItem(int index) native;

  _SVGNumberJs replaceItem(_SVGNumberJs item, int index) native;
}

class _SVGPaintJs extends _SVGColorJs implements SVGPaint native "*SVGPaint" {

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

class _SVGPathElementJs extends _SVGElementJs implements SVGPathElement native "*SVGPathElement" {

  final _SVGPathSegListJs animatedNormalizedPathSegList;

  final _SVGPathSegListJs animatedPathSegList;

  final _SVGPathSegListJs normalizedPathSegList;

  final _SVGAnimatedNumberJs pathLength;

  final _SVGPathSegListJs pathSegList;

  _SVGPathSegArcAbsJs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  _SVGPathSegArcRelJs createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  _SVGPathSegClosePathJs createSVGPathSegClosePath() native;

  _SVGPathSegCurvetoCubicAbsJs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  _SVGPathSegCurvetoCubicRelJs createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  _SVGPathSegCurvetoCubicSmoothAbsJs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  _SVGPathSegCurvetoCubicSmoothRelJs createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  _SVGPathSegCurvetoQuadraticAbsJs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  _SVGPathSegCurvetoQuadraticRelJs createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  _SVGPathSegCurvetoQuadraticSmoothAbsJs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  _SVGPathSegCurvetoQuadraticSmoothRelJs createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  _SVGPathSegLinetoAbsJs createSVGPathSegLinetoAbs(num x, num y) native;

  _SVGPathSegLinetoHorizontalAbsJs createSVGPathSegLinetoHorizontalAbs(num x) native;

  _SVGPathSegLinetoHorizontalRelJs createSVGPathSegLinetoHorizontalRel(num x) native;

  _SVGPathSegLinetoRelJs createSVGPathSegLinetoRel(num x, num y) native;

  _SVGPathSegLinetoVerticalAbsJs createSVGPathSegLinetoVerticalAbs(num y) native;

  _SVGPathSegLinetoVerticalRelJs createSVGPathSegLinetoVerticalRel(num y) native;

  _SVGPathSegMovetoAbsJs createSVGPathSegMovetoAbs(num x, num y) native;

  _SVGPathSegMovetoRelJs createSVGPathSegMovetoRel(num x, num y) native;

  int getPathSegAtLength(num distance) native;

  _SVGPointJs getPointAtLength(num distance) native;

  num getTotalLength() native;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGPathSegJs extends _DOMTypeJs implements SVGPathSeg native "*SVGPathSeg" {

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

class _SVGPathSegArcAbsJs extends _SVGPathSegJs implements SVGPathSegArcAbs native "*SVGPathSegArcAbs" {

  num angle;

  bool largeArcFlag;

  num r1;

  num r2;

  bool sweepFlag;

  num x;

  num y;
}

class _SVGPathSegArcRelJs extends _SVGPathSegJs implements SVGPathSegArcRel native "*SVGPathSegArcRel" {

  num angle;

  bool largeArcFlag;

  num r1;

  num r2;

  bool sweepFlag;

  num x;

  num y;
}

class _SVGPathSegClosePathJs extends _SVGPathSegJs implements SVGPathSegClosePath native "*SVGPathSegClosePath" {
}

class _SVGPathSegCurvetoCubicAbsJs extends _SVGPathSegJs implements SVGPathSegCurvetoCubicAbs native "*SVGPathSegCurvetoCubicAbs" {

  num x;

  num x1;

  num x2;

  num y;

  num y1;

  num y2;
}

class _SVGPathSegCurvetoCubicRelJs extends _SVGPathSegJs implements SVGPathSegCurvetoCubicRel native "*SVGPathSegCurvetoCubicRel" {

  num x;

  num x1;

  num x2;

  num y;

  num y1;

  num y2;
}

class _SVGPathSegCurvetoCubicSmoothAbsJs extends _SVGPathSegJs implements SVGPathSegCurvetoCubicSmoothAbs native "*SVGPathSegCurvetoCubicSmoothAbs" {

  num x;

  num x2;

  num y;

  num y2;
}

class _SVGPathSegCurvetoCubicSmoothRelJs extends _SVGPathSegJs implements SVGPathSegCurvetoCubicSmoothRel native "*SVGPathSegCurvetoCubicSmoothRel" {

  num x;

  num x2;

  num y;

  num y2;
}

class _SVGPathSegCurvetoQuadraticAbsJs extends _SVGPathSegJs implements SVGPathSegCurvetoQuadraticAbs native "*SVGPathSegCurvetoQuadraticAbs" {

  num x;

  num x1;

  num y;

  num y1;
}

class _SVGPathSegCurvetoQuadraticRelJs extends _SVGPathSegJs implements SVGPathSegCurvetoQuadraticRel native "*SVGPathSegCurvetoQuadraticRel" {

  num x;

  num x1;

  num y;

  num y1;
}

class _SVGPathSegCurvetoQuadraticSmoothAbsJs extends _SVGPathSegJs implements SVGPathSegCurvetoQuadraticSmoothAbs native "*SVGPathSegCurvetoQuadraticSmoothAbs" {

  num x;

  num y;
}

class _SVGPathSegCurvetoQuadraticSmoothRelJs extends _SVGPathSegJs implements SVGPathSegCurvetoQuadraticSmoothRel native "*SVGPathSegCurvetoQuadraticSmoothRel" {

  num x;

  num y;
}

class _SVGPathSegLinetoAbsJs extends _SVGPathSegJs implements SVGPathSegLinetoAbs native "*SVGPathSegLinetoAbs" {

  num x;

  num y;
}

class _SVGPathSegLinetoHorizontalAbsJs extends _SVGPathSegJs implements SVGPathSegLinetoHorizontalAbs native "*SVGPathSegLinetoHorizontalAbs" {

  num x;
}

class _SVGPathSegLinetoHorizontalRelJs extends _SVGPathSegJs implements SVGPathSegLinetoHorizontalRel native "*SVGPathSegLinetoHorizontalRel" {

  num x;
}

class _SVGPathSegLinetoRelJs extends _SVGPathSegJs implements SVGPathSegLinetoRel native "*SVGPathSegLinetoRel" {

  num x;

  num y;
}

class _SVGPathSegLinetoVerticalAbsJs extends _SVGPathSegJs implements SVGPathSegLinetoVerticalAbs native "*SVGPathSegLinetoVerticalAbs" {

  num y;
}

class _SVGPathSegLinetoVerticalRelJs extends _SVGPathSegJs implements SVGPathSegLinetoVerticalRel native "*SVGPathSegLinetoVerticalRel" {

  num y;
}

class _SVGPathSegListJs extends _DOMTypeJs implements SVGPathSegList native "*SVGPathSegList" {

  final int numberOfItems;

  _SVGPathSegJs appendItem(_SVGPathSegJs newItem) native;

  void clear() native;

  _SVGPathSegJs getItem(int index) native;

  _SVGPathSegJs initialize(_SVGPathSegJs newItem) native;

  _SVGPathSegJs insertItemBefore(_SVGPathSegJs newItem, int index) native;

  _SVGPathSegJs removeItem(int index) native;

  _SVGPathSegJs replaceItem(_SVGPathSegJs newItem, int index) native;
}

class _SVGPathSegMovetoAbsJs extends _SVGPathSegJs implements SVGPathSegMovetoAbs native "*SVGPathSegMovetoAbs" {

  num x;

  num y;
}

class _SVGPathSegMovetoRelJs extends _SVGPathSegJs implements SVGPathSegMovetoRel native "*SVGPathSegMovetoRel" {

  num x;

  num y;
}

class _SVGPatternElementJs extends _SVGElementJs implements SVGPatternElement native "*SVGPatternElement" {

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedEnumerationJs patternContentUnits;

  final _SVGAnimatedTransformListJs patternTransform;

  final _SVGAnimatedEnumerationJs patternUnits;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedRectJs viewBox;
}

class _SVGPointJs extends _DOMTypeJs implements SVGPoint native "*SVGPoint" {

  num x;

  num y;

  _SVGPointJs matrixTransform(_SVGMatrixJs matrix) native;
}

class _SVGPointListJs extends _DOMTypeJs implements SVGPointList native "*SVGPointList" {

  final int numberOfItems;

  _SVGPointJs appendItem(_SVGPointJs item) native;

  void clear() native;

  _SVGPointJs getItem(int index) native;

  _SVGPointJs initialize(_SVGPointJs item) native;

  _SVGPointJs insertItemBefore(_SVGPointJs item, int index) native;

  _SVGPointJs removeItem(int index) native;

  _SVGPointJs replaceItem(_SVGPointJs item, int index) native;
}

class _SVGPolygonElementJs extends _SVGElementJs implements SVGPolygonElement native "*SVGPolygonElement" {

  final _SVGPointListJs animatedPoints;

  final _SVGPointListJs points;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGPolylineElementJs extends _SVGElementJs implements SVGPolylineElement native "*SVGPolylineElement" {

  final _SVGPointListJs animatedPoints;

  final _SVGPointListJs points;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGPreserveAspectRatioJs extends _DOMTypeJs implements SVGPreserveAspectRatio native "*SVGPreserveAspectRatio" {

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

class _SVGRadialGradientElementJs extends _SVGGradientElementJs implements SVGRadialGradientElement native "*SVGRadialGradientElement" {

  final _SVGAnimatedLengthJs cx;

  final _SVGAnimatedLengthJs cy;

  final _SVGAnimatedLengthJs fx;

  final _SVGAnimatedLengthJs fy;

  final _SVGAnimatedLengthJs r;
}

class _SVGRectJs extends _DOMTypeJs implements SVGRect native "*SVGRect" {

  num height;

  num width;

  num x;

  num y;
}

class _SVGRectElementJs extends _SVGElementJs implements SVGRectElement native "*SVGRectElement" {

  final _SVGAnimatedLengthJs height;

  final _SVGAnimatedLengthJs rx;

  final _SVGAnimatedLengthJs ry;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGRenderingIntentJs extends _DOMTypeJs implements SVGRenderingIntent native "*SVGRenderingIntent" {

  static final int RENDERING_INTENT_ABSOLUTE_COLORIMETRIC = 5;

  static final int RENDERING_INTENT_AUTO = 1;

  static final int RENDERING_INTENT_PERCEPTUAL = 2;

  static final int RENDERING_INTENT_RELATIVE_COLORIMETRIC = 3;

  static final int RENDERING_INTENT_SATURATION = 4;

  static final int RENDERING_INTENT_UNKNOWN = 0;
}

class _SVGSVGElementJs extends _SVGElementJs implements SVGSVGElement native "*SVGSVGElement" {

  String contentScriptType;

  String contentStyleType;

  num currentScale;

  final _SVGPointJs currentTranslate;

  final _SVGAnimatedLengthJs height;

  final num pixelUnitToMillimeterX;

  final num pixelUnitToMillimeterY;

  final num screenPixelToMillimeterX;

  final num screenPixelToMillimeterY;

  bool useCurrentView;

  final _SVGRectJs viewport;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  bool animationsPaused() native;

  bool checkEnclosure(_SVGElementJs element, _SVGRectJs rect) native;

  bool checkIntersection(_SVGElementJs element, _SVGRectJs rect) native;

  _SVGAngleJs createSVGAngle() native;

  _SVGLengthJs createSVGLength() native;

  _SVGMatrixJs createSVGMatrix() native;

  _SVGNumberJs createSVGNumber() native;

  _SVGPointJs createSVGPoint() native;

  _SVGRectJs createSVGRect() native;

  _SVGTransformJs createSVGTransform() native;

  _SVGTransformJs createSVGTransformFromMatrix(_SVGMatrixJs matrix) native;

  void deselectAll() native;

  void forceRedraw() native;

  num getCurrentTime() native;

  _ElementJs getElementById(String elementId) native;

  _NodeListJs getEnclosureList(_SVGRectJs rect, _SVGElementJs referenceElement) native;

  _NodeListJs getIntersectionList(_SVGRectJs rect, _SVGElementJs referenceElement) native;

  void pauseAnimations() native;

  void setCurrentTime(num seconds) native;

  int suspendRedraw(int maxWaitMilliseconds) native;

  void unpauseAnimations() native;

  void unsuspendRedraw(int suspendHandleId) native;

  void unsuspendRedrawAll() native;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedRectJs viewBox;

  // From SVGZoomAndPan

  int zoomAndPan;
}

class _SVGScriptElementJs extends _SVGElementJs implements SVGScriptElement native "*SVGScriptElement" {

  String type;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;
}

class _SVGSetElementJs extends _SVGAnimationElementJs implements SVGSetElement native "*SVGSetElement" {
}

class _SVGStopElementJs extends _SVGElementJs implements SVGStopElement native "*SVGStopElement" {

  final _SVGAnimatedNumberJs offset;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGStringListJs extends _DOMTypeJs implements SVGStringList native "*SVGStringList" {

  final int numberOfItems;

  String appendItem(String item) native;

  void clear() native;

  String getItem(int index) native;

  String initialize(String item) native;

  String insertItemBefore(String item, int index) native;

  String removeItem(int index) native;

  String replaceItem(String item, int index) native;
}

class _SVGStylableJs extends _DOMTypeJs implements SVGStylable native "*SVGStylable" {

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGStyleElementJs extends _SVGElementJs implements SVGStyleElement native "*SVGStyleElement" {

  String media;

  String title;

  String type;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;
}

class _SVGSwitchElementJs extends _SVGElementJs implements SVGSwitchElement native "*SVGSwitchElement" {

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGSymbolElementJs extends _SVGElementJs implements SVGSymbolElement native "*SVGSymbolElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedRectJs viewBox;
}

class _SVGTRefElementJs extends _SVGTextPositioningElementJs implements SVGTRefElement native "*SVGTRefElement" {

  // From SVGURIReference

  final _SVGAnimatedStringJs href;
}

class _SVGTSpanElementJs extends _SVGTextPositioningElementJs implements SVGTSpanElement native "*SVGTSpanElement" {
}

class _SVGTestsJs extends _DOMTypeJs implements SVGTests native "*SVGTests" {

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;
}

class _SVGTextContentElementJs extends _SVGElementJs implements SVGTextContentElement native "*SVGTextContentElement" {

  static final int LENGTHADJUST_SPACING = 1;

  static final int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static final int LENGTHADJUST_UNKNOWN = 0;

  final _SVGAnimatedEnumerationJs lengthAdjust;

  final _SVGAnimatedLengthJs textLength;

  int getCharNumAtPosition(_SVGPointJs point) native;

  num getComputedTextLength() native;

  _SVGPointJs getEndPositionOfChar(int offset) native;

  _SVGRectJs getExtentOfChar(int offset) native;

  int getNumberOfChars() native;

  num getRotationOfChar(int offset) native;

  _SVGPointJs getStartPositionOfChar(int offset) native;

  num getSubStringLength(int offset, int length) native;

  void selectSubString(int offset, int length) native;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGTextElementJs extends _SVGTextPositioningElementJs implements SVGTextElement native "*SVGTextElement" {

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGTextPathElementJs extends _SVGTextContentElementJs implements SVGTextPathElement native "*SVGTextPathElement" {

  static final int TEXTPATH_METHODTYPE_ALIGN = 1;

  static final int TEXTPATH_METHODTYPE_STRETCH = 2;

  static final int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static final int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static final int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static final int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  final _SVGAnimatedEnumerationJs method;

  final _SVGAnimatedEnumerationJs spacing;

  final _SVGAnimatedLengthJs startOffset;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;
}

class _SVGTextPositioningElementJs extends _SVGTextContentElementJs implements SVGTextPositioningElement native "*SVGTextPositioningElement" {

  final _SVGAnimatedLengthListJs dx;

  final _SVGAnimatedLengthListJs dy;

  final _SVGAnimatedNumberListJs rotate;

  final _SVGAnimatedLengthListJs x;

  final _SVGAnimatedLengthListJs y;
}

class _SVGTitleElementJs extends _SVGElementJs implements SVGTitleElement native "*SVGTitleElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}

class _SVGTransformJs extends _DOMTypeJs implements SVGTransform native "*SVGTransform" {

  static final int SVG_TRANSFORM_MATRIX = 1;

  static final int SVG_TRANSFORM_ROTATE = 4;

  static final int SVG_TRANSFORM_SCALE = 3;

  static final int SVG_TRANSFORM_SKEWX = 5;

  static final int SVG_TRANSFORM_SKEWY = 6;

  static final int SVG_TRANSFORM_TRANSLATE = 2;

  static final int SVG_TRANSFORM_UNKNOWN = 0;

  final num angle;

  final _SVGMatrixJs matrix;

  final int type;

  void setMatrix(_SVGMatrixJs matrix) native;

  void setRotate(num angle, num cx, num cy) native;

  void setScale(num sx, num sy) native;

  void setSkewX(num angle) native;

  void setSkewY(num angle) native;

  void setTranslate(num tx, num ty) native;
}

class _SVGTransformListJs extends _DOMTypeJs implements SVGTransformList native "*SVGTransformList" {

  final int numberOfItems;

  _SVGTransformJs appendItem(_SVGTransformJs item) native;

  void clear() native;

  _SVGTransformJs consolidate() native;

  _SVGTransformJs createSVGTransformFromMatrix(_SVGMatrixJs matrix) native;

  _SVGTransformJs getItem(int index) native;

  _SVGTransformJs initialize(_SVGTransformJs item) native;

  _SVGTransformJs insertItemBefore(_SVGTransformJs item, int index) native;

  _SVGTransformJs removeItem(int index) native;

  _SVGTransformJs replaceItem(_SVGTransformJs item, int index) native;
}

class _SVGTransformableJs extends _SVGLocatableJs implements SVGTransformable native "*SVGTransformable" {

  final _SVGAnimatedTransformListJs transform;
}

class _SVGURIReferenceJs extends _DOMTypeJs implements SVGURIReference native "*SVGURIReference" {

  final _SVGAnimatedStringJs href;
}

class _SVGUnitTypesJs extends _DOMTypeJs implements SVGUnitTypes native "*SVGUnitTypes" {

  static final int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static final int SVG_UNIT_TYPE_UNKNOWN = 0;

  static final int SVG_UNIT_TYPE_USERSPACEONUSE = 1;
}

class _SVGUseElementJs extends _SVGElementJs implements SVGUseElement native "*SVGUseElement" {

  final _SVGElementInstanceJs animatedInstanceRoot;

  final _SVGAnimatedLengthJs height;

  final _SVGElementInstanceJs instanceRoot;

  final _SVGAnimatedLengthJs width;

  final _SVGAnimatedLengthJs x;

  final _SVGAnimatedLengthJs y;

  // From SVGURIReference

  final _SVGAnimatedStringJs href;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  final _SVGAnimatedTransformListJs transform;

  // From SVGLocatable

  final _SVGElementJs farthestViewportElement;

  final _SVGElementJs nearestViewportElement;

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}

class _SVGVKernElementJs extends _SVGElementJs implements SVGVKernElement native "*SVGVKernElement" {
}

class _SVGViewElementJs extends _SVGElementJs implements SVGViewElement native "*SVGViewElement" {

  final _SVGStringListJs viewTarget;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedRectJs viewBox;

  // From SVGZoomAndPan

  int zoomAndPan;
}

class _SVGViewSpecJs extends _SVGZoomAndPanJs implements SVGViewSpec native "*SVGViewSpec" {

  final String preserveAspectRatioString;

  final _SVGTransformListJs transform;

  final String transformString;

  final String viewBoxString;

  final _SVGElementJs viewTarget;

  final String viewTargetString;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioJs preserveAspectRatio;

  final _SVGAnimatedRectJs viewBox;
}

class _SVGZoomAndPanJs extends _DOMTypeJs implements SVGZoomAndPan native "*SVGZoomAndPan" {

  static final int SVG_ZOOMANDPAN_DISABLE = 1;

  static final int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static final int SVG_ZOOMANDPAN_UNKNOWN = 0;

  int zoomAndPan;
}

class _SVGZoomEventJs extends _UIEventJs implements SVGZoomEvent native "*SVGZoomEvent" {

  final num newScale;

  final _SVGPointJs newTranslate;

  final num previousScale;

  final _SVGPointJs previousTranslate;

  final _SVGRectJs zoomRectScreen;
}

class _ScreenJs extends _DOMTypeJs implements Screen native "*Screen" {

  final int availHeight;

  final int availLeft;

  final int availTop;

  final int availWidth;

  final int colorDepth;

  final int height;

  final int pixelDepth;

  final int width;
}

class _ScriptProfileJs extends _DOMTypeJs implements ScriptProfile native "*ScriptProfile" {

  final _ScriptProfileNodeJs head;

  final String title;

  final int uid;
}

class _ScriptProfileNodeJs extends _DOMTypeJs implements ScriptProfileNode native "*ScriptProfileNode" {

  final int callUID;

  final List children;

  final String functionName;

  final int lineNumber;

  final int numberOfCalls;

  final num selfTime;

  final num totalTime;

  final String url;

  final bool visible;
}

class _ShadowRootJs extends _NodeJs implements ShadowRoot native "*ShadowRoot" {

  final _ElementJs host;
}

class _SharedWorkerJs extends _AbstractWorkerJs implements SharedWorker native "*SharedWorker" {

  final _MessagePortJs port;
}

class _SharedWorkerContextJs extends _WorkerContextJs implements SharedWorkerContext native "*SharedWorkerContext" {

  final String name;

  EventListener onconnect;
}

class _SpeechInputEventJs extends _EventJs implements SpeechInputEvent native "*SpeechInputEvent" {

  final _SpeechInputResultListJs results;
}

class _SpeechInputResultJs extends _DOMTypeJs implements SpeechInputResult native "*SpeechInputResult" {

  final num confidence;

  final String utterance;
}

class _SpeechInputResultListJs extends _DOMTypeJs implements SpeechInputResultList native "*SpeechInputResultList" {

  final int length;

  _SpeechInputResultJs item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _StorageJs extends _DOMTypeJs implements Storage native "*Storage" {

  final int length;

  void clear() native;

  String getItem(String key) native;

  String key(int index) native;

  void removeItem(String key) native;

  void setItem(String key, String data) native;


  // Storage needs a special implementation of dartObjectLocalStorage since it
  // captures what would normally be an expando and places property in the
  // storage, stringifying the assigned value.

  var get dartObjectLocalStorage() native """
    if (this === window.localStorage)
      return window._dartLocalStorageLocalStorage;
    else if (this === window.sessionStorage)
      return window._dartSessionStorageLocalStorage;
    else
      throw new UnsupportedOperationException('Cannot dartObjectLocalStorage for unknown Storage object.');
""" { throw new UnsupportedOperationException(''); }

  void set dartObjectLocalStorage(var value) native """
    if (this === window.localStorage)
      window._dartLocalStorageLocalStorage = value;
    else if (this === window.sessionStorage)
      window._dartSessionStorageLocalStorage = value;
    else
      throw new UnsupportedOperationException('Cannot dartObjectLocalStorage for unknown Storage object.');
""" { throw new UnsupportedOperationException(''); }
}

class _StorageEventJs extends _EventJs implements StorageEvent native "*StorageEvent" {

  final String key;

  final String newValue;

  final String oldValue;

  final _StorageJs storageArea;

  final String url;

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, _StorageJs storageAreaArg) native;
}

class _StorageInfoJs extends _DOMTypeJs implements StorageInfo native "*StorageInfo" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback = null, StorageInfoErrorCallback errorCallback = null]) native;

  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback = null, StorageInfoErrorCallback errorCallback = null]) native;
}

class _StyleMediaJs extends _DOMTypeJs implements StyleMedia native "*StyleMedia" {

  final String type;

  bool matchMedium(String mediaquery) native;
}

class _StyleSheetJs extends _DOMTypeJs implements StyleSheet native "*StyleSheet" {

  bool disabled;

  final String href;

  final _MediaListJs media;

  final _NodeJs ownerNode;

  final _StyleSheetJs parentStyleSheet;

  final String title;

  final String type;
}

class _StyleSheetListJs extends _DOMTypeJs implements StyleSheetList native "*StyleSheetList" {

  final int length;

  _StyleSheetJs operator[](int index) native "return this[index];";

  void operator[]=(int index, _StyleSheetJs value) {
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

  _StyleSheetJs item(int index) native;
}

class _TextJs extends _CharacterDataJs implements Text native "*Text" {

  final String wholeText;

  _TextJs replaceWholeText(String content) native;

  _TextJs splitText(int offset) native;
}

class _TextEventJs extends _UIEventJs implements TextEvent native "*TextEvent" {

  final String data;

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, _DOMWindowJs viewArg, String dataArg) native;
}

class _TextMetricsJs extends _DOMTypeJs implements TextMetrics native "*TextMetrics" {

  final num width;
}

class _TextTrackJs extends _DOMTypeJs implements TextTrack native "*TextTrack" {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  final _TextTrackCueListJs activeCues;

  final _TextTrackCueListJs cues;

  final String kind;

  final String label;

  final String language;

  int mode;

  EventListener oncuechange;

  void addCue(_TextTrackCueJs cue) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeCue(_TextTrackCueJs cue) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _TextTrackCueJs extends _DOMTypeJs implements TextTrackCue native "*TextTrackCue" {

  String alignment;

  String direction;

  num endTime;

  String id;

  int linePosition;

  EventListener onenter;

  EventListener onexit;

  bool pauseOnExit;

  int size;

  bool snapToLines;

  num startTime;

  String text;

  int textPosition;

  final _TextTrackJs track;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  _DocumentFragmentJs getCueAsHTML() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _TextTrackCueListJs extends _DOMTypeJs implements TextTrackCueList native "*TextTrackCueList" {

  final int length;

  _TextTrackCueJs getCueById(String id) native;

  _TextTrackCueJs item(int index) native;
}

class _TextTrackListJs extends _DOMTypeJs implements TextTrackList native "*TextTrackList" {

  final int length;

  EventListener onaddtrack;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  _TextTrackJs item(int index) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _TimeRangesJs extends _DOMTypeJs implements TimeRanges native "*TimeRanges" {

  final int length;

  num end(int index) native;

  num start(int index) native;
}

class _TouchJs extends _DOMTypeJs implements Touch native "*Touch" {

  final int clientX;

  final int clientY;

  final int identifier;

  final int pageX;

  final int pageY;

  final int screenX;

  final int screenY;

  final _EventTargetJs target;

  final num webkitForce;

  final int webkitRadiusX;

  final int webkitRadiusY;

  final num webkitRotationAngle;
}

class _TouchEventJs extends _UIEventJs implements TouchEvent native "*TouchEvent" {

  final bool altKey;

  final _TouchListJs changedTouches;

  final bool ctrlKey;

  final bool metaKey;

  final bool shiftKey;

  final _TouchListJs targetTouches;

  final _TouchListJs touches;

  void initTouchEvent(_TouchListJs touches, _TouchListJs targetTouches, _TouchListJs changedTouches, String type, _DOMWindowJs view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}

class _TouchListJs extends _DOMTypeJs implements TouchList native "*TouchList" {

  final int length;

  _TouchJs operator[](int index) native "return this[index];";

  void operator[]=(int index, _TouchJs value) {
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

  _TouchJs item(int index) native;
}

class _TrackEventJs extends _EventJs implements TrackEvent native "*TrackEvent" {

  final Object track;
}

class _TreeWalkerJs extends _DOMTypeJs implements TreeWalker native "*TreeWalker" {

  _NodeJs currentNode;

  final bool expandEntityReferences;

  final _NodeFilterJs filter;

  final _NodeJs root;

  final int whatToShow;

  _NodeJs firstChild() native;

  _NodeJs lastChild() native;

  _NodeJs nextNode() native;

  _NodeJs nextSibling() native;

  _NodeJs parentNode() native;

  _NodeJs previousNode() native;

  _NodeJs previousSibling() native;
}

class _UIEventJs extends _EventJs implements UIEvent native "*UIEvent" {

  final int charCode;

  final int detail;

  final int keyCode;

  final int layerX;

  final int layerY;

  final int pageX;

  final int pageY;

  final _DOMWindowJs view;

  final int which;

  void initUIEvent(String type, bool canBubble, bool cancelable, _DOMWindowJs view, int detail) native;
}

class _Uint16ArrayJs extends _ArrayBufferViewJs implements Uint16Array, List<int> native "*Uint16Array" {

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

  _Uint16ArrayJs subarray(int start, [int end = null]) native;
}

class _Uint32ArrayJs extends _ArrayBufferViewJs implements Uint32Array, List<int> native "*Uint32Array" {

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

  _Uint32ArrayJs subarray(int start, [int end = null]) native;
}

class _Uint8ArrayJs extends _ArrayBufferViewJs implements Uint8Array, List<int> native "*Uint8Array" {

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

  _Uint8ArrayJs subarray(int start, [int end = null]) native;
}

class _Uint8ClampedArrayJs extends _Uint8ArrayJs implements Uint8ClampedArray, List<int> native "*Uint8ClampedArray" {

  factory Uint8ClampedArray(int length) =>  _construct_Uint8ClampedArray(length);

  factory Uint8ClampedArray.fromList(List<int> list) => _construct_Uint8ClampedArray(list);

  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer) => _construct_Uint8ClampedArray(buffer);

  static _construct_Uint8ClampedArray(arg) native 'return new Uint8ClampedArray(arg);';

  final int length;

  _Uint8ClampedArrayJs subarray(int start, [int end = null]) native;
}

class _ValidityStateJs extends _DOMTypeJs implements ValidityState native "*ValidityState" {

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

class _WaveShaperNodeJs extends _AudioNodeJs implements WaveShaperNode native "*WaveShaperNode" {

  _Float32ArrayJs curve;
}

class _WebGLActiveInfoJs extends _DOMTypeJs implements WebGLActiveInfo native "*WebGLActiveInfo" {

  final String name;

  final int size;

  final int type;
}

class _WebGLBufferJs extends _DOMTypeJs implements WebGLBuffer native "*WebGLBuffer" {
}

class _WebGLCompressedTexturesJs extends _DOMTypeJs implements WebGLCompressedTextures native "*WebGLCompressedTextures" {

  static final int COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;

  static final int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  static final int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  static final int COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;

  static final int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;

  static final int ETC1_RGB8_OES = 0x8D64;

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, _ArrayBufferViewJs data) native;

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, _ArrayBufferViewJs data) native;
}

class _WebGLContextAttributesJs extends _DOMTypeJs implements WebGLContextAttributes native "*WebGLContextAttributes" {

  bool alpha;

  bool antialias;

  bool depth;

  bool premultipliedAlpha;

  bool preserveDrawingBuffer;

  bool stencil;
}

class _WebGLContextEventJs extends _EventJs implements WebGLContextEvent native "*WebGLContextEvent" {

  final String statusMessage;
}

class _WebGLDebugRendererInfoJs extends _DOMTypeJs implements WebGLDebugRendererInfo native "*WebGLDebugRendererInfo" {

  static final int UNMASKED_RENDERER_WEBGL = 0x9246;

  static final int UNMASKED_VENDOR_WEBGL = 0x9245;
}

class _WebGLDebugShadersJs extends _DOMTypeJs implements WebGLDebugShaders native "*WebGLDebugShaders" {

  String getTranslatedShaderSource(_WebGLShaderJs shader) native;
}

class _WebGLFramebufferJs extends _DOMTypeJs implements WebGLFramebuffer native "*WebGLFramebuffer" {
}

class _WebGLLoseContextJs extends _DOMTypeJs implements WebGLLoseContext native "*WebGLLoseContext" {

  void loseContext() native;

  void restoreContext() native;
}

class _WebGLProgramJs extends _DOMTypeJs implements WebGLProgram native "*WebGLProgram" {
}

class _WebGLRenderbufferJs extends _DOMTypeJs implements WebGLRenderbuffer native "*WebGLRenderbuffer" {
}

class _WebGLRenderingContextJs extends _CanvasRenderingContextJs implements WebGLRenderingContext native "*WebGLRenderingContext" {

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

  final int drawingBufferHeight;

  final int drawingBufferWidth;

  void activeTexture(int texture) native;

  void attachShader(_WebGLProgramJs program, _WebGLShaderJs shader) native;

  void bindAttribLocation(_WebGLProgramJs program, int index, String name) native;

  void bindBuffer(int target, _WebGLBufferJs buffer) native;

  void bindFramebuffer(int target, _WebGLFramebufferJs framebuffer) native;

  void bindRenderbuffer(int target, _WebGLRenderbufferJs renderbuffer) native;

  void bindTexture(int target, _WebGLTextureJs texture) native;

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

  void compileShader(_WebGLShaderJs shader) native;

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, _ArrayBufferViewJs data) native;

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, _ArrayBufferViewJs data) native;

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) native;

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) native;

  _WebGLBufferJs createBuffer() native;

  _WebGLFramebufferJs createFramebuffer() native;

  _WebGLProgramJs createProgram() native;

  _WebGLRenderbufferJs createRenderbuffer() native;

  _WebGLShaderJs createShader(int type) native;

  _WebGLTextureJs createTexture() native;

  void cullFace(int mode) native;

  void deleteBuffer(_WebGLBufferJs buffer) native;

  void deleteFramebuffer(_WebGLFramebufferJs framebuffer) native;

  void deleteProgram(_WebGLProgramJs program) native;

  void deleteRenderbuffer(_WebGLRenderbufferJs renderbuffer) native;

  void deleteShader(_WebGLShaderJs shader) native;

  void deleteTexture(_WebGLTextureJs texture) native;

  void depthFunc(int func) native;

  void depthMask(bool flag) native;

  void depthRange(num zNear, num zFar) native;

  void detachShader(_WebGLProgramJs program, _WebGLShaderJs shader) native;

  void disable(int cap) native;

  void disableVertexAttribArray(int index) native;

  void drawArrays(int mode, int first, int count) native;

  void drawElements(int mode, int count, int type, int offset) native;

  void enable(int cap) native;

  void enableVertexAttribArray(int index) native;

  void finish() native;

  void flush() native;

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, _WebGLRenderbufferJs renderbuffer) native;

  void framebufferTexture2D(int target, int attachment, int textarget, _WebGLTextureJs texture, int level) native;

  void frontFace(int mode) native;

  void generateMipmap(int target) native;

  _WebGLActiveInfoJs getActiveAttrib(_WebGLProgramJs program, int index) native;

  _WebGLActiveInfoJs getActiveUniform(_WebGLProgramJs program, int index) native;

  List getAttachedShaders(_WebGLProgramJs program) native;

  int getAttribLocation(_WebGLProgramJs program, String name) native;

  Object getBufferParameter(int target, int pname) native;

  _WebGLContextAttributesJs getContextAttributes() native;

  int getError() native;

  Object getExtension(String name) native;

  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) native;

  Object getParameter(int pname) native;

  String getProgramInfoLog(_WebGLProgramJs program) native;

  Object getProgramParameter(_WebGLProgramJs program, int pname) native;

  Object getRenderbufferParameter(int target, int pname) native;

  String getShaderInfoLog(_WebGLShaderJs shader) native;

  Object getShaderParameter(_WebGLShaderJs shader, int pname) native;

  String getShaderSource(_WebGLShaderJs shader) native;

  Object getTexParameter(int target, int pname) native;

  Object getUniform(_WebGLProgramJs program, _WebGLUniformLocationJs location) native;

  _WebGLUniformLocationJs getUniformLocation(_WebGLProgramJs program, String name) native;

  Object getVertexAttrib(int index, int pname) native;

  int getVertexAttribOffset(int index, int pname) native;

  void hint(int target, int mode) native;

  bool isBuffer(_WebGLBufferJs buffer) native;

  bool isContextLost() native;

  bool isEnabled(int cap) native;

  bool isFramebuffer(_WebGLFramebufferJs framebuffer) native;

  bool isProgram(_WebGLProgramJs program) native;

  bool isRenderbuffer(_WebGLRenderbufferJs renderbuffer) native;

  bool isShader(_WebGLShaderJs shader) native;

  bool isTexture(_WebGLTextureJs texture) native;

  void lineWidth(num width) native;

  void linkProgram(_WebGLProgramJs program) native;

  void pixelStorei(int pname, int param) native;

  void polygonOffset(num factor, num units) native;

  void readPixels(int x, int y, int width, int height, int format, int type, _ArrayBufferViewJs pixels) native;

  void releaseShaderCompiler() native;

  void renderbufferStorage(int target, int internalformat, int width, int height) native;

  void sampleCoverage(num value, bool invert) native;

  void scissor(int x, int y, int width, int height) native;

  void shaderSource(_WebGLShaderJs shader, String string) native;

  void stencilFunc(int func, int ref, int mask) native;

  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  void stencilMask(int mask) native;

  void stencilMaskSeparate(int face, int mask) native;

  void stencilOp(int fail, int zfail, int zpass) native;

  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels_OR_video, [int format = null, int type = null, _ArrayBufferViewJs pixels = null]) native;

  void texParameterf(int target, int pname, num param) native;

  void texParameteri(int target, int pname, int param) native;

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels_OR_video, [int type = null, _ArrayBufferViewJs pixels = null]) native;

  void uniform1f(_WebGLUniformLocationJs location, num x) native;

  void uniform1fv(_WebGLUniformLocationJs location, _Float32ArrayJs v) native;

  void uniform1i(_WebGLUniformLocationJs location, int x) native;

  void uniform1iv(_WebGLUniformLocationJs location, _Int32ArrayJs v) native;

  void uniform2f(_WebGLUniformLocationJs location, num x, num y) native;

  void uniform2fv(_WebGLUniformLocationJs location, _Float32ArrayJs v) native;

  void uniform2i(_WebGLUniformLocationJs location, int x, int y) native;

  void uniform2iv(_WebGLUniformLocationJs location, _Int32ArrayJs v) native;

  void uniform3f(_WebGLUniformLocationJs location, num x, num y, num z) native;

  void uniform3fv(_WebGLUniformLocationJs location, _Float32ArrayJs v) native;

  void uniform3i(_WebGLUniformLocationJs location, int x, int y, int z) native;

  void uniform3iv(_WebGLUniformLocationJs location, _Int32ArrayJs v) native;

  void uniform4f(_WebGLUniformLocationJs location, num x, num y, num z, num w) native;

  void uniform4fv(_WebGLUniformLocationJs location, _Float32ArrayJs v) native;

  void uniform4i(_WebGLUniformLocationJs location, int x, int y, int z, int w) native;

  void uniform4iv(_WebGLUniformLocationJs location, _Int32ArrayJs v) native;

  void uniformMatrix2fv(_WebGLUniformLocationJs location, bool transpose, _Float32ArrayJs array) native;

  void uniformMatrix3fv(_WebGLUniformLocationJs location, bool transpose, _Float32ArrayJs array) native;

  void uniformMatrix4fv(_WebGLUniformLocationJs location, bool transpose, _Float32ArrayJs array) native;

  void useProgram(_WebGLProgramJs program) native;

  void validateProgram(_WebGLProgramJs program) native;

  void vertexAttrib1f(int indx, num x) native;

  void vertexAttrib1fv(int indx, _Float32ArrayJs values) native;

  void vertexAttrib2f(int indx, num x, num y) native;

  void vertexAttrib2fv(int indx, _Float32ArrayJs values) native;

  void vertexAttrib3f(int indx, num x, num y, num z) native;

  void vertexAttrib3fv(int indx, _Float32ArrayJs values) native;

  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  void vertexAttrib4fv(int indx, _Float32ArrayJs values) native;

  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) native;

  void viewport(int x, int y, int width, int height) native;
}

class _WebGLShaderJs extends _DOMTypeJs implements WebGLShader native "*WebGLShader" {
}

class _WebGLTextureJs extends _DOMTypeJs implements WebGLTexture native "*WebGLTexture" {
}

class _WebGLUniformLocationJs extends _DOMTypeJs implements WebGLUniformLocation native "*WebGLUniformLocation" {
}

class _WebGLVertexArrayObjectOESJs extends _DOMTypeJs implements WebGLVertexArrayObjectOES native "*WebGLVertexArrayObjectOES" {
}

class _WebKitAnimationJs extends _DOMTypeJs implements WebKitAnimation native "*WebKitAnimation" {

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

class _WebKitAnimationEventJs extends _EventJs implements WebKitAnimationEvent native "*WebKitAnimationEvent" {

  final String animationName;

  final num elapsedTime;
}

class _WebKitAnimationListJs extends _DOMTypeJs implements WebKitAnimationList native "*WebKitAnimationList" {

  final int length;

  _WebKitAnimationJs item(int index) native;
}

class _WebKitBlobBuilderJs extends _DOMTypeJs implements WebKitBlobBuilder native "*WebKitBlobBuilder" {

  void append(var arrayBuffer_OR_blob_OR_value, [String endings = null]) native;

  _BlobJs getBlob([String contentType = null]) native;
}

class _WebKitCSSFilterValueJs extends _CSSValueListJs implements WebKitCSSFilterValue native "*WebKitCSSFilterValue" {

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

  final int operationType;
}

class _WebKitCSSKeyframeRuleJs extends _CSSRuleJs implements WebKitCSSKeyframeRule native "*WebKitCSSKeyframeRule" {

  String keyText;

  final _CSSStyleDeclarationJs style;
}

class _WebKitCSSKeyframesRuleJs extends _CSSRuleJs implements WebKitCSSKeyframesRule native "*WebKitCSSKeyframesRule" {

  final _CSSRuleListJs cssRules;

  String name;

  void deleteRule(String key) native;

  _WebKitCSSKeyframeRuleJs findRule(String key) native;

  void insertRule(String rule) native;
}

class _WebKitCSSMatrixJs extends _DOMTypeJs implements WebKitCSSMatrix native "*WebKitCSSMatrix" {
  WebKitCSSMatrix([String spec]) native;


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

  _WebKitCSSMatrixJs inverse() native;

  _WebKitCSSMatrixJs multiply(_WebKitCSSMatrixJs secondMatrix) native;

  _WebKitCSSMatrixJs rotate(num rotX, num rotY, num rotZ) native;

  _WebKitCSSMatrixJs rotateAxisAngle(num x, num y, num z, num angle) native;

  _WebKitCSSMatrixJs scale(num scaleX, num scaleY, num scaleZ) native;

  void setMatrixValue(String string) native;

  _WebKitCSSMatrixJs skewX(num angle) native;

  _WebKitCSSMatrixJs skewY(num angle) native;

  String toString() native;

  _WebKitCSSMatrixJs translate(num x, num y, num z) native;
}

class _WebKitCSSRegionRuleJs extends _CSSRuleJs implements WebKitCSSRegionRule native "*WebKitCSSRegionRule" {

  final _CSSRuleListJs cssRules;
}

class _WebKitCSSTransformValueJs extends _CSSValueListJs implements WebKitCSSTransformValue native "*WebKitCSSTransformValue" {

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

class _WebKitMutationObserverJs extends _DOMTypeJs implements WebKitMutationObserver native "*WebKitMutationObserver" {

  void disconnect() native;
}

class _WebKitNamedFlowJs extends _DOMTypeJs implements WebKitNamedFlow native "*WebKitNamedFlow" {
}

class _WebKitPointJs extends _DOMTypeJs implements WebKitPoint native "*WebKitPoint" {
  WebKitPoint(num x, num y) native;


  num x;

  num y;
}

class _WebKitTransitionEventJs extends _EventJs implements WebKitTransitionEvent native "*WebKitTransitionEvent" {

  final num elapsedTime;

  final String propertyName;
}

class _WebSocketJs extends _DOMTypeJs implements WebSocket native "*WebSocket" {
  WebSocket(String url) native;


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

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close([int code = null, String reason = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool send(String data) native;
}

class _WheelEventJs extends _UIEventJs implements WheelEvent native "*WheelEvent" {

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

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, _DOMWindowJs view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}

class _WorkerJs extends _AbstractWorkerJs implements Worker native "*Worker" {

  void postMessage(Dynamic message, [List messagePorts = null]) native;

  void terminate() native;

  void webkitPostMessage(Dynamic message, [List messagePorts = null]) native;
}

class _WorkerContextJs extends _DOMTypeJs implements WorkerContext native "*WorkerContext" {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  _WorkerLocationJs location;

  _WorkerNavigatorJs navigator;

  EventListener onerror;

  _WorkerContextJs self;

  final _IDBFactoryJs webkitIndexedDB;

  final _NotificationCenterJs webkitNotifications;

  final _DOMURLJs webkitURL;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool dispatchEvent(_EventJs evt) native;

  void importScripts() native;

  _DatabaseJs openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  _DatabaseSyncJs openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  _DOMFileSystemSyncJs webkitRequestFileSystemSync(int type, int size) native;

  _EntrySyncJs webkitResolveLocalFileSystemSyncURL(String url) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;
}

class _WorkerLocationJs extends _DOMTypeJs implements WorkerLocation native "*WorkerLocation" {

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

class _WorkerNavigatorJs extends _DOMTypeJs implements WorkerNavigator native "*WorkerNavigator" {

  final String appName;

  final String appVersion;

  final bool onLine;

  final String platform;

  final String userAgent;
}

class _XMLHttpRequestJs extends _DOMTypeJs implements XMLHttpRequest native "*XMLHttpRequest" {
  XMLHttpRequest() native;


  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  bool asBlob;

  final int readyState;

  final Object response;

  final _BlobJs responseBlob;

  final String responseText;

  String responseType;

  final _DocumentJs responseXML;

  final int status;

  final String statusText;

  final _XMLHttpRequestUploadJs upload;

  bool withCredentials;

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  String getAllResponseHeaders() native;

  String getResponseHeader(String header) native;

  void open(String method, String url, [bool async = null, String user = null, String password = null]) native;

  void overrideMimeType(String override) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void send([var data = null]) native;

  void setRequestHeader(String header, String value) native;
}

class _XMLHttpRequestExceptionJs extends _DOMTypeJs implements XMLHttpRequestException native "*XMLHttpRequestException" {

  static final int ABORT_ERR = 102;

  static final int NETWORK_ERR = 101;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _XMLHttpRequestProgressEventJs extends _ProgressEventJs implements XMLHttpRequestProgressEvent native "*XMLHttpRequestProgressEvent" {

  final int position;

  final int totalSize;
}

class _XMLHttpRequestUploadJs extends _DOMTypeJs implements XMLHttpRequestUpload native "*XMLHttpRequestUpload" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}

class _XMLSerializerJs extends _DOMTypeJs implements XMLSerializer native "*XMLSerializer" {

  String serializeToString(_NodeJs node) native;
}

class _XPathEvaluatorJs extends _DOMTypeJs implements XPathEvaluator native "*XPathEvaluator" {

  _XPathExpressionJs createExpression(String expression, _XPathNSResolverJs resolver) native;

  _XPathNSResolverJs createNSResolver(_NodeJs nodeResolver) native;

  _XPathResultJs evaluate(String expression, _NodeJs contextNode, _XPathNSResolverJs resolver, int type, _XPathResultJs inResult) native;
}

class _XPathExceptionJs extends _DOMTypeJs implements XPathException native "*XPathException" {

  static final int INVALID_EXPRESSION_ERR = 51;

  static final int TYPE_ERR = 52;

  final int code;

  final String message;

  final String name;

  String toString() native;
}

class _XPathExpressionJs extends _DOMTypeJs implements XPathExpression native "*XPathExpression" {

  _XPathResultJs evaluate(_NodeJs contextNode, int type, _XPathResultJs inResult) native;
}

class _XPathNSResolverJs extends _DOMTypeJs implements XPathNSResolver native "*XPathNSResolver" {

  String lookupNamespaceURI(String prefix) native;
}

class _XPathResultJs extends _DOMTypeJs implements XPathResult native "*XPathResult" {

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

  final _NodeJs singleNodeValue;

  final int snapshotLength;

  final String stringValue;

  _NodeJs iterateNext() native;

  _NodeJs snapshotItem(int index) native;
}

class _XSLTProcessorJs extends _DOMTypeJs implements XSLTProcessor native "*XSLTProcessor" {

  void clearParameters() native;

  String getParameter(String namespaceURI, String localName) native;

  void importStylesheet(_NodeJs stylesheet) native;

  void removeParameter(String namespaceURI, String localName) native;

  void reset() native;

  void setParameter(String namespaceURI, String localName, String value) native;

  _DocumentJs transformToDocument(_NodeJs source) native;

  _DocumentFragmentJs transformToFragment(_NodeJs source, _DocumentJs docVal) native;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AbstractWorker extends EventTarget {

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ArrayBuffer {

  int get byteLength();

  ArrayBuffer slice(int begin, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ArrayBufferView {

  ArrayBuffer get buffer();

  int get byteLength();

  int get byteOffset();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Attr extends Node {

  bool get isId();

  String get name();

  Element get ownerElement();

  bool get specified();

  String get value();

  void set value(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioBuffer {

  num get duration();

  num get gain();

  void set gain(num value);

  int get length();

  int get numberOfChannels();

  num get sampleRate();

  Float32Array getChannelData(int channelIndex);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool AudioBufferCallback(AudioBuffer audioBuffer);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioBufferSourceNode extends AudioSourceNode {

  AudioBuffer get buffer();

  void set buffer(AudioBuffer value);

  AudioGain get gain();

  bool get loop();

  void set loop(bool value);

  bool get looping();

  void set looping(bool value);

  AudioParam get playbackRate();

  void noteGrainOn(num when, num grainOffset, num grainDuration);

  void noteOff(num when);

  void noteOn(num when);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioChannelMerger extends AudioNode {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioChannelSplitter extends AudioNode {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioContext default _AudioContextFactoryProvider {

  AudioContext();

  num get currentTime();

  AudioDestinationNode get destination();

  AudioListener get listener();

  EventListener get oncomplete();

  void set oncomplete(EventListener value);

  num get sampleRate();

  RealtimeAnalyserNode createAnalyser();

  BiquadFilterNode createBiquadFilter();

  AudioBuffer createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate]);

  AudioBufferSourceNode createBufferSource();

  AudioChannelMerger createChannelMerger();

  AudioChannelSplitter createChannelSplitter();

  ConvolverNode createConvolver();

  DelayNode createDelayNode();

  DynamicsCompressorNode createDynamicsCompressor();

  AudioGainNode createGainNode();

  HighPass2FilterNode createHighPass2Filter();

  JavaScriptAudioNode createJavaScriptNode(int bufferSize);

  LowPass2FilterNode createLowPass2Filter();

  MediaElementAudioSourceNode createMediaElementSource(HTMLMediaElement mediaElement);

  AudioPannerNode createPanner();

  WaveShaperNode createWaveShaper();

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]);

  void startRendering();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioDestinationNode extends AudioNode {

  int get numberOfChannels();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioGain extends AudioParam {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioGainNode extends AudioNode {

  AudioGain get gain();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioListener {

  num get dopplerFactor();

  void set dopplerFactor(num value);

  num get speedOfSound();

  void set speedOfSound(num value);

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp);

  void setPosition(num x, num y, num z);

  void setVelocity(num x, num y, num z);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioNode {

  AudioContext get context();

  int get numberOfInputs();

  int get numberOfOutputs();

  void connect(AudioNode destination, int output, int input);

  void disconnect(int output);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioPannerNode extends AudioNode {

  static final int EQUALPOWER = 0;

  static final int HRTF = 1;

  static final int SOUNDFIELD = 2;

  AudioGain get coneGain();

  num get coneInnerAngle();

  void set coneInnerAngle(num value);

  num get coneOuterAngle();

  void set coneOuterAngle(num value);

  num get coneOuterGain();

  void set coneOuterGain(num value);

  AudioGain get distanceGain();

  int get distanceModel();

  void set distanceModel(int value);

  num get maxDistance();

  void set maxDistance(num value);

  int get panningModel();

  void set panningModel(int value);

  num get refDistance();

  void set refDistance(num value);

  num get rolloffFactor();

  void set rolloffFactor(num value);

  void setOrientation(num x, num y, num z);

  void setPosition(num x, num y, num z);

  void setVelocity(num x, num y, num z);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioParam {

  num get defaultValue();

  num get maxValue();

  num get minValue();

  String get name();

  int get units();

  num get value();

  void set value(num value);

  void cancelScheduledValues(num startTime);

  void exponentialRampToValueAtTime(num value, num time);

  void linearRampToValueAtTime(num value, num time);

  void setTargetValueAtTime(num targetValue, num time, num timeConstant);

  void setValueAtTime(num value, num time);

  void setValueCurveAtTime(Float32Array values, num time, num duration);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioProcessingEvent extends Event {

  AudioBuffer get inputBuffer();

  AudioBuffer get outputBuffer();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioSourceNode extends AudioNode {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BarProp {

  bool get visible();
}

interface BarInfo extends BarProp {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BeforeLoadEvent extends Event {

  String get url();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  AudioParam get Q();

  AudioParam get frequency();

  AudioParam get gain();

  int get type();

  void set type(int value);

  void getFrequencyResponse(Float32Array frequencyHz, Float32Array magResponse, Float32Array phaseResponse);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Blob {

  int get size();

  String get type();

  Blob webkitSlice([int start, int end, String contentType]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CDATASection extends Text {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSCharsetRule extends CSSRule {

  String get encoding();

  void set encoding(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSFontFaceRule extends CSSRule {

  CSSStyleDeclaration get style();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSImportRule extends CSSRule {

  String get href();

  MediaList get media();

  CSSStyleSheet get styleSheet();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSMediaRule extends CSSRule {

  CSSRuleList get cssRules();

  MediaList get media();

  void deleteRule(int index);

  int insertRule(String rule, int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSPageRule extends CSSRule {

  String get selectorText();

  void set selectorText(String value);

  CSSStyleDeclaration get style();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get primitiveType();

  Counter getCounterValue();

  num getFloatValue(int unitType);

  RGBColor getRGBColorValue();

  Rect getRectValue();

  String getStringValue();

  void setFloatValue(int unitType, num floatValue);

  void setStringValue(int stringType, String stringValue);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  static final int WEBKIT_KEYFRAMES_RULE = 8;

  static final int WEBKIT_KEYFRAME_RULE = 9;

  static final int WEBKIT_REGION_RULE = 10;

  String get cssText();

  void set cssText(String value);

  CSSRule get parentRule();

  CSSStyleSheet get parentStyleSheet();

  int get type();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSRuleList {

  int get length();

  CSSRule item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSStyleDeclaration {

  String get cssText();

  void set cssText(String value);

  int get length();

  CSSRule get parentRule();

  CSSValue getPropertyCSSValue(String propertyName);

  String getPropertyPriority(String propertyName);

  String getPropertyShorthand(String propertyName);

  String getPropertyValue(String propertyName);

  bool isPropertyImplicit(String propertyName);

  String item(int index);

  String removeProperty(String propertyName);

  void setProperty(String propertyName, String value, [String priority]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSStyleRule extends CSSRule {

  String get selectorText();

  void set selectorText(String value);

  CSSStyleDeclaration get style();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSStyleSheet extends StyleSheet {

  CSSRuleList get cssRules();

  CSSRule get ownerRule();

  CSSRuleList get rules();

  int addRule(String selector, String style, [int index]);

  void deleteRule(int index);

  int insertRule(String rule, int index);

  void removeRule(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSUnknownRule extends CSSRule {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSValue {

  static final int CSS_CUSTOM = 3;

  static final int CSS_INHERIT = 0;

  static final int CSS_PRIMITIVE_VALUE = 1;

  static final int CSS_VALUE_LIST = 2;

  String get cssText();

  void set cssText(String value);

  int get cssValueType();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSValueList extends CSSValue {

  int get length();

  CSSValue item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasGradient {

  void addColorStop(num offset, String color);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasPattern {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasPixelArray extends List<int> {

  int get length();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasRenderingContext {

  HTMLCanvasElement get canvas();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasRenderingContext2D extends CanvasRenderingContext {

  Dynamic get fillStyle();

  void set fillStyle(Dynamic value);

  String get font();

  void set font(String value);

  num get globalAlpha();

  void set globalAlpha(num value);

  String get globalCompositeOperation();

  void set globalCompositeOperation(String value);

  String get lineCap();

  void set lineCap(String value);

  String get lineJoin();

  void set lineJoin(String value);

  num get lineWidth();

  void set lineWidth(num value);

  num get miterLimit();

  void set miterLimit(num value);

  num get shadowBlur();

  void set shadowBlur(num value);

  String get shadowColor();

  void set shadowColor(String value);

  num get shadowOffsetX();

  void set shadowOffsetX(num value);

  num get shadowOffsetY();

  void set shadowOffsetY(num value);

  Dynamic get strokeStyle();

  void set strokeStyle(Dynamic value);

  String get textAlign();

  void set textAlign(String value);

  String get textBaseline();

  void set textBaseline(String value);

  List get webkitLineDash();

  void set webkitLineDash(List value);

  num get webkitLineDashOffset();

  void set webkitLineDashOffset(num value);

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

  void drawImageFromRect(HTMLImageElement image, [num sx, num sy, num sw, num sh, num dx, num dy, num dw, num dh, String compositeOperation]);

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CharacterData extends Node {

  String get data();

  void set data(String value);

  int get length();

  void appendData(String data);

  void deleteData(int offset, int length);

  void insertData(int offset, String data);

  void replaceData(int offset, int length, String data);

  String substringData(int offset, int length);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ClientRect {

  num get bottom();

  num get height();

  num get left();

  num get right();

  num get top();

  num get width();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ClientRectList {

  int get length();

  ClientRect item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Clipboard {

  String get dropEffect();

  void set dropEffect(String value);

  String get effectAllowed();

  void set effectAllowed(String value);

  FileList get files();

  DataTransferItemList get items();

  List get types();

  void clearData([String type]);

  void getData(String type);

  bool setData(String type, String data);

  void setDragImage(HTMLImageElement image, int x, int y);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CloseEvent extends Event {

  int get code();

  String get reason();

  bool get wasClean();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Comment extends CharacterData {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CompositionEvent extends UIEvent {

  String get data();

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindow viewArg, String dataArg);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Console {

  MemoryInfo get memory();

  List get profiles();

  void assertCondition(bool condition);

  void count();

  void debug(Object arg);

  void dir();

  void dirxml();

  void error(Object arg);

  void group();

  void groupCollapsed();

  void groupEnd();

  void info(Object arg);

  void log(Object arg);

  void markTimeline();

  void profile(String title);

  void profileEnd(String title);

  void time(String title);

  void timeEnd(String title);

  void timeStamp();

  void trace(Object arg);

  void warn(Object arg);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ConvolverNode extends AudioNode {

  AudioBuffer get buffer();

  void set buffer(AudioBuffer value);

  bool get normalize();

  void set normalize(bool value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Coordinates {

  num get accuracy();

  num get altitude();

  num get altitudeAccuracy();

  num get heading();

  num get latitude();

  num get longitude();

  num get speed();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Counter {

  String get identifier();

  String get listStyle();

  String get separator();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Crypto {

  void getRandomValues(ArrayBufferView array);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CustomEvent extends Event {

  Object get detail();

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ApplicationCache extends EventTarget {

  int get status();

  void abort();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  void swapCache();

  void update();
}

interface DOMApplicationCache extends ApplicationCache {

  static final int CHECKING = 2;

  static final int DOWNLOADING = 3;

  static final int IDLE = 1;

  static final int OBSOLETE = 5;

  static final int UNCACHED = 0;

  static final int UPDATEREADY = 4;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get code();

  String get message();

  String get name();

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMFileSystem {

  String get name();

  DirectoryEntry get root();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMFileSystemSync {

  String get name();

  DirectoryEntrySync get root();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FormData {

  void append(String name, String value, String filename);
}

interface DOMFormData extends FormData {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMImplementation {

  CSSStyleSheet createCSSStyleSheet(String title, String media);

  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype);

  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId);

  HTMLDocument createHTMLDocument(String title);

  bool hasFeature(String feature, String version);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMMimeType {

  String get description();

  DOMPlugin get enabledPlugin();

  String get suffixes();

  String get type();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMMimeTypeArray {

  int get length();

  DOMMimeType item(int index);

  DOMMimeType namedItem(String name);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMParser default _DOMParserFactoryProvider {

  DOMParser();

  Document parseFromString(String str, String contentType);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMPlugin {

  String get description();

  String get filename();

  int get length();

  String get name();

  DOMMimeType item(int index);

  DOMMimeType namedItem(String name);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMPluginArray {

  int get length();

  DOMPlugin item(int index);

  DOMPlugin namedItem(String name);

  void refresh(bool reload);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Selection {

  Node get anchorNode();

  int get anchorOffset();

  Node get baseNode();

  int get baseOffset();

  Node get extentNode();

  int get extentOffset();

  Node get focusNode();

  int get focusOffset();

  bool get isCollapsed();

  int get rangeCount();

  String get type();

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

interface DOMSelection extends Selection {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMSettableTokenList extends DOMTokenList {

  String get value();

  void set value(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMTokenList {

  int get length();

  void add(String token);

  bool contains(String token);

  String item(int index);

  void remove(String token);

  String toString();

  bool toggle(String token);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMURL {

  String createObjectURL(Blob blob);

  void revokeObjectURL(String url);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Window extends EventTarget {

  DOMApplicationCache get applicationCache();

  Navigator get clientInformation();

  void set clientInformation(Navigator value);

  bool get closed();

  Console get console();

  void set console(Console value);

  Crypto get crypto();

  String get defaultStatus();

  void set defaultStatus(String value);

  String get defaultstatus();

  void set defaultstatus(String value);

  num get devicePixelRatio();

  void set devicePixelRatio(num value);

  Document get document();

  Event get event();

  void set event(Event value);

  Element get frameElement();

  DOMWindow get frames();

  void set frames(DOMWindow value);

  History get history();

  void set history(History value);

  int get innerHeight();

  void set innerHeight(int value);

  int get innerWidth();

  void set innerWidth(int value);

  int get length();

  void set length(int value);

  Storage get localStorage();

  Location get location();

  void set location(Location value);

  BarInfo get locationbar();

  void set locationbar(BarInfo value);

  BarInfo get menubar();

  void set menubar(BarInfo value);

  String get name();

  void set name(String value);

  Navigator get navigator();

  void set navigator(Navigator value);

  bool get offscreenBuffering();

  void set offscreenBuffering(bool value);

  DOMWindow get opener();

  void set opener(DOMWindow value);

  int get outerHeight();

  void set outerHeight(int value);

  int get outerWidth();

  void set outerWidth(int value);

  int get pageXOffset();

  int get pageYOffset();

  DOMWindow get parent();

  void set parent(DOMWindow value);

  Performance get performance();

  void set performance(Performance value);

  BarInfo get personalbar();

  void set personalbar(BarInfo value);

  Screen get screen();

  void set screen(Screen value);

  int get screenLeft();

  void set screenLeft(int value);

  int get screenTop();

  void set screenTop(int value);

  int get screenX();

  void set screenX(int value);

  int get screenY();

  void set screenY(int value);

  int get scrollX();

  void set scrollX(int value);

  int get scrollY();

  void set scrollY(int value);

  BarInfo get scrollbars();

  void set scrollbars(BarInfo value);

  DOMWindow get self();

  void set self(DOMWindow value);

  Storage get sessionStorage();

  String get status();

  void set status(String value);

  BarInfo get statusbar();

  void set statusbar(BarInfo value);

  StyleMedia get styleMedia();

  BarInfo get toolbar();

  void set toolbar(BarInfo value);

  DOMWindow get top();

  void set top(DOMWindow value);

  IDBFactory get webkitIndexedDB();

  NotificationCenter get webkitNotifications();

  StorageInfo get webkitStorageInfo();

  DOMURL get webkitURL();

  DOMWindow get window();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void alert(String message);

  String atob(String string);

  void blur();

  String btoa(String string);

  void captureEvents();

  void clearInterval(int handle);

  void clearTimeout(int handle);

  void close();

  bool confirm(String message);

  bool dispatchEvent(Event evt);

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog);

  void focus();

  CSSStyleDeclaration getComputedStyle(Element element, String pseudoElement);

  CSSRuleList getMatchedCSSRules(Element element, String pseudoElement);

  DOMSelection getSelection();

  MediaQueryList matchMedia(String query);

  void moveBy(num x, num y);

  void moveTo(num x, num y);

  DOMWindow open(String url, String name, [String options]);

  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]);

  void postMessage(Dynamic message, String targetOrigin, [List messagePorts]);

  void print();

  String prompt(String message, String defaultValue);

  void releaseEvents();

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

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

  WebKitPoint webkitConvertPointFromNodeToPage(Node node, WebKitPoint p);

  WebKitPoint webkitConvertPointFromPageToNode(Node node, WebKitPoint p);

  void webkitPostMessage(Dynamic message, String targetOrigin, [List transferList]);

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, Element element);

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback]);

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback, ErrorCallback errorCallback]);
}

interface DOMWindow extends Window {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DataTransferItem {

  String get kind();

  String get type();

  Blob getAsFile();

  void getAsString(StringCallback callback);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DataTransferItemList {

  int get length();

  void add(var data_OR_file, [String type]);

  void clear();

  DataTransferItem item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Database {

  String get version();

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback, SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]);

  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]);

  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool DatabaseCallback(var database);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DatabaseSync {

  String get lastErrorMessage();

  String get version();

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback]);

  void readTransaction(SQLTransactionSyncCallback callback);

  void transaction(SQLTransactionSyncCallback callback);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DedicatedWorkerGlobalScope extends WorkerContext {

  EventListener get onmessage();

  void set onmessage(EventListener value);

  void postMessage(Object message, [List messagePorts]);

  void webkitPostMessage(Object message, [List transferList]);
}

interface DedicatedWorkerContext extends DedicatedWorkerGlobalScope {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DelayNode extends AudioNode {

  AudioParam get delayTime();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DeviceMotionEvent extends Event {

  num get interval();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DeviceOrientationEvent extends Event {

  bool get absolute();

  num get alpha();

  num get beta();

  num get gamma();

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryEntry extends Entry {

  DirectoryReader createReader();

  void getDirectory(String path, [Object flags, EntryCallback successCallback, ErrorCallback errorCallback]);

  void getFile(String path, [Object flags, EntryCallback successCallback, ErrorCallback errorCallback]);

  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryEntrySync extends EntrySync {

  DirectoryReaderSync createReader();

  DirectoryEntrySync getDirectory(String path, Object flags);

  FileEntrySync getFile(String path, Object flags);

  void removeRecursively();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryReader {

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryReaderSync {

  EntryArraySync readEntries();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Document extends Node, NodeSelector {

  String get URL();

  HTMLCollection get anchors();

  HTMLCollection get applets();

  HTMLElement get body();

  void set body(HTMLElement value);

  String get characterSet();

  String get charset();

  void set charset(String value);

  String get compatMode();

  String get cookie();

  void set cookie(String value);

  String get defaultCharset();

  DOMWindow get defaultView();

  DocumentType get doctype();

  Element get documentElement();

  String get documentURI();

  void set documentURI(String value);

  String get domain();

  void set domain(String value);

  HTMLCollection get forms();

  HTMLHeadElement get head();

  HTMLCollection get images();

  DOMImplementation get implementation();

  String get inputEncoding();

  String get lastModified();

  HTMLCollection get links();

  Location get location();

  void set location(Location value);

  String get preferredStylesheetSet();

  String get readyState();

  String get referrer();

  String get selectedStylesheetSet();

  void set selectedStylesheetSet(String value);

  StyleSheetList get styleSheets();

  String get title();

  void set title(String value);

  Element get webkitCurrentFullScreenElement();

  bool get webkitFullScreenKeyboardInputAllowed();

  bool get webkitHidden();

  bool get webkitIsFullScreen();

  String get webkitVisibilityState();

  String get xmlEncoding();

  bool get xmlStandalone();

  void set xmlStandalone(bool value);

  String get xmlVersion();

  void set xmlVersion(String value);

  Node adoptNode(Node source);

  Range caretRangeFromPoint(int x, int y);

  Attr createAttribute(String name);

  Attr createAttributeNS(String namespaceURI, String qualifiedName);

  CDATASection createCDATASection(String data);

  Comment createComment(String data);

  DocumentFragment createDocumentFragment();

  Element createElement(String tagName);

  Element createElementNS(String namespaceURI, String qualifiedName);

  EntityReference createEntityReference(String name);

  Event createEvent(String eventType);

  XPathExpression createExpression(String expression, XPathNSResolver resolver);

  XPathNSResolver createNSResolver(Node nodeResolver);

  NodeIterator createNodeIterator(Node root, int whatToShow, NodeFilter filter, bool expandEntityReferences);

  ProcessingInstruction createProcessingInstruction(String target, String data);

  Range createRange();

  Text createTextNode(String data);

  Touch createTouch(DOMWindow window, EventTarget target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce);

  TouchList createTouchList();

  TreeWalker createTreeWalker(Node root, int whatToShow, NodeFilter filter, bool expandEntityReferences);

  Element elementFromPoint(int x, int y);

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult);

  bool execCommand(String command, bool userInterface, String value);

  Object getCSSCanvasContext(String contextId, String name, int width, int height);

  Element getElementById(String elementId);

  NodeList getElementsByClassName(String tagname);

  NodeList getElementsByName(String elementName);

  NodeList getElementsByTagName(String tagname);

  NodeList getElementsByTagNameNS(String namespaceURI, String localName);

  CSSStyleDeclaration getOverrideStyle(Element element, String pseudoElement);

  DOMSelection getSelection();

  Node importNode(Node importedNode, [bool deep]);

  bool queryCommandEnabled(String command);

  bool queryCommandIndeterm(String command);

  bool queryCommandState(String command);

  bool queryCommandSupported(String command);

  String queryCommandValue(String command);

  Element querySelector(String selectors);

  NodeList querySelectorAll(String selectors);

  void webkitCancelFullScreen();

  WebKitNamedFlow webkitGetFlowByName(String name);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DocumentFragment extends Node, NodeSelector {

  Element querySelector(String selectors);

  NodeList querySelectorAll(String selectors);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DocumentType extends Node {

  NamedNodeMap get entities();

  String get internalSubset();

  String get name();

  NamedNodeMap get notations();

  String get publicId();

  String get systemId();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DynamicsCompressorNode extends AudioNode {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Element extends Node, NodeSelector, ElementTraversal {

  static final int ALLOW_KEYBOARD_INPUT = 1;

  int get childElementCount();

  int get clientHeight();

  int get clientLeft();

  int get clientTop();

  int get clientWidth();

  Element get firstElementChild();

  Element get lastElementChild();

  Element get nextElementSibling();

  int get offsetHeight();

  int get offsetLeft();

  Element get offsetParent();

  int get offsetTop();

  int get offsetWidth();

  Element get previousElementSibling();

  int get scrollHeight();

  int get scrollLeft();

  void set scrollLeft(int value);

  int get scrollTop();

  void set scrollTop(int value);

  int get scrollWidth();

  CSSStyleDeclaration get style();

  String get tagName();

  void blur();

  void focus();

  String getAttribute(String name);

  String getAttributeNS(String namespaceURI, String localName);

  Attr getAttributeNode(String name);

  Attr getAttributeNodeNS(String namespaceURI, String localName);

  ClientRect getBoundingClientRect();

  ClientRectList getClientRects();

  NodeList getElementsByClassName(String name);

  NodeList getElementsByTagName(String name);

  NodeList getElementsByTagNameNS(String namespaceURI, String localName);

  bool hasAttribute(String name);

  bool hasAttributeNS(String namespaceURI, String localName);

  Element querySelector(String selectors);

  NodeList querySelectorAll(String selectors);

  void removeAttribute(String name);

  void removeAttributeNS(String namespaceURI, String localName);

  Attr removeAttributeNode(Attr oldAttr);

  void scrollByLines(int lines);

  void scrollByPages(int pages);

  void scrollIntoView([bool alignWithTop]);

  void scrollIntoViewIfNeeded([bool centerIfNeeded]);

  void setAttribute(String name, String value);

  void setAttributeNS(String namespaceURI, String qualifiedName, String value);

  Attr setAttributeNode(Attr newAttr);

  Attr setAttributeNodeNS(Attr newAttr);

  bool webkitMatchesSelector(String selectors);

  void webkitRequestFullScreen(int flags);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ElementTimeControl {

  void beginElement();

  void beginElementAt(num offset);

  void endElement();

  void endElementAt(num offset);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ElementTraversal {

  int get childElementCount();

  Element get firstElementChild();

  Element get lastElementChild();

  Element get nextElementSibling();

  Element get previousElementSibling();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Entity extends Node {

  String get notationName();

  String get publicId();

  String get systemId();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Entry {

  DOMFileSystem get filesystem();

  String get fullPath();

  bool get isDirectory();

  bool get isFile();

  String get name();

  void copyTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]);

  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback]);

  void getParent([EntryCallback successCallback, ErrorCallback errorCallback]);

  void moveTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]);

  void remove(VoidCallback successCallback, [ErrorCallback errorCallback]);

  String toURL();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EntryArray {

  int get length();

  Entry item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EntryArraySync {

  int get length();

  EntrySync item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool EntryCallback(Entry entry);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EntrySync {

  DOMFileSystemSync get filesystem();

  String get fullPath();

  bool get isDirectory();

  bool get isFile();

  String get name();

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ErrorEvent extends Event {

  String get filename();

  int get lineno();

  String get message();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Event {

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

  bool get bubbles();

  bool get cancelBubble();

  void set cancelBubble(bool value);

  bool get cancelable();

  Clipboard get clipboardData();

  EventTarget get currentTarget();

  bool get defaultPrevented();

  int get eventPhase();

  bool get returnValue();

  void set returnValue(bool value);

  EventTarget get srcElement();

  EventTarget get target();

  int get timeStamp();

  String get type();

  void initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg);

  void preventDefault();

  void stopImmediatePropagation();

  void stopPropagation();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EventException {

  static final int DISPATCH_REQUEST_ERR = 1;

  static final int UNSPECIFIED_EVENT_TYPE_ERR = 0;

  int get code();

  String get message();

  String get name();

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EventSource extends EventTarget {

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String get URL();

  int get readyState();

  String get url();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void close();

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EventTarget {

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event event);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface File extends Blob {

  String get fileName();

  int get fileSize();

  Date get lastModifiedDate();

  String get name();

  String get webkitRelativePath();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool FileCallback(File file);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileEntry extends Entry {

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback]);

  void file(FileCallback successCallback, [ErrorCallback errorCallback]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileEntrySync extends EntrySync {

  FileWriterSync createWriter();

  File file();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get code();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get code();

  String get message();

  String get name();

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileList {

  int get length();

  File item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileReader default _FileReaderFactoryProvider {

  FileReader();

  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  FileError get error();

  EventListener get onabort();

  void set onabort(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onload();

  void set onload(EventListener value);

  EventListener get onloadend();

  void set onloadend(EventListener value);

  EventListener get onloadstart();

  void set onloadstart(EventListener value);

  EventListener get onprogress();

  void set onprogress(EventListener value);

  int get readyState();

  Object get result();

  void abort();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void readAsArrayBuffer(Blob blob);

  void readAsBinaryString(Blob blob);

  void readAsDataURL(Blob blob);

  void readAsText(Blob blob, [String encoding]);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileReaderSync {

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileWriter {

  static final int DONE = 2;

  static final int INIT = 0;

  static final int WRITING = 1;

  FileError get error();

  int get length();

  EventListener get onabort();

  void set onabort(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onprogress();

  void set onprogress(EventListener value);

  EventListener get onwrite();

  void set onwrite(EventListener value);

  EventListener get onwriteend();

  void set onwriteend(EventListener value);

  EventListener get onwritestart();

  void set onwritestart(EventListener value);

  int get position();

  int get readyState();

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileWriterSync {

  int get length();

  int get position();

  void seek(int position);

  void truncate(int size);

  void write(Blob data);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Float32Array extends ArrayBufferView, List<num> default _TypedArrayFactoryProvider {

  Float32Array(int length);

  Float32Array.fromList(List<num> list);

  Float32Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 4;

  int get length();

  void setElements(Object array, [int offset]);

  Float32Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Float64Array extends ArrayBufferView, List<num> default _TypedArrayFactoryProvider {

  Float64Array(int length);

  Float64Array.fromList(List<num> list);

  Float64Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 8;

  int get length();

  void setElements(Object array, [int offset]);

  Float64Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Geolocation {

  void clearWatch(int watchId);

  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback]);

  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Geoposition {

  Coordinates get coords();

  int get timestamp();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLAllCollection {

  int get length();

  Node item(int index);

  Node namedItem(String name);

  NodeList tags(String name);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLAnchorElement extends HTMLElement {

  String get charset();

  void set charset(String value);

  String get coords();

  void set coords(String value);

  String get download();

  void set download(String value);

  String get hash();

  void set hash(String value);

  String get host();

  void set host(String value);

  String get hostname();

  void set hostname(String value);

  String get href();

  void set href(String value);

  String get hreflang();

  void set hreflang(String value);

  String get name();

  void set name(String value);

  String get origin();

  String get pathname();

  void set pathname(String value);

  String get ping();

  void set ping(String value);

  String get port();

  void set port(String value);

  String get protocol();

  void set protocol(String value);

  String get rel();

  void set rel(String value);

  String get rev();

  void set rev(String value);

  String get search();

  void set search(String value);

  String get shape();

  void set shape(String value);

  String get target();

  void set target(String value);

  String get text();

  String get type();

  void set type(String value);

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLAppletElement extends HTMLElement {

  String get align();

  void set align(String value);

  String get alt();

  void set alt(String value);

  String get archive();

  void set archive(String value);

  String get code();

  void set code(String value);

  String get codeBase();

  void set codeBase(String value);

  String get height();

  void set height(String value);

  String get hspace();

  void set hspace(String value);

  String get name();

  void set name(String value);

  String get object();

  void set object(String value);

  String get vspace();

  void set vspace(String value);

  String get width();

  void set width(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLAreaElement extends HTMLElement {

  String get alt();

  void set alt(String value);

  String get coords();

  void set coords(String value);

  String get hash();

  String get host();

  String get hostname();

  String get href();

  void set href(String value);

  bool get noHref();

  void set noHref(bool value);

  String get pathname();

  String get ping();

  void set ping(String value);

  String get port();

  String get protocol();

  String get search();

  String get shape();

  void set shape(String value);

  String get target();

  void set target(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLAudioElement extends HTMLMediaElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLBRElement extends HTMLElement {

  String get clear();

  void set clear(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLBaseElement extends HTMLElement {

  String get href();

  void set href(String value);

  String get target();

  void set target(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLBaseFontElement extends HTMLElement {

  String get color();

  void set color(String value);

  String get face();

  void set face(String value);

  int get size();

  void set size(int value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLBodyElement extends HTMLElement {

  String get aLink();

  void set aLink(String value);

  String get background();

  void set background(String value);

  String get bgColor();

  void set bgColor(String value);

  String get link();

  void set link(String value);

  String get text();

  void set text(String value);

  String get vLink();

  void set vLink(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLButtonElement extends HTMLElement {

  bool get autofocus();

  void set autofocus(bool value);

  bool get disabled();

  void set disabled(bool value);

  HTMLFormElement get form();

  String get formAction();

  void set formAction(String value);

  String get formEnctype();

  void set formEnctype(String value);

  String get formMethod();

  void set formMethod(String value);

  bool get formNoValidate();

  void set formNoValidate(bool value);

  String get formTarget();

  void set formTarget(String value);

  NodeList get labels();

  String get name();

  void set name(String value);

  String get type();

  String get validationMessage();

  ValidityState get validity();

  String get value();

  void set value(String value);

  bool get willValidate();

  bool checkValidity();

  void click();

  void setCustomValidity(String error);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLCanvasElement extends HTMLElement {

  int get height();

  void set height(int value);

  int get width();

  void set width(int value);

  Object getContext(String contextId);

  String toDataURL(String type);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLCollection extends List<Node> {

  int get length();

  Node item(int index);

  Node namedItem(String name);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLContentElement extends HTMLElement {

  String get select();

  void set select(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLDListElement extends HTMLElement {

  bool get compact();

  void set compact(bool value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLDataListElement extends HTMLElement {

  HTMLCollection get options();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLDetailsElement extends HTMLElement {

  bool get open();

  void set open(bool value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLDirectoryElement extends HTMLElement {

  bool get compact();

  void set compact(bool value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLDivElement extends HTMLElement {

  String get align();

  void set align(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLDocument extends Document {

  Element get activeElement();

  String get alinkColor();

  void set alinkColor(String value);

  HTMLAllCollection get all();

  void set all(HTMLAllCollection value);

  String get bgColor();

  void set bgColor(String value);

  String get compatMode();

  String get designMode();

  void set designMode(String value);

  String get dir();

  void set dir(String value);

  HTMLCollection get embeds();

  String get fgColor();

  void set fgColor(String value);

  String get linkColor();

  void set linkColor(String value);

  HTMLCollection get plugins();

  HTMLCollection get scripts();

  String get vlinkColor();

  void set vlinkColor(String value);

  void captureEvents();

  void clear();

  void close();

  bool hasFocus();

  void open();

  void releaseEvents();

  void write(String text);

  void writeln(String text);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLElement extends Element {

  String get accessKey();

  void set accessKey(String value);

  HTMLCollection get children();

  DOMTokenList get classList();

  String get className();

  void set className(String value);

  String get contentEditable();

  void set contentEditable(String value);

  String get dir();

  void set dir(String value);

  bool get draggable();

  void set draggable(bool value);

  bool get hidden();

  void set hidden(bool value);

  String get id();

  void set id(String value);

  String get innerHTML();

  void set innerHTML(String value);

  String get innerText();

  void set innerText(String value);

  bool get isContentEditable();

  String get itemId();

  void set itemId(String value);

  DOMSettableTokenList get itemProp();

  DOMSettableTokenList get itemRef();

  bool get itemScope();

  void set itemScope(bool value);

  DOMSettableTokenList get itemType();

  Object get itemValue();

  void set itemValue(Object value);

  String get lang();

  void set lang(String value);

  String get outerHTML();

  void set outerHTML(String value);

  String get outerText();

  void set outerText(String value);

  bool get spellcheck();

  void set spellcheck(bool value);

  int get tabIndex();

  void set tabIndex(int value);

  String get title();

  void set title(String value);

  String get webkitdropzone();

  void set webkitdropzone(String value);

  Element insertAdjacentElement(String where, Element element);

  void insertAdjacentHTML(String where, String html);

  void insertAdjacentText(String where, String text);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLEmbedElement extends HTMLElement {

  String get align();

  void set align(String value);

  String get height();

  void set height(String value);

  String get name();

  void set name(String value);

  String get src();

  void set src(String value);

  String get type();

  void set type(String value);

  String get width();

  void set width(String value);

  SVGDocument getSVGDocument();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLFieldSetElement extends HTMLElement {

  HTMLFormElement get form();

  String get validationMessage();

  ValidityState get validity();

  bool get willValidate();

  bool checkValidity();

  void setCustomValidity(String error);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLFontElement extends HTMLElement {

  String get color();

  void set color(String value);

  String get face();

  void set face(String value);

  String get size();

  void set size(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLFormElement extends HTMLElement {

  String get acceptCharset();

  void set acceptCharset(String value);

  String get action();

  void set action(String value);

  String get autocomplete();

  void set autocomplete(String value);

  HTMLCollection get elements();

  String get encoding();

  void set encoding(String value);

  String get enctype();

  void set enctype(String value);

  int get length();

  String get method();

  void set method(String value);

  String get name();

  void set name(String value);

  bool get noValidate();

  void set noValidate(bool value);

  String get target();

  void set target(String value);

  bool checkValidity();

  void reset();

  void submit();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLFrameElement extends HTMLElement {

  Document get contentDocument();

  DOMWindow get contentWindow();

  String get frameBorder();

  void set frameBorder(String value);

  int get height();

  String get location();

  void set location(String value);

  String get longDesc();

  void set longDesc(String value);

  String get marginHeight();

  void set marginHeight(String value);

  String get marginWidth();

  void set marginWidth(String value);

  String get name();

  void set name(String value);

  bool get noResize();

  void set noResize(bool value);

  String get scrolling();

  void set scrolling(String value);

  String get src();

  void set src(String value);

  int get width();

  SVGDocument getSVGDocument();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLFrameSetElement extends HTMLElement {

  String get cols();

  void set cols(String value);

  String get rows();

  void set rows(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLHRElement extends HTMLElement {

  String get align();

  void set align(String value);

  bool get noShade();

  void set noShade(bool value);

  String get size();

  void set size(String value);

  String get width();

  void set width(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLHeadElement extends HTMLElement {

  String get profile();

  void set profile(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLHeadingElement extends HTMLElement {

  String get align();

  void set align(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLHtmlElement extends HTMLElement {

  String get manifest();

  void set manifest(String value);

  String get version();

  void set version(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLIFrameElement extends HTMLElement {

  String get align();

  void set align(String value);

  Document get contentDocument();

  DOMWindow get contentWindow();

  String get frameBorder();

  void set frameBorder(String value);

  String get height();

  void set height(String value);

  String get longDesc();

  void set longDesc(String value);

  String get marginHeight();

  void set marginHeight(String value);

  String get marginWidth();

  void set marginWidth(String value);

  String get name();

  void set name(String value);

  String get sandbox();

  void set sandbox(String value);

  String get scrolling();

  void set scrolling(String value);

  String get src();

  void set src(String value);

  String get width();

  void set width(String value);

  SVGDocument getSVGDocument();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLImageElement extends HTMLElement {

  String get align();

  void set align(String value);

  String get alt();

  void set alt(String value);

  String get border();

  void set border(String value);

  bool get complete();

  String get crossOrigin();

  void set crossOrigin(String value);

  int get height();

  void set height(int value);

  int get hspace();

  void set hspace(int value);

  bool get isMap();

  void set isMap(bool value);

  String get longDesc();

  void set longDesc(String value);

  String get lowsrc();

  void set lowsrc(String value);

  String get name();

  void set name(String value);

  int get naturalHeight();

  int get naturalWidth();

  String get src();

  void set src(String value);

  String get useMap();

  void set useMap(String value);

  int get vspace();

  void set vspace(int value);

  int get width();

  void set width(int value);

  int get x();

  int get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLInputElement extends HTMLElement {

  String get accept();

  void set accept(String value);

  String get align();

  void set align(String value);

  String get alt();

  void set alt(String value);

  String get autocomplete();

  void set autocomplete(String value);

  bool get autofocus();

  void set autofocus(bool value);

  bool get checked();

  void set checked(bool value);

  bool get defaultChecked();

  void set defaultChecked(bool value);

  String get defaultValue();

  void set defaultValue(String value);

  String get dirName();

  void set dirName(String value);

  bool get disabled();

  void set disabled(bool value);

  FileList get files();

  HTMLFormElement get form();

  String get formAction();

  void set formAction(String value);

  String get formEnctype();

  void set formEnctype(String value);

  String get formMethod();

  void set formMethod(String value);

  bool get formNoValidate();

  void set formNoValidate(bool value);

  String get formTarget();

  void set formTarget(String value);

  bool get incremental();

  void set incremental(bool value);

  bool get indeterminate();

  void set indeterminate(bool value);

  NodeList get labels();

  HTMLElement get list();

  String get max();

  void set max(String value);

  int get maxLength();

  void set maxLength(int value);

  String get min();

  void set min(String value);

  bool get multiple();

  void set multiple(bool value);

  String get name();

  void set name(String value);

  String get pattern();

  void set pattern(String value);

  String get placeholder();

  void set placeholder(String value);

  bool get readOnly();

  void set readOnly(bool value);

  bool get required();

  void set required(bool value);

  HTMLOptionElement get selectedOption();

  String get selectionDirection();

  void set selectionDirection(String value);

  int get selectionEnd();

  void set selectionEnd(int value);

  int get selectionStart();

  void set selectionStart(int value);

  int get size();

  void set size(int value);

  String get src();

  void set src(String value);

  String get step();

  void set step(String value);

  String get type();

  void set type(String value);

  String get useMap();

  void set useMap(String value);

  String get validationMessage();

  ValidityState get validity();

  String get value();

  void set value(String value);

  Date get valueAsDate();

  void set valueAsDate(Date value);

  num get valueAsNumber();

  void set valueAsNumber(num value);

  bool get webkitGrammar();

  void set webkitGrammar(bool value);

  bool get webkitSpeech();

  void set webkitSpeech(bool value);

  bool get webkitdirectory();

  void set webkitdirectory(bool value);

  bool get willValidate();

  bool checkValidity();

  void click();

  void select();

  void setCustomValidity(String error);

  void setSelectionRange(int start, int end, [String direction]);

  void stepDown([int n]);

  void stepUp([int n]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLIsIndexElement extends HTMLInputElement {

  HTMLFormElement get form();

  String get prompt();

  void set prompt(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLKeygenElement extends HTMLElement {

  bool get autofocus();

  void set autofocus(bool value);

  String get challenge();

  void set challenge(String value);

  bool get disabled();

  void set disabled(bool value);

  HTMLFormElement get form();

  String get keytype();

  void set keytype(String value);

  NodeList get labels();

  String get name();

  void set name(String value);

  String get type();

  String get validationMessage();

  ValidityState get validity();

  bool get willValidate();

  bool checkValidity();

  void setCustomValidity(String error);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLLIElement extends HTMLElement {

  String get type();

  void set type(String value);

  int get value();

  void set value(int value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLLabelElement extends HTMLElement {

  HTMLElement get control();

  HTMLFormElement get form();

  String get htmlFor();

  void set htmlFor(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLLegendElement extends HTMLElement {

  String get align();

  void set align(String value);

  HTMLFormElement get form();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLLinkElement extends HTMLElement {

  String get charset();

  void set charset(String value);

  bool get disabled();

  void set disabled(bool value);

  String get href();

  void set href(String value);

  String get hreflang();

  void set hreflang(String value);

  String get media();

  void set media(String value);

  String get rel();

  void set rel(String value);

  String get rev();

  void set rev(String value);

  StyleSheet get sheet();

  DOMSettableTokenList get sizes();

  void set sizes(DOMSettableTokenList value);

  String get target();

  void set target(String value);

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLMapElement extends HTMLElement {

  HTMLCollection get areas();

  String get name();

  void set name(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLMarqueeElement extends HTMLElement {

  String get behavior();

  void set behavior(String value);

  String get bgColor();

  void set bgColor(String value);

  String get direction();

  void set direction(String value);

  String get height();

  void set height(String value);

  int get hspace();

  void set hspace(int value);

  int get loop();

  void set loop(int value);

  int get scrollAmount();

  void set scrollAmount(int value);

  int get scrollDelay();

  void set scrollDelay(int value);

  bool get trueSpeed();

  void set trueSpeed(bool value);

  int get vspace();

  void set vspace(int value);

  String get width();

  void set width(String value);

  void start();

  void stop();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLMediaElement extends HTMLElement {

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

  bool get autoplay();

  void set autoplay(bool value);

  TimeRanges get buffered();

  MediaController get controller();

  void set controller(MediaController value);

  bool get controls();

  void set controls(bool value);

  String get currentSrc();

  num get currentTime();

  void set currentTime(num value);

  bool get defaultMuted();

  void set defaultMuted(bool value);

  num get defaultPlaybackRate();

  void set defaultPlaybackRate(num value);

  num get duration();

  bool get ended();

  MediaError get error();

  num get initialTime();

  bool get loop();

  void set loop(bool value);

  String get mediaGroup();

  void set mediaGroup(String value);

  bool get muted();

  void set muted(bool value);

  int get networkState();

  bool get paused();

  num get playbackRate();

  void set playbackRate(num value);

  TimeRanges get played();

  String get preload();

  void set preload(String value);

  int get readyState();

  TimeRanges get seekable();

  bool get seeking();

  String get src();

  void set src(String value);

  num get startTime();

  TextTrackList get textTracks();

  num get volume();

  void set volume(num value);

  int get webkitAudioDecodedByteCount();

  bool get webkitClosedCaptionsVisible();

  void set webkitClosedCaptionsVisible(bool value);

  bool get webkitHasClosedCaptions();

  String get webkitMediaSourceURL();

  bool get webkitPreservesPitch();

  void set webkitPreservesPitch(bool value);

  int get webkitSourceState();

  int get webkitVideoDecodedByteCount();

  TextTrack addTrack(String kind, [String label, String language]);

  String canPlayType(String type);

  void load();

  void pause();

  void play();

  void webkitSourceAppend(Uint8Array data);

  void webkitSourceEndOfStream(int status);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLMenuElement extends HTMLElement {

  bool get compact();

  void set compact(bool value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLMetaElement extends HTMLElement {

  String get content();

  void set content(String value);

  String get httpEquiv();

  void set httpEquiv(String value);

  String get name();

  void set name(String value);

  String get scheme();

  void set scheme(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLMeterElement extends HTMLElement {

  HTMLFormElement get form();

  num get high();

  void set high(num value);

  NodeList get labels();

  num get low();

  void set low(num value);

  num get max();

  void set max(num value);

  num get min();

  void set min(num value);

  num get optimum();

  void set optimum(num value);

  num get value();

  void set value(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLModElement extends HTMLElement {

  String get cite();

  void set cite(String value);

  String get dateTime();

  void set dateTime(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLOListElement extends HTMLElement {

  bool get compact();

  void set compact(bool value);

  bool get reversed();

  void set reversed(bool value);

  int get start();

  void set start(int value);

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLObjectElement extends HTMLElement {

  String get align();

  void set align(String value);

  String get archive();

  void set archive(String value);

  String get border();

  void set border(String value);

  String get code();

  void set code(String value);

  String get codeBase();

  void set codeBase(String value);

  String get codeType();

  void set codeType(String value);

  Document get contentDocument();

  String get data();

  void set data(String value);

  bool get declare();

  void set declare(bool value);

  HTMLFormElement get form();

  String get height();

  void set height(String value);

  int get hspace();

  void set hspace(int value);

  String get name();

  void set name(String value);

  String get standby();

  void set standby(String value);

  String get type();

  void set type(String value);

  String get useMap();

  void set useMap(String value);

  String get validationMessage();

  ValidityState get validity();

  int get vspace();

  void set vspace(int value);

  String get width();

  void set width(String value);

  bool get willValidate();

  bool checkValidity();

  SVGDocument getSVGDocument();

  void setCustomValidity(String error);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLOptGroupElement extends HTMLElement {

  bool get disabled();

  void set disabled(bool value);

  String get label();

  void set label(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLOptionElement extends HTMLElement {

  bool get defaultSelected();

  void set defaultSelected(bool value);

  bool get disabled();

  void set disabled(bool value);

  HTMLFormElement get form();

  int get index();

  String get label();

  void set label(String value);

  bool get selected();

  void set selected(bool value);

  String get text();

  void set text(String value);

  String get value();

  void set value(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLOptionsCollection extends HTMLCollection {

  int get length();

  void set length(int value);

  int get selectedIndex();

  void set selectedIndex(int value);

  void remove(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLOutputElement extends HTMLElement {

  String get defaultValue();

  void set defaultValue(String value);

  HTMLFormElement get form();

  DOMSettableTokenList get htmlFor();

  void set htmlFor(DOMSettableTokenList value);

  NodeList get labels();

  String get name();

  void set name(String value);

  String get type();

  String get validationMessage();

  ValidityState get validity();

  String get value();

  void set value(String value);

  bool get willValidate();

  bool checkValidity();

  void setCustomValidity(String error);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLParagraphElement extends HTMLElement {

  String get align();

  void set align(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLParamElement extends HTMLElement {

  String get name();

  void set name(String value);

  String get type();

  void set type(String value);

  String get value();

  void set value(String value);

  String get valueType();

  void set valueType(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLPreElement extends HTMLElement {

  int get width();

  void set width(int value);

  bool get wrap();

  void set wrap(bool value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLProgressElement extends HTMLElement {

  HTMLFormElement get form();

  NodeList get labels();

  num get max();

  void set max(num value);

  num get position();

  num get value();

  void set value(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLPropertiesCollection extends HTMLCollection {

  int get length();

  Node item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLQuoteElement extends HTMLElement {

  String get cite();

  void set cite(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLScriptElement extends HTMLElement {

  bool get async();

  void set async(bool value);

  String get charset();

  void set charset(String value);

  bool get defer();

  void set defer(bool value);

  String get event();

  void set event(String value);

  String get htmlFor();

  void set htmlFor(String value);

  String get src();

  void set src(String value);

  String get text();

  void set text(String value);

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLSelectElement extends HTMLElement {

  bool get autofocus();

  void set autofocus(bool value);

  bool get disabled();

  void set disabled(bool value);

  HTMLFormElement get form();

  NodeList get labels();

  int get length();

  void set length(int value);

  bool get multiple();

  void set multiple(bool value);

  String get name();

  void set name(String value);

  HTMLOptionsCollection get options();

  bool get required();

  void set required(bool value);

  int get selectedIndex();

  void set selectedIndex(int value);

  int get size();

  void set size(int value);

  String get type();

  String get validationMessage();

  ValidityState get validity();

  String get value();

  void set value(String value);

  bool get willValidate();

  void add(HTMLElement element, HTMLElement before);

  bool checkValidity();

  Node item(int index);

  Node namedItem(String name);

  void remove(var index_OR_option);

  void setCustomValidity(String error);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLSourceElement extends HTMLElement {

  String get media();

  void set media(String value);

  String get src();

  void set src(String value);

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLSpanElement extends HTMLElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLStyleElement extends HTMLElement {

  bool get disabled();

  void set disabled(bool value);

  String get media();

  void set media(String value);

  bool get scoped();

  void set scoped(bool value);

  StyleSheet get sheet();

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTableCaptionElement extends HTMLElement {

  String get align();

  void set align(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTableCellElement extends HTMLElement {

  String get abbr();

  void set abbr(String value);

  String get align();

  void set align(String value);

  String get axis();

  void set axis(String value);

  String get bgColor();

  void set bgColor(String value);

  int get cellIndex();

  String get ch();

  void set ch(String value);

  String get chOff();

  void set chOff(String value);

  int get colSpan();

  void set colSpan(int value);

  String get headers();

  void set headers(String value);

  String get height();

  void set height(String value);

  bool get noWrap();

  void set noWrap(bool value);

  int get rowSpan();

  void set rowSpan(int value);

  String get scope();

  void set scope(String value);

  String get vAlign();

  void set vAlign(String value);

  String get width();

  void set width(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTableColElement extends HTMLElement {

  String get align();

  void set align(String value);

  String get ch();

  void set ch(String value);

  String get chOff();

  void set chOff(String value);

  int get span();

  void set span(int value);

  String get vAlign();

  void set vAlign(String value);

  String get width();

  void set width(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTableElement extends HTMLElement {

  String get align();

  void set align(String value);

  String get bgColor();

  void set bgColor(String value);

  String get border();

  void set border(String value);

  HTMLTableCaptionElement get caption();

  void set caption(HTMLTableCaptionElement value);

  String get cellPadding();

  void set cellPadding(String value);

  String get cellSpacing();

  void set cellSpacing(String value);

  String get frame();

  void set frame(String value);

  HTMLCollection get rows();

  String get rules();

  void set rules(String value);

  String get summary();

  void set summary(String value);

  HTMLCollection get tBodies();

  HTMLTableSectionElement get tFoot();

  void set tFoot(HTMLTableSectionElement value);

  HTMLTableSectionElement get tHead();

  void set tHead(HTMLTableSectionElement value);

  String get width();

  void set width(String value);

  HTMLElement createCaption();

  HTMLElement createTFoot();

  HTMLElement createTHead();

  void deleteCaption();

  void deleteRow(int index);

  void deleteTFoot();

  void deleteTHead();

  HTMLElement insertRow(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTableRowElement extends HTMLElement {

  String get align();

  void set align(String value);

  String get bgColor();

  void set bgColor(String value);

  HTMLCollection get cells();

  String get ch();

  void set ch(String value);

  String get chOff();

  void set chOff(String value);

  int get rowIndex();

  int get sectionRowIndex();

  String get vAlign();

  void set vAlign(String value);

  void deleteCell(int index);

  HTMLElement insertCell(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTableSectionElement extends HTMLElement {

  String get align();

  void set align(String value);

  String get ch();

  void set ch(String value);

  String get chOff();

  void set chOff(String value);

  HTMLCollection get rows();

  String get vAlign();

  void set vAlign(String value);

  void deleteRow(int index);

  HTMLElement insertRow(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTextAreaElement extends HTMLElement {

  bool get autofocus();

  void set autofocus(bool value);

  int get cols();

  void set cols(int value);

  String get defaultValue();

  void set defaultValue(String value);

  String get dirName();

  void set dirName(String value);

  bool get disabled();

  void set disabled(bool value);

  HTMLFormElement get form();

  NodeList get labels();

  int get maxLength();

  void set maxLength(int value);

  String get name();

  void set name(String value);

  String get placeholder();

  void set placeholder(String value);

  bool get readOnly();

  void set readOnly(bool value);

  bool get required();

  void set required(bool value);

  int get rows();

  void set rows(int value);

  String get selectionDirection();

  void set selectionDirection(String value);

  int get selectionEnd();

  void set selectionEnd(int value);

  int get selectionStart();

  void set selectionStart(int value);

  int get textLength();

  String get type();

  String get validationMessage();

  ValidityState get validity();

  String get value();

  void set value(String value);

  bool get willValidate();

  String get wrap();

  void set wrap(String value);

  bool checkValidity();

  void select();

  void setCustomValidity(String error);

  void setSelectionRange(int start, int end, [String direction]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTitleElement extends HTMLElement {

  String get text();

  void set text(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLTrackElement extends HTMLElement {

  static final int ERROR = 3;

  static final int LOADED = 2;

  static final int LOADING = 1;

  static final int NONE = 0;

  bool get isDefault();

  void set isDefault(bool value);

  String get kind();

  void set kind(String value);

  String get label();

  void set label(String value);

  int get readyState();

  String get src();

  void set src(String value);

  String get srclang();

  void set srclang(String value);

  TextTrack get track();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLUListElement extends HTMLElement {

  bool get compact();

  void set compact(bool value);

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLUnknownElement extends HTMLElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLVideoElement extends HTMLMediaElement {

  int get height();

  void set height(int value);

  String get poster();

  void set poster(String value);

  int get videoHeight();

  int get videoWidth();

  int get webkitDecodedFrameCount();

  bool get webkitDisplayingFullscreen();

  int get webkitDroppedFrameCount();

  bool get webkitSupportsFullscreen();

  int get width();

  void set width(int value);

  void webkitEnterFullScreen();

  void webkitEnterFullscreen();

  void webkitExitFullScreen();

  void webkitExitFullscreen();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HashChangeEvent extends Event {

  String get newURL();

  String get oldURL();

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HighPass2FilterNode extends AudioNode {

  AudioParam get cutoff();

  AudioParam get resonance();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface History {

  int get length();

  void back();

  void forward();

  void go(int distance);

  void pushState(Object data, String title, [String url]);

  void replaceState(Object data, String title, [String url]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBAny {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBCursor {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

  int get direction();

  IDBKey get key();

  IDBKey get primaryKey();

  IDBAny get source();

  void continueFunction([IDBKey key]);

  IDBRequest delete();

  IDBRequest update(Dynamic value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBCursorWithValue extends IDBCursor {

  IDBAny get value();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBDatabase {

  String get name();

  EventListener get onabort();

  void set onabort(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onversionchange();

  void set onversionchange(EventListener value);

  String get version();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void close();

  IDBObjectStore createObjectStore(String name);

  void deleteObjectStore(String name);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  IDBVersionChangeRequest setVersion(String version);

  IDBTransaction transaction(String storeName, int mode);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBDatabaseError {

  int get code();

  void set code(int value);

  String get message();

  void set message(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get code();

  String get message();

  String get name();

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBFactory {

  int cmp(IDBKey first, IDBKey second);

  IDBVersionChangeRequest deleteDatabase(String name);

  IDBRequest getDatabaseNames();

  IDBRequest open(String name);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBIndex {

  String get keyPath();

  bool get multiEntry();

  String get name();

  IDBObjectStore get objectStore();

  bool get unique();

  IDBRequest count([IDBKeyRange range]);

  IDBRequest getObject(IDBKey key);

  IDBRequest getKey(IDBKey key);

  IDBRequest openCursor([IDBKeyRange range, int direction]);

  IDBRequest openKeyCursor([IDBKeyRange range, int direction]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBKey {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBKeyRange {

  IDBKey get lower();

  bool get lowerOpen();

  IDBKey get upper();

  bool get upperOpen();

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen, bool upperOpen]);

  IDBKeyRange lowerBound(IDBKey bound, [bool open]);

  IDBKeyRange only(IDBKey value);

  IDBKeyRange upperBound(IDBKey bound, [bool open]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBObjectStore {

  String get keyPath();

  String get name();

  IDBTransaction get transaction();

  IDBRequest add(Dynamic value, [IDBKey key]);

  IDBRequest clear();

  IDBRequest count([IDBKeyRange range]);

  IDBIndex createIndex(String name, String keyPath);

  IDBRequest delete(IDBKey key);

  void deleteIndex(String name);

  IDBRequest getObject(IDBKey key);

  IDBIndex index(String name);

  IDBRequest openCursor([IDBKeyRange range, int direction]);

  IDBRequest put(Dynamic value, [IDBKey key]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBRequest {

  static final int DONE = 2;

  static final int LOADING = 1;

  int get errorCode();

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onsuccess();

  void set onsuccess(EventListener value);

  int get readyState();

  IDBAny get result();

  IDBAny get source();

  IDBTransaction get transaction();

  String get webkitErrorMessage();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBTransaction {

  static final int READ_ONLY = 0;

  static final int READ_WRITE = 1;

  static final int VERSION_CHANGE = 2;

  IDBDatabase get db();

  int get mode();

  EventListener get onabort();

  void set onabort(EventListener value);

  EventListener get oncomplete();

  void set oncomplete(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  void abort();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  IDBObjectStore objectStore(String name);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBVersionChangeEvent extends Event {

  String get version();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBVersionChangeRequest extends IDBRequest {

  EventListener get onblocked();

  void set onblocked(EventListener value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ImageData {

  CanvasPixelArray get data();

  int get height();

  int get width();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface InjectedScriptHost {

  void clearConsoleMessages();

  void copyText(String text);

  int databaseId(Object database);

  void didCreateWorker(int id, String url, bool isFakeWorker);

  void didDestroyWorker(int id);

  Object evaluate(String text);

  Object functionDetails(Object object);

  void inspect(Object objectId, Object hints);

  Object inspectedNode(int num);

  Object internalConstructorName(Object object);

  bool isHTMLAllCollection(Object object);

  int nextWorkerId();

  int storageId(Object storage);

  String type(Object object);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface InspectorFrontendHost {

  void bringToFront();

  bool canSaveAs();

  void closeWindow();

  void copyText(String text);

  String hiddenPanels();

  void inspectedURLChanged(String newURL);

  String loadResourceSynchronously(String url);

  void loaded();

  String localizedStringsURL();

  void moveWindowBy(num x, num y);

  void openInNewTab(String url);

  String platform();

  String port();

  void recordActionTaken(int actionCode);

  void recordPanelShown(int panelCode);

  void recordSettingChanged(int settingChanged);

  void requestAttachWindow();

  void requestDetachWindow();

  void requestSetDockSide(String side);

  void saveAs(String fileName, String content);

  void sendMessageToBackend(String message);

  void setAttachedWindowHeight(int height);

  void setInjectedScriptForOrigin(String origin, String script);

  void showContextMenu(MouseEvent event, Object items);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int16Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Int16Array(int length);

  Int16Array.fromList(List<int> list);

  Int16Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 2;

  int get length();

  void setElements(Object array, [int offset]);

  Int16Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int32Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Int32Array(int length);

  Int32Array.fromList(List<int> list);

  Int32Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 4;

  int get length();

  void setElements(Object array, [int offset]);

  Int32Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int8Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Int8Array(int length);

  Int8Array.fromList(List<int> list);

  Int8Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 1;

  int get length();

  void setElements(Object array, [int offset]);

  Int8Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface JavaScriptAudioNode extends AudioNode {

  int get bufferSize();

  EventListener get onaudioprocess();

  void set onaudioprocess(EventListener value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface JavaScriptCallFrame {

  static final int CATCH_SCOPE = 4;

  static final int CLOSURE_SCOPE = 3;

  static final int GLOBAL_SCOPE = 0;

  static final int LOCAL_SCOPE = 1;

  static final int WITH_SCOPE = 2;

  JavaScriptCallFrame get caller();

  int get column();

  String get functionName();

  int get line();

  List get scopeChain();

  int get sourceID();

  Object get thisObject();

  String get type();

  void evaluate(String script);

  int scopeType(int scopeIndex);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface KeyboardEvent extends UIEvent {

  bool get altGraphKey();

  bool get altKey();

  bool get ctrlKey();

  String get keyIdentifier();

  int get keyLocation();

  bool get metaKey();

  bool get shiftKey();

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, DOMWindow view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Location {

  String get hash();

  void set hash(String value);

  String get host();

  void set host(String value);

  String get hostname();

  void set hostname(String value);

  String get href();

  void set href(String value);

  String get origin();

  String get pathname();

  void set pathname(String value);

  String get port();

  void set port(String value);

  String get protocol();

  void set protocol(String value);

  String get search();

  void set search(String value);

  void assign(String url);

  void reload();

  void replace(String url);

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LowPass2FilterNode extends AudioNode {

  AudioParam get cutoff();

  AudioParam get resonance();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaController {

  TimeRanges get buffered();

  num get currentTime();

  void set currentTime(num value);

  num get defaultPlaybackRate();

  void set defaultPlaybackRate(num value);

  num get duration();

  bool get muted();

  void set muted(bool value);

  bool get paused();

  num get playbackRate();

  void set playbackRate(num value);

  TimeRanges get played();

  TimeRanges get seekable();

  num get volume();

  void set volume(num value);

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void pause();

  void play();

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaElementAudioSourceNode extends AudioSourceNode {

  HTMLMediaElement get mediaElement();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaError {

  static final int MEDIA_ERR_ABORTED = 1;

  static final int MEDIA_ERR_DECODE = 3;

  static final int MEDIA_ERR_NETWORK = 2;

  static final int MEDIA_ERR_SRC_NOT_SUPPORTED = 4;

  int get code();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaList extends List<String> {

  int get length();

  String get mediaText();

  void set mediaText(String value);

  void appendMedium(String newMedium);

  void deleteMedium(String oldMedium);

  String item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaQueryList {

  bool get matches();

  String get media();

  void addListener(MediaQueryListListener listener);

  void removeListener(MediaQueryListListener listener);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaQueryListListener {

  void queryChanged(MediaQueryList list);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MemoryInfo {

  int get jsHeapSizeLimit();

  int get totalJSHeapSize();

  int get usedJSHeapSize();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MessageChannel {

  MessagePort get port1();

  MessagePort get port2();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MessageEvent extends Event {

  Object get data();

  String get lastEventId();

  String get origin();

  List get ports();

  DOMWindow get source();

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, DOMWindow sourceArg, List messagePorts);

  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, DOMWindow sourceArg, List transferables);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MessagePort extends EventTarget {

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void close();

  bool dispatchEvent(Event evt);

  void postMessage(String message, [List messagePorts]);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  void start();

  void webkitPostMessage(String message, [List transfer]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Metadata {

  Date get modificationTime();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool MetadataCallback(Metadata metadata);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MouseEvent extends UIEvent {

  bool get altKey();

  int get button();

  int get clientX();

  int get clientY();

  bool get ctrlKey();

  Clipboard get dataTransfer();

  Node get fromElement();

  bool get metaKey();

  int get offsetX();

  int get offsetY();

  EventTarget get relatedTarget();

  int get screenX();

  int get screenY();

  bool get shiftKey();

  Node get toElement();

  int get webkitMovementX();

  int get webkitMovementY();

  int get x();

  int get y();

  void initMouseEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MutationCallback {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MutationEvent extends Event {

  static final int ADDITION = 2;

  static final int MODIFICATION = 1;

  static final int REMOVAL = 3;

  int get attrChange();

  String get attrName();

  String get newValue();

  String get prevValue();

  Node get relatedNode();

  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MutationRecord {

  NodeList get addedNodes();

  String get attributeName();

  String get attributeNamespace();

  Node get nextSibling();

  String get oldValue();

  Node get previousSibling();

  NodeList get removedNodes();

  Node get target();

  String get type();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NamedNodeMap extends List<Node> {

  int get length();

  Node getNamedItem(String name);

  Node getNamedItemNS(String namespaceURI, String localName);

  Node item(int index);

  Node removeNamedItem(String name);

  Node removeNamedItemNS(String namespaceURI, String localName);

  Node setNamedItem(Node node);

  Node setNamedItemNS(Node node);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Navigator {

  String get appCodeName();

  String get appName();

  String get appVersion();

  bool get cookieEnabled();

  Geolocation get geolocation();

  String get language();

  DOMMimeTypeArray get mimeTypes();

  bool get onLine();

  String get platform();

  DOMPluginArray get plugins();

  String get product();

  String get productSub();

  String get userAgent();

  String get vendor();

  String get vendorSub();

  void getStorageUpdates();

  bool javaEnabled();

  void registerProtocolHandler(String scheme, String url, String title);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Node extends EventTarget {

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

  NamedNodeMap get attributes();

  String get baseURI();

  NodeList get childNodes();

  Node get firstChild();

  Node get lastChild();

  String get localName();

  String get namespaceURI();

  Node get nextSibling();

  String get nodeName();

  int get nodeType();

  String get nodeValue();

  void set nodeValue(String value);

  Document get ownerDocument();

  Element get parentElement();

  Node get parentNode();

  String get prefix();

  void set prefix(String value);

  Node get previousSibling();

  String get textContent();

  void set textContent(String value);

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  Node appendChild(Node newChild);

  Node cloneNode(bool deep);

  int compareDocumentPosition(Node other);

  bool contains(Node other);

  bool dispatchEvent(Event event);

  bool hasAttributes();

  bool hasChildNodes();

  Node insertBefore(Node newChild, Node refChild);

  bool isDefaultNamespace(String namespaceURI);

  bool isEqualNode(Node other);

  bool isSameNode(Node other);

  bool isSupported(String feature, String version);

  String lookupNamespaceURI(String prefix);

  String lookupPrefix(String namespaceURI);

  void normalize();

  Node removeChild(Node oldChild);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  Node replaceChild(Node newChild, Node oldChild);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NodeIterator {

  bool get expandEntityReferences();

  NodeFilter get filter();

  bool get pointerBeforeReferenceNode();

  Node get referenceNode();

  Node get root();

  int get whatToShow();

  void detach();

  Node nextNode();

  Node previousNode();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NodeList extends List<Node> {

  int get length();

  Node item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NodeSelector {

  Element querySelector(String selectors);

  NodeList querySelectorAll(String selectors);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Notation extends Node {

  String get publicId();

  String get systemId();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Notification extends EventTarget {

  String get dir();

  void set dir(String value);

  String get replaceId();

  void set replaceId(String value);

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void cancel();

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  void show();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NotificationCenter {

  int checkPermission();

  Notification createHTMLNotification(String url);

  Notification createNotification(String iconUrl, String title, String body);

  void requestPermission(VoidCallback callback);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OESStandardDerivatives {

  static final int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OESTextureFloat {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OfflineAudioCompletionEvent extends Event {

  AudioBuffer get renderedBuffer();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OperationNotAllowedException {

  static final int NOT_ALLOWED_ERR = 1;

  int get code();

  String get message();

  String get name();

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OverflowEvent extends Event {

  static final int BOTH = 2;

  static final int HORIZONTAL = 0;

  static final int VERTICAL = 1;

  bool get horizontalOverflow();

  int get orient();

  bool get verticalOverflow();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PageTransitionEvent extends Event {

  bool get persisted();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Performance {

  MemoryInfo get memory();

  PerformanceNavigation get navigation();

  PerformanceTiming get timing();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PerformanceNavigation {

  static final int TYPE_BACK_FORWARD = 2;

  static final int TYPE_NAVIGATE = 0;

  static final int TYPE_RELOAD = 1;

  static final int TYPE_RESERVED = 255;

  int get redirectCount();

  int get type();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PerformanceTiming {

  int get connectEnd();

  int get connectStart();

  int get domComplete();

  int get domContentLoadedEventEnd();

  int get domContentLoadedEventStart();

  int get domInteractive();

  int get domLoading();

  int get domainLookupEnd();

  int get domainLookupStart();

  int get fetchStart();

  int get loadEventEnd();

  int get loadEventStart();

  int get navigationStart();

  int get redirectEnd();

  int get redirectStart();

  int get requestStart();

  int get responseEnd();

  int get responseStart();

  int get secureConnectionStart();

  int get unloadEventEnd();

  int get unloadEventStart();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PointerLock {

  bool get isLocked();

  void lock(Element target, [VoidCallback successCallback, VoidCallback failureCallback]);

  void unlock();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PopStateEvent extends Event {

  Object get state();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool PositionCallback(Geoposition position);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PositionError {

  static final int PERMISSION_DENIED = 1;

  static final int POSITION_UNAVAILABLE = 2;

  static final int TIMEOUT = 3;

  int get code();

  String get message();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef bool PositionErrorCallback(PositionError error);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ProcessingInstruction extends Node {

  String get data();

  void set data(String value);

  StyleSheet get sheet();

  String get target();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ProgressEvent extends Event {

  bool get lengthComputable();

  int get loaded();

  int get total();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface RGBColor {

  CSSPrimitiveValue get blue();

  CSSPrimitiveValue get green();

  CSSPrimitiveValue get red();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  bool get collapsed();

  Node get commonAncestorContainer();

  Node get endContainer();

  int get endOffset();

  Node get startContainer();

  int get startOffset();

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface RangeException {

  static final int BAD_BOUNDARYPOINTS_ERR = 1;

  static final int INVALID_NODE_TYPE_ERR = 2;

  int get code();

  String get message();

  String get name();

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface RealtimeAnalyserNode extends AudioNode {

  int get fftSize();

  void set fftSize(int value);

  int get frequencyBinCount();

  num get maxDecibels();

  void set maxDecibels(num value);

  num get minDecibels();

  void set minDecibels(num value);

  num get smoothingTimeConstant();

  void set smoothingTimeConstant(num value);

  void getByteFrequencyData(Uint8Array array);

  void getByteTimeDomainData(Uint8Array array);

  void getFloatFrequencyData(Float32Array array);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Rect {

  CSSPrimitiveValue get bottom();

  CSSPrimitiveValue get left();

  CSSPrimitiveValue get right();

  CSSPrimitiveValue get top();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get code();

  String get message();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get code();

  String get message();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SQLResultSet {

  int get insertId();

  SQLResultSetRowList get rows();

  int get rowsAffected();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SQLResultSetRowList {

  int get length();

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAElement extends SVGElement, SVGURIReference, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGAnimatedString get target();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAltGlyphDefElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAltGlyphElement extends SVGTextPositioningElement, SVGURIReference {

  String get format();

  void set format(String value);

  String get glyphRef();

  void set glyphRef(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAltGlyphItemElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAngle {

  static final int SVG_ANGLETYPE_DEG = 2;

  static final int SVG_ANGLETYPE_GRAD = 4;

  static final int SVG_ANGLETYPE_RAD = 3;

  static final int SVG_ANGLETYPE_UNKNOWN = 0;

  static final int SVG_ANGLETYPE_UNSPECIFIED = 1;

  int get unitType();

  num get value();

  void set value(num value);

  String get valueAsString();

  void set valueAsString(String value);

  num get valueInSpecifiedUnits();

  void set valueInSpecifiedUnits(num value);

  void convertToSpecifiedUnits(int unitType);

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimateColorElement extends SVGAnimationElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimateElement extends SVGAnimationElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimateMotionElement extends SVGAnimationElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimateTransformElement extends SVGAnimationElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedAngle {

  SVGAngle get animVal();

  SVGAngle get baseVal();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedBoolean {

  bool get animVal();

  bool get baseVal();

  void set baseVal(bool value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedEnumeration {

  int get animVal();

  int get baseVal();

  void set baseVal(int value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedInteger {

  int get animVal();

  int get baseVal();

  void set baseVal(int value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedLength {

  SVGLength get animVal();

  SVGLength get baseVal();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedLengthList {

  SVGLengthList get animVal();

  SVGLengthList get baseVal();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedNumber {

  num get animVal();

  num get baseVal();

  void set baseVal(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedNumberList {

  SVGNumberList get animVal();

  SVGNumberList get baseVal();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedPreserveAspectRatio {

  SVGPreserveAspectRatio get animVal();

  SVGPreserveAspectRatio get baseVal();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedRect {

  SVGRect get animVal();

  SVGRect get baseVal();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedString {

  String get animVal();

  String get baseVal();

  void set baseVal(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimatedTransformList {

  SVGTransformList get animVal();

  SVGTransformList get baseVal();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGAnimationElement extends SVGElement, SVGTests, SVGExternalResourcesRequired, ElementTimeControl {

  SVGElement get targetElement();

  num getCurrentTime();

  num getSimpleDuration();

  num getStartTime();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGCircleElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGAnimatedLength get cx();

  SVGAnimatedLength get cy();

  SVGAnimatedLength get r();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGClipPathElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGAnimatedEnumeration get clipPathUnits();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGColor extends CSSValue {

  static final int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static final int SVG_COLORTYPE_RGBCOLOR = 1;

  static final int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static final int SVG_COLORTYPE_UNKNOWN = 0;

  int get colorType();

  RGBColor get rgbColor();

  void setColor(int colorType, String rgbColor, String iccColor);

  void setRGBColor(String rgbColor);

  void setRGBColorICCColor(String rgbColor, String iccColor);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  SVGAnimatedNumber get amplitude();

  SVGAnimatedNumber get exponent();

  SVGAnimatedNumber get intercept();

  SVGAnimatedNumber get offset();

  SVGAnimatedNumber get slope();

  SVGAnimatedNumberList get tableValues();

  SVGAnimatedEnumeration get type();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGCursorElement extends SVGElement, SVGURIReference, SVGTests, SVGExternalResourcesRequired {

  SVGAnimatedLength get x();

  SVGAnimatedLength get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGDefsElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGDescElement extends SVGElement, SVGLangSpace, SVGStylable {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGDocument extends Document {

  SVGSVGElement get rootElement();

  Event createEvent(String eventType);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGElement extends Element {

  String get id();

  void set id(String value);

  SVGSVGElement get ownerSVGElement();

  SVGElement get viewportElement();

  String get xmlbase();

  void set xmlbase(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGElementInstance extends EventTarget {

  SVGElementInstanceList get childNodes();

  SVGElement get correspondingElement();

  SVGUseElement get correspondingUseElement();

  SVGElementInstance get firstChild();

  SVGElementInstance get lastChild();

  SVGElementInstance get nextSibling();

  SVGElementInstance get parentNode();

  SVGElementInstance get previousSibling();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event event);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGElementInstanceList {

  int get length();

  SVGElementInstance item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGEllipseElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGAnimatedLength get cx();

  SVGAnimatedLength get cy();

  SVGAnimatedLength get rx();

  SVGAnimatedLength get ry();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGException {

  static final int SVG_INVALID_VALUE_ERR = 1;

  static final int SVG_MATRIX_NOT_INVERTABLE = 2;

  static final int SVG_WRONG_TYPE_ERR = 0;

  int get code();

  String get message();

  String get name();

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGExternalResourcesRequired {

  SVGAnimatedBoolean get externalResourcesRequired();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  SVGAnimatedString get in1();

  SVGAnimatedString get in2();

  SVGAnimatedEnumeration get mode();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEColorMatrixElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static final int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static final int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static final int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static final int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  SVGAnimatedString get in1();

  SVGAnimatedEnumeration get type();

  SVGAnimatedNumberList get values();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEComponentTransferElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  SVGAnimatedString get in1();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  SVGAnimatedString get in1();

  SVGAnimatedString get in2();

  SVGAnimatedNumber get k1();

  SVGAnimatedNumber get k2();

  SVGAnimatedNumber get k3();

  SVGAnimatedNumber get k4();

  SVGAnimatedEnumeration get operator();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEConvolveMatrixElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  SVGAnimatedNumber get bias();

  SVGAnimatedNumber get divisor();

  SVGAnimatedEnumeration get edgeMode();

  SVGAnimatedString get in1();

  SVGAnimatedNumberList get kernelMatrix();

  SVGAnimatedNumber get kernelUnitLengthX();

  SVGAnimatedNumber get kernelUnitLengthY();

  SVGAnimatedInteger get orderX();

  SVGAnimatedInteger get orderY();

  SVGAnimatedBoolean get preserveAlpha();

  SVGAnimatedInteger get targetX();

  SVGAnimatedInteger get targetY();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEDiffuseLightingElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  SVGAnimatedNumber get diffuseConstant();

  SVGAnimatedString get in1();

  SVGAnimatedNumber get kernelUnitLengthX();

  SVGAnimatedNumber get kernelUnitLengthY();

  SVGAnimatedNumber get surfaceScale();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEDisplacementMapElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  SVGAnimatedString get in1();

  SVGAnimatedString get in2();

  SVGAnimatedNumber get scale();

  SVGAnimatedEnumeration get xChannelSelector();

  SVGAnimatedEnumeration get yChannelSelector();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEDistantLightElement extends SVGElement {

  SVGAnimatedNumber get azimuth();

  SVGAnimatedNumber get elevation();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEDropShadowElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  SVGAnimatedNumber get dx();

  SVGAnimatedNumber get dy();

  SVGAnimatedString get in1();

  SVGAnimatedNumber get stdDeviationX();

  SVGAnimatedNumber get stdDeviationY();

  void setStdDeviation(num stdDeviationX, num stdDeviationY);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEFloodElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEFuncAElement extends SVGComponentTransferFunctionElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEFuncBElement extends SVGComponentTransferFunctionElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEFuncGElement extends SVGComponentTransferFunctionElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEFuncRElement extends SVGComponentTransferFunctionElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEGaussianBlurElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  SVGAnimatedString get in1();

  SVGAnimatedNumber get stdDeviationX();

  SVGAnimatedNumber get stdDeviationY();

  void setStdDeviation(num stdDeviationX, num stdDeviationY);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEImageElement extends SVGElement, SVGURIReference, SVGLangSpace, SVGExternalResourcesRequired, SVGFilterPrimitiveStandardAttributes {

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEMergeElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEMergeNodeElement extends SVGElement {

  SVGAnimatedString get in1();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEMorphologyElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  SVGAnimatedString get in1();

  SVGAnimatedEnumeration get operator();

  SVGAnimatedNumber get radiusX();

  SVGAnimatedNumber get radiusY();

  void setRadius(num radiusX, num radiusY);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEOffsetElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  SVGAnimatedNumber get dx();

  SVGAnimatedNumber get dy();

  SVGAnimatedString get in1();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFEPointLightElement extends SVGElement {

  SVGAnimatedNumber get x();

  SVGAnimatedNumber get y();

  SVGAnimatedNumber get z();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFESpecularLightingElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  SVGAnimatedString get in1();

  SVGAnimatedNumber get specularConstant();

  SVGAnimatedNumber get specularExponent();

  SVGAnimatedNumber get surfaceScale();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFESpotLightElement extends SVGElement {

  SVGAnimatedNumber get limitingConeAngle();

  SVGAnimatedNumber get pointsAtX();

  SVGAnimatedNumber get pointsAtY();

  SVGAnimatedNumber get pointsAtZ();

  SVGAnimatedNumber get specularExponent();

  SVGAnimatedNumber get x();

  SVGAnimatedNumber get y();

  SVGAnimatedNumber get z();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFETileElement extends SVGElement, SVGFilterPrimitiveStandardAttributes {

  SVGAnimatedString get in1();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  SVGAnimatedNumber get baseFrequencyX();

  SVGAnimatedNumber get baseFrequencyY();

  SVGAnimatedInteger get numOctaves();

  SVGAnimatedNumber get seed();

  SVGAnimatedEnumeration get stitchTiles();

  SVGAnimatedEnumeration get type();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFilterElement extends SVGElement, SVGURIReference, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable {

  SVGAnimatedInteger get filterResX();

  SVGAnimatedInteger get filterResY();

  SVGAnimatedEnumeration get filterUnits();

  SVGAnimatedLength get height();

  SVGAnimatedEnumeration get primitiveUnits();

  SVGAnimatedLength get width();

  SVGAnimatedLength get x();

  SVGAnimatedLength get y();

  void setFilterRes(int filterResX, int filterResY);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFilterPrimitiveStandardAttributes extends SVGStylable {

  SVGAnimatedLength get height();

  SVGAnimatedString get result();

  SVGAnimatedLength get width();

  SVGAnimatedLength get x();

  SVGAnimatedLength get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFitToViewBox {

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio();

  SVGAnimatedRect get viewBox();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontFaceElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontFaceFormatElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontFaceNameElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontFaceSrcElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGFontFaceUriElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGForeignObjectElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGAnimatedLength get height();

  SVGAnimatedLength get width();

  SVGAnimatedLength get x();

  SVGAnimatedLength get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGGElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGGlyphElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGGlyphRefElement extends SVGElement, SVGURIReference, SVGStylable {

  num get dx();

  void set dx(num value);

  num get dy();

  void set dy(num value);

  String get format();

  void set format(String value);

  String get glyphRef();

  void set glyphRef(String value);

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGGradientElement extends SVGElement, SVGURIReference, SVGExternalResourcesRequired, SVGStylable {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  SVGAnimatedTransformList get gradientTransform();

  SVGAnimatedEnumeration get gradientUnits();

  SVGAnimatedEnumeration get spreadMethod();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGHKernElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGImageElement extends SVGElement, SVGURIReference, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGAnimatedLength get height();

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio();

  SVGAnimatedLength get width();

  SVGAnimatedLength get x();

  SVGAnimatedLength get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLangSpace {

  String get xmllang();

  void set xmllang(String value);

  String get xmlspace();

  void set xmlspace(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get unitType();

  num get value();

  void set value(num value);

  String get valueAsString();

  void set valueAsString(String value);

  num get valueInSpecifiedUnits();

  void set valueInSpecifiedUnits(num value);

  void convertToSpecifiedUnits(int unitType);

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLengthList {

  int get numberOfItems();

  SVGLength appendItem(SVGLength item);

  void clear();

  SVGLength getItem(int index);

  SVGLength initialize(SVGLength item);

  SVGLength insertItemBefore(SVGLength item, int index);

  SVGLength removeItem(int index);

  SVGLength replaceItem(SVGLength item, int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLineElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGAnimatedLength get x1();

  SVGAnimatedLength get x2();

  SVGAnimatedLength get y1();

  SVGAnimatedLength get y2();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLinearGradientElement extends SVGGradientElement {

  SVGAnimatedLength get x1();

  SVGAnimatedLength get x2();

  SVGAnimatedLength get y1();

  SVGAnimatedLength get y2();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGLocatable {

  SVGElement get farthestViewportElement();

  SVGElement get nearestViewportElement();

  SVGRect getBBox();

  SVGMatrix getCTM();

  SVGMatrix getScreenCTM();

  SVGMatrix getTransformToElement(SVGElement element);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMPathElement extends SVGElement, SVGURIReference, SVGExternalResourcesRequired {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  SVGAnimatedLength get markerHeight();

  SVGAnimatedEnumeration get markerUnits();

  SVGAnimatedLength get markerWidth();

  SVGAnimatedAngle get orientAngle();

  SVGAnimatedEnumeration get orientType();

  SVGAnimatedLength get refX();

  SVGAnimatedLength get refY();

  void setOrientToAngle(SVGAngle angle);

  void setOrientToAuto();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMaskElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable {

  SVGAnimatedLength get height();

  SVGAnimatedEnumeration get maskContentUnits();

  SVGAnimatedEnumeration get maskUnits();

  SVGAnimatedLength get width();

  SVGAnimatedLength get x();

  SVGAnimatedLength get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMatrix {

  num get a();

  void set a(num value);

  num get b();

  void set b(num value);

  num get c();

  void set c(num value);

  num get d();

  void set d(num value);

  num get e();

  void set e(num value);

  num get f();

  void set f(num value);

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMetadataElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGMissingGlyphElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGNumber {

  num get value();

  void set value(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGNumberList {

  int get numberOfItems();

  SVGNumber appendItem(SVGNumber item);

  void clear();

  SVGNumber getItem(int index);

  SVGNumber initialize(SVGNumber item);

  SVGNumber insertItemBefore(SVGNumber item, int index);

  SVGNumber removeItem(int index);

  SVGNumber replaceItem(SVGNumber item, int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get paintType();

  String get uri();

  void setPaint(int paintType, String uri, String rgbColor, String iccColor);

  void setUri(String uri);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGPathSegList get animatedNormalizedPathSegList();

  SVGPathSegList get animatedPathSegList();

  SVGPathSegList get normalizedPathSegList();

  SVGAnimatedNumber get pathLength();

  SVGPathSegList get pathSegList();

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get pathSegType();

  String get pathSegTypeAsLetter();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegArcAbs extends SVGPathSeg {

  num get angle();

  void set angle(num value);

  bool get largeArcFlag();

  void set largeArcFlag(bool value);

  num get r1();

  void set r1(num value);

  num get r2();

  void set r2(num value);

  bool get sweepFlag();

  void set sweepFlag(bool value);

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegArcRel extends SVGPathSeg {

  num get angle();

  void set angle(num value);

  bool get largeArcFlag();

  void set largeArcFlag(bool value);

  num get r1();

  void set r1(num value);

  num get r2();

  void set r2(num value);

  bool get sweepFlag();

  void set sweepFlag(bool value);

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegClosePath extends SVGPathSeg {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoCubicAbs extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get x1();

  void set x1(num value);

  num get x2();

  void set x2(num value);

  num get y();

  void set y(num value);

  num get y1();

  void set y1(num value);

  num get y2();

  void set y2(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoCubicRel extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get x1();

  void set x1(num value);

  num get x2();

  void set x2(num value);

  num get y();

  void set y(num value);

  num get y1();

  void set y1(num value);

  num get y2();

  void set y2(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoCubicSmoothAbs extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get x2();

  void set x2(num value);

  num get y();

  void set y(num value);

  num get y2();

  void set y2(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoCubicSmoothRel extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get x2();

  void set x2(num value);

  num get y();

  void set y(num value);

  num get y2();

  void set y2(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoQuadraticAbs extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get x1();

  void set x1(num value);

  num get y();

  void set y(num value);

  num get y1();

  void set y1(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoQuadraticRel extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get x1();

  void set x1(num value);

  num get y();

  void set y(num value);

  num get y1();

  void set y1(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoQuadraticSmoothAbs extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegCurvetoQuadraticSmoothRel extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoAbs extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoHorizontalAbs extends SVGPathSeg {

  num get x();

  void set x(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoHorizontalRel extends SVGPathSeg {

  num get x();

  void set x(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoRel extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoVerticalAbs extends SVGPathSeg {

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegLinetoVerticalRel extends SVGPathSeg {

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegList {

  int get numberOfItems();

  SVGPathSeg appendItem(SVGPathSeg newItem);

  void clear();

  SVGPathSeg getItem(int index);

  SVGPathSeg initialize(SVGPathSeg newItem);

  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index);

  SVGPathSeg removeItem(int index);

  SVGPathSeg replaceItem(SVGPathSeg newItem, int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegMovetoAbs extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPathSegMovetoRel extends SVGPathSeg {

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPatternElement extends SVGElement, SVGURIReference, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGFitToViewBox {

  SVGAnimatedLength get height();

  SVGAnimatedEnumeration get patternContentUnits();

  SVGAnimatedTransformList get patternTransform();

  SVGAnimatedEnumeration get patternUnits();

  SVGAnimatedLength get width();

  SVGAnimatedLength get x();

  SVGAnimatedLength get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPoint {

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);

  SVGPoint matrixTransform(SVGMatrix matrix);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPointList {

  int get numberOfItems();

  SVGPoint appendItem(SVGPoint item);

  void clear();

  SVGPoint getItem(int index);

  SVGPoint initialize(SVGPoint item);

  SVGPoint insertItemBefore(SVGPoint item, int index);

  SVGPoint removeItem(int index);

  SVGPoint replaceItem(SVGPoint item, int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPolygonElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGPointList get animatedPoints();

  SVGPointList get points();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGPolylineElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGPointList get animatedPoints();

  SVGPointList get points();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get align();

  void set align(int value);

  int get meetOrSlice();

  void set meetOrSlice(int value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGRadialGradientElement extends SVGGradientElement {

  SVGAnimatedLength get cx();

  SVGAnimatedLength get cy();

  SVGAnimatedLength get fx();

  SVGAnimatedLength get fy();

  SVGAnimatedLength get r();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGRect {

  num get height();

  void set height(num value);

  num get width();

  void set width(num value);

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGRectElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGAnimatedLength get height();

  SVGAnimatedLength get rx();

  SVGAnimatedLength get ry();

  SVGAnimatedLength get width();

  SVGAnimatedLength get x();

  SVGAnimatedLength get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGSVGElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGLocatable, SVGFitToViewBox, SVGZoomAndPan {

  String get contentScriptType();

  void set contentScriptType(String value);

  String get contentStyleType();

  void set contentStyleType(String value);

  num get currentScale();

  void set currentScale(num value);

  SVGPoint get currentTranslate();

  SVGAnimatedLength get height();

  num get pixelUnitToMillimeterX();

  num get pixelUnitToMillimeterY();

  num get screenPixelToMillimeterX();

  num get screenPixelToMillimeterY();

  bool get useCurrentView();

  void set useCurrentView(bool value);

  SVGRect get viewport();

  SVGAnimatedLength get width();

  SVGAnimatedLength get x();

  SVGAnimatedLength get y();

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGScriptElement extends SVGElement, SVGURIReference, SVGExternalResourcesRequired {

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGSetElement extends SVGAnimationElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGStopElement extends SVGElement, SVGStylable {

  SVGAnimatedNumber get offset();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGStringList {

  int get numberOfItems();

  String appendItem(String item);

  void clear();

  String getItem(int index);

  String initialize(String item);

  String insertItemBefore(String item, int index);

  String removeItem(int index);

  String replaceItem(String item, int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGStylable {

  SVGAnimatedString get className();

  CSSStyleDeclaration get style();

  CSSValue getPresentationAttribute(String name);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGStyleElement extends SVGElement, SVGLangSpace {

  String get media();

  void set media(String value);

  String get title();

  void set title(String value);

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGSwitchElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGSymbolElement extends SVGElement, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGFitToViewBox {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTRefElement extends SVGTextPositioningElement, SVGURIReference {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTSpanElement extends SVGTextPositioningElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTests {

  SVGStringList get requiredExtensions();

  SVGStringList get requiredFeatures();

  SVGStringList get systemLanguage();

  bool hasExtension(String extension);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTextContentElement extends SVGElement, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable {

  static final int LENGTHADJUST_SPACING = 1;

  static final int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static final int LENGTHADJUST_UNKNOWN = 0;

  SVGAnimatedEnumeration get lengthAdjust();

  SVGAnimatedLength get textLength();

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTextElement extends SVGTextPositioningElement, SVGTransformable {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  SVGAnimatedEnumeration get method();

  SVGAnimatedEnumeration get spacing();

  SVGAnimatedLength get startOffset();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTextPositioningElement extends SVGTextContentElement {

  SVGAnimatedLengthList get dx();

  SVGAnimatedLengthList get dy();

  SVGAnimatedNumberList get rotate();

  SVGAnimatedLengthList get x();

  SVGAnimatedLengthList get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTitleElement extends SVGElement, SVGLangSpace, SVGStylable {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  num get angle();

  SVGMatrix get matrix();

  int get type();

  void setMatrix(SVGMatrix matrix);

  void setRotate(num angle, num cx, num cy);

  void setScale(num sx, num sy);

  void setSkewX(num angle);

  void setSkewY(num angle);

  void setTranslate(num tx, num ty);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTransformList {

  int get numberOfItems();

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGTransformable extends SVGLocatable {

  SVGAnimatedTransformList get transform();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGURIReference {

  SVGAnimatedString get href();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGUnitTypes {

  static final int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static final int SVG_UNIT_TYPE_UNKNOWN = 0;

  static final int SVG_UNIT_TYPE_USERSPACEONUSE = 1;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGUseElement extends SVGElement, SVGURIReference, SVGTests, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable, SVGTransformable {

  SVGElementInstance get animatedInstanceRoot();

  SVGAnimatedLength get height();

  SVGElementInstance get instanceRoot();

  SVGAnimatedLength get width();

  SVGAnimatedLength get x();

  SVGAnimatedLength get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGVKernElement extends SVGElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGViewElement extends SVGElement, SVGExternalResourcesRequired, SVGFitToViewBox, SVGZoomAndPan {

  SVGStringList get viewTarget();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGViewSpec extends SVGZoomAndPan, SVGFitToViewBox {

  String get preserveAspectRatioString();

  SVGTransformList get transform();

  String get transformString();

  String get viewBoxString();

  SVGElement get viewTarget();

  String get viewTargetString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGZoomAndPan {

  static final int SVG_ZOOMANDPAN_DISABLE = 1;

  static final int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static final int SVG_ZOOMANDPAN_UNKNOWN = 0;

  int get zoomAndPan();

  void set zoomAndPan(int value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SVGZoomEvent extends UIEvent {

  num get newScale();

  SVGPoint get newTranslate();

  num get previousScale();

  SVGPoint get previousTranslate();

  SVGRect get zoomRectScreen();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Screen {

  int get availHeight();

  int get availLeft();

  int get availTop();

  int get availWidth();

  int get colorDepth();

  int get height();

  int get pixelDepth();

  int get width();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ScriptProfile {

  ScriptProfileNode get head();

  String get title();

  int get uid();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ScriptProfileNode {

  int get callUID();

  List get children();

  String get functionName();

  int get lineNumber();

  int get numberOfCalls();

  num get selfTime();

  num get totalTime();

  String get url();

  bool get visible();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ShadowRoot extends Node {

  Element get host();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SharedWorker extends AbstractWorker {

  MessagePort get port();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SharedWorkerGlobalScope extends WorkerContext {

  String get name();

  EventListener get onconnect();

  void set onconnect(EventListener value);
}

interface SharedWorkerContext extends SharedWorkerGlobalScope {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechInputEvent extends Event {

  SpeechInputResultList get results();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechInputResult {

  num get confidence();

  String get utterance();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SpeechInputResultList {

  int get length();

  SpeechInputResult item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Storage {

  int get length();

  void clear();

  String getItem(String key);

  String key(int index);

  void removeItem(String key);

  void setItem(String key, String data);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StorageEvent extends Event {

  String get key();

  String get newValue();

  String get oldValue();

  Storage get storageArea();

  String get url();

  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StyleMedia {

  String get type();

  bool matchMedium(String mediaquery);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StyleSheet {

  bool get disabled();

  void set disabled(bool value);

  String get href();

  MediaList get media();

  Node get ownerNode();

  StyleSheet get parentStyleSheet();

  String get title();

  String get type();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StyleSheetList extends List<StyleSheet> {

  int get length();

  StyleSheet item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Text extends CharacterData {

  String get wholeText();

  Text replaceWholeText(String content);

  Text splitText(int offset);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextEvent extends UIEvent {

  String get data();

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindow viewArg, String dataArg);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextMetrics {

  num get width();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrack {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  TextTrackCueList get activeCues();

  TextTrackCueList get cues();

  String get kind();

  String get label();

  String get language();

  int get mode();

  void set mode(int value);

  EventListener get oncuechange();

  void set oncuechange(EventListener value);

  void addCue(TextTrackCue cue);

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void removeCue(TextTrackCue cue);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrackCue {

  String get alignment();

  void set alignment(String value);

  String get direction();

  void set direction(String value);

  num get endTime();

  void set endTime(num value);

  String get id();

  void set id(String value);

  int get linePosition();

  void set linePosition(int value);

  EventListener get onenter();

  void set onenter(EventListener value);

  EventListener get onexit();

  void set onexit(EventListener value);

  bool get pauseOnExit();

  void set pauseOnExit(bool value);

  int get size();

  void set size(int value);

  bool get snapToLines();

  void set snapToLines(bool value);

  num get startTime();

  void set startTime(num value);

  String get text();

  void set text(String value);

  int get textPosition();

  void set textPosition(int value);

  TextTrack get track();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  DocumentFragment getCueAsHTML();

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrackCueList {

  int get length();

  TextTrackCue getCueById(String id);

  TextTrackCue item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextTrackList {

  int get length();

  EventListener get onaddtrack();

  void set onaddtrack(EventListener value);

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  TextTrack item(int index);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TimeRanges {

  int get length();

  num end(int index);

  num start(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Touch {

  int get clientX();

  int get clientY();

  int get identifier();

  int get pageX();

  int get pageY();

  int get screenX();

  int get screenY();

  EventTarget get target();

  num get webkitForce();

  int get webkitRadiusX();

  int get webkitRadiusY();

  num get webkitRotationAngle();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TouchEvent extends UIEvent {

  bool get altKey();

  TouchList get changedTouches();

  bool get ctrlKey();

  bool get metaKey();

  bool get shiftKey();

  TouchList get targetTouches();

  TouchList get touches();

  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TouchList extends List<Touch> {

  int get length();

  Touch item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TrackEvent extends Event {

  Object get track();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TreeWalker {

  Node get currentNode();

  void set currentNode(Node value);

  bool get expandEntityReferences();

  NodeFilter get filter();

  Node get root();

  int get whatToShow();

  Node firstChild();

  Node lastChild();

  Node nextNode();

  Node nextSibling();

  Node parentNode();

  Node previousNode();

  Node previousSibling();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface UIEvent extends Event {

  int get charCode();

  int get detail();

  int get keyCode();

  int get layerX();

  int get layerY();

  int get pageX();

  int get pageY();

  DOMWindow get view();

  int get which();

  void initUIEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint16Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Uint16Array(int length);

  Uint16Array.fromList(List<int> list);

  Uint16Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 2;

  int get length();

  void setElements(Object array, [int offset]);

  Uint16Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint32Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Uint32Array(int length);

  Uint32Array.fromList(List<int> list);

  Uint32Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 4;

  int get length();

  void setElements(Object array, [int offset]);

  Uint32Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint8Array extends ArrayBufferView, List<int> default _TypedArrayFactoryProvider {

  Uint8Array(int length);

  Uint8Array.fromList(List<int> list);

  Uint8Array.fromBuffer(ArrayBuffer buffer);

  static final int BYTES_PER_ELEMENT = 1;

  int get length();

  void setElements(Object array, [int offset]);

  Uint8Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint8ClampedArray extends Uint8Array default _TypedArrayFactoryProvider {

  Uint8ClampedArray(int length);

  Uint8ClampedArray.fromList(List<int> list);

  Uint8ClampedArray.fromBuffer(ArrayBuffer buffer);

  int get length();

  Uint8ClampedArray subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ValidityState {

  bool get customError();

  bool get patternMismatch();

  bool get rangeOverflow();

  bool get rangeUnderflow();

  bool get stepMismatch();

  bool get tooLong();

  bool get typeMismatch();

  bool get valid();

  bool get valueMissing();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

typedef void VoidCallback();
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WaveShaperNode extends AudioNode {

  Float32Array get curve();

  void set curve(Float32Array value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLActiveInfo {

  String get name();

  int get size();

  int get type();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLBuffer {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLCompressedTextures {

  static final int COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;

  static final int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  static final int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  static final int COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;

  static final int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;

  static final int ETC1_RGB8_OES = 0x8D64;

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, ArrayBufferView data);

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, ArrayBufferView data);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLContextAttributes {

  bool get alpha();

  void set alpha(bool value);

  bool get antialias();

  void set antialias(bool value);

  bool get depth();

  void set depth(bool value);

  bool get premultipliedAlpha();

  void set premultipliedAlpha(bool value);

  bool get preserveDrawingBuffer();

  void set preserveDrawingBuffer(bool value);

  bool get stencil();

  void set stencil(bool value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLContextEvent extends Event {

  String get statusMessage();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLDebugRendererInfo {

  static final int UNMASKED_RENDERER_WEBGL = 0x9246;

  static final int UNMASKED_VENDOR_WEBGL = 0x9245;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLDebugShaders {

  String getTranslatedShaderSource(WebGLShader shader);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLFramebuffer {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLLoseContext {

  void loseContext();

  void restoreContext();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLProgram {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLRenderbuffer {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  int get drawingBufferHeight();

  int get drawingBufferWidth();

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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLShader {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLTexture {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLUniformLocation {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebGLVertexArrayObjectOES {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitAnimation {

  static final int DIRECTION_ALTERNATE = 1;

  static final int DIRECTION_NORMAL = 0;

  static final int FILL_BACKWARDS = 1;

  static final int FILL_BOTH = 3;

  static final int FILL_FORWARDS = 2;

  static final int FILL_NONE = 0;

  num get delay();

  int get direction();

  num get duration();

  num get elapsedTime();

  void set elapsedTime(num value);

  bool get ended();

  int get fillMode();

  int get iterationCount();

  String get name();

  bool get paused();

  void pause();

  void play();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitAnimationEvent extends Event {

  String get animationName();

  num get elapsedTime();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitAnimationList {

  int get length();

  WebKitAnimation item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitBlobBuilder {

  void append(var arrayBuffer_OR_blob_OR_value, [String endings]);

  Blob getBlob([String contentType]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitCSSFilterValue extends CSSValueList {

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

  int get operationType();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitCSSKeyframeRule extends CSSRule {

  String get keyText();

  void set keyText(String value);

  CSSStyleDeclaration get style();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitCSSKeyframesRule extends CSSRule {

  CSSRuleList get cssRules();

  String get name();

  void set name(String value);

  void deleteRule(String key);

  WebKitCSSKeyframeRule findRule(String key);

  void insertRule(String rule);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitCSSMatrix default _WebKitCSSMatrixFactoryProvider {

  WebKitCSSMatrix([String spec]);

  num get a();

  void set a(num value);

  num get b();

  void set b(num value);

  num get c();

  void set c(num value);

  num get d();

  void set d(num value);

  num get e();

  void set e(num value);

  num get f();

  void set f(num value);

  num get m11();

  void set m11(num value);

  num get m12();

  void set m12(num value);

  num get m13();

  void set m13(num value);

  num get m14();

  void set m14(num value);

  num get m21();

  void set m21(num value);

  num get m22();

  void set m22(num value);

  num get m23();

  void set m23(num value);

  num get m24();

  void set m24(num value);

  num get m31();

  void set m31(num value);

  num get m32();

  void set m32(num value);

  num get m33();

  void set m33(num value);

  num get m34();

  void set m34(num value);

  num get m41();

  void set m41(num value);

  num get m42();

  void set m42(num value);

  num get m43();

  void set m43(num value);

  num get m44();

  void set m44(num value);

  WebKitCSSMatrix inverse();

  WebKitCSSMatrix multiply(WebKitCSSMatrix secondMatrix);

  WebKitCSSMatrix rotate(num rotX, num rotY, num rotZ);

  WebKitCSSMatrix rotateAxisAngle(num x, num y, num z, num angle);

  WebKitCSSMatrix scale(num scaleX, num scaleY, num scaleZ);

  void setMatrixValue(String string);

  WebKitCSSMatrix skewX(num angle);

  WebKitCSSMatrix skewY(num angle);

  String toString();

  WebKitCSSMatrix translate(num x, num y, num z);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitCSSRegionRule extends CSSRule {

  CSSRuleList get cssRules();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitCSSTransformValue extends CSSValueList {

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

  int get operationType();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitMutationObserver {

  void disconnect();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitNamedFlow {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitPoint default _WebKitPointFactoryProvider {

  WebKitPoint(num x, num y);

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebKitTransitionEvent extends Event {

  num get elapsedTime();

  String get propertyName();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WebSocket extends EventTarget default _WebSocketFactoryProvider {

  WebSocket(String url);

  static final int CLOSED = 3;

  static final int CLOSING = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String get URL();

  String get binaryType();

  void set binaryType(String value);

  int get bufferedAmount();

  String get extensions();

  String get protocol();

  int get readyState();

  String get url();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void close([int code, String reason]);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  bool send(String data);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WheelEvent extends UIEvent {

  bool get altKey();

  int get clientX();

  int get clientY();

  bool get ctrlKey();

  bool get metaKey();

  int get offsetX();

  int get offsetY();

  int get screenX();

  int get screenY();

  bool get shiftKey();

  bool get webkitDirectionInvertedFromDevice();

  int get wheelDelta();

  int get wheelDeltaX();

  int get wheelDeltaY();

  int get x();

  int get y();

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Worker extends AbstractWorker {

  void postMessage(Dynamic message, [List messagePorts]);

  void terminate();

  void webkitPostMessage(Dynamic message, [List messagePorts]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WorkerGlobalScope {

  WorkerLocation get location();

  void set location(WorkerLocation value);

  WorkerNavigator get navigator();

  void set navigator(WorkerNavigator value);

  EventListener get onerror();

  void set onerror(EventListener value);

  WorkerContext get self();

  void set self(WorkerContext value);

  IDBFactory get webkitIndexedDB();

  NotificationCenter get webkitNotifications();

  DOMURL get webkitURL();

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

interface WorkerContext extends WorkerGlobalScope {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WorkerLocation {

  String get hash();

  String get host();

  String get hostname();

  String get href();

  String get pathname();

  String get port();

  String get protocol();

  String get search();

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WorkerNavigator {

  String get appName();

  String get appVersion();

  bool get onLine();

  String get platform();

  String get userAgent();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequest extends EventTarget default _XMLHttpRequestFactoryProvider {

  XMLHttpRequest();


  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  bool get asBlob();

  void set asBlob(bool value);

  int get readyState();

  Object get response();

  Blob get responseBlob();

  String get responseText();

  String get responseType();

  void set responseType(String value);

  Document get responseXML();

  int get status();

  String get statusText();

  XMLHttpRequestUpload get upload();

  bool get withCredentials();

  void set withCredentials(bool value);

  void abort();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  String getAllResponseHeaders();

  String getResponseHeader(String header);

  void open(String method, String url, [bool async, String user, String password]);

  void overrideMimeType(String override);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  void send([var data]);

  void setRequestHeader(String header, String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequestException {

  static final int ABORT_ERR = 102;

  static final int NETWORK_ERR = 101;

  int get code();

  String get message();

  String get name();

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequestProgressEvent extends ProgressEvent {

  int get position();

  int get totalSize();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequestUpload extends EventTarget {

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLSerializer {

  String serializeToString(Node node);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XPathEvaluator {

  XPathExpression createExpression(String expression, XPathNSResolver resolver);

  XPathNSResolver createNSResolver(Node nodeResolver);

  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XPathException {

  static final int INVALID_EXPRESSION_ERR = 51;

  static final int TYPE_ERR = 52;

  int get code();

  String get message();

  String get name();

  String toString();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XPathExpression {

  XPathResult evaluate(Node contextNode, int type, XPathResult inResult);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XPathNSResolver {

  String lookupNamespaceURI(String prefix);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  bool get booleanValue();

  bool get invalidIteratorState();

  num get numberValue();

  int get resultType();

  Node get singleNodeValue();

  int get snapshotLength();

  String get stringValue();

  Node iterateNext();

  Node snapshotItem(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XSLTProcessor {

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

interface DOMType {
  // TODO(vsm): Remove if/when Dart supports OLS for all objects.
  var dartObjectLocalStorage;

  String get typeName();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _DOMTypeJs implements DOMType native '*DOMType' {

  var dartObjectLocalStorage;

  String get typeName() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// These factory methods could all live in one factory provider class but dartc
// has a bug (5399939) preventing that.

class _AudioContextFactoryProvider {

  factory AudioContext() native '''
    var constructor = window.AudioContext || window.webkitAudioContext;
    return new constructor();
''';
}

class _DOMParserFactoryProvider {
  factory DOMParser() native '''return new DOMParser();''';
}

class _FileReaderFactoryProvider {

  factory FileReader() native '''return new FileReader();''';
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

class _WebKitCSSMatrixFactoryProvider {

  factory WebKitCSSMatrix([String spec = '']) native
      '''return new WebKitCSSMatrix(spec);''';
}

class _WebKitPointFactoryProvider {

  factory WebKitPoint(num x, num y) native '''return new WebKitPoint(x, y);''';
}

class _WebSocketFactoryProvider {

  factory WebSocket(String url) native '''return new WebSocket(url);''';
}

class _XMLHttpRequestFactoryProvider {

  factory XMLHttpRequest() native '''return new XMLHttpRequest();''';
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
