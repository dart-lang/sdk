#library('dom');

#native('frog_dom.js');
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated Dart DOM library.




class Window extends DOMWindow {}
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

  int byteLength;

  ArrayBuffer slice(int begin, [int end = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ArrayBufferView native "*ArrayBufferView" {

  ArrayBuffer buffer;

  int byteLength;

  int byteOffset;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Attr extends Node native "*Attr" {

  bool isId;

  String name;

  Element ownerElement;

  bool specified;

  String value;
}

class BarInfo native "*BarInfo" {

  bool visible;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class BeforeLoadEvent extends Event native "*BeforeLoadEvent" {

  String url;

  void initBeforeLoadEvent(String type, bool canBubble, bool cancelable, String url) native;
}

class Blob native "*Blob" {

  int size;

  String type;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CDATASection extends Text native "*CDATASection" {
}

class CSSCharsetRule extends CSSRule native "*CSSCharsetRule" {

  String encoding;
}

class CSSFontFaceRule extends CSSRule native "*CSSFontFaceRule" {

  CSSStyleDeclaration style;
}

class CSSImportRule extends CSSRule native "*CSSImportRule" {

  String href;

  MediaList media;

  CSSStyleSheet styleSheet;
}

class CSSMediaRule extends CSSRule native "*CSSMediaRule" {

  CSSRuleList cssRules;

  MediaList media;

  void deleteRule(int index) native;

  int insertRule(String rule, int index) native;
}

class CSSPageRule extends CSSRule native "*CSSPageRule" {

  String selectorText;

  CSSStyleDeclaration style;
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

  int primitiveType;

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

  static final int WEBKIT_REGION_STYLE_RULE = 10;

  String cssText;

  CSSRule parentRule;

  CSSStyleSheet parentStyleSheet;

  int type;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CSSRuleList native "*CSSRuleList" {

  int length;

  CSSRule item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CSSStyleDeclaration native "*CSSStyleDeclaration" {

  String cssText;

  int length;

  CSSRule parentRule;

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

  String selectorText;

  CSSStyleDeclaration style;
}

class CSSStyleSheet extends StyleSheet native "*CSSStyleSheet" {

  CSSRuleList cssRules;

  CSSRule ownerRule;

  CSSRuleList rules;

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

  String cssText;

  int cssValueType;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CSSValueList extends CSSValue native "*CSSValueList" {

  int length;

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

  int length;

  int operator[](int index) native;

  int item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CanvasRenderingContext native "*CanvasRenderingContext" {

  HTMLCanvasElement canvas;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CanvasRenderingContext2D extends CanvasRenderingContext native "*CanvasRenderingContext2D" {

  Object fillStyle;

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

  Object strokeStyle;

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

  ImageData createImageData(var imagedata_OR_sw, [num sh = null]) native;

  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) native;

  CanvasPattern createPattern(var canvas_OR_image, String repetitionType) native;

  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) native;

  void drawImage(var canvas_OR_image, num sx_OR_x, num sy_OR_y, [num sw_OR_width = null, num height_OR_sh = null, num dx = null, num dy = null, num dw = null, num dh = null]) native;

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

  String data;

  int length;

  void appendData(String data) native;

  void deleteData(int offset, int length) native;

  void insertData(int offset, String data) native;

  void replaceData(int offset, int length, String data) native;

  String substringData(int offset, int length) native;
}

class ClientRect native "*ClientRect" {

  num bottom;

  num height;

  num left;

  num right;

  num top;

  num width;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ClientRectList native "*ClientRectList" {

  int length;

  ClientRect item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Clipboard native "*Clipboard" {

  String dropEffect;

  String effectAllowed;

  FileList files;

  DataTransferItemList items;

  List types;

  void clearData([String type = null]) native;

  void getData(String type) native;

  bool setData(String type, String data) native;

  void setDragImage(HTMLImageElement image, int x, int y) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CloseEvent extends Event native "*CloseEvent" {

  int code;

  String reason;

  bool wasClean;

  void initCloseEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool wasCleanArg, int codeArg, String reasonArg) native;
}

class Comment extends CharacterData native "*Comment" {
}

class CompositionEvent extends UIEvent native "*CompositionEvent" {

  String data;

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindow viewArg, String dataArg) native;
}

class Console native "*Console" {

  MemoryInfo memory;

  void assert(bool condition) native;

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

  void time(String title) native;

  void timeEnd(String title) native;

  void timeStamp() native;

  void trace(Object arg) native;

  void warn(Object arg) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Coordinates native "*Coordinates" {

  num accuracy;

  num altitude;

  num altitudeAccuracy;

  num heading;

  num latitude;

  num longitude;

  num speed;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Counter native "*Counter" {

  String identifier;

  String listStyle;

  String separator;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Crypto native "*Crypto" {

  void getRandomValues(ArrayBufferView array) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class CustomEvent extends Event native "*CustomEvent" {

  Object detail;

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) native;
}

class DOMApplicationCache native "*DOMApplicationCache" {

  static final int CHECKING = 2;

  static final int DOWNLOADING = 3;

  static final int IDLE = 1;

  static final int OBSOLETE = 5;

  static final int UNCACHED = 0;

  static final int UPDATEREADY = 4;

  int status;

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

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMFileSystem native "*DOMFileSystem" {

  String name;

  DirectoryEntry root;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMFileSystemSync native "*DOMFileSystemSync" {

  String name;

  DirectoryEntrySync root;

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

  String description;

  DOMPlugin enabledPlugin;

  String suffixes;

  String type;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMMimeTypeArray native "*DOMMimeTypeArray" {

  int length;

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

  String description;

  String filename;

  int length;

  String name;

  DOMMimeType item(int index) native;

  DOMMimeType namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMPluginArray native "*DOMPluginArray" {

  int length;

  DOMPlugin item(int index) native;

  DOMPlugin namedItem(String name) native;

  void refresh(bool reload) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DOMSelection native "*DOMSelection" {

  Node anchorNode;

  int anchorOffset;

  Node baseNode;

  int baseOffset;

  Node extentNode;

  int extentOffset;

  Node focusNode;

  int focusOffset;

  bool isCollapsed;

  int rangeCount;

  String type;

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

  String value;
}

class DOMTokenList native "*DOMTokenList" {

  int length;

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

// TODO(jmesserly): generator needs to know to put in @
class DOMWindow native "@*DOMWindow" {

  DOMApplicationCache applicationCache;

  Navigator clientInformation;

  bool closed;

  Console console;

  Crypto crypto;

  String defaultStatus;

  String defaultstatus;

  num devicePixelRatio;

  Document document;

  Event event;

  Element frameElement;

  DOMWindow frames;

  History history;

  int innerHeight;

  int innerWidth;

  int length;

  Storage localStorage;

  Location location;

  BarInfo locationbar;

  BarInfo menubar;

  String name;

  Navigator navigator;

  bool offscreenBuffering;

  DOMWindow opener;

  int outerHeight;

  int outerWidth;

  int pageXOffset;

  int pageYOffset;

  DOMWindow parent;

  Performance performance;

  BarInfo personalbar;

  Screen screen;

  int screenLeft;

  int screenTop;

  int screenX;

  int screenY;

  int scrollX;

  int scrollY;

  BarInfo scrollbars;

  DOMWindow self;

  Storage sessionStorage;

  String status;

  BarInfo statusbar;

  StyleMedia styleMedia;

  BarInfo toolbar;

  DOMWindow top;

  NotificationCenter webkitNotifications;

  DOMURL webkitURL;

  DOMWindow window;

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

  void postMessage(String message, var messagePorts_OR_targetOrigin, [String targetOrigin = null]) native;

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

  void webkitCancelRequestAnimationFrame(int id) native;

  WebKitPoint webkitConvertPointFromNodeToPage(Node node, WebKitPoint p) native;

  WebKitPoint webkitConvertPointFromPageToNode(Node node, WebKitPoint p) native;

  void webkitPostMessage(String message, var targetOrigin_OR_transferList, [String targetOrigin = null]) native;

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, Element element) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DataTransferItem native "*DataTransferItem" {

  String kind;

  String type;

  Blob getAsFile() native;

  void getAsString(StringCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DataTransferItemList native "*DataTransferItemList" {

  int length;

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

  String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback = null, SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DatabaseCallback native "*DatabaseCallback" {

  bool handleEvent(var database) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DatabaseSync native "*DatabaseSync" {

  String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback = null]) native;

  void readTransaction(SQLTransactionSyncCallback callback) native;

  void transaction(SQLTransactionSyncCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class DedicatedWorkerContext extends WorkerContext native "*DedicatedWorkerContext" {

  void postMessage(Object message, [List messagePorts = null]) native;

  void webkitPostMessage(Object message, [List transferList = null]) native;
}

class DeviceMotionEvent extends Event native "*DeviceMotionEvent" {

  num interval;
}

class DeviceOrientationEvent extends Event native "*DeviceOrientationEvent" {

  num alpha;

  num beta;

  num gamma;

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma) native;
}

class DirectoryEntry extends Entry native "*DirectoryEntry" {

  DirectoryReader createReader() native;

  void getDirectory(String path, [WebKitFlags flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getFile(String path, [WebKitFlags flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void removeRecursively([VoidCallback successCallback = null, ErrorCallback errorCallback = null]) native;
}

class DirectoryEntrySync extends EntrySync native "*DirectoryEntrySync" {

  DirectoryReaderSync createReader() native;

  DirectoryEntrySync getDirectory(String path, WebKitFlags flags) native;

  FileEntrySync getFile(String path, WebKitFlags flags) native;

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

  String URL;

  HTMLCollection anchors;

  HTMLCollection applets;

  HTMLElement body;

  String characterSet;

  String charset;

  String compatMode;

  String cookie;

  String defaultCharset;

  DOMWindow defaultView;

  DocumentType doctype;

  Element documentElement;

  String documentURI;

  String domain;

  HTMLCollection forms;

  HTMLHeadElement head;

  HTMLCollection images;

  DOMImplementation implementation;

  String inputEncoding;

  String lastModified;

  HTMLCollection links;

  Location location;

  String preferredStylesheetSet;

  String readyState;

  String referrer;

  String selectedStylesheetSet;

  StyleSheetList styleSheets;

  String title;

  bool webkitHidden;

  String webkitVisibilityState;

  String xmlEncoding;

  bool xmlStandalone;

  String xmlVersion;

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

  Node importNode(Node importedNode, bool deep) native;

  bool queryCommandEnabled(String command) native;

  bool queryCommandIndeterm(String command) native;

  bool queryCommandState(String command) native;

  bool queryCommandSupported(String command) native;

  String queryCommandValue(String command) native;

  Element querySelector(String selectors) native;

  NodeList querySelectorAll(String selectors) native;
}

class DocumentFragment extends Node native "*DocumentFragment" {

  Element querySelector(String selectors) native;

  NodeList querySelectorAll(String selectors) native;
}

class DocumentType extends Node native "*DocumentType" {

  NamedNodeMap entities;

  String internalSubset;

  String name;

  NamedNodeMap notations;

  String publicId;

  String systemId;
}

class Element extends Node native "*Element" {

  int childElementCount;

  int clientHeight;

  int clientLeft;

  int clientTop;

  int clientWidth;

  Element firstElementChild;

  Element lastElementChild;

  Element nextElementSibling;

  int offsetHeight;

  int offsetLeft;

  Element offsetParent;

  int offsetTop;

  int offsetWidth;

  Element previousElementSibling;

  int scrollHeight;

  int scrollLeft;

  int scrollTop;

  int scrollWidth;

  CSSStyleDeclaration style;

  String tagName;

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

  int childElementCount;

  Element firstElementChild;

  Element lastElementChild;

  Element nextElementSibling;

  Element previousElementSibling;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Entity extends Node native "*Entity" {

  String notationName;

  String publicId;

  String systemId;
}

class EntityReference extends Node native "*EntityReference" {
}

class EntriesCallback native "*EntriesCallback" {

  bool handleEvent(EntryArray entries) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Entry native "*Entry" {

  DOMFileSystem filesystem;

  String fullPath;

  bool isDirectory;

  bool isFile;

  String name;

  void copyTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getMetadata([MetadataCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void getParent([EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void moveTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  void remove([VoidCallback successCallback = null, ErrorCallback errorCallback = null]) native;

  String toURL() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EntryArray native "*EntryArray" {

  int length;

  Entry item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EntryArraySync native "*EntryArraySync" {

  int length;

  EntrySync item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EntryCallback native "*EntryCallback" {

  bool handleEvent(Entry entry) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EntrySync native "*EntrySync" {

  DOMFileSystemSync filesystem;

  String fullPath;

  bool isDirectory;

  bool isFile;

  String name;

  EntrySync copyTo(DirectoryEntrySync parent, String name) native;

  Metadata getMetadata() native;

  DirectoryEntrySync getParent() native;

  EntrySync moveTo(DirectoryEntrySync parent, String name) native;

  void remove() native;

  String toURL() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ErrorCallback native "*ErrorCallback" {

  bool handleEvent(FileError error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ErrorEvent extends Event native "*ErrorEvent" {

  String filename;

  int lineno;

  String message;

  void initErrorEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String messageArg, String filenameArg, int linenoArg) native;
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

  bool bubbles;

  bool cancelBubble;

  bool cancelable;

  Clipboard clipboardData;

  EventTarget currentTarget;

  bool defaultPrevented;

  int eventPhase;

  bool returnValue;

  EventTarget srcElement;

  EventTarget target;

  int timeStamp;

  String type;

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

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EventSource native "*EventSource" {

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String URL;

  int readyState;

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

  String fileName;

  int fileSize;

  Date lastModifiedDate;

  String name;
}

class FileCallback native "*FileCallback" {

  bool handleEvent(File file) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

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

  int code;

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

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class FileList native "*FileList" {

  int length;

  File item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class FileReader native "*FileReader" {
  FileReader() native;


  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  FileError error;

  int readyState;

  Object result;

  void abort() native;

  void readAsArrayBuffer(Blob blob) native;

  void readAsBinaryString(Blob blob) native;

  void readAsDataURL(Blob blob) native;

  void readAsText(Blob blob, [String encoding = null]) native;

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

class FileSystemCallback native "*FileSystemCallback" {

  bool handleEvent(DOMFileSystem fileSystem) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class FileWriter native "*FileWriter" {

  static final int DONE = 2;

  static final int INIT = 0;

  static final int WRITING = 1;

  FileError error;

  int length;

  int position;

  int readyState;

  void abort() native;

  void seek(int position) native;

  void truncate(int size) native;

  void write(Blob data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class FileWriterCallback native "*FileWriterCallback" {

  bool handleEvent(FileWriter fileWriter) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class FileWriterSync native "*FileWriterSync" {

  int length;

  int position;

  void seek(int position) native;

  void truncate(int size) native;

  void write(Blob data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Float32Array extends ArrayBufferView native "*Float32Array" {

  static final int BYTES_PER_ELEMENT = 4;

  int length;

  Float32Array subarray(int start, [int end = null]) native;
}

class Float64Array extends ArrayBufferView native "*Float64Array" {

  static final int BYTES_PER_ELEMENT = 8;

  int length;

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

  Coordinates coords;

  int timestamp;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class HTMLAllCollection native "*HTMLAllCollection" {

  int length;

  Node item(int index) native;

  Node namedItem(String name) native;

  NodeList tags(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class HTMLAnchorElement extends HTMLElement native "*HTMLAnchorElement" {

  String accessKey;

  String charset;

  String coords;

  String download;

  String hash;

  String host;

  String hostname;

  String href;

  String hreflang;

  String name;

  String origin;

  String pathname;

  String ping;

  String port;

  String protocol;

  String rel;

  String rev;

  String search;

  String shape;

  String target;

  String text;

  String type;

  String getParameter(String name) native;

  String toString() native;
}

class HTMLAppletElement extends HTMLElement native "*HTMLAppletElement" {

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

class HTMLAreaElement extends HTMLElement native "*HTMLAreaElement" {

  String accessKey;

  String alt;

  String coords;

  String hash;

  String host;

  String hostname;

  String href;

  bool noHref;

  String pathname;

  String ping;

  String port;

  String protocol;

  String search;

  String shape;

  String target;
}

class HTMLAudioElement extends HTMLMediaElement native "*HTMLAudioElement" {
}

class HTMLBRElement extends HTMLElement native "*HTMLBRElement" {

  String clear;
}

class HTMLBaseElement extends HTMLElement native "*HTMLBaseElement" {

  String href;

  String target;
}

class HTMLBaseFontElement extends HTMLElement native "*HTMLBaseFontElement" {

  String color;

  String face;

  int size;
}

class HTMLBodyElement extends HTMLElement native "*HTMLBodyElement" {

  String aLink;

  String background;

  String bgColor;

  String link;

  String text;

  String vLink;
}

class HTMLButtonElement extends HTMLElement native "*HTMLButtonElement" {

  String accessKey;

  bool autofocus;

  bool disabled;

  HTMLFormElement form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  NodeList labels;

  String name;

  String type;

  String validationMessage;

  ValidityState validity;

  String value;

  bool willValidate;

  bool checkValidity() native;

  void click() native;

  void setCustomValidity(String error) native;
}

class HTMLCanvasElement extends HTMLElement native "*HTMLCanvasElement" {

  int height;

  int width;

  Object getContext(String contextId) native;

  String toDataURL(String type) native;
}

class HTMLCollection native "*HTMLCollection" {

  int length;

  Node operator[](int index) native;

  Node item(int index) native;

  Node namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class HTMLDListElement extends HTMLElement native "*HTMLDListElement" {

  bool compact;
}

class HTMLDataListElement extends HTMLElement native "*HTMLDataListElement" {

  HTMLCollection options;
}

class HTMLDetailsElement extends HTMLElement native "*HTMLDetailsElement" {

  bool open;
}

class HTMLDirectoryElement extends HTMLElement native "*HTMLDirectoryElement" {

  bool compact;
}

class HTMLDivElement extends HTMLElement native "*HTMLDivElement" {

  String align;
}

class HTMLDocument extends Document native "*HTMLDocument" {

  Element activeElement;

  String alinkColor;

  HTMLAllCollection all;

  String bgColor;

  String compatMode;

  String designMode;

  String dir;

  HTMLCollection embeds;

  String fgColor;

  int height;

  String linkColor;

  HTMLCollection plugins;

  HTMLCollection scripts;

  String vlinkColor;

  int width;

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

  HTMLCollection children;

  DOMTokenList classList;

  String className;

  String contentEditable;

  String dir;

  bool draggable;

  bool hidden;

  String id;

  String innerHTML;

  String innerText;

  bool isContentEditable;

  String itemId;

  DOMSettableTokenList itemProp;

  DOMSettableTokenList itemRef;

  bool itemScope;

  DOMSettableTokenList itemType;

  Object itemValue;

  String lang;

  String outerHTML;

  String outerText;

  bool spellcheck;

  int tabIndex;

  String title;

  String webkitdropzone;

  Element insertAdjacentElement(String where, Element element) native;

  void insertAdjacentHTML(String where, String html) native;

  void insertAdjacentText(String where, String text) native;
}

class HTMLEmbedElement extends HTMLElement native "*HTMLEmbedElement" {

  String align;

  String height;

  String name;

  String src;

  String type;

  String width;
}

class HTMLFieldSetElement extends HTMLElement native "*HTMLFieldSetElement" {

  HTMLFormElement form;

  String validationMessage;

  ValidityState validity;

  bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class HTMLFontElement extends HTMLElement native "*HTMLFontElement" {

  String color;

  String face;

  String size;
}

class HTMLFormElement extends HTMLElement native "*HTMLFormElement" {

  String acceptCharset;

  String action;

  String autocomplete;

  HTMLCollection elements;

  String encoding;

  String enctype;

  int length;

  String method;

  String name;

  bool noValidate;

  String target;

  bool checkValidity() native;

  void reset() native;

  void submit() native;
}

class HTMLFrameElement extends HTMLElement native "*HTMLFrameElement" {

  Document contentDocument;

  DOMWindow contentWindow;

  String frameBorder;

  int height;

  String location;

  String longDesc;

  String marginHeight;

  String marginWidth;

  String name;

  bool noResize;

  String scrolling;

  String src;

  int width;
}

class HTMLFrameSetElement extends HTMLElement native "*HTMLFrameSetElement" {

  String cols;

  String rows;
}

class HTMLHRElement extends HTMLElement native "*HTMLHRElement" {

  String align;

  bool noShade;

  String size;

  String width;
}

class HTMLHeadElement extends HTMLElement native "*HTMLHeadElement" {

  String profile;
}

class HTMLHeadingElement extends HTMLElement native "*HTMLHeadingElement" {

  String align;
}

class HTMLHtmlElement extends HTMLElement native "*HTMLHtmlElement" {

  String manifest;

  String version;
}

class HTMLIFrameElement extends HTMLElement native "*HTMLIFrameElement" {

  String align;

  Document contentDocument;

  DOMWindow contentWindow;

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
}

class HTMLImageElement extends HTMLElement native "*HTMLImageElement" {

  String align;

  String alt;

  String border;

  bool complete;

  String crossOrigin;

  int height;

  int hspace;

  bool isMap;

  String longDesc;

  String lowsrc;

  String name;

  int naturalHeight;

  int naturalWidth;

  String src;

  String useMap;

  int vspace;

  int width;

  int x;

  int y;
}

class HTMLInputElement extends HTMLElement native "*HTMLInputElement" {

  String accept;

  String accessKey;

  String align;

  String alt;

  String autocomplete;

  bool autofocus;

  bool checked;

  bool defaultChecked;

  String defaultValue;

  bool disabled;

  FileList files;

  HTMLFormElement form;

  String formAction;

  String formEnctype;

  String formMethod;

  bool formNoValidate;

  String formTarget;

  bool incremental;

  bool indeterminate;

  NodeList labels;

  HTMLElement list;

  String max;

  int maxLength;

  String min;

  bool multiple;

  String name;

  String pattern;

  String placeholder;

  bool readOnly;

  bool required;

  HTMLOptionElement selectedOption;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  int size;

  String src;

  String step;

  String type;

  String useMap;

  String validationMessage;

  ValidityState validity;

  String value;

  Date valueAsDate;

  num valueAsNumber;

  bool webkitGrammar;

  bool webkitSpeech;

  bool webkitdirectory;

  bool willValidate;

  bool checkValidity() native;

  void click() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;

  void stepDown([int n = null]) native;

  void stepUp([int n = null]) native;
}

class HTMLIsIndexElement extends HTMLInputElement native "*HTMLIsIndexElement" {

  HTMLFormElement form;

  String prompt;
}

class HTMLKeygenElement extends HTMLElement native "*HTMLKeygenElement" {

  bool autofocus;

  String challenge;

  bool disabled;

  HTMLFormElement form;

  String keytype;

  NodeList labels;

  String name;

  String type;

  String validationMessage;

  ValidityState validity;

  bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class HTMLLIElement extends HTMLElement native "*HTMLLIElement" {

  String type;

  int value;
}

class HTMLLabelElement extends HTMLElement native "*HTMLLabelElement" {

  String accessKey;

  HTMLElement control;

  HTMLFormElement form;

  String htmlFor;
}

class HTMLLegendElement extends HTMLElement native "*HTMLLegendElement" {

  String accessKey;

  String align;

  HTMLFormElement form;
}

class HTMLLinkElement extends HTMLElement native "*HTMLLinkElement" {

  String charset;

  bool disabled;

  String href;

  String hreflang;

  String media;

  String rel;

  String rev;

  StyleSheet sheet;

  DOMSettableTokenList sizes;

  String target;

  String type;
}

class HTMLMapElement extends HTMLElement native "*HTMLMapElement" {

  HTMLCollection areas;

  String name;
}

class HTMLMarqueeElement extends HTMLElement native "*HTMLMarqueeElement" {

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

class HTMLMediaElement extends HTMLElement native "*HTMLMediaElement" {

  static final int HAVE_CURRENT_DATA = 2;

  static final int HAVE_ENOUGH_DATA = 4;

  static final int HAVE_FUTURE_DATA = 3;

  static final int HAVE_METADATA = 1;

  static final int HAVE_NOTHING = 0;

  static final int NETWORK_EMPTY = 0;

  static final int NETWORK_IDLE = 1;

  static final int NETWORK_LOADING = 2;

  static final int NETWORK_NO_SOURCE = 3;

  bool autoplay;

  TimeRanges buffered;

  bool controls;

  String currentSrc;

  num currentTime;

  bool defaultMuted;

  num defaultPlaybackRate;

  num duration;

  bool ended;

  MediaError error;

  num initialTime;

  bool loop;

  bool muted;

  int networkState;

  bool paused;

  num playbackRate;

  TimeRanges played;

  String preload;

  int readyState;

  TimeRanges seekable;

  bool seeking;

  String src;

  num startTime;

  num volume;

  int webkitAudioDecodedByteCount;

  bool webkitClosedCaptionsVisible;

  bool webkitHasClosedCaptions;

  bool webkitPreservesPitch;

  int webkitVideoDecodedByteCount;

  String canPlayType(String type) native;

  void load() native;

  void pause() native;

  void play() native;
}

class HTMLMenuElement extends HTMLElement native "*HTMLMenuElement" {

  bool compact;
}

class HTMLMetaElement extends HTMLElement native "*HTMLMetaElement" {

  String content;

  String httpEquiv;

  String name;

  String scheme;
}

class HTMLMeterElement extends HTMLElement native "*HTMLMeterElement" {

  HTMLFormElement form;

  num high;

  NodeList labels;

  num low;

  num max;

  num min;

  num optimum;

  num value;
}

class HTMLModElement extends HTMLElement native "*HTMLModElement" {

  String cite;

  String dateTime;
}

class HTMLOListElement extends HTMLElement native "*HTMLOListElement" {

  bool compact;

  int start;

  String type;
}

class HTMLObjectElement extends HTMLElement native "*HTMLObjectElement" {

  String align;

  String archive;

  String border;

  String code;

  String codeBase;

  String codeType;

  Document contentDocument;

  String data;

  bool declare;

  HTMLFormElement form;

  String height;

  int hspace;

  String name;

  String standby;

  String type;

  String useMap;

  String validationMessage;

  ValidityState validity;

  int vspace;

  String width;

  bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class HTMLOptGroupElement extends HTMLElement native "*HTMLOptGroupElement" {

  bool disabled;

  String label;
}

class HTMLOptionElement extends HTMLElement native "*HTMLOptionElement" {

  bool defaultSelected;

  bool disabled;

  HTMLFormElement form;

  int index;

  String label;

  bool selected;

  String text;

  String value;
}

class HTMLOptionsCollection extends HTMLCollection native "*HTMLOptionsCollection" {

  int length;

  int selectedIndex;

  void remove(int index) native;
}

class HTMLOutputElement extends HTMLElement native "*HTMLOutputElement" {

  String defaultValue;

  HTMLFormElement form;

  DOMSettableTokenList htmlFor;

  NodeList labels;

  String name;

  String type;

  String validationMessage;

  ValidityState validity;

  String value;

  bool willValidate;

  bool checkValidity() native;

  void setCustomValidity(String error) native;
}

class HTMLParagraphElement extends HTMLElement native "*HTMLParagraphElement" {

  String align;
}

class HTMLParamElement extends HTMLElement native "*HTMLParamElement" {

  String name;

  String type;

  String value;

  String valueType;
}

class HTMLPreElement extends HTMLElement native "*HTMLPreElement" {

  int width;

  bool wrap;
}

class HTMLProgressElement extends HTMLElement native "*HTMLProgressElement" {

  HTMLFormElement form;

  NodeList labels;

  num max;

  num position;

  num value;
}

class HTMLQuoteElement extends HTMLElement native "*HTMLQuoteElement" {

  String cite;
}

class HTMLScriptElement extends HTMLElement native "*HTMLScriptElement" {

  bool async;

  String charset;

  bool defer;

  String event;

  String htmlFor;

  String src;

  String text;

  String type;
}

class HTMLSelectElement extends HTMLElement native "*HTMLSelectElement" {

  bool autofocus;

  bool disabled;

  HTMLFormElement form;

  NodeList labels;

  int length;

  bool multiple;

  String name;

  HTMLOptionsCollection options;

  bool required;

  int selectedIndex;

  int size;

  String type;

  String validationMessage;

  ValidityState validity;

  String value;

  bool willValidate;

  void add(HTMLElement element, HTMLElement before) native;

  bool checkValidity() native;

  Node item(int index) native;

  Node namedItem(String name) native;

  void remove(var index_OR_option) native;

  void setCustomValidity(String error) native;
}

class HTMLSourceElement extends HTMLElement native "*HTMLSourceElement" {

  String media;

  String src;

  String type;
}

class HTMLSpanElement extends HTMLElement native "*HTMLSpanElement" {
}

class HTMLStyleElement extends HTMLElement native "*HTMLStyleElement" {

  bool disabled;

  String media;

  StyleSheet sheet;

  String type;
}

class HTMLTableCaptionElement extends HTMLElement native "*HTMLTableCaptionElement" {

  String align;
}

class HTMLTableCellElement extends HTMLElement native "*HTMLTableCellElement" {

  String abbr;

  String align;

  String axis;

  String bgColor;

  int cellIndex;

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

class HTMLTableColElement extends HTMLElement native "*HTMLTableColElement" {

  String align;

  String ch;

  String chOff;

  int span;

  String vAlign;

  String width;
}

class HTMLTableElement extends HTMLElement native "*HTMLTableElement" {

  String align;

  String bgColor;

  String border;

  HTMLTableCaptionElement caption;

  String cellPadding;

  String cellSpacing;

  String frame;

  HTMLCollection rows;

  String rules;

  String summary;

  HTMLCollection tBodies;

  HTMLTableSectionElement tFoot;

  HTMLTableSectionElement tHead;

  String width;

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

  String align;

  String bgColor;

  HTMLCollection cells;

  String ch;

  String chOff;

  int rowIndex;

  int sectionRowIndex;

  String vAlign;

  void deleteCell(int index) native;

  HTMLElement insertCell(int index) native;
}

class HTMLTableSectionElement extends HTMLElement native "*HTMLTableSectionElement" {

  String align;

  String ch;

  String chOff;

  HTMLCollection rows;

  String vAlign;

  void deleteRow(int index) native;

  HTMLElement insertRow(int index) native;
}

class HTMLTextAreaElement extends HTMLElement native "*HTMLTextAreaElement" {

  String accessKey;

  bool autofocus;

  int cols;

  String defaultValue;

  bool disabled;

  HTMLFormElement form;

  NodeList labels;

  int maxLength;

  String name;

  String placeholder;

  bool readOnly;

  bool required;

  int rows;

  String selectionDirection;

  int selectionEnd;

  int selectionStart;

  int textLength;

  String type;

  String validationMessage;

  ValidityState validity;

  String value;

  bool willValidate;

  String wrap;

  bool checkValidity() native;

  void select() native;

  void setCustomValidity(String error) native;

  void setSelectionRange(int start, int end, [String direction = null]) native;
}

class HTMLTitleElement extends HTMLElement native "*HTMLTitleElement" {

  String text;
}

class HTMLTrackElement extends HTMLElement native "*HTMLTrackElement" {

  bool isDefault;

  String kind;

  String label;

  String src;

  String srclang;

  TextTrack track;
}

class HTMLUListElement extends HTMLElement native "*HTMLUListElement" {

  bool compact;

  String type;
}

class HTMLUnknownElement extends HTMLElement native "*HTMLUnknownElement" {
}

class HTMLVideoElement extends HTMLMediaElement native "*HTMLVideoElement" {

  int height;

  String poster;

  int videoHeight;

  int videoWidth;

  int webkitDecodedFrameCount;

  bool webkitDisplayingFullscreen;

  int webkitDroppedFrameCount;

  bool webkitSupportsFullscreen;

  int width;

  void webkitEnterFullScreen() native;

  void webkitEnterFullscreen() native;

  void webkitExitFullScreen() native;

  void webkitExitFullscreen() native;
}

class HashChangeEvent extends Event native "*HashChangeEvent" {

  String newURL;

  String oldURL;

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native;
}

class History native "*History" {

  int length;

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

  int direction;

  IDBKey key;

  IDBKey primaryKey;

  IDBAny source;

  void continueFunction([IDBKey key = null]) native;

  IDBRequest delete() native;

  IDBRequest update(String value) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBCursorWithValue extends IDBCursor native "*IDBCursorWithValue" {

  IDBAny value;
}

class IDBDatabase native "*IDBDatabase" {

  String name;

  String version;

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

  int code;

  String message;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBDatabaseException native "*IDBDatabaseException" {

  static final int ABORT_ERR = 13;

  static final int CONSTRAINT_ERR = 4;

  static final int DATA_ERR = 5;

  static final int DEADLOCK_ERR = 11;

  static final int NON_TRANSIENT_ERR = 2;

  static final int NOT_ALLOWED_ERR = 6;

  static final int NOT_FOUND_ERR = 3;

  static final int NO_ERR = 0;

  static final int READ_ONLY_ERR = 12;

  static final int RECOVERABLE_ERR = 8;

  static final int SERIAL_ERR = 7;

  static final int TIMEOUT_ERR = 10;

  static final int TRANSIENT_ERR = 9;

  static final int UNKNOWN_ERR = 1;

  int code;

  String message;

  String name;

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

  String keyPath;

  String name;

  IDBObjectStore objectStore;

  bool unique;

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

  IDBKey lower;

  bool lowerOpen;

  IDBKey upper;

  bool upperOpen;

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  IDBKeyRange lowerBound(IDBKey bound, [bool open = null]) native;

  IDBKeyRange only(IDBKey value) native;

  IDBKeyRange upperBound(IDBKey bound, [bool open = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBObjectStore native "*IDBObjectStore" {

  String keyPath;

  String name;

  IDBTransaction transaction;

  IDBRequest add(String value, [IDBKey key = null]) native;

  IDBRequest clear() native;

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

  int errorCode;

  int readyState;

  IDBAny result;

  IDBAny source;

  IDBTransaction transaction;

  String webkitErrorMessage;

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

  IDBDatabase db;

  int mode;

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  IDBObjectStore objectStore(String name) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class IDBVersionChangeEvent extends Event native "*IDBVersionChangeEvent" {

  String version;
}

class IDBVersionChangeRequest extends IDBRequest native "*IDBVersionChangeRequest" {
}

class ImageData native "*ImageData" {

  CanvasPixelArray data;

  int height;

  int width;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class InjectedScriptHost native "*InjectedScriptHost" {

  void clearConsoleMessages() native;

  void copyText(String text) native;

  int databaseId(Object database) native;

  Object evaluate(String text) native;

  void inspect(Object objectId, Object hints) native;

  Object inspectedNode(int num) native;

  Object internalConstructorName(Object object) native;

  bool isHTMLAllCollection(Object object) native;

  int storageId(Object storage) native;

  String type(Object object) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class InspectorFrontendHost native "*InspectorFrontendHost" {

  void bringToFront() native;

  void closeWindow() native;

  void copyText(String text) native;

  void disconnectFromBackend() native;

  String hiddenPanels() native;

  void inspectedURLChanged(String newURL) native;

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

  void saveAs(String fileName, String content) native;

  void sendMessageToBackend(String message) native;

  void setAttachedWindowHeight(int height) native;

  void setExtensionAPI(String script) native;

  void showContextMenu(MouseEvent event, Object items) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Int16Array extends ArrayBufferView native "*Int16Array" {

  static final int BYTES_PER_ELEMENT = 2;

  int length;

  Int16Array subarray(int start, [int end = null]) native;
}

class Int32Array extends ArrayBufferView native "*Int32Array" {

  static final int BYTES_PER_ELEMENT = 4;

  int length;

  Int32Array subarray(int start, [int end = null]) native;
}

class Int8Array extends ArrayBufferView native "*Int8Array" {

  static final int BYTES_PER_ELEMENT = 1;

  int length;

  Int8Array subarray(int start, [int end = null]) native;
}

class JavaScriptCallFrame native "*JavaScriptCallFrame" {

  static final int CATCH_SCOPE = 4;

  static final int CLOSURE_SCOPE = 3;

  static final int GLOBAL_SCOPE = 0;

  static final int LOCAL_SCOPE = 1;

  static final int WITH_SCOPE = 2;

  JavaScriptCallFrame caller;

  int column;

  String functionName;

  int line;

  List scopeChain;

  int sourceID;

  String type;

  void evaluate(String script) native;

  int scopeType(int scopeIndex) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class KeyboardEvent extends UIEvent native "*KeyboardEvent" {

  bool altGraphKey;

  bool altKey;

  bool ctrlKey;

  String keyIdentifier;

  int keyLocation;

  bool metaKey;

  bool shiftKey;

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, DOMWindow view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) native;
}

class Location native "*Location" {

  String hash;

  String host;

  String hostname;

  String href;

  String origin;

  String pathname;

  String port;

  String protocol;

  String search;

  void assign(String url) native;

  String getParameter(String name) native;

  void reload() native;

  void replace(String url) native;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MediaError native "*MediaError" {

  static final int MEDIA_ERR_ABORTED = 1;

  static final int MEDIA_ERR_DECODE = 3;

  static final int MEDIA_ERR_NETWORK = 2;

  static final int MEDIA_ERR_SRC_NOT_SUPPORTED = 4;

  int code;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MediaList native "*MediaList" {

  int length;

  String mediaText;

  String operator[](int index) native;

  void appendMedium(String newMedium) native;

  void deleteMedium(String oldMedium) native;

  String item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MediaQueryList native "*MediaQueryList" {

  bool matches;

  String media;

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

  int jsHeapSizeLimit;

  int totalJSHeapSize;

  int usedJSHeapSize;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MessageChannel native "*MessageChannel" {

  MessagePort port1;

  MessagePort port2;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MessageEvent extends Event native "*MessageEvent" {

  Object data;

  String lastEventId;

  String origin;

  List ports;

  DOMWindow source;

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

  Date modificationTime;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MetadataCallback native "*MetadataCallback" {

  bool handleEvent(Metadata metadata) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class MouseEvent extends UIEvent native "*MouseEvent" {

  bool altKey;

  int button;

  int clientX;

  int clientY;

  bool ctrlKey;

  Clipboard dataTransfer;

  Node fromElement;

  bool metaKey;

  int offsetX;

  int offsetY;

  EventTarget relatedTarget;

  int screenX;

  int screenY;

  bool shiftKey;

  Node toElement;

  int x;

  int y;

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

  int attrChange;

  String attrName;

  String newValue;

  String prevValue;

  Node relatedNode;

  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange) native;
}

class MutationRecord native "*MutationRecord" {

  NodeList addedNodes;

  String attributeName;

  String attributeNamespace;

  Node nextSibling;

  String oldValue;

  Node previousSibling;

  NodeList removedNodes;

  Node target;

  String type;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NamedNodeMap native "*NamedNodeMap" {

  int length;

  Node operator[](int index) native;

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

  String appCodeName;

  String appName;

  String appVersion;

  bool cookieEnabled;

  String language;

  DOMMimeTypeArray mimeTypes;

  bool onLine;

  String platform;

  DOMPluginArray plugins;

  String product;

  String productSub;

  String userAgent;

  String vendor;

  String vendorSub;

  void getStorageUpdates() native;

  bool javaEnabled() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NavigatorUserMediaError native "*NavigatorUserMediaError" {

  static final int PERMISSION_DENIED = 1;

  int code;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NavigatorUserMediaErrorCallback native "*NavigatorUserMediaErrorCallback" {

  bool handleEvent(NavigatorUserMediaError error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NavigatorUserMediaSuccessCallback native "*NavigatorUserMediaSuccessCallback" {

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

  NamedNodeMap attributes;

  String baseURI;

  NodeList childNodes;

  Node firstChild;

  Node lastChild;

  String localName;

  String namespaceURI;

  Node nextSibling;

  String nodeName;

  int nodeType;

  String nodeValue;

  Document ownerDocument;

  Element parentElement;

  Node parentNode;

  String prefix;

  Node previousSibling;

  String textContent;

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

  bool expandEntityReferences;

  NodeFilter filter;

  bool pointerBeforeReferenceNode;

  Node referenceNode;

  Node root;

  int whatToShow;

  void detach() native;

  Node nextNode() native;

  Node previousNode() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class NodeList native "*NodeList" {

  int length;

  Node operator[](int index) native;

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

  String publicId;

  String systemId;
}

class Notification native "*Notification" {

  String dir;

  String replaceId;

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

class OperationNotAllowedException native "*OperationNotAllowedException" {

  static final int NOT_ALLOWED_ERR = 1;

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class OverflowEvent extends Event native "*OverflowEvent" {

  static final int BOTH = 2;

  static final int HORIZONTAL = 0;

  static final int VERTICAL = 1;

  bool horizontalOverflow;

  int orient;

  bool verticalOverflow;

  void initOverflowEvent(int orient, bool horizontalOverflow, bool verticalOverflow) native;
}

class PageTransitionEvent extends Event native "*PageTransitionEvent" {

  bool persisted;

  void initPageTransitionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool persisted) native;
}

class Performance native "*Performance" {

  MemoryInfo memory;

  PerformanceNavigation navigation;

  PerformanceTiming timing;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class PerformanceNavigation native "*PerformanceNavigation" {

  static final int TYPE_BACK_FORWARD = 2;

  static final int TYPE_NAVIGATE = 0;

  static final int TYPE_RELOAD = 1;

  static final int TYPE_RESERVED = 255;

  int redirectCount;

  int type;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class PerformanceTiming native "*PerformanceTiming" {

  int connectEnd;

  int connectStart;

  int domComplete;

  int domContentLoadedEventEnd;

  int domContentLoadedEventStart;

  int domInteractive;

  int domLoading;

  int domainLookupEnd;

  int domainLookupStart;

  int fetchStart;

  int loadEventEnd;

  int loadEventStart;

  int navigationStart;

  int redirectEnd;

  int redirectStart;

  int requestStart;

  int responseEnd;

  int responseStart;

  int secureConnectionStart;

  int unloadEventEnd;

  int unloadEventStart;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class PopStateEvent extends Event native "*PopStateEvent" {

  Object state;

  void initPopStateEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object stateArg) native;
}

class PositionCallback native "*PositionCallback" {

  bool handleEvent(Geoposition position) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class PositionError native "*PositionError" {

  static final int PERMISSION_DENIED = 1;

  static final int POSITION_UNAVAILABLE = 2;

  static final int TIMEOUT = 3;

  int code;

  String message;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class PositionErrorCallback native "*PositionErrorCallback" {

  bool handleEvent(PositionError error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ProcessingInstruction extends Node native "*ProcessingInstruction" {

  String data;

  StyleSheet sheet;

  String target;
}

class ProgressEvent extends Event native "*ProgressEvent" {

  bool lengthComputable;

  int loaded;

  int total;

  void initProgressEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool lengthComputableArg, int loadedArg, int totalArg) native;
}

class RGBColor native "*RGBColor" {

  CSSPrimitiveValue blue;

  CSSPrimitiveValue green;

  CSSPrimitiveValue red;

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

  bool collapsed;

  Node commonAncestorContainer;

  Node endContainer;

  int endOffset;

  Node startContainer;

  int startOffset;

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

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Rect native "*Rect" {

  CSSPrimitiveValue bottom;

  CSSPrimitiveValue left;

  CSSPrimitiveValue right;

  CSSPrimitiveValue top;

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

  int code;

  String message;

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

  int code;

  String message;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLResultSet native "*SQLResultSet" {

  int insertId;

  SQLResultSetRowList rows;

  int rowsAffected;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLResultSetRowList native "*SQLResultSetRowList" {

  int length;

  Object item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLStatementCallback native "*SQLStatementCallback" {

  bool handleEvent(SQLTransaction transaction, SQLResultSet resultSet) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLStatementErrorCallback native "*SQLStatementErrorCallback" {

  bool handleEvent(SQLTransaction transaction, SQLError error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLTransaction native "*SQLTransaction" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLTransactionCallback native "*SQLTransactionCallback" {

  bool handleEvent(SQLTransaction transaction) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLTransactionErrorCallback native "*SQLTransactionErrorCallback" {

  bool handleEvent(SQLError error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLTransactionSync native "*SQLTransactionSync" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLTransactionSyncCallback native "*SQLTransactionSyncCallback" {

  bool handleEvent(SQLTransactionSync transaction) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAElement extends SVGElement native "*SVGAElement" {

  SVGAnimatedString target;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGAltGlyphDefElement extends SVGElement native "*SVGAltGlyphDefElement" {
}

class SVGAltGlyphElement extends SVGTextPositioningElement native "*SVGAltGlyphElement" {

  String format;

  String glyphRef;

  // From SVGURIReference

  SVGAnimatedString href;
}

class SVGAltGlyphItemElement extends SVGElement native "*SVGAltGlyphItemElement" {
}

class SVGAngle native "*SVGAngle" {

  static final int SVG_ANGLETYPE_DEG = 2;

  static final int SVG_ANGLETYPE_GRAD = 4;

  static final int SVG_ANGLETYPE_RAD = 3;

  static final int SVG_ANGLETYPE_UNKNOWN = 0;

  static final int SVG_ANGLETYPE_UNSPECIFIED = 1;

  int unitType;

  num value;

  String valueAsString;

  num valueInSpecifiedUnits;

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

  SVGAngle animVal;

  SVGAngle baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedBoolean native "*SVGAnimatedBoolean" {

  bool animVal;

  bool baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedEnumeration native "*SVGAnimatedEnumeration" {

  int animVal;

  int baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedInteger native "*SVGAnimatedInteger" {

  int animVal;

  int baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedLength native "*SVGAnimatedLength" {

  SVGLength animVal;

  SVGLength baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedLengthList native "*SVGAnimatedLengthList" {

  SVGLengthList animVal;

  SVGLengthList baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedNumber native "*SVGAnimatedNumber" {

  num animVal;

  num baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedNumberList native "*SVGAnimatedNumberList" {

  SVGNumberList animVal;

  SVGNumberList baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedPreserveAspectRatio native "*SVGAnimatedPreserveAspectRatio" {

  SVGPreserveAspectRatio animVal;

  SVGPreserveAspectRatio baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedRect native "*SVGAnimatedRect" {

  SVGRect animVal;

  SVGRect baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedString native "*SVGAnimatedString" {

  String animVal;

  String baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimatedTransformList native "*SVGAnimatedTransformList" {

  SVGTransformList animVal;

  SVGTransformList baseVal;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGAnimationElement extends SVGElement native "*SVGAnimationElement" {

  SVGElement targetElement;

  num getCurrentTime() native;

  num getSimpleDuration() native;

  num getStartTime() native;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From ElementTimeControl

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;
}

class SVGCircleElement extends SVGElement native "*SVGCircleElement" {

  SVGAnimatedLength cx;

  SVGAnimatedLength cy;

  SVGAnimatedLength r;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGClipPathElement extends SVGElement native "*SVGClipPathElement" {

  SVGAnimatedEnumeration clipPathUnits;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

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

  int colorType;

  RGBColor rgbColor;

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

  SVGAnimatedNumber amplitude;

  SVGAnimatedNumber exponent;

  SVGAnimatedNumber intercept;

  SVGAnimatedNumber offset;

  SVGAnimatedNumber slope;

  SVGAnimatedNumberList tableValues;

  SVGAnimatedEnumeration type;
}

class SVGCursorElement extends SVGElement native "*SVGCursorElement" {

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;
}

class SVGDefsElement extends SVGElement native "*SVGDefsElement" {

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGDescElement extends SVGElement native "*SVGDescElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGDocument extends Document native "*SVGDocument" {

  SVGSVGElement rootElement;

  Event createEvent(String eventType) native;
}

class SVGElement extends Element native "*SVGElement" {

  String id;

  SVGSVGElement ownerSVGElement;

  SVGElement viewportElement;

  String xmlbase;
}

class SVGElementInstance native "*SVGElementInstance" {

  SVGElementInstanceList childNodes;

  SVGElement correspondingElement;

  SVGUseElement correspondingUseElement;

  SVGElementInstance firstChild;

  SVGElementInstance lastChild;

  SVGElementInstance nextSibling;

  SVGElementInstance parentNode;

  SVGElementInstance previousSibling;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGElementInstanceList native "*SVGElementInstanceList" {

  int length;

  SVGElementInstance item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGEllipseElement extends SVGElement native "*SVGEllipseElement" {

  SVGAnimatedLength cx;

  SVGAnimatedLength cy;

  SVGAnimatedLength rx;

  SVGAnimatedLength ry;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGException native "*SVGException" {

  static final int SVG_INVALID_VALUE_ERR = 1;

  static final int SVG_MATRIX_NOT_INVERTABLE = 2;

  static final int SVG_WRONG_TYPE_ERR = 0;

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGExternalResourcesRequired native "*SVGExternalResourcesRequired" {

  SVGAnimatedBoolean externalResourcesRequired;

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

  SVGAnimatedString in1;

  SVGAnimatedString in2;

  SVGAnimatedEnumeration mode;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEColorMatrixElement extends SVGElement native "*SVGFEColorMatrixElement" {

  static final int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static final int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static final int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static final int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static final int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  SVGAnimatedString in1;

  SVGAnimatedEnumeration type;

  SVGAnimatedNumberList values;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEComponentTransferElement extends SVGElement native "*SVGFEComponentTransferElement" {

  SVGAnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

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

  SVGAnimatedString in1;

  SVGAnimatedString in2;

  SVGAnimatedNumber k1;

  SVGAnimatedNumber k2;

  SVGAnimatedNumber k3;

  SVGAnimatedNumber k4;

  SVGAnimatedEnumeration operator;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEConvolveMatrixElement extends SVGElement native "*SVGFEConvolveMatrixElement" {

  static final int SVG_EDGEMODE_DUPLICATE = 1;

  static final int SVG_EDGEMODE_NONE = 3;

  static final int SVG_EDGEMODE_UNKNOWN = 0;

  static final int SVG_EDGEMODE_WRAP = 2;

  SVGAnimatedNumber bias;

  SVGAnimatedNumber divisor;

  SVGAnimatedEnumeration edgeMode;

  SVGAnimatedString in1;

  SVGAnimatedNumberList kernelMatrix;

  SVGAnimatedNumber kernelUnitLengthX;

  SVGAnimatedNumber kernelUnitLengthY;

  SVGAnimatedInteger orderX;

  SVGAnimatedInteger orderY;

  SVGAnimatedBoolean preserveAlpha;

  SVGAnimatedInteger targetX;

  SVGAnimatedInteger targetY;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEDiffuseLightingElement extends SVGElement native "*SVGFEDiffuseLightingElement" {

  SVGAnimatedNumber diffuseConstant;

  SVGAnimatedString in1;

  SVGAnimatedNumber kernelUnitLengthX;

  SVGAnimatedNumber kernelUnitLengthY;

  SVGAnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEDisplacementMapElement extends SVGElement native "*SVGFEDisplacementMapElement" {

  static final int SVG_CHANNEL_A = 4;

  static final int SVG_CHANNEL_B = 3;

  static final int SVG_CHANNEL_G = 2;

  static final int SVG_CHANNEL_R = 1;

  static final int SVG_CHANNEL_UNKNOWN = 0;

  SVGAnimatedString in1;

  SVGAnimatedString in2;

  SVGAnimatedNumber scale;

  SVGAnimatedEnumeration xChannelSelector;

  SVGAnimatedEnumeration yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEDistantLightElement extends SVGElement native "*SVGFEDistantLightElement" {

  SVGAnimatedNumber azimuth;

  SVGAnimatedNumber elevation;
}

class SVGFEDropShadowElement extends SVGElement native "*SVGFEDropShadowElement" {

  SVGAnimatedNumber dx;

  SVGAnimatedNumber dy;

  SVGAnimatedString in1;

  SVGAnimatedNumber stdDeviationX;

  SVGAnimatedNumber stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEFloodElement extends SVGElement native "*SVGFEFloodElement" {

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

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

  SVGAnimatedString in1;

  SVGAnimatedNumber stdDeviationX;

  SVGAnimatedNumber stdDeviationY;

  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEImageElement extends SVGElement native "*SVGFEImageElement" {

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEMergeElement extends SVGElement native "*SVGFEMergeElement" {

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEMergeNodeElement extends SVGElement native "*SVGFEMergeNodeElement" {

  SVGAnimatedString in1;
}

class SVGFEMorphologyElement extends SVGElement native "*SVGFEMorphologyElement" {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  SVGAnimatedString in1;

  SVGAnimatedEnumeration operator;

  SVGAnimatedNumber radiusX;

  SVGAnimatedNumber radiusY;

  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEOffsetElement extends SVGElement native "*SVGFEOffsetElement" {

  SVGAnimatedNumber dx;

  SVGAnimatedNumber dy;

  SVGAnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFEPointLightElement extends SVGElement native "*SVGFEPointLightElement" {

  SVGAnimatedNumber x;

  SVGAnimatedNumber y;

  SVGAnimatedNumber z;
}

class SVGFESpecularLightingElement extends SVGElement native "*SVGFESpecularLightingElement" {

  SVGAnimatedString in1;

  SVGAnimatedNumber specularConstant;

  SVGAnimatedNumber specularExponent;

  SVGAnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFESpotLightElement extends SVGElement native "*SVGFESpotLightElement" {

  SVGAnimatedNumber limitingConeAngle;

  SVGAnimatedNumber pointsAtX;

  SVGAnimatedNumber pointsAtY;

  SVGAnimatedNumber pointsAtZ;

  SVGAnimatedNumber specularExponent;

  SVGAnimatedNumber x;

  SVGAnimatedNumber y;

  SVGAnimatedNumber z;
}

class SVGFETileElement extends SVGElement native "*SVGFETileElement" {

  SVGAnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFETurbulenceElement extends SVGElement native "*SVGFETurbulenceElement" {

  static final int SVG_STITCHTYPE_NOSTITCH = 2;

  static final int SVG_STITCHTYPE_STITCH = 1;

  static final int SVG_STITCHTYPE_UNKNOWN = 0;

  static final int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static final int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static final int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  SVGAnimatedNumber baseFrequencyX;

  SVGAnimatedNumber baseFrequencyY;

  SVGAnimatedInteger numOctaves;

  SVGAnimatedNumber seed;

  SVGAnimatedEnumeration stitchTiles;

  SVGAnimatedEnumeration type;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFilterElement extends SVGElement native "*SVGFilterElement" {

  SVGAnimatedInteger filterResX;

  SVGAnimatedInteger filterResY;

  SVGAnimatedEnumeration filterUnits;

  SVGAnimatedLength height;

  SVGAnimatedEnumeration primitiveUnits;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGFilterPrimitiveStandardAttributes extends SVGStylable native "*SVGFilterPrimitiveStandardAttributes" {

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;
}

class SVGFitToViewBox native "*SVGFitToViewBox" {

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;

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

  SVGAnimatedLength height;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGGElement extends SVGElement native "*SVGGElement" {

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGGlyphElement extends SVGElement native "*SVGGlyphElement" {
}

class SVGGlyphRefElement extends SVGElement native "*SVGGlyphRefElement" {

  num dx;

  num dy;

  String format;

  String glyphRef;

  num x;

  num y;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGGradientElement extends SVGElement native "*SVGGradientElement" {

  static final int SVG_SPREADMETHOD_PAD = 1;

  static final int SVG_SPREADMETHOD_REFLECT = 2;

  static final int SVG_SPREADMETHOD_REPEAT = 3;

  static final int SVG_SPREADMETHOD_UNKNOWN = 0;

  SVGAnimatedTransformList gradientTransform;

  SVGAnimatedEnumeration gradientUnits;

  SVGAnimatedEnumeration spreadMethod;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGHKernElement extends SVGElement native "*SVGHKernElement" {
}

class SVGImageElement extends SVGElement native "*SVGImageElement" {

  SVGAnimatedLength height;

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGLangSpace native "*SVGLangSpace" {

  String xmllang;

  String xmlspace;

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

  int unitType;

  num value;

  String valueAsString;

  num valueInSpecifiedUnits;

  void convertToSpecifiedUnits(int unitType) native;

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGLengthList native "*SVGLengthList" {

  int numberOfItems;

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

  SVGAnimatedLength x1;

  SVGAnimatedLength x2;

  SVGAnimatedLength y1;

  SVGAnimatedLength y2;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGLinearGradientElement extends SVGGradientElement native "*SVGLinearGradientElement" {

  SVGAnimatedLength x1;

  SVGAnimatedLength x2;

  SVGAnimatedLength y1;

  SVGAnimatedLength y2;
}

class SVGLocatable native "*SVGLocatable" {

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGMPathElement extends SVGElement native "*SVGMPathElement" {

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;
}

class SVGMarkerElement extends SVGElement native "*SVGMarkerElement" {

  static final int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static final int SVG_MARKERUNITS_UNKNOWN = 0;

  static final int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static final int SVG_MARKER_ORIENT_ANGLE = 2;

  static final int SVG_MARKER_ORIENT_AUTO = 1;

  static final int SVG_MARKER_ORIENT_UNKNOWN = 0;

  SVGAnimatedLength markerHeight;

  SVGAnimatedEnumeration markerUnits;

  SVGAnimatedLength markerWidth;

  SVGAnimatedAngle orientAngle;

  SVGAnimatedEnumeration orientType;

  SVGAnimatedLength refX;

  SVGAnimatedLength refY;

  void setOrientToAngle(SVGAngle angle) native;

  void setOrientToAuto() native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;
}

class SVGMaskElement extends SVGElement native "*SVGMaskElement" {

  SVGAnimatedLength height;

  SVGAnimatedEnumeration maskContentUnits;

  SVGAnimatedEnumeration maskUnits;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGMatrix native "*SVGMatrix" {

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

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

  num value;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGNumberList native "*SVGNumberList" {

  int numberOfItems;

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

  int paintType;

  String uri;

  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native;

  void setUri(String uri) native;
}

class SVGPathElement extends SVGElement native "*SVGPathElement" {

  SVGPathSegList animatedNormalizedPathSegList;

  SVGPathSegList animatedPathSegList;

  SVGPathSegList normalizedPathSegList;

  SVGAnimatedNumber pathLength;

  SVGPathSegList pathSegList;

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

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

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

  int pathSegType;

  String pathSegTypeAsLetter;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGPathSegArcAbs extends SVGPathSeg native "*SVGPathSegArcAbs" {

  num angle;

  bool largeArcFlag;

  num r1;

  num r2;

  bool sweepFlag;

  num x;

  num y;
}

class SVGPathSegArcRel extends SVGPathSeg native "*SVGPathSegArcRel" {

  num angle;

  bool largeArcFlag;

  num r1;

  num r2;

  bool sweepFlag;

  num x;

  num y;
}

class SVGPathSegClosePath extends SVGPathSeg native "*SVGPathSegClosePath" {
}

class SVGPathSegCurvetoCubicAbs extends SVGPathSeg native "*SVGPathSegCurvetoCubicAbs" {

  num x;

  num x1;

  num x2;

  num y;

  num y1;

  num y2;
}

class SVGPathSegCurvetoCubicRel extends SVGPathSeg native "*SVGPathSegCurvetoCubicRel" {

  num x;

  num x1;

  num x2;

  num y;

  num y1;

  num y2;
}

class SVGPathSegCurvetoCubicSmoothAbs extends SVGPathSeg native "*SVGPathSegCurvetoCubicSmoothAbs" {

  num x;

  num x2;

  num y;

  num y2;
}

class SVGPathSegCurvetoCubicSmoothRel extends SVGPathSeg native "*SVGPathSegCurvetoCubicSmoothRel" {

  num x;

  num x2;

  num y;

  num y2;
}

class SVGPathSegCurvetoQuadraticAbs extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticAbs" {

  num x;

  num x1;

  num y;

  num y1;
}

class SVGPathSegCurvetoQuadraticRel extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticRel" {

  num x;

  num x1;

  num y;

  num y1;
}

class SVGPathSegCurvetoQuadraticSmoothAbs extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticSmoothAbs" {

  num x;

  num y;
}

class SVGPathSegCurvetoQuadraticSmoothRel extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticSmoothRel" {

  num x;

  num y;
}

class SVGPathSegLinetoAbs extends SVGPathSeg native "*SVGPathSegLinetoAbs" {

  num x;

  num y;
}

class SVGPathSegLinetoHorizontalAbs extends SVGPathSeg native "*SVGPathSegLinetoHorizontalAbs" {

  num x;
}

class SVGPathSegLinetoHorizontalRel extends SVGPathSeg native "*SVGPathSegLinetoHorizontalRel" {

  num x;
}

class SVGPathSegLinetoRel extends SVGPathSeg native "*SVGPathSegLinetoRel" {

  num x;

  num y;
}

class SVGPathSegLinetoVerticalAbs extends SVGPathSeg native "*SVGPathSegLinetoVerticalAbs" {

  num y;
}

class SVGPathSegLinetoVerticalRel extends SVGPathSeg native "*SVGPathSegLinetoVerticalRel" {

  num y;
}

class SVGPathSegList native "*SVGPathSegList" {

  int numberOfItems;

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

  num x;

  num y;
}

class SVGPathSegMovetoRel extends SVGPathSeg native "*SVGPathSegMovetoRel" {

  num x;

  num y;
}

class SVGPatternElement extends SVGElement native "*SVGPatternElement" {

  SVGAnimatedLength height;

  SVGAnimatedEnumeration patternContentUnits;

  SVGAnimatedTransformList patternTransform;

  SVGAnimatedEnumeration patternUnits;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;
}

class SVGPoint native "*SVGPoint" {

  num x;

  num y;

  SVGPoint matrixTransform(SVGMatrix matrix) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGPointList native "*SVGPointList" {

  int numberOfItems;

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

  SVGPointList animatedPoints;

  SVGPointList points;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGPolylineElement extends SVGElement native "*SVGPolylineElement" {

  SVGPointList animatedPoints;

  SVGPointList points;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

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

  int align;

  int meetOrSlice;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGRadialGradientElement extends SVGGradientElement native "*SVGRadialGradientElement" {

  SVGAnimatedLength cx;

  SVGAnimatedLength cy;

  SVGAnimatedLength fx;

  SVGAnimatedLength fy;

  SVGAnimatedLength r;
}

class SVGRect native "*SVGRect" {

  num height;

  num width;

  num x;

  num y;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGRectElement extends SVGElement native "*SVGRectElement" {

  SVGAnimatedLength height;

  SVGAnimatedLength rx;

  SVGAnimatedLength ry;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

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

  String contentScriptType;

  String contentStyleType;

  num currentScale;

  SVGPoint currentTranslate;

  SVGAnimatedLength height;

  num pixelUnitToMillimeterX;

  num pixelUnitToMillimeterY;

  num screenPixelToMillimeterX;

  num screenPixelToMillimeterY;

  bool useCurrentView;

  SVGRect viewport;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

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

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;

  // From SVGZoomAndPan

  int zoomAndPan;
}

class SVGScriptElement extends SVGElement native "*SVGScriptElement" {

  String type;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;
}

class SVGSetElement extends SVGAnimationElement native "*SVGSetElement" {
}

class SVGStopElement extends SVGElement native "*SVGStopElement" {

  SVGAnimatedNumber offset;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGStringList native "*SVGStringList" {

  int numberOfItems;

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

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGStyleElement extends SVGElement native "*SVGStyleElement" {

  String media;

  String title;

  String type;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;
}

class SVGSwitchElement extends SVGElement native "*SVGSwitchElement" {

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGSymbolElement extends SVGElement native "*SVGSymbolElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;
}

class SVGTRefElement extends SVGTextPositioningElement native "*SVGTRefElement" {

  // From SVGURIReference

  SVGAnimatedString href;
}

class SVGTSpanElement extends SVGTextPositioningElement native "*SVGTSpanElement" {
}

class SVGTests native "*SVGTests" {

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGTextContentElement extends SVGElement native "*SVGTextContentElement" {

  static final int LENGTHADJUST_SPACING = 1;

  static final int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static final int LENGTHADJUST_UNKNOWN = 0;

  SVGAnimatedEnumeration lengthAdjust;

  SVGAnimatedLength textLength;

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

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}

class SVGTextElement extends SVGTextPositioningElement native "*SVGTextElement" {

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

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

  SVGAnimatedEnumeration method;

  SVGAnimatedEnumeration spacing;

  SVGAnimatedLength startOffset;

  // From SVGURIReference

  SVGAnimatedString href;
}

class SVGTextPositioningElement extends SVGTextContentElement native "*SVGTextPositioningElement" {

  SVGAnimatedLengthList dx;

  SVGAnimatedLengthList dy;

  SVGAnimatedNumberList rotate;

  SVGAnimatedLengthList x;

  SVGAnimatedLengthList y;
}

class SVGTitleElement extends SVGElement native "*SVGTitleElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

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

  num angle;

  SVGMatrix matrix;

  int type;

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

  int numberOfItems;

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

  SVGAnimatedTransformList transform;
}

class SVGURIReference native "*SVGURIReference" {

  SVGAnimatedString href;

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

  SVGElementInstance animatedInstanceRoot;

  SVGAnimatedLength height;

  SVGElementInstance instanceRoot;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}

class SVGVKernElement extends SVGElement native "*SVGVKernElement" {
}

class SVGViewElement extends SVGElement native "*SVGViewElement" {

  SVGStringList viewTarget;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;

  // From SVGZoomAndPan

  int zoomAndPan;
}

class SVGViewSpec extends SVGZoomAndPan native "*SVGViewSpec" {

  String preserveAspectRatioString;

  SVGTransformList transform;

  String transformString;

  String viewBoxString;

  SVGElement viewTarget;

  String viewTargetString;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;
}

class SVGZoomAndPan native "*SVGZoomAndPan" {

  static final int SVG_ZOOMANDPAN_DISABLE = 1;

  static final int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static final int SVG_ZOOMANDPAN_UNKNOWN = 0;

  int zoomAndPan;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SVGZoomEvent extends UIEvent native "*SVGZoomEvent" {

  num newScale;

  SVGPoint newTranslate;

  num previousScale;

  SVGPoint previousTranslate;

  SVGRect zoomRectScreen;
}

class Screen native "*Screen" {

  int availHeight;

  int availLeft;

  int availTop;

  int availWidth;

  int colorDepth;

  int height;

  int pixelDepth;

  int width;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ScriptProfile native "*ScriptProfile" {

  ScriptProfileNode head;

  String title;

  int uid;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class ScriptProfileNode native "*ScriptProfileNode" {

  int callUID;

  List children;

  String functionName;

  int lineNumber;

  int numberOfCalls;

  num selfTime;

  num totalTime;

  String url;

  bool visible;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SharedWorker extends AbstractWorker native "*SharedWorker" {

  MessagePort port;
}

class SharedWorkercontext extends WorkerContext native "*SharedWorkercontext" {

  String name;
}

class SpeechInputEvent extends Event native "*SpeechInputEvent" {

  SpeechInputResultList results;
}

class SpeechInputResult native "*SpeechInputResult" {

  num confidence;

  String utterance;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SpeechInputResultList native "*SpeechInputResultList" {

  int length;

  SpeechInputResult item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Storage native "*Storage" {

  int length;

  void clear() native;

  String getItem(String key) native;

  String key(int index) native;

  void removeItem(String key) native;

  void setItem(String key, String data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class StorageEvent extends Event native "*StorageEvent" {

  String key;

  String newValue;

  String oldValue;

  Storage storageArea;

  String url;

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

class StorageInfoErrorCallback native "*StorageInfoErrorCallback" {

  bool handleEvent(DOMException error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class StorageInfoQuotaCallback native "*StorageInfoQuotaCallback" {

  bool handleEvent(int grantedQuotaInBytes) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class StorageInfoUsageCallback native "*StorageInfoUsageCallback" {

  bool handleEvent(int currentUsageInBytes, int currentQuotaInBytes) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class StringCallback native "*StringCallback" {

  bool handleEvent(String data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class StyleMedia native "*StyleMedia" {

  String type;

  bool matchMedium(String mediaquery) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class StyleSheet native "*StyleSheet" {

  bool disabled;

  String href;

  MediaList media;

  Node ownerNode;

  StyleSheet parentStyleSheet;

  String title;

  String type;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class StyleSheetList native "*StyleSheetList" {

  int length;

  StyleSheet operator[](int index) native;

  StyleSheet item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Text extends CharacterData native "*Text" {

  String wholeText;

  Text replaceWholeText(String content) native;

  Text splitText(int offset) native;
}

class TextEvent extends UIEvent native "*TextEvent" {

  String data;

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindow viewArg, String dataArg) native;
}

class TextMetrics native "*TextMetrics" {

  num width;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TextTrack native "*TextTrack" {

  static final int Disabled = 0;

  static final int Error = 3;

  static final int Hidden = 1;

  static final int Loaded = 2;

  static final int Loading = 1;

  static final int None = 0;

  static final int Showing = 2;

  TextTrackCueList activeCues;

  TextTrackCueList cues;

  String kind;

  String label;

  String language;

  int mode;

  int readyState;

  void addCue(TextTrackCue cue) native;

  void removeCue(TextTrackCue cue) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TextTrackCue native "*TextTrackCue" {

  String alignment;

  String direction;

  num endTime;

  String id;

  int linePosition;

  bool pauseOnExit;

  int size;

  bool snapToLines;

  num startTime;

  int textPosition;

  TextTrack track;

  DocumentFragment getCueAsHTML() native;

  String getCueAsSource() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TextTrackCueList native "*TextTrackCueList" {

  int length;

  TextTrackCue getCueById(String id) native;

  TextTrackCue item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TimeRanges native "*TimeRanges" {

  int length;

  num end(int index) native;

  num start(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class Touch native "*Touch" {

  int clientX;

  int clientY;

  int identifier;

  int pageX;

  int pageY;

  int screenX;

  int screenY;

  EventTarget target;

  num webkitForce;

  int webkitRadiusX;

  int webkitRadiusY;

  num webkitRotationAngle;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TouchEvent extends UIEvent native "*TouchEvent" {

  bool altKey;

  TouchList changedTouches;

  bool ctrlKey;

  bool metaKey;

  bool shiftKey;

  TouchList targetTouches;

  TouchList touches;

  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}

class TouchList native "*TouchList" {

  int length;

  Touch operator[](int index) native;

  Touch item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class TreeWalker native "*TreeWalker" {

  Node currentNode;

  bool expandEntityReferences;

  NodeFilter filter;

  Node root;

  int whatToShow;

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

  int charCode;

  int detail;

  int keyCode;

  int layerX;

  int layerY;

  int pageX;

  int pageY;

  DOMWindow view;

  int which;

  void initUIEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail) native;
}

class Uint16Array extends ArrayBufferView native "*Uint16Array" {

  static final int BYTES_PER_ELEMENT = 2;

  int length;

  Uint16Array subarray(int start, [int end = null]) native;
}

class Uint32Array extends ArrayBufferView native "*Uint32Array" {

  static final int BYTES_PER_ELEMENT = 4;

  int length;

  Uint32Array subarray(int start, [int end = null]) native;
}

class Uint8Array extends ArrayBufferView native "*Uint8Array" {

  static final int BYTES_PER_ELEMENT = 1;

  int length;

  Uint8Array subarray(int start, [int end = null]) native;
}

class ValidityState native "*ValidityState" {

  bool customError;

  bool patternMismatch;

  bool rangeOverflow;

  bool rangeUnderflow;

  bool stepMismatch;

  bool tooLong;

  bool typeMismatch;

  bool valid;

  bool valueMissing;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class VoidCallback native "*VoidCallback" {

  void handleEvent() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLActiveInfo native "*WebGLActiveInfo" {

  String name;

  int size;

  int type;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLBuffer native "*WebGLBuffer" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLContextAttributes native "*WebGLContextAttributes" {

  bool alpha;

  bool antialias;

  bool depth;

  bool premultipliedAlpha;

  bool preserveDrawingBuffer;

  bool stencil;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebGLContextEvent extends Event native "*WebGLContextEvent" {

  String statusMessage;
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

  int drawingBufferHeight;

  int drawingBufferWidth;

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

  void getBufferParameter() native;

  WebGLContextAttributes getContextAttributes() native;

  int getError() native;

  void getExtension(String name) native;

  void getFramebufferAttachmentParameter() native;

  void getParameter() native;

  String getProgramInfoLog(WebGLProgram program) native;

  void getProgramParameter() native;

  void getRenderbufferParameter() native;

  String getShaderInfoLog(WebGLShader shader) native;

  void getShaderParameter() native;

  String getShaderSource(WebGLShader shader) native;

  void getSupportedExtensions() native;

  void getTexParameter() native;

  void getUniform() native;

  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) native;

  void getVertexAttrib() native;

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

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels, [int format = null, int type = null, ArrayBufferView pixels = null]) native;

  void texParameterf(int target, int pname, num param) native;

  void texParameteri(int target, int pname, int param) native;

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels, [int type = null, ArrayBufferView pixels = null]) native;

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

  num delay;

  int direction;

  num duration;

  num elapsedTime;

  bool ended;

  int fillMode;

  int iterationCount;

  String name;

  bool paused;

  void pause() native;

  void play() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitAnimationEvent extends Event native "*WebKitAnimationEvent" {

  String animationName;

  num elapsedTime;

  void initWebKitAnimationEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String animationNameArg, num elapsedTimeArg) native;
}

class WebKitAnimationList native "*WebKitAnimationList" {

  int length;

  WebKitAnimation item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitBlobBuilder native "*WebKitBlobBuilder" {

  void append(var blob_OR_value, [String endings = null]) native;

  Blob getBlob([String contentType = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitCSSFilterValue extends CSSValueList native "*WebKitCSSFilterValue" {

  static final int CSS_FILTER_BLUR = 9;

  static final int CSS_FILTER_DROP_SHADOW = 11;

  static final int CSS_FILTER_GAMMA = 8;

  static final int CSS_FILTER_GRAYSCALE = 2;

  static final int CSS_FILTER_HUE_ROTATE = 5;

  static final int CSS_FILTER_INVERT = 6;

  static final int CSS_FILTER_OPACITY = 7;

  static final int CSS_FILTER_REFERENCE = 1;

  static final int CSS_FILTER_SATURATE = 4;

  static final int CSS_FILTER_SEPIA = 3;

  static final int CSS_FILTER_SHARPEN = 10;

  int operationType;
}

class WebKitCSSKeyframeRule extends CSSRule native "*WebKitCSSKeyframeRule" {

  String keyText;

  CSSStyleDeclaration style;
}

class WebKitCSSKeyframesRule extends CSSRule native "*WebKitCSSKeyframesRule" {

  CSSRuleList cssRules;

  String name;

  void deleteRule(String key) native;

  WebKitCSSKeyframeRule findRule(String key) native;

  void insertRule(String rule) native;
}

class WebKitCSSMatrix native "*WebKitCSSMatrix" {
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

  int operationType;
}

class WebKitFlags native "*WebKitFlags" {

  bool create;

  bool exclusive;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitLoseContext native "*WebKitLoseContext" {

  void loseContext() native;

  void restoreContext() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitMutationObserver native "*WebKitMutationObserver" {

  void disconnect() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitPoint native "*WebKitPoint" {
  WebKitPoint(num x, num y) native;


  num x;

  num y;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WebKitTransitionEvent extends Event native "*WebKitTransitionEvent" {

  num elapsedTime;

  String propertyName;

  void initWebKitTransitionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String propertyNameArg, num elapsedTimeArg) native;
}

class WebSocket native "*WebSocket" {

  static final int CLOSED = 3;

  static final int CLOSING = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String URL;

  String binaryType;

  int bufferedAmount;

  String extensions;

  String protocol;

  int readyState;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close([int code = null, String reason = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool send(String data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WheelEvent extends UIEvent native "*WheelEvent" {

  bool altKey;

  int clientX;

  int clientY;

  bool ctrlKey;

  bool metaKey;

  int offsetX;

  int offsetY;

  int screenX;

  int screenY;

  bool shiftKey;

  bool webkitDirectionInvertedFromDevice;

  int wheelDelta;

  int wheelDeltaX;

  int wheelDeltaY;

  int x;

  int y;

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}

class Worker extends AbstractWorker native "*Worker" {

  void postMessage(String message, [List messagePorts = null]) native;

  void terminate() native;

  void webkitPostMessage(String message, [List messagePorts = null]) native;
}

class WorkerContext native "*WorkerContext" {

  WorkerLocation location;

  WorkerNavigator navigator;

  WorkerContext self;

  NotificationCenter webkitNotifications;

  DOMURL webkitURL;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool dispatchEvent(Event evt) native;

  void importScripts() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WorkerLocation native "*WorkerLocation" {

  String hash;

  String host;

  String hostname;

  String href;

  String pathname;

  String port;

  String protocol;

  String search;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class WorkerNavigator native "*WorkerNavigator" {

  String appName;

  String appVersion;

  bool onLine;

  String platform;

  String userAgent;

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

  bool asBlob;

  int readyState;

  Blob responseBlob;

  String responseText;

  String responseType;

  Document responseXML;

  int status;

  String statusText;

  XMLHttpRequestUpload upload;

  bool withCredentials;

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

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class XMLHttpRequestProgressEvent extends ProgressEvent native "*XMLHttpRequestProgressEvent" {

  int position;

  int totalSize;
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

  int code;

  String message;

  String name;

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

  bool booleanValue;

  bool invalidIteratorState;

  num numberValue;

  int resultType;

  Node singleNodeValue;

  int snapshotLength;

  String stringValue;

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

typedef bool RequestAnimationFrameCallback(int time);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void TimeoutHandler();
