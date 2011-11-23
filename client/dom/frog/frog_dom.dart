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

class DOMWindow native "*DOMWindow" {

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

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class EventSource native "*EventSource" {

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

  int code;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class FileException native "*FileException" {

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

  int length;

  Float32Array subarray(int start, [int end = null]) native;
}

class Float64Array extends ArrayBufferView native "*Float64Array" {

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

  int length;

  Int16Array subarray(int start, [int end = null]) native;
}

class Int32Array extends ArrayBufferView native "*Int32Array" {

  int length;

  Int32Array subarray(int start, [int end = null]) native;
}

class Int8Array extends ArrayBufferView native "*Int8Array" {

  int length;

  Int8Array subarray(int start, [int end = null]) native;
}

class JavaScriptCallFrame native "*JavaScriptCallFrame" {

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

  var dartObjectLocalStorage;

  String get typeName() native;
}

class OESTextureFloat native "*OESTextureFloat" {

  var dartObjectLocalStorage;

  String get typeName() native;
}

class OESVertexArrayObject native "*OESVertexArrayObject" {

  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  WebGLVertexArrayObjectOES createVertexArrayOES() native;

  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class OperationNotAllowedException native "*OperationNotAllowedException" {

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class OverflowEvent extends Event native "*OverflowEvent" {

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

  int code;

  String message;

  var dartObjectLocalStorage;

  String get typeName() native;
}

class SQLException native "*SQLException" {

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

  int colorType;

  RGBColor rgbColor;

  void setColor(int colorType, String rgbColor, String iccColor) native;

  void setRGBColor(String rgbColor) native;

  void setRGBColorICCColor(String rgbColor, String iccColor) native;
}

class SVGComponentTransferFunctionElement extends SVGElement native "*SVGComponentTransferFunctionElement" {

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

  int length;

  Uint16Array subarray(int start, [int end = null]) native;
}

class Uint32Array extends ArrayBufferView native "*Uint32Array" {

  int length;

  Uint32Array subarray(int start, [int end = null]) native;
}

class Uint8Array extends ArrayBufferView native "*Uint8Array" {

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
