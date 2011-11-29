#library('html');

#import('dart:dom', prefix:'dom');
#import('dart:htmlimpl');
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated Dart HTML library.




// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AnchorElement extends Element {

  String get accessKey();

  void set accessKey(String value);

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

  String getParameter(String name);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

interface AnimationList {

  int get length();

  Animation item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AreaElement extends Element {

  String get accessKey();

  void set accessKey(String value);

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

interface ArrayBuffer {

  int get byteLength();
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

interface AudioElement extends MediaElement {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BRElement extends Element {

  String get clear();

  void set clear(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BarInfo {

  bool get visible();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BaseElement extends Element {

  String get href();

  void set href(String value);

  String get target();

  void set target(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Blob {

  int get size();

  String get type();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BlobBuilder {

  void append(var blob_OR_value, [String endings]);

  Blob getBlob([String contentType]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ButtonElement extends Element {

  String get accessKey();

  void set accessKey(String value);

  bool get autofocus();

  void set autofocus(bool value);

  bool get disabled();

  void set disabled(bool value);

  FormElement get form();

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

  ElementList get labels();

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

interface CSSKeyframeRule extends CSSRule {

  String get keyText();

  void set keyText(String value);

  CSSStyleDeclaration get style();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSKeyframesRule extends CSSRule {

  CSSRuleList get cssRules();

  String get name();

  void set name(String value);

  void deleteRule(String key);

  CSSKeyframeRule findRule(String key);

  void insertRule(String rule);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CSSMatrix factory CSSMatrixFactoryProvider {

  CSSMatrix([String spec]);

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

  int get operationType();
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

interface CanvasElement extends Element {

  int get height();

  void set height(int value);

  int get width();

  void set width(int value);

  CanvasRenderingContext getContext([String contextId]);

  String toDataURL(String type);
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

  int item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasRenderingContext {

  CanvasElement get canvas();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface CanvasRenderingContext2D extends CanvasRenderingContext {

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

  String get textAlign();

  void set textAlign(String value);

  String get textBaseline();

  void set textBaseline(String value);

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

  void drawImage(var canvas_OR_image, num sx_OR_x, num sy_OR_y, [num sw_OR_width, num height_OR_sh, num dx, num dy, num dw, num dh]);

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

  void setFillStyle(var color_OR_gradient_OR_pattern);

  void setLineCap(String cap);

  void setLineJoin(String join);

  void setLineWidth(num width);

  void setMiterLimit(num limit);

  void setShadow(num width, num height, num blur, [var c_OR_color_OR_grayLevel_OR_r, num alpha_OR_g_OR_m, num b_OR_y, num a_OR_k, num a]);

  void setStrokeColor(var c_OR_color_OR_grayLevel_OR_r, [num alpha_OR_g_OR_m, num b_OR_y, num a_OR_k, num a]);

  void setStrokeStyle(var color_OR_gradient_OR_pattern);

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

interface Clipboard {

  String get dropEffect();

  void set dropEffect(String value);

  String get effectAllowed();

  void set effectAllowed(String value);

  FileList get files();

  DataTransferItems get items();

  void clearData([String type]);

  void getData(String type);

  bool setData(String type, String data);

  void setDragImage(ImageElement image, int x, int y);
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

interface Console {

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

interface DListElement extends Element {

  bool get compact();

  void set compact(bool value);
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

interface DOMFormData {

  void append(String name, String value);
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

interface DOMParser {

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

interface DOMSelection {

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

interface DataListElement extends Element {

  ElementList get options();
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

interface DataTransferItems {

  int get length();

  void add(String data, String type);

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

  int getInt8();

  int getUint16(int byteOffset, [bool littleEndian]);

  int getUint32(int byteOffset, [bool littleEndian]);

  int getUint8();

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

interface DetailsElement extends Element {

  bool get open();

  void set open(bool value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryEntry extends Entry {

  DirectoryReader createReader();

  void getDirectory(String path, [Flags flags, EntryCallback successCallback, ErrorCallback errorCallback]);

  void getFile(String path, [Flags flags, EntryCallback successCallback, ErrorCallback errorCallback]);

  void removeRecursively([VoidCallback successCallback, ErrorCallback errorCallback]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryEntrySync extends EntrySync {

  DirectoryReaderSync createReader();

  DirectoryEntrySync getDirectory(String path, Flags flags);

  FileEntrySync getFile(String path, Flags flags);

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

interface DivElement extends Element {

  String get align();

  void set align(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EmbedElement extends Element {

  String get align();

  void set align(String value);

  int get height();

  void set height(int value);

  String get name();

  void set name(String value);

  String get src();

  void set src(String value);

  String get type();

  void set type(String value);

  int get width();

  void set width(int value);
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

interface EntriesCallback {

  bool handleEvent(EntryArray entries);
}
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

  void getMetadata([MetadataCallback successCallback, ErrorCallback errorCallback]);

  void getParent([EntryCallback successCallback, ErrorCallback errorCallback]);

  void moveTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]);

  void remove([VoidCallback successCallback, ErrorCallback errorCallback]);

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

interface EntryCallback {

  bool handleEvent(Entry entry);
}
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

interface ErrorCallback {

  bool handleEvent(FileError error);
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
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FieldSetElement extends Element {

  FormElement get form();

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

interface File extends Blob {

  String get fileName();

  int get fileSize();

  Date get lastModifiedDate();

  String get name();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileCallback {

  bool handleEvent(File file);
}
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

interface FileReader factory FileReaderFactoryProvider {

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

  String get result();

  void abort();

  void readAsArrayBuffer(Blob blob);

  void readAsBinaryString(Blob blob);

  void readAsDataURL(Blob blob);

  void readAsText(Blob blob, [String encoding]);
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

interface FileSystemCallback {

  bool handleEvent(DOMFileSystem fileSystem);
}
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

interface FileWriterCallback {

  bool handleEvent(FileWriter fileWriter);
}
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

interface Flags {

  bool get create();

  void set create(bool value);

  bool get exclusive();

  void set exclusive(bool value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Float32Array extends ArrayBufferView {

  static final int BYTES_PER_ELEMENT = 4;

  int get length();

  Float32Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Float64Array extends ArrayBufferView {

  static final int BYTES_PER_ELEMENT = 8;

  int get length();

  Float64Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FontElement extends Element {

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

interface FormElement extends Element {

  String get acceptCharset();

  void set acceptCharset(String value);

  String get action();

  void set action(String value);

  String get autocomplete();

  void set autocomplete(String value);

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

interface HRElement extends Element {

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

interface HTMLAllCollection {

  int get length();

  Node item(int index);

  Node namedItem(String name);

  ElementList tags(String name);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HeadElement extends Element {

  String get profile();

  void set profile(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HeadingElement extends Element {

  String get align();

  void set align(String value);
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

interface HtmlElement extends Element {

  String get manifest();

  void set manifest(String value);

  String get version();

  void set version(String value);
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

  IDBRequest update(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBCursorWithValue extends IDBCursor {

  String get value();
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

  int get code();

  String get message();

  String get name();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBFactory {

  IDBRequest getDatabaseNames();

  IDBRequest open(String name);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBIndex {

  String get keyPath();

  String get name();

  IDBObjectStore get objectStore();

  bool get unique();

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

  IDBRequest add(String value, [IDBKey key]);

  IDBRequest clear();

  IDBIndex createIndex(String name, String keyPath);

  IDBRequest delete(IDBKey key);

  void deleteIndex(String name);

  IDBRequest getObject(IDBKey key);

  IDBIndex index(String name);

  IDBRequest openCursor([IDBKeyRange range, int direction]);

  IDBRequest put(String value, [IDBKey key]);
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

interface IFrameElement extends Element {

  String get align();

  void set align(String value);

  Document get contentDocument();

  Window get contentWindow();

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

interface ImageElement extends Element {

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

interface InputElement extends Element {

  String get accept();

  void set accept(String value);

  String get accessKey();

  void set accessKey(String value);

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

  bool get disabled();

  void set disabled(bool value);

  FileList get files();

  FormElement get form();

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

  ElementList get labels();

  Element get list();

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

  EventListener get onwebkitspeechchange();

  void set onwebkitspeechchange(EventListener value);

  String get pattern();

  void set pattern(String value);

  String get placeholder();

  void set placeholder(String value);

  bool get readOnly();

  void set readOnly(bool value);

  bool get required();

  void set required(bool value);

  OptionElement get selectedOption();

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

  void setValueForUser(String value);

  void stepDown([int n]);

  void stepUp([int n]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int16Array extends ArrayBufferView {

  static final int BYTES_PER_ELEMENT = 2;

  int get length();

  Int16Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int32Array extends ArrayBufferView {

  static final int BYTES_PER_ELEMENT = 4;

  int get length();

  Int32Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Int8Array extends ArrayBufferView {

  static final int BYTES_PER_ELEMENT = 1;

  int get length();

  Int8Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface KeygenElement extends Element {

  bool get autofocus();

  void set autofocus(bool value);

  String get challenge();

  void set challenge(String value);

  bool get disabled();

  void set disabled(bool value);

  FormElement get form();

  String get keytype();

  void set keytype(String value);

  ElementList get labels();

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

interface LIElement extends Element {

  String get type();

  void set type(String value);

  int get value();

  void set value(int value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LabelElement extends Element {

  String get accessKey();

  void set accessKey(String value);

  Element get control();

  FormElement get form();

  String get htmlFor();

  void set htmlFor(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LegendElement extends Element {

  String get accessKey();

  void set accessKey(String value);

  String get align();

  void set align(String value);

  FormElement get form();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LinkElement extends Element {

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

  String get target();

  void set target(String value);

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LocalMediaStream extends MediaStream {

  void stop();
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

  String getParameter(String name);

  void reload();

  void replace(String url);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface LoseContext {

  void loseContext();

  void restoreContext();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MapElement extends Element {

  ElementList get areas();

  String get name();

  void set name(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MarqueeElement extends Element {

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

interface MediaElement extends Element {

  static final int HAVE_CURRENT_DATA = 2;

  static final int HAVE_ENOUGH_DATA = 4;

  static final int HAVE_FUTURE_DATA = 3;

  static final int HAVE_METADATA = 1;

  static final int HAVE_NOTHING = 0;

  static final int NETWORK_EMPTY = 0;

  static final int NETWORK_IDLE = 1;

  static final int NETWORK_LOADING = 2;

  static final int NETWORK_NO_SOURCE = 3;

  bool get autoplay();

  void set autoplay(bool value);

  TimeRanges get buffered();

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

  num get volume();

  void set volume(num value);

  int get webkitAudioDecodedByteCount();

  bool get webkitClosedCaptionsVisible();

  void set webkitClosedCaptionsVisible(bool value);

  bool get webkitHasClosedCaptions();

  bool get webkitPreservesPitch();

  void set webkitPreservesPitch(bool value);

  int get webkitVideoDecodedByteCount();

  String canPlayType(String type);

  void load();

  void pause();

  void play();
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

interface MediaStream {

  static final int ENDED = 2;

  static final int LIVE = 1;

  String get label();

  EventListener get onended();

  void set onended(EventListener value);

  int get readyState();

  MediaStreamTrackList get tracks();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event event);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaStreamList {

  int get length();

  MediaStream item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaStreamTrack {

  bool get enabled();

  void set enabled(bool value);

  String get kind();

  String get label();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MediaStreamTrackList {

  int get length();

  MediaStreamTrack item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MenuElement extends Element {

  bool get compact();

  void set compact(bool value);
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

interface MetaElement extends Element {

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

interface Metadata {

  Date get modificationTime();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MetadataCallback {

  bool handleEvent(Metadata metadata);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MeterElement extends Element {

  FormElement get form();

  num get high();

  void set high(num value);

  ElementList get labels();

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

interface ModElement extends Element {

  String get cite();

  void set cite(String value);

  String get dateTime();

  void set dateTime(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MutationRecord {

  ElementList get addedNodes();

  String get attributeName();

  String get attributeNamespace();

  Node get nextSibling();

  String get oldValue();

  Node get previousSibling();

  ElementList get removedNodes();

  Node get target();

  String get type();
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
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NavigatorUserMediaError {

  static final int PERMISSION_DENIED = 1;

  int get code();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NavigatorUserMediaErrorCallback {

  bool handleEvent(NavigatorUserMediaError error);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NavigatorUserMediaSuccessCallback {

  bool handleEvent(LocalMediaStream stream);
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

interface OListElement extends Element {

  bool get compact();

  void set compact(bool value);

  int get start();

  void set start(int value);

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ObjectElement extends Element {

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

  FormElement get form();

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

  void setCustomValidity(String error);
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
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OptGroupElement extends Element {

  bool get disabled();

  void set disabled(bool value);

  String get label();

  void set label(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OptionElement extends Element {

  bool get defaultSelected();

  void set defaultSelected(bool value);

  bool get disabled();

  void set disabled(bool value);

  FormElement get form();

  int get index();

  String get label();

  void set label(String value);

  bool get selected();

  void set selected(bool value);

  String get text();

  String get value();

  void set value(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface OutputElement extends Element {

  String get defaultValue();

  void set defaultValue(String value);

  FormElement get form();

  DOMSettableTokenList get htmlFor();

  void set htmlFor(DOMSettableTokenList value);

  ElementList get labels();

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

interface ParagraphElement extends Element {

  String get align();

  void set align(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ParamElement extends Element {

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

interface Point factory PointFactoryProvider {

  Point(num x, num y);

  num get x();

  void set x(num value);

  num get y();

  void set y(num value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PositionCallback {

  bool handleEvent(Geoposition position);
}
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

interface PositionErrorCallback {

  bool handleEvent(PositionError error);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface PreElement extends Element {

  int get width();

  void set width(int value);

  bool get wrap();

  void set wrap(bool value);
}
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

interface ProgressElement extends Element {

  FormElement get form();

  ElementList get labels();

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

interface QuoteElement extends Element {

  String get cite();

  void set cite(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface RGBColor {

  CSSPrimitiveValue get alpha();

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

  String get text();

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

interface ScriptElement extends Element {

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

interface SelectElement extends Element {

  bool get autofocus();

  void set autofocus(bool value);

  bool get disabled();

  void set disabled(bool value);

  FormElement get form();

  ElementList get labels();

  int get length();

  void set length(int value);

  bool get multiple();

  void set multiple(bool value);

  String get name();

  void set name(String value);

  ElementList get options();

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

  void add(Element element, Element before);

  bool checkValidity();

  Node item(int index);

  Node namedItem(String name);

  void setCustomValidity(String error);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface SourceElement extends Element {

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

interface SpanElement extends Element {
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

interface StorageInfoErrorCallback {

  bool handleEvent(DOMException error);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StorageInfoQuotaCallback {

  bool handleEvent(int grantedQuotaInBytes);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StorageInfoUsageCallback {

  bool handleEvent(int currentUsageInBytes, int currentQuotaInBytes);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StringCallback {

  bool handleEvent(String data);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface StyleElement extends Element {

  bool get disabled();

  void set disabled(bool value);

  String get media();

  void set media(String value);

  StyleSheet get sheet();

  String get type();

  void set type(String value);
}
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

interface TableCaptionElement extends Element {

  String get align();

  void set align(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableCellElement extends Element {

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

interface TableColElement extends Element {

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

interface TableElement extends Element {

  String get align();

  void set align(String value);

  String get bgColor();

  void set bgColor(String value);

  String get border();

  void set border(String value);

  TableCaptionElement get caption();

  void set caption(TableCaptionElement value);

  String get cellPadding();

  void set cellPadding(String value);

  String get cellSpacing();

  void set cellSpacing(String value);

  String get frame();

  void set frame(String value);

  ElementList get rows();

  String get rules();

  void set rules(String value);

  String get summary();

  void set summary(String value);

  ElementList get tBodies();

  TableSectionElement get tFoot();

  void set tFoot(TableSectionElement value);

  TableSectionElement get tHead();

  void set tHead(TableSectionElement value);

  String get width();

  void set width(String value);

  Element createCaption();

  Element createTFoot();

  Element createTHead();

  void deleteCaption();

  void deleteRow(int index);

  void deleteTFoot();

  void deleteTHead();

  Element insertRow(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableRowElement extends Element {

  String get align();

  void set align(String value);

  String get bgColor();

  void set bgColor(String value);

  ElementList get cells();

  String get ch();

  void set ch(String value);

  String get chOff();

  void set chOff(String value);

  int get rowIndex();

  int get sectionRowIndex();

  String get vAlign();

  void set vAlign(String value);

  void deleteCell(int index);

  Element insertCell(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TableSectionElement extends Element {

  String get align();

  void set align(String value);

  String get ch();

  void set ch(String value);

  String get chOff();

  void set chOff(String value);

  ElementList get rows();

  String get vAlign();

  void set vAlign(String value);

  void deleteRow(int index);

  Element insertRow(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TextAreaElement extends Element {

  String get accessKey();

  void set accessKey(String value);

  bool get autofocus();

  void set autofocus(bool value);

  int get cols();

  void set cols(int value);

  String get defaultValue();

  void set defaultValue(String value);

  bool get disabled();

  void set disabled(bool value);

  FormElement get form();

  ElementList get labels();

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

interface TextMetrics {

  num get width();
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

interface TitleElement extends Element {

  String get text();

  void set text(String value);
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

interface TouchList extends List<Touch> {

  int get length();

  Touch item(int index);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TrackElement extends Element {

  bool get isDefault();

  void set isDefault(bool value);

  String get kind();

  void set kind(String value);

  String get label();

  void set label(String value);

  String get src();

  void set src(String value);

  String get srclang();

  void set srclang(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface UListElement extends Element {

  bool get compact();

  void set compact(bool value);

  String get type();

  void set type(String value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint16Array extends ArrayBufferView {

  static final int BYTES_PER_ELEMENT = 2;

  int get length();

  Uint16Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint32Array extends ArrayBufferView {

  static final int BYTES_PER_ELEMENT = 4;

  int get length();

  Uint32Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Uint8Array extends ArrayBufferView {

  static final int BYTES_PER_ELEMENT = 1;

  int get length();

  Uint8Array subarray(int start, [int end]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface UnknownElement extends Element {
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

interface VideoElement extends MediaElement {

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

interface VoidCallback {

  void handleEvent();
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

interface WebGLFramebuffer {
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

  void getAttachedShaders(WebGLProgram program);

  int getAttribLocation(WebGLProgram program, String name);

  void getBufferParameter();

  WebGLContextAttributes getContextAttributes();

  int getError();

  void getExtension(String name);

  void getFramebufferAttachmentParameter();

  void getParameter();

  String getProgramInfoLog(WebGLProgram program);

  void getProgramParameter();

  void getRenderbufferParameter();

  String getShaderInfoLog(WebGLShader shader);

  void getShaderParameter();

  String getShaderSource(WebGLShader shader);

  void getSupportedExtensions();

  void getTexParameter();

  void getUniform();

  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name);

  void getVertexAttrib();

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

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels, [int format, int type, ArrayBufferView pixels]);

  void texParameterf(int target, int pname, num param);

  void texParameteri(int target, int pname, int param);

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels, [int type, ArrayBufferView pixels]);

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

interface XMLHttpRequestException {

  static final int ABORT_ERR = 102;

  static final int NETWORK_ERR = 101;

  int get code();

  String get message();

  String get name();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface AbstractWorkerEvents extends Events {
  EventListenerList get error();
}

interface AbstractWorker extends EventTarget {
  AbstractWorkerEvents get on();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface AnimationEvent extends Event factory AnimationEventWrappingImplementation {

  AnimationEvent(String type, String propertyName, double elapsedTime,
      [bool canBubble, bool cancelable]);

  String get animationName();

  num get elapsedTime();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface BeforeLoadEvent extends Event factory BeforeLoadEventWrappingImplementation {

  BeforeLoadEvent(String type, String url, [bool canBubble, bool cancelable]);

  String get url();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface BodyElementEvents extends ElementEvents {
  EventListenerList get beforeUnload();
  EventListenerList get hashChange();
  EventListenerList get message();
  EventListenerList get offline();
  EventListenerList get online();
  EventListenerList get orientationChange();
  EventListenerList get popState();
  EventListenerList get resize();
  EventListenerList get storage();
  EventListenerList get unLoad();
}

interface BodyElement extends Element { 
  BodyElementEvents get on();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface CloseEvent extends Event factory CloseEventWrappingImplementation {

  CloseEvent(String type, int code, String reason,
      [bool canBubble, bool cancelable, bool wasClean]);

  int get code();

  String get reason();

  bool get wasClean();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface CompositionEvent extends UIEvent factory CompositionEventWrappingImplementation {

  CompositionEvent(String type, Window view, String data, [bool canBubble,
      bool cancelable]);

  String get data();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit.
// This file was generated by html/scripts/css_code_generator.py

// Source of CSS properties:
//   Source/WebCore/css/CSSPropertyNames.in

// TODO(jacobr): add versions that take numeric values in px, miliseconds, etc.

interface CSSStyleDeclaration factory CSSStyleDeclarationWrappingImplementation {

  CSSStyleDeclaration();

  CSSStyleDeclaration.css(String css);

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

  /** Gets the value of "animation" */
  String get animation();

  /** Sets the value of "animation" */
  void set animation(String value);

  /** Gets the value of "animation-delay" */
  String get animationDelay();

  /** Sets the value of "animation-delay" */
  void set animationDelay(String value);

  /** Gets the value of "animation-direction" */
  String get animationDirection();

  /** Sets the value of "animation-direction" */
  void set animationDirection(String value);

  /** Gets the value of "animation-duration" */
  String get animationDuration();

  /** Sets the value of "animation-duration" */
  void set animationDuration(String value);

  /** Gets the value of "animation-fill-mode" */
  String get animationFillMode();

  /** Sets the value of "animation-fill-mode" */
  void set animationFillMode(String value);

  /** Gets the value of "animation-iteration-count" */
  String get animationIterationCount();

  /** Sets the value of "animation-iteration-count" */
  void set animationIterationCount(String value);

  /** Gets the value of "animation-name" */
  String get animationName();

  /** Sets the value of "animation-name" */
  void set animationName(String value);

  /** Gets the value of "animation-play-state" */
  String get animationPlayState();

  /** Sets the value of "animation-play-state" */
  void set animationPlayState(String value);

  /** Gets the value of "animation-timing-function" */
  String get animationTimingFunction();

  /** Sets the value of "animation-timing-function" */
  void set animationTimingFunction(String value);

  /** Gets the value of "appearance" */
  String get appearance();

  /** Sets the value of "appearance" */
  void set appearance(String value);

  /** Gets the value of "backface-visibility" */
  String get backfaceVisibility();

  /** Sets the value of "backface-visibility" */
  void set backfaceVisibility(String value);

  /** Gets the value of "background" */
  String get background();

  /** Sets the value of "background" */
  void set background(String value);

  /** Gets the value of "background-attachment" */
  String get backgroundAttachment();

  /** Sets the value of "background-attachment" */
  void set backgroundAttachment(String value);

  /** Gets the value of "background-clip" */
  String get backgroundClip();

  /** Sets the value of "background-clip" */
  void set backgroundClip(String value);

  /** Gets the value of "background-color" */
  String get backgroundColor();

  /** Sets the value of "background-color" */
  void set backgroundColor(String value);

  /** Gets the value of "background-composite" */
  String get backgroundComposite();

  /** Sets the value of "background-composite" */
  void set backgroundComposite(String value);

  /** Gets the value of "background-image" */
  String get backgroundImage();

  /** Sets the value of "background-image" */
  void set backgroundImage(String value);

  /** Gets the value of "background-origin" */
  String get backgroundOrigin();

  /** Sets the value of "background-origin" */
  void set backgroundOrigin(String value);

  /** Gets the value of "background-position" */
  String get backgroundPosition();

  /** Sets the value of "background-position" */
  void set backgroundPosition(String value);

  /** Gets the value of "background-position-x" */
  String get backgroundPositionX();

  /** Sets the value of "background-position-x" */
  void set backgroundPositionX(String value);

  /** Gets the value of "background-position-y" */
  String get backgroundPositionY();

  /** Sets the value of "background-position-y" */
  void set backgroundPositionY(String value);

  /** Gets the value of "background-repeat" */
  String get backgroundRepeat();

  /** Sets the value of "background-repeat" */
  void set backgroundRepeat(String value);

  /** Gets the value of "background-repeat-x" */
  String get backgroundRepeatX();

  /** Sets the value of "background-repeat-x" */
  void set backgroundRepeatX(String value);

  /** Gets the value of "background-repeat-y" */
  String get backgroundRepeatY();

  /** Sets the value of "background-repeat-y" */
  void set backgroundRepeatY(String value);

  /** Gets the value of "background-size" */
  String get backgroundSize();

  /** Sets the value of "background-size" */
  void set backgroundSize(String value);

  /** Gets the value of "border" */
  String get border();

  /** Sets the value of "border" */
  void set border(String value);

  /** Gets the value of "border-after" */
  String get borderAfter();

  /** Sets the value of "border-after" */
  void set borderAfter(String value);

  /** Gets the value of "border-after-color" */
  String get borderAfterColor();

  /** Sets the value of "border-after-color" */
  void set borderAfterColor(String value);

  /** Gets the value of "border-after-style" */
  String get borderAfterStyle();

  /** Sets the value of "border-after-style" */
  void set borderAfterStyle(String value);

  /** Gets the value of "border-after-width" */
  String get borderAfterWidth();

  /** Sets the value of "border-after-width" */
  void set borderAfterWidth(String value);

  /** Gets the value of "border-before" */
  String get borderBefore();

  /** Sets the value of "border-before" */
  void set borderBefore(String value);

  /** Gets the value of "border-before-color" */
  String get borderBeforeColor();

  /** Sets the value of "border-before-color" */
  void set borderBeforeColor(String value);

  /** Gets the value of "border-before-style" */
  String get borderBeforeStyle();

  /** Sets the value of "border-before-style" */
  void set borderBeforeStyle(String value);

  /** Gets the value of "border-before-width" */
  String get borderBeforeWidth();

  /** Sets the value of "border-before-width" */
  void set borderBeforeWidth(String value);

  /** Gets the value of "border-bottom" */
  String get borderBottom();

  /** Sets the value of "border-bottom" */
  void set borderBottom(String value);

  /** Gets the value of "border-bottom-color" */
  String get borderBottomColor();

  /** Sets the value of "border-bottom-color" */
  void set borderBottomColor(String value);

  /** Gets the value of "border-bottom-left-radius" */
  String get borderBottomLeftRadius();

  /** Sets the value of "border-bottom-left-radius" */
  void set borderBottomLeftRadius(String value);

  /** Gets the value of "border-bottom-right-radius" */
  String get borderBottomRightRadius();

  /** Sets the value of "border-bottom-right-radius" */
  void set borderBottomRightRadius(String value);

  /** Gets the value of "border-bottom-style" */
  String get borderBottomStyle();

  /** Sets the value of "border-bottom-style" */
  void set borderBottomStyle(String value);

  /** Gets the value of "border-bottom-width" */
  String get borderBottomWidth();

  /** Sets the value of "border-bottom-width" */
  void set borderBottomWidth(String value);

  /** Gets the value of "border-collapse" */
  String get borderCollapse();

  /** Sets the value of "border-collapse" */
  void set borderCollapse(String value);

  /** Gets the value of "border-color" */
  String get borderColor();

  /** Sets the value of "border-color" */
  void set borderColor(String value);

  /** Gets the value of "border-end" */
  String get borderEnd();

  /** Sets the value of "border-end" */
  void set borderEnd(String value);

  /** Gets the value of "border-end-color" */
  String get borderEndColor();

  /** Sets the value of "border-end-color" */
  void set borderEndColor(String value);

  /** Gets the value of "border-end-style" */
  String get borderEndStyle();

  /** Sets the value of "border-end-style" */
  void set borderEndStyle(String value);

  /** Gets the value of "border-end-width" */
  String get borderEndWidth();

  /** Sets the value of "border-end-width" */
  void set borderEndWidth(String value);

  /** Gets the value of "border-fit" */
  String get borderFit();

  /** Sets the value of "border-fit" */
  void set borderFit(String value);

  /** Gets the value of "border-horizontal-spacing" */
  String get borderHorizontalSpacing();

  /** Sets the value of "border-horizontal-spacing" */
  void set borderHorizontalSpacing(String value);

  /** Gets the value of "border-image" */
  String get borderImage();

  /** Sets the value of "border-image" */
  void set borderImage(String value);

  /** Gets the value of "border-image-outset" */
  String get borderImageOutset();

  /** Sets the value of "border-image-outset" */
  void set borderImageOutset(String value);

  /** Gets the value of "border-image-repeat" */
  String get borderImageRepeat();

  /** Sets the value of "border-image-repeat" */
  void set borderImageRepeat(String value);

  /** Gets the value of "border-image-slice" */
  String get borderImageSlice();

  /** Sets the value of "border-image-slice" */
  void set borderImageSlice(String value);

  /** Gets the value of "border-image-source" */
  String get borderImageSource();

  /** Sets the value of "border-image-source" */
  void set borderImageSource(String value);

  /** Gets the value of "border-image-width" */
  String get borderImageWidth();

  /** Sets the value of "border-image-width" */
  void set borderImageWidth(String value);

  /** Gets the value of "border-left" */
  String get borderLeft();

  /** Sets the value of "border-left" */
  void set borderLeft(String value);

  /** Gets the value of "border-left-color" */
  String get borderLeftColor();

  /** Sets the value of "border-left-color" */
  void set borderLeftColor(String value);

  /** Gets the value of "border-left-style" */
  String get borderLeftStyle();

  /** Sets the value of "border-left-style" */
  void set borderLeftStyle(String value);

  /** Gets the value of "border-left-width" */
  String get borderLeftWidth();

  /** Sets the value of "border-left-width" */
  void set borderLeftWidth(String value);

  /** Gets the value of "border-radius" */
  String get borderRadius();

  /** Sets the value of "border-radius" */
  void set borderRadius(String value);

  /** Gets the value of "border-right" */
  String get borderRight();

  /** Sets the value of "border-right" */
  void set borderRight(String value);

  /** Gets the value of "border-right-color" */
  String get borderRightColor();

  /** Sets the value of "border-right-color" */
  void set borderRightColor(String value);

  /** Gets the value of "border-right-style" */
  String get borderRightStyle();

  /** Sets the value of "border-right-style" */
  void set borderRightStyle(String value);

  /** Gets the value of "border-right-width" */
  String get borderRightWidth();

  /** Sets the value of "border-right-width" */
  void set borderRightWidth(String value);

  /** Gets the value of "border-spacing" */
  String get borderSpacing();

  /** Sets the value of "border-spacing" */
  void set borderSpacing(String value);

  /** Gets the value of "border-start" */
  String get borderStart();

  /** Sets the value of "border-start" */
  void set borderStart(String value);

  /** Gets the value of "border-start-color" */
  String get borderStartColor();

  /** Sets the value of "border-start-color" */
  void set borderStartColor(String value);

  /** Gets the value of "border-start-style" */
  String get borderStartStyle();

  /** Sets the value of "border-start-style" */
  void set borderStartStyle(String value);

  /** Gets the value of "border-start-width" */
  String get borderStartWidth();

  /** Sets the value of "border-start-width" */
  void set borderStartWidth(String value);

  /** Gets the value of "border-style" */
  String get borderStyle();

  /** Sets the value of "border-style" */
  void set borderStyle(String value);

  /** Gets the value of "border-top" */
  String get borderTop();

  /** Sets the value of "border-top" */
  void set borderTop(String value);

  /** Gets the value of "border-top-color" */
  String get borderTopColor();

  /** Sets the value of "border-top-color" */
  void set borderTopColor(String value);

  /** Gets the value of "border-top-left-radius" */
  String get borderTopLeftRadius();

  /** Sets the value of "border-top-left-radius" */
  void set borderTopLeftRadius(String value);

  /** Gets the value of "border-top-right-radius" */
  String get borderTopRightRadius();

  /** Sets the value of "border-top-right-radius" */
  void set borderTopRightRadius(String value);

  /** Gets the value of "border-top-style" */
  String get borderTopStyle();

  /** Sets the value of "border-top-style" */
  void set borderTopStyle(String value);

  /** Gets the value of "border-top-width" */
  String get borderTopWidth();

  /** Sets the value of "border-top-width" */
  void set borderTopWidth(String value);

  /** Gets the value of "border-vertical-spacing" */
  String get borderVerticalSpacing();

  /** Sets the value of "border-vertical-spacing" */
  void set borderVerticalSpacing(String value);

  /** Gets the value of "border-width" */
  String get borderWidth();

  /** Sets the value of "border-width" */
  void set borderWidth(String value);

  /** Gets the value of "bottom" */
  String get bottom();

  /** Sets the value of "bottom" */
  void set bottom(String value);

  /** Gets the value of "box-align" */
  String get boxAlign();

  /** Sets the value of "box-align" */
  void set boxAlign(String value);

  /** Gets the value of "box-direction" */
  String get boxDirection();

  /** Sets the value of "box-direction" */
  void set boxDirection(String value);

  /** Gets the value of "box-flex" */
  String get boxFlex();

  /** Sets the value of "box-flex" */
  void set boxFlex(String value);

  /** Gets the value of "box-flex-group" */
  String get boxFlexGroup();

  /** Sets the value of "box-flex-group" */
  void set boxFlexGroup(String value);

  /** Gets the value of "box-lines" */
  String get boxLines();

  /** Sets the value of "box-lines" */
  void set boxLines(String value);

  /** Gets the value of "box-ordinal-group" */
  String get boxOrdinalGroup();

  /** Sets the value of "box-ordinal-group" */
  void set boxOrdinalGroup(String value);

  /** Gets the value of "box-orient" */
  String get boxOrient();

  /** Sets the value of "box-orient" */
  void set boxOrient(String value);

  /** Gets the value of "box-pack" */
  String get boxPack();

  /** Sets the value of "box-pack" */
  void set boxPack(String value);

  /** Gets the value of "box-reflect" */
  String get boxReflect();

  /** Sets the value of "box-reflect" */
  void set boxReflect(String value);

  /** Gets the value of "box-shadow" */
  String get boxShadow();

  /** Sets the value of "box-shadow" */
  void set boxShadow(String value);

  /** Gets the value of "box-sizing" */
  String get boxSizing();

  /** Sets the value of "box-sizing" */
  void set boxSizing(String value);

  /** Gets the value of "caption-side" */
  String get captionSide();

  /** Sets the value of "caption-side" */
  void set captionSide(String value);

  /** Gets the value of "clear" */
  String get clear();

  /** Sets the value of "clear" */
  void set clear(String value);

  /** Gets the value of "clip" */
  String get clip();

  /** Sets the value of "clip" */
  void set clip(String value);

  /** Gets the value of "color" */
  String get color();

  /** Sets the value of "color" */
  void set color(String value);

  /** Gets the value of "color-correction" */
  String get colorCorrection();

  /** Sets the value of "color-correction" */
  void set colorCorrection(String value);

  /** Gets the value of "column-break-after" */
  String get columnBreakAfter();

  /** Sets the value of "column-break-after" */
  void set columnBreakAfter(String value);

  /** Gets the value of "column-break-before" */
  String get columnBreakBefore();

  /** Sets the value of "column-break-before" */
  void set columnBreakBefore(String value);

  /** Gets the value of "column-break-inside" */
  String get columnBreakInside();

  /** Sets the value of "column-break-inside" */
  void set columnBreakInside(String value);

  /** Gets the value of "column-count" */
  String get columnCount();

  /** Sets the value of "column-count" */
  void set columnCount(String value);

  /** Gets the value of "column-gap" */
  String get columnGap();

  /** Sets the value of "column-gap" */
  void set columnGap(String value);

  /** Gets the value of "column-rule" */
  String get columnRule();

  /** Sets the value of "column-rule" */
  void set columnRule(String value);

  /** Gets the value of "column-rule-color" */
  String get columnRuleColor();

  /** Sets the value of "column-rule-color" */
  void set columnRuleColor(String value);

  /** Gets the value of "column-rule-style" */
  String get columnRuleStyle();

  /** Sets the value of "column-rule-style" */
  void set columnRuleStyle(String value);

  /** Gets the value of "column-rule-width" */
  String get columnRuleWidth();

  /** Sets the value of "column-rule-width" */
  void set columnRuleWidth(String value);

  /** Gets the value of "column-span" */
  String get columnSpan();

  /** Sets the value of "column-span" */
  void set columnSpan(String value);

  /** Gets the value of "column-width" */
  String get columnWidth();

  /** Sets the value of "column-width" */
  void set columnWidth(String value);

  /** Gets the value of "columns" */
  String get columns();

  /** Sets the value of "columns" */
  void set columns(String value);

  /** Gets the value of "content" */
  String get content();

  /** Sets the value of "content" */
  void set content(String value);

  /** Gets the value of "counter-increment" */
  String get counterIncrement();

  /** Sets the value of "counter-increment" */
  void set counterIncrement(String value);

  /** Gets the value of "counter-reset" */
  String get counterReset();

  /** Sets the value of "counter-reset" */
  void set counterReset(String value);

  /** Gets the value of "cursor" */
  String get cursor();

  /** Sets the value of "cursor" */
  void set cursor(String value);

  /** Gets the value of "direction" */
  String get direction();

  /** Sets the value of "direction" */
  void set direction(String value);

  /** Gets the value of "display" */
  String get display();

  /** Sets the value of "display" */
  void set display(String value);

  /** Gets the value of "empty-cells" */
  String get emptyCells();

  /** Sets the value of "empty-cells" */
  void set emptyCells(String value);

  /** Gets the value of "filter" */
  String get filter();

  /** Sets the value of "filter" */
  void set filter(String value);

  /** Gets the value of "flex-align" */
  String get flexAlign();

  /** Sets the value of "flex-align" */
  void set flexAlign(String value);

  /** Gets the value of "flex-flow" */
  String get flexFlow();

  /** Sets the value of "flex-flow" */
  void set flexFlow(String value);

  /** Gets the value of "flex-order" */
  String get flexOrder();

  /** Sets the value of "flex-order" */
  void set flexOrder(String value);

  /** Gets the value of "flex-pack" */
  String get flexPack();

  /** Sets the value of "flex-pack" */
  void set flexPack(String value);

  /** Gets the value of "float" */
  String get float();

  /** Sets the value of "float" */
  void set float(String value);

  /** Gets the value of "flow-from" */
  String get flowFrom();

  /** Sets the value of "flow-from" */
  void set flowFrom(String value);

  /** Gets the value of "flow-into" */
  String get flowInto();

  /** Sets the value of "flow-into" */
  void set flowInto(String value);

  /** Gets the value of "font" */
  String get font();

  /** Sets the value of "font" */
  void set font(String value);

  /** Gets the value of "font-family" */
  String get fontFamily();

  /** Sets the value of "font-family" */
  void set fontFamily(String value);

  /** Gets the value of "font-feature-settings" */
  String get fontFeatureSettings();

  /** Sets the value of "font-feature-settings" */
  void set fontFeatureSettings(String value);

  /** Gets the value of "font-size" */
  String get fontSize();

  /** Sets the value of "font-size" */
  void set fontSize(String value);

  /** Gets the value of "font-size-delta" */
  String get fontSizeDelta();

  /** Sets the value of "font-size-delta" */
  void set fontSizeDelta(String value);

  /** Gets the value of "font-smoothing" */
  String get fontSmoothing();

  /** Sets the value of "font-smoothing" */
  void set fontSmoothing(String value);

  /** Gets the value of "font-stretch" */
  String get fontStretch();

  /** Sets the value of "font-stretch" */
  void set fontStretch(String value);

  /** Gets the value of "font-style" */
  String get fontStyle();

  /** Sets the value of "font-style" */
  void set fontStyle(String value);

  /** Gets the value of "font-variant" */
  String get fontVariant();

  /** Sets the value of "font-variant" */
  void set fontVariant(String value);

  /** Gets the value of "font-weight" */
  String get fontWeight();

  /** Sets the value of "font-weight" */
  void set fontWeight(String value);

  /** Gets the value of "height" */
  String get height();

  /** Sets the value of "height" */
  void set height(String value);

  /** Gets the value of "highlight" */
  String get highlight();

  /** Sets the value of "highlight" */
  void set highlight(String value);

  /** Gets the value of "hyphenate-character" */
  String get hyphenateCharacter();

  /** Sets the value of "hyphenate-character" */
  void set hyphenateCharacter(String value);

  /** Gets the value of "hyphenate-limit-after" */
  String get hyphenateLimitAfter();

  /** Sets the value of "hyphenate-limit-after" */
  void set hyphenateLimitAfter(String value);

  /** Gets the value of "hyphenate-limit-before" */
  String get hyphenateLimitBefore();

  /** Sets the value of "hyphenate-limit-before" */
  void set hyphenateLimitBefore(String value);

  /** Gets the value of "hyphenate-limit-lines" */
  String get hyphenateLimitLines();

  /** Sets the value of "hyphenate-limit-lines" */
  void set hyphenateLimitLines(String value);

  /** Gets the value of "hyphens" */
  String get hyphens();

  /** Sets the value of "hyphens" */
  void set hyphens(String value);

  /** Gets the value of "image-rendering" */
  String get imageRendering();

  /** Sets the value of "image-rendering" */
  void set imageRendering(String value);

  /** Gets the value of "left" */
  String get left();

  /** Sets the value of "left" */
  void set left(String value);

  /** Gets the value of "letter-spacing" */
  String get letterSpacing();

  /** Sets the value of "letter-spacing" */
  void set letterSpacing(String value);

  /** Gets the value of "line-box-contain" */
  String get lineBoxContain();

  /** Sets the value of "line-box-contain" */
  void set lineBoxContain(String value);

  /** Gets the value of "line-break" */
  String get lineBreak();

  /** Sets the value of "line-break" */
  void set lineBreak(String value);

  /** Gets the value of "line-clamp" */
  String get lineClamp();

  /** Sets the value of "line-clamp" */
  void set lineClamp(String value);

  /** Gets the value of "line-height" */
  String get lineHeight();

  /** Sets the value of "line-height" */
  void set lineHeight(String value);

  /** Gets the value of "list-style" */
  String get listStyle();

  /** Sets the value of "list-style" */
  void set listStyle(String value);

  /** Gets the value of "list-style-image" */
  String get listStyleImage();

  /** Sets the value of "list-style-image" */
  void set listStyleImage(String value);

  /** Gets the value of "list-style-position" */
  String get listStylePosition();

  /** Sets the value of "list-style-position" */
  void set listStylePosition(String value);

  /** Gets the value of "list-style-type" */
  String get listStyleType();

  /** Sets the value of "list-style-type" */
  void set listStyleType(String value);

  /** Gets the value of "locale" */
  String get locale();

  /** Sets the value of "locale" */
  void set locale(String value);

  /** Gets the value of "logical-height" */
  String get logicalHeight();

  /** Sets the value of "logical-height" */
  void set logicalHeight(String value);

  /** Gets the value of "logical-width" */
  String get logicalWidth();

  /** Sets the value of "logical-width" */
  void set logicalWidth(String value);

  /** Gets the value of "margin" */
  String get margin();

  /** Sets the value of "margin" */
  void set margin(String value);

  /** Gets the value of "margin-after" */
  String get marginAfter();

  /** Sets the value of "margin-after" */
  void set marginAfter(String value);

  /** Gets the value of "margin-after-collapse" */
  String get marginAfterCollapse();

  /** Sets the value of "margin-after-collapse" */
  void set marginAfterCollapse(String value);

  /** Gets the value of "margin-before" */
  String get marginBefore();

  /** Sets the value of "margin-before" */
  void set marginBefore(String value);

  /** Gets the value of "margin-before-collapse" */
  String get marginBeforeCollapse();

  /** Sets the value of "margin-before-collapse" */
  void set marginBeforeCollapse(String value);

  /** Gets the value of "margin-bottom" */
  String get marginBottom();

  /** Sets the value of "margin-bottom" */
  void set marginBottom(String value);

  /** Gets the value of "margin-bottom-collapse" */
  String get marginBottomCollapse();

  /** Sets the value of "margin-bottom-collapse" */
  void set marginBottomCollapse(String value);

  /** Gets the value of "margin-collapse" */
  String get marginCollapse();

  /** Sets the value of "margin-collapse" */
  void set marginCollapse(String value);

  /** Gets the value of "margin-end" */
  String get marginEnd();

  /** Sets the value of "margin-end" */
  void set marginEnd(String value);

  /** Gets the value of "margin-left" */
  String get marginLeft();

  /** Sets the value of "margin-left" */
  void set marginLeft(String value);

  /** Gets the value of "margin-right" */
  String get marginRight();

  /** Sets the value of "margin-right" */
  void set marginRight(String value);

  /** Gets the value of "margin-start" */
  String get marginStart();

  /** Sets the value of "margin-start" */
  void set marginStart(String value);

  /** Gets the value of "margin-top" */
  String get marginTop();

  /** Sets the value of "margin-top" */
  void set marginTop(String value);

  /** Gets the value of "margin-top-collapse" */
  String get marginTopCollapse();

  /** Sets the value of "margin-top-collapse" */
  void set marginTopCollapse(String value);

  /** Gets the value of "marquee" */
  String get marquee();

  /** Sets the value of "marquee" */
  void set marquee(String value);

  /** Gets the value of "marquee-direction" */
  String get marqueeDirection();

  /** Sets the value of "marquee-direction" */
  void set marqueeDirection(String value);

  /** Gets the value of "marquee-increment" */
  String get marqueeIncrement();

  /** Sets the value of "marquee-increment" */
  void set marqueeIncrement(String value);

  /** Gets the value of "marquee-repetition" */
  String get marqueeRepetition();

  /** Sets the value of "marquee-repetition" */
  void set marqueeRepetition(String value);

  /** Gets the value of "marquee-speed" */
  String get marqueeSpeed();

  /** Sets the value of "marquee-speed" */
  void set marqueeSpeed(String value);

  /** Gets the value of "marquee-style" */
  String get marqueeStyle();

  /** Sets the value of "marquee-style" */
  void set marqueeStyle(String value);

  /** Gets the value of "mask" */
  String get mask();

  /** Sets the value of "mask" */
  void set mask(String value);

  /** Gets the value of "mask-attachment" */
  String get maskAttachment();

  /** Sets the value of "mask-attachment" */
  void set maskAttachment(String value);

  /** Gets the value of "mask-box-image" */
  String get maskBoxImage();

  /** Sets the value of "mask-box-image" */
  void set maskBoxImage(String value);

  /** Gets the value of "mask-box-image-outset" */
  String get maskBoxImageOutset();

  /** Sets the value of "mask-box-image-outset" */
  void set maskBoxImageOutset(String value);

  /** Gets the value of "mask-box-image-repeat" */
  String get maskBoxImageRepeat();

  /** Sets the value of "mask-box-image-repeat" */
  void set maskBoxImageRepeat(String value);

  /** Gets the value of "mask-box-image-slice" */
  String get maskBoxImageSlice();

  /** Sets the value of "mask-box-image-slice" */
  void set maskBoxImageSlice(String value);

  /** Gets the value of "mask-box-image-source" */
  String get maskBoxImageSource();

  /** Sets the value of "mask-box-image-source" */
  void set maskBoxImageSource(String value);

  /** Gets the value of "mask-box-image-width" */
  String get maskBoxImageWidth();

  /** Sets the value of "mask-box-image-width" */
  void set maskBoxImageWidth(String value);

  /** Gets the value of "mask-clip" */
  String get maskClip();

  /** Sets the value of "mask-clip" */
  void set maskClip(String value);

  /** Gets the value of "mask-composite" */
  String get maskComposite();

  /** Sets the value of "mask-composite" */
  void set maskComposite(String value);

  /** Gets the value of "mask-image" */
  String get maskImage();

  /** Sets the value of "mask-image" */
  void set maskImage(String value);

  /** Gets the value of "mask-origin" */
  String get maskOrigin();

  /** Sets the value of "mask-origin" */
  void set maskOrigin(String value);

  /** Gets the value of "mask-position" */
  String get maskPosition();

  /** Sets the value of "mask-position" */
  void set maskPosition(String value);

  /** Gets the value of "mask-position-x" */
  String get maskPositionX();

  /** Sets the value of "mask-position-x" */
  void set maskPositionX(String value);

  /** Gets the value of "mask-position-y" */
  String get maskPositionY();

  /** Sets the value of "mask-position-y" */
  void set maskPositionY(String value);

  /** Gets the value of "mask-repeat" */
  String get maskRepeat();

  /** Sets the value of "mask-repeat" */
  void set maskRepeat(String value);

  /** Gets the value of "mask-repeat-x" */
  String get maskRepeatX();

  /** Sets the value of "mask-repeat-x" */
  void set maskRepeatX(String value);

  /** Gets the value of "mask-repeat-y" */
  String get maskRepeatY();

  /** Sets the value of "mask-repeat-y" */
  void set maskRepeatY(String value);

  /** Gets the value of "mask-size" */
  String get maskSize();

  /** Sets the value of "mask-size" */
  void set maskSize(String value);

  /** Gets the value of "match-nearest-mail-blockquote-color" */
  String get matchNearestMailBlockquoteColor();

  /** Sets the value of "match-nearest-mail-blockquote-color" */
  void set matchNearestMailBlockquoteColor(String value);

  /** Gets the value of "max-height" */
  String get maxHeight();

  /** Sets the value of "max-height" */
  void set maxHeight(String value);

  /** Gets the value of "max-logical-height" */
  String get maxLogicalHeight();

  /** Sets the value of "max-logical-height" */
  void set maxLogicalHeight(String value);

  /** Gets the value of "max-logical-width" */
  String get maxLogicalWidth();

  /** Sets the value of "max-logical-width" */
  void set maxLogicalWidth(String value);

  /** Gets the value of "max-width" */
  String get maxWidth();

  /** Sets the value of "max-width" */
  void set maxWidth(String value);

  /** Gets the value of "min-height" */
  String get minHeight();

  /** Sets the value of "min-height" */
  void set minHeight(String value);

  /** Gets the value of "min-logical-height" */
  String get minLogicalHeight();

  /** Sets the value of "min-logical-height" */
  void set minLogicalHeight(String value);

  /** Gets the value of "min-logical-width" */
  String get minLogicalWidth();

  /** Sets the value of "min-logical-width" */
  void set minLogicalWidth(String value);

  /** Gets the value of "min-width" */
  String get minWidth();

  /** Sets the value of "min-width" */
  void set minWidth(String value);

  /** Gets the value of "nbsp-mode" */
  String get nbspMode();

  /** Sets the value of "nbsp-mode" */
  void set nbspMode(String value);

  /** Gets the value of "opacity" */
  String get opacity();

  /** Sets the value of "opacity" */
  void set opacity(String value);

  /** Gets the value of "orphans" */
  String get orphans();

  /** Sets the value of "orphans" */
  void set orphans(String value);

  /** Gets the value of "outline" */
  String get outline();

  /** Sets the value of "outline" */
  void set outline(String value);

  /** Gets the value of "outline-color" */
  String get outlineColor();

  /** Sets the value of "outline-color" */
  void set outlineColor(String value);

  /** Gets the value of "outline-offset" */
  String get outlineOffset();

  /** Sets the value of "outline-offset" */
  void set outlineOffset(String value);

  /** Gets the value of "outline-style" */
  String get outlineStyle();

  /** Sets the value of "outline-style" */
  void set outlineStyle(String value);

  /** Gets the value of "outline-width" */
  String get outlineWidth();

  /** Sets the value of "outline-width" */
  void set outlineWidth(String value);

  /** Gets the value of "overflow" */
  String get overflow();

  /** Sets the value of "overflow" */
  void set overflow(String value);

  /** Gets the value of "overflow-x" */
  String get overflowX();

  /** Sets the value of "overflow-x" */
  void set overflowX(String value);

  /** Gets the value of "overflow-y" */
  String get overflowY();

  /** Sets the value of "overflow-y" */
  void set overflowY(String value);

  /** Gets the value of "padding" */
  String get padding();

  /** Sets the value of "padding" */
  void set padding(String value);

  /** Gets the value of "padding-after" */
  String get paddingAfter();

  /** Sets the value of "padding-after" */
  void set paddingAfter(String value);

  /** Gets the value of "padding-before" */
  String get paddingBefore();

  /** Sets the value of "padding-before" */
  void set paddingBefore(String value);

  /** Gets the value of "padding-bottom" */
  String get paddingBottom();

  /** Sets the value of "padding-bottom" */
  void set paddingBottom(String value);

  /** Gets the value of "padding-end" */
  String get paddingEnd();

  /** Sets the value of "padding-end" */
  void set paddingEnd(String value);

  /** Gets the value of "padding-left" */
  String get paddingLeft();

  /** Sets the value of "padding-left" */
  void set paddingLeft(String value);

  /** Gets the value of "padding-right" */
  String get paddingRight();

  /** Sets the value of "padding-right" */
  void set paddingRight(String value);

  /** Gets the value of "padding-start" */
  String get paddingStart();

  /** Sets the value of "padding-start" */
  void set paddingStart(String value);

  /** Gets the value of "padding-top" */
  String get paddingTop();

  /** Sets the value of "padding-top" */
  void set paddingTop(String value);

  /** Gets the value of "page" */
  String get page();

  /** Sets the value of "page" */
  void set page(String value);

  /** Gets the value of "page-break-after" */
  String get pageBreakAfter();

  /** Sets the value of "page-break-after" */
  void set pageBreakAfter(String value);

  /** Gets the value of "page-break-before" */
  String get pageBreakBefore();

  /** Sets the value of "page-break-before" */
  void set pageBreakBefore(String value);

  /** Gets the value of "page-break-inside" */
  String get pageBreakInside();

  /** Sets the value of "page-break-inside" */
  void set pageBreakInside(String value);

  /** Gets the value of "perspective" */
  String get perspective();

  /** Sets the value of "perspective" */
  void set perspective(String value);

  /** Gets the value of "perspective-origin" */
  String get perspectiveOrigin();

  /** Sets the value of "perspective-origin" */
  void set perspectiveOrigin(String value);

  /** Gets the value of "perspective-origin-x" */
  String get perspectiveOriginX();

  /** Sets the value of "perspective-origin-x" */
  void set perspectiveOriginX(String value);

  /** Gets the value of "perspective-origin-y" */
  String get perspectiveOriginY();

  /** Sets the value of "perspective-origin-y" */
  void set perspectiveOriginY(String value);

  /** Gets the value of "pointer-events" */
  String get pointerEvents();

  /** Sets the value of "pointer-events" */
  void set pointerEvents(String value);

  /** Gets the value of "position" */
  String get position();

  /** Sets the value of "position" */
  void set position(String value);

  /** Gets the value of "quotes" */
  String get quotes();

  /** Sets the value of "quotes" */
  void set quotes(String value);

  /** Gets the value of "region-break-after" */
  String get regionBreakAfter();

  /** Sets the value of "region-break-after" */
  void set regionBreakAfter(String value);

  /** Gets the value of "region-break-before" */
  String get regionBreakBefore();

  /** Sets the value of "region-break-before" */
  void set regionBreakBefore(String value);

  /** Gets the value of "region-break-inside" */
  String get regionBreakInside();

  /** Sets the value of "region-break-inside" */
  void set regionBreakInside(String value);

  /** Gets the value of "region-overflow" */
  String get regionOverflow();

  /** Sets the value of "region-overflow" */
  void set regionOverflow(String value);

  /** Gets the value of "resize" */
  String get resize();

  /** Sets the value of "resize" */
  void set resize(String value);

  /** Gets the value of "right" */
  String get right();

  /** Sets the value of "right" */
  void set right(String value);

  /** Gets the value of "rtl-ordering" */
  String get rtlOrdering();

  /** Sets the value of "rtl-ordering" */
  void set rtlOrdering(String value);

  /** Gets the value of "size" */
  String get size();

  /** Sets the value of "size" */
  void set size(String value);

  /** Gets the value of "speak" */
  String get speak();

  /** Sets the value of "speak" */
  void set speak(String value);

  /** Gets the value of "src" */
  String get src();

  /** Sets the value of "src" */
  void set src(String value);

  /** Gets the value of "table-layout" */
  String get tableLayout();

  /** Sets the value of "table-layout" */
  void set tableLayout(String value);

  /** Gets the value of "tap-highlight-color" */
  String get tapHighlightColor();

  /** Sets the value of "tap-highlight-color" */
  void set tapHighlightColor(String value);

  /** Gets the value of "text-align" */
  String get textAlign();

  /** Sets the value of "text-align" */
  void set textAlign(String value);

  /** Gets the value of "text-combine" */
  String get textCombine();

  /** Sets the value of "text-combine" */
  void set textCombine(String value);

  /** Gets the value of "text-decoration" */
  String get textDecoration();

  /** Sets the value of "text-decoration" */
  void set textDecoration(String value);

  /** Gets the value of "text-decorations-in-effect" */
  String get textDecorationsInEffect();

  /** Sets the value of "text-decorations-in-effect" */
  void set textDecorationsInEffect(String value);

  /** Gets the value of "text-emphasis" */
  String get textEmphasis();

  /** Sets the value of "text-emphasis" */
  void set textEmphasis(String value);

  /** Gets the value of "text-emphasis-color" */
  String get textEmphasisColor();

  /** Sets the value of "text-emphasis-color" */
  void set textEmphasisColor(String value);

  /** Gets the value of "text-emphasis-position" */
  String get textEmphasisPosition();

  /** Sets the value of "text-emphasis-position" */
  void set textEmphasisPosition(String value);

  /** Gets the value of "text-emphasis-style" */
  String get textEmphasisStyle();

  /** Sets the value of "text-emphasis-style" */
  void set textEmphasisStyle(String value);

  /** Gets the value of "text-fill-color" */
  String get textFillColor();

  /** Sets the value of "text-fill-color" */
  void set textFillColor(String value);

  /** Gets the value of "text-indent" */
  String get textIndent();

  /** Sets the value of "text-indent" */
  void set textIndent(String value);

  /** Gets the value of "text-line-through" */
  String get textLineThrough();

  /** Sets the value of "text-line-through" */
  void set textLineThrough(String value);

  /** Gets the value of "text-line-through-color" */
  String get textLineThroughColor();

  /** Sets the value of "text-line-through-color" */
  void set textLineThroughColor(String value);

  /** Gets the value of "text-line-through-mode" */
  String get textLineThroughMode();

  /** Sets the value of "text-line-through-mode" */
  void set textLineThroughMode(String value);

  /** Gets the value of "text-line-through-style" */
  String get textLineThroughStyle();

  /** Sets the value of "text-line-through-style" */
  void set textLineThroughStyle(String value);

  /** Gets the value of "text-line-through-width" */
  String get textLineThroughWidth();

  /** Sets the value of "text-line-through-width" */
  void set textLineThroughWidth(String value);

  /** Gets the value of "text-orientation" */
  String get textOrientation();

  /** Sets the value of "text-orientation" */
  void set textOrientation(String value);

  /** Gets the value of "text-overflow" */
  String get textOverflow();

  /** Sets the value of "text-overflow" */
  void set textOverflow(String value);

  /** Gets the value of "text-overline" */
  String get textOverline();

  /** Sets the value of "text-overline" */
  void set textOverline(String value);

  /** Gets the value of "text-overline-color" */
  String get textOverlineColor();

  /** Sets the value of "text-overline-color" */
  void set textOverlineColor(String value);

  /** Gets the value of "text-overline-mode" */
  String get textOverlineMode();

  /** Sets the value of "text-overline-mode" */
  void set textOverlineMode(String value);

  /** Gets the value of "text-overline-style" */
  String get textOverlineStyle();

  /** Sets the value of "text-overline-style" */
  void set textOverlineStyle(String value);

  /** Gets the value of "text-overline-width" */
  String get textOverlineWidth();

  /** Sets the value of "text-overline-width" */
  void set textOverlineWidth(String value);

  /** Gets the value of "text-rendering" */
  String get textRendering();

  /** Sets the value of "text-rendering" */
  void set textRendering(String value);

  /** Gets the value of "text-security" */
  String get textSecurity();

  /** Sets the value of "text-security" */
  void set textSecurity(String value);

  /** Gets the value of "text-shadow" */
  String get textShadow();

  /** Sets the value of "text-shadow" */
  void set textShadow(String value);

  /** Gets the value of "text-size-adjust" */
  String get textSizeAdjust();

  /** Sets the value of "text-size-adjust" */
  void set textSizeAdjust(String value);

  /** Gets the value of "text-stroke" */
  String get textStroke();

  /** Sets the value of "text-stroke" */
  void set textStroke(String value);

  /** Gets the value of "text-stroke-color" */
  String get textStrokeColor();

  /** Sets the value of "text-stroke-color" */
  void set textStrokeColor(String value);

  /** Gets the value of "text-stroke-width" */
  String get textStrokeWidth();

  /** Sets the value of "text-stroke-width" */
  void set textStrokeWidth(String value);

  /** Gets the value of "text-transform" */
  String get textTransform();

  /** Sets the value of "text-transform" */
  void set textTransform(String value);

  /** Gets the value of "text-underline" */
  String get textUnderline();

  /** Sets the value of "text-underline" */
  void set textUnderline(String value);

  /** Gets the value of "text-underline-color" */
  String get textUnderlineColor();

  /** Sets the value of "text-underline-color" */
  void set textUnderlineColor(String value);

  /** Gets the value of "text-underline-mode" */
  String get textUnderlineMode();

  /** Sets the value of "text-underline-mode" */
  void set textUnderlineMode(String value);

  /** Gets the value of "text-underline-style" */
  String get textUnderlineStyle();

  /** Sets the value of "text-underline-style" */
  void set textUnderlineStyle(String value);

  /** Gets the value of "text-underline-width" */
  String get textUnderlineWidth();

  /** Sets the value of "text-underline-width" */
  void set textUnderlineWidth(String value);

  /** Gets the value of "top" */
  String get top();

  /** Sets the value of "top" */
  void set top(String value);

  /** Gets the value of "transform" */
  String get transform();

  /** Sets the value of "transform" */
  void set transform(String value);

  /** Gets the value of "transform-origin" */
  String get transformOrigin();

  /** Sets the value of "transform-origin" */
  void set transformOrigin(String value);

  /** Gets the value of "transform-origin-x" */
  String get transformOriginX();

  /** Sets the value of "transform-origin-x" */
  void set transformOriginX(String value);

  /** Gets the value of "transform-origin-y" */
  String get transformOriginY();

  /** Sets the value of "transform-origin-y" */
  void set transformOriginY(String value);

  /** Gets the value of "transform-origin-z" */
  String get transformOriginZ();

  /** Sets the value of "transform-origin-z" */
  void set transformOriginZ(String value);

  /** Gets the value of "transform-style" */
  String get transformStyle();

  /** Sets the value of "transform-style" */
  void set transformStyle(String value);

  /** Gets the value of "transition" */
  String get transition();

  /** Sets the value of "transition" */
  void set transition(String value);

  /** Gets the value of "transition-delay" */
  String get transitionDelay();

  /** Sets the value of "transition-delay" */
  void set transitionDelay(String value);

  /** Gets the value of "transition-duration" */
  String get transitionDuration();

  /** Sets the value of "transition-duration" */
  void set transitionDuration(String value);

  /** Gets the value of "transition-property" */
  String get transitionProperty();

  /** Sets the value of "transition-property" */
  void set transitionProperty(String value);

  /** Gets the value of "transition-timing-function" */
  String get transitionTimingFunction();

  /** Sets the value of "transition-timing-function" */
  void set transitionTimingFunction(String value);

  /** Gets the value of "unicode-bidi" */
  String get unicodeBidi();

  /** Sets the value of "unicode-bidi" */
  void set unicodeBidi(String value);

  /** Gets the value of "unicode-range" */
  String get unicodeRange();

  /** Sets the value of "unicode-range" */
  void set unicodeRange(String value);

  /** Gets the value of "user-drag" */
  String get userDrag();

  /** Sets the value of "user-drag" */
  void set userDrag(String value);

  /** Gets the value of "user-modify" */
  String get userModify();

  /** Sets the value of "user-modify" */
  void set userModify(String value);

  /** Gets the value of "user-select" */
  String get userSelect();

  /** Sets the value of "user-select" */
  void set userSelect(String value);

  /** Gets the value of "vertical-align" */
  String get verticalAlign();

  /** Sets the value of "vertical-align" */
  void set verticalAlign(String value);

  /** Gets the value of "visibility" */
  String get visibility();

  /** Sets the value of "visibility" */
  void set visibility(String value);

  /** Gets the value of "white-space" */
  String get whiteSpace();

  /** Sets the value of "white-space" */
  void set whiteSpace(String value);

  /** Gets the value of "widows" */
  String get widows();

  /** Sets the value of "widows" */
  void set widows(String value);

  /** Gets the value of "width" */
  String get width();

  /** Sets the value of "width" */
  void set width(String value);

  /** Gets the value of "word-break" */
  String get wordBreak();

  /** Sets the value of "word-break" */
  void set wordBreak(String value);

  /** Gets the value of "word-spacing" */
  String get wordSpacing();

  /** Sets the value of "word-spacing" */
  void set wordSpacing(String value);

  /** Gets the value of "word-wrap" */
  String get wordWrap();

  /** Sets the value of "word-wrap" */
  void set wordWrap(String value);

  /** Gets the value of "wrap-shape" */
  String get wrapShape();

  /** Sets the value of "wrap-shape" */
  void set wrapShape(String value);

  /** Gets the value of "writing-mode" */
  String get writingMode();

  /** Sets the value of "writing-mode" */
  void set writingMode(String value);

  /** Gets the value of "z-index" */
  String get zIndex();

  /** Sets the value of "z-index" */
  void set zIndex(String value);

  /** Gets the value of "zoom" */
  String get zoom();

  /** Sets the value of "zoom" */
  void set zoom(String value);

}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface CustomEvent extends Event factory CustomEventWrappingImplementation {

  CustomEvent(String type, [bool canBubble, bool cancelable, Object detail]);

  String get detail();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DeviceMotionEvent extends Event factory DeviceMotionEventWrappingImplementation {

  // TODO(nweiz): Add more arguments to the constructor when we support
  // DeviceMotionEvent more thoroughly.
  DeviceMotionEvent(String type, [bool canBubble, bool cancelable]);

  num get interval();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DeviceOrientationEvent extends Event factory DeviceOrientationEventWrappingImplementation {

  DeviceOrientationEvent(String type, double alpha, double beta, double gamma,
      [bool canBubble, bool cancelable]);

  num get alpha();

  num get beta();

  num get gamma();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DocumentEvents extends ElementEvents {
  EventListenerList get readyStateChange();
  EventListenerList get selectionChange();
  EventListenerList get contentLoaded();
}

// TODO(jacobr): add DocumentFragment ctor
// add something smarted for document.domain
interface Document extends Element /*, common.NodeSelector */ {

  // TODO(jacobr): remove.
  Event createEvent([String eventType]);

  Element get activeElement();

  // TODO(jacobr): add
  // Map<String, Class> tags;

  Element get body();

  void set body(Element value);

  String get charset();

  void set charset(String value);

  // FIXME(slightlyoff): FIX COOKIES, MMM...COOKIES. ME WANT COOKIES!!
  //                     Map<String, CookieList> cookies
  //                     Map<String, Cookie> CookieList
  String get cookie();

  void set cookie(String value);

  Window get window();

  String get domain();

  HeadElement get head();

  String get lastModified();

  // TODO(jacobr): remove once on.contentLoaded is changed to return a Future.
  String get readyState();

  String get referrer();

  StyleSheetList get styleSheets();

  // TODO(jacobr): should this be removed? Users could write document.query("title").text instead.
  String get title();

  void set title(String value);

  bool get webkitHidden();

  String get webkitVisibilityState();

  Future<Range> caretRangeFromPoint([int x, int y]);

  // TODO(jacobr): remove.
  Element createElement([String tagName]);

  Future<Element> elementFromPoint([int x, int y]);

  bool execCommand([String command, bool userInterface, String value]);

  // TODO(jacobr): remove once a new API is specified
  CanvasRenderingContext getCSSCanvasContext(String contextId, String name,
                                             int width, int height);

  bool queryCommandEnabled([String command]);

  bool queryCommandIndeterm([String command]);

  bool queryCommandState([String command]);

  bool queryCommandSupported([String command]);

  String queryCommandValue([String command]);

  String get manifest();

  void set manifest(String value);

  DocumentEvents get on();

  Future<ElementRect> get rect();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DocumentFragment extends Element factory DocumentFragmentWrappingImplementation {
 
  DocumentFragment();

  DocumentFragment.html(String html);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

interface DOMApplicationCache extends EventTarget {

  static final int CHECKING = 2;

  static final int DOWNLOADING = 3;

  static final int IDLE = 1;

  static final int OBSOLETE = 5;

  static final int UNCACHED = 0;

  static final int UPDATEREADY = 4;

  int get status();

  void swapCache();

  void update();

  DOMApplicationCacheEvents get on();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface ElementList extends List<Element> {
  // TODO(jacobr): add element batch manipulation methods.
  Element get first();
  // TODO(jacobr): add insertAt
}

class DeferredElementRect {
  // TODO(jacobr)
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
  EventListenerList get dblClick();
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
  EventListenerList get fullscreenChange();
}

/**
 * All your element measurement needs in one place
 */
interface ElementRect {
  ClientRect get client();
  ClientRect get offset();
  ClientRect get scroll();
  ClientRect get bounding();
  List<ClientRect> get clientRects();
}


interface Element extends Node /*, common.NodeSelector, common.ElementTraversal */
    factory ElementWrappingImplementation {

  Element.html(String html);
  Element.tag(String tag);

  Map<String, String> get attributes();
  void set attributes(Map<String, String> value);

  ElementList get elements();

  // TODO: The type of value should be Collection<Element>. See http://b/5392897
  void set elements(value);

  Set<String> get classes();

  // TODO: The type of value should be Collection<String>. See http://b/5392897
  void set classes(value);

  Map<String, String> get dataAttributes();
  void set dataAttributes(Map<String, String> value);

  String get contentEditable();

  void set contentEditable(String value);

  String get dir();

  void set dir(String value);

  bool get draggable();

  void set draggable(bool value);

  Element get firstElementChild();

  bool get hidden();

  void set hidden(bool value);

  String get id();

  void set id(String value);

  String get innerHTML();

  void set innerHTML(String value);

  bool get isContentEditable();

  String get lang();

  void set lang(String value);

  Element get lastElementChild();

  Element get nextElementSibling();

  Element get offsetParent();

  String get outerHTML();

  Element get previousElementSibling();

  void set scrollLeft(int value);

  void set scrollTop(int value);

  bool get spellcheck();

  void set spellcheck(bool value);

  CSSStyleDeclaration get style();

  int get tabIndex();

  void set tabIndex(int value);

  String get tagName();

  String get title();

  void set title(String value);

  String get webkitdropzone();

  void set webkitdropzone(String value);

  void blur();

  void focus();

  Element insertAdjacentElement([String where, Element element]);

  void insertAdjacentHTML([String position_OR_where, String text]);

  void insertAdjacentText([String where, String text]);

  Element query(String selectors);

  ElementList queryAll(String selectors);

  Element get parent();

  void scrollByLines([int lines]);

  void scrollByPages([int pages]);

  void scrollIntoView([bool centerIfNeeded]);

  bool matchesSelector([String selectors]);

  Future<ElementRect> get rect();

  Future<CSSStyleDeclaration> get computedStyle();

  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement);

  ElementEvents get on();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface ErrorEvent extends Event factory ErrorEventWrappingImplementation {

  ErrorEvent(String type, String message, String filename, int lineNo,
      [bool canBubble, bool cancelable]);

  String get filename();

  int get lineno();

  String get message();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Event factory EventWrappingImplementation {

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

  // In JS, canBubble and cancelable are technically required parameters to
  // init*Event. In practice, though, if they aren't provided they simply
  // default to false (since that's Boolean(undefined)).
  //
  // Contrary to JS, we default canBubble and cancelable to true, since that's
  // what people want most of the time anyway.
  Event(String type, [bool canBubble, bool cancelable]);

  bool get bubbles();

  bool get cancelBubble();

  void set cancelBubble(bool value);

  bool get cancelable();

  EventTarget get currentTarget();

  bool get defaultPrevented();

  int get eventPhase();

  bool get returnValue();

  void set returnValue(bool value);

  EventTarget get srcElement();

  EventTarget get target();

  int get timeStamp();

  String get type();

  void preventDefault();

  void stopImmediatePropagation();

  void stopPropagation();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void EventListener(Event event);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface EventSourceEvents extends Events {
  EventListenerList get error();
  EventListenerList get message();
  EventListenerList get open();
}

interface EventSource extends EventTarget {

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String get URL();

  int get readyState();

  void close();

  EventSourceEvents get on();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface EventListenerList {
  EventListenerList add(EventListener handler, [bool useCapture]);

  EventListenerList remove(EventListener handler, [bool useCapture]);

  bool dispatch(Event evt);
}

interface Events {
  EventListenerList operator [](String type);
}

interface EventTarget {
  Events get on();
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var secretWindow;
var secretDocument;

Window get window() {
  if (secretWindow === null) {
    LevelDom.initialize(dom.window);
  }
  return secretWindow;
}

Document get document() {
  if (secretWindow === null) {
    LevelDom.initialize(dom.window);
  }
  return secretDocument;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface HashChangeEvent extends Event factory HashChangeEventWrappingImplementation {

  HashChangeEvent(String type, String oldURL, String newURL, [bool canBubble,
      bool cancelable]);

  String get newURL();

  String get oldURL();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface KeyboardEvent extends UIEvent factory KeyboardEventWrappingImplementation {

  static final int KEY_LOCATION_LEFT = 0x01;

  static final int KEY_LOCATION_NUMPAD = 0x03;

  static final int KEY_LOCATION_RIGHT = 0x02;

  static final int KEY_LOCATION_STANDARD = 0x00;

  KeyboardEvent(String type, Window view, String keyIdentifier, int keyLocation,
      [bool canBubble, bool cancelable, bool ctrlKey, bool altKey,
      bool shiftKey, bool metaKey, bool altGraphKey]);

  bool get altGraphKey();

  bool get altKey();

  bool get ctrlKey();

  String get keyIdentifier();

  int get keyLocation();

  bool get metaKey();

  bool get shiftKey();

  bool getModifierState(String keyIdentifierArg);
}

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

interface MessageEvent extends Event factory MessageEventWrappingImplementation {

  MessageEvent(String type, String data, String origin, String lastEventId,
      Window source, [bool canBubble, bool cancelable, MessagePort port]);

  String get data();

  String get lastEventId();

  MessagePort get messagePort();

  String get origin();

  Window get source();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface MessagePort extends EventTarget {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface MouseEvent extends UIEvent factory MouseEventWrappingImplementation {

  MouseEvent(String type, Window view, int detail, int screenX, int screenY,
      int clientX, int clientY, int button, [bool canBubble, bool cancelable,
      bool ctrlKey, bool altKey, bool shiftKey, bool metaKey,
      EventTarget relatedTarget]);

  bool get altKey();

  int get button();

  int get clientX();

  int get clientY();

  bool get ctrlKey();

  Node get fromElement();

  bool get metaKey();

  int get offsetX();

  int get offsetY();

  EventTarget get relatedTarget();

  int get screenX();

  int get screenY();

  bool get shiftKey();

  Node get toElement();

  int get x();

  int get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface MutationEvent extends Event factory MutationEventWrappingImplementation {

  MutationEvent(String type, Node relatedNode, String prevValue,
      String newValue, String attrName, int attrChange, [bool canBubble,
      bool cancelable]);

  static final int ADDITION = 2;

  static final int MODIFICATION = 1;

  static final int REMOVAL = 3;

  int get attrChange();

  String get attrName();

  String get newValue();

  String get prevValue();

  Node get relatedNode();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): stop extending eventTarget.
interface Node extends EventTarget {

  NodeList get nodes();

  // TODO: The type of value should be Collection<Node>. See http://b/5392897
  void set nodes(value);

  Node get nextNode();

  Document get document();

  Node get parent();

  Node get previousNode();

  String get text();

  void set text(String value);

  Node replaceWith(Node otherNode);

  Node remove();

  bool contains(Node otherNode);

  // TODO(jacobr): remove when/if Array supports a method similar to
  // insertBefore or we switch NodeList to implement LinkedList rather than
  // array.
  Node insertBefore(Node newChild, Node refChild);

  Node clone(bool deep);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface NodeList extends List<Node> {
  Node get first();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Notification extends EventTarget {

  String get dir();

  void set dir(String value);

  EventListener get onclick();

  void set onclick(EventListener value);

  EventListener get onclose();

  void set onclose(EventListener value);

  EventListener get ondisplay();

  void set ondisplay(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  String get replaceId();

  void set replaceId(String value);

  void cancel();

  void show();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface OverflowEvent extends Event factory OverflowEventWrappingImplementation {

  OverflowEvent(int orient, bool horizontalOverflow, bool verticalOverflow);

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

interface PageTransitionEvent extends Event factory PageTransitionEventWrappingImplementation {

  PageTransitionEvent(String type, [bool canBubble, bool cancelable,
      bool persisted]);

  bool get persisted();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface PopStateEvent extends Event factory PopStateEventWrappingImplementation {

  PopStateEvent(String type, Object state, [bool canBubble, bool cancelable]);

  String get state();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface ProgressEvent extends Event factory ProgressEventWrappingImplementation {

  ProgressEvent(String type, int loaded, [bool canBubble, bool cancelable,
      bool lengthComputable, int total]);

  bool get lengthComputable();

  int get loaded();

  int get total();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef bool RequestAnimationFrameCallback(int time);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface SharedWorker extends AbstractWorker {

  MessagePort get port();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface StorageEvent extends Event factory StorageEventWrappingImplementation {

  StorageEvent(String type, String key, String url, Storage storageArea,
      [bool canBubble, bool cancelable, String oldValue, String newValue]);

  String get key();

  String get newValue();

  String get oldValue();

  Storage get storageArea();

  String get url();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Text extends CharacterData factory TextWrappingImplementation {
  
  Text(String content);

  String get wholeText();

  Text replaceWholeText([String content]);

  Text splitText([int offset]);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface TextEvent extends UIEvent factory TextEventWrappingImplementation {

  TextEvent(String type, Window view, String data, [bool canBubble,
      bool cancelable]);

  String get data();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void TimeoutHandler();
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface TouchEvent extends UIEvent factory TouchEventWrappingImplementation {

  TouchEvent(TouchList touches, TouchList targetTouches,
      TouchList changedTouches, String type, Window view, int screenX,
      int screenY, int clientX, int clientY, [bool ctrlKey, bool altKey,
      bool shiftKey, bool metaKey]);

  bool get altKey();

  TouchList get changedTouches();

  bool get ctrlKey();

  bool get metaKey();

  bool get shiftKey();

  TouchList get targetTouches();

  TouchList get touches();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface TransitionEvent extends Event factory TransitionEventWrappingImplementation {

  TransitionEvent(String type, String propertyName, double elapsedTime,
      [bool canBubble, bool cancelable]);

  num get elapsedTime();

  String get propertyName();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface UIEvent extends Event factory UIEventWrappingImplementation {

  UIEvent(String type, Window view, int detail, [bool canBubble,
      bool cancelable]);

  int get charCode();

  int get detail();

  int get keyCode();

  int get layerX();

  int get layerY();

  int get pageX();

  int get pageY();

  Window get view();

  int get which();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface WebSocket extends EventTarget {

  static final int CLOSED = 3;

  static final int CLOSING = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String get URL();

  String get binaryType();

  void set binaryType(String value);

  int get bufferedAmount();

  EventListener get onclose();

  void set onclose(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onmessage();

  void set onmessage(EventListener value);

  EventListener get onopen();

  void set onopen(EventListener value);

  String get protocol();

  int get readyState();

  void close();

  bool send(String data);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface WheelEvent extends UIEvent factory WheelEventWrappingImplementation {

  WheelEvent(int deltaX, int deltaY, Window view, int screenX, int screenY,
      int clientX, int clientY, [bool ctrlKey, bool altKey, bool shiftKey,
      bool metaKey]);

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

  int get wheelDelta();

  int get wheelDeltaX();

  int get wheelDeltaY();

  int get x();

  int get y();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface WindowEvents extends Events {
  EventListenerList get abort();
  EventListenerList get beforeUnload();
  EventListenerList get blur();
  EventListenerList get canPlay();
  EventListenerList get canPlayThrough();
  EventListenerList get change();
  EventListenerList get click();
  EventListenerList get contextMenu();
  EventListenerList get dblClick();
  EventListenerList get deviceMotion();
  EventListenerList get deviceOrientation();
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
  EventListenerList get loadedData();
  EventListenerList get loadedMetaData();
  EventListenerList get loadStart();
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
  EventListenerList get unLoad();
  EventListenerList get volumeChange();
  EventListenerList get waiting();
  EventListenerList get animationEnd();
  EventListenerList get animationIteration();
  EventListenerList get animationStart();
  EventListenerList get transitionEnd();
  EventListenerList get contentLoaded();
}

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

  num get devicePixelRatio();

  void set devicePixelRatio(num value);

  Document get document();

  Event get event();

  void set event(Event value);

  Element get frameElement();

  Window get frames();

  void set frames(Window value);

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

  Window get opener();

  void set opener(Window value);

  int get outerHeight();

  void set outerHeight(int value);

  int get outerWidth();

  void set outerWidth(int value);

  int get pageXOffset();

  int get pageYOffset();

  Window get parent();

  void set parent(Window value);

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

  Window get self();

  void set self(Window value);

  Storage get sessionStorage();

  String get status();

  void set status(String value);

  BarInfo get statusbar();

  void set statusbar(BarInfo value);

  StyleMedia get styleMedia();

  BarInfo get toolbar();

  void set toolbar(BarInfo value);

  Window get top();

  void set top(Window value);

  NotificationCenter get webkitNotifications();

  void alert([String message]);

  String atob([String string]);

  void blur();

  String btoa([String string]);

  void captureEvents();

  void clearInterval([int handle]);

  void clearTimeout([int handle]);

  void close();

  bool confirm([String message]);

  FileReader createFileReader();

  bool find([String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog]);

  void focus();

  DOMSelection getSelection();

  MediaQueryList matchMedia(String query);

  void moveBy(num x, num y);

  void moveTo(num x, num y);

  Window open(String url, String target, [String features]);

  void postMessage(String message, [var messagePort, String targetOrigin]);

  void print();

  String prompt([String message, String defaultValue]);

  void releaseEvents();

  void resizeBy(num x, num y);

  void resizeTo(num width, num height);

  void scroll(int x, int y);

  void scrollBy(int x, int y);

  void scrollTo(int x, int y);

  int setInterval(TimeoutHandler handler, int timeout);

  int setTimeout(TimeoutHandler handler, int timeout);

  Object showModalDialog(String url, [Object dialogArgs, String featureArgs]);

  void stop();

  void webkitCancelRequestAnimationFrame(int id);

  // TODO(jacobr): make these return Future<Point>.
  Point webkitConvertPointFromNodeToPage([Node node, Point p]);

  Point webkitConvertPointFromPageToNode([Node node, Point p]);

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, [Element element]);

  /**
   * Executes a [callback] after the next batch of browser layout measurements
   * has completed or would have completed if any browser layout measurements
   * had been scheduled.
   */
  void requestLayoutFrame(TimeoutHandler callback);

  // Window open(String url, String target, WindowSpec features);

  WindowEvents get on();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface WorkerEvents extends AbstractWorkerEvents {  
  EventListenerList get message();
}

interface Worker extends AbstractWorker {

  void postMessage(String message, [MessagePort messagePort]);

  void terminate();

  WorkerEvents get on();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface XMLHttpRequestEvents extends Events {
  EventListenerList get abort();
  EventListenerList get error();
  EventListenerList get load();
  EventListenerList get loadStart();
  EventListenerList get progress();
  EventListenerList get readyStateChange();
}

interface XMLHttpRequest extends EventTarget factory XMLHttpRequestWrappingImplementation {
  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  XMLHttpRequest();

  // TODO(rnystrom): This name should just be "get" which is valid in Dart, but
  // not correctly implemented yet. (b/4970173)
  XMLHttpRequest.getTEMPNAME(String url, onSuccess(XMLHttpRequest request));

  int get readyState();

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

  String getAllResponseHeaders();

  String getResponseHeader(String header);

  void open(String method, String url, bool async, [String user, String password]);

  void overrideMimeType(String mime);

  void send([String data]);

  void setRequestHeader(String header, String value);

  XMLHttpRequestEvents get on();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface XMLHttpRequestProgressEvent extends ProgressEvent factory XMLHttpRequestProgressEventWrappingImplementation {

  XMLHttpRequestProgressEvent(String type, int loaded, [bool canBubble,
      bool cancelable, bool lengthComputable, int total]);

  int get position();

  int get totalSize();
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface XMLHttpRequestUploadEvents extends Events {
  EventListenerList get abort();
  EventListenerList get error();
  EventListenerList get load();
  EventListenerList get loadStart();
  EventListenerList get progress();
}

interface XMLHttpRequestUpload extends EventTarget {
  XMLHttpRequestUploadEvents get on();
}
