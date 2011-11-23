#library('html');

#import('dart:dom', prefix:'dom');
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

interface CSSMatrix factory _CSSMatrixFactoryProvider {

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

interface FileReader factory _FileReaderFactoryProvider {

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

interface Point factory _PointFactoryProvider {

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

// WARNING: Do not edit - generated code.

class AnchorElementWrappingImplementation extends ElementWrappingImplementation implements AnchorElement {
  AnchorElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  String get charset() { return _ptr.charset; }

  void set charset(String value) { _ptr.charset = value; }

  String get coords() { return _ptr.coords; }

  void set coords(String value) { _ptr.coords = value; }

  String get download() { return _ptr.download; }

  void set download(String value) { _ptr.download = value; }

  String get hash() { return _ptr.hash; }

  void set hash(String value) { _ptr.hash = value; }

  String get host() { return _ptr.host; }

  void set host(String value) { _ptr.host = value; }

  String get hostname() { return _ptr.hostname; }

  void set hostname(String value) { _ptr.hostname = value; }

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  String get hreflang() { return _ptr.hreflang; }

  void set hreflang(String value) { _ptr.hreflang = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get origin() { return _ptr.origin; }

  String get pathname() { return _ptr.pathname; }

  void set pathname(String value) { _ptr.pathname = value; }

  String get ping() { return _ptr.ping; }

  void set ping(String value) { _ptr.ping = value; }

  String get port() { return _ptr.port; }

  void set port(String value) { _ptr.port = value; }

  String get protocol() { return _ptr.protocol; }

  void set protocol(String value) { _ptr.protocol = value; }

  String get rel() { return _ptr.rel; }

  void set rel(String value) { _ptr.rel = value; }

  String get rev() { return _ptr.rev; }

  void set rev(String value) { _ptr.rev = value; }

  String get search() { return _ptr.search; }

  void set search(String value) { _ptr.search = value; }

  String get shape() { return _ptr.shape; }

  void set shape(String value) { _ptr.shape = value; }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }

  String get text() { return _ptr.text; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String getParameter(String name) {
    return _ptr.getParameter(name);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AnimationListWrappingImplementation extends DOMWrapperBase implements AnimationList {
  AnimationListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Animation item(int index) {
    return LevelDom.wrapAnimation(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AnimationWrappingImplementation extends DOMWrapperBase implements Animation {
  AnimationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get delay() { return _ptr.delay; }

  int get direction() { return _ptr.direction; }

  num get duration() { return _ptr.duration; }

  num get elapsedTime() { return _ptr.elapsedTime; }

  void set elapsedTime(num value) { _ptr.elapsedTime = value; }

  bool get ended() { return _ptr.ended; }

  int get fillMode() { return _ptr.fillMode; }

  int get iterationCount() { return _ptr.iterationCount; }

  String get name() { return _ptr.name; }

  bool get paused() { return _ptr.paused; }

  void pause() {
    _ptr.pause();
    return;
  }

  void play() {
    _ptr.play();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AreaElementWrappingImplementation extends ElementWrappingImplementation implements AreaElement {
  AreaElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  String get alt() { return _ptr.alt; }

  void set alt(String value) { _ptr.alt = value; }

  String get coords() { return _ptr.coords; }

  void set coords(String value) { _ptr.coords = value; }

  String get hash() { return _ptr.hash; }

  String get host() { return _ptr.host; }

  String get hostname() { return _ptr.hostname; }

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  bool get noHref() { return _ptr.noHref; }

  void set noHref(bool value) { _ptr.noHref = value; }

  String get pathname() { return _ptr.pathname; }

  String get ping() { return _ptr.ping; }

  void set ping(String value) { _ptr.ping = value; }

  String get port() { return _ptr.port; }

  String get protocol() { return _ptr.protocol; }

  String get search() { return _ptr.search; }

  String get shape() { return _ptr.shape; }

  void set shape(String value) { _ptr.shape = value; }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ArrayBufferViewWrappingImplementation extends DOMWrapperBase implements ArrayBufferView {
  ArrayBufferViewWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ArrayBuffer get buffer() { return LevelDom.wrapArrayBuffer(_ptr.buffer); }

  int get byteLength() { return _ptr.byteLength; }

  int get byteOffset() { return _ptr.byteOffset; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ArrayBufferWrappingImplementation extends DOMWrapperBase implements ArrayBuffer {
  ArrayBufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get byteLength() { return _ptr.byteLength; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioElementWrappingImplementation extends MediaElementWrappingImplementation implements AudioElement {
  AudioElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BRElementWrappingImplementation extends ElementWrappingImplementation implements BRElement {
  BRElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get clear() { return _ptr.clear; }

  void set clear(String value) { _ptr.clear = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BarInfoWrappingImplementation extends DOMWrapperBase implements BarInfo {
  BarInfoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get visible() { return _ptr.visible; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BaseElementWrappingImplementation extends ElementWrappingImplementation implements BaseElement {
  BaseElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BlobBuilderWrappingImplementation extends DOMWrapperBase implements BlobBuilder {
  BlobBuilderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void append(var blob_OR_value, [String endings = null]) {
    if (blob_OR_value is Blob) {
      if (endings === null) {
        _ptr.append(LevelDom.unwrap(blob_OR_value));
        return;
      }
    } else {
      if (blob_OR_value is String) {
        if (endings === null) {
          _ptr.append(LevelDom.unwrap(blob_OR_value));
          return;
        } else {
          _ptr.append(LevelDom.unwrap(blob_OR_value), endings);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  Blob getBlob([String contentType = null]) {
    if (contentType === null) {
      return LevelDom.wrapBlob(_ptr.getBlob());
    } else {
      return LevelDom.wrapBlob(_ptr.getBlob(contentType));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BlobWrappingImplementation extends DOMWrapperBase implements Blob {
  BlobWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get size() { return _ptr.size; }

  String get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ButtonElementWrappingImplementation extends ElementWrappingImplementation implements ButtonElement {
  ButtonElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get formAction() { return _ptr.formAction; }

  void set formAction(String value) { _ptr.formAction = value; }

  String get formEnctype() { return _ptr.formEnctype; }

  void set formEnctype(String value) { _ptr.formEnctype = value; }

  String get formMethod() { return _ptr.formMethod; }

  void set formMethod(String value) { _ptr.formMethod = value; }

  bool get formNoValidate() { return _ptr.formNoValidate; }

  void set formNoValidate(bool value) { _ptr.formNoValidate = value; }

  String get formTarget() { return _ptr.formTarget; }

  void set formTarget(String value) { _ptr.formTarget = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void click() {
    _ptr.click();
    return;
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CDATASectionWrappingImplementation extends TextWrappingImplementation implements CDATASection {
  CDATASectionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSCharsetRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSCharsetRule {
  CSSCharsetRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get encoding() { return _ptr.encoding; }

  void set encoding(String value) { _ptr.encoding = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSFontFaceRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSFontFaceRule {
  CSSFontFaceRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSImportRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSImportRule {
  CSSImportRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get href() { return _ptr.href; }

  MediaList get media() { return LevelDom.wrapMediaList(_ptr.media); }

  CSSStyleSheet get styleSheet() { return LevelDom.wrapCSSStyleSheet(_ptr.styleSheet); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSKeyframeRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSKeyframeRule {
  CSSKeyframeRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get keyText() { return _ptr.keyText; }

  void set keyText(String value) { _ptr.keyText = value; }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSKeyframesRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSKeyframesRule {
  CSSKeyframesRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSRuleList get cssRules() { return LevelDom.wrapCSSRuleList(_ptr.cssRules); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  void deleteRule(String key) {
    _ptr.deleteRule(key);
    return;
  }

  CSSKeyframeRule findRule(String key) {
    return LevelDom.wrapCSSKeyframeRule(_ptr.findRule(key));
  }

  void insertRule(String rule) {
    _ptr.insertRule(rule);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSMatrixWrappingImplementation extends DOMWrapperBase implements CSSMatrix {
  CSSMatrixWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get a() { return _ptr.a; }

  void set a(num value) { _ptr.a = value; }

  num get b() { return _ptr.b; }

  void set b(num value) { _ptr.b = value; }

  num get c() { return _ptr.c; }

  void set c(num value) { _ptr.c = value; }

  num get d() { return _ptr.d; }

  void set d(num value) { _ptr.d = value; }

  num get e() { return _ptr.e; }

  void set e(num value) { _ptr.e = value; }

  num get f() { return _ptr.f; }

  void set f(num value) { _ptr.f = value; }

  num get m11() { return _ptr.m11; }

  void set m11(num value) { _ptr.m11 = value; }

  num get m12() { return _ptr.m12; }

  void set m12(num value) { _ptr.m12 = value; }

  num get m13() { return _ptr.m13; }

  void set m13(num value) { _ptr.m13 = value; }

  num get m14() { return _ptr.m14; }

  void set m14(num value) { _ptr.m14 = value; }

  num get m21() { return _ptr.m21; }

  void set m21(num value) { _ptr.m21 = value; }

  num get m22() { return _ptr.m22; }

  void set m22(num value) { _ptr.m22 = value; }

  num get m23() { return _ptr.m23; }

  void set m23(num value) { _ptr.m23 = value; }

  num get m24() { return _ptr.m24; }

  void set m24(num value) { _ptr.m24 = value; }

  num get m31() { return _ptr.m31; }

  void set m31(num value) { _ptr.m31 = value; }

  num get m32() { return _ptr.m32; }

  void set m32(num value) { _ptr.m32 = value; }

  num get m33() { return _ptr.m33; }

  void set m33(num value) { _ptr.m33 = value; }

  num get m34() { return _ptr.m34; }

  void set m34(num value) { _ptr.m34 = value; }

  num get m41() { return _ptr.m41; }

  void set m41(num value) { _ptr.m41 = value; }

  num get m42() { return _ptr.m42; }

  void set m42(num value) { _ptr.m42 = value; }

  num get m43() { return _ptr.m43; }

  void set m43(num value) { _ptr.m43 = value; }

  num get m44() { return _ptr.m44; }

  void set m44(num value) { _ptr.m44 = value; }

  CSSMatrix inverse() {
    return LevelDom.wrapCSSMatrix(_ptr.inverse());
  }

  CSSMatrix multiply(CSSMatrix secondMatrix) {
    return LevelDom.wrapCSSMatrix(_ptr.multiply(LevelDom.unwrap(secondMatrix)));
  }

  CSSMatrix rotate(num rotX, num rotY, num rotZ) {
    return LevelDom.wrapCSSMatrix(_ptr.rotate(rotX, rotY, rotZ));
  }

  CSSMatrix rotateAxisAngle(num x, num y, num z, num angle) {
    return LevelDom.wrapCSSMatrix(_ptr.rotateAxisAngle(x, y, z, angle));
  }

  CSSMatrix scale(num scaleX, num scaleY, num scaleZ) {
    return LevelDom.wrapCSSMatrix(_ptr.scale(scaleX, scaleY, scaleZ));
  }

  void setMatrixValue(String string) {
    _ptr.setMatrixValue(string);
    return;
  }

  CSSMatrix skewX(num angle) {
    return LevelDom.wrapCSSMatrix(_ptr.skewX(angle));
  }

  CSSMatrix skewY(num angle) {
    return LevelDom.wrapCSSMatrix(_ptr.skewY(angle));
  }

  String toString() {
    return _ptr.toString();
  }

  CSSMatrix translate(num x, num y, num z) {
    return LevelDom.wrapCSSMatrix(_ptr.translate(x, y, z));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSMediaRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSMediaRule {
  CSSMediaRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSRuleList get cssRules() { return LevelDom.wrapCSSRuleList(_ptr.cssRules); }

  MediaList get media() { return LevelDom.wrapMediaList(_ptr.media); }

  void deleteRule(int index) {
    _ptr.deleteRule(index);
    return;
  }

  int insertRule(String rule, int index) {
    return _ptr.insertRule(rule, index);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSPageRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSPageRule {
  CSSPageRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get selectorText() { return _ptr.selectorText; }

  void set selectorText(String value) { _ptr.selectorText = value; }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSPrimitiveValueWrappingImplementation extends CSSValueWrappingImplementation implements CSSPrimitiveValue {
  CSSPrimitiveValueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get primitiveType() { return _ptr.primitiveType; }

  Counter getCounterValue() {
    return LevelDom.wrapCounter(_ptr.getCounterValue());
  }

  num getFloatValue(int unitType) {
    return _ptr.getFloatValue(unitType);
  }

  RGBColor getRGBColorValue() {
    return LevelDom.wrapRGBColor(_ptr.getRGBColorValue());
  }

  Rect getRectValue() {
    return LevelDom.wrapRect(_ptr.getRectValue());
  }

  String getStringValue() {
    return _ptr.getStringValue();
  }

  void setFloatValue(int unitType, num floatValue) {
    _ptr.setFloatValue(unitType, floatValue);
    return;
  }

  void setStringValue(int stringType, String stringValue) {
    _ptr.setStringValue(stringType, stringValue);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSRuleListWrappingImplementation extends DOMWrapperBase implements CSSRuleList {
  CSSRuleListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  CSSRule item(int index) {
    return LevelDom.wrapCSSRule(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSRuleWrappingImplementation extends DOMWrapperBase implements CSSRule {
  CSSRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get cssText() { return _ptr.cssText; }

  void set cssText(String value) { _ptr.cssText = value; }

  CSSRule get parentRule() { return LevelDom.wrapCSSRule(_ptr.parentRule); }

  CSSStyleSheet get parentStyleSheet() { return LevelDom.wrapCSSStyleSheet(_ptr.parentStyleSheet); }

  int get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSStyleRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSStyleRule {
  CSSStyleRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get selectorText() { return _ptr.selectorText; }

  void set selectorText(String value) { _ptr.selectorText = value; }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSStyleSheetWrappingImplementation extends StyleSheetWrappingImplementation implements CSSStyleSheet {
  CSSStyleSheetWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSRuleList get cssRules() { return LevelDom.wrapCSSRuleList(_ptr.cssRules); }

  CSSRule get ownerRule() { return LevelDom.wrapCSSRule(_ptr.ownerRule); }

  CSSRuleList get rules() { return LevelDom.wrapCSSRuleList(_ptr.rules); }

  int addRule(String selector, String style, [int index = null]) {
    if (index === null) {
      return _ptr.addRule(selector, style);
    } else {
      return _ptr.addRule(selector, style, index);
    }
  }

  void deleteRule(int index) {
    _ptr.deleteRule(index);
    return;
  }

  int insertRule(String rule, int index) {
    return _ptr.insertRule(rule, index);
  }

  void removeRule(int index) {
    _ptr.removeRule(index);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSTransformValueWrappingImplementation extends CSSValueListWrappingImplementation implements CSSTransformValue {
  CSSTransformValueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get operationType() { return _ptr.operationType; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSUnknownRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSUnknownRule {
  CSSUnknownRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSValueListWrappingImplementation extends CSSValueWrappingImplementation implements CSSValueList {
  CSSValueListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  CSSValue item(int index) {
    return LevelDom.wrapCSSValue(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSValueWrappingImplementation extends DOMWrapperBase implements CSSValue {
  CSSValueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get cssText() { return _ptr.cssText; }

  void set cssText(String value) { _ptr.cssText = value; }

  int get cssValueType() { return _ptr.cssValueType; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasElementWrappingImplementation extends ElementWrappingImplementation implements CanvasElement {
  CanvasElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get height() { return _ptr.height; }

  void set height(int value) { _ptr.height = value; }

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }

  CanvasRenderingContext getContext([String contextId = null]) {
    if (contextId === null) {
      return LevelDom.wrapCanvasRenderingContext(_ptr.getContext());
    } else {
      return LevelDom.wrapCanvasRenderingContext(_ptr.getContext(contextId));
    }
  }

  String toDataURL(String type) {
    return _ptr.toDataURL(type);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasGradientWrappingImplementation extends DOMWrapperBase implements CanvasGradient {
  CanvasGradientWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void addColorStop(num offset, String color) {
    _ptr.addColorStop(offset, color);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasPatternWrappingImplementation extends DOMWrapperBase implements CanvasPattern {
  CanvasPatternWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasPixelArrayWrappingImplementation extends DOMWrapperBase implements CanvasPixelArray {
  CanvasPixelArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  int operator[](int index) {
    return item(index);
  }

  void operator[]=(int index, int value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(int a, int b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(int element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(int element, [int start = null]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  int removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  int last() {
    return this[length - 1];
  }

  void forEach(void f(int element)) {
    _Collections.forEach(this, f);
  }

  Collection<int> filter(bool f(int element)) {
    return _Collections.filter(this, new List<int>(), f);
  }

  bool every(bool f(int element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(int element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<int> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [int initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<int> iterator() {
    return new _FixedSizeListIterator<int>(this);
  }

  int item(int index) {
    return _ptr.item(index);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasRenderingContext2DWrappingImplementation extends CanvasRenderingContextWrappingImplementation implements CanvasRenderingContext2D {
  CanvasRenderingContext2DWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get font() { return _ptr.font; }

  void set font(String value) { _ptr.font = value; }

  num get globalAlpha() { return _ptr.globalAlpha; }

  void set globalAlpha(num value) { _ptr.globalAlpha = value; }

  String get globalCompositeOperation() { return _ptr.globalCompositeOperation; }

  void set globalCompositeOperation(String value) { _ptr.globalCompositeOperation = value; }

  String get lineCap() { return _ptr.lineCap; }

  void set lineCap(String value) { _ptr.lineCap = value; }

  String get lineJoin() { return _ptr.lineJoin; }

  void set lineJoin(String value) { _ptr.lineJoin = value; }

  num get lineWidth() { return _ptr.lineWidth; }

  void set lineWidth(num value) { _ptr.lineWidth = value; }

  num get miterLimit() { return _ptr.miterLimit; }

  void set miterLimit(num value) { _ptr.miterLimit = value; }

  num get shadowBlur() { return _ptr.shadowBlur; }

  void set shadowBlur(num value) { _ptr.shadowBlur = value; }

  String get shadowColor() { return _ptr.shadowColor; }

  void set shadowColor(String value) { _ptr.shadowColor = value; }

  num get shadowOffsetX() { return _ptr.shadowOffsetX; }

  void set shadowOffsetX(num value) { _ptr.shadowOffsetX = value; }

  num get shadowOffsetY() { return _ptr.shadowOffsetY; }

  void set shadowOffsetY(num value) { _ptr.shadowOffsetY = value; }

  String get textAlign() { return _ptr.textAlign; }

  void set textAlign(String value) { _ptr.textAlign = value; }

  String get textBaseline() { return _ptr.textBaseline; }

  void set textBaseline(String value) { _ptr.textBaseline = value; }

  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise) {
    _ptr.arc(x, y, radius, startAngle, endAngle, anticlockwise);
    return;
  }

  void arcTo(num x1, num y1, num x2, num y2, num radius) {
    _ptr.arcTo(x1, y1, x2, y2, radius);
    return;
  }

  void beginPath() {
    _ptr.beginPath();
    return;
  }

  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) {
    _ptr.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
    return;
  }

  void clearRect(num x, num y, num width, num height) {
    _ptr.clearRect(x, y, width, height);
    return;
  }

  void clearShadow() {
    _ptr.clearShadow();
    return;
  }

  void clip() {
    _ptr.clip();
    return;
  }

  void closePath() {
    _ptr.closePath();
    return;
  }

  ImageData createImageData(var imagedata_OR_sw, [num sh = null]) {
    if (imagedata_OR_sw is ImageData) {
      if (sh === null) {
        return LevelDom.wrapImageData(_ptr.createImageData(LevelDom.unwrap(imagedata_OR_sw)));
      }
    } else {
      if (imagedata_OR_sw is num) {
        return LevelDom.wrapImageData(_ptr.createImageData(LevelDom.unwrap(imagedata_OR_sw), sh));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) {
    return LevelDom.wrapCanvasGradient(_ptr.createLinearGradient(x0, y0, x1, y1));
  }

  CanvasPattern createPattern(var canvas_OR_image, String repetitionType) {
    if (canvas_OR_image is CanvasElement) {
      return LevelDom.wrapCanvasPattern(_ptr.createPattern(LevelDom.unwrap(canvas_OR_image), repetitionType));
    } else {
      if (canvas_OR_image is ImageElement) {
        return LevelDom.wrapCanvasPattern(_ptr.createPattern(LevelDom.unwrap(canvas_OR_image), repetitionType));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) {
    return LevelDom.wrapCanvasGradient(_ptr.createRadialGradient(x0, y0, r0, x1, y1, r1));
  }

  void drawImage(var canvas_OR_image, num sx_OR_x, num sy_OR_y, [num sw_OR_width = null, num height_OR_sh = null, num dx = null, num dy = null, num dw = null, num dh = null]) {
    if (canvas_OR_image is ImageElement) {
      if (sw_OR_width === null) {
        if (height_OR_sh === null) {
          if (dx === null) {
            if (dy === null) {
              if (dw === null) {
                if (dh === null) {
                  _ptr.drawImage(LevelDom.unwrap(canvas_OR_image), sx_OR_x, sy_OR_y);
                  return;
                }
              }
            }
          }
        }
      } else {
        if (dx === null) {
          if (dy === null) {
            if (dw === null) {
              if (dh === null) {
                _ptr.drawImage(LevelDom.unwrap(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
                return;
              }
            }
          }
        } else {
          _ptr.drawImage(LevelDom.unwrap(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
          return;
        }
      }
    } else {
      if (canvas_OR_image is CanvasElement) {
        if (sw_OR_width === null) {
          if (height_OR_sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    _ptr.drawImage(LevelDom.unwrap(canvas_OR_image), sx_OR_x, sy_OR_y);
                    return;
                  }
                }
              }
            }
          }
        } else {
          if (dx === null) {
            if (dy === null) {
              if (dw === null) {
                if (dh === null) {
                  _ptr.drawImage(LevelDom.unwrap(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
                  return;
                }
              }
            }
          } else {
            _ptr.drawImage(LevelDom.unwrap(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void drawImageFromRect(ImageElement image, [num sx = null, num sy = null, num sw = null, num sh = null, num dx = null, num dy = null, num dw = null, num dh = null, String compositeOperation = null]) {
    if (sx === null) {
      if (sy === null) {
        if (sw === null) {
          if (sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image));
                      return;
                    }
                  }
                }
              }
            }
          }
        }
      }
    } else {
      if (sy === null) {
        if (sw === null) {
          if (sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx);
                      return;
                    }
                  }
                }
              }
            }
          }
        }
      } else {
        if (sw === null) {
          if (sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy);
                      return;
                    }
                  }
                }
              }
            }
          }
        } else {
          if (sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw);
                      return;
                    }
                  }
                }
              }
            }
          } else {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh);
                      return;
                    }
                  }
                }
              }
            } else {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh, dx);
                      return;
                    }
                  }
                }
              } else {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh, dx, dy);
                      return;
                    }
                  }
                } else {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh, dx, dy, dw);
                      return;
                    }
                  } else {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh, dx, dy, dw, dh);
                      return;
                    } else {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh, dx, dy, dw, dh, compositeOperation);
                      return;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void fill() {
    _ptr.fill();
    return;
  }

  void fillRect(num x, num y, num width, num height) {
    _ptr.fillRect(x, y, width, height);
    return;
  }

  void fillText(String text, num x, num y, [num maxWidth = null]) {
    if (maxWidth === null) {
      _ptr.fillText(text, x, y);
      return;
    } else {
      _ptr.fillText(text, x, y, maxWidth);
      return;
    }
  }

  ImageData getImageData(num sx, num sy, num sw, num sh) {
    return LevelDom.wrapImageData(_ptr.getImageData(sx, sy, sw, sh));
  }

  bool isPointInPath(num x, num y) {
    return _ptr.isPointInPath(x, y);
  }

  void lineTo(num x, num y) {
    _ptr.lineTo(x, y);
    return;
  }

  TextMetrics measureText(String text) {
    return LevelDom.wrapTextMetrics(_ptr.measureText(text));
  }

  void moveTo(num x, num y) {
    _ptr.moveTo(x, y);
    return;
  }

  void putImageData(ImageData imagedata, num dx, num dy, [num dirtyX = null, num dirtyY = null, num dirtyWidth = null, num dirtyHeight = null]) {
    if (dirtyX === null) {
      if (dirtyY === null) {
        if (dirtyWidth === null) {
          if (dirtyHeight === null) {
            _ptr.putImageData(LevelDom.unwrap(imagedata), dx, dy);
            return;
          }
        }
      }
    } else {
      _ptr.putImageData(LevelDom.unwrap(imagedata), dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
      return;
    }
    throw "Incorrect number or type of arguments";
  }

  void quadraticCurveTo(num cpx, num cpy, num x, num y) {
    _ptr.quadraticCurveTo(cpx, cpy, x, y);
    return;
  }

  void rect(num x, num y, num width, num height) {
    _ptr.rect(x, y, width, height);
    return;
  }

  void restore() {
    _ptr.restore();
    return;
  }

  void rotate(num angle) {
    _ptr.rotate(angle);
    return;
  }

  void save() {
    _ptr.save();
    return;
  }

  void scale(num sx, num sy) {
    _ptr.scale(sx, sy);
    return;
  }

  void setAlpha(num alpha) {
    _ptr.setAlpha(alpha);
    return;
  }

  void setCompositeOperation(String compositeOperation) {
    _ptr.setCompositeOperation(compositeOperation);
    return;
  }

  void setFillColor(var c_OR_color_OR_grayLevel_OR_r, [num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) {
    if (c_OR_color_OR_grayLevel_OR_r is String) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setFillColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r));
              return;
            }
          }
        }
      } else {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setFillColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
              return;
            }
          }
        }
      }
    } else {
      if (c_OR_color_OR_grayLevel_OR_r is num) {
        if (alpha_OR_g_OR_m === null) {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setFillColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setFillColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                return;
              }
            }
          } else {
            if (a === null) {
              _ptr.setFillColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k);
              return;
            } else {
              _ptr.setFillColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setFillStyle(var color_OR_gradient_OR_pattern) {
    if (color_OR_gradient_OR_pattern is String) {
      _ptr.setFillStyle(LevelDom.unwrap(color_OR_gradient_OR_pattern));
      return;
    } else {
      if (color_OR_gradient_OR_pattern is CanvasGradient) {
        _ptr.setFillStyle(LevelDom.unwrap(color_OR_gradient_OR_pattern));
        return;
      } else {
        if (color_OR_gradient_OR_pattern is CanvasPattern) {
          _ptr.setFillStyle(LevelDom.unwrap(color_OR_gradient_OR_pattern));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setLineCap(String cap) {
    _ptr.setLineCap(cap);
    return;
  }

  void setLineJoin(String join) {
    _ptr.setLineJoin(join);
    return;
  }

  void setLineWidth(num width) {
    _ptr.setLineWidth(width);
    return;
  }

  void setMiterLimit(num limit) {
    _ptr.setMiterLimit(limit);
    return;
  }

  void setShadow(num width, num height, num blur, [var c_OR_color_OR_grayLevel_OR_r = null, num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) {
    if (c_OR_color_OR_grayLevel_OR_r === null) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setShadow(width, height, blur);
              return;
            }
          }
        }
      }
    } else {
      if (c_OR_color_OR_grayLevel_OR_r is String) {
        if (alpha_OR_g_OR_m === null) {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setShadow(width, height, blur, LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setShadow(width, height, blur, LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                return;
              }
            }
          }
        }
      } else {
        if (c_OR_color_OR_grayLevel_OR_r is num) {
          if (alpha_OR_g_OR_m === null) {
            if (b_OR_y === null) {
              if (a_OR_k === null) {
                if (a === null) {
                  _ptr.setShadow(width, height, blur, LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r));
                  return;
                }
              }
            }
          } else {
            if (b_OR_y === null) {
              if (a_OR_k === null) {
                if (a === null) {
                  _ptr.setShadow(width, height, blur, LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                  return;
                }
              }
            } else {
              if (a === null) {
                _ptr.setShadow(width, height, blur, LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k);
                return;
              } else {
                _ptr.setShadow(width, height, blur, LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
                return;
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setStrokeColor(var c_OR_color_OR_grayLevel_OR_r, [num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) {
    if (c_OR_color_OR_grayLevel_OR_r is String) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setStrokeColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r));
              return;
            }
          }
        }
      } else {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setStrokeColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
              return;
            }
          }
        }
      }
    } else {
      if (c_OR_color_OR_grayLevel_OR_r is num) {
        if (alpha_OR_g_OR_m === null) {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setStrokeColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setStrokeColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                return;
              }
            }
          } else {
            if (a === null) {
              _ptr.setStrokeColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k);
              return;
            } else {
              _ptr.setStrokeColor(LevelDom.unwrap(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setStrokeStyle(var color_OR_gradient_OR_pattern) {
    if (color_OR_gradient_OR_pattern is String) {
      _ptr.setStrokeStyle(LevelDom.unwrap(color_OR_gradient_OR_pattern));
      return;
    } else {
      if (color_OR_gradient_OR_pattern is CanvasGradient) {
        _ptr.setStrokeStyle(LevelDom.unwrap(color_OR_gradient_OR_pattern));
        return;
      } else {
        if (color_OR_gradient_OR_pattern is CanvasPattern) {
          _ptr.setStrokeStyle(LevelDom.unwrap(color_OR_gradient_OR_pattern));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy) {
    _ptr.setTransform(m11, m12, m21, m22, dx, dy);
    return;
  }

  void stroke() {
    _ptr.stroke();
    return;
  }

  void strokeRect(num x, num y, num width, num height, [num lineWidth = null]) {
    if (lineWidth === null) {
      _ptr.strokeRect(x, y, width, height);
      return;
    } else {
      _ptr.strokeRect(x, y, width, height, lineWidth);
      return;
    }
  }

  void strokeText(String text, num x, num y, [num maxWidth = null]) {
    if (maxWidth === null) {
      _ptr.strokeText(text, x, y);
      return;
    } else {
      _ptr.strokeText(text, x, y, maxWidth);
      return;
    }
  }

  void transform(num m11, num m12, num m21, num m22, num dx, num dy) {
    _ptr.transform(m11, m12, m21, m22, dx, dy);
    return;
  }

  void translate(num tx, num ty) {
    _ptr.translate(tx, ty);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasRenderingContextWrappingImplementation extends DOMWrapperBase implements CanvasRenderingContext {
  CanvasRenderingContextWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CanvasElement get canvas() { return LevelDom.wrapCanvasElement(_ptr.canvas); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CharacterDataWrappingImplementation extends NodeWrappingImplementation implements CharacterData {
  CharacterDataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get data() { return _ptr.data; }

  void set data(String value) { _ptr.data = value; }

  int get length() { return _ptr.length; }

  void appendData(String data) {
    _ptr.appendData(data);
    return;
  }

  void deleteData(int offset, int length) {
    _ptr.deleteData(offset, length);
    return;
  }

  void insertData(int offset, String data) {
    _ptr.insertData(offset, data);
    return;
  }

  void replaceData(int offset, int length, String data) {
    _ptr.replaceData(offset, length, data);
    return;
  }

  String substringData(int offset, int length) {
    return _ptr.substringData(offset, length);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ClientRectWrappingImplementation extends DOMWrapperBase implements ClientRect {
  ClientRectWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get bottom() { return _ptr.bottom; }

  num get height() { return _ptr.height; }

  num get left() { return _ptr.left; }

  num get right() { return _ptr.right; }

  num get top() { return _ptr.top; }

  num get width() { return _ptr.width; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ClipboardWrappingImplementation extends DOMWrapperBase implements Clipboard {
  ClipboardWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get dropEffect() { return _ptr.dropEffect; }

  void set dropEffect(String value) { _ptr.dropEffect = value; }

  String get effectAllowed() { return _ptr.effectAllowed; }

  void set effectAllowed(String value) { _ptr.effectAllowed = value; }

  FileList get files() { return LevelDom.wrapFileList(_ptr.files); }

  DataTransferItems get items() { return LevelDom.wrapDataTransferItems(_ptr.items); }

  void clearData([String type = null]) {
    if (type === null) {
      _ptr.clearData();
      return;
    } else {
      _ptr.clearData(type);
      return;
    }
  }

  void getData(String type) {
    _ptr.getData(type);
    return;
  }

  bool setData(String type, String data) {
    return _ptr.setData(type, data);
  }

  void setDragImage(ImageElement image, int x, int y) {
    _ptr.setDragImage(LevelDom.unwrap(image), x, y);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CommentWrappingImplementation extends CharacterDataWrappingImplementation implements Comment {
  CommentWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ConsoleWrappingImplementation extends DOMWrapperBase implements Console {
  ConsoleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void count() {
    _ptr.count();
    return;
  }

  void debug(Object arg) {
    _ptr.debug(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void dir() {
    _ptr.dir();
    return;
  }

  void dirxml() {
    _ptr.dirxml();
    return;
  }

  void error(Object arg) {
    _ptr.error(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void group() {
    _ptr.group();
    return;
  }

  void groupCollapsed() {
    _ptr.groupCollapsed();
    return;
  }

  void groupEnd() {
    _ptr.groupEnd();
    return;
  }

  void info(Object arg) {
    _ptr.info(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void log(Object arg) {
    _ptr.log(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void markTimeline() {
    _ptr.markTimeline();
    return;
  }

  void time(String title) {
    _ptr.time(title);
    return;
  }

  void timeEnd(String title) {
    _ptr.timeEnd(title);
    return;
  }

  void timeStamp() {
    _ptr.timeStamp();
    return;
  }

  void trace(Object arg) {
    _ptr.trace(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void warn(Object arg) {
    _ptr.warn(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CoordinatesWrappingImplementation extends DOMWrapperBase implements Coordinates {
  CoordinatesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get accuracy() { return _ptr.accuracy; }

  num get altitude() { return _ptr.altitude; }

  num get altitudeAccuracy() { return _ptr.altitudeAccuracy; }

  num get heading() { return _ptr.heading; }

  num get latitude() { return _ptr.latitude; }

  num get longitude() { return _ptr.longitude; }

  num get speed() { return _ptr.speed; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CounterWrappingImplementation extends DOMWrapperBase implements Counter {
  CounterWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get identifier() { return _ptr.identifier; }

  String get listStyle() { return _ptr.listStyle; }

  String get separator() { return _ptr.separator; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CryptoWrappingImplementation extends DOMWrapperBase implements Crypto {
  CryptoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void getRandomValues(ArrayBufferView array) {
    _ptr.getRandomValues(LevelDom.unwrap(array));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DListElementWrappingImplementation extends ElementWrappingImplementation implements DListElement {
  DListElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get compact() { return _ptr.compact; }

  void set compact(bool value) { _ptr.compact = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMExceptionWrappingImplementation extends DOMWrapperBase implements DOMException {
  DOMExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMFileSystemSyncWrappingImplementation extends DOMWrapperBase implements DOMFileSystemSync {
  DOMFileSystemSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  DirectoryEntrySync get root() { return LevelDom.wrapDirectoryEntrySync(_ptr.root); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMFileSystemWrappingImplementation extends DOMWrapperBase implements DOMFileSystem {
  DOMFileSystemWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  DirectoryEntry get root() { return LevelDom.wrapDirectoryEntry(_ptr.root); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMFormDataWrappingImplementation extends DOMWrapperBase implements DOMFormData {
  DOMFormDataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void append(String name, String value) {
    _ptr.append(name, value);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMMimeTypeArrayWrappingImplementation extends DOMWrapperBase implements DOMMimeTypeArray {
  DOMMimeTypeArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  DOMMimeType item(int index) {
    return LevelDom.wrapDOMMimeType(_ptr.item(index));
  }

  DOMMimeType namedItem(String name) {
    return LevelDom.wrapDOMMimeType(_ptr.namedItem(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMMimeTypeWrappingImplementation extends DOMWrapperBase implements DOMMimeType {
  DOMMimeTypeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get description() { return _ptr.description; }

  DOMPlugin get enabledPlugin() { return LevelDom.wrapDOMPlugin(_ptr.enabledPlugin); }

  String get suffixes() { return _ptr.suffixes; }

  String get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMParserWrappingImplementation extends DOMWrapperBase implements DOMParser {
  DOMParserWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Document parseFromString(String str, String contentType) {
    return LevelDom.wrapDocument(_ptr.parseFromString(str, contentType));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMPluginArrayWrappingImplementation extends DOMWrapperBase implements DOMPluginArray {
  DOMPluginArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  DOMPlugin item(int index) {
    return LevelDom.wrapDOMPlugin(_ptr.item(index));
  }

  DOMPlugin namedItem(String name) {
    return LevelDom.wrapDOMPlugin(_ptr.namedItem(name));
  }

  void refresh(bool reload) {
    _ptr.refresh(reload);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMPluginWrappingImplementation extends DOMWrapperBase implements DOMPlugin {
  DOMPluginWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get description() { return _ptr.description; }

  String get filename() { return _ptr.filename; }

  int get length() { return _ptr.length; }

  String get name() { return _ptr.name; }

  DOMMimeType item(int index) {
    return LevelDom.wrapDOMMimeType(_ptr.item(index));
  }

  DOMMimeType namedItem(String name) {
    return LevelDom.wrapDOMMimeType(_ptr.namedItem(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMSelectionWrappingImplementation extends DOMWrapperBase implements DOMSelection {
  DOMSelectionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Node get anchorNode() { return LevelDom.wrapNode(_ptr.anchorNode); }

  int get anchorOffset() { return _ptr.anchorOffset; }

  Node get baseNode() { return LevelDom.wrapNode(_ptr.baseNode); }

  int get baseOffset() { return _ptr.baseOffset; }

  Node get extentNode() { return LevelDom.wrapNode(_ptr.extentNode); }

  int get extentOffset() { return _ptr.extentOffset; }

  Node get focusNode() { return LevelDom.wrapNode(_ptr.focusNode); }

  int get focusOffset() { return _ptr.focusOffset; }

  bool get isCollapsed() { return _ptr.isCollapsed; }

  int get rangeCount() { return _ptr.rangeCount; }

  String get type() { return _ptr.type; }

  void addRange(Range range) {
    _ptr.addRange(LevelDom.unwrap(range));
    return;
  }

  void collapse(Node node, int index) {
    _ptr.collapse(LevelDom.unwrap(node), index);
    return;
  }

  void collapseToEnd() {
    _ptr.collapseToEnd();
    return;
  }

  void collapseToStart() {
    _ptr.collapseToStart();
    return;
  }

  bool containsNode(Node node, bool allowPartial) {
    return _ptr.containsNode(LevelDom.unwrap(node), allowPartial);
  }

  void deleteFromDocument() {
    _ptr.deleteFromDocument();
    return;
  }

  void empty() {
    _ptr.empty();
    return;
  }

  void extend(Node node, int offset) {
    _ptr.extend(LevelDom.unwrap(node), offset);
    return;
  }

  Range getRangeAt(int index) {
    return LevelDom.wrapRange(_ptr.getRangeAt(index));
  }

  void modify(String alter, String direction, String granularity) {
    _ptr.modify(alter, direction, granularity);
    return;
  }

  void removeAllRanges() {
    _ptr.removeAllRanges();
    return;
  }

  void selectAllChildren(Node node) {
    _ptr.selectAllChildren(LevelDom.unwrap(node));
    return;
  }

  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset) {
    _ptr.setBaseAndExtent(LevelDom.unwrap(baseNode), baseOffset, LevelDom.unwrap(extentNode), extentOffset);
    return;
  }

  void setPosition(Node node, int offset) {
    _ptr.setPosition(LevelDom.unwrap(node), offset);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMSettableTokenListWrappingImplementation extends DOMTokenListWrappingImplementation implements DOMSettableTokenList {
  DOMSettableTokenListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMTokenListWrappingImplementation extends DOMWrapperBase implements DOMTokenList {
  DOMTokenListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void add(String token) {
    _ptr.add(token);
    return;
  }

  bool contains(String token) {
    return _ptr.contains(token);
  }

  String item(int index) {
    return _ptr.item(index);
  }

  void remove(String token) {
    _ptr.remove(token);
    return;
  }

  bool toggle(String token) {
    return _ptr.toggle(token);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMURLWrappingImplementation extends DOMWrapperBase implements DOMURL {
  DOMURLWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String createObjectURL(Blob blob) {
    return _ptr.createObjectURL(LevelDom.unwrap(blob));
  }

  void revokeObjectURL(String url) {
    _ptr.revokeObjectURL(url);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataListElementWrappingImplementation extends ElementWrappingImplementation implements DataListElement {
  DataListElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ElementList get options() { return LevelDom.wrapElementList(_ptr.options); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataTransferItemWrappingImplementation extends DOMWrapperBase implements DataTransferItem {
  DataTransferItemWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get kind() { return _ptr.kind; }

  String get type() { return _ptr.type; }

  Blob getAsFile() {
    return LevelDom.wrapBlob(_ptr.getAsFile());
  }

  void getAsString(StringCallback callback) {
    _ptr.getAsString(LevelDom.unwrap(callback));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataTransferItemsWrappingImplementation extends DOMWrapperBase implements DataTransferItems {
  DataTransferItemsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void add(String data, String type) {
    _ptr.add(data, type);
    return;
  }

  void clear() {
    _ptr.clear();
    return;
  }

  DataTransferItem item(int index) {
    return LevelDom.wrapDataTransferItem(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataViewWrappingImplementation extends ArrayBufferViewWrappingImplementation implements DataView {
  DataViewWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num getFloat32(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getFloat32(byteOffset);
    } else {
      return _ptr.getFloat32(byteOffset, littleEndian);
    }
  }

  num getFloat64(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getFloat64(byteOffset);
    } else {
      return _ptr.getFloat64(byteOffset, littleEndian);
    }
  }

  int getInt16(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getInt16(byteOffset);
    } else {
      return _ptr.getInt16(byteOffset, littleEndian);
    }
  }

  int getInt32(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getInt32(byteOffset);
    } else {
      return _ptr.getInt32(byteOffset, littleEndian);
    }
  }

  int getInt8() {
    return _ptr.getInt8();
  }

  int getUint16(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getUint16(byteOffset);
    } else {
      return _ptr.getUint16(byteOffset, littleEndian);
    }
  }

  int getUint32(int byteOffset, [bool littleEndian = null]) {
    if (littleEndian === null) {
      return _ptr.getUint32(byteOffset);
    } else {
      return _ptr.getUint32(byteOffset, littleEndian);
    }
  }

  int getUint8() {
    return _ptr.getUint8();
  }

  void setFloat32(int byteOffset, num value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setFloat32(byteOffset, value);
      return;
    } else {
      _ptr.setFloat32(byteOffset, value, littleEndian);
      return;
    }
  }

  void setFloat64(int byteOffset, num value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setFloat64(byteOffset, value);
      return;
    } else {
      _ptr.setFloat64(byteOffset, value, littleEndian);
      return;
    }
  }

  void setInt16(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setInt16(byteOffset, value);
      return;
    } else {
      _ptr.setInt16(byteOffset, value, littleEndian);
      return;
    }
  }

  void setInt32(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setInt32(byteOffset, value);
      return;
    } else {
      _ptr.setInt32(byteOffset, value, littleEndian);
      return;
    }
  }

  void setInt8() {
    _ptr.setInt8();
    return;
  }

  void setUint16(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setUint16(byteOffset, value);
      return;
    } else {
      _ptr.setUint16(byteOffset, value, littleEndian);
      return;
    }
  }

  void setUint32(int byteOffset, int value, [bool littleEndian = null]) {
    if (littleEndian === null) {
      _ptr.setUint32(byteOffset, value);
      return;
    } else {
      _ptr.setUint32(byteOffset, value, littleEndian);
      return;
    }
  }

  void setUint8() {
    _ptr.setUint8();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DetailsElementWrappingImplementation extends ElementWrappingImplementation implements DetailsElement {
  DetailsElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get open() { return _ptr.open; }

  void set open(bool value) { _ptr.open = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryEntrySyncWrappingImplementation extends EntrySyncWrappingImplementation implements DirectoryEntrySync {
  DirectoryEntrySyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DirectoryReaderSync createReader() {
    return LevelDom.wrapDirectoryReaderSync(_ptr.createReader());
  }

  DirectoryEntrySync getDirectory(String path, Flags flags) {
    return LevelDom.wrapDirectoryEntrySync(_ptr.getDirectory(path, LevelDom.unwrap(flags)));
  }

  FileEntrySync getFile(String path, Flags flags) {
    return LevelDom.wrapFileEntrySync(_ptr.getFile(path, LevelDom.unwrap(flags)));
  }

  void removeRecursively() {
    _ptr.removeRecursively();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryEntryWrappingImplementation extends EntryWrappingImplementation implements DirectoryEntry {
  DirectoryEntryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DirectoryReader createReader() {
    return LevelDom.wrapDirectoryReader(_ptr.createReader());
  }

  void getDirectory(String path, [Flags flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (flags === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getDirectory(path);
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getDirectory(path, LevelDom.unwrap(flags));
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.getDirectory(path, LevelDom.unwrap(flags), LevelDom.unwrap(successCallback));
          return;
        } else {
          _ptr.getDirectory(path, LevelDom.unwrap(flags), LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getFile(String path, [Flags flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (flags === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getFile(path);
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getFile(path, LevelDom.unwrap(flags));
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.getFile(path, LevelDom.unwrap(flags), LevelDom.unwrap(successCallback));
          return;
        } else {
          _ptr.getFile(path, LevelDom.unwrap(flags), LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void removeRecursively([VoidCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.removeRecursively();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.removeRecursively(LevelDom.unwrap(successCallback));
        return;
      } else {
        _ptr.removeRecursively(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryReaderSyncWrappingImplementation extends DOMWrapperBase implements DirectoryReaderSync {
  DirectoryReaderSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  EntryArraySync readEntries() {
    return LevelDom.wrapEntryArraySync(_ptr.readEntries());
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryReaderWrappingImplementation extends DOMWrapperBase implements DirectoryReader {
  DirectoryReaderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.readEntries(LevelDom.unwrap(successCallback));
      return;
    } else {
      _ptr.readEntries(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DivElementWrappingImplementation extends ElementWrappingImplementation implements DivElement {
  DivElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EmbedElementWrappingImplementation extends ElementWrappingImplementation implements EmbedElement {
  EmbedElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  int get height() { return _ptr.height; }

  void set height(int value) { _ptr.height = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntityReferenceWrappingImplementation extends NodeWrappingImplementation implements EntityReference {
  EntityReferenceWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntityWrappingImplementation extends NodeWrappingImplementation implements Entity {
  EntityWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get notationName() { return _ptr.notationName; }

  String get publicId() { return _ptr.publicId; }

  String get systemId() { return _ptr.systemId; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntriesCallbackWrappingImplementation extends DOMWrapperBase implements EntriesCallback {
  EntriesCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(EntryArray entries) {
    return _ptr.handleEvent(LevelDom.unwrap(entries));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntryArraySyncWrappingImplementation extends DOMWrapperBase implements EntryArraySync {
  EntryArraySyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  EntrySync item(int index) {
    return LevelDom.wrapEntrySync(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntryArrayWrappingImplementation extends DOMWrapperBase implements EntryArray {
  EntryArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Entry item(int index) {
    return LevelDom.wrapEntry(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntryCallbackWrappingImplementation extends DOMWrapperBase implements EntryCallback {
  EntryCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(Entry entry) {
    return _ptr.handleEvent(LevelDom.unwrap(entry));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntrySyncWrappingImplementation extends DOMWrapperBase implements EntrySync {
  EntrySyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DOMFileSystemSync get filesystem() { return LevelDom.wrapDOMFileSystemSync(_ptr.filesystem); }

  String get fullPath() { return _ptr.fullPath; }

  bool get isDirectory() { return _ptr.isDirectory; }

  bool get isFile() { return _ptr.isFile; }

  String get name() { return _ptr.name; }

  EntrySync copyTo(DirectoryEntrySync parent, String name) {
    return LevelDom.wrapEntrySync(_ptr.copyTo(LevelDom.unwrap(parent), name));
  }

  Metadata getMetadata() {
    return LevelDom.wrapMetadata(_ptr.getMetadata());
  }

  DirectoryEntrySync getParent() {
    return LevelDom.wrapDirectoryEntrySync(_ptr.getParent());
  }

  EntrySync moveTo(DirectoryEntrySync parent, String name) {
    return LevelDom.wrapEntrySync(_ptr.moveTo(LevelDom.unwrap(parent), name));
  }

  void remove() {
    _ptr.remove();
    return;
  }

  String toURL() {
    return _ptr.toURL();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntryWrappingImplementation extends DOMWrapperBase implements Entry {
  EntryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DOMFileSystem get filesystem() { return LevelDom.wrapDOMFileSystem(_ptr.filesystem); }

  String get fullPath() { return _ptr.fullPath; }

  bool get isDirectory() { return _ptr.isDirectory; }

  bool get isFile() { return _ptr.isFile; }

  String get name() { return _ptr.name; }

  void copyTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (name === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.copyTo(LevelDom.unwrap(parent));
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.copyTo(LevelDom.unwrap(parent), name);
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.copyTo(LevelDom.unwrap(parent), name, LevelDom.unwrap(successCallback));
          return;
        } else {
          _ptr.copyTo(LevelDom.unwrap(parent), name, LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getMetadata([MetadataCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.getMetadata();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.getMetadata(LevelDom.unwrap(successCallback));
        return;
      } else {
        _ptr.getMetadata(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getParent([EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.getParent();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.getParent(LevelDom.unwrap(successCallback));
        return;
      } else {
        _ptr.getParent(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void moveTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (name === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.moveTo(LevelDom.unwrap(parent));
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.moveTo(LevelDom.unwrap(parent), name);
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.moveTo(LevelDom.unwrap(parent), name, LevelDom.unwrap(successCallback));
          return;
        } else {
          _ptr.moveTo(LevelDom.unwrap(parent), name, LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void remove([VoidCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.remove();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.remove(LevelDom.unwrap(successCallback));
        return;
      } else {
        _ptr.remove(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  String toURL() {
    return _ptr.toURL();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ErrorCallbackWrappingImplementation extends DOMWrapperBase implements ErrorCallback {
  ErrorCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(FileError error) {
    return _ptr.handleEvent(LevelDom.unwrap(error));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EventExceptionWrappingImplementation extends DOMWrapperBase implements EventException {
  EventExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FieldSetElementWrappingImplementation extends ElementWrappingImplementation implements FieldSetElement {
  FieldSetElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileCallbackWrappingImplementation extends DOMWrapperBase implements FileCallback {
  FileCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(File file) {
    return _ptr.handleEvent(LevelDom.unwrap(file));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileEntrySyncWrappingImplementation extends EntrySyncWrappingImplementation implements FileEntrySync {
  FileEntrySyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FileWriterSync createWriter() {
    return LevelDom.wrapFileWriterSync(_ptr.createWriter());
  }

  File file() {
    return LevelDom.wrapFile(_ptr.file());
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileEntryWrappingImplementation extends EntryWrappingImplementation implements FileEntry {
  FileEntryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.createWriter(LevelDom.unwrap(successCallback));
      return;
    } else {
      _ptr.createWriter(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
      return;
    }
  }

  void file(FileCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.file(LevelDom.unwrap(successCallback));
      return;
    } else {
      _ptr.file(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileErrorWrappingImplementation extends DOMWrapperBase implements FileError {
  FileErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileExceptionWrappingImplementation extends DOMWrapperBase implements FileException {
  FileExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileListWrappingImplementation extends DOMWrapperBase implements FileList {
  FileListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  File item(int index) {
    return LevelDom.wrapFile(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileReaderSyncWrappingImplementation extends DOMWrapperBase implements FileReaderSync {
  FileReaderSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ArrayBuffer readAsArrayBuffer(Blob blob) {
    return LevelDom.wrapArrayBuffer(_ptr.readAsArrayBuffer(LevelDom.unwrap(blob)));
  }

  String readAsBinaryString(Blob blob) {
    return _ptr.readAsBinaryString(LevelDom.unwrap(blob));
  }

  String readAsDataURL(Blob blob) {
    return _ptr.readAsDataURL(LevelDom.unwrap(blob));
  }

  String readAsText(Blob blob, [String encoding = null]) {
    if (encoding === null) {
      return _ptr.readAsText(LevelDom.unwrap(blob));
    } else {
      return _ptr.readAsText(LevelDom.unwrap(blob), encoding);
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileReaderWrappingImplementation extends DOMWrapperBase implements FileReader {
  FileReaderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FileError get error() { return LevelDom.wrapFileError(_ptr.error); }

  EventListener get onabort() { return LevelDom.wrapEventListener(_ptr.onabort); }

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onload() { return LevelDom.wrapEventListener(_ptr.onload); }

  void set onload(EventListener value) { _ptr.onload = LevelDom.unwrap(value); }

  EventListener get onloadend() { return LevelDom.wrapEventListener(_ptr.onloadend); }

  void set onloadend(EventListener value) { _ptr.onloadend = LevelDom.unwrap(value); }

  EventListener get onloadstart() { return LevelDom.wrapEventListener(_ptr.onloadstart); }

  void set onloadstart(EventListener value) { _ptr.onloadstart = LevelDom.unwrap(value); }

  EventListener get onprogress() { return LevelDom.wrapEventListener(_ptr.onprogress); }

  void set onprogress(EventListener value) { _ptr.onprogress = LevelDom.unwrap(value); }

  int get readyState() { return _ptr.readyState; }

  String get result() { return _ptr.result; }

  void abort() {
    _ptr.abort();
    return;
  }

  void readAsArrayBuffer(Blob blob) {
    _ptr.readAsArrayBuffer(LevelDom.unwrap(blob));
    return;
  }

  void readAsBinaryString(Blob blob) {
    _ptr.readAsBinaryString(LevelDom.unwrap(blob));
    return;
  }

  void readAsDataURL(Blob blob) {
    _ptr.readAsDataURL(LevelDom.unwrap(blob));
    return;
  }

  void readAsText(Blob blob, [String encoding = null]) {
    if (encoding === null) {
      _ptr.readAsText(LevelDom.unwrap(blob));
      return;
    } else {
      _ptr.readAsText(LevelDom.unwrap(blob), encoding);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileSystemCallbackWrappingImplementation extends DOMWrapperBase implements FileSystemCallback {
  FileSystemCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(DOMFileSystem fileSystem) {
    return _ptr.handleEvent(LevelDom.unwrap(fileSystem));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileWrappingImplementation extends BlobWrappingImplementation implements File {
  FileWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get fileName() { return _ptr.fileName; }

  int get fileSize() { return _ptr.fileSize; }

  Date get lastModifiedDate() { return _ptr.lastModifiedDate; }

  String get name() { return _ptr.name; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileWriterCallbackWrappingImplementation extends DOMWrapperBase implements FileWriterCallback {
  FileWriterCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(FileWriter fileWriter) {
    return _ptr.handleEvent(LevelDom.unwrap(fileWriter));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileWriterSyncWrappingImplementation extends DOMWrapperBase implements FileWriterSync {
  FileWriterSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  int get position() { return _ptr.position; }

  void seek(int position) {
    _ptr.seek(position);
    return;
  }

  void truncate(int size) {
    _ptr.truncate(size);
    return;
  }

  void write(Blob data) {
    _ptr.write(LevelDom.unwrap(data));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileWriterWrappingImplementation extends DOMWrapperBase implements FileWriter {
  FileWriterWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FileError get error() { return LevelDom.wrapFileError(_ptr.error); }

  int get length() { return _ptr.length; }

  EventListener get onabort() { return LevelDom.wrapEventListener(_ptr.onabort); }

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onprogress() { return LevelDom.wrapEventListener(_ptr.onprogress); }

  void set onprogress(EventListener value) { _ptr.onprogress = LevelDom.unwrap(value); }

  EventListener get onwrite() { return LevelDom.wrapEventListener(_ptr.onwrite); }

  void set onwrite(EventListener value) { _ptr.onwrite = LevelDom.unwrap(value); }

  EventListener get onwriteend() { return LevelDom.wrapEventListener(_ptr.onwriteend); }

  void set onwriteend(EventListener value) { _ptr.onwriteend = LevelDom.unwrap(value); }

  EventListener get onwritestart() { return LevelDom.wrapEventListener(_ptr.onwritestart); }

  void set onwritestart(EventListener value) { _ptr.onwritestart = LevelDom.unwrap(value); }

  int get position() { return _ptr.position; }

  int get readyState() { return _ptr.readyState; }

  void abort() {
    _ptr.abort();
    return;
  }

  void seek(int position) {
    _ptr.seek(position);
    return;
  }

  void truncate(int size) {
    _ptr.truncate(size);
    return;
  }

  void write(Blob data) {
    _ptr.write(LevelDom.unwrap(data));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FlagsWrappingImplementation extends DOMWrapperBase implements Flags {
  FlagsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get create() { return _ptr.create; }

  void set create(bool value) { _ptr.create = value; }

  bool get exclusive() { return _ptr.exclusive; }

  void set exclusive(bool value) { _ptr.exclusive = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Float32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Float32Array {
  Float32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Float32Array subarray(int start, [int end = null]) {
    if (end === null) {
      return LevelDom.wrapFloat32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapFloat32Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Float64ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Float64Array {
  Float64ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Float64Array subarray(int start, [int end = null]) {
    if (end === null) {
      return LevelDom.wrapFloat64Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapFloat64Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FontElementWrappingImplementation extends ElementWrappingImplementation implements FontElement {
  FontElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get color() { return _ptr.color; }

  void set color(String value) { _ptr.color = value; }

  String get face() { return _ptr.face; }

  void set face(String value) { _ptr.face = value; }

  String get size() { return _ptr.size; }

  void set size(String value) { _ptr.size = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FormElementWrappingImplementation extends ElementWrappingImplementation implements FormElement {
  FormElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get acceptCharset() { return _ptr.acceptCharset; }

  void set acceptCharset(String value) { _ptr.acceptCharset = value; }

  String get action() { return _ptr.action; }

  void set action(String value) { _ptr.action = value; }

  String get autocomplete() { return _ptr.autocomplete; }

  void set autocomplete(String value) { _ptr.autocomplete = value; }

  String get encoding() { return _ptr.encoding; }

  void set encoding(String value) { _ptr.encoding = value; }

  String get enctype() { return _ptr.enctype; }

  void set enctype(String value) { _ptr.enctype = value; }

  int get length() { return _ptr.length; }

  String get method() { return _ptr.method; }

  void set method(String value) { _ptr.method = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  bool get noValidate() { return _ptr.noValidate; }

  void set noValidate(bool value) { _ptr.noValidate = value; }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void reset() {
    _ptr.reset();
    return;
  }

  void submit() {
    _ptr.submit();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class GeolocationWrappingImplementation extends DOMWrapperBase implements Geolocation {
  GeolocationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void clearWatch(int watchId) {
    _ptr.clearWatch(watchId);
    return;
  }

  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.getCurrentPosition(LevelDom.unwrap(successCallback));
      return;
    } else {
      _ptr.getCurrentPosition(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
      return;
    }
  }

  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      return _ptr.watchPosition(LevelDom.unwrap(successCallback));
    } else {
      return _ptr.watchPosition(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class GeopositionWrappingImplementation extends DOMWrapperBase implements Geoposition {
  GeopositionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Coordinates get coords() { return LevelDom.wrapCoordinates(_ptr.coords); }

  int get timestamp() { return _ptr.timestamp; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HRElementWrappingImplementation extends ElementWrappingImplementation implements HRElement {
  HRElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  bool get noShade() { return _ptr.noShade; }

  void set noShade(bool value) { _ptr.noShade = value; }

  String get size() { return _ptr.size; }

  void set size(String value) { _ptr.size = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HTMLAllCollectionWrappingImplementation extends DOMWrapperBase implements HTMLAllCollection {
  HTMLAllCollectionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Node item(int index) {
    return LevelDom.wrapNode(_ptr.item(index));
  }

  Node namedItem(String name) {
    return LevelDom.wrapNode(_ptr.namedItem(name));
  }

  ElementList tags(String name) {
    return LevelDom.wrapElementList(_ptr.tags(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HeadElementWrappingImplementation extends ElementWrappingImplementation implements HeadElement {
  HeadElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get profile() { return _ptr.profile; }

  void set profile(String value) { _ptr.profile = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HeadingElementWrappingImplementation extends ElementWrappingImplementation implements HeadingElement {
  HeadingElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HistoryWrappingImplementation extends DOMWrapperBase implements History {
  HistoryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void back() {
    _ptr.back();
    return;
  }

  void forward() {
    _ptr.forward();
    return;
  }

  void go(int distance) {
    _ptr.go(distance);
    return;
  }

  void pushState(Object data, String title, [String url = null]) {
    if (url === null) {
      _ptr.pushState(LevelDom.unwrapMaybePrimitive(data), title);
      return;
    } else {
      _ptr.pushState(LevelDom.unwrapMaybePrimitive(data), title, url);
      return;
    }
  }

  void replaceState(Object data, String title, [String url = null]) {
    if (url === null) {
      _ptr.replaceState(LevelDom.unwrapMaybePrimitive(data), title);
      return;
    } else {
      _ptr.replaceState(LevelDom.unwrapMaybePrimitive(data), title, url);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HtmlElementWrappingImplementation extends ElementWrappingImplementation implements HtmlElement {
  HtmlElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get manifest() { return _ptr.manifest; }

  void set manifest(String value) { _ptr.manifest = value; }

  String get version() { return _ptr.version; }

  void set version(String value) { _ptr.version = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBAnyWrappingImplementation extends DOMWrapperBase implements IDBAny {
  IDBAnyWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBCursorWithValueWrappingImplementation extends IDBCursorWrappingImplementation implements IDBCursorWithValue {
  IDBCursorWithValueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get value() { return _ptr.value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBCursorWrappingImplementation extends DOMWrapperBase implements IDBCursor {
  IDBCursorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get direction() { return _ptr.direction; }

  IDBKey get key() { return LevelDom.wrapIDBKey(_ptr.key); }

  IDBKey get primaryKey() { return LevelDom.wrapIDBKey(_ptr.primaryKey); }

  IDBAny get source() { return LevelDom.wrapIDBAny(_ptr.source); }

  void continueFunction([IDBKey key = null]) {
    if (key === null) {
      _ptr.continueFunction();
      return;
    } else {
      _ptr.continueFunction(LevelDom.unwrap(key));
      return;
    }
  }

  IDBRequest delete() {
    return LevelDom.wrapIDBRequest(_ptr.delete());
  }

  IDBRequest update(String value) {
    return LevelDom.wrapIDBRequest(_ptr.update(value));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBDatabaseErrorWrappingImplementation extends DOMWrapperBase implements IDBDatabaseError {
  IDBDatabaseErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  void set code(int value) { _ptr.code = value; }

  String get message() { return _ptr.message; }

  void set message(String value) { _ptr.message = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBDatabaseExceptionWrappingImplementation extends DOMWrapperBase implements IDBDatabaseException {
  IDBDatabaseExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBDatabaseWrappingImplementation extends DOMWrapperBase implements IDBDatabase {
  IDBDatabaseWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  EventListener get onabort() { return LevelDom.wrapEventListener(_ptr.onabort); }

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onversionchange() { return LevelDom.wrapEventListener(_ptr.onversionchange); }

  void set onversionchange(EventListener value) { _ptr.onversionchange = LevelDom.unwrap(value); }

  String get version() { return _ptr.version; }

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  void close() {
    _ptr.close();
    return;
  }

  IDBObjectStore createObjectStore(String name) {
    return LevelDom.wrapIDBObjectStore(_ptr.createObjectStore(name));
  }

  void deleteObjectStore(String name) {
    _ptr.deleteObjectStore(name);
    return;
  }

  bool dispatchEvent(Event evt) {
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  IDBVersionChangeRequest setVersion(String version) {
    return LevelDom.wrapIDBVersionChangeRequest(_ptr.setVersion(version));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBFactoryWrappingImplementation extends DOMWrapperBase implements IDBFactory {
  IDBFactoryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  IDBRequest getDatabaseNames() {
    return LevelDom.wrapIDBRequest(_ptr.getDatabaseNames());
  }

  IDBRequest open(String name) {
    return LevelDom.wrapIDBRequest(_ptr.open(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBIndexWrappingImplementation extends DOMWrapperBase implements IDBIndex {
  IDBIndexWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get keyPath() { return _ptr.keyPath; }

  String get name() { return _ptr.name; }

  IDBObjectStore get objectStore() { return LevelDom.wrapIDBObjectStore(_ptr.objectStore); }

  bool get unique() { return _ptr.unique; }

  IDBRequest getObject(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.getObject(LevelDom.unwrap(key)));
  }

  IDBRequest getKey(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.getKey(LevelDom.unwrap(key)));
  }

  IDBRequest openCursor([IDBKeyRange range = null, int direction = null]) {
    if (range === null) {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openCursor());
      }
    } else {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range)));
      } else {
        return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range), direction));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  IDBRequest openKeyCursor([IDBKeyRange range = null, int direction = null]) {
    if (range === null) {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openKeyCursor());
      }
    } else {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openKeyCursor(LevelDom.unwrap(range)));
      } else {
        return LevelDom.wrapIDBRequest(_ptr.openKeyCursor(LevelDom.unwrap(range), direction));
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBKeyRangeWrappingImplementation extends DOMWrapperBase implements IDBKeyRange {
  IDBKeyRangeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  IDBKey get lower() { return LevelDom.wrapIDBKey(_ptr.lower); }

  bool get lowerOpen() { return _ptr.lowerOpen; }

  IDBKey get upper() { return LevelDom.wrapIDBKey(_ptr.upper); }

  bool get upperOpen() { return _ptr.upperOpen; }

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen = null, bool upperOpen = null]) {
    if (lowerOpen === null) {
      if (upperOpen === null) {
        return LevelDom.wrapIDBKeyRange(_ptr.bound(LevelDom.unwrap(lower), LevelDom.unwrap(upper)));
      }
    } else {
      if (upperOpen === null) {
        return LevelDom.wrapIDBKeyRange(_ptr.bound(LevelDom.unwrap(lower), LevelDom.unwrap(upper), lowerOpen));
      } else {
        return LevelDom.wrapIDBKeyRange(_ptr.bound(LevelDom.unwrap(lower), LevelDom.unwrap(upper), lowerOpen, upperOpen));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  IDBKeyRange lowerBound(IDBKey bound, [bool open = null]) {
    if (open === null) {
      return LevelDom.wrapIDBKeyRange(_ptr.lowerBound(LevelDom.unwrap(bound)));
    } else {
      return LevelDom.wrapIDBKeyRange(_ptr.lowerBound(LevelDom.unwrap(bound), open));
    }
  }

  IDBKeyRange only(IDBKey value) {
    return LevelDom.wrapIDBKeyRange(_ptr.only(LevelDom.unwrap(value)));
  }

  IDBKeyRange upperBound(IDBKey bound, [bool open = null]) {
    if (open === null) {
      return LevelDom.wrapIDBKeyRange(_ptr.upperBound(LevelDom.unwrap(bound)));
    } else {
      return LevelDom.wrapIDBKeyRange(_ptr.upperBound(LevelDom.unwrap(bound), open));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBKeyWrappingImplementation extends DOMWrapperBase implements IDBKey {
  IDBKeyWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBObjectStoreWrappingImplementation extends DOMWrapperBase implements IDBObjectStore {
  IDBObjectStoreWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get keyPath() { return _ptr.keyPath; }

  String get name() { return _ptr.name; }

  IDBRequest add(String value, [IDBKey key = null]) {
    if (key === null) {
      return LevelDom.wrapIDBRequest(_ptr.add(value));
    } else {
      return LevelDom.wrapIDBRequest(_ptr.add(value, LevelDom.unwrap(key)));
    }
  }

  IDBRequest clear() {
    return LevelDom.wrapIDBRequest(_ptr.clear());
  }

  IDBIndex createIndex(String name, String keyPath) {
    return LevelDom.wrapIDBIndex(_ptr.createIndex(name, keyPath));
  }

  IDBRequest delete(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.delete(LevelDom.unwrap(key)));
  }

  void deleteIndex(String name) {
    _ptr.deleteIndex(name);
    return;
  }

  IDBRequest getObject(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.getObject(LevelDom.unwrap(key)));
  }

  IDBIndex index(String name) {
    return LevelDom.wrapIDBIndex(_ptr.index(name));
  }

  IDBRequest openCursor([IDBKeyRange range = null, int direction = null]) {
    if (range === null) {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openCursor());
      }
    } else {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range)));
      } else {
        return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range), direction));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  IDBRequest put(String value, [IDBKey key = null]) {
    if (key === null) {
      return LevelDom.wrapIDBRequest(_ptr.put(value));
    } else {
      return LevelDom.wrapIDBRequest(_ptr.put(value, LevelDom.unwrap(key)));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBRequestWrappingImplementation extends DOMWrapperBase implements IDBRequest {
  IDBRequestWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get errorCode() { return _ptr.errorCode; }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onsuccess() { return LevelDom.wrapEventListener(_ptr.onsuccess); }

  void set onsuccess(EventListener value) { _ptr.onsuccess = LevelDom.unwrap(value); }

  int get readyState() { return _ptr.readyState; }

  IDBAny get result() { return LevelDom.wrapIDBAny(_ptr.result); }

  IDBAny get source() { return LevelDom.wrapIDBAny(_ptr.source); }

  IDBTransaction get transaction() { return LevelDom.wrapIDBTransaction(_ptr.transaction); }

  String get webkitErrorMessage() { return _ptr.webkitErrorMessage; }

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  bool dispatchEvent(Event evt) {
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBTransactionWrappingImplementation extends DOMWrapperBase implements IDBTransaction {
  IDBTransactionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  IDBDatabase get db() { return LevelDom.wrapIDBDatabase(_ptr.db); }

  int get mode() { return _ptr.mode; }

  EventListener get onabort() { return LevelDom.wrapEventListener(_ptr.onabort); }

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get oncomplete() { return LevelDom.wrapEventListener(_ptr.oncomplete); }

  void set oncomplete(EventListener value) { _ptr.oncomplete = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  void abort() {
    _ptr.abort();
    return;
  }

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  bool dispatchEvent(Event evt) {
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  IDBObjectStore objectStore(String name) {
    return LevelDom.wrapIDBObjectStore(_ptr.objectStore(name));
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBVersionChangeEventWrappingImplementation extends EventWrappingImplementation implements IDBVersionChangeEvent {
  IDBVersionChangeEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get version() { return _ptr.version; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBVersionChangeRequestWrappingImplementation extends IDBRequestWrappingImplementation implements IDBVersionChangeRequest {
  IDBVersionChangeRequestWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  EventListener get onblocked() { return LevelDom.wrapEventListener(_ptr.onblocked); }

  void set onblocked(EventListener value) { _ptr.onblocked = LevelDom.unwrap(value); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IFrameElementWrappingImplementation extends ElementWrappingImplementation implements IFrameElement {
  IFrameElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  Document get contentDocument() { return LevelDom.wrapDocument(_ptr.contentDocument); }

  Window get contentWindow() { return LevelDom.wrapWindow(_ptr.contentWindow); }

  String get frameBorder() { return _ptr.frameBorder; }

  void set frameBorder(String value) { _ptr.frameBorder = value; }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  String get longDesc() { return _ptr.longDesc; }

  void set longDesc(String value) { _ptr.longDesc = value; }

  String get marginHeight() { return _ptr.marginHeight; }

  void set marginHeight(String value) { _ptr.marginHeight = value; }

  String get marginWidth() { return _ptr.marginWidth; }

  void set marginWidth(String value) { _ptr.marginWidth = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get sandbox() { return _ptr.sandbox; }

  void set sandbox(String value) { _ptr.sandbox = value; }

  String get scrolling() { return _ptr.scrolling; }

  void set scrolling(String value) { _ptr.scrolling = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ImageDataWrappingImplementation extends DOMWrapperBase implements ImageData {
  ImageDataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CanvasPixelArray get data() { return LevelDom.wrapCanvasPixelArray(_ptr.data); }

  int get height() { return _ptr.height; }

  int get width() { return _ptr.width; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ImageElementWrappingImplementation extends ElementWrappingImplementation implements ImageElement {
  ImageElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get alt() { return _ptr.alt; }

  void set alt(String value) { _ptr.alt = value; }

  String get border() { return _ptr.border; }

  void set border(String value) { _ptr.border = value; }

  bool get complete() { return _ptr.complete; }

  String get crossOrigin() { return _ptr.crossOrigin; }

  void set crossOrigin(String value) { _ptr.crossOrigin = value; }

  int get height() { return _ptr.height; }

  void set height(int value) { _ptr.height = value; }

  int get hspace() { return _ptr.hspace; }

  void set hspace(int value) { _ptr.hspace = value; }

  bool get isMap() { return _ptr.isMap; }

  void set isMap(bool value) { _ptr.isMap = value; }

  String get longDesc() { return _ptr.longDesc; }

  void set longDesc(String value) { _ptr.longDesc = value; }

  String get lowsrc() { return _ptr.lowsrc; }

  void set lowsrc(String value) { _ptr.lowsrc = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  int get naturalHeight() { return _ptr.naturalHeight; }

  int get naturalWidth() { return _ptr.naturalWidth; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get useMap() { return _ptr.useMap; }

  void set useMap(String value) { _ptr.useMap = value; }

  int get vspace() { return _ptr.vspace; }

  void set vspace(int value) { _ptr.vspace = value; }

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }

  int get x() { return _ptr.x; }

  int get y() { return _ptr.y; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class InputElementWrappingImplementation extends ElementWrappingImplementation implements InputElement {
  InputElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accept() { return _ptr.accept; }

  void set accept(String value) { _ptr.accept = value; }

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get alt() { return _ptr.alt; }

  void set alt(String value) { _ptr.alt = value; }

  String get autocomplete() { return _ptr.autocomplete; }

  void set autocomplete(String value) { _ptr.autocomplete = value; }

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  bool get checked() { return _ptr.checked; }

  void set checked(bool value) { _ptr.checked = value; }

  bool get defaultChecked() { return _ptr.defaultChecked; }

  void set defaultChecked(bool value) { _ptr.defaultChecked = value; }

  String get defaultValue() { return _ptr.defaultValue; }

  void set defaultValue(String value) { _ptr.defaultValue = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FileList get files() { return LevelDom.wrapFileList(_ptr.files); }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get formAction() { return _ptr.formAction; }

  void set formAction(String value) { _ptr.formAction = value; }

  String get formEnctype() { return _ptr.formEnctype; }

  void set formEnctype(String value) { _ptr.formEnctype = value; }

  String get formMethod() { return _ptr.formMethod; }

  void set formMethod(String value) { _ptr.formMethod = value; }

  bool get formNoValidate() { return _ptr.formNoValidate; }

  void set formNoValidate(bool value) { _ptr.formNoValidate = value; }

  String get formTarget() { return _ptr.formTarget; }

  void set formTarget(String value) { _ptr.formTarget = value; }

  bool get incremental() { return _ptr.incremental; }

  void set incremental(bool value) { _ptr.incremental = value; }

  bool get indeterminate() { return _ptr.indeterminate; }

  void set indeterminate(bool value) { _ptr.indeterminate = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  Element get list() { return LevelDom.wrapElement(_ptr.list); }

  String get max() { return _ptr.max; }

  void set max(String value) { _ptr.max = value; }

  int get maxLength() { return _ptr.maxLength; }

  void set maxLength(int value) { _ptr.maxLength = value; }

  String get min() { return _ptr.min; }

  void set min(String value) { _ptr.min = value; }

  bool get multiple() { return _ptr.multiple; }

  void set multiple(bool value) { _ptr.multiple = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  EventListener get onwebkitspeechchange() { return LevelDom.wrapEventListener(_ptr.onwebkitspeechchange); }

  void set onwebkitspeechchange(EventListener value) { _ptr.onwebkitspeechchange = LevelDom.unwrap(value); }

  String get pattern() { return _ptr.pattern; }

  void set pattern(String value) { _ptr.pattern = value; }

  String get placeholder() { return _ptr.placeholder; }

  void set placeholder(String value) { _ptr.placeholder = value; }

  bool get readOnly() { return _ptr.readOnly; }

  void set readOnly(bool value) { _ptr.readOnly = value; }

  bool get required() { return _ptr.required; }

  void set required(bool value) { _ptr.required = value; }

  OptionElement get selectedOption() { return LevelDom.wrapOptionElement(_ptr.selectedOption); }

  String get selectionDirection() { return _ptr.selectionDirection; }

  void set selectionDirection(String value) { _ptr.selectionDirection = value; }

  int get selectionEnd() { return _ptr.selectionEnd; }

  void set selectionEnd(int value) { _ptr.selectionEnd = value; }

  int get selectionStart() { return _ptr.selectionStart; }

  void set selectionStart(int value) { _ptr.selectionStart = value; }

  int get size() { return _ptr.size; }

  void set size(int value) { _ptr.size = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get step() { return _ptr.step; }

  void set step(String value) { _ptr.step = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String get useMap() { return _ptr.useMap; }

  void set useMap(String value) { _ptr.useMap = value; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  Date get valueAsDate() { return _ptr.valueAsDate; }

  void set valueAsDate(Date value) { _ptr.valueAsDate = value; }

  num get valueAsNumber() { return _ptr.valueAsNumber; }

  void set valueAsNumber(num value) { _ptr.valueAsNumber = value; }

  bool get webkitGrammar() { return _ptr.webkitGrammar; }

  void set webkitGrammar(bool value) { _ptr.webkitGrammar = value; }

  bool get webkitSpeech() { return _ptr.webkitSpeech; }

  void set webkitSpeech(bool value) { _ptr.webkitSpeech = value; }

  bool get webkitdirectory() { return _ptr.webkitdirectory; }

  void set webkitdirectory(bool value) { _ptr.webkitdirectory = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void click() {
    _ptr.click();
    return;
  }

  void select() {
    _ptr.select();
    return;
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }

  void setSelectionRange(int start, int end, [String direction = null]) {
    if (direction === null) {
      _ptr.setSelectionRange(start, end);
      return;
    } else {
      _ptr.setSelectionRange(start, end, direction);
      return;
    }
  }

  void setValueForUser(String value) {
    _ptr.setValueForUser(value);
    return;
  }

  void stepDown([int n = null]) {
    if (n === null) {
      _ptr.stepDown();
      return;
    } else {
      _ptr.stepDown(n);
      return;
    }
  }

  void stepUp([int n = null]) {
    if (n === null) {
      _ptr.stepUp();
      return;
    } else {
      _ptr.stepUp(n);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Int16ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Int16Array {
  Int16ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Int16Array subarray(int start, [int end = null]) {
    if (end === null) {
      return LevelDom.wrapInt16Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapInt16Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Int32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Int32Array {
  Int32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Int32Array subarray(int start, [int end = null]) {
    if (end === null) {
      return LevelDom.wrapInt32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapInt32Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Int8ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Int8Array {
  Int8ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Int8Array subarray(int start, [int end = null]) {
    if (end === null) {
      return LevelDom.wrapInt8Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapInt8Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class KeygenElementWrappingImplementation extends ElementWrappingImplementation implements KeygenElement {
  KeygenElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  String get challenge() { return _ptr.challenge; }

  void set challenge(String value) { _ptr.challenge = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get keytype() { return _ptr.keytype; }

  void set keytype(String value) { _ptr.keytype = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LIElementWrappingImplementation extends ElementWrappingImplementation implements LIElement {
  LIElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  int get value() { return _ptr.value; }

  void set value(int value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LabelElementWrappingImplementation extends ElementWrappingImplementation implements LabelElement {
  LabelElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  Element get control() { return LevelDom.wrapElement(_ptr.control); }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get htmlFor() { return _ptr.htmlFor; }

  void set htmlFor(String value) { _ptr.htmlFor = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LegendElementWrappingImplementation extends ElementWrappingImplementation implements LegendElement {
  LegendElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LinkElementWrappingImplementation extends ElementWrappingImplementation implements LinkElement {
  LinkElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get charset() { return _ptr.charset; }

  void set charset(String value) { _ptr.charset = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  String get hreflang() { return _ptr.hreflang; }

  void set hreflang(String value) { _ptr.hreflang = value; }

  String get media() { return _ptr.media; }

  void set media(String value) { _ptr.media = value; }

  String get rel() { return _ptr.rel; }

  void set rel(String value) { _ptr.rel = value; }

  String get rev() { return _ptr.rev; }

  void set rev(String value) { _ptr.rev = value; }

  StyleSheet get sheet() { return LevelDom.wrapStyleSheet(_ptr.sheet); }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LocalMediaStreamWrappingImplementation extends MediaStreamWrappingImplementation implements LocalMediaStream {
  LocalMediaStreamWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void stop() {
    _ptr.stop();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LocationWrappingImplementation extends DOMWrapperBase implements Location {
  LocationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get hash() { return _ptr.hash; }

  void set hash(String value) { _ptr.hash = value; }

  String get host() { return _ptr.host; }

  void set host(String value) { _ptr.host = value; }

  String get hostname() { return _ptr.hostname; }

  void set hostname(String value) { _ptr.hostname = value; }

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  String get origin() { return _ptr.origin; }

  String get pathname() { return _ptr.pathname; }

  void set pathname(String value) { _ptr.pathname = value; }

  String get port() { return _ptr.port; }

  void set port(String value) { _ptr.port = value; }

  String get protocol() { return _ptr.protocol; }

  void set protocol(String value) { _ptr.protocol = value; }

  String get search() { return _ptr.search; }

  void set search(String value) { _ptr.search = value; }

  void assign(String url) {
    _ptr.assign(url);
    return;
  }

  String getParameter(String name) {
    return _ptr.getParameter(name);
  }

  void reload() {
    _ptr.reload();
    return;
  }

  void replace(String url) {
    _ptr.replace(url);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LoseContextWrappingImplementation extends DOMWrapperBase implements LoseContext {
  LoseContextWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void loseContext() {
    _ptr.loseContext();
    return;
  }

  void restoreContext() {
    _ptr.restoreContext();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MapElementWrappingImplementation extends ElementWrappingImplementation implements MapElement {
  MapElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ElementList get areas() { return LevelDom.wrapElementList(_ptr.areas); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MarqueeElementWrappingImplementation extends ElementWrappingImplementation implements MarqueeElement {
  MarqueeElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get behavior() { return _ptr.behavior; }

  void set behavior(String value) { _ptr.behavior = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  String get direction() { return _ptr.direction; }

  void set direction(String value) { _ptr.direction = value; }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  int get hspace() { return _ptr.hspace; }

  void set hspace(int value) { _ptr.hspace = value; }

  int get loop() { return _ptr.loop; }

  void set loop(int value) { _ptr.loop = value; }

  int get scrollAmount() { return _ptr.scrollAmount; }

  void set scrollAmount(int value) { _ptr.scrollAmount = value; }

  int get scrollDelay() { return _ptr.scrollDelay; }

  void set scrollDelay(int value) { _ptr.scrollDelay = value; }

  bool get trueSpeed() { return _ptr.trueSpeed; }

  void set trueSpeed(bool value) { _ptr.trueSpeed = value; }

  int get vspace() { return _ptr.vspace; }

  void set vspace(int value) { _ptr.vspace = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }

  void start() {
    _ptr.start();
    return;
  }

  void stop() {
    _ptr.stop();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaElementWrappingImplementation extends ElementWrappingImplementation implements MediaElement {
  MediaElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get autoplay() { return _ptr.autoplay; }

  void set autoplay(bool value) { _ptr.autoplay = value; }

  TimeRanges get buffered() { return LevelDom.wrapTimeRanges(_ptr.buffered); }

  bool get controls() { return _ptr.controls; }

  void set controls(bool value) { _ptr.controls = value; }

  String get currentSrc() { return _ptr.currentSrc; }

  num get currentTime() { return _ptr.currentTime; }

  void set currentTime(num value) { _ptr.currentTime = value; }

  bool get defaultMuted() { return _ptr.defaultMuted; }

  void set defaultMuted(bool value) { _ptr.defaultMuted = value; }

  num get defaultPlaybackRate() { return _ptr.defaultPlaybackRate; }

  void set defaultPlaybackRate(num value) { _ptr.defaultPlaybackRate = value; }

  num get duration() { return _ptr.duration; }

  bool get ended() { return _ptr.ended; }

  MediaError get error() { return LevelDom.wrapMediaError(_ptr.error); }

  num get initialTime() { return _ptr.initialTime; }

  bool get loop() { return _ptr.loop; }

  void set loop(bool value) { _ptr.loop = value; }

  bool get muted() { return _ptr.muted; }

  void set muted(bool value) { _ptr.muted = value; }

  int get networkState() { return _ptr.networkState; }

  bool get paused() { return _ptr.paused; }

  num get playbackRate() { return _ptr.playbackRate; }

  void set playbackRate(num value) { _ptr.playbackRate = value; }

  TimeRanges get played() { return LevelDom.wrapTimeRanges(_ptr.played); }

  String get preload() { return _ptr.preload; }

  void set preload(String value) { _ptr.preload = value; }

  int get readyState() { return _ptr.readyState; }

  TimeRanges get seekable() { return LevelDom.wrapTimeRanges(_ptr.seekable); }

  bool get seeking() { return _ptr.seeking; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  num get startTime() { return _ptr.startTime; }

  num get volume() { return _ptr.volume; }

  void set volume(num value) { _ptr.volume = value; }

  int get webkitAudioDecodedByteCount() { return _ptr.webkitAudioDecodedByteCount; }

  bool get webkitClosedCaptionsVisible() { return _ptr.webkitClosedCaptionsVisible; }

  void set webkitClosedCaptionsVisible(bool value) { _ptr.webkitClosedCaptionsVisible = value; }

  bool get webkitHasClosedCaptions() { return _ptr.webkitHasClosedCaptions; }

  bool get webkitPreservesPitch() { return _ptr.webkitPreservesPitch; }

  void set webkitPreservesPitch(bool value) { _ptr.webkitPreservesPitch = value; }

  int get webkitVideoDecodedByteCount() { return _ptr.webkitVideoDecodedByteCount; }

  String canPlayType(String type) {
    return _ptr.canPlayType(type);
  }

  void load() {
    _ptr.load();
    return;
  }

  void pause() {
    _ptr.pause();
    return;
  }

  void play() {
    _ptr.play();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaErrorWrappingImplementation extends DOMWrapperBase implements MediaError {
  MediaErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaListWrappingImplementation extends DOMWrapperBase implements MediaList {
  MediaListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  String get mediaText() { return _ptr.mediaText; }

  void set mediaText(String value) { _ptr.mediaText = value; }

  String operator[](int index) {
    return item(index);
  }

  void operator[]=(int index, String value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(String value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(String value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<String> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(String a, String b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(String element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(String element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  String removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  String last() {
    return this[length - 1];
  }

  void forEach(void f(String element)) {
    _Collections.forEach(this, f);
  }

  Collection<String> filter(bool f(String element)) {
    return _Collections.filter(this, new List<String>(), f);
  }

  bool every(bool f(String element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(String element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<String> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [String initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<String> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<String> iterator() {
    return new _FixedSizeListIterator<String>(this);
  }

  void appendMedium(String newMedium) {
    _ptr.appendMedium(newMedium);
    return;
  }

  void deleteMedium(String oldMedium) {
    _ptr.deleteMedium(oldMedium);
    return;
  }

  String item(int index) {
    return _ptr.item(index);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaQueryListListenerWrappingImplementation extends DOMWrapperBase implements MediaQueryListListener {
  MediaQueryListListenerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void queryChanged(MediaQueryList list) {
    _ptr.queryChanged(LevelDom.unwrap(list));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaQueryListWrappingImplementation extends DOMWrapperBase implements MediaQueryList {
  MediaQueryListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get matches() { return _ptr.matches; }

  String get media() { return _ptr.media; }

  void addListener(MediaQueryListListener listener) {
    _ptr.addListener(LevelDom.unwrap(listener));
    return;
  }

  void removeListener(MediaQueryListListener listener) {
    _ptr.removeListener(LevelDom.unwrap(listener));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaStreamListWrappingImplementation extends DOMWrapperBase implements MediaStreamList {
  MediaStreamListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  MediaStream item(int index) {
    return LevelDom.wrapMediaStream(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaStreamTrackListWrappingImplementation extends DOMWrapperBase implements MediaStreamTrackList {
  MediaStreamTrackListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  MediaStreamTrack item(int index) {
    return LevelDom.wrapMediaStreamTrack(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaStreamTrackWrappingImplementation extends DOMWrapperBase implements MediaStreamTrack {
  MediaStreamTrackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get enabled() { return _ptr.enabled; }

  void set enabled(bool value) { _ptr.enabled = value; }

  String get kind() { return _ptr.kind; }

  String get label() { return _ptr.label; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaStreamWrappingImplementation extends DOMWrapperBase implements MediaStream {
  MediaStreamWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get label() { return _ptr.label; }

  EventListener get onended() { return LevelDom.wrapEventListener(_ptr.onended); }

  void set onended(EventListener value) { _ptr.onended = LevelDom.unwrap(value); }

  int get readyState() { return _ptr.readyState; }

  MediaStreamTrackList get tracks() { return LevelDom.wrapMediaStreamTrackList(_ptr.tracks); }

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  bool dispatchEvent(Event event) {
    return _ptr.dispatchEvent(LevelDom.unwrap(event));
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MenuElementWrappingImplementation extends ElementWrappingImplementation implements MenuElement {
  MenuElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get compact() { return _ptr.compact; }

  void set compact(bool value) { _ptr.compact = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MessageChannelWrappingImplementation extends DOMWrapperBase implements MessageChannel {
  MessageChannelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  MessagePort get port1() { return LevelDom.wrapMessagePort(_ptr.port1); }

  MessagePort get port2() { return LevelDom.wrapMessagePort(_ptr.port2); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MetaElementWrappingImplementation extends ElementWrappingImplementation implements MetaElement {
  MetaElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get content() { return _ptr.content; }

  void set content(String value) { _ptr.content = value; }

  String get httpEquiv() { return _ptr.httpEquiv; }

  void set httpEquiv(String value) { _ptr.httpEquiv = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get scheme() { return _ptr.scheme; }

  void set scheme(String value) { _ptr.scheme = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MetadataCallbackWrappingImplementation extends DOMWrapperBase implements MetadataCallback {
  MetadataCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(Metadata metadata) {
    return _ptr.handleEvent(LevelDom.unwrap(metadata));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MetadataWrappingImplementation extends DOMWrapperBase implements Metadata {
  MetadataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Date get modificationTime() { return _ptr.modificationTime; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MeterElementWrappingImplementation extends ElementWrappingImplementation implements MeterElement {
  MeterElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  num get high() { return _ptr.high; }

  void set high(num value) { _ptr.high = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  num get low() { return _ptr.low; }

  void set low(num value) { _ptr.low = value; }

  num get max() { return _ptr.max; }

  void set max(num value) { _ptr.max = value; }

  num get min() { return _ptr.min; }

  void set min(num value) { _ptr.min = value; }

  num get optimum() { return _ptr.optimum; }

  void set optimum(num value) { _ptr.optimum = value; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ModElementWrappingImplementation extends ElementWrappingImplementation implements ModElement {
  ModElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get cite() { return _ptr.cite; }

  void set cite(String value) { _ptr.cite = value; }

  String get dateTime() { return _ptr.dateTime; }

  void set dateTime(String value) { _ptr.dateTime = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MutationRecordWrappingImplementation extends DOMWrapperBase implements MutationRecord {
  MutationRecordWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ElementList get addedNodes() { return LevelDom.wrapElementList(_ptr.addedNodes); }

  String get attributeName() { return _ptr.attributeName; }

  String get attributeNamespace() { return _ptr.attributeNamespace; }

  Node get nextSibling() { return LevelDom.wrapNode(_ptr.nextSibling); }

  String get oldValue() { return _ptr.oldValue; }

  Node get previousSibling() { return LevelDom.wrapNode(_ptr.previousSibling); }

  ElementList get removedNodes() { return LevelDom.wrapElementList(_ptr.removedNodes); }

  Node get target() { return LevelDom.wrapNode(_ptr.target); }

  String get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NavigatorUserMediaErrorCallbackWrappingImplementation extends DOMWrapperBase implements NavigatorUserMediaErrorCallback {
  NavigatorUserMediaErrorCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(NavigatorUserMediaError error) {
    return _ptr.handleEvent(LevelDom.unwrap(error));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NavigatorUserMediaErrorWrappingImplementation extends DOMWrapperBase implements NavigatorUserMediaError {
  NavigatorUserMediaErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NavigatorUserMediaSuccessCallbackWrappingImplementation extends DOMWrapperBase implements NavigatorUserMediaSuccessCallback {
  NavigatorUserMediaSuccessCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(LocalMediaStream stream) {
    return _ptr.handleEvent(LevelDom.unwrap(stream));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NavigatorWrappingImplementation extends DOMWrapperBase implements Navigator {
  NavigatorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get appCodeName() { return _ptr.appCodeName; }

  String get appName() { return _ptr.appName; }

  String get appVersion() { return _ptr.appVersion; }

  bool get cookieEnabled() { return _ptr.cookieEnabled; }

  String get language() { return _ptr.language; }

  DOMMimeTypeArray get mimeTypes() { return LevelDom.wrapDOMMimeTypeArray(_ptr.mimeTypes); }

  bool get onLine() { return _ptr.onLine; }

  String get platform() { return _ptr.platform; }

  DOMPluginArray get plugins() { return LevelDom.wrapDOMPluginArray(_ptr.plugins); }

  String get product() { return _ptr.product; }

  String get productSub() { return _ptr.productSub; }

  String get userAgent() { return _ptr.userAgent; }

  String get vendor() { return _ptr.vendor; }

  String get vendorSub() { return _ptr.vendorSub; }

  void getStorageUpdates() {
    _ptr.getStorageUpdates();
    return;
  }

  bool javaEnabled() {
    return _ptr.javaEnabled();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NotationWrappingImplementation extends NodeWrappingImplementation implements Notation {
  NotationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get publicId() { return _ptr.publicId; }

  String get systemId() { return _ptr.systemId; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NotificationCenterWrappingImplementation extends DOMWrapperBase implements NotificationCenter {
  NotificationCenterWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int checkPermission() {
    return _ptr.checkPermission();
  }

  Notification createHTMLNotification(String url) {
    return LevelDom.wrapNotification(_ptr.createHTMLNotification(url));
  }

  Notification createNotification(String iconUrl, String title, String body) {
    return LevelDom.wrapNotification(_ptr.createNotification(iconUrl, title, body));
  }

  void requestPermission(VoidCallback callback) {
    _ptr.requestPermission(LevelDom.unwrap(callback));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OESStandardDerivativesWrappingImplementation extends DOMWrapperBase implements OESStandardDerivatives {
  OESStandardDerivativesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OESTextureFloatWrappingImplementation extends DOMWrapperBase implements OESTextureFloat {
  OESTextureFloatWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OESVertexArrayObjectWrappingImplementation extends DOMWrapperBase implements OESVertexArrayObject {
  OESVertexArrayObjectWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    _ptr.bindVertexArrayOES(LevelDom.unwrap(arrayObject));
    return;
  }

  WebGLVertexArrayObjectOES createVertexArrayOES() {
    return LevelDom.wrapWebGLVertexArrayObjectOES(_ptr.createVertexArrayOES());
  }

  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    _ptr.deleteVertexArrayOES(LevelDom.unwrap(arrayObject));
    return;
  }

  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    return _ptr.isVertexArrayOES(LevelDom.unwrap(arrayObject));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OListElementWrappingImplementation extends ElementWrappingImplementation implements OListElement {
  OListElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get compact() { return _ptr.compact; }

  void set compact(bool value) { _ptr.compact = value; }

  int get start() { return _ptr.start; }

  void set start(int value) { _ptr.start = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ObjectElementWrappingImplementation extends ElementWrappingImplementation implements ObjectElement {
  ObjectElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get archive() { return _ptr.archive; }

  void set archive(String value) { _ptr.archive = value; }

  String get border() { return _ptr.border; }

  void set border(String value) { _ptr.border = value; }

  String get code() { return _ptr.code; }

  void set code(String value) { _ptr.code = value; }

  String get codeBase() { return _ptr.codeBase; }

  void set codeBase(String value) { _ptr.codeBase = value; }

  String get codeType() { return _ptr.codeType; }

  void set codeType(String value) { _ptr.codeType = value; }

  Document get contentDocument() { return LevelDom.wrapDocument(_ptr.contentDocument); }

  String get data() { return _ptr.data; }

  void set data(String value) { _ptr.data = value; }

  bool get declare() { return _ptr.declare; }

  void set declare(bool value) { _ptr.declare = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  int get hspace() { return _ptr.hspace; }

  void set hspace(int value) { _ptr.hspace = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get standby() { return _ptr.standby; }

  void set standby(String value) { _ptr.standby = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String get useMap() { return _ptr.useMap; }

  void set useMap(String value) { _ptr.useMap = value; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  int get vspace() { return _ptr.vspace; }

  void set vspace(int value) { _ptr.vspace = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OperationNotAllowedExceptionWrappingImplementation extends DOMWrapperBase implements OperationNotAllowedException {
  OperationNotAllowedExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OptGroupElementWrappingImplementation extends ElementWrappingImplementation implements OptGroupElement {
  OptGroupElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get label() { return _ptr.label; }

  void set label(String value) { _ptr.label = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OptionElementWrappingImplementation extends ElementWrappingImplementation implements OptionElement {
  OptionElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get defaultSelected() { return _ptr.defaultSelected; }

  void set defaultSelected(bool value) { _ptr.defaultSelected = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  int get index() { return _ptr.index; }

  String get label() { return _ptr.label; }

  void set label(String value) { _ptr.label = value; }

  bool get selected() { return _ptr.selected; }

  void set selected(bool value) { _ptr.selected = value; }

  String get text() { return _ptr.text; }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OutputElementWrappingImplementation extends ElementWrappingImplementation implements OutputElement {
  OutputElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get defaultValue() { return _ptr.defaultValue; }

  void set defaultValue(String value) { _ptr.defaultValue = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  DOMSettableTokenList get htmlFor() { return LevelDom.wrapDOMSettableTokenList(_ptr.htmlFor); }

  void set htmlFor(DOMSettableTokenList value) { _ptr.htmlFor = LevelDom.unwrap(value); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ParagraphElementWrappingImplementation extends ElementWrappingImplementation implements ParagraphElement {
  ParagraphElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ParamElementWrappingImplementation extends ElementWrappingImplementation implements ParamElement {
  ParamElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  String get valueType() { return _ptr.valueType; }

  void set valueType(String value) { _ptr.valueType = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PointWrappingImplementation extends DOMWrapperBase implements Point {
  PointWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PositionCallbackWrappingImplementation extends DOMWrapperBase implements PositionCallback {
  PositionCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(Geoposition position) {
    return _ptr.handleEvent(LevelDom.unwrap(position));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PositionErrorCallbackWrappingImplementation extends DOMWrapperBase implements PositionErrorCallback {
  PositionErrorCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(PositionError error) {
    return _ptr.handleEvent(LevelDom.unwrap(error));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PositionErrorWrappingImplementation extends DOMWrapperBase implements PositionError {
  PositionErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PreElementWrappingImplementation extends ElementWrappingImplementation implements PreElement {
  PreElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }

  bool get wrap() { return _ptr.wrap; }

  void set wrap(bool value) { _ptr.wrap = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ProcessingInstructionWrappingImplementation extends NodeWrappingImplementation implements ProcessingInstruction {
  ProcessingInstructionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get data() { return _ptr.data; }

  void set data(String value) { _ptr.data = value; }

  StyleSheet get sheet() { return LevelDom.wrapStyleSheet(_ptr.sheet); }

  String get target() { return _ptr.target; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ProgressElementWrappingImplementation extends ElementWrappingImplementation implements ProgressElement {
  ProgressElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  num get max() { return _ptr.max; }

  void set max(num value) { _ptr.max = value; }

  num get position() { return _ptr.position; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class QuoteElementWrappingImplementation extends ElementWrappingImplementation implements QuoteElement {
  QuoteElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get cite() { return _ptr.cite; }

  void set cite(String value) { _ptr.cite = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RGBColorWrappingImplementation extends DOMWrapperBase implements RGBColor {
  RGBColorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSPrimitiveValue get alpha() { return LevelDom.wrapCSSPrimitiveValue(_ptr.alpha); }

  CSSPrimitiveValue get blue() { return LevelDom.wrapCSSPrimitiveValue(_ptr.blue); }

  CSSPrimitiveValue get green() { return LevelDom.wrapCSSPrimitiveValue(_ptr.green); }

  CSSPrimitiveValue get red() { return LevelDom.wrapCSSPrimitiveValue(_ptr.red); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RangeExceptionWrappingImplementation extends DOMWrapperBase implements RangeException {
  RangeExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RangeWrappingImplementation extends DOMWrapperBase implements Range {
  RangeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get collapsed() { return _ptr.collapsed; }

  Node get commonAncestorContainer() { return LevelDom.wrapNode(_ptr.commonAncestorContainer); }

  Node get endContainer() { return LevelDom.wrapNode(_ptr.endContainer); }

  int get endOffset() { return _ptr.endOffset; }

  Node get startContainer() { return LevelDom.wrapNode(_ptr.startContainer); }

  int get startOffset() { return _ptr.startOffset; }

  String get text() { return _ptr.text; }

  DocumentFragment cloneContents() {
    return LevelDom.wrapDocumentFragment(_ptr.cloneContents());
  }

  Range cloneRange() {
    return LevelDom.wrapRange(_ptr.cloneRange());
  }

  void collapse(bool toStart) {
    _ptr.collapse(toStart);
    return;
  }

  int compareNode(Node refNode) {
    return _ptr.compareNode(LevelDom.unwrap(refNode));
  }

  int comparePoint(Node refNode, int offset) {
    return _ptr.comparePoint(LevelDom.unwrap(refNode), offset);
  }

  DocumentFragment createContextualFragment(String html) {
    return LevelDom.wrapDocumentFragment(_ptr.createContextualFragment(html));
  }

  void deleteContents() {
    _ptr.deleteContents();
    return;
  }

  void detach() {
    _ptr.detach();
    return;
  }

  void expand(String unit) {
    _ptr.expand(unit);
    return;
  }

  DocumentFragment extractContents() {
    return LevelDom.wrapDocumentFragment(_ptr.extractContents());
  }

  void insertNode(Node newNode) {
    _ptr.insertNode(LevelDom.unwrap(newNode));
    return;
  }

  bool intersectsNode(Node refNode) {
    return _ptr.intersectsNode(LevelDom.unwrap(refNode));
  }

  bool isPointInRange(Node refNode, int offset) {
    return _ptr.isPointInRange(LevelDom.unwrap(refNode), offset);
  }

  void selectNode(Node refNode) {
    _ptr.selectNode(LevelDom.unwrap(refNode));
    return;
  }

  void selectNodeContents(Node refNode) {
    _ptr.selectNodeContents(LevelDom.unwrap(refNode));
    return;
  }

  void setEnd(Node refNode, int offset) {
    _ptr.setEnd(LevelDom.unwrap(refNode), offset);
    return;
  }

  void setEndAfter(Node refNode) {
    _ptr.setEndAfter(LevelDom.unwrap(refNode));
    return;
  }

  void setEndBefore(Node refNode) {
    _ptr.setEndBefore(LevelDom.unwrap(refNode));
    return;
  }

  void setStart(Node refNode, int offset) {
    _ptr.setStart(LevelDom.unwrap(refNode), offset);
    return;
  }

  void setStartAfter(Node refNode) {
    _ptr.setStartAfter(LevelDom.unwrap(refNode));
    return;
  }

  void setStartBefore(Node refNode) {
    _ptr.setStartBefore(LevelDom.unwrap(refNode));
    return;
  }

  void surroundContents(Node newParent) {
    _ptr.surroundContents(LevelDom.unwrap(newParent));
    return;
  }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RectWrappingImplementation extends DOMWrapperBase implements Rect {
  RectWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSPrimitiveValue get bottom() { return LevelDom.wrapCSSPrimitiveValue(_ptr.bottom); }

  CSSPrimitiveValue get left() { return LevelDom.wrapCSSPrimitiveValue(_ptr.left); }

  CSSPrimitiveValue get right() { return LevelDom.wrapCSSPrimitiveValue(_ptr.right); }

  CSSPrimitiveValue get top() { return LevelDom.wrapCSSPrimitiveValue(_ptr.top); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ScreenWrappingImplementation extends DOMWrapperBase implements Screen {
  ScreenWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get availHeight() { return _ptr.availHeight; }

  int get availLeft() { return _ptr.availLeft; }

  int get availTop() { return _ptr.availTop; }

  int get availWidth() { return _ptr.availWidth; }

  int get colorDepth() { return _ptr.colorDepth; }

  int get height() { return _ptr.height; }

  int get pixelDepth() { return _ptr.pixelDepth; }

  int get width() { return _ptr.width; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ScriptElementWrappingImplementation extends ElementWrappingImplementation implements ScriptElement {
  ScriptElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get async() { return _ptr.async; }

  void set async(bool value) { _ptr.async = value; }

  String get charset() { return _ptr.charset; }

  void set charset(String value) { _ptr.charset = value; }

  bool get defer() { return _ptr.defer; }

  void set defer(bool value) { _ptr.defer = value; }

  String get event() { return _ptr.event; }

  void set event(String value) { _ptr.event = value; }

  String get htmlFor() { return _ptr.htmlFor; }

  void set htmlFor(String value) { _ptr.htmlFor = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get text() { return _ptr.text; }

  void set text(String value) { _ptr.text = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SelectElementWrappingImplementation extends ElementWrappingImplementation implements SelectElement {
  SelectElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  int get length() { return _ptr.length; }

  void set length(int value) { _ptr.length = value; }

  bool get multiple() { return _ptr.multiple; }

  void set multiple(bool value) { _ptr.multiple = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  ElementList get options() { return LevelDom.wrapElementList(_ptr.options); }

  bool get required() { return _ptr.required; }

  void set required(bool value) { _ptr.required = value; }

  int get selectedIndex() { return _ptr.selectedIndex; }

  void set selectedIndex(int value) { _ptr.selectedIndex = value; }

  int get size() { return _ptr.size; }

  void set size(int value) { _ptr.size = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  void add(Element element, Element before) {
    _ptr.add(LevelDom.unwrap(element), LevelDom.unwrap(before));
    return;
  }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  Node item(int index) {
    return LevelDom.wrapNode(_ptr.item(index));
  }

  Node namedItem(String name) {
    return LevelDom.wrapNode(_ptr.namedItem(name));
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SourceElementWrappingImplementation extends ElementWrappingImplementation implements SourceElement {
  SourceElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get media() { return _ptr.media; }

  void set media(String value) { _ptr.media = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SpanElementWrappingImplementation extends ElementWrappingImplementation implements SpanElement {
  SpanElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SpeechInputEventWrappingImplementation extends EventWrappingImplementation implements SpeechInputEvent {
  SpeechInputEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SpeechInputResultList get results() { return LevelDom.wrapSpeechInputResultList(_ptr.results); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SpeechInputResultListWrappingImplementation extends DOMWrapperBase implements SpeechInputResultList {
  SpeechInputResultListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  SpeechInputResult item(int index) {
    return LevelDom.wrapSpeechInputResult(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SpeechInputResultWrappingImplementation extends DOMWrapperBase implements SpeechInputResult {
  SpeechInputResultWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get confidence() { return _ptr.confidence; }

  String get utterance() { return _ptr.utterance; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageInfoErrorCallbackWrappingImplementation extends DOMWrapperBase implements StorageInfoErrorCallback {
  StorageInfoErrorCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(DOMException error) {
    return _ptr.handleEvent(LevelDom.unwrap(error));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageInfoQuotaCallbackWrappingImplementation extends DOMWrapperBase implements StorageInfoQuotaCallback {
  StorageInfoQuotaCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(int grantedQuotaInBytes) {
    return _ptr.handleEvent(grantedQuotaInBytes);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageInfoUsageCallbackWrappingImplementation extends DOMWrapperBase implements StorageInfoUsageCallback {
  StorageInfoUsageCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(int currentUsageInBytes, int currentQuotaInBytes) {
    return _ptr.handleEvent(currentUsageInBytes, currentQuotaInBytes);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageInfoWrappingImplementation extends DOMWrapperBase implements StorageInfo {
  StorageInfoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback = null, StorageInfoErrorCallback errorCallback = null]) {
    if (usageCallback === null) {
      if (errorCallback === null) {
        _ptr.queryUsageAndQuota(storageType);
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.queryUsageAndQuota(storageType, LevelDom.unwrap(usageCallback));
        return;
      } else {
        _ptr.queryUsageAndQuota(storageType, LevelDom.unwrap(usageCallback), LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback = null, StorageInfoErrorCallback errorCallback = null]) {
    if (quotaCallback === null) {
      if (errorCallback === null) {
        _ptr.requestQuota(storageType, newQuotaInBytes);
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.requestQuota(storageType, newQuotaInBytes, LevelDom.unwrap(quotaCallback));
        return;
      } else {
        _ptr.requestQuota(storageType, newQuotaInBytes, LevelDom.unwrap(quotaCallback), LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageWrappingImplementation extends DOMWrapperBase implements Storage {
  StorageWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void clear() {
    _ptr.clear();
    return;
  }

  String getItem(String key) {
    return _ptr.getItem(key);
  }

  String key(int index) {
    return _ptr.key(index);
  }

  void removeItem(String key) {
    _ptr.removeItem(key);
    return;
  }

  void setItem(String key, String data) {
    _ptr.setItem(key, data);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StringCallbackWrappingImplementation extends DOMWrapperBase implements StringCallback {
  StringCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(String data) {
    return _ptr.handleEvent(data);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleElementWrappingImplementation extends ElementWrappingImplementation implements StyleElement {
  StyleElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get media() { return _ptr.media; }

  void set media(String value) { _ptr.media = value; }

  StyleSheet get sheet() { return LevelDom.wrapStyleSheet(_ptr.sheet); }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleMediaWrappingImplementation extends DOMWrapperBase implements StyleMedia {
  StyleMediaWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get type() { return _ptr.type; }

  bool matchMedium(String mediaquery) {
    return _ptr.matchMedium(mediaquery);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleSheetListWrappingImplementation extends DOMWrapperBase implements StyleSheetList {
  StyleSheetListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  StyleSheet operator[](int index) {
    return item(index);
  }

  void operator[]=(int index, StyleSheet value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(StyleSheet value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(StyleSheet value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<StyleSheet> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(StyleSheet a, StyleSheet b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(StyleSheet element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(StyleSheet element, [int start = null]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  StyleSheet removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  StyleSheet last() {
    return this[length - 1];
  }

  void forEach(void f(StyleSheet element)) {
    _Collections.forEach(this, f);
  }

  Collection<StyleSheet> filter(bool f(StyleSheet element)) {
    return _Collections.filter(this, new List<StyleSheet>(), f);
  }

  bool every(bool f(StyleSheet element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(StyleSheet element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<StyleSheet> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [StyleSheet initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<StyleSheet> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<StyleSheet> iterator() {
    return new _FixedSizeListIterator<StyleSheet>(this);
  }

  StyleSheet item(int index) {
    return LevelDom.wrapStyleSheet(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleSheetWrappingImplementation extends DOMWrapperBase implements StyleSheet {
  StyleSheetWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get href() { return _ptr.href; }

  MediaList get media() { return LevelDom.wrapMediaList(_ptr.media); }

  Node get ownerNode() { return LevelDom.wrapNode(_ptr.ownerNode); }

  StyleSheet get parentStyleSheet() { return LevelDom.wrapStyleSheet(_ptr.parentStyleSheet); }

  String get title() { return _ptr.title; }

  String get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableCaptionElementWrappingImplementation extends ElementWrappingImplementation implements TableCaptionElement {
  TableCaptionElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableCellElementWrappingImplementation extends ElementWrappingImplementation implements TableCellElement {
  TableCellElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get abbr() { return _ptr.abbr; }

  void set abbr(String value) { _ptr.abbr = value; }

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get axis() { return _ptr.axis; }

  void set axis(String value) { _ptr.axis = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  int get cellIndex() { return _ptr.cellIndex; }

  String get ch() { return _ptr.ch; }

  void set ch(String value) { _ptr.ch = value; }

  String get chOff() { return _ptr.chOff; }

  void set chOff(String value) { _ptr.chOff = value; }

  int get colSpan() { return _ptr.colSpan; }

  void set colSpan(int value) { _ptr.colSpan = value; }

  String get headers() { return _ptr.headers; }

  void set headers(String value) { _ptr.headers = value; }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  bool get noWrap() { return _ptr.noWrap; }

  void set noWrap(bool value) { _ptr.noWrap = value; }

  int get rowSpan() { return _ptr.rowSpan; }

  void set rowSpan(int value) { _ptr.rowSpan = value; }

  String get scope() { return _ptr.scope; }

  void set scope(String value) { _ptr.scope = value; }

  String get vAlign() { return _ptr.vAlign; }

  void set vAlign(String value) { _ptr.vAlign = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableColElementWrappingImplementation extends ElementWrappingImplementation implements TableColElement {
  TableColElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get ch() { return _ptr.ch; }

  void set ch(String value) { _ptr.ch = value; }

  String get chOff() { return _ptr.chOff; }

  void set chOff(String value) { _ptr.chOff = value; }

  int get span() { return _ptr.span; }

  void set span(int value) { _ptr.span = value; }

  String get vAlign() { return _ptr.vAlign; }

  void set vAlign(String value) { _ptr.vAlign = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableElementWrappingImplementation extends ElementWrappingImplementation implements TableElement {
  TableElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  String get border() { return _ptr.border; }

  void set border(String value) { _ptr.border = value; }

  TableCaptionElement get caption() { return LevelDom.wrapTableCaptionElement(_ptr.caption); }

  void set caption(TableCaptionElement value) { _ptr.caption = LevelDom.unwrap(value); }

  String get cellPadding() { return _ptr.cellPadding; }

  void set cellPadding(String value) { _ptr.cellPadding = value; }

  String get cellSpacing() { return _ptr.cellSpacing; }

  void set cellSpacing(String value) { _ptr.cellSpacing = value; }

  String get frame() { return _ptr.frame; }

  void set frame(String value) { _ptr.frame = value; }

  ElementList get rows() { return LevelDom.wrapElementList(_ptr.rows); }

  String get rules() { return _ptr.rules; }

  void set rules(String value) { _ptr.rules = value; }

  String get summary() { return _ptr.summary; }

  void set summary(String value) { _ptr.summary = value; }

  ElementList get tBodies() { return LevelDom.wrapElementList(_ptr.tBodies); }

  TableSectionElement get tFoot() { return LevelDom.wrapTableSectionElement(_ptr.tFoot); }

  void set tFoot(TableSectionElement value) { _ptr.tFoot = LevelDom.unwrap(value); }

  TableSectionElement get tHead() { return LevelDom.wrapTableSectionElement(_ptr.tHead); }

  void set tHead(TableSectionElement value) { _ptr.tHead = LevelDom.unwrap(value); }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }

  Element createCaption() {
    return LevelDom.wrapElement(_ptr.createCaption());
  }

  Element createTFoot() {
    return LevelDom.wrapElement(_ptr.createTFoot());
  }

  Element createTHead() {
    return LevelDom.wrapElement(_ptr.createTHead());
  }

  void deleteCaption() {
    _ptr.deleteCaption();
    return;
  }

  void deleteRow(int index) {
    _ptr.deleteRow(index);
    return;
  }

  void deleteTFoot() {
    _ptr.deleteTFoot();
    return;
  }

  void deleteTHead() {
    _ptr.deleteTHead();
    return;
  }

  Element insertRow(int index) {
    return LevelDom.wrapElement(_ptr.insertRow(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableRowElementWrappingImplementation extends ElementWrappingImplementation implements TableRowElement {
  TableRowElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  ElementList get cells() { return LevelDom.wrapElementList(_ptr.cells); }

  String get ch() { return _ptr.ch; }

  void set ch(String value) { _ptr.ch = value; }

  String get chOff() { return _ptr.chOff; }

  void set chOff(String value) { _ptr.chOff = value; }

  int get rowIndex() { return _ptr.rowIndex; }

  int get sectionRowIndex() { return _ptr.sectionRowIndex; }

  String get vAlign() { return _ptr.vAlign; }

  void set vAlign(String value) { _ptr.vAlign = value; }

  void deleteCell(int index) {
    _ptr.deleteCell(index);
    return;
  }

  Element insertCell(int index) {
    return LevelDom.wrapElement(_ptr.insertCell(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableSectionElementWrappingImplementation extends ElementWrappingImplementation implements TableSectionElement {
  TableSectionElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get ch() { return _ptr.ch; }

  void set ch(String value) { _ptr.ch = value; }

  String get chOff() { return _ptr.chOff; }

  void set chOff(String value) { _ptr.chOff = value; }

  ElementList get rows() { return LevelDom.wrapElementList(_ptr.rows); }

  String get vAlign() { return _ptr.vAlign; }

  void set vAlign(String value) { _ptr.vAlign = value; }

  void deleteRow(int index) {
    _ptr.deleteRow(index);
    return;
  }

  Element insertRow(int index) {
    return LevelDom.wrapElement(_ptr.insertRow(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TextAreaElementWrappingImplementation extends ElementWrappingImplementation implements TextAreaElement {
  TextAreaElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  int get cols() { return _ptr.cols; }

  void set cols(int value) { _ptr.cols = value; }

  String get defaultValue() { return _ptr.defaultValue; }

  void set defaultValue(String value) { _ptr.defaultValue = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  int get maxLength() { return _ptr.maxLength; }

  void set maxLength(int value) { _ptr.maxLength = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get placeholder() { return _ptr.placeholder; }

  void set placeholder(String value) { _ptr.placeholder = value; }

  bool get readOnly() { return _ptr.readOnly; }

  void set readOnly(bool value) { _ptr.readOnly = value; }

  bool get required() { return _ptr.required; }

  void set required(bool value) { _ptr.required = value; }

  int get rows() { return _ptr.rows; }

  void set rows(int value) { _ptr.rows = value; }

  String get selectionDirection() { return _ptr.selectionDirection; }

  void set selectionDirection(String value) { _ptr.selectionDirection = value; }

  int get selectionEnd() { return _ptr.selectionEnd; }

  void set selectionEnd(int value) { _ptr.selectionEnd = value; }

  int get selectionStart() { return _ptr.selectionStart; }

  void set selectionStart(int value) { _ptr.selectionStart = value; }

  int get textLength() { return _ptr.textLength; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  String get wrap() { return _ptr.wrap; }

  void set wrap(String value) { _ptr.wrap = value; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void select() {
    _ptr.select();
    return;
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }

  void setSelectionRange(int start, int end, [String direction = null]) {
    if (direction === null) {
      _ptr.setSelectionRange(start, end);
      return;
    } else {
      _ptr.setSelectionRange(start, end, direction);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TextMetricsWrappingImplementation extends DOMWrapperBase implements TextMetrics {
  TextMetricsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get width() { return _ptr.width; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TimeRangesWrappingImplementation extends DOMWrapperBase implements TimeRanges {
  TimeRangesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  num end(int index) {
    return _ptr.end(index);
  }

  num start(int index) {
    return _ptr.start(index);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TitleElementWrappingImplementation extends ElementWrappingImplementation implements TitleElement {
  TitleElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get text() { return _ptr.text; }

  void set text(String value) { _ptr.text = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TouchListWrappingImplementation extends DOMWrapperBase implements TouchList {
  TouchListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Touch operator[](int index) {
    return item(index);
  }

  void operator[]=(int index, Touch value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(Touch value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(Touch value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<Touch> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(Touch a, Touch b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(Touch element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Touch element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  Touch removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  Touch last() {
    return this[length - 1];
  }

  void forEach(void f(Touch element)) {
    _Collections.forEach(this, f);
  }

  Collection<Touch> filter(bool f(Touch element)) {
    return _Collections.filter(this, new List<Touch>(), f);
  }

  bool every(bool f(Touch element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(Touch element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<Touch> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [Touch initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<Touch> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<Touch> iterator() {
    return new _FixedSizeListIterator<Touch>(this);
  }

  Touch item(int index) {
    return LevelDom.wrapTouch(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TouchWrappingImplementation extends DOMWrapperBase implements Touch {
  TouchWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get clientX() { return _ptr.clientX; }

  int get clientY() { return _ptr.clientY; }

  int get identifier() { return _ptr.identifier; }

  int get pageX() { return _ptr.pageX; }

  int get pageY() { return _ptr.pageY; }

  int get screenX() { return _ptr.screenX; }

  int get screenY() { return _ptr.screenY; }

  EventTarget get target() { return LevelDom.wrapEventTarget(_ptr.target); }

  num get webkitForce() { return _ptr.webkitForce; }

  int get webkitRadiusX() { return _ptr.webkitRadiusX; }

  int get webkitRadiusY() { return _ptr.webkitRadiusY; }

  num get webkitRotationAngle() { return _ptr.webkitRotationAngle; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TrackElementWrappingImplementation extends ElementWrappingImplementation implements TrackElement {
  TrackElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get isDefault() { return _ptr.isDefault; }

  void set isDefault(bool value) { _ptr.isDefault = value; }

  String get kind() { return _ptr.kind; }

  void set kind(String value) { _ptr.kind = value; }

  String get label() { return _ptr.label; }

  void set label(String value) { _ptr.label = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get srclang() { return _ptr.srclang; }

  void set srclang(String value) { _ptr.srclang = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class UListElementWrappingImplementation extends ElementWrappingImplementation implements UListElement {
  UListElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get compact() { return _ptr.compact; }

  void set compact(bool value) { _ptr.compact = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Uint16ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Uint16Array {
  Uint16ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Uint16Array subarray(int start, [int end = null]) {
    if (end === null) {
      return LevelDom.wrapUint16Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapUint16Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Uint32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Uint32Array {
  Uint32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Uint32Array subarray(int start, [int end = null]) {
    if (end === null) {
      return LevelDom.wrapUint32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapUint32Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Uint8ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Uint8Array {
  Uint8ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Uint8Array subarray(int start, [int end = null]) {
    if (end === null) {
      return LevelDom.wrapUint8Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapUint8Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class UnknownElementWrappingImplementation extends ElementWrappingImplementation implements UnknownElement {
  UnknownElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ValidityStateWrappingImplementation extends DOMWrapperBase implements ValidityState {
  ValidityStateWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get customError() { return _ptr.customError; }

  bool get patternMismatch() { return _ptr.patternMismatch; }

  bool get rangeOverflow() { return _ptr.rangeOverflow; }

  bool get rangeUnderflow() { return _ptr.rangeUnderflow; }

  bool get stepMismatch() { return _ptr.stepMismatch; }

  bool get tooLong() { return _ptr.tooLong; }

  bool get typeMismatch() { return _ptr.typeMismatch; }

  bool get valid() { return _ptr.valid; }

  bool get valueMissing() { return _ptr.valueMissing; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class VideoElementWrappingImplementation extends MediaElementWrappingImplementation implements VideoElement {
  VideoElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get height() { return _ptr.height; }

  void set height(int value) { _ptr.height = value; }

  String get poster() { return _ptr.poster; }

  void set poster(String value) { _ptr.poster = value; }

  int get videoHeight() { return _ptr.videoHeight; }

  int get videoWidth() { return _ptr.videoWidth; }

  int get webkitDecodedFrameCount() { return _ptr.webkitDecodedFrameCount; }

  bool get webkitDisplayingFullscreen() { return _ptr.webkitDisplayingFullscreen; }

  int get webkitDroppedFrameCount() { return _ptr.webkitDroppedFrameCount; }

  bool get webkitSupportsFullscreen() { return _ptr.webkitSupportsFullscreen; }

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }

  void webkitEnterFullScreen() {
    _ptr.webkitEnterFullScreen();
    return;
  }

  void webkitEnterFullscreen() {
    _ptr.webkitEnterFullscreen();
    return;
  }

  void webkitExitFullScreen() {
    _ptr.webkitExitFullScreen();
    return;
  }

  void webkitExitFullscreen() {
    _ptr.webkitExitFullscreen();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class VoidCallbackWrappingImplementation extends DOMWrapperBase implements VoidCallback {
  VoidCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void handleEvent() {
    _ptr.handleEvent();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLActiveInfoWrappingImplementation extends DOMWrapperBase implements WebGLActiveInfo {
  WebGLActiveInfoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  int get size() { return _ptr.size; }

  int get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLBufferWrappingImplementation extends DOMWrapperBase implements WebGLBuffer {
  WebGLBufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLContextAttributesWrappingImplementation extends DOMWrapperBase implements WebGLContextAttributes {
  WebGLContextAttributesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get alpha() { return _ptr.alpha; }

  void set alpha(bool value) { _ptr.alpha = value; }

  bool get antialias() { return _ptr.antialias; }

  void set antialias(bool value) { _ptr.antialias = value; }

  bool get depth() { return _ptr.depth; }

  void set depth(bool value) { _ptr.depth = value; }

  bool get premultipliedAlpha() { return _ptr.premultipliedAlpha; }

  void set premultipliedAlpha(bool value) { _ptr.premultipliedAlpha = value; }

  bool get preserveDrawingBuffer() { return _ptr.preserveDrawingBuffer; }

  void set preserveDrawingBuffer(bool value) { _ptr.preserveDrawingBuffer = value; }

  bool get stencil() { return _ptr.stencil; }

  void set stencil(bool value) { _ptr.stencil = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLContextEventWrappingImplementation extends EventWrappingImplementation implements WebGLContextEvent {
  WebGLContextEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get statusMessage() { return _ptr.statusMessage; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLFramebufferWrappingImplementation extends DOMWrapperBase implements WebGLFramebuffer {
  WebGLFramebufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLProgramWrappingImplementation extends DOMWrapperBase implements WebGLProgram {
  WebGLProgramWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLRenderbufferWrappingImplementation extends DOMWrapperBase implements WebGLRenderbuffer {
  WebGLRenderbufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLRenderingContextWrappingImplementation extends CanvasRenderingContextWrappingImplementation implements WebGLRenderingContext {
  WebGLRenderingContextWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get drawingBufferHeight() { return _ptr.drawingBufferHeight; }

  int get drawingBufferWidth() { return _ptr.drawingBufferWidth; }

  void activeTexture(int texture) {
    _ptr.activeTexture(texture);
    return;
  }

  void attachShader(WebGLProgram program, WebGLShader shader) {
    _ptr.attachShader(LevelDom.unwrap(program), LevelDom.unwrap(shader));
    return;
  }

  void bindAttribLocation(WebGLProgram program, int index, String name) {
    _ptr.bindAttribLocation(LevelDom.unwrap(program), index, name);
    return;
  }

  void bindBuffer(int target, WebGLBuffer buffer) {
    _ptr.bindBuffer(target, LevelDom.unwrap(buffer));
    return;
  }

  void bindFramebuffer(int target, WebGLFramebuffer framebuffer) {
    _ptr.bindFramebuffer(target, LevelDom.unwrap(framebuffer));
    return;
  }

  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer) {
    _ptr.bindRenderbuffer(target, LevelDom.unwrap(renderbuffer));
    return;
  }

  void bindTexture(int target, WebGLTexture texture) {
    _ptr.bindTexture(target, LevelDom.unwrap(texture));
    return;
  }

  void blendColor(num red, num green, num blue, num alpha) {
    _ptr.blendColor(red, green, blue, alpha);
    return;
  }

  void blendEquation(int mode) {
    _ptr.blendEquation(mode);
    return;
  }

  void blendEquationSeparate(int modeRGB, int modeAlpha) {
    _ptr.blendEquationSeparate(modeRGB, modeAlpha);
    return;
  }

  void blendFunc(int sfactor, int dfactor) {
    _ptr.blendFunc(sfactor, dfactor);
    return;
  }

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) {
    _ptr.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
    return;
  }

  void bufferData(int target, var data_OR_size, int usage) {
    if (data_OR_size is ArrayBuffer) {
      _ptr.bufferData(target, LevelDom.unwrap(data_OR_size), usage);
      return;
    } else {
      if (data_OR_size is ArrayBufferView) {
        _ptr.bufferData(target, LevelDom.unwrap(data_OR_size), usage);
        return;
      } else {
        if (data_OR_size is int) {
          _ptr.bufferData(target, LevelDom.unwrap(data_OR_size), usage);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void bufferSubData(int target, int offset, var data) {
    if (data is ArrayBuffer) {
      _ptr.bufferSubData(target, offset, LevelDom.unwrap(data));
      return;
    } else {
      if (data is ArrayBufferView) {
        _ptr.bufferSubData(target, offset, LevelDom.unwrap(data));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  int checkFramebufferStatus(int target) {
    return _ptr.checkFramebufferStatus(target);
  }

  void clear(int mask) {
    _ptr.clear(mask);
    return;
  }

  void clearColor(num red, num green, num blue, num alpha) {
    _ptr.clearColor(red, green, blue, alpha);
    return;
  }

  void clearDepth(num depth) {
    _ptr.clearDepth(depth);
    return;
  }

  void clearStencil(int s) {
    _ptr.clearStencil(s);
    return;
  }

  void colorMask(bool red, bool green, bool blue, bool alpha) {
    _ptr.colorMask(red, green, blue, alpha);
    return;
  }

  void compileShader(WebGLShader shader) {
    _ptr.compileShader(LevelDom.unwrap(shader));
    return;
  }

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) {
    _ptr.copyTexImage2D(target, level, internalformat, x, y, width, height, border);
    return;
  }

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) {
    _ptr.copyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
    return;
  }

  WebGLBuffer createBuffer() {
    return LevelDom.wrapWebGLBuffer(_ptr.createBuffer());
  }

  WebGLFramebuffer createFramebuffer() {
    return LevelDom.wrapWebGLFramebuffer(_ptr.createFramebuffer());
  }

  WebGLProgram createProgram() {
    return LevelDom.wrapWebGLProgram(_ptr.createProgram());
  }

  WebGLRenderbuffer createRenderbuffer() {
    return LevelDom.wrapWebGLRenderbuffer(_ptr.createRenderbuffer());
  }

  WebGLShader createShader(int type) {
    return LevelDom.wrapWebGLShader(_ptr.createShader(type));
  }

  WebGLTexture createTexture() {
    return LevelDom.wrapWebGLTexture(_ptr.createTexture());
  }

  void cullFace(int mode) {
    _ptr.cullFace(mode);
    return;
  }

  void deleteBuffer(WebGLBuffer buffer) {
    _ptr.deleteBuffer(LevelDom.unwrap(buffer));
    return;
  }

  void deleteFramebuffer(WebGLFramebuffer framebuffer) {
    _ptr.deleteFramebuffer(LevelDom.unwrap(framebuffer));
    return;
  }

  void deleteProgram(WebGLProgram program) {
    _ptr.deleteProgram(LevelDom.unwrap(program));
    return;
  }

  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer) {
    _ptr.deleteRenderbuffer(LevelDom.unwrap(renderbuffer));
    return;
  }

  void deleteShader(WebGLShader shader) {
    _ptr.deleteShader(LevelDom.unwrap(shader));
    return;
  }

  void deleteTexture(WebGLTexture texture) {
    _ptr.deleteTexture(LevelDom.unwrap(texture));
    return;
  }

  void depthFunc(int func) {
    _ptr.depthFunc(func);
    return;
  }

  void depthMask(bool flag) {
    _ptr.depthMask(flag);
    return;
  }

  void depthRange(num zNear, num zFar) {
    _ptr.depthRange(zNear, zFar);
    return;
  }

  void detachShader(WebGLProgram program, WebGLShader shader) {
    _ptr.detachShader(LevelDom.unwrap(program), LevelDom.unwrap(shader));
    return;
  }

  void disable(int cap) {
    _ptr.disable(cap);
    return;
  }

  void disableVertexAttribArray(int index) {
    _ptr.disableVertexAttribArray(index);
    return;
  }

  void drawArrays(int mode, int first, int count) {
    _ptr.drawArrays(mode, first, count);
    return;
  }

  void drawElements(int mode, int count, int type, int offset) {
    _ptr.drawElements(mode, count, type, offset);
    return;
  }

  void enable(int cap) {
    _ptr.enable(cap);
    return;
  }

  void enableVertexAttribArray(int index) {
    _ptr.enableVertexAttribArray(index);
    return;
  }

  void finish() {
    _ptr.finish();
    return;
  }

  void flush() {
    _ptr.flush();
    return;
  }

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, WebGLRenderbuffer renderbuffer) {
    _ptr.framebufferRenderbuffer(target, attachment, renderbuffertarget, LevelDom.unwrap(renderbuffer));
    return;
  }

  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level) {
    _ptr.framebufferTexture2D(target, attachment, textarget, LevelDom.unwrap(texture), level);
    return;
  }

  void frontFace(int mode) {
    _ptr.frontFace(mode);
    return;
  }

  void generateMipmap(int target) {
    _ptr.generateMipmap(target);
    return;
  }

  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index) {
    return LevelDom.wrapWebGLActiveInfo(_ptr.getActiveAttrib(LevelDom.unwrap(program), index));
  }

  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index) {
    return LevelDom.wrapWebGLActiveInfo(_ptr.getActiveUniform(LevelDom.unwrap(program), index));
  }

  void getAttachedShaders(WebGLProgram program) {
    _ptr.getAttachedShaders(LevelDom.unwrap(program));
    return;
  }

  int getAttribLocation(WebGLProgram program, String name) {
    return _ptr.getAttribLocation(LevelDom.unwrap(program), name);
  }

  void getBufferParameter() {
    _ptr.getBufferParameter();
    return;
  }

  WebGLContextAttributes getContextAttributes() {
    return LevelDom.wrapWebGLContextAttributes(_ptr.getContextAttributes());
  }

  int getError() {
    return _ptr.getError();
  }

  void getExtension(String name) {
    _ptr.getExtension(name);
    return;
  }

  void getFramebufferAttachmentParameter() {
    _ptr.getFramebufferAttachmentParameter();
    return;
  }

  void getParameter() {
    _ptr.getParameter();
    return;
  }

  String getProgramInfoLog(WebGLProgram program) {
    return _ptr.getProgramInfoLog(LevelDom.unwrap(program));
  }

  void getProgramParameter() {
    _ptr.getProgramParameter();
    return;
  }

  void getRenderbufferParameter() {
    _ptr.getRenderbufferParameter();
    return;
  }

  String getShaderInfoLog(WebGLShader shader) {
    return _ptr.getShaderInfoLog(LevelDom.unwrap(shader));
  }

  void getShaderParameter() {
    _ptr.getShaderParameter();
    return;
  }

  String getShaderSource(WebGLShader shader) {
    return _ptr.getShaderSource(LevelDom.unwrap(shader));
  }

  void getSupportedExtensions() {
    _ptr.getSupportedExtensions();
    return;
  }

  void getTexParameter() {
    _ptr.getTexParameter();
    return;
  }

  void getUniform() {
    _ptr.getUniform();
    return;
  }

  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) {
    return LevelDom.wrapWebGLUniformLocation(_ptr.getUniformLocation(LevelDom.unwrap(program), name));
  }

  void getVertexAttrib() {
    _ptr.getVertexAttrib();
    return;
  }

  int getVertexAttribOffset(int index, int pname) {
    return _ptr.getVertexAttribOffset(index, pname);
  }

  void hint(int target, int mode) {
    _ptr.hint(target, mode);
    return;
  }

  bool isBuffer(WebGLBuffer buffer) {
    return _ptr.isBuffer(LevelDom.unwrap(buffer));
  }

  bool isContextLost() {
    return _ptr.isContextLost();
  }

  bool isEnabled(int cap) {
    return _ptr.isEnabled(cap);
  }

  bool isFramebuffer(WebGLFramebuffer framebuffer) {
    return _ptr.isFramebuffer(LevelDom.unwrap(framebuffer));
  }

  bool isProgram(WebGLProgram program) {
    return _ptr.isProgram(LevelDom.unwrap(program));
  }

  bool isRenderbuffer(WebGLRenderbuffer renderbuffer) {
    return _ptr.isRenderbuffer(LevelDom.unwrap(renderbuffer));
  }

  bool isShader(WebGLShader shader) {
    return _ptr.isShader(LevelDom.unwrap(shader));
  }

  bool isTexture(WebGLTexture texture) {
    return _ptr.isTexture(LevelDom.unwrap(texture));
  }

  void lineWidth(num width) {
    _ptr.lineWidth(width);
    return;
  }

  void linkProgram(WebGLProgram program) {
    _ptr.linkProgram(LevelDom.unwrap(program));
    return;
  }

  void pixelStorei(int pname, int param) {
    _ptr.pixelStorei(pname, param);
    return;
  }

  void polygonOffset(num factor, num units) {
    _ptr.polygonOffset(factor, units);
    return;
  }

  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels) {
    _ptr.readPixels(x, y, width, height, format, type, LevelDom.unwrap(pixels));
    return;
  }

  void releaseShaderCompiler() {
    _ptr.releaseShaderCompiler();
    return;
  }

  void renderbufferStorage(int target, int internalformat, int width, int height) {
    _ptr.renderbufferStorage(target, internalformat, width, height);
    return;
  }

  void sampleCoverage(num value, bool invert) {
    _ptr.sampleCoverage(value, invert);
    return;
  }

  void scissor(int x, int y, int width, int height) {
    _ptr.scissor(x, y, width, height);
    return;
  }

  void shaderSource(WebGLShader shader, String string) {
    _ptr.shaderSource(LevelDom.unwrap(shader), string);
    return;
  }

  void stencilFunc(int func, int ref, int mask) {
    _ptr.stencilFunc(func, ref, mask);
    return;
  }

  void stencilFuncSeparate(int face, int func, int ref, int mask) {
    _ptr.stencilFuncSeparate(face, func, ref, mask);
    return;
  }

  void stencilMask(int mask) {
    _ptr.stencilMask(mask);
    return;
  }

  void stencilMaskSeparate(int face, int mask) {
    _ptr.stencilMaskSeparate(face, mask);
    return;
  }

  void stencilOp(int fail, int zfail, int zpass) {
    _ptr.stencilOp(fail, zfail, zpass);
    return;
  }

  void stencilOpSeparate(int face, int fail, int zfail, int zpass) {
    _ptr.stencilOpSeparate(face, fail, zfail, zpass);
    return;
  }

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels, [int format = null, int type = null, ArrayBufferView pixels = null]) {
    if (border_OR_canvas_OR_image_OR_pixels is ImageData) {
      if (format === null) {
        if (type === null) {
          if (pixels === null) {
            _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrap(border_OR_canvas_OR_image_OR_pixels));
            return;
          }
        }
      }
    } else {
      if (border_OR_canvas_OR_image_OR_pixels is ImageElement) {
        if (format === null) {
          if (type === null) {
            if (pixels === null) {
              _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrap(border_OR_canvas_OR_image_OR_pixels));
              return;
            }
          }
        }
      } else {
        if (border_OR_canvas_OR_image_OR_pixels is CanvasElement) {
          if (format === null) {
            if (type === null) {
              if (pixels === null) {
                _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrap(border_OR_canvas_OR_image_OR_pixels));
                return;
              }
            }
          }
        } else {
          if (border_OR_canvas_OR_image_OR_pixels is int) {
            _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrap(border_OR_canvas_OR_image_OR_pixels), format, type, LevelDom.unwrap(pixels));
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void texParameterf(int target, int pname, num param) {
    _ptr.texParameterf(target, pname, param);
    return;
  }

  void texParameteri(int target, int pname, int param) {
    _ptr.texParameteri(target, pname, param);
    return;
  }

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels, [int type = null, ArrayBufferView pixels = null]) {
    if (canvas_OR_format_OR_image_OR_pixels is ImageData) {
      if (type === null) {
        if (pixels === null) {
          _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrap(canvas_OR_format_OR_image_OR_pixels));
          return;
        }
      }
    } else {
      if (canvas_OR_format_OR_image_OR_pixels is ImageElement) {
        if (type === null) {
          if (pixels === null) {
            _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrap(canvas_OR_format_OR_image_OR_pixels));
            return;
          }
        }
      } else {
        if (canvas_OR_format_OR_image_OR_pixels is CanvasElement) {
          if (type === null) {
            if (pixels === null) {
              _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrap(canvas_OR_format_OR_image_OR_pixels));
              return;
            }
          }
        } else {
          if (canvas_OR_format_OR_image_OR_pixels is int) {
            _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrap(canvas_OR_format_OR_image_OR_pixels), type, LevelDom.unwrap(pixels));
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void uniform1f(WebGLUniformLocation location, num x) {
    _ptr.uniform1f(LevelDom.unwrap(location), x);
    return;
  }

  void uniform1fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform1fv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform1i(WebGLUniformLocation location, int x) {
    _ptr.uniform1i(LevelDom.unwrap(location), x);
    return;
  }

  void uniform1iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform1iv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform2f(WebGLUniformLocation location, num x, num y) {
    _ptr.uniform2f(LevelDom.unwrap(location), x, y);
    return;
  }

  void uniform2fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform2fv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform2i(WebGLUniformLocation location, int x, int y) {
    _ptr.uniform2i(LevelDom.unwrap(location), x, y);
    return;
  }

  void uniform2iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform2iv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform3f(WebGLUniformLocation location, num x, num y, num z) {
    _ptr.uniform3f(LevelDom.unwrap(location), x, y, z);
    return;
  }

  void uniform3fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform3fv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform3i(WebGLUniformLocation location, int x, int y, int z) {
    _ptr.uniform3i(LevelDom.unwrap(location), x, y, z);
    return;
  }

  void uniform3iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform3iv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w) {
    _ptr.uniform4f(LevelDom.unwrap(location), x, y, z, w);
    return;
  }

  void uniform4fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform4fv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w) {
    _ptr.uniform4i(LevelDom.unwrap(location), x, y, z, w);
    return;
  }

  void uniform4iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform4iv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _ptr.uniformMatrix2fv(LevelDom.unwrap(location), transpose, LevelDom.unwrap(array));
    return;
  }

  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _ptr.uniformMatrix3fv(LevelDom.unwrap(location), transpose, LevelDom.unwrap(array));
    return;
  }

  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _ptr.uniformMatrix4fv(LevelDom.unwrap(location), transpose, LevelDom.unwrap(array));
    return;
  }

  void useProgram(WebGLProgram program) {
    _ptr.useProgram(LevelDom.unwrap(program));
    return;
  }

  void validateProgram(WebGLProgram program) {
    _ptr.validateProgram(LevelDom.unwrap(program));
    return;
  }

  void vertexAttrib1f(int indx, num x) {
    _ptr.vertexAttrib1f(indx, x);
    return;
  }

  void vertexAttrib1fv(int indx, Float32Array values) {
    _ptr.vertexAttrib1fv(indx, LevelDom.unwrap(values));
    return;
  }

  void vertexAttrib2f(int indx, num x, num y) {
    _ptr.vertexAttrib2f(indx, x, y);
    return;
  }

  void vertexAttrib2fv(int indx, Float32Array values) {
    _ptr.vertexAttrib2fv(indx, LevelDom.unwrap(values));
    return;
  }

  void vertexAttrib3f(int indx, num x, num y, num z) {
    _ptr.vertexAttrib3f(indx, x, y, z);
    return;
  }

  void vertexAttrib3fv(int indx, Float32Array values) {
    _ptr.vertexAttrib3fv(indx, LevelDom.unwrap(values));
    return;
  }

  void vertexAttrib4f(int indx, num x, num y, num z, num w) {
    _ptr.vertexAttrib4f(indx, x, y, z, w);
    return;
  }

  void vertexAttrib4fv(int indx, Float32Array values) {
    _ptr.vertexAttrib4fv(indx, LevelDom.unwrap(values));
    return;
  }

  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) {
    _ptr.vertexAttribPointer(indx, size, type, normalized, stride, offset);
    return;
  }

  void viewport(int x, int y, int width, int height) {
    _ptr.viewport(x, y, width, height);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLShaderWrappingImplementation extends DOMWrapperBase implements WebGLShader {
  WebGLShaderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLTextureWrappingImplementation extends DOMWrapperBase implements WebGLTexture {
  WebGLTextureWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLUniformLocationWrappingImplementation extends DOMWrapperBase implements WebGLUniformLocation {
  WebGLUniformLocationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLVertexArrayObjectOESWrappingImplementation extends DOMWrapperBase implements WebGLVertexArrayObjectOES {
  WebGLVertexArrayObjectOESWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class XMLHttpRequestExceptionWrappingImplementation extends DOMWrapperBase implements XMLHttpRequestException {
  XMLHttpRequestExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LevelDom {
  static AnchorElement wrapAnchorElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnchorElementWrappingImplementation._wrap(raw);
  }

  static Animation wrapAnimation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnimationWrappingImplementation._wrap(raw);
  }

  static AnimationEvent wrapAnimationEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnimationEventWrappingImplementation._wrap(raw);
  }

  static AnimationList wrapAnimationList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnimationListWrappingImplementation._wrap(raw);
  }

  static AreaElement wrapAreaElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AreaElementWrappingImplementation._wrap(raw);
  }

  static ArrayBuffer wrapArrayBuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ArrayBufferWrappingImplementation._wrap(raw);
  }

  static ArrayBufferView wrapArrayBufferView(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "ArrayBufferView":
        return new ArrayBufferViewWrappingImplementation._wrap(raw);
      case "DataView":
        return new DataViewWrappingImplementation._wrap(raw);
      case "Float32Array":
        return new Float32ArrayWrappingImplementation._wrap(raw);
      case "Float64Array":
        return new Float64ArrayWrappingImplementation._wrap(raw);
      case "Int16Array":
        return new Int16ArrayWrappingImplementation._wrap(raw);
      case "Int32Array":
        return new Int32ArrayWrappingImplementation._wrap(raw);
      case "Int8Array":
        return new Int8ArrayWrappingImplementation._wrap(raw);
      case "Uint16Array":
        return new Uint16ArrayWrappingImplementation._wrap(raw);
      case "Uint32Array":
        return new Uint32ArrayWrappingImplementation._wrap(raw);
      case "Uint8Array":
        return new Uint8ArrayWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static AudioElement wrapAudioElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioElementWrappingImplementation._wrap(raw);
  }

  static BRElement wrapBRElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BRElementWrappingImplementation._wrap(raw);
  }

  static BarInfo wrapBarInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BarInfoWrappingImplementation._wrap(raw);
  }

  static BaseElement wrapBaseElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BaseElementWrappingImplementation._wrap(raw);
  }

  static BeforeLoadEvent wrapBeforeLoadEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BeforeLoadEventWrappingImplementation._wrap(raw);
  }

  static Blob wrapBlob(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "Blob":
        return new BlobWrappingImplementation._wrap(raw);
      case "File":
        return new FileWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static BlobBuilder wrapBlobBuilder(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BlobBuilderWrappingImplementation._wrap(raw);
  }

  static BodyElement wrapBodyElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BodyElementWrappingImplementation._wrap(raw);
  }

  static ButtonElement wrapButtonElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ButtonElementWrappingImplementation._wrap(raw);
  }

  static CDATASection wrapCDATASection(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CDATASectionWrappingImplementation._wrap(raw);
  }

  static CSSCharsetRule wrapCSSCharsetRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSCharsetRuleWrappingImplementation._wrap(raw);
  }

  static CSSFontFaceRule wrapCSSFontFaceRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSFontFaceRuleWrappingImplementation._wrap(raw);
  }

  static CSSImportRule wrapCSSImportRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSImportRuleWrappingImplementation._wrap(raw);
  }

  static CSSKeyframeRule wrapCSSKeyframeRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSKeyframeRuleWrappingImplementation._wrap(raw);
  }

  static CSSKeyframesRule wrapCSSKeyframesRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSKeyframesRuleWrappingImplementation._wrap(raw);
  }

  static CSSMatrix wrapCSSMatrix(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSMatrixWrappingImplementation._wrap(raw);
  }

  static CSSMediaRule wrapCSSMediaRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSMediaRuleWrappingImplementation._wrap(raw);
  }

  static CSSPageRule wrapCSSPageRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSPageRuleWrappingImplementation._wrap(raw);
  }

  static CSSPrimitiveValue wrapCSSPrimitiveValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSPrimitiveValueWrappingImplementation._wrap(raw);
  }

  static CSSRule wrapCSSRule(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CSSCharsetRule":
        return new CSSCharsetRuleWrappingImplementation._wrap(raw);
      case "CSSFontFaceRule":
        return new CSSFontFaceRuleWrappingImplementation._wrap(raw);
      case "CSSImportRule":
        return new CSSImportRuleWrappingImplementation._wrap(raw);
      case "WebKitCSSKeyframeRule":
        return new CSSKeyframeRuleWrappingImplementation._wrap(raw);
      case "WebKitCSSKeyframesRule":
        return new CSSKeyframesRuleWrappingImplementation._wrap(raw);
      case "CSSMediaRule":
        return new CSSMediaRuleWrappingImplementation._wrap(raw);
      case "CSSPageRule":
        return new CSSPageRuleWrappingImplementation._wrap(raw);
      case "CSSRule":
        return new CSSRuleWrappingImplementation._wrap(raw);
      case "CSSStyleRule":
        return new CSSStyleRuleWrappingImplementation._wrap(raw);
      case "CSSUnknownRule":
        return new CSSUnknownRuleWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CSSRuleList wrapCSSRuleList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSRuleListWrappingImplementation._wrap(raw);
  }

  static CSSStyleDeclaration wrapCSSStyleDeclaration(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSStyleDeclarationWrappingImplementation._wrap(raw);
  }

  static CSSStyleRule wrapCSSStyleRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSStyleRuleWrappingImplementation._wrap(raw);
  }

  static CSSStyleSheet wrapCSSStyleSheet(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSStyleSheetWrappingImplementation._wrap(raw);
  }

  static CSSTransformValue wrapCSSTransformValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSTransformValueWrappingImplementation._wrap(raw);
  }

  static CSSUnknownRule wrapCSSUnknownRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSUnknownRuleWrappingImplementation._wrap(raw);
  }

  static CSSValue wrapCSSValue(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CSSPrimitiveValue":
        return new CSSPrimitiveValueWrappingImplementation._wrap(raw);
      case "WebKitCSSTransformValue":
        return new CSSTransformValueWrappingImplementation._wrap(raw);
      case "CSSValue":
        return new CSSValueWrappingImplementation._wrap(raw);
      case "CSSValueList":
        return new CSSValueListWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CSSValueList wrapCSSValueList(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "WebKitCSSTransformValue":
        return new CSSTransformValueWrappingImplementation._wrap(raw);
      case "CSSValueList":
        return new CSSValueListWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CanvasElement wrapCanvasElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasElementWrappingImplementation._wrap(raw);
  }

  static CanvasGradient wrapCanvasGradient(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasGradientWrappingImplementation._wrap(raw);
  }

  static CanvasPattern wrapCanvasPattern(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasPatternWrappingImplementation._wrap(raw);
  }

  static CanvasPixelArray wrapCanvasPixelArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasPixelArrayWrappingImplementation._wrap(raw);
  }

  static CanvasRenderingContext wrapCanvasRenderingContext(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CanvasRenderingContext":
        return new CanvasRenderingContextWrappingImplementation._wrap(raw);
      case "CanvasRenderingContext2D":
        return new CanvasRenderingContext2DWrappingImplementation._wrap(raw);
      case "WebGLRenderingContext":
        return new WebGLRenderingContextWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CanvasRenderingContext2D wrapCanvasRenderingContext2D(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasRenderingContext2DWrappingImplementation._wrap(raw);
  }

  static CharacterData wrapCharacterData(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static ClientRect wrapClientRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ClientRectWrappingImplementation._wrap(raw);
  }

  static Clipboard wrapClipboard(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ClipboardWrappingImplementation._wrap(raw);
  }

  static CloseEvent wrapCloseEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CloseEventWrappingImplementation._wrap(raw);
  }

  static Comment wrapComment(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CommentWrappingImplementation._wrap(raw);
  }

  static CompositionEvent wrapCompositionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CompositionEventWrappingImplementation._wrap(raw);
  }

  static Console wrapConsole(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ConsoleWrappingImplementation._wrap(raw);
  }

  static Coordinates wrapCoordinates(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CoordinatesWrappingImplementation._wrap(raw);
  }

  static Counter wrapCounter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CounterWrappingImplementation._wrap(raw);
  }

  static Crypto wrapCrypto(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CryptoWrappingImplementation._wrap(raw);
  }

  static CustomEvent wrapCustomEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CustomEventWrappingImplementation._wrap(raw);
  }

  static DListElement wrapDListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DListElementWrappingImplementation._wrap(raw);
  }

  static DOMApplicationCache wrapDOMApplicationCache(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMApplicationCacheWrappingImplementation._wrap(raw);
  }

  static DOMException wrapDOMException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMExceptionWrappingImplementation._wrap(raw);
  }

  static DOMFileSystem wrapDOMFileSystem(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMFileSystemWrappingImplementation._wrap(raw);
  }

  static DOMFileSystemSync wrapDOMFileSystemSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMFileSystemSyncWrappingImplementation._wrap(raw);
  }

  static DOMFormData wrapDOMFormData(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMFormDataWrappingImplementation._wrap(raw);
  }

  static DOMMimeType wrapDOMMimeType(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMMimeTypeWrappingImplementation._wrap(raw);
  }

  static DOMMimeTypeArray wrapDOMMimeTypeArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMMimeTypeArrayWrappingImplementation._wrap(raw);
  }

  static DOMParser wrapDOMParser(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMParserWrappingImplementation._wrap(raw);
  }

  static DOMPlugin wrapDOMPlugin(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMPluginWrappingImplementation._wrap(raw);
  }

  static DOMPluginArray wrapDOMPluginArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMPluginArrayWrappingImplementation._wrap(raw);
  }

  static DOMSelection wrapDOMSelection(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMSelectionWrappingImplementation._wrap(raw);
  }

  static DOMSettableTokenList wrapDOMSettableTokenList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMSettableTokenListWrappingImplementation._wrap(raw);
  }

  static DOMTokenList wrapDOMTokenList(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "DOMSettableTokenList":
        return new DOMSettableTokenListWrappingImplementation._wrap(raw);
      case "DOMTokenList":
        return new DOMTokenListWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static DOMURL wrapDOMURL(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMURLWrappingImplementation._wrap(raw);
  }

  static DataListElement wrapDataListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataListElementWrappingImplementation._wrap(raw);
  }

  static DataTransferItem wrapDataTransferItem(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataTransferItemWrappingImplementation._wrap(raw);
  }

  static DataTransferItems wrapDataTransferItems(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataTransferItemsWrappingImplementation._wrap(raw);
  }

  static DataView wrapDataView(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataViewWrappingImplementation._wrap(raw);
  }

  static DetailsElement wrapDetailsElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DetailsElementWrappingImplementation._wrap(raw);
  }

  static DeviceMotionEvent wrapDeviceMotionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DeviceMotionEventWrappingImplementation._wrap(raw);
  }

  static DeviceOrientationEvent wrapDeviceOrientationEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DeviceOrientationEventWrappingImplementation._wrap(raw);
  }

  static DirectoryEntry wrapDirectoryEntry(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryEntryWrappingImplementation._wrap(raw);
  }

  static DirectoryEntrySync wrapDirectoryEntrySync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryEntrySyncWrappingImplementation._wrap(raw);
  }

  static DirectoryReader wrapDirectoryReader(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryReaderWrappingImplementation._wrap(raw);
  }

  static DirectoryReaderSync wrapDirectoryReaderSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryReaderSyncWrappingImplementation._wrap(raw);
  }

  static DivElement wrapDivElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DivElementWrappingImplementation._wrap(raw);
  }

  static Document wrapDocument(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
  }

  static DocumentFragment wrapDocumentFragment(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DocumentFragmentWrappingImplementation._wrap(raw);
  }

  static Element wrapElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "HTMLKeygenElement":
        return new KeygenElementWrappingImplementation._wrap(raw);
      case "HTMLLIElement":
        return new LIElementWrappingImplementation._wrap(raw);
      case "HTMLLabelElement":
        return new LabelElementWrappingImplementation._wrap(raw);
      case "HTMLLegendElement":
        return new LegendElementWrappingImplementation._wrap(raw);
      case "HTMLLinkElement":
        return new LinkElementWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "HTMLTableCaptionElement":
        return new TableCaptionElementWrappingImplementation._wrap(raw);
      case "HTMLTableCellElement":
        return new TableCellElementWrappingImplementation._wrap(raw);
      case "HTMLTableColElement":
        return new TableColElementWrappingImplementation._wrap(raw);
      case "HTMLTableElement":
        return new TableElementWrappingImplementation._wrap(raw);
      case "HTMLTableRowElement":
        return new TableRowElementWrappingImplementation._wrap(raw);
      case "HTMLTableSectionElement":
        return new TableSectionElementWrappingImplementation._wrap(raw);
      case "HTMLTextAreaElement":
        return new TextAreaElementWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static ElementList wrapElementList(raw) {
    return raw === null ? null : new FrozenElementList._wrap(raw);
  }

  static EmbedElement wrapEmbedElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EmbedElementWrappingImplementation._wrap(raw);
  }

  static Entity wrapEntity(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntityWrappingImplementation._wrap(raw);
  }

  static EntityReference wrapEntityReference(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntityReferenceWrappingImplementation._wrap(raw);
  }

  static EntriesCallback wrapEntriesCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntriesCallbackWrappingImplementation._wrap(raw);
  }

  static Entry wrapEntry(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "DirectoryEntry":
        return new DirectoryEntryWrappingImplementation._wrap(raw);
      case "Entry":
        return new EntryWrappingImplementation._wrap(raw);
      case "FileEntry":
        return new FileEntryWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static EntryArray wrapEntryArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntryArrayWrappingImplementation._wrap(raw);
  }

  static EntryArraySync wrapEntryArraySync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntryArraySyncWrappingImplementation._wrap(raw);
  }

  static EntryCallback wrapEntryCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntryCallbackWrappingImplementation._wrap(raw);
  }

  static EntrySync wrapEntrySync(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "DirectoryEntrySync":
        return new DirectoryEntrySyncWrappingImplementation._wrap(raw);
      case "EntrySync":
        return new EntrySyncWrappingImplementation._wrap(raw);
      case "FileEntrySync":
        return new FileEntrySyncWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static ErrorCallback wrapErrorCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ErrorCallbackWrappingImplementation._wrap(raw);
  }

  static ErrorEvent wrapErrorEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ErrorEventWrappingImplementation._wrap(raw);
  }

  static Event wrapEvent(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "WebKitAnimationEvent":
        return new AnimationEventWrappingImplementation._wrap(raw);
      case "BeforeLoadEvent":
        return new BeforeLoadEventWrappingImplementation._wrap(raw);
      case "CloseEvent":
        return new CloseEventWrappingImplementation._wrap(raw);
      case "CompositionEvent":
        return new CompositionEventWrappingImplementation._wrap(raw);
      case "CustomEvent":
        return new CustomEventWrappingImplementation._wrap(raw);
      case "DeviceMotionEvent":
        return new DeviceMotionEventWrappingImplementation._wrap(raw);
      case "DeviceOrientationEvent":
        return new DeviceOrientationEventWrappingImplementation._wrap(raw);
      case "ErrorEvent":
        return new ErrorEventWrappingImplementation._wrap(raw);
      case "Event":
        return new EventWrappingImplementation._wrap(raw);
      case "HashChangeEvent":
        return new HashChangeEventWrappingImplementation._wrap(raw);
      case "IDBVersionChangeEvent":
        return new IDBVersionChangeEventWrappingImplementation._wrap(raw);
      case "KeyboardEvent":
        return new KeyboardEventWrappingImplementation._wrap(raw);
      case "MessageEvent":
        return new MessageEventWrappingImplementation._wrap(raw);
      case "MouseEvent":
        return new MouseEventWrappingImplementation._wrap(raw);
      case "MutationEvent":
        return new MutationEventWrappingImplementation._wrap(raw);
      case "OverflowEvent":
        return new OverflowEventWrappingImplementation._wrap(raw);
      case "PageTransitionEvent":
        return new PageTransitionEventWrappingImplementation._wrap(raw);
      case "PopStateEvent":
        return new PopStateEventWrappingImplementation._wrap(raw);
      case "ProgressEvent":
        return new ProgressEventWrappingImplementation._wrap(raw);
      case "SpeechInputEvent":
        return new SpeechInputEventWrappingImplementation._wrap(raw);
      case "StorageEvent":
        return new StorageEventWrappingImplementation._wrap(raw);
      case "TextEvent":
        return new TextEventWrappingImplementation._wrap(raw);
      case "TouchEvent":
        return new TouchEventWrappingImplementation._wrap(raw);
      case "WebKitTransitionEvent":
        return new TransitionEventWrappingImplementation._wrap(raw);
      case "UIEvent":
        return new UIEventWrappingImplementation._wrap(raw);
      case "WebGLContextEvent":
        return new WebGLContextEventWrappingImplementation._wrap(raw);
      case "WheelEvent":
        return new WheelEventWrappingImplementation._wrap(raw);
      case "XMLHttpRequestProgressEvent":
        return new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static EventException wrapEventException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EventExceptionWrappingImplementation._wrap(raw);
  }

  static Function wrapEventListener(raw) {
    return raw === null ? null : function(evt) { return raw(LevelDom.wrapEvent(evt)); };
  }

  static EventSource wrapEventSource(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EventSourceWrappingImplementation._wrap(raw);
  }

  static EventTarget wrapEventTarget(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      /* Skipping AbstractWorker*/
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      /* Skipping Attr*/
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "DOMApplicationCache":
        return new DOMApplicationCacheWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLDocument":
        return new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
      case "DocumentFragment":
        return new DocumentFragmentWrappingImplementation._wrap(raw);
      /* Skipping DocumentType*/
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "Entity":
        return new EntityWrappingImplementation._wrap(raw);
      case "EntityReference":
        return new EntityReferenceWrappingImplementation._wrap(raw);
      case "EventSource":
        return new EventSourceWrappingImplementation._wrap(raw);
      case "EventTarget":
        return new EventTargetWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "HTMLKeygenElement":
        return new KeygenElementWrappingImplementation._wrap(raw);
      case "HTMLLIElement":
        return new LIElementWrappingImplementation._wrap(raw);
      case "HTMLLabelElement":
        return new LabelElementWrappingImplementation._wrap(raw);
      case "HTMLLegendElement":
        return new LegendElementWrappingImplementation._wrap(raw);
      case "HTMLLinkElement":
        return new LinkElementWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "MessagePort":
        return new MessagePortWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "Node":
        return new NodeWrappingImplementation._wrap(raw);
      case "Notation":
        return new NotationWrappingImplementation._wrap(raw);
      case "Notification":
        return new NotificationWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "ProcessingInstruction":
        return new ProcessingInstructionWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "SharedWorker":
        return new SharedWorkerWrappingImplementation._wrap(raw);
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "HTMLTableCaptionElement":
        return new TableCaptionElementWrappingImplementation._wrap(raw);
      case "HTMLTableCellElement":
        return new TableCellElementWrappingImplementation._wrap(raw);
      case "HTMLTableColElement":
        return new TableColElementWrappingImplementation._wrap(raw);
      case "HTMLTableElement":
        return new TableElementWrappingImplementation._wrap(raw);
      case "HTMLTableRowElement":
        return new TableRowElementWrappingImplementation._wrap(raw);
      case "HTMLTableSectionElement":
        return new TableSectionElementWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      case "HTMLTextAreaElement":
        return new TextAreaElementWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      case "WebSocket":
        return new WebSocketWrappingImplementation._wrap(raw);
      case "Window":
        return new WindowWrappingImplementation._wrap(raw);
      case "Worker":
        return new WorkerWrappingImplementation._wrap(raw);
      case "XMLHttpRequest":
        return new XMLHttpRequestWrappingImplementation._wrap(raw);
      case "XMLHttpRequestUpload":
        return new XMLHttpRequestUploadWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static FieldSetElement wrapFieldSetElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FieldSetElementWrappingImplementation._wrap(raw);
  }

  static File wrapFile(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWrappingImplementation._wrap(raw);
  }

  static FileCallback wrapFileCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileCallbackWrappingImplementation._wrap(raw);
  }

  static FileEntry wrapFileEntry(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileEntryWrappingImplementation._wrap(raw);
  }

  static FileEntrySync wrapFileEntrySync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileEntrySyncWrappingImplementation._wrap(raw);
  }

  static FileError wrapFileError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileErrorWrappingImplementation._wrap(raw);
  }

  static FileException wrapFileException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileExceptionWrappingImplementation._wrap(raw);
  }

  static FileList wrapFileList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileListWrappingImplementation._wrap(raw);
  }

  static FileReader wrapFileReader(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileReaderWrappingImplementation._wrap(raw);
  }

  static FileReaderSync wrapFileReaderSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileReaderSyncWrappingImplementation._wrap(raw);
  }

  static FileSystemCallback wrapFileSystemCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileSystemCallbackWrappingImplementation._wrap(raw);
  }

  static FileWriter wrapFileWriter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWriterWrappingImplementation._wrap(raw);
  }

  static FileWriterCallback wrapFileWriterCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWriterCallbackWrappingImplementation._wrap(raw);
  }

  static FileWriterSync wrapFileWriterSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWriterSyncWrappingImplementation._wrap(raw);
  }

  static Flags wrapFlags(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FlagsWrappingImplementation._wrap(raw);
  }

  static Float32Array wrapFloat32Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Float32ArrayWrappingImplementation._wrap(raw);
  }

  static Float64Array wrapFloat64Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Float64ArrayWrappingImplementation._wrap(raw);
  }

  static FontElement wrapFontElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FontElementWrappingImplementation._wrap(raw);
  }

  static FormElement wrapFormElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FormElementWrappingImplementation._wrap(raw);
  }

  static Geolocation wrapGeolocation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new GeolocationWrappingImplementation._wrap(raw);
  }

  static Geoposition wrapGeoposition(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new GeopositionWrappingImplementation._wrap(raw);
  }

  static HRElement wrapHRElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HRElementWrappingImplementation._wrap(raw);
  }

  static HTMLAllCollection wrapHTMLAllCollection(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HTMLAllCollectionWrappingImplementation._wrap(raw);
  }

  static HashChangeEvent wrapHashChangeEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HashChangeEventWrappingImplementation._wrap(raw);
  }

  static HeadElement wrapHeadElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HeadElementWrappingImplementation._wrap(raw);
  }

  static HeadingElement wrapHeadingElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HeadingElementWrappingImplementation._wrap(raw);
  }

  static History wrapHistory(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HistoryWrappingImplementation._wrap(raw);
  }

  static IDBAny wrapIDBAny(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBAnyWrappingImplementation._wrap(raw);
  }

  static IDBCursor wrapIDBCursor(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "IDBCursor":
        return new IDBCursorWrappingImplementation._wrap(raw);
      case "IDBCursorWithValue":
        return new IDBCursorWithValueWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static IDBCursorWithValue wrapIDBCursorWithValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBCursorWithValueWrappingImplementation._wrap(raw);
  }

  static IDBDatabase wrapIDBDatabase(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBDatabaseWrappingImplementation._wrap(raw);
  }

  static IDBDatabaseError wrapIDBDatabaseError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBDatabaseErrorWrappingImplementation._wrap(raw);
  }

  static IDBDatabaseException wrapIDBDatabaseException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBDatabaseExceptionWrappingImplementation._wrap(raw);
  }

  static IDBFactory wrapIDBFactory(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBFactoryWrappingImplementation._wrap(raw);
  }

  static IDBIndex wrapIDBIndex(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBIndexWrappingImplementation._wrap(raw);
  }

  static IDBKey wrapIDBKey(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBKeyWrappingImplementation._wrap(raw);
  }

  static IDBKeyRange wrapIDBKeyRange(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBKeyRangeWrappingImplementation._wrap(raw);
  }

  static IDBObjectStore wrapIDBObjectStore(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBObjectStoreWrappingImplementation._wrap(raw);
  }

  static IDBRequest wrapIDBRequest(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "IDBRequest":
        return new IDBRequestWrappingImplementation._wrap(raw);
      case "IDBVersionChangeRequest":
        return new IDBVersionChangeRequestWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static IDBTransaction wrapIDBTransaction(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBTransactionWrappingImplementation._wrap(raw);
  }

  static IDBVersionChangeEvent wrapIDBVersionChangeEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBVersionChangeEventWrappingImplementation._wrap(raw);
  }

  static IDBVersionChangeRequest wrapIDBVersionChangeRequest(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBVersionChangeRequestWrappingImplementation._wrap(raw);
  }

  static IFrameElement wrapIFrameElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IFrameElementWrappingImplementation._wrap(raw);
  }

  static ImageData wrapImageData(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ImageDataWrappingImplementation._wrap(raw);
  }

  static ImageElement wrapImageElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ImageElementWrappingImplementation._wrap(raw);
  }

  static InputElement wrapInputElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static Int16Array wrapInt16Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Int16ArrayWrappingImplementation._wrap(raw);
  }

  static Int32Array wrapInt32Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Int32ArrayWrappingImplementation._wrap(raw);
  }

  static Int8Array wrapInt8Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Int8ArrayWrappingImplementation._wrap(raw);
  }

  static KeyboardEvent wrapKeyboardEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new KeyboardEventWrappingImplementation._wrap(raw);
  }

  static KeygenElement wrapKeygenElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new KeygenElementWrappingImplementation._wrap(raw);
  }

  static LIElement wrapLIElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LIElementWrappingImplementation._wrap(raw);
  }

  static LabelElement wrapLabelElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LabelElementWrappingImplementation._wrap(raw);
  }

  static LegendElement wrapLegendElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LegendElementWrappingImplementation._wrap(raw);
  }

  static LinkElement wrapLinkElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LinkElementWrappingImplementation._wrap(raw);
  }

  static LocalMediaStream wrapLocalMediaStream(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LocalMediaStreamWrappingImplementation._wrap(raw);
  }

  static Location wrapLocation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LocationWrappingImplementation._wrap(raw);
  }

  static LoseContext wrapLoseContext(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LoseContextWrappingImplementation._wrap(raw);
  }

  static MapElement wrapMapElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MapElementWrappingImplementation._wrap(raw);
  }

  static MarqueeElement wrapMarqueeElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MarqueeElementWrappingImplementation._wrap(raw);
  }

  static MediaElement wrapMediaElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static MediaError wrapMediaError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaErrorWrappingImplementation._wrap(raw);
  }

  static MediaList wrapMediaList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaListWrappingImplementation._wrap(raw);
  }

  static MediaQueryList wrapMediaQueryList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaQueryListWrappingImplementation._wrap(raw);
  }

  static MediaQueryListListener wrapMediaQueryListListener(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaQueryListListenerWrappingImplementation._wrap(raw);
  }

  static MediaStream wrapMediaStream(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "LocalMediaStream":
        return new LocalMediaStreamWrappingImplementation._wrap(raw);
      case "MediaStream":
        return new MediaStreamWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static MediaStreamList wrapMediaStreamList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaStreamListWrappingImplementation._wrap(raw);
  }

  static MediaStreamTrack wrapMediaStreamTrack(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaStreamTrackWrappingImplementation._wrap(raw);
  }

  static MediaStreamTrackList wrapMediaStreamTrackList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaStreamTrackListWrappingImplementation._wrap(raw);
  }

  static MenuElement wrapMenuElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MenuElementWrappingImplementation._wrap(raw);
  }

  static MessageChannel wrapMessageChannel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MessageChannelWrappingImplementation._wrap(raw);
  }

  static MessageEvent wrapMessageEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MessageEventWrappingImplementation._wrap(raw);
  }

  static MessagePort wrapMessagePort(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MessagePortWrappingImplementation._wrap(raw);
  }

  static MetaElement wrapMetaElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MetaElementWrappingImplementation._wrap(raw);
  }

  static Metadata wrapMetadata(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MetadataWrappingImplementation._wrap(raw);
  }

  static MetadataCallback wrapMetadataCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MetadataCallbackWrappingImplementation._wrap(raw);
  }

  static MeterElement wrapMeterElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MeterElementWrappingImplementation._wrap(raw);
  }

  static ModElement wrapModElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ModElementWrappingImplementation._wrap(raw);
  }

  static MouseEvent wrapMouseEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MouseEventWrappingImplementation._wrap(raw);
  }

  static MutationEvent wrapMutationEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MutationEventWrappingImplementation._wrap(raw);
  }

  static MutationRecord wrapMutationRecord(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MutationRecordWrappingImplementation._wrap(raw);
  }

  static Navigator wrapNavigator(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorWrappingImplementation._wrap(raw);
  }

  static NavigatorUserMediaError wrapNavigatorUserMediaError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorUserMediaErrorWrappingImplementation._wrap(raw);
  }

  static NavigatorUserMediaErrorCallback wrapNavigatorUserMediaErrorCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorUserMediaErrorCallbackWrappingImplementation._wrap(raw);
  }

  static NavigatorUserMediaSuccessCallback wrapNavigatorUserMediaSuccessCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorUserMediaSuccessCallbackWrappingImplementation._wrap(raw);
  }

  static Node wrapNode(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      /* Skipping Attr*/
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLDocument":
        return new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
      case "DocumentFragment":
        return new DocumentFragmentWrappingImplementation._wrap(raw);
      /* Skipping DocumentType*/
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "Entity":
        return new EntityWrappingImplementation._wrap(raw);
      case "EntityReference":
        return new EntityReferenceWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "HTMLKeygenElement":
        return new KeygenElementWrappingImplementation._wrap(raw);
      case "HTMLLIElement":
        return new LIElementWrappingImplementation._wrap(raw);
      case "HTMLLabelElement":
        return new LabelElementWrappingImplementation._wrap(raw);
      case "HTMLLegendElement":
        return new LegendElementWrappingImplementation._wrap(raw);
      case "HTMLLinkElement":
        return new LinkElementWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "Node":
        return new NodeWrappingImplementation._wrap(raw);
      case "Notation":
        return new NotationWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "ProcessingInstruction":
        return new ProcessingInstructionWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "HTMLTableCaptionElement":
        return new TableCaptionElementWrappingImplementation._wrap(raw);
      case "HTMLTableCellElement":
        return new TableCellElementWrappingImplementation._wrap(raw);
      case "HTMLTableColElement":
        return new TableColElementWrappingImplementation._wrap(raw);
      case "HTMLTableElement":
        return new TableElementWrappingImplementation._wrap(raw);
      case "HTMLTableRowElement":
        return new TableRowElementWrappingImplementation._wrap(raw);
      case "HTMLTableSectionElement":
        return new TableSectionElementWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      case "HTMLTextAreaElement":
        return new TextAreaElementWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static Notation wrapNotation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NotationWrappingImplementation._wrap(raw);
  }

  static Notification wrapNotification(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NotificationWrappingImplementation._wrap(raw);
  }

  static NotificationCenter wrapNotificationCenter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NotificationCenterWrappingImplementation._wrap(raw);
  }

  static OESStandardDerivatives wrapOESStandardDerivatives(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OESStandardDerivativesWrappingImplementation._wrap(raw);
  }

  static OESTextureFloat wrapOESTextureFloat(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OESTextureFloatWrappingImplementation._wrap(raw);
  }

  static OESVertexArrayObject wrapOESVertexArrayObject(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OESVertexArrayObjectWrappingImplementation._wrap(raw);
  }

  static OListElement wrapOListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OListElementWrappingImplementation._wrap(raw);
  }

  static ObjectElement wrapObjectElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ObjectElementWrappingImplementation._wrap(raw);
  }

  static OperationNotAllowedException wrapOperationNotAllowedException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OperationNotAllowedExceptionWrappingImplementation._wrap(raw);
  }

  static OptGroupElement wrapOptGroupElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OptGroupElementWrappingImplementation._wrap(raw);
  }

  static OptionElement wrapOptionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OptionElementWrappingImplementation._wrap(raw);
  }

  static OutputElement wrapOutputElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OutputElementWrappingImplementation._wrap(raw);
  }

  static OverflowEvent wrapOverflowEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OverflowEventWrappingImplementation._wrap(raw);
  }

  static PageTransitionEvent wrapPageTransitionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PageTransitionEventWrappingImplementation._wrap(raw);
  }

  static ParagraphElement wrapParagraphElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ParagraphElementWrappingImplementation._wrap(raw);
  }

  static ParamElement wrapParamElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ParamElementWrappingImplementation._wrap(raw);
  }

  static Point wrapPoint(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PointWrappingImplementation._wrap(raw);
  }

  static PopStateEvent wrapPopStateEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PopStateEventWrappingImplementation._wrap(raw);
  }

  static PositionCallback wrapPositionCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PositionCallbackWrappingImplementation._wrap(raw);
  }

  static PositionError wrapPositionError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PositionErrorWrappingImplementation._wrap(raw);
  }

  static PositionErrorCallback wrapPositionErrorCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PositionErrorCallbackWrappingImplementation._wrap(raw);
  }

  static PreElement wrapPreElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PreElementWrappingImplementation._wrap(raw);
  }

  static ProcessingInstruction wrapProcessingInstruction(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ProcessingInstructionWrappingImplementation._wrap(raw);
  }

  static ProgressElement wrapProgressElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ProgressElementWrappingImplementation._wrap(raw);
  }

  static ProgressEvent wrapProgressEvent(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "ProgressEvent":
        return new ProgressEventWrappingImplementation._wrap(raw);
      case "XMLHttpRequestProgressEvent":
        return new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static QuoteElement wrapQuoteElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new QuoteElementWrappingImplementation._wrap(raw);
  }

  static RGBColor wrapRGBColor(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RGBColorWrappingImplementation._wrap(raw);
  }

  static Range wrapRange(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RangeWrappingImplementation._wrap(raw);
  }

  static RangeException wrapRangeException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RangeExceptionWrappingImplementation._wrap(raw);
  }

  static Rect wrapRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RectWrappingImplementation._wrap(raw);
  }

  static Screen wrapScreen(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ScreenWrappingImplementation._wrap(raw);
  }

  static ScriptElement wrapScriptElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ScriptElementWrappingImplementation._wrap(raw);
  }

  static SelectElement wrapSelectElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SelectElementWrappingImplementation._wrap(raw);
  }

  static SharedWorker wrapSharedWorker(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SharedWorkerWrappingImplementation._wrap(raw);
  }

  static SourceElement wrapSourceElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SourceElementWrappingImplementation._wrap(raw);
  }

  static SpanElement wrapSpanElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpanElementWrappingImplementation._wrap(raw);
  }

  static SpeechInputEvent wrapSpeechInputEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpeechInputEventWrappingImplementation._wrap(raw);
  }

  static SpeechInputResult wrapSpeechInputResult(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpeechInputResultWrappingImplementation._wrap(raw);
  }

  static SpeechInputResultList wrapSpeechInputResultList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpeechInputResultListWrappingImplementation._wrap(raw);
  }

  static Storage wrapStorage(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageWrappingImplementation._wrap(raw);
  }

  static StorageEvent wrapStorageEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageEventWrappingImplementation._wrap(raw);
  }

  static StorageInfo wrapStorageInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageInfoWrappingImplementation._wrap(raw);
  }

  static StorageInfoErrorCallback wrapStorageInfoErrorCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageInfoErrorCallbackWrappingImplementation._wrap(raw);
  }

  static StorageInfoQuotaCallback wrapStorageInfoQuotaCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageInfoQuotaCallbackWrappingImplementation._wrap(raw);
  }

  static StorageInfoUsageCallback wrapStorageInfoUsageCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageInfoUsageCallbackWrappingImplementation._wrap(raw);
  }

  static StringCallback wrapStringCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StringCallbackWrappingImplementation._wrap(raw);
  }

  static StyleElement wrapStyleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StyleElementWrappingImplementation._wrap(raw);
  }

  static StyleMedia wrapStyleMedia(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StyleMediaWrappingImplementation._wrap(raw);
  }

  static StyleSheet wrapStyleSheet(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CSSStyleSheet":
        return new CSSStyleSheetWrappingImplementation._wrap(raw);
      case "StyleSheet":
        return new StyleSheetWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static StyleSheetList wrapStyleSheetList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StyleSheetListWrappingImplementation._wrap(raw);
  }

  static TableCaptionElement wrapTableCaptionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableCaptionElementWrappingImplementation._wrap(raw);
  }

  static TableCellElement wrapTableCellElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableCellElementWrappingImplementation._wrap(raw);
  }

  static TableColElement wrapTableColElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableColElementWrappingImplementation._wrap(raw);
  }

  static TableElement wrapTableElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableElementWrappingImplementation._wrap(raw);
  }

  static TableRowElement wrapTableRowElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableRowElementWrappingImplementation._wrap(raw);
  }

  static TableSectionElement wrapTableSectionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableSectionElementWrappingImplementation._wrap(raw);
  }

  static Text wrapText(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static TextAreaElement wrapTextAreaElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextAreaElementWrappingImplementation._wrap(raw);
  }

  static TextEvent wrapTextEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextEventWrappingImplementation._wrap(raw);
  }

  static TextMetrics wrapTextMetrics(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextMetricsWrappingImplementation._wrap(raw);
  }

  static TimeRanges wrapTimeRanges(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TimeRangesWrappingImplementation._wrap(raw);
  }

  static TitleElement wrapTitleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TitleElementWrappingImplementation._wrap(raw);
  }

  static Touch wrapTouch(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TouchWrappingImplementation._wrap(raw);
  }

  static TouchEvent wrapTouchEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TouchEventWrappingImplementation._wrap(raw);
  }

  static TouchList wrapTouchList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TouchListWrappingImplementation._wrap(raw);
  }

  static TrackElement wrapTrackElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TrackElementWrappingImplementation._wrap(raw);
  }

  static TransitionEvent wrapTransitionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TransitionEventWrappingImplementation._wrap(raw);
  }

  static UIEvent wrapUIEvent(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CompositionEvent":
        return new CompositionEventWrappingImplementation._wrap(raw);
      case "KeyboardEvent":
        return new KeyboardEventWrappingImplementation._wrap(raw);
      case "MouseEvent":
        return new MouseEventWrappingImplementation._wrap(raw);
      case "TextEvent":
        return new TextEventWrappingImplementation._wrap(raw);
      case "TouchEvent":
        return new TouchEventWrappingImplementation._wrap(raw);
      case "UIEvent":
        return new UIEventWrappingImplementation._wrap(raw);
      case "WheelEvent":
        return new WheelEventWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static UListElement wrapUListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new UListElementWrappingImplementation._wrap(raw);
  }

  static Uint16Array wrapUint16Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Uint16ArrayWrappingImplementation._wrap(raw);
  }

  static Uint32Array wrapUint32Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Uint32ArrayWrappingImplementation._wrap(raw);
  }

  static Uint8Array wrapUint8Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Uint8ArrayWrappingImplementation._wrap(raw);
  }

  static UnknownElement wrapUnknownElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new UnknownElementWrappingImplementation._wrap(raw);
  }

  static ValidityState wrapValidityState(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ValidityStateWrappingImplementation._wrap(raw);
  }

  static VideoElement wrapVideoElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new VideoElementWrappingImplementation._wrap(raw);
  }

  static VoidCallback wrapVoidCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new VoidCallbackWrappingImplementation._wrap(raw);
  }

  static WebGLActiveInfo wrapWebGLActiveInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLActiveInfoWrappingImplementation._wrap(raw);
  }

  static WebGLBuffer wrapWebGLBuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLBufferWrappingImplementation._wrap(raw);
  }

  static WebGLContextAttributes wrapWebGLContextAttributes(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLContextAttributesWrappingImplementation._wrap(raw);
  }

  static WebGLContextEvent wrapWebGLContextEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLContextEventWrappingImplementation._wrap(raw);
  }

  static WebGLFramebuffer wrapWebGLFramebuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLFramebufferWrappingImplementation._wrap(raw);
  }

  static WebGLProgram wrapWebGLProgram(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLProgramWrappingImplementation._wrap(raw);
  }

  static WebGLRenderbuffer wrapWebGLRenderbuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLRenderbufferWrappingImplementation._wrap(raw);
  }

  static WebGLRenderingContext wrapWebGLRenderingContext(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLRenderingContextWrappingImplementation._wrap(raw);
  }

  static WebGLShader wrapWebGLShader(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLShaderWrappingImplementation._wrap(raw);
  }

  static WebGLTexture wrapWebGLTexture(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLTextureWrappingImplementation._wrap(raw);
  }

  static WebGLUniformLocation wrapWebGLUniformLocation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLUniformLocationWrappingImplementation._wrap(raw);
  }

  static WebGLVertexArrayObjectOES wrapWebGLVertexArrayObjectOES(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLVertexArrayObjectOESWrappingImplementation._wrap(raw);
  }

  static WebSocket wrapWebSocket(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebSocketWrappingImplementation._wrap(raw);
  }

  static WheelEvent wrapWheelEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WheelEventWrappingImplementation._wrap(raw);
  }

  static Window wrapWindow(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WindowWrappingImplementation._wrap(raw);
  }

  static Worker wrapWorker(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WorkerWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequest wrapXMLHttpRequest(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequestException wrapXMLHttpRequestException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestExceptionWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequestProgressEvent wrapXMLHttpRequestProgressEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequestUpload wrapXMLHttpRequestUpload(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestUploadWrappingImplementation._wrap(raw);
  }

  static unwrapMaybePrimitive(raw) {
    return raw is DOMWrapperBase ? raw._ptr : raw;
  }

  static unwrap(raw) {
    return raw === null ? null : raw._ptr;
  }


  static void initialize(var rawWindow) {
    secretWindow = wrapWindow(rawWindow);
    secretDocument = wrapDocument(rawWindow.document);
  }

}
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


// These factory methods could all live in one factory provider class but dartc
// has a bug (5399939) preventing that.

class _FileReaderFactoryProvider {

  factory FileReader() {
    return new dom.FileReader();
  }
}

class _CSSMatrixFactoryProvider {

  factory CSSMatrix([String spec = '']) {
    return new CSSMatrixWrappingImplementation._wrap(
        new dom.WebKitCSSMatrix(spec));
  }
}

class _PointFactoryProvider {

  /** @domName Window.createWebKitPoint */
  factory Point(num x, num y) {
    return new PointWrappingImplementation._wrap(new dom.WebKitPoint(x, y));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Iterator for lists with fixed size.
class _FixedSizeListIterator<T> extends _VariableSizeListIterator<T> {
  _FixedSizeListIterator(List<T> list)
      : super(list),
        _length = list.length;

  bool hasNext() => _length > _pos;

  final int _length;  // Cache list length for faster access.
}

// Iterator for lists with variable size.
class _VariableSizeListIterator<T> implements Iterator<T> {
  _VariableSizeListIterator(List<T> list)
      : _list = list,
        _pos = 0;

  bool hasNext() => _list.length > _pos;

  T next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _list[_pos++];
  }

  final List<T> _list;
  int _pos;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): move into a core library or at least merge with the copy
// in client/dom/src
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

class AbstractWorkerEventsImplementation extends EventsImplementation implements AbstractWorkerEvents {
  AbstractWorkerEventsImplementation._wrap(_ptr) : super._wrap(_ptr);
  
  EventListenerList get error() => _get('error');
}

class AbstractWorkerWrappingImplementation extends EventTargetWrappingImplementation implements AbstractWorker {
  AbstractWorkerWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  AbstractWorkerEvents get on() {
    if (_on === null) {	
      _on = new AbstractWorkerEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
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

class AnimationEventWrappingImplementation extends EventWrappingImplementation implements AnimationEvent {
  static String _name;

  AnimationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  static String get _eventName() {
    if (_name != null) return _name;

    try {
      dom.document.createEvent("WebKitAnimationEvent");
      _name = "WebKitAnimationEvent";
    } catch (var e) {
      _name = "AnimationEvent";
    }
    return _name;
  }

  factory AnimationEventWrappingImplementation(String type, String propertyName,
      double elapsedTime, [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent(_eventName);
    e.initWebKitAnimationEvent(
        type, canBubble, cancelable, propertyName, elapsedTime);
    return LevelDom.wrapAnimationEvent(e);
  }

  String get animationName() => _ptr.animationName;

  num get elapsedTime() => _ptr.elapsedTime;
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

class BeforeLoadEventWrappingImplementation extends EventWrappingImplementation implements BeforeLoadEvent {
  BeforeLoadEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory BeforeLoadEventWrappingImplementation(String type, String url,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("BeforeLoadEvent");
    e.initBeforeLoadEvent(type, canBubble, cancelable, url);
    return LevelDom.wrapBeforeLoadEvent(e);
  }

  String get url() => _ptr.url;
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

class BodyElementEventsImplementation
    extends ElementEventsImplementation implements BodyElementEvents {

  BodyElementEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get beforeUnload() => _get('beforeunload');
  EventListenerList get hashChange() => _get('hashchange');
  EventListenerList get message() => _get('message');
  EventListenerList get offline() => _get('offline');
  EventListenerList get online() => _get('online');
  EventListenerList get orientationChange() => _get('orientationchange');
  EventListenerList get popState() => _get('popstate');
  EventListenerList get resize() => _get('resize');
  EventListenerList get storage() => _get('storage');
  EventListenerList get unLoad() => _get('unload');
}

class BodyElementWrappingImplementation
    extends ElementWrappingImplementation implements BodyElement {

  BodyElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  BodyElementEvents get on() {
    if (_on === null) {
      _on = new BodyElementEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
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

class CloseEventWrappingImplementation extends EventWrappingImplementation implements CloseEvent {
  CloseEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory CloseEventWrappingImplementation(String type, int code, String reason,
      [bool canBubble = true, bool cancelable = true, bool wasClean = true]) {
    final e = dom.document.createEvent("CloseEvent");
    e.initCloseEvent(type, canBubble, cancelable, wasClean, code, reason);
    return LevelDom.wrapCloseEvent(e);
  }

  int get code() => _ptr.code;

  String get reason() => _ptr.reason;

  bool get wasClean() => _ptr.wasClean;
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

class CompositionEventWrappingImplementation extends UIEventWrappingImplementation implements CompositionEvent {
  CompositionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory CompositionEventWrappingImplementation(String type, Window view,
      String data, [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("CompositionEvent");
    e.initCompositionEvent(type, canBubble, cancelable, LevelDom.unwrap(view),
        data);
    return LevelDom.wrapCompositionEvent(e);
  }

  String get data() => _ptr.data;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO - figure out whether classList exists, and if so use that
// rather than the className property that is being used here.

class _CssClassSet implements Set<String> {

  final _element;

  _CssClassSet(this._element);

  String toString() {
    return _formatSet(_read());
  }

  // interface Iterable - BEGIN
  Iterator<String> iterator() {
    return _read().iterator();
  }
  // interface Iterable - END

  // interface Collection - BEGIN
  void forEach(void f(String element)) {
    _read().forEach(f);
  }

  Collection<String> filter(bool f(String element)) {
    return _read().filter(f);
  }

  bool every(bool f(String element)) {
    return _read().every(f);
  }

  bool some(bool f(String element)) {
    return _read().some(f);
  }

  bool isEmpty() {
    return _read().isEmpty();
  }

  int get length() {
    return _read().length;
  }
  // interface Collection - END

  // interface Set - BEGIN
  bool contains(String value) {
    return _read().contains(value);
  }

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

  bool isSubsetOf(Collection<String> collection) {
    return _read().isSubsetOf(collection);
  }

  bool containsAll(Collection<String> collection) {
    return _read().containsAll(collection);
  }

  Set<String> intersection(Collection<String> other) {
    return _read().intersection(other);
  }

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
   * Read the class names from the HTMLElement class property,
   * and put them into a set (duplicates are discarded).
   */
  Set<String> _read() {
    // TODO(mattsh) simplify this once split can take regex.
    Set<String> s = new Set<String>();
    for (String name in _element.className.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty()) {
        s.add(trimmed);
      }
    }
    return s;
  }

  /**
   * Join all the elements of a set into one string and write
   * back to the element.
   */
  void _write(Set s) {
    _element.className = _formatSet(s);
  }

  String _formatSet(Set<String> s) {
    // TODO(mattsh) should be able to pass Set to String.joins http:/b/5398605
    List list = new List.from(s);
    return Strings.join(list, ' ');
  }

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

// WARNING: Do not edit.
// This file was generated by html/scripts/css_code_generator.py

// Source of CSS properties:
//   Source/WebCore/css/CSSPropertyNames.in

// TODO(jacobr): add versions that take numeric values in px, miliseconds, etc.

class CSSStyleDeclarationWrappingImplementation extends DOMWrapperBase implements CSSStyleDeclaration {
  static String _cachedBrowserPrefix;

  CSSStyleDeclarationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory CSSStyleDeclarationWrappingImplementation.css(String css) {
    var style = new Element.tag('div').style;
    style.cssText = css;
    return style;
  }

  factory CSSStyleDeclarationWrappingImplementation() {
    return new CSSStyleDeclarationWrappingImplementation.css('');
  }

  static String get _browserPrefix() {
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

  String get cssText() { return _ptr.cssText; }

  void set cssText(String value) { _ptr.cssText = value; }

  int get length() { return _ptr.length; }

  CSSRule get parentRule() { return LevelDom.wrapCSSRule(_ptr.parentRule); }

  CSSValue getPropertyCSSValue(String propertyName) {
    return LevelDom.wrapCSSValue(_ptr.getPropertyCSSValue(propertyName));
  }

  String getPropertyPriority(String propertyName) {
    return _ptr.getPropertyPriority(propertyName);
  }

  String getPropertyShorthand(String propertyName) {
    return _ptr.getPropertyShorthand(propertyName);
  }

  String getPropertyValue(String propertyName) {
    return _ptr.getPropertyValue(propertyName);
  }

  bool isPropertyImplicit(String propertyName) {
    return _ptr.isPropertyImplicit(propertyName);
  }

  String item(int index) {
    return _ptr.item(index);
  }

  String removeProperty(String propertyName) {
    return _ptr.removeProperty(propertyName);
  }

  void setProperty(String propertyName, String value, [String priority = '']) {
    _ptr.setProperty(propertyName, value, priority);
  }

  String get typeName() { return "CSSStyleDeclaration"; }


  /** Gets the value of "animation" */
  String get animation() =>
    getPropertyValue('${_browserPrefix}animation');

  /** Sets the value of "animation" */
  void set animation(String value) {
    setProperty('${_browserPrefix}animation', value, '');
  }

  /** Gets the value of "animation-delay" */
  String get animationDelay() =>
    getPropertyValue('${_browserPrefix}animation-delay');

  /** Sets the value of "animation-delay" */
  void set animationDelay(String value) {
    setProperty('${_browserPrefix}animation-delay', value, '');
  }

  /** Gets the value of "animation-direction" */
  String get animationDirection() =>
    getPropertyValue('${_browserPrefix}animation-direction');

  /** Sets the value of "animation-direction" */
  void set animationDirection(String value) {
    setProperty('${_browserPrefix}animation-direction', value, '');
  }

  /** Gets the value of "animation-duration" */
  String get animationDuration() =>
    getPropertyValue('${_browserPrefix}animation-duration');

  /** Sets the value of "animation-duration" */
  void set animationDuration(String value) {
    setProperty('${_browserPrefix}animation-duration', value, '');
  }

  /** Gets the value of "animation-fill-mode" */
  String get animationFillMode() =>
    getPropertyValue('${_browserPrefix}animation-fill-mode');

  /** Sets the value of "animation-fill-mode" */
  void set animationFillMode(String value) {
    setProperty('${_browserPrefix}animation-fill-mode', value, '');
  }

  /** Gets the value of "animation-iteration-count" */
  String get animationIterationCount() =>
    getPropertyValue('${_browserPrefix}animation-iteration-count');

  /** Sets the value of "animation-iteration-count" */
  void set animationIterationCount(String value) {
    setProperty('${_browserPrefix}animation-iteration-count', value, '');
  }

  /** Gets the value of "animation-name" */
  String get animationName() =>
    getPropertyValue('${_browserPrefix}animation-name');

  /** Sets the value of "animation-name" */
  void set animationName(String value) {
    setProperty('${_browserPrefix}animation-name', value, '');
  }

  /** Gets the value of "animation-play-state" */
  String get animationPlayState() =>
    getPropertyValue('${_browserPrefix}animation-play-state');

  /** Sets the value of "animation-play-state" */
  void set animationPlayState(String value) {
    setProperty('${_browserPrefix}animation-play-state', value, '');
  }

  /** Gets the value of "animation-timing-function" */
  String get animationTimingFunction() =>
    getPropertyValue('${_browserPrefix}animation-timing-function');

  /** Sets the value of "animation-timing-function" */
  void set animationTimingFunction(String value) {
    setProperty('${_browserPrefix}animation-timing-function', value, '');
  }

  /** Gets the value of "appearance" */
  String get appearance() =>
    getPropertyValue('${_browserPrefix}appearance');

  /** Sets the value of "appearance" */
  void set appearance(String value) {
    setProperty('${_browserPrefix}appearance', value, '');
  }

  /** Gets the value of "backface-visibility" */
  String get backfaceVisibility() =>
    getPropertyValue('${_browserPrefix}backface-visibility');

  /** Sets the value of "backface-visibility" */
  void set backfaceVisibility(String value) {
    setProperty('${_browserPrefix}backface-visibility', value, '');
  }

  /** Gets the value of "background" */
  String get background() =>
    getPropertyValue('background');

  /** Sets the value of "background" */
  void set background(String value) {
    setProperty('background', value, '');
  }

  /** Gets the value of "background-attachment" */
  String get backgroundAttachment() =>
    getPropertyValue('background-attachment');

  /** Sets the value of "background-attachment" */
  void set backgroundAttachment(String value) {
    setProperty('background-attachment', value, '');
  }

  /** Gets the value of "background-clip" */
  String get backgroundClip() =>
    getPropertyValue('background-clip');

  /** Sets the value of "background-clip" */
  void set backgroundClip(String value) {
    setProperty('background-clip', value, '');
  }

  /** Gets the value of "background-color" */
  String get backgroundColor() =>
    getPropertyValue('background-color');

  /** Sets the value of "background-color" */
  void set backgroundColor(String value) {
    setProperty('background-color', value, '');
  }

  /** Gets the value of "background-composite" */
  String get backgroundComposite() =>
    getPropertyValue('${_browserPrefix}background-composite');

  /** Sets the value of "background-composite" */
  void set backgroundComposite(String value) {
    setProperty('${_browserPrefix}background-composite', value, '');
  }

  /** Gets the value of "background-image" */
  String get backgroundImage() =>
    getPropertyValue('background-image');

  /** Sets the value of "background-image" */
  void set backgroundImage(String value) {
    setProperty('background-image', value, '');
  }

  /** Gets the value of "background-origin" */
  String get backgroundOrigin() =>
    getPropertyValue('background-origin');

  /** Sets the value of "background-origin" */
  void set backgroundOrigin(String value) {
    setProperty('background-origin', value, '');
  }

  /** Gets the value of "background-position" */
  String get backgroundPosition() =>
    getPropertyValue('background-position');

  /** Sets the value of "background-position" */
  void set backgroundPosition(String value) {
    setProperty('background-position', value, '');
  }

  /** Gets the value of "background-position-x" */
  String get backgroundPositionX() =>
    getPropertyValue('background-position-x');

  /** Sets the value of "background-position-x" */
  void set backgroundPositionX(String value) {
    setProperty('background-position-x', value, '');
  }

  /** Gets the value of "background-position-y" */
  String get backgroundPositionY() =>
    getPropertyValue('background-position-y');

  /** Sets the value of "background-position-y" */
  void set backgroundPositionY(String value) {
    setProperty('background-position-y', value, '');
  }

  /** Gets the value of "background-repeat" */
  String get backgroundRepeat() =>
    getPropertyValue('background-repeat');

  /** Sets the value of "background-repeat" */
  void set backgroundRepeat(String value) {
    setProperty('background-repeat', value, '');
  }

  /** Gets the value of "background-repeat-x" */
  String get backgroundRepeatX() =>
    getPropertyValue('background-repeat-x');

  /** Sets the value of "background-repeat-x" */
  void set backgroundRepeatX(String value) {
    setProperty('background-repeat-x', value, '');
  }

  /** Gets the value of "background-repeat-y" */
  String get backgroundRepeatY() =>
    getPropertyValue('background-repeat-y');

  /** Sets the value of "background-repeat-y" */
  void set backgroundRepeatY(String value) {
    setProperty('background-repeat-y', value, '');
  }

  /** Gets the value of "background-size" */
  String get backgroundSize() =>
    getPropertyValue('background-size');

  /** Sets the value of "background-size" */
  void set backgroundSize(String value) {
    setProperty('background-size', value, '');
  }

  /** Gets the value of "border" */
  String get border() =>
    getPropertyValue('border');

  /** Sets the value of "border" */
  void set border(String value) {
    setProperty('border', value, '');
  }

  /** Gets the value of "border-after" */
  String get borderAfter() =>
    getPropertyValue('${_browserPrefix}border-after');

  /** Sets the value of "border-after" */
  void set borderAfter(String value) {
    setProperty('${_browserPrefix}border-after', value, '');
  }

  /** Gets the value of "border-after-color" */
  String get borderAfterColor() =>
    getPropertyValue('${_browserPrefix}border-after-color');

  /** Sets the value of "border-after-color" */
  void set borderAfterColor(String value) {
    setProperty('${_browserPrefix}border-after-color', value, '');
  }

  /** Gets the value of "border-after-style" */
  String get borderAfterStyle() =>
    getPropertyValue('${_browserPrefix}border-after-style');

  /** Sets the value of "border-after-style" */
  void set borderAfterStyle(String value) {
    setProperty('${_browserPrefix}border-after-style', value, '');
  }

  /** Gets the value of "border-after-width" */
  String get borderAfterWidth() =>
    getPropertyValue('${_browserPrefix}border-after-width');

  /** Sets the value of "border-after-width" */
  void set borderAfterWidth(String value) {
    setProperty('${_browserPrefix}border-after-width', value, '');
  }

  /** Gets the value of "border-before" */
  String get borderBefore() =>
    getPropertyValue('${_browserPrefix}border-before');

  /** Sets the value of "border-before" */
  void set borderBefore(String value) {
    setProperty('${_browserPrefix}border-before', value, '');
  }

  /** Gets the value of "border-before-color" */
  String get borderBeforeColor() =>
    getPropertyValue('${_browserPrefix}border-before-color');

  /** Sets the value of "border-before-color" */
  void set borderBeforeColor(String value) {
    setProperty('${_browserPrefix}border-before-color', value, '');
  }

  /** Gets the value of "border-before-style" */
  String get borderBeforeStyle() =>
    getPropertyValue('${_browserPrefix}border-before-style');

  /** Sets the value of "border-before-style" */
  void set borderBeforeStyle(String value) {
    setProperty('${_browserPrefix}border-before-style', value, '');
  }

  /** Gets the value of "border-before-width" */
  String get borderBeforeWidth() =>
    getPropertyValue('${_browserPrefix}border-before-width');

  /** Sets the value of "border-before-width" */
  void set borderBeforeWidth(String value) {
    setProperty('${_browserPrefix}border-before-width', value, '');
  }

  /** Gets the value of "border-bottom" */
  String get borderBottom() =>
    getPropertyValue('border-bottom');

  /** Sets the value of "border-bottom" */
  void set borderBottom(String value) {
    setProperty('border-bottom', value, '');
  }

  /** Gets the value of "border-bottom-color" */
  String get borderBottomColor() =>
    getPropertyValue('border-bottom-color');

  /** Sets the value of "border-bottom-color" */
  void set borderBottomColor(String value) {
    setProperty('border-bottom-color', value, '');
  }

  /** Gets the value of "border-bottom-left-radius" */
  String get borderBottomLeftRadius() =>
    getPropertyValue('border-bottom-left-radius');

  /** Sets the value of "border-bottom-left-radius" */
  void set borderBottomLeftRadius(String value) {
    setProperty('border-bottom-left-radius', value, '');
  }

  /** Gets the value of "border-bottom-right-radius" */
  String get borderBottomRightRadius() =>
    getPropertyValue('border-bottom-right-radius');

  /** Sets the value of "border-bottom-right-radius" */
  void set borderBottomRightRadius(String value) {
    setProperty('border-bottom-right-radius', value, '');
  }

  /** Gets the value of "border-bottom-style" */
  String get borderBottomStyle() =>
    getPropertyValue('border-bottom-style');

  /** Sets the value of "border-bottom-style" */
  void set borderBottomStyle(String value) {
    setProperty('border-bottom-style', value, '');
  }

  /** Gets the value of "border-bottom-width" */
  String get borderBottomWidth() =>
    getPropertyValue('border-bottom-width');

  /** Sets the value of "border-bottom-width" */
  void set borderBottomWidth(String value) {
    setProperty('border-bottom-width', value, '');
  }

  /** Gets the value of "border-collapse" */
  String get borderCollapse() =>
    getPropertyValue('border-collapse');

  /** Sets the value of "border-collapse" */
  void set borderCollapse(String value) {
    setProperty('border-collapse', value, '');
  }

  /** Gets the value of "border-color" */
  String get borderColor() =>
    getPropertyValue('border-color');

  /** Sets the value of "border-color" */
  void set borderColor(String value) {
    setProperty('border-color', value, '');
  }

  /** Gets the value of "border-end" */
  String get borderEnd() =>
    getPropertyValue('${_browserPrefix}border-end');

  /** Sets the value of "border-end" */
  void set borderEnd(String value) {
    setProperty('${_browserPrefix}border-end', value, '');
  }

  /** Gets the value of "border-end-color" */
  String get borderEndColor() =>
    getPropertyValue('${_browserPrefix}border-end-color');

  /** Sets the value of "border-end-color" */
  void set borderEndColor(String value) {
    setProperty('${_browserPrefix}border-end-color', value, '');
  }

  /** Gets the value of "border-end-style" */
  String get borderEndStyle() =>
    getPropertyValue('${_browserPrefix}border-end-style');

  /** Sets the value of "border-end-style" */
  void set borderEndStyle(String value) {
    setProperty('${_browserPrefix}border-end-style', value, '');
  }

  /** Gets the value of "border-end-width" */
  String get borderEndWidth() =>
    getPropertyValue('${_browserPrefix}border-end-width');

  /** Sets the value of "border-end-width" */
  void set borderEndWidth(String value) {
    setProperty('${_browserPrefix}border-end-width', value, '');
  }

  /** Gets the value of "border-fit" */
  String get borderFit() =>
    getPropertyValue('${_browserPrefix}border-fit');

  /** Sets the value of "border-fit" */
  void set borderFit(String value) {
    setProperty('${_browserPrefix}border-fit', value, '');
  }

  /** Gets the value of "border-horizontal-spacing" */
  String get borderHorizontalSpacing() =>
    getPropertyValue('${_browserPrefix}border-horizontal-spacing');

  /** Sets the value of "border-horizontal-spacing" */
  void set borderHorizontalSpacing(String value) {
    setProperty('${_browserPrefix}border-horizontal-spacing', value, '');
  }

  /** Gets the value of "border-image" */
  String get borderImage() =>
    getPropertyValue('border-image');

  /** Sets the value of "border-image" */
  void set borderImage(String value) {
    setProperty('border-image', value, '');
  }

  /** Gets the value of "border-image-outset" */
  String get borderImageOutset() =>
    getPropertyValue('border-image-outset');

  /** Sets the value of "border-image-outset" */
  void set borderImageOutset(String value) {
    setProperty('border-image-outset', value, '');
  }

  /** Gets the value of "border-image-repeat" */
  String get borderImageRepeat() =>
    getPropertyValue('border-image-repeat');

  /** Sets the value of "border-image-repeat" */
  void set borderImageRepeat(String value) {
    setProperty('border-image-repeat', value, '');
  }

  /** Gets the value of "border-image-slice" */
  String get borderImageSlice() =>
    getPropertyValue('border-image-slice');

  /** Sets the value of "border-image-slice" */
  void set borderImageSlice(String value) {
    setProperty('border-image-slice', value, '');
  }

  /** Gets the value of "border-image-source" */
  String get borderImageSource() =>
    getPropertyValue('border-image-source');

  /** Sets the value of "border-image-source" */
  void set borderImageSource(String value) {
    setProperty('border-image-source', value, '');
  }

  /** Gets the value of "border-image-width" */
  String get borderImageWidth() =>
    getPropertyValue('border-image-width');

  /** Sets the value of "border-image-width" */
  void set borderImageWidth(String value) {
    setProperty('border-image-width', value, '');
  }

  /** Gets the value of "border-left" */
  String get borderLeft() =>
    getPropertyValue('border-left');

  /** Sets the value of "border-left" */
  void set borderLeft(String value) {
    setProperty('border-left', value, '');
  }

  /** Gets the value of "border-left-color" */
  String get borderLeftColor() =>
    getPropertyValue('border-left-color');

  /** Sets the value of "border-left-color" */
  void set borderLeftColor(String value) {
    setProperty('border-left-color', value, '');
  }

  /** Gets the value of "border-left-style" */
  String get borderLeftStyle() =>
    getPropertyValue('border-left-style');

  /** Sets the value of "border-left-style" */
  void set borderLeftStyle(String value) {
    setProperty('border-left-style', value, '');
  }

  /** Gets the value of "border-left-width" */
  String get borderLeftWidth() =>
    getPropertyValue('border-left-width');

  /** Sets the value of "border-left-width" */
  void set borderLeftWidth(String value) {
    setProperty('border-left-width', value, '');
  }

  /** Gets the value of "border-radius" */
  String get borderRadius() =>
    getPropertyValue('border-radius');

  /** Sets the value of "border-radius" */
  void set borderRadius(String value) {
    setProperty('border-radius', value, '');
  }

  /** Gets the value of "border-right" */
  String get borderRight() =>
    getPropertyValue('border-right');

  /** Sets the value of "border-right" */
  void set borderRight(String value) {
    setProperty('border-right', value, '');
  }

  /** Gets the value of "border-right-color" */
  String get borderRightColor() =>
    getPropertyValue('border-right-color');

  /** Sets the value of "border-right-color" */
  void set borderRightColor(String value) {
    setProperty('border-right-color', value, '');
  }

  /** Gets the value of "border-right-style" */
  String get borderRightStyle() =>
    getPropertyValue('border-right-style');

  /** Sets the value of "border-right-style" */
  void set borderRightStyle(String value) {
    setProperty('border-right-style', value, '');
  }

  /** Gets the value of "border-right-width" */
  String get borderRightWidth() =>
    getPropertyValue('border-right-width');

  /** Sets the value of "border-right-width" */
  void set borderRightWidth(String value) {
    setProperty('border-right-width', value, '');
  }

  /** Gets the value of "border-spacing" */
  String get borderSpacing() =>
    getPropertyValue('border-spacing');

  /** Sets the value of "border-spacing" */
  void set borderSpacing(String value) {
    setProperty('border-spacing', value, '');
  }

  /** Gets the value of "border-start" */
  String get borderStart() =>
    getPropertyValue('${_browserPrefix}border-start');

  /** Sets the value of "border-start" */
  void set borderStart(String value) {
    setProperty('${_browserPrefix}border-start', value, '');
  }

  /** Gets the value of "border-start-color" */
  String get borderStartColor() =>
    getPropertyValue('${_browserPrefix}border-start-color');

  /** Sets the value of "border-start-color" */
  void set borderStartColor(String value) {
    setProperty('${_browserPrefix}border-start-color', value, '');
  }

  /** Gets the value of "border-start-style" */
  String get borderStartStyle() =>
    getPropertyValue('${_browserPrefix}border-start-style');

  /** Sets the value of "border-start-style" */
  void set borderStartStyle(String value) {
    setProperty('${_browserPrefix}border-start-style', value, '');
  }

  /** Gets the value of "border-start-width" */
  String get borderStartWidth() =>
    getPropertyValue('${_browserPrefix}border-start-width');

  /** Sets the value of "border-start-width" */
  void set borderStartWidth(String value) {
    setProperty('${_browserPrefix}border-start-width', value, '');
  }

  /** Gets the value of "border-style" */
  String get borderStyle() =>
    getPropertyValue('border-style');

  /** Sets the value of "border-style" */
  void set borderStyle(String value) {
    setProperty('border-style', value, '');
  }

  /** Gets the value of "border-top" */
  String get borderTop() =>
    getPropertyValue('border-top');

  /** Sets the value of "border-top" */
  void set borderTop(String value) {
    setProperty('border-top', value, '');
  }

  /** Gets the value of "border-top-color" */
  String get borderTopColor() =>
    getPropertyValue('border-top-color');

  /** Sets the value of "border-top-color" */
  void set borderTopColor(String value) {
    setProperty('border-top-color', value, '');
  }

  /** Gets the value of "border-top-left-radius" */
  String get borderTopLeftRadius() =>
    getPropertyValue('border-top-left-radius');

  /** Sets the value of "border-top-left-radius" */
  void set borderTopLeftRadius(String value) {
    setProperty('border-top-left-radius', value, '');
  }

  /** Gets the value of "border-top-right-radius" */
  String get borderTopRightRadius() =>
    getPropertyValue('border-top-right-radius');

  /** Sets the value of "border-top-right-radius" */
  void set borderTopRightRadius(String value) {
    setProperty('border-top-right-radius', value, '');
  }

  /** Gets the value of "border-top-style" */
  String get borderTopStyle() =>
    getPropertyValue('border-top-style');

  /** Sets the value of "border-top-style" */
  void set borderTopStyle(String value) {
    setProperty('border-top-style', value, '');
  }

  /** Gets the value of "border-top-width" */
  String get borderTopWidth() =>
    getPropertyValue('border-top-width');

  /** Sets the value of "border-top-width" */
  void set borderTopWidth(String value) {
    setProperty('border-top-width', value, '');
  }

  /** Gets the value of "border-vertical-spacing" */
  String get borderVerticalSpacing() =>
    getPropertyValue('${_browserPrefix}border-vertical-spacing');

  /** Sets the value of "border-vertical-spacing" */
  void set borderVerticalSpacing(String value) {
    setProperty('${_browserPrefix}border-vertical-spacing', value, '');
  }

  /** Gets the value of "border-width" */
  String get borderWidth() =>
    getPropertyValue('border-width');

  /** Sets the value of "border-width" */
  void set borderWidth(String value) {
    setProperty('border-width', value, '');
  }

  /** Gets the value of "bottom" */
  String get bottom() =>
    getPropertyValue('bottom');

  /** Sets the value of "bottom" */
  void set bottom(String value) {
    setProperty('bottom', value, '');
  }

  /** Gets the value of "box-align" */
  String get boxAlign() =>
    getPropertyValue('${_browserPrefix}box-align');

  /** Sets the value of "box-align" */
  void set boxAlign(String value) {
    setProperty('${_browserPrefix}box-align', value, '');
  }

  /** Gets the value of "box-direction" */
  String get boxDirection() =>
    getPropertyValue('${_browserPrefix}box-direction');

  /** Sets the value of "box-direction" */
  void set boxDirection(String value) {
    setProperty('${_browserPrefix}box-direction', value, '');
  }

  /** Gets the value of "box-flex" */
  String get boxFlex() =>
    getPropertyValue('${_browserPrefix}box-flex');

  /** Sets the value of "box-flex" */
  void set boxFlex(String value) {
    setProperty('${_browserPrefix}box-flex', value, '');
  }

  /** Gets the value of "box-flex-group" */
  String get boxFlexGroup() =>
    getPropertyValue('${_browserPrefix}box-flex-group');

  /** Sets the value of "box-flex-group" */
  void set boxFlexGroup(String value) {
    setProperty('${_browserPrefix}box-flex-group', value, '');
  }

  /** Gets the value of "box-lines" */
  String get boxLines() =>
    getPropertyValue('${_browserPrefix}box-lines');

  /** Sets the value of "box-lines" */
  void set boxLines(String value) {
    setProperty('${_browserPrefix}box-lines', value, '');
  }

  /** Gets the value of "box-ordinal-group" */
  String get boxOrdinalGroup() =>
    getPropertyValue('${_browserPrefix}box-ordinal-group');

  /** Sets the value of "box-ordinal-group" */
  void set boxOrdinalGroup(String value) {
    setProperty('${_browserPrefix}box-ordinal-group', value, '');
  }

  /** Gets the value of "box-orient" */
  String get boxOrient() =>
    getPropertyValue('${_browserPrefix}box-orient');

  /** Sets the value of "box-orient" */
  void set boxOrient(String value) {
    setProperty('${_browserPrefix}box-orient', value, '');
  }

  /** Gets the value of "box-pack" */
  String get boxPack() =>
    getPropertyValue('${_browserPrefix}box-pack');

  /** Sets the value of "box-pack" */
  void set boxPack(String value) {
    setProperty('${_browserPrefix}box-pack', value, '');
  }

  /** Gets the value of "box-reflect" */
  String get boxReflect() =>
    getPropertyValue('${_browserPrefix}box-reflect');

  /** Sets the value of "box-reflect" */
  void set boxReflect(String value) {
    setProperty('${_browserPrefix}box-reflect', value, '');
  }

  /** Gets the value of "box-shadow" */
  String get boxShadow() =>
    getPropertyValue('box-shadow');

  /** Sets the value of "box-shadow" */
  void set boxShadow(String value) {
    setProperty('box-shadow', value, '');
  }

  /** Gets the value of "box-sizing" */
  String get boxSizing() =>
    getPropertyValue('box-sizing');

  /** Sets the value of "box-sizing" */
  void set boxSizing(String value) {
    setProperty('box-sizing', value, '');
  }

  /** Gets the value of "caption-side" */
  String get captionSide() =>
    getPropertyValue('caption-side');

  /** Sets the value of "caption-side" */
  void set captionSide(String value) {
    setProperty('caption-side', value, '');
  }

  /** Gets the value of "clear" */
  String get clear() =>
    getPropertyValue('clear');

  /** Sets the value of "clear" */
  void set clear(String value) {
    setProperty('clear', value, '');
  }

  /** Gets the value of "clip" */
  String get clip() =>
    getPropertyValue('clip');

  /** Sets the value of "clip" */
  void set clip(String value) {
    setProperty('clip', value, '');
  }

  /** Gets the value of "color" */
  String get color() =>
    getPropertyValue('color');

  /** Sets the value of "color" */
  void set color(String value) {
    setProperty('color', value, '');
  }

  /** Gets the value of "color-correction" */
  String get colorCorrection() =>
    getPropertyValue('${_browserPrefix}color-correction');

  /** Sets the value of "color-correction" */
  void set colorCorrection(String value) {
    setProperty('${_browserPrefix}color-correction', value, '');
  }

  /** Gets the value of "column-break-after" */
  String get columnBreakAfter() =>
    getPropertyValue('${_browserPrefix}column-break-after');

  /** Sets the value of "column-break-after" */
  void set columnBreakAfter(String value) {
    setProperty('${_browserPrefix}column-break-after', value, '');
  }

  /** Gets the value of "column-break-before" */
  String get columnBreakBefore() =>
    getPropertyValue('${_browserPrefix}column-break-before');

  /** Sets the value of "column-break-before" */
  void set columnBreakBefore(String value) {
    setProperty('${_browserPrefix}column-break-before', value, '');
  }

  /** Gets the value of "column-break-inside" */
  String get columnBreakInside() =>
    getPropertyValue('${_browserPrefix}column-break-inside');

  /** Sets the value of "column-break-inside" */
  void set columnBreakInside(String value) {
    setProperty('${_browserPrefix}column-break-inside', value, '');
  }

  /** Gets the value of "column-count" */
  String get columnCount() =>
    getPropertyValue('${_browserPrefix}column-count');

  /** Sets the value of "column-count" */
  void set columnCount(String value) {
    setProperty('${_browserPrefix}column-count', value, '');
  }

  /** Gets the value of "column-gap" */
  String get columnGap() =>
    getPropertyValue('${_browserPrefix}column-gap');

  /** Sets the value of "column-gap" */
  void set columnGap(String value) {
    setProperty('${_browserPrefix}column-gap', value, '');
  }

  /** Gets the value of "column-rule" */
  String get columnRule() =>
    getPropertyValue('${_browserPrefix}column-rule');

  /** Sets the value of "column-rule" */
  void set columnRule(String value) {
    setProperty('${_browserPrefix}column-rule', value, '');
  }

  /** Gets the value of "column-rule-color" */
  String get columnRuleColor() =>
    getPropertyValue('${_browserPrefix}column-rule-color');

  /** Sets the value of "column-rule-color" */
  void set columnRuleColor(String value) {
    setProperty('${_browserPrefix}column-rule-color', value, '');
  }

  /** Gets the value of "column-rule-style" */
  String get columnRuleStyle() =>
    getPropertyValue('${_browserPrefix}column-rule-style');

  /** Sets the value of "column-rule-style" */
  void set columnRuleStyle(String value) {
    setProperty('${_browserPrefix}column-rule-style', value, '');
  }

  /** Gets the value of "column-rule-width" */
  String get columnRuleWidth() =>
    getPropertyValue('${_browserPrefix}column-rule-width');

  /** Sets the value of "column-rule-width" */
  void set columnRuleWidth(String value) {
    setProperty('${_browserPrefix}column-rule-width', value, '');
  }

  /** Gets the value of "column-span" */
  String get columnSpan() =>
    getPropertyValue('${_browserPrefix}column-span');

  /** Sets the value of "column-span" */
  void set columnSpan(String value) {
    setProperty('${_browserPrefix}column-span', value, '');
  }

  /** Gets the value of "column-width" */
  String get columnWidth() =>
    getPropertyValue('${_browserPrefix}column-width');

  /** Sets the value of "column-width" */
  void set columnWidth(String value) {
    setProperty('${_browserPrefix}column-width', value, '');
  }

  /** Gets the value of "columns" */
  String get columns() =>
    getPropertyValue('${_browserPrefix}columns');

  /** Sets the value of "columns" */
  void set columns(String value) {
    setProperty('${_browserPrefix}columns', value, '');
  }

  /** Gets the value of "content" */
  String get content() =>
    getPropertyValue('content');

  /** Sets the value of "content" */
  void set content(String value) {
    setProperty('content', value, '');
  }

  /** Gets the value of "counter-increment" */
  String get counterIncrement() =>
    getPropertyValue('counter-increment');

  /** Sets the value of "counter-increment" */
  void set counterIncrement(String value) {
    setProperty('counter-increment', value, '');
  }

  /** Gets the value of "counter-reset" */
  String get counterReset() =>
    getPropertyValue('counter-reset');

  /** Sets the value of "counter-reset" */
  void set counterReset(String value) {
    setProperty('counter-reset', value, '');
  }

  /** Gets the value of "cursor" */
  String get cursor() =>
    getPropertyValue('cursor');

  /** Sets the value of "cursor" */
  void set cursor(String value) {
    setProperty('cursor', value, '');
  }

  /** Gets the value of "direction" */
  String get direction() =>
    getPropertyValue('direction');

  /** Sets the value of "direction" */
  void set direction(String value) {
    setProperty('direction', value, '');
  }

  /** Gets the value of "display" */
  String get display() =>
    getPropertyValue('display');

  /** Sets the value of "display" */
  void set display(String value) {
    setProperty('display', value, '');
  }

  /** Gets the value of "empty-cells" */
  String get emptyCells() =>
    getPropertyValue('empty-cells');

  /** Sets the value of "empty-cells" */
  void set emptyCells(String value) {
    setProperty('empty-cells', value, '');
  }

  /** Gets the value of "filter" */
  String get filter() =>
    getPropertyValue('${_browserPrefix}filter');

  /** Sets the value of "filter" */
  void set filter(String value) {
    setProperty('${_browserPrefix}filter', value, '');
  }

  /** Gets the value of "flex-align" */
  String get flexAlign() =>
    getPropertyValue('${_browserPrefix}flex-align');

  /** Sets the value of "flex-align" */
  void set flexAlign(String value) {
    setProperty('${_browserPrefix}flex-align', value, '');
  }

  /** Gets the value of "flex-flow" */
  String get flexFlow() =>
    getPropertyValue('${_browserPrefix}flex-flow');

  /** Sets the value of "flex-flow" */
  void set flexFlow(String value) {
    setProperty('${_browserPrefix}flex-flow', value, '');
  }

  /** Gets the value of "flex-order" */
  String get flexOrder() =>
    getPropertyValue('${_browserPrefix}flex-order');

  /** Sets the value of "flex-order" */
  void set flexOrder(String value) {
    setProperty('${_browserPrefix}flex-order', value, '');
  }

  /** Gets the value of "flex-pack" */
  String get flexPack() =>
    getPropertyValue('${_browserPrefix}flex-pack');

  /** Sets the value of "flex-pack" */
  void set flexPack(String value) {
    setProperty('${_browserPrefix}flex-pack', value, '');
  }

  /** Gets the value of "float" */
  String get float() =>
    getPropertyValue('float');

  /** Sets the value of "float" */
  void set float(String value) {
    setProperty('float', value, '');
  }

  /** Gets the value of "flow-from" */
  String get flowFrom() =>
    getPropertyValue('${_browserPrefix}flow-from');

  /** Sets the value of "flow-from" */
  void set flowFrom(String value) {
    setProperty('${_browserPrefix}flow-from', value, '');
  }

  /** Gets the value of "flow-into" */
  String get flowInto() =>
    getPropertyValue('${_browserPrefix}flow-into');

  /** Sets the value of "flow-into" */
  void set flowInto(String value) {
    setProperty('${_browserPrefix}flow-into', value, '');
  }

  /** Gets the value of "font" */
  String get font() =>
    getPropertyValue('font');

  /** Sets the value of "font" */
  void set font(String value) {
    setProperty('font', value, '');
  }

  /** Gets the value of "font-family" */
  String get fontFamily() =>
    getPropertyValue('font-family');

  /** Sets the value of "font-family" */
  void set fontFamily(String value) {
    setProperty('font-family', value, '');
  }

  /** Gets the value of "font-feature-settings" */
  String get fontFeatureSettings() =>
    getPropertyValue('${_browserPrefix}font-feature-settings');

  /** Sets the value of "font-feature-settings" */
  void set fontFeatureSettings(String value) {
    setProperty('${_browserPrefix}font-feature-settings', value, '');
  }

  /** Gets the value of "font-size" */
  String get fontSize() =>
    getPropertyValue('font-size');

  /** Sets the value of "font-size" */
  void set fontSize(String value) {
    setProperty('font-size', value, '');
  }

  /** Gets the value of "font-size-delta" */
  String get fontSizeDelta() =>
    getPropertyValue('${_browserPrefix}font-size-delta');

  /** Sets the value of "font-size-delta" */
  void set fontSizeDelta(String value) {
    setProperty('${_browserPrefix}font-size-delta', value, '');
  }

  /** Gets the value of "font-smoothing" */
  String get fontSmoothing() =>
    getPropertyValue('${_browserPrefix}font-smoothing');

  /** Sets the value of "font-smoothing" */
  void set fontSmoothing(String value) {
    setProperty('${_browserPrefix}font-smoothing', value, '');
  }

  /** Gets the value of "font-stretch" */
  String get fontStretch() =>
    getPropertyValue('font-stretch');

  /** Sets the value of "font-stretch" */
  void set fontStretch(String value) {
    setProperty('font-stretch', value, '');
  }

  /** Gets the value of "font-style" */
  String get fontStyle() =>
    getPropertyValue('font-style');

  /** Sets the value of "font-style" */
  void set fontStyle(String value) {
    setProperty('font-style', value, '');
  }

  /** Gets the value of "font-variant" */
  String get fontVariant() =>
    getPropertyValue('font-variant');

  /** Sets the value of "font-variant" */
  void set fontVariant(String value) {
    setProperty('font-variant', value, '');
  }

  /** Gets the value of "font-weight" */
  String get fontWeight() =>
    getPropertyValue('font-weight');

  /** Sets the value of "font-weight" */
  void set fontWeight(String value) {
    setProperty('font-weight', value, '');
  }

  /** Gets the value of "height" */
  String get height() =>
    getPropertyValue('height');

  /** Sets the value of "height" */
  void set height(String value) {
    setProperty('height', value, '');
  }

  /** Gets the value of "highlight" */
  String get highlight() =>
    getPropertyValue('${_browserPrefix}highlight');

  /** Sets the value of "highlight" */
  void set highlight(String value) {
    setProperty('${_browserPrefix}highlight', value, '');
  }

  /** Gets the value of "hyphenate-character" */
  String get hyphenateCharacter() =>
    getPropertyValue('${_browserPrefix}hyphenate-character');

  /** Sets the value of "hyphenate-character" */
  void set hyphenateCharacter(String value) {
    setProperty('${_browserPrefix}hyphenate-character', value, '');
  }

  /** Gets the value of "hyphenate-limit-after" */
  String get hyphenateLimitAfter() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-after');

  /** Sets the value of "hyphenate-limit-after" */
  void set hyphenateLimitAfter(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-after', value, '');
  }

  /** Gets the value of "hyphenate-limit-before" */
  String get hyphenateLimitBefore() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-before');

  /** Sets the value of "hyphenate-limit-before" */
  void set hyphenateLimitBefore(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-before', value, '');
  }

  /** Gets the value of "hyphenate-limit-lines" */
  String get hyphenateLimitLines() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-lines');

  /** Sets the value of "hyphenate-limit-lines" */
  void set hyphenateLimitLines(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-lines', value, '');
  }

  /** Gets the value of "hyphens" */
  String get hyphens() =>
    getPropertyValue('${_browserPrefix}hyphens');

  /** Sets the value of "hyphens" */
  void set hyphens(String value) {
    setProperty('${_browserPrefix}hyphens', value, '');
  }

  /** Gets the value of "image-rendering" */
  String get imageRendering() =>
    getPropertyValue('image-rendering');

  /** Sets the value of "image-rendering" */
  void set imageRendering(String value) {
    setProperty('image-rendering', value, '');
  }

  /** Gets the value of "left" */
  String get left() =>
    getPropertyValue('left');

  /** Sets the value of "left" */
  void set left(String value) {
    setProperty('left', value, '');
  }

  /** Gets the value of "letter-spacing" */
  String get letterSpacing() =>
    getPropertyValue('letter-spacing');

  /** Sets the value of "letter-spacing" */
  void set letterSpacing(String value) {
    setProperty('letter-spacing', value, '');
  }

  /** Gets the value of "line-box-contain" */
  String get lineBoxContain() =>
    getPropertyValue('${_browserPrefix}line-box-contain');

  /** Sets the value of "line-box-contain" */
  void set lineBoxContain(String value) {
    setProperty('${_browserPrefix}line-box-contain', value, '');
  }

  /** Gets the value of "line-break" */
  String get lineBreak() =>
    getPropertyValue('${_browserPrefix}line-break');

  /** Sets the value of "line-break" */
  void set lineBreak(String value) {
    setProperty('${_browserPrefix}line-break', value, '');
  }

  /** Gets the value of "line-clamp" */
  String get lineClamp() =>
    getPropertyValue('${_browserPrefix}line-clamp');

  /** Sets the value of "line-clamp" */
  void set lineClamp(String value) {
    setProperty('${_browserPrefix}line-clamp', value, '');
  }

  /** Gets the value of "line-height" */
  String get lineHeight() =>
    getPropertyValue('line-height');

  /** Sets the value of "line-height" */
  void set lineHeight(String value) {
    setProperty('line-height', value, '');
  }

  /** Gets the value of "list-style" */
  String get listStyle() =>
    getPropertyValue('list-style');

  /** Sets the value of "list-style" */
  void set listStyle(String value) {
    setProperty('list-style', value, '');
  }

  /** Gets the value of "list-style-image" */
  String get listStyleImage() =>
    getPropertyValue('list-style-image');

  /** Sets the value of "list-style-image" */
  void set listStyleImage(String value) {
    setProperty('list-style-image', value, '');
  }

  /** Gets the value of "list-style-position" */
  String get listStylePosition() =>
    getPropertyValue('list-style-position');

  /** Sets the value of "list-style-position" */
  void set listStylePosition(String value) {
    setProperty('list-style-position', value, '');
  }

  /** Gets the value of "list-style-type" */
  String get listStyleType() =>
    getPropertyValue('list-style-type');

  /** Sets the value of "list-style-type" */
  void set listStyleType(String value) {
    setProperty('list-style-type', value, '');
  }

  /** Gets the value of "locale" */
  String get locale() =>
    getPropertyValue('${_browserPrefix}locale');

  /** Sets the value of "locale" */
  void set locale(String value) {
    setProperty('${_browserPrefix}locale', value, '');
  }

  /** Gets the value of "logical-height" */
  String get logicalHeight() =>
    getPropertyValue('${_browserPrefix}logical-height');

  /** Sets the value of "logical-height" */
  void set logicalHeight(String value) {
    setProperty('${_browserPrefix}logical-height', value, '');
  }

  /** Gets the value of "logical-width" */
  String get logicalWidth() =>
    getPropertyValue('${_browserPrefix}logical-width');

  /** Sets the value of "logical-width" */
  void set logicalWidth(String value) {
    setProperty('${_browserPrefix}logical-width', value, '');
  }

  /** Gets the value of "margin" */
  String get margin() =>
    getPropertyValue('margin');

  /** Sets the value of "margin" */
  void set margin(String value) {
    setProperty('margin', value, '');
  }

  /** Gets the value of "margin-after" */
  String get marginAfter() =>
    getPropertyValue('${_browserPrefix}margin-after');

  /** Sets the value of "margin-after" */
  void set marginAfter(String value) {
    setProperty('${_browserPrefix}margin-after', value, '');
  }

  /** Gets the value of "margin-after-collapse" */
  String get marginAfterCollapse() =>
    getPropertyValue('${_browserPrefix}margin-after-collapse');

  /** Sets the value of "margin-after-collapse" */
  void set marginAfterCollapse(String value) {
    setProperty('${_browserPrefix}margin-after-collapse', value, '');
  }

  /** Gets the value of "margin-before" */
  String get marginBefore() =>
    getPropertyValue('${_browserPrefix}margin-before');

  /** Sets the value of "margin-before" */
  void set marginBefore(String value) {
    setProperty('${_browserPrefix}margin-before', value, '');
  }

  /** Gets the value of "margin-before-collapse" */
  String get marginBeforeCollapse() =>
    getPropertyValue('${_browserPrefix}margin-before-collapse');

  /** Sets the value of "margin-before-collapse" */
  void set marginBeforeCollapse(String value) {
    setProperty('${_browserPrefix}margin-before-collapse', value, '');
  }

  /** Gets the value of "margin-bottom" */
  String get marginBottom() =>
    getPropertyValue('margin-bottom');

  /** Sets the value of "margin-bottom" */
  void set marginBottom(String value) {
    setProperty('margin-bottom', value, '');
  }

  /** Gets the value of "margin-bottom-collapse" */
  String get marginBottomCollapse() =>
    getPropertyValue('${_browserPrefix}margin-bottom-collapse');

  /** Sets the value of "margin-bottom-collapse" */
  void set marginBottomCollapse(String value) {
    setProperty('${_browserPrefix}margin-bottom-collapse', value, '');
  }

  /** Gets the value of "margin-collapse" */
  String get marginCollapse() =>
    getPropertyValue('${_browserPrefix}margin-collapse');

  /** Sets the value of "margin-collapse" */
  void set marginCollapse(String value) {
    setProperty('${_browserPrefix}margin-collapse', value, '');
  }

  /** Gets the value of "margin-end" */
  String get marginEnd() =>
    getPropertyValue('${_browserPrefix}margin-end');

  /** Sets the value of "margin-end" */
  void set marginEnd(String value) {
    setProperty('${_browserPrefix}margin-end', value, '');
  }

  /** Gets the value of "margin-left" */
  String get marginLeft() =>
    getPropertyValue('margin-left');

  /** Sets the value of "margin-left" */
  void set marginLeft(String value) {
    setProperty('margin-left', value, '');
  }

  /** Gets the value of "margin-right" */
  String get marginRight() =>
    getPropertyValue('margin-right');

  /** Sets the value of "margin-right" */
  void set marginRight(String value) {
    setProperty('margin-right', value, '');
  }

  /** Gets the value of "margin-start" */
  String get marginStart() =>
    getPropertyValue('${_browserPrefix}margin-start');

  /** Sets the value of "margin-start" */
  void set marginStart(String value) {
    setProperty('${_browserPrefix}margin-start', value, '');
  }

  /** Gets the value of "margin-top" */
  String get marginTop() =>
    getPropertyValue('margin-top');

  /** Sets the value of "margin-top" */
  void set marginTop(String value) {
    setProperty('margin-top', value, '');
  }

  /** Gets the value of "margin-top-collapse" */
  String get marginTopCollapse() =>
    getPropertyValue('${_browserPrefix}margin-top-collapse');

  /** Sets the value of "margin-top-collapse" */
  void set marginTopCollapse(String value) {
    setProperty('${_browserPrefix}margin-top-collapse', value, '');
  }

  /** Gets the value of "marquee" */
  String get marquee() =>
    getPropertyValue('${_browserPrefix}marquee');

  /** Sets the value of "marquee" */
  void set marquee(String value) {
    setProperty('${_browserPrefix}marquee', value, '');
  }

  /** Gets the value of "marquee-direction" */
  String get marqueeDirection() =>
    getPropertyValue('${_browserPrefix}marquee-direction');

  /** Sets the value of "marquee-direction" */
  void set marqueeDirection(String value) {
    setProperty('${_browserPrefix}marquee-direction', value, '');
  }

  /** Gets the value of "marquee-increment" */
  String get marqueeIncrement() =>
    getPropertyValue('${_browserPrefix}marquee-increment');

  /** Sets the value of "marquee-increment" */
  void set marqueeIncrement(String value) {
    setProperty('${_browserPrefix}marquee-increment', value, '');
  }

  /** Gets the value of "marquee-repetition" */
  String get marqueeRepetition() =>
    getPropertyValue('${_browserPrefix}marquee-repetition');

  /** Sets the value of "marquee-repetition" */
  void set marqueeRepetition(String value) {
    setProperty('${_browserPrefix}marquee-repetition', value, '');
  }

  /** Gets the value of "marquee-speed" */
  String get marqueeSpeed() =>
    getPropertyValue('${_browserPrefix}marquee-speed');

  /** Sets the value of "marquee-speed" */
  void set marqueeSpeed(String value) {
    setProperty('${_browserPrefix}marquee-speed', value, '');
  }

  /** Gets the value of "marquee-style" */
  String get marqueeStyle() =>
    getPropertyValue('${_browserPrefix}marquee-style');

  /** Sets the value of "marquee-style" */
  void set marqueeStyle(String value) {
    setProperty('${_browserPrefix}marquee-style', value, '');
  }

  /** Gets the value of "mask" */
  String get mask() =>
    getPropertyValue('${_browserPrefix}mask');

  /** Sets the value of "mask" */
  void set mask(String value) {
    setProperty('${_browserPrefix}mask', value, '');
  }

  /** Gets the value of "mask-attachment" */
  String get maskAttachment() =>
    getPropertyValue('${_browserPrefix}mask-attachment');

  /** Sets the value of "mask-attachment" */
  void set maskAttachment(String value) {
    setProperty('${_browserPrefix}mask-attachment', value, '');
  }

  /** Gets the value of "mask-box-image" */
  String get maskBoxImage() =>
    getPropertyValue('${_browserPrefix}mask-box-image');

  /** Sets the value of "mask-box-image" */
  void set maskBoxImage(String value) {
    setProperty('${_browserPrefix}mask-box-image', value, '');
  }

  /** Gets the value of "mask-box-image-outset" */
  String get maskBoxImageOutset() =>
    getPropertyValue('${_browserPrefix}mask-box-image-outset');

  /** Sets the value of "mask-box-image-outset" */
  void set maskBoxImageOutset(String value) {
    setProperty('${_browserPrefix}mask-box-image-outset', value, '');
  }

  /** Gets the value of "mask-box-image-repeat" */
  String get maskBoxImageRepeat() =>
    getPropertyValue('${_browserPrefix}mask-box-image-repeat');

  /** Sets the value of "mask-box-image-repeat" */
  void set maskBoxImageRepeat(String value) {
    setProperty('${_browserPrefix}mask-box-image-repeat', value, '');
  }

  /** Gets the value of "mask-box-image-slice" */
  String get maskBoxImageSlice() =>
    getPropertyValue('${_browserPrefix}mask-box-image-slice');

  /** Sets the value of "mask-box-image-slice" */
  void set maskBoxImageSlice(String value) {
    setProperty('${_browserPrefix}mask-box-image-slice', value, '');
  }

  /** Gets the value of "mask-box-image-source" */
  String get maskBoxImageSource() =>
    getPropertyValue('${_browserPrefix}mask-box-image-source');

  /** Sets the value of "mask-box-image-source" */
  void set maskBoxImageSource(String value) {
    setProperty('${_browserPrefix}mask-box-image-source', value, '');
  }

  /** Gets the value of "mask-box-image-width" */
  String get maskBoxImageWidth() =>
    getPropertyValue('${_browserPrefix}mask-box-image-width');

  /** Sets the value of "mask-box-image-width" */
  void set maskBoxImageWidth(String value) {
    setProperty('${_browserPrefix}mask-box-image-width', value, '');
  }

  /** Gets the value of "mask-clip" */
  String get maskClip() =>
    getPropertyValue('${_browserPrefix}mask-clip');

  /** Sets the value of "mask-clip" */
  void set maskClip(String value) {
    setProperty('${_browserPrefix}mask-clip', value, '');
  }

  /** Gets the value of "mask-composite" */
  String get maskComposite() =>
    getPropertyValue('${_browserPrefix}mask-composite');

  /** Sets the value of "mask-composite" */
  void set maskComposite(String value) {
    setProperty('${_browserPrefix}mask-composite', value, '');
  }

  /** Gets the value of "mask-image" */
  String get maskImage() =>
    getPropertyValue('${_browserPrefix}mask-image');

  /** Sets the value of "mask-image" */
  void set maskImage(String value) {
    setProperty('${_browserPrefix}mask-image', value, '');
  }

  /** Gets the value of "mask-origin" */
  String get maskOrigin() =>
    getPropertyValue('${_browserPrefix}mask-origin');

  /** Sets the value of "mask-origin" */
  void set maskOrigin(String value) {
    setProperty('${_browserPrefix}mask-origin', value, '');
  }

  /** Gets the value of "mask-position" */
  String get maskPosition() =>
    getPropertyValue('${_browserPrefix}mask-position');

  /** Sets the value of "mask-position" */
  void set maskPosition(String value) {
    setProperty('${_browserPrefix}mask-position', value, '');
  }

  /** Gets the value of "mask-position-x" */
  String get maskPositionX() =>
    getPropertyValue('${_browserPrefix}mask-position-x');

  /** Sets the value of "mask-position-x" */
  void set maskPositionX(String value) {
    setProperty('${_browserPrefix}mask-position-x', value, '');
  }

  /** Gets the value of "mask-position-y" */
  String get maskPositionY() =>
    getPropertyValue('${_browserPrefix}mask-position-y');

  /** Sets the value of "mask-position-y" */
  void set maskPositionY(String value) {
    setProperty('${_browserPrefix}mask-position-y', value, '');
  }

  /** Gets the value of "mask-repeat" */
  String get maskRepeat() =>
    getPropertyValue('${_browserPrefix}mask-repeat');

  /** Sets the value of "mask-repeat" */
  void set maskRepeat(String value) {
    setProperty('${_browserPrefix}mask-repeat', value, '');
  }

  /** Gets the value of "mask-repeat-x" */
  String get maskRepeatX() =>
    getPropertyValue('${_browserPrefix}mask-repeat-x');

  /** Sets the value of "mask-repeat-x" */
  void set maskRepeatX(String value) {
    setProperty('${_browserPrefix}mask-repeat-x', value, '');
  }

  /** Gets the value of "mask-repeat-y" */
  String get maskRepeatY() =>
    getPropertyValue('${_browserPrefix}mask-repeat-y');

  /** Sets the value of "mask-repeat-y" */
  void set maskRepeatY(String value) {
    setProperty('${_browserPrefix}mask-repeat-y', value, '');
  }

  /** Gets the value of "mask-size" */
  String get maskSize() =>
    getPropertyValue('${_browserPrefix}mask-size');

  /** Sets the value of "mask-size" */
  void set maskSize(String value) {
    setProperty('${_browserPrefix}mask-size', value, '');
  }

  /** Gets the value of "match-nearest-mail-blockquote-color" */
  String get matchNearestMailBlockquoteColor() =>
    getPropertyValue('${_browserPrefix}match-nearest-mail-blockquote-color');

  /** Sets the value of "match-nearest-mail-blockquote-color" */
  void set matchNearestMailBlockquoteColor(String value) {
    setProperty('${_browserPrefix}match-nearest-mail-blockquote-color', value, '');
  }

  /** Gets the value of "max-height" */
  String get maxHeight() =>
    getPropertyValue('max-height');

  /** Sets the value of "max-height" */
  void set maxHeight(String value) {
    setProperty('max-height', value, '');
  }

  /** Gets the value of "max-logical-height" */
  String get maxLogicalHeight() =>
    getPropertyValue('${_browserPrefix}max-logical-height');

  /** Sets the value of "max-logical-height" */
  void set maxLogicalHeight(String value) {
    setProperty('${_browserPrefix}max-logical-height', value, '');
  }

  /** Gets the value of "max-logical-width" */
  String get maxLogicalWidth() =>
    getPropertyValue('${_browserPrefix}max-logical-width');

  /** Sets the value of "max-logical-width" */
  void set maxLogicalWidth(String value) {
    setProperty('${_browserPrefix}max-logical-width', value, '');
  }

  /** Gets the value of "max-width" */
  String get maxWidth() =>
    getPropertyValue('max-width');

  /** Sets the value of "max-width" */
  void set maxWidth(String value) {
    setProperty('max-width', value, '');
  }

  /** Gets the value of "min-height" */
  String get minHeight() =>
    getPropertyValue('min-height');

  /** Sets the value of "min-height" */
  void set minHeight(String value) {
    setProperty('min-height', value, '');
  }

  /** Gets the value of "min-logical-height" */
  String get minLogicalHeight() =>
    getPropertyValue('${_browserPrefix}min-logical-height');

  /** Sets the value of "min-logical-height" */
  void set minLogicalHeight(String value) {
    setProperty('${_browserPrefix}min-logical-height', value, '');
  }

  /** Gets the value of "min-logical-width" */
  String get minLogicalWidth() =>
    getPropertyValue('${_browserPrefix}min-logical-width');

  /** Sets the value of "min-logical-width" */
  void set minLogicalWidth(String value) {
    setProperty('${_browserPrefix}min-logical-width', value, '');
  }

  /** Gets the value of "min-width" */
  String get minWidth() =>
    getPropertyValue('min-width');

  /** Sets the value of "min-width" */
  void set minWidth(String value) {
    setProperty('min-width', value, '');
  }

  /** Gets the value of "nbsp-mode" */
  String get nbspMode() =>
    getPropertyValue('${_browserPrefix}nbsp-mode');

  /** Sets the value of "nbsp-mode" */
  void set nbspMode(String value) {
    setProperty('${_browserPrefix}nbsp-mode', value, '');
  }

  /** Gets the value of "opacity" */
  String get opacity() =>
    getPropertyValue('opacity');

  /** Sets the value of "opacity" */
  void set opacity(String value) {
    setProperty('opacity', value, '');
  }

  /** Gets the value of "orphans" */
  String get orphans() =>
    getPropertyValue('orphans');

  /** Sets the value of "orphans" */
  void set orphans(String value) {
    setProperty('orphans', value, '');
  }

  /** Gets the value of "outline" */
  String get outline() =>
    getPropertyValue('outline');

  /** Sets the value of "outline" */
  void set outline(String value) {
    setProperty('outline', value, '');
  }

  /** Gets the value of "outline-color" */
  String get outlineColor() =>
    getPropertyValue('outline-color');

  /** Sets the value of "outline-color" */
  void set outlineColor(String value) {
    setProperty('outline-color', value, '');
  }

  /** Gets the value of "outline-offset" */
  String get outlineOffset() =>
    getPropertyValue('outline-offset');

  /** Sets the value of "outline-offset" */
  void set outlineOffset(String value) {
    setProperty('outline-offset', value, '');
  }

  /** Gets the value of "outline-style" */
  String get outlineStyle() =>
    getPropertyValue('outline-style');

  /** Sets the value of "outline-style" */
  void set outlineStyle(String value) {
    setProperty('outline-style', value, '');
  }

  /** Gets the value of "outline-width" */
  String get outlineWidth() =>
    getPropertyValue('outline-width');

  /** Sets the value of "outline-width" */
  void set outlineWidth(String value) {
    setProperty('outline-width', value, '');
  }

  /** Gets the value of "overflow" */
  String get overflow() =>
    getPropertyValue('overflow');

  /** Sets the value of "overflow" */
  void set overflow(String value) {
    setProperty('overflow', value, '');
  }

  /** Gets the value of "overflow-x" */
  String get overflowX() =>
    getPropertyValue('overflow-x');

  /** Sets the value of "overflow-x" */
  void set overflowX(String value) {
    setProperty('overflow-x', value, '');
  }

  /** Gets the value of "overflow-y" */
  String get overflowY() =>
    getPropertyValue('overflow-y');

  /** Sets the value of "overflow-y" */
  void set overflowY(String value) {
    setProperty('overflow-y', value, '');
  }

  /** Gets the value of "padding" */
  String get padding() =>
    getPropertyValue('padding');

  /** Sets the value of "padding" */
  void set padding(String value) {
    setProperty('padding', value, '');
  }

  /** Gets the value of "padding-after" */
  String get paddingAfter() =>
    getPropertyValue('${_browserPrefix}padding-after');

  /** Sets the value of "padding-after" */
  void set paddingAfter(String value) {
    setProperty('${_browserPrefix}padding-after', value, '');
  }

  /** Gets the value of "padding-before" */
  String get paddingBefore() =>
    getPropertyValue('${_browserPrefix}padding-before');

  /** Sets the value of "padding-before" */
  void set paddingBefore(String value) {
    setProperty('${_browserPrefix}padding-before', value, '');
  }

  /** Gets the value of "padding-bottom" */
  String get paddingBottom() =>
    getPropertyValue('padding-bottom');

  /** Sets the value of "padding-bottom" */
  void set paddingBottom(String value) {
    setProperty('padding-bottom', value, '');
  }

  /** Gets the value of "padding-end" */
  String get paddingEnd() =>
    getPropertyValue('${_browserPrefix}padding-end');

  /** Sets the value of "padding-end" */
  void set paddingEnd(String value) {
    setProperty('${_browserPrefix}padding-end', value, '');
  }

  /** Gets the value of "padding-left" */
  String get paddingLeft() =>
    getPropertyValue('padding-left');

  /** Sets the value of "padding-left" */
  void set paddingLeft(String value) {
    setProperty('padding-left', value, '');
  }

  /** Gets the value of "padding-right" */
  String get paddingRight() =>
    getPropertyValue('padding-right');

  /** Sets the value of "padding-right" */
  void set paddingRight(String value) {
    setProperty('padding-right', value, '');
  }

  /** Gets the value of "padding-start" */
  String get paddingStart() =>
    getPropertyValue('${_browserPrefix}padding-start');

  /** Sets the value of "padding-start" */
  void set paddingStart(String value) {
    setProperty('${_browserPrefix}padding-start', value, '');
  }

  /** Gets the value of "padding-top" */
  String get paddingTop() =>
    getPropertyValue('padding-top');

  /** Sets the value of "padding-top" */
  void set paddingTop(String value) {
    setProperty('padding-top', value, '');
  }

  /** Gets the value of "page" */
  String get page() =>
    getPropertyValue('page');

  /** Sets the value of "page" */
  void set page(String value) {
    setProperty('page', value, '');
  }

  /** Gets the value of "page-break-after" */
  String get pageBreakAfter() =>
    getPropertyValue('page-break-after');

  /** Sets the value of "page-break-after" */
  void set pageBreakAfter(String value) {
    setProperty('page-break-after', value, '');
  }

  /** Gets the value of "page-break-before" */
  String get pageBreakBefore() =>
    getPropertyValue('page-break-before');

  /** Sets the value of "page-break-before" */
  void set pageBreakBefore(String value) {
    setProperty('page-break-before', value, '');
  }

  /** Gets the value of "page-break-inside" */
  String get pageBreakInside() =>
    getPropertyValue('page-break-inside');

  /** Sets the value of "page-break-inside" */
  void set pageBreakInside(String value) {
    setProperty('page-break-inside', value, '');
  }

  /** Gets the value of "perspective" */
  String get perspective() =>
    getPropertyValue('${_browserPrefix}perspective');

  /** Sets the value of "perspective" */
  void set perspective(String value) {
    setProperty('${_browserPrefix}perspective', value, '');
  }

  /** Gets the value of "perspective-origin" */
  String get perspectiveOrigin() =>
    getPropertyValue('${_browserPrefix}perspective-origin');

  /** Sets the value of "perspective-origin" */
  void set perspectiveOrigin(String value) {
    setProperty('${_browserPrefix}perspective-origin', value, '');
  }

  /** Gets the value of "perspective-origin-x" */
  String get perspectiveOriginX() =>
    getPropertyValue('${_browserPrefix}perspective-origin-x');

  /** Sets the value of "perspective-origin-x" */
  void set perspectiveOriginX(String value) {
    setProperty('${_browserPrefix}perspective-origin-x', value, '');
  }

  /** Gets the value of "perspective-origin-y" */
  String get perspectiveOriginY() =>
    getPropertyValue('${_browserPrefix}perspective-origin-y');

  /** Sets the value of "perspective-origin-y" */
  void set perspectiveOriginY(String value) {
    setProperty('${_browserPrefix}perspective-origin-y', value, '');
  }

  /** Gets the value of "pointer-events" */
  String get pointerEvents() =>
    getPropertyValue('pointer-events');

  /** Sets the value of "pointer-events" */
  void set pointerEvents(String value) {
    setProperty('pointer-events', value, '');
  }

  /** Gets the value of "position" */
  String get position() =>
    getPropertyValue('position');

  /** Sets the value of "position" */
  void set position(String value) {
    setProperty('position', value, '');
  }

  /** Gets the value of "quotes" */
  String get quotes() =>
    getPropertyValue('quotes');

  /** Sets the value of "quotes" */
  void set quotes(String value) {
    setProperty('quotes', value, '');
  }

  /** Gets the value of "region-break-after" */
  String get regionBreakAfter() =>
    getPropertyValue('${_browserPrefix}region-break-after');

  /** Sets the value of "region-break-after" */
  void set regionBreakAfter(String value) {
    setProperty('${_browserPrefix}region-break-after', value, '');
  }

  /** Gets the value of "region-break-before" */
  String get regionBreakBefore() =>
    getPropertyValue('${_browserPrefix}region-break-before');

  /** Sets the value of "region-break-before" */
  void set regionBreakBefore(String value) {
    setProperty('${_browserPrefix}region-break-before', value, '');
  }

  /** Gets the value of "region-break-inside" */
  String get regionBreakInside() =>
    getPropertyValue('${_browserPrefix}region-break-inside');

  /** Sets the value of "region-break-inside" */
  void set regionBreakInside(String value) {
    setProperty('${_browserPrefix}region-break-inside', value, '');
  }

  /** Gets the value of "region-overflow" */
  String get regionOverflow() =>
    getPropertyValue('${_browserPrefix}region-overflow');

  /** Sets the value of "region-overflow" */
  void set regionOverflow(String value) {
    setProperty('${_browserPrefix}region-overflow', value, '');
  }

  /** Gets the value of "resize" */
  String get resize() =>
    getPropertyValue('resize');

  /** Sets the value of "resize" */
  void set resize(String value) {
    setProperty('resize', value, '');
  }

  /** Gets the value of "right" */
  String get right() =>
    getPropertyValue('right');

  /** Sets the value of "right" */
  void set right(String value) {
    setProperty('right', value, '');
  }

  /** Gets the value of "rtl-ordering" */
  String get rtlOrdering() =>
    getPropertyValue('${_browserPrefix}rtl-ordering');

  /** Sets the value of "rtl-ordering" */
  void set rtlOrdering(String value) {
    setProperty('${_browserPrefix}rtl-ordering', value, '');
  }

  /** Gets the value of "size" */
  String get size() =>
    getPropertyValue('size');

  /** Sets the value of "size" */
  void set size(String value) {
    setProperty('size', value, '');
  }

  /** Gets the value of "speak" */
  String get speak() =>
    getPropertyValue('speak');

  /** Sets the value of "speak" */
  void set speak(String value) {
    setProperty('speak', value, '');
  }

  /** Gets the value of "src" */
  String get src() =>
    getPropertyValue('src');

  /** Sets the value of "src" */
  void set src(String value) {
    setProperty('src', value, '');
  }

  /** Gets the value of "table-layout" */
  String get tableLayout() =>
    getPropertyValue('table-layout');

  /** Sets the value of "table-layout" */
  void set tableLayout(String value) {
    setProperty('table-layout', value, '');
  }

  /** Gets the value of "tap-highlight-color" */
  String get tapHighlightColor() =>
    getPropertyValue('${_browserPrefix}tap-highlight-color');

  /** Sets the value of "tap-highlight-color" */
  void set tapHighlightColor(String value) {
    setProperty('${_browserPrefix}tap-highlight-color', value, '');
  }

  /** Gets the value of "text-align" */
  String get textAlign() =>
    getPropertyValue('text-align');

  /** Sets the value of "text-align" */
  void set textAlign(String value) {
    setProperty('text-align', value, '');
  }

  /** Gets the value of "text-combine" */
  String get textCombine() =>
    getPropertyValue('${_browserPrefix}text-combine');

  /** Sets the value of "text-combine" */
  void set textCombine(String value) {
    setProperty('${_browserPrefix}text-combine', value, '');
  }

  /** Gets the value of "text-decoration" */
  String get textDecoration() =>
    getPropertyValue('text-decoration');

  /** Sets the value of "text-decoration" */
  void set textDecoration(String value) {
    setProperty('text-decoration', value, '');
  }

  /** Gets the value of "text-decorations-in-effect" */
  String get textDecorationsInEffect() =>
    getPropertyValue('${_browserPrefix}text-decorations-in-effect');

  /** Sets the value of "text-decorations-in-effect" */
  void set textDecorationsInEffect(String value) {
    setProperty('${_browserPrefix}text-decorations-in-effect', value, '');
  }

  /** Gets the value of "text-emphasis" */
  String get textEmphasis() =>
    getPropertyValue('${_browserPrefix}text-emphasis');

  /** Sets the value of "text-emphasis" */
  void set textEmphasis(String value) {
    setProperty('${_browserPrefix}text-emphasis', value, '');
  }

  /** Gets the value of "text-emphasis-color" */
  String get textEmphasisColor() =>
    getPropertyValue('${_browserPrefix}text-emphasis-color');

  /** Sets the value of "text-emphasis-color" */
  void set textEmphasisColor(String value) {
    setProperty('${_browserPrefix}text-emphasis-color', value, '');
  }

  /** Gets the value of "text-emphasis-position" */
  String get textEmphasisPosition() =>
    getPropertyValue('${_browserPrefix}text-emphasis-position');

  /** Sets the value of "text-emphasis-position" */
  void set textEmphasisPosition(String value) {
    setProperty('${_browserPrefix}text-emphasis-position', value, '');
  }

  /** Gets the value of "text-emphasis-style" */
  String get textEmphasisStyle() =>
    getPropertyValue('${_browserPrefix}text-emphasis-style');

  /** Sets the value of "text-emphasis-style" */
  void set textEmphasisStyle(String value) {
    setProperty('${_browserPrefix}text-emphasis-style', value, '');
  }

  /** Gets the value of "text-fill-color" */
  String get textFillColor() =>
    getPropertyValue('${_browserPrefix}text-fill-color');

  /** Sets the value of "text-fill-color" */
  void set textFillColor(String value) {
    setProperty('${_browserPrefix}text-fill-color', value, '');
  }

  /** Gets the value of "text-indent" */
  String get textIndent() =>
    getPropertyValue('text-indent');

  /** Sets the value of "text-indent" */
  void set textIndent(String value) {
    setProperty('text-indent', value, '');
  }

  /** Gets the value of "text-line-through" */
  String get textLineThrough() =>
    getPropertyValue('text-line-through');

  /** Sets the value of "text-line-through" */
  void set textLineThrough(String value) {
    setProperty('text-line-through', value, '');
  }

  /** Gets the value of "text-line-through-color" */
  String get textLineThroughColor() =>
    getPropertyValue('text-line-through-color');

  /** Sets the value of "text-line-through-color" */
  void set textLineThroughColor(String value) {
    setProperty('text-line-through-color', value, '');
  }

  /** Gets the value of "text-line-through-mode" */
  String get textLineThroughMode() =>
    getPropertyValue('text-line-through-mode');

  /** Sets the value of "text-line-through-mode" */
  void set textLineThroughMode(String value) {
    setProperty('text-line-through-mode', value, '');
  }

  /** Gets the value of "text-line-through-style" */
  String get textLineThroughStyle() =>
    getPropertyValue('text-line-through-style');

  /** Sets the value of "text-line-through-style" */
  void set textLineThroughStyle(String value) {
    setProperty('text-line-through-style', value, '');
  }

  /** Gets the value of "text-line-through-width" */
  String get textLineThroughWidth() =>
    getPropertyValue('text-line-through-width');

  /** Sets the value of "text-line-through-width" */
  void set textLineThroughWidth(String value) {
    setProperty('text-line-through-width', value, '');
  }

  /** Gets the value of "text-orientation" */
  String get textOrientation() =>
    getPropertyValue('${_browserPrefix}text-orientation');

  /** Sets the value of "text-orientation" */
  void set textOrientation(String value) {
    setProperty('${_browserPrefix}text-orientation', value, '');
  }

  /** Gets the value of "text-overflow" */
  String get textOverflow() =>
    getPropertyValue('text-overflow');

  /** Sets the value of "text-overflow" */
  void set textOverflow(String value) {
    setProperty('text-overflow', value, '');
  }

  /** Gets the value of "text-overline" */
  String get textOverline() =>
    getPropertyValue('text-overline');

  /** Sets the value of "text-overline" */
  void set textOverline(String value) {
    setProperty('text-overline', value, '');
  }

  /** Gets the value of "text-overline-color" */
  String get textOverlineColor() =>
    getPropertyValue('text-overline-color');

  /** Sets the value of "text-overline-color" */
  void set textOverlineColor(String value) {
    setProperty('text-overline-color', value, '');
  }

  /** Gets the value of "text-overline-mode" */
  String get textOverlineMode() =>
    getPropertyValue('text-overline-mode');

  /** Sets the value of "text-overline-mode" */
  void set textOverlineMode(String value) {
    setProperty('text-overline-mode', value, '');
  }

  /** Gets the value of "text-overline-style" */
  String get textOverlineStyle() =>
    getPropertyValue('text-overline-style');

  /** Sets the value of "text-overline-style" */
  void set textOverlineStyle(String value) {
    setProperty('text-overline-style', value, '');
  }

  /** Gets the value of "text-overline-width" */
  String get textOverlineWidth() =>
    getPropertyValue('text-overline-width');

  /** Sets the value of "text-overline-width" */
  void set textOverlineWidth(String value) {
    setProperty('text-overline-width', value, '');
  }

  /** Gets the value of "text-rendering" */
  String get textRendering() =>
    getPropertyValue('text-rendering');

  /** Sets the value of "text-rendering" */
  void set textRendering(String value) {
    setProperty('text-rendering', value, '');
  }

  /** Gets the value of "text-security" */
  String get textSecurity() =>
    getPropertyValue('${_browserPrefix}text-security');

  /** Sets the value of "text-security" */
  void set textSecurity(String value) {
    setProperty('${_browserPrefix}text-security', value, '');
  }

  /** Gets the value of "text-shadow" */
  String get textShadow() =>
    getPropertyValue('text-shadow');

  /** Sets the value of "text-shadow" */
  void set textShadow(String value) {
    setProperty('text-shadow', value, '');
  }

  /** Gets the value of "text-size-adjust" */
  String get textSizeAdjust() =>
    getPropertyValue('${_browserPrefix}text-size-adjust');

  /** Sets the value of "text-size-adjust" */
  void set textSizeAdjust(String value) {
    setProperty('${_browserPrefix}text-size-adjust', value, '');
  }

  /** Gets the value of "text-stroke" */
  String get textStroke() =>
    getPropertyValue('${_browserPrefix}text-stroke');

  /** Sets the value of "text-stroke" */
  void set textStroke(String value) {
    setProperty('${_browserPrefix}text-stroke', value, '');
  }

  /** Gets the value of "text-stroke-color" */
  String get textStrokeColor() =>
    getPropertyValue('${_browserPrefix}text-stroke-color');

  /** Sets the value of "text-stroke-color" */
  void set textStrokeColor(String value) {
    setProperty('${_browserPrefix}text-stroke-color', value, '');
  }

  /** Gets the value of "text-stroke-width" */
  String get textStrokeWidth() =>
    getPropertyValue('${_browserPrefix}text-stroke-width');

  /** Sets the value of "text-stroke-width" */
  void set textStrokeWidth(String value) {
    setProperty('${_browserPrefix}text-stroke-width', value, '');
  }

  /** Gets the value of "text-transform" */
  String get textTransform() =>
    getPropertyValue('text-transform');

  /** Sets the value of "text-transform" */
  void set textTransform(String value) {
    setProperty('text-transform', value, '');
  }

  /** Gets the value of "text-underline" */
  String get textUnderline() =>
    getPropertyValue('text-underline');

  /** Sets the value of "text-underline" */
  void set textUnderline(String value) {
    setProperty('text-underline', value, '');
  }

  /** Gets the value of "text-underline-color" */
  String get textUnderlineColor() =>
    getPropertyValue('text-underline-color');

  /** Sets the value of "text-underline-color" */
  void set textUnderlineColor(String value) {
    setProperty('text-underline-color', value, '');
  }

  /** Gets the value of "text-underline-mode" */
  String get textUnderlineMode() =>
    getPropertyValue('text-underline-mode');

  /** Sets the value of "text-underline-mode" */
  void set textUnderlineMode(String value) {
    setProperty('text-underline-mode', value, '');
  }

  /** Gets the value of "text-underline-style" */
  String get textUnderlineStyle() =>
    getPropertyValue('text-underline-style');

  /** Sets the value of "text-underline-style" */
  void set textUnderlineStyle(String value) {
    setProperty('text-underline-style', value, '');
  }

  /** Gets the value of "text-underline-width" */
  String get textUnderlineWidth() =>
    getPropertyValue('text-underline-width');

  /** Sets the value of "text-underline-width" */
  void set textUnderlineWidth(String value) {
    setProperty('text-underline-width', value, '');
  }

  /** Gets the value of "top" */
  String get top() =>
    getPropertyValue('top');

  /** Sets the value of "top" */
  void set top(String value) {
    setProperty('top', value, '');
  }

  /** Gets the value of "transform" */
  String get transform() =>
    getPropertyValue('${_browserPrefix}transform');

  /** Sets the value of "transform" */
  void set transform(String value) {
    setProperty('${_browserPrefix}transform', value, '');
  }

  /** Gets the value of "transform-origin" */
  String get transformOrigin() =>
    getPropertyValue('${_browserPrefix}transform-origin');

  /** Sets the value of "transform-origin" */
  void set transformOrigin(String value) {
    setProperty('${_browserPrefix}transform-origin', value, '');
  }

  /** Gets the value of "transform-origin-x" */
  String get transformOriginX() =>
    getPropertyValue('${_browserPrefix}transform-origin-x');

  /** Sets the value of "transform-origin-x" */
  void set transformOriginX(String value) {
    setProperty('${_browserPrefix}transform-origin-x', value, '');
  }

  /** Gets the value of "transform-origin-y" */
  String get transformOriginY() =>
    getPropertyValue('${_browserPrefix}transform-origin-y');

  /** Sets the value of "transform-origin-y" */
  void set transformOriginY(String value) {
    setProperty('${_browserPrefix}transform-origin-y', value, '');
  }

  /** Gets the value of "transform-origin-z" */
  String get transformOriginZ() =>
    getPropertyValue('${_browserPrefix}transform-origin-z');

  /** Sets the value of "transform-origin-z" */
  void set transformOriginZ(String value) {
    setProperty('${_browserPrefix}transform-origin-z', value, '');
  }

  /** Gets the value of "transform-style" */
  String get transformStyle() =>
    getPropertyValue('${_browserPrefix}transform-style');

  /** Sets the value of "transform-style" */
  void set transformStyle(String value) {
    setProperty('${_browserPrefix}transform-style', value, '');
  }

  /** Gets the value of "transition" */
  String get transition() =>
    getPropertyValue('${_browserPrefix}transition');

  /** Sets the value of "transition" */
  void set transition(String value) {
    setProperty('${_browserPrefix}transition', value, '');
  }

  /** Gets the value of "transition-delay" */
  String get transitionDelay() =>
    getPropertyValue('${_browserPrefix}transition-delay');

  /** Sets the value of "transition-delay" */
  void set transitionDelay(String value) {
    setProperty('${_browserPrefix}transition-delay', value, '');
  }

  /** Gets the value of "transition-duration" */
  String get transitionDuration() =>
    getPropertyValue('${_browserPrefix}transition-duration');

  /** Sets the value of "transition-duration" */
  void set transitionDuration(String value) {
    setProperty('${_browserPrefix}transition-duration', value, '');
  }

  /** Gets the value of "transition-property" */
  String get transitionProperty() =>
    getPropertyValue('${_browserPrefix}transition-property');

  /** Sets the value of "transition-property" */
  void set transitionProperty(String value) {
    setProperty('${_browserPrefix}transition-property', value, '');
  }

  /** Gets the value of "transition-timing-function" */
  String get transitionTimingFunction() =>
    getPropertyValue('${_browserPrefix}transition-timing-function');

  /** Sets the value of "transition-timing-function" */
  void set transitionTimingFunction(String value) {
    setProperty('${_browserPrefix}transition-timing-function', value, '');
  }

  /** Gets the value of "unicode-bidi" */
  String get unicodeBidi() =>
    getPropertyValue('unicode-bidi');

  /** Sets the value of "unicode-bidi" */
  void set unicodeBidi(String value) {
    setProperty('unicode-bidi', value, '');
  }

  /** Gets the value of "unicode-range" */
  String get unicodeRange() =>
    getPropertyValue('unicode-range');

  /** Sets the value of "unicode-range" */
  void set unicodeRange(String value) {
    setProperty('unicode-range', value, '');
  }

  /** Gets the value of "user-drag" */
  String get userDrag() =>
    getPropertyValue('${_browserPrefix}user-drag');

  /** Sets the value of "user-drag" */
  void set userDrag(String value) {
    setProperty('${_browserPrefix}user-drag', value, '');
  }

  /** Gets the value of "user-modify" */
  String get userModify() =>
    getPropertyValue('${_browserPrefix}user-modify');

  /** Sets the value of "user-modify" */
  void set userModify(String value) {
    setProperty('${_browserPrefix}user-modify', value, '');
  }

  /** Gets the value of "user-select" */
  String get userSelect() =>
    getPropertyValue('${_browserPrefix}user-select');

  /** Sets the value of "user-select" */
  void set userSelect(String value) {
    setProperty('${_browserPrefix}user-select', value, '');
  }

  /** Gets the value of "vertical-align" */
  String get verticalAlign() =>
    getPropertyValue('vertical-align');

  /** Sets the value of "vertical-align" */
  void set verticalAlign(String value) {
    setProperty('vertical-align', value, '');
  }

  /** Gets the value of "visibility" */
  String get visibility() =>
    getPropertyValue('visibility');

  /** Sets the value of "visibility" */
  void set visibility(String value) {
    setProperty('visibility', value, '');
  }

  /** Gets the value of "white-space" */
  String get whiteSpace() =>
    getPropertyValue('white-space');

  /** Sets the value of "white-space" */
  void set whiteSpace(String value) {
    setProperty('white-space', value, '');
  }

  /** Gets the value of "widows" */
  String get widows() =>
    getPropertyValue('widows');

  /** Sets the value of "widows" */
  void set widows(String value) {
    setProperty('widows', value, '');
  }

  /** Gets the value of "width" */
  String get width() =>
    getPropertyValue('width');

  /** Sets the value of "width" */
  void set width(String value) {
    setProperty('width', value, '');
  }

  /** Gets the value of "word-break" */
  String get wordBreak() =>
    getPropertyValue('word-break');

  /** Sets the value of "word-break" */
  void set wordBreak(String value) {
    setProperty('word-break', value, '');
  }

  /** Gets the value of "word-spacing" */
  String get wordSpacing() =>
    getPropertyValue('word-spacing');

  /** Sets the value of "word-spacing" */
  void set wordSpacing(String value) {
    setProperty('word-spacing', value, '');
  }

  /** Gets the value of "word-wrap" */
  String get wordWrap() =>
    getPropertyValue('word-wrap');

  /** Sets the value of "word-wrap" */
  void set wordWrap(String value) {
    setProperty('word-wrap', value, '');
  }

  /** Gets the value of "wrap-shape" */
  String get wrapShape() =>
    getPropertyValue('${_browserPrefix}wrap-shape');

  /** Sets the value of "wrap-shape" */
  void set wrapShape(String value) {
    setProperty('${_browserPrefix}wrap-shape', value, '');
  }

  /** Gets the value of "writing-mode" */
  String get writingMode() =>
    getPropertyValue('${_browserPrefix}writing-mode');

  /** Sets the value of "writing-mode" */
  void set writingMode(String value) {
    setProperty('${_browserPrefix}writing-mode', value, '');
  }

  /** Gets the value of "z-index" */
  String get zIndex() =>
    getPropertyValue('z-index');

  /** Sets the value of "z-index" */
  void set zIndex(String value) {
    setProperty('z-index', value, '');
  }

  /** Gets the value of "zoom" */
  String get zoom() =>
    getPropertyValue('zoom');

  /** Sets the value of "zoom" */
  void set zoom(String value) {
    setProperty('zoom', value, '');
  }
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

class CustomEventWrappingImplementation extends EventWrappingImplementation implements CustomEvent {
  CustomEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory CustomEventWrappingImplementation(String type,
      [bool canBubble = true, bool cancelable = true, Object detail = null]) {
    final e = dom.document.createEvent("CustomEvent");
    e.initCustomEvent(type, canBubble, cancelable, detail);
    return LevelDom.wrapCustomEvent(e);
  }

  String get detail() => _ptr.detail;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap implements Map<String, String> {

  final Map<String, String> _attributes;

  _DataAttributeMap(this._attributes);

  // interface Map

  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(String value) => getValues().some((v) => v == value);

  bool containsKey(String key) => _attributes.containsKey(_attr(key));

  String operator [](String key) => _attributes[_attr(key)];

  void operator []=(String key, String value) {
    _attributes[_attr(key)] = value;
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      return this[key] = ifAbsent();
    }
    return this[key];
  }

  String remove(String key) => _attributes.remove(_attr(key));

  void clear() {
    // Needs to operate on a snapshot since we are mutatiting the collection.
    for (String key in getKeys()) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        f(_strip(key), value);
      }
    });
  }

  Collection<String> getKeys() {
    final keys = new List<String>();
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        keys.add(_strip(key));
      }
    });
    return keys;
  }

  Collection<String> getValues() {
    final values = new List<String>();
    _attributes.forEach((String key, String value) {
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

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
  static String get userAgent() => dom.window.navigator.userAgent;

  /**
   * Determines if the current device is running Firefox.
   */
  static bool get isFirefox() => userAgent.contains("Firefox", 0);
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

class DeviceMotionEventWrappingImplementation extends EventWrappingImplementation implements DeviceMotionEvent {
  DeviceMotionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory DeviceMotionEventWrappingImplementation(String type,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("DeviceMotionEvent");
    e.initEvent(type, canBubble, cancelable);
    return LevelDom.wrapDeviceMotionEvent(e);
  }

  num get interval() => _ptr.interval;
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

class DeviceOrientationEventWrappingImplementation extends EventWrappingImplementation implements DeviceOrientationEvent {
  DeviceOrientationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory DeviceOrientationEventWrappingImplementation(String type,
      double alpha, double beta, double gamma, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent("DeviceOrientationEvent");
    e.initDeviceOrientationEvent(
        type, canBubble, cancelable, alpha, beta, gamma);
    return LevelDom.wrapDeviceOrientationEvent(e);
  }

  num get alpha() => _ptr.alpha;

  num get beta() => _ptr.beta;

  num get gamma() => _ptr.gamma;
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
    for (var node in _childNodes) {
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
    var len = this.length;
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
    var last = this.last();
    if (last != null) {
      last.remove();
    }
    return last;
  }

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

class EmptyStyleDeclaration extends CSSStyleDeclarationWrappingImplementation {
  // This can't call super(), since that's a factory constructor
  EmptyStyleDeclaration()
    : super._wrap(dom.document.createElement('div').style);

  void set cssText(String value) {
    throw new UnsupportedOperationException(
        "Can't modify a frozen style declaration.");
  }

  String removeProperty(String propertyName) {
    throw new UnsupportedOperationException(
        "Can't modify a frozen style declaration.");
  }

  void setProperty(String propertyName, String value, [String priority]) {
    throw new UnsupportedOperationException(
        "Can't modify a frozen style declaration.");
  }
}

Future<CSSStyleDeclaration> _emptyStyleFuture() {
  return _createMeasurementFuture(() => new EmptyStyleDeclaration(),
                                  new Completer<CSSStyleDeclaration>());
}

class EmptyElementRect implements ElementRect {
  final ClientRect client = const SimpleClientRect(0, 0, 0, 0);
  final ClientRect offset = const SimpleClientRect(0, 0, 0, 0);
  final ClientRect scroll = const SimpleClientRect(0, 0, 0, 0);
  final ClientRect bounding = const SimpleClientRect(0, 0, 0, 0);
  final List<ClientRect> clientRects = const <ClientRect>[];

  const EmptyElementRect();
}

class DocumentFragmentWrappingImplementation extends NodeWrappingImplementation implements DocumentFragment {
  ElementList _elements;

  DocumentFragmentWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  /** @domName Document.createDocumentFragment */
  factory DocumentFragmentWrappingImplementation() {
    return new DocumentFragmentWrappingImplementation._wrap(
	    dom.document.createDocumentFragment());
  }

  factory DocumentFragmentWrappingImplementation.html(String html) {
    var fragment = new DocumentFragment();
    fragment.innerHTML = html;
    return fragment;
  }

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

  String get innerHTML() {
    var e = new Element.tag("div");
    e.nodes.add(this.clone(true));
    return e.innerHTML;
  }

  String get outerHTML() => innerHTML;

  void set innerHTML(String value) {
    this.nodes.clear();

    var e = new Element.tag("div");
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
        this.insertBefore(node, nodes.first);
        return node;
      case "beforeend":
        this.nodes.add(node);
        return node;
      default:
        throw new IllegalArgumentException("Invalid position ${where}");
    }
  }

  Element insertAdjacentElement([String where = null, Element element = null])
    => this._insertAdjacentNode(where, element);

  void insertAdjacentText([String where = null, String text = null]) {
    this._insertAdjacentNode(where, new Text(text));
  }

  void insertAdjacentHTML(
      [String position_OR_where = null, String text = null]) {
    this._insertAdjacentNode(
      position_OR_where, new DocumentFragment.html(text));
  }

  ElementEvents get on() {
    if (_on === null) {
      _on = new ElementEventsImplementation._wrap(_ptr);
    }
    return _on;
  }

  Future<ElementRect> get rect() {
    return _createMeasurementFuture(() => const EmptyElementRect(),
                                    new Completer<ElementRect>());
  }

  Element query(String selectors) =>
    LevelDom.wrapElement(_ptr.querySelector(selectors));

  ElementList queryAll(String selectors) =>
    LevelDom.wrapElementList(_ptr.querySelectorAll(selectors));

  // If we can come up with a semi-reasonable default value for an Element
  // getter, we'll use it. In general, these return the same values as an
  // element that has no parent.
  String get contentEditable() => "false";
  bool get isContentEditable() => false;
  bool get draggable() => false;
  bool get hidden() => false;
  bool get spellcheck() => false;
  int get tabIndex() => -1;
  String get id() => "";
  String get title() => "";
  String get tagName() => "";
  String get webkitdropzone() => "";
  Element get firstElementChild() => elements.first();
  Element get lastElementChild() => elements.last();
  Element get nextElementSibling() => null;
  Element get previousElementSibling() => null;
  Element get offsetParent() => null;
  Element get parent() => null;
  Map<String, String> get attributes() => const {};
  // Issue 174: this should be a const set.
  Set<String> get classes() => new Set<String>();
  Map<String, String> get dataAttributes() => const {};
  CSSStyleDeclaration get style() => new EmptyStyleDeclaration();
  Future<CSSStyleDeclaration> get computedStyle() =>
      _emptyStyleFuture();
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) =>
      _emptyStyleFuture();
  bool matchesSelector([String selectors]) => false;

  // Imperative Element methods are made into no-ops, as they are on parentless
  // elements.
  void blur() {}
  void focus() {}
  void scrollByLines([int lines]) {}
  void scrollByPages([int pages]) {}
  void scrollIntoView([bool centerIfNeeded]) {}

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
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DocumentEventsImplementation extends ElementEventsImplementation
      implements DocumentEvents {

  DocumentEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get readyStateChange() => _get('readystatechange');

  EventListenerList get selectionChange() => _get('selectionchange');

  EventListenerList get contentLoaded() => _get('DOMContentLoaded');
}

class DocumentWrappingImplementation extends ElementWrappingImplementation implements Document {

  final _documentPtr;

  DocumentWrappingImplementation._wrap(this._documentPtr, ptr) : super._wrap(ptr) {
    // We have to set the back ptr on the document as well as the documentElement
    // so that it is always simple to detect when an existing wrapper exists.
    _documentPtr.dartObjectLocalStorage = this;
  }

  /** @domName HTMLDocument.activeElement */
  Element get activeElement() => LevelDom.wrapElement(_documentPtr.activeElement);

  Node get parent() => null;

  /** @domName Document.body */
  Element get body() => LevelDom.wrapElement(_documentPtr.body);

  /** @domName Document.body */
  void set body(Element value) { _documentPtr.body = LevelDom.unwrap(value); }

  /** @domName Document.charset */
  String get charset() => _documentPtr.charset;

  /** @domName Document.charset */
  void set charset(String value) { _documentPtr.charset = value; }

  /** @domName Document.cookie */
  String get cookie() => _documentPtr.cookie;

  /** @domName Document.cookie */
  void set cookie(String value) { _documentPtr.cookie = value; }

  /** @domName Document.defaultView */
  Window get window() => LevelDom.wrapWindow(_documentPtr.defaultView);

  /** @domName HTMLDocument.designMode */
  void set designMode(String value) { _documentPtr.designMode = value; }

  /** @domName Document.domain */
  String get domain() => _documentPtr.domain;

  /** @domName Document.head */
  HeadElement get head() => LevelDom.wrapHeadElement(_documentPtr.head);

  /** @domName Document.lastModified */
  String get lastModified() => _documentPtr.lastModified;

  /** @domName Document.readyState */
  String get readyState() => _documentPtr.readyState;

  /** @domName Document.referrer */
  String get referrer() => _documentPtr.referrer;

  /** @domName Document.styleSheets */
  StyleSheetList get styleSheets() => LevelDom.wrapStyleSheetList(_documentPtr.styleSheets);

  /** @domName Document.title */
  String get title() => _documentPtr.title;

  /** @domName Document.title */
  void set title(String value) { _documentPtr.title = value; }

  /** @domName Document.webkitHidden */
  bool get webkitHidden() => _documentPtr.webkitHidden;

  /** @domName Document.webkitVisibilityState */
  String get webkitVisibilityState() => _documentPtr.webkitVisibilityState;

  /** @domName Document.caretRangeFromPoint */
  Future<Range> caretRangeFromPoint([int x = null, int y = null]) {
    return _createMeasurementFuture(
        () => LevelDom.wrapRange(_documentPtr.caretRangeFromPoint(x, y)),
        new Completer<Range>());
  }

  /** @domName Document.createElement */
  Element createElement([String tagName = null]) {
    return LevelDom.wrapElement(_documentPtr.createElement(tagName));
  }

  /** @domName Document.createEvent */
  Event createEvent([String eventType = null]) {
    return LevelDom.wrapEvent(_documentPtr.createEvent(eventType));
  }

  /** @domName Document.elementFromPoint */
  Future<Element> elementFromPoint([int x = null, int y = null]) {
    return _createMeasurementFuture(
        () => LevelDom.wrapElement(_documentPtr.elementFromPoint(x, y)),
        new Completer<Element>());
  }

  /** @domName Document.execCommand */
  bool execCommand([String command = null, bool userInterface = null, String value = null]) {
    return _documentPtr.execCommand(command, userInterface, value);
  }

  /** @domName Document.getCSSCanvasContext */
  CanvasRenderingContext getCSSCanvasContext(String contextId, String name,
                                             int width, int height) {
    return LevelDom.wrapCanvasRenderingContext(_documentPtr.getCSSCanvasContext(contextId, name, width, height));
  }

  /** @domName Document.queryCommandEnabled */
  bool queryCommandEnabled([String command = null]) {
    return _documentPtr.queryCommandEnabled(command);
  }

  /** @domName Document.queryCommandIndeterm */
  bool queryCommandIndeterm([String command = null]) {
    return _documentPtr.queryCommandIndeterm(command);
  }

  /** @domName Document.queryCommandState */
  bool queryCommandState([String command = null]) {
    return _documentPtr.queryCommandState(command);
  }

  /** @domName Document.queryCommandSupported */
  bool queryCommandSupported([String command = null]) {
    return _documentPtr.queryCommandSupported(command);
  }

  /** @domName Document.queryCommandValue */
  String queryCommandValue([String command = null]) {
    return _documentPtr.queryCommandValue(command);
  }

  String get manifest() => _ptr.manifest;

  void set manifest(String value) { _ptr.manifest = value; }

  DocumentEvents get on() {
    if (_on === null) {
      _on = new DocumentEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
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

class DOMApplicationCacheEventsImplementation extends EventsImplementation
    implements DOMApplicationCacheEvents {
  DOMApplicationCacheEventsImplementation._wrap(ptr) : super._wrap(ptr);

  EventListenerList get cached() => _get('cached');
  EventListenerList get checking() => _get('checking');
  EventListenerList get downloading() => _get('downloading');
  EventListenerList get error() => _get('error');
  EventListenerList get noUpdate() => _get('noupdate');
  EventListenerList get obsolete() => _get('obsolete');
  EventListenerList get progress() => _get('progress');
  EventListenerList get updateReady() => _get('updateready');
}

class DOMApplicationCacheWrappingImplementation extends EventTargetWrappingImplementation implements DOMApplicationCache {
  DOMApplicationCacheWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  int get status() => _ptr.status;

  void swapCache() {
    _ptr.swapCache();
  }

  void update() {
    _ptr.update();
  }

  DOMApplicationCacheEvents get on() {
    if (_on === null) {
      _on = new DOMApplicationCacheEventsImplementation._wrap(_ptr);
    }
    return _on;  
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DOMWrapperBase {
  final _ptr;

  DOMWrapperBase._wrap(this._ptr) {
  	// We should never be creating duplicate wrappers.
  	assert(_ptr.dartObjectLocalStorage === null);
	_ptr.dartObjectLocalStorage = this;
  }
}

/** This function is provided for unittest purposes only. */
unwrapDomObject(DOMWrapperBase wrapper) {
  return wrapper._ptr;
}// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

// TODO(jacobr): use Lists.dart to remove some of the duplicated functionality.
class _ChildrenElementList implements ElementList {
  // Raw Element.
  final _element;
  final _childElements;

  _ChildrenElementList._wrap(var element)
    : _childElements = element.children,
      _element = element;

  List<Element> _toList() {
    final output = new List(_childElements.length);
    for (int i = 0, len = _childElements.length; i < len; i++) {
      output[i] = LevelDom.wrapElement(_childElements[i]);
    }
    return output;
  }

  Element get first() {
    return LevelDom.wrapElement(_element.firstElementChild);
  }

  void forEach(void f(Element element)) {
    for (var element in _childElements) {
      f(LevelDom.wrapElement(element));
    }
  }

  Collection<Element> filter(bool f(Element element)) {
    List<Element> output = new List<Element>();
    forEach((Element element) {
      if (f(element)) {
        output.add(element);
      }
    });
    return output;
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

  bool isEmpty() {
    return _element.firstElementChild !== null;
  }

  int get length() {
    return _childElements.length;
  }

  Element operator [](int index) {
    return LevelDom.wrapElement(_childElements[index]);
  }

  void operator []=(int index, Element value) {
    _element.replaceChild(LevelDom.unwrap(value), _childElements.item(index));
  }

   void set length(int newLength) {
     // TODO(jacobr): remove children when length is reduced.
     throw const UnsupportedOperationException('');
   }

  Element add(Element value) {
    _element.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Element addLast(Element value) => add(value);

  Iterator<Element> iterator() => _toList().iterator();

  void addAll(Collection<Element> collection) {
    for (Element element in collection) {
      _element.appendChild(LevelDom.unwrap(element));
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

  List getRange(int start, int length) {
    throw const NotImplementedException();
  }

  int indexOf(Element element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Element element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    // It is unclear if we want to keep non element nodes?
    _element.textContent = '';
  }

  Element removeLast() {
    final last = this.last();
    if (last != null) {
      _element.removeChild(LevelDom.unwrap(last));
    }
    return last;
  }

  Element last() {
    return LevelDom.wrapElement(_element.lastElementChild);
  }
}

class FrozenElementList implements ElementList {
  final _ptr;

  FrozenElementList._wrap(this._ptr);

  Element get first() {
    return this[0];
  }

  void forEach(void f(Element element)) {
    for (var element in _ptr) {
      f(LevelDom.wrapElement(element));
    }
  }

  Collection<Element> filter(bool f(Element element)) {
    throw 'Not impl yet. todo(jacobr)';
  }

  bool every(bool f(Element element)) {
    throw 'Not impl yet. todo(jacobr)';
  }

  bool some(bool f(Element element)) {
    throw 'Not impl yet. todo(jacobr)';
  }

  bool isEmpty() {
    return _ptr.length == 0;
  }

  int get length() {
    return _ptr.length;
  }

  Element operator [](int index) {
    return LevelDom.wrapElement(_ptr[index]);
  }

  void operator []=(int index, Element value) {
    throw const UnsupportedOperationException('');
  }

   void set length(int newLength) {
    throw const UnsupportedOperationException('');
   }

  void add(Element value) {
    throw const UnsupportedOperationException('');
  }


  void addLast(Element value) {
    throw const UnsupportedOperationException('');
  }

  Iterator<Element> iterator() => new FrozenElementListIterator(this);

  void addAll(Collection<Element> collection) {
    throw const UnsupportedOperationException('');
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('');
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

  List getRange(int start, int length) {
    throw const NotImplementedException();
  }

  int indexOf(Element element, [int start = 0]) {
    throw 'Not impl yet. todo(jacobr)';
  }

  int lastIndexOf(Element element, [int start = null]) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void clear() {
    throw 'Not impl yet. todo(jacobr)';
  }

  Element removeLast() {
    throw 'Not impl yet. todo(jacobr)';
  }

  Element last() {
    return this[length-1];
  }
}

class FrozenElementListIterator implements Iterator<Element> {
  final FrozenElementList _list;
  int _index = 0;

  FrozenElementListIterator(this._list);

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

class ElementAttributeMap implements Map<String, String> {

  final _element;

  ElementAttributeMap._wrap(this._element);

  bool containsValue(String value) {
    final attributes = _element.attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      if(value == attributes.item(i).value) {
        return true;
      }
    }
    return false;
  }

  /** @domName Element.hasAttribute */
  bool containsKey(String key) {
    return _element.hasAttribute(key);
  }

  /** @domName Element.getAttribute */
  String operator [](String key) {
    return _element.getAttribute(key);
  }

  /** @domName Element.setAttribute */
  void operator []=(String key, String value) {
    _element.setAttribute(key, value);
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      this[key] = ifAbsent();
    }
  }

  /** @domName Element.removeAttribute */
  String remove(String key) {
    _element.removeAttribute(key);
  }

  void clear() {
    final attributes = _element.attributes;
    for (int i = attributes.length - 1; i >= 0; i--) {
      _element.removeAttribute(attributes.item(i).name);
    }
  }

  void forEach(void f(String key, String value)) {
    final attributes = _element.attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      final item = attributes.item(i);
      f(item.name, item.value);
    }
  }

  Collection<String> getKeys() {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element.attributes;
    final keys = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      keys[i] = attributes.item(i).name;
    }
    return keys;
  }

  Collection<String> getValues() {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element.attributes;
    final values = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      values[i] = attributes.item(i).value;
    }
    return values;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length() {
    return _element.attributes.length;
  }

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool isEmpty() {
    return !_element.hasAttributes();
  }
}

class ElementEventsImplementation extends EventsImplementation implements ElementEvents {
  ElementEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get("abort");
  EventListenerList get beforeCopy() => _get("beforecopy");
  EventListenerList get beforeCut() => _get("beforecut");
  EventListenerList get beforePaste() => _get("beforepaste");
  EventListenerList get blur() => _get("blur");
  EventListenerList get change() => _get("change");
  EventListenerList get click() => _get("click");
  EventListenerList get contextMenu() => _get("contextmenu");
  EventListenerList get copy() => _get("copy");
  EventListenerList get cut() => _get("cut");
  EventListenerList get dblClick() => _get("dblclick");
  EventListenerList get drag() => _get("drag");
  EventListenerList get dragEnd() => _get("dragend");
  EventListenerList get dragEnter() => _get("dragenter");
  EventListenerList get dragLeave() => _get("dragleave");
  EventListenerList get dragOver() => _get("dragover");
  EventListenerList get dragStart() => _get("dragstart");
  EventListenerList get drop() => _get("drop");
  EventListenerList get error() => _get("error");
  EventListenerList get focus() => _get("focus");
  EventListenerList get input() => _get("input");
  EventListenerList get invalid() => _get("invalid");
  EventListenerList get keyDown() => _get("keydown");
  EventListenerList get keyPress() => _get("keypress");
  EventListenerList get keyUp() => _get("keyup");
  EventListenerList get load() => _get("load");
  EventListenerList get mouseDown() => _get("mousedown");
  EventListenerList get mouseMove() => _get("mousemove");
  EventListenerList get mouseOut() => _get("mouseout");
  EventListenerList get mouseOver() => _get("mouseover");
  EventListenerList get mouseUp() => _get("mouseup");
  EventListenerList get mouseWheel() => _get("mousewheel");
  EventListenerList get paste() => _get("paste");
  EventListenerList get reset() => _get("reset");
  EventListenerList get scroll() => _get("scroll");
  EventListenerList get search() => _get("search");
  EventListenerList get select() => _get("select");
  EventListenerList get selectStart() => _get("selectstart");
  EventListenerList get submit() => _get("submit");
  EventListenerList get touchCancel() => _get("touchcancel");
  EventListenerList get touchEnd() => _get("touchend");
  EventListenerList get touchLeave() => _get("touchleave");
  EventListenerList get touchMove() => _get("touchmove");
  EventListenerList get touchStart() => _get("touchstart");
  EventListenerList get transitionEnd() => _get("webkitTransitionEnd");
  EventListenerList get fullscreenChange() => _get("webkitfullscreenchange");
}

class SimpleClientRect implements ClientRect {
  final num left;
  final num top;
  final num width;
  final num height;
  num get right() => left + width;
  num get bottom() => top + height;

  const SimpleClientRect(this.left, this.top, this.width, this.height);

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
class ElementRectWrappingImplementation implements ElementRect {
  final ClientRect client;
  final ClientRect offset;
  final ClientRect scroll;

  // TODO(jacobr): should we move these outside of ElementRect to avoid the
  // overhead of computing them every time even though they are rarely used.
  // This should be type dom.ClientRect but that fails on dartium. b/5522629
  final _boundingClientRect; 
  // an exception due to a dartium bug.
  final dom.ClientRectList _clientRects;

  ElementRectWrappingImplementation(dom.HTMLElement element) :
    client = new SimpleClientRect(element.clientLeft,
                                  element.clientTop,
                                  element.clientWidth, 
                                  element.clientHeight), 
    offset = new SimpleClientRect(element.offsetLeft,
                                  element.offsetTop,
                                  element.offsetWidth,
                                  element.offsetHeight),
    scroll = new SimpleClientRect(element.scrollLeft,
                                  element.scrollTop,
                                  element.scrollWidth,
                                  element.scrollHeight),
    _boundingClientRect = element.getBoundingClientRect(),
    _clientRects = element.getClientRects();

  ClientRect get bounding() =>
      LevelDom.wrapClientRect(_boundingClientRect);

  List<ClientRect> get clientRects() {
    final out = new List(_clientRects.length);
    for (num i = 0; i < _clientRects.length; i++) {
      out[i] = LevelDom.wrapClientRect(_clientRects.item(i));
    }
    return out;
  }
}

class ElementWrappingImplementation extends NodeWrappingImplementation implements Element {
  
    static final _START_TAG_REGEXP = const RegExp('<(\\w+)');
    static final _CUSTOM_PARENT_TAG_MAP = const {
      'body' : 'html',
      'head' : 'html',
      'caption' : 'table',
      'td': 'tr',
      'tbody': 'table',
      'colgroup': 'table',
      'col' : 'colgroup',
      'tr' : 'tbody',
      'tbody' : 'table',
      'tfoot' : 'table',
      'thead' : 'table',
      'track' : 'audio',
    };

   factory ElementWrappingImplementation.html(String html) {
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
    final temp = dom.document.createElement(parentTag);
    temp.innerHTML = html;

    if (temp.childElementCount == 1) {
      return LevelDom.wrapElement(temp.firstElementChild);     
    } else if (parentTag == 'html' && temp.childElementCount == 2) {
      // Work around for edge case in WebKit and possibly other browsers where
      // both body and head elements are created even though the inner html
      // only contains a head or body element.
      return LevelDom.wrapElement(temp.children.item(tag == 'head' ? 0 : 1));
    } else {
      throw 'HTML had ${temp.childElementCount} top level elements but 1 expected';
    }
  }

  factory ElementWrappingImplementation.tag(String tag) {
    return LevelDom.wrapElement(dom.document.createElement(tag));
  }

  ElementWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  ElementAttributeMap _elementAttributeMap;
  ElementList _elements;
  _CssClassSet _cssClassSet;
  _DataAttributeMap _dataAttributes;

  Map<String, String> get attributes() {
    if (_elementAttributeMap === null) {
      _elementAttributeMap = new ElementAttributeMap._wrap(_ptr);
    }
    return _elementAttributeMap;
  }

  void set attributes(Map<String, String> value) {
    Map<String, String> attributes = this.attributes;
    attributes.clear();
    for (String key in value.getKeys()) {
      attributes[key] = value[key];
    }
  }

  void set elements(Collection<Element> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    final elements = this.elements;
    elements.clear();
    elements.addAll(copy);
  }

  ElementList get elements() {
    if (_elements == null) {
      _elements = new _ChildrenElementList._wrap(_ptr);
    }
    return _elements;
  }

  Set<String> get classes() {
    if (_cssClassSet === null) {
      _cssClassSet = new _CssClassSet(_ptr);
    }
    return _cssClassSet;
  }

  void set classes(Collection<String> value) {
    _CssClassSet classSet = classes;
    classSet.clear();
    classSet.addAll(value);
  }

  Map<String, String> get dataAttributes() {
    if (_dataAttributes === null) {
      _dataAttributes = new _DataAttributeMap(attributes);
    }
    return _dataAttributes;
  }

  void set dataAttributes(Map<String, String> value) {
    Map<String, String> dataAttributes = this.dataAttributes;
    dataAttributes.clear();
    for (String key in value.getKeys()) {
      dataAttributes[key] = value[key];
    }
  }

  String get contentEditable() => _ptr.contentEditable;

  void set contentEditable(String value) { _ptr.contentEditable = value; }

  String get dir() => _ptr.dir;

  void set dir(String value) { _ptr.dir = value; }

  bool get draggable() => _ptr.draggable;

  void set draggable(bool value) { _ptr.draggable = value; }

  Element get firstElementChild() => LevelDom.wrapElement(_ptr.firstElementChild);

  bool get hidden() => _ptr.hidden;

  void set hidden(bool value) { _ptr.hidden = value; }

  String get id() => _ptr.id;

  void set id(String value) { _ptr.id = value; }

  String get innerHTML() => _ptr.innerHTML;

  void set innerHTML(String value) { _ptr.innerHTML = value; }

  bool get isContentEditable() => _ptr.isContentEditable;

  String get lang() => _ptr.lang;

  void set lang(String value) { _ptr.lang = value; }

  Element get lastElementChild() => LevelDom.wrapElement(_ptr.lastElementChild);

  Element get nextElementSibling() => LevelDom.wrapElement(_ptr.nextElementSibling);

  Element get offsetParent() => LevelDom.wrapElement(_ptr.offsetParent);

  String get outerHTML() => _ptr.outerHTML;

  Element get previousElementSibling() => LevelDom.wrapElement(_ptr.previousElementSibling);

  bool get spellcheck() => _ptr.spellcheck;

  void set spellcheck(bool value) { _ptr.spellcheck = value; }

  CSSStyleDeclaration get style() => LevelDom.wrapCSSStyleDeclaration(_ptr.style);

  int get tabIndex() => _ptr.tabIndex;

  void set tabIndex(int value) { _ptr.tabIndex = value; }

  String get tagName() => _ptr.tagName;

  String get title() => _ptr.title;

  void set title(String value) { _ptr.title = value; }

  String get webkitdropzone() => _ptr.webkitdropzone;

  void set webkitdropzone(String value) { _ptr.webkitdropzone = value; }

  void blur() {
    _ptr.blur();
  }

  bool contains(Node element) {
    return _ptr.contains(LevelDom.unwrap(element));
  }

  void focus() {
    _ptr.focus();
  }

  /** @domName HTMLElement.insertAdjacentElement */
  Element insertAdjacentElement([String where = null, Element element = null]) {
    return LevelDom.wrapElement(_ptr.insertAdjacentElement(where, LevelDom.unwrap(element)));
  }

  /** @domName HTMLElement.insertAdjacentHTML */
  void insertAdjacentHTML([String position_OR_where = null, String text = null]) {
    _ptr.insertAdjacentHTML(position_OR_where, text);
  }

  /** @domName HTMLElement.insertAdjacentText */
  void insertAdjacentText([String where = null, String text = null]) {
    _ptr.insertAdjacentText(where, text);
  }

  Element query(String selectors) {
    // TODO(jacobr): scope fix.
    return LevelDom.wrapElement(_ptr.querySelector(selectors));
  }

  ElementList queryAll(String selectors) {
    // TODO(jacobr): scope fix.
    return new FrozenElementList._wrap(_ptr.querySelectorAll(selectors));
  }

  void scrollByLines([int lines = null]) {
    _ptr.scrollByLines(lines);
  }

  void scrollByPages([int pages = null]) {
    _ptr.scrollByPages(pages);
  }

  void scrollIntoView([bool centerIfNeeded = null]) {
    _ptr.scrollIntoViewIfNeeded(centerIfNeeded);
  }

  bool matchesSelector([String selectors = null]) {
    return _ptr.webkitMatchesSelector(selectors);
  }

  void set scrollLeft(int value) { _ptr.scrollLeft = value; }
 
  void set scrollTop(int value) { _ptr.scrollTop = value; }

  /** @domName getClientRects */
  Future<ElementRect> get rect() {
    return _createMeasurementFuture(
        () => new ElementRectWrappingImplementation(_ptr),
        new Completer<ElementRect>());
  }

  Future<CSSStyleDeclaration> get computedStyle() {
     // TODO(jacobr): last param should be null, see b/5045788
     return getComputedStyle('');
  }

  /** @domName Window.getComputedStyle */
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) {
    return _createMeasurementFuture(() =>
        LevelDom.wrapCSSStyleDeclaration(
            dom.window.getComputedStyle(_ptr, pseudoElement)),
        new Completer<CSSStyleDeclaration>());
  }

  ElementEvents get on() {
    if (_on === null) {
      _on = new ElementEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
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

class ErrorEventWrappingImplementation extends EventWrappingImplementation implements ErrorEvent {
  ErrorEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory ErrorEventWrappingImplementation(String type, String message,
      String filename, int lineNo, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent("ErrorEvent");
    e.initErrorEvent(type, canBubble, cancelable, message, filename, lineNo);
    return LevelDom.wrapErrorEvent(e);
  }

  String get filename() => _ptr.filename;

  int get lineno() => _ptr.lineno;

  String get message() => _ptr.message;
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

class EventSourceEventsImplementation extends EventsImplementation implements EventSourceEvents {
  EventSourceEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get error() => _get('error');
  EventListenerList get message() => _get('message');
  EventListenerList get open() => _get('open');
}

class EventSourceWrappingImplementation extends EventTargetWrappingImplementation implements EventSource {
  EventSourceWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  String get URL() => _ptr.URL;

  int get readyState() => _ptr.readyState;

  void close() {
    _ptr.close();
  }

  EventSourceEvents get on() {
    if (_on === null) {
      _on = new EventSourceEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
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

class EventsImplementation implements Events {
  /* Raw event target. */
  var _ptr;

  Map<String, EventListenerList> _listenerMap;

  EventsImplementation._wrap(this._ptr) {
    _listenerMap = <String, EventListenerList>{};
  }

  EventListenerList operator [](String type) {
    return _get(type.toLowerCase());
  }
  
  EventListenerList _get(String type) {
    return _listenerMap.putIfAbsent(type,
      () => new EventListenerListImplementation(_ptr, type));
  }
}

class _EventListenerWrapper {
  final EventListener raw;
  final Function wrapped;
  final bool useCapture;
  _EventListenerWrapper(this.raw, this.wrapped, this.useCapture);
}

class EventListenerListImplementation implements EventListenerList {
  final _ptr;
  final String _type;
  List<_EventListenerWrapper> _wrappers;

  EventListenerListImplementation(this._ptr, this._type) :
    // TODO(jacobr): switch to <_EventListenerWrapper>[] when the VM allow it.
    _wrappers = new List<_EventListenerWrapper>();

  EventListenerList add(EventListener listener, [bool useCapture = false]) {
    _add(listener, useCapture);
    return this;
  }

  EventListenerList remove(EventListener listener, [bool useCapture = false]) {
    _remove(listener, useCapture);
    return this;
  }

  bool dispatch(Event evt) {
    // TODO(jacobr): what is the correct behavior here. We could alternately
    // force the event to have the expected type.
    assert(evt.type == _type);
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  void _add(EventListener listener, bool useCapture) {
    _ptr.addEventListener(_type,
                          _findOrAddWrapper(listener, useCapture),
                          useCapture);
  }

  void _remove(EventListener listener, bool useCapture) {
    Function wrapper = _removeWrapper(listener, useCapture);
    if (wrapper !== null) {
      _ptr.removeEventListener(_type, wrapper, useCapture);
    }
  }

  Function _removeWrapper(EventListener listener, bool useCapture) {
    if (_wrappers === null) {
      return null;
    }
    for (int i = 0; i < _wrappers.length; i++) {
      _EventListenerWrapper wrapper = _wrappers[i];
      if (wrapper.raw === listener && wrapper.useCapture == useCapture) {
        // Order doesn't matter so we swap with the last element instead of
        // performing a more expensive remove from the middle of the list.
        if (i + 1 != _wrappers.length) {
          _wrappers[i] = _wrappers.removeLast();
        } else {
          _wrappers.removeLast();
        }
        return wrapper.wrapped;
      }
    }
    return null;
  }

  Function _findOrAddWrapper(EventListener listener, bool useCapture) {
    if (_wrappers === null) {
      _wrappers = <_EventListenerWrapper>[];
    } else {
      for (_EventListenerWrapper wrapper in _wrappers) {
        if (wrapper.raw === listener && wrapper.useCapture == useCapture) {
          return wrapper.wrapped;
        }
      }
    }
    final wrapped = (e) { listener(LevelDom.wrapEvent(e)); };
    _wrappers.add(new _EventListenerWrapper(listener, wrapped, useCapture));
    return wrapped;
  }
}

class EventTargetWrappingImplementation extends DOMWrapperBase implements EventTarget {
  Events _on;

  EventTargetWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  Events get on() {
    if (_on === null) {
      _on = new EventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EventWrappingImplementation extends DOMWrapperBase implements Event {
  EventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory EventWrappingImplementation(String type, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent("Event");
    e.initEvent(type, canBubble, cancelable);
    return LevelDom.wrapEvent(e);
  }

  bool get bubbles() => _ptr.bubbles;

  bool get cancelBubble() => _ptr.cancelBubble;

  void set cancelBubble(bool value) { _ptr.cancelBubble = value; }

  bool get cancelable() => _ptr.cancelable;

  EventTarget get currentTarget() => LevelDom.wrapEventTarget(_ptr.currentTarget);

  bool get defaultPrevented() => _ptr.defaultPrevented;

  int get eventPhase() => _ptr.eventPhase;

  bool get returnValue() => _ptr.returnValue;

  void set returnValue(bool value) { _ptr.returnValue = value; }

  EventTarget get srcElement() => LevelDom.wrapEventTarget(_ptr.srcElement);

  EventTarget get target() => LevelDom.wrapEventTarget(_ptr.target);

  int get timeStamp() => _ptr.timeStamp;

  String get type() => _ptr.type;

  void preventDefault() {
    _ptr.preventDefault();
    return;
  }

  void stopImmediatePropagation() {
    _ptr.stopImmediatePropagation();
    return;
  }

  void stopPropagation() {
    _ptr.stopPropagation();
    return;
  }
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

class HashChangeEventWrappingImplementation extends EventWrappingImplementation implements HashChangeEvent {
  HashChangeEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory HashChangeEventWrappingImplementation(String type, String oldURL,
      String newURL, [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("HashChangeEvent");
    e.initHashChangeEvent(type, canBubble, cancelable, oldURL, newURL);
    return LevelDom.wrapHashChangeEvent(e);
  }

  String get newURL() => _ptr.newURL;

  String get oldURL() => _ptr.oldURL;
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

class KeyboardEventWrappingImplementation extends UIEventWrappingImplementation implements KeyboardEvent {
  KeyboardEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory KeyboardEventWrappingImplementation(String type, Window view,
      String keyIdentifier, int keyLocation, [bool canBubble = true,
      bool cancelable = true, bool ctrlKey = false, bool altKey = false,
      bool shiftKey = false, bool metaKey = false, bool altGraphKey = false]) {
    final e = dom.document.createEvent("KeyboardEvent");
    e.initKeyboardEvent(type, canBubble, cancelable, LevelDom.unwrap(view),
        keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey,
        altGraphKey);
    return LevelDom.wrapKeyboardEvent(e);
  }

  bool get altGraphKey() => _ptr.altGraphKey;

  bool get altKey() => _ptr.altKey;

  bool get ctrlKey() => _ptr.ctrlKey;

  String get keyIdentifier() => _ptr.keyIdentifier;

  int get keyLocation() => _ptr.keyLocation;

  bool get metaKey() => _ptr.metaKey;

  bool get shiftKey() => _ptr.shiftKey;

  bool getModifierState(String keyIdentifierArg) {
    return _ptr.getModifierState(keyIdentifierArg);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
  for (_MeasurementRequest request in _pendingRequests) {
    try {
      request.value = request.computeValue();
    } catch(var e) {
      request.value = e;
      request.exception = true;
    }
  }

  final completedRequests = _pendingRequests;
  final readyMeasurementFrameCallbacks = _pendingMeasurementFrameCallbacks;
  _pendingRequests = null;
  _pendingMeasurementFrameCallbacks = null;
  for (_MeasurementRequest request in completedRequests) {
    if (request.exception) {
      request.completer.completeException(request.value);
    } else {
      request.completer.complete(request.value);
    }
  }

  if (readyMeasurementFrameCallbacks !== null) {
    for (TimeoutHandler handler in readyMeasurementFrameCallbacks) {
      // TODO(jacobr): wrap each call to a handler in a try-catch block.
      handler();
    }
  }
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

class MessageEventWrappingImplementation extends EventWrappingImplementation implements MessageEvent {
  MessageEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory MessageEventWrappingImplementation(String type, String data,
      String origin, String lastEventId, Window source, MessagePort port,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("MessageEvent");
    e.initMessageEvent(type, canBubble, cancelable, data, origin, lastEventId,
        LevelDom.unwrap(source), LevelDom.unwrap(port));
    return LevelDom.wrapMessageEvent(e);
  }

  String get data() => _ptr.data;

  String get lastEventId() => _ptr.lastEventId;

  MessagePort get messagePort() => LevelDom.wrapMessagePort(_ptr.messagePort);

  String get origin() => _ptr.origin;

  Window get source() => LevelDom.wrapWindow(_ptr.source);

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String dataArg, String originArg, String lastEventIdArg, Window sourceArg, MessagePort messagePort) {
    _ptr.initMessageEvent(typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, LevelDom.unwrap(sourceArg), LevelDom.unwrap(messagePort));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface MessagePort extends EventTarget {
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MessagePortWrappingImplementation extends EventTargetWrappingImplementation implements MessagePort {
  MessagePortWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
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

class MouseEventWrappingImplementation extends UIEventWrappingImplementation implements MouseEvent {
  MouseEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory MouseEventWrappingImplementation(String type, Window view, int detail,
      int screenX, int screenY, int clientX, int clientY, int button,
      [bool canBubble = true, bool cancelable = true, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) {
    final e = dom.document.createEvent("MouseEvent");
    e.initMouseEvent(type, canBubble, cancelable, LevelDom.unwrap(view), detail,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey,
        button, LevelDom.unwrap(relatedTarget));
    return LevelDom.wrapMouseEvent(e);
  }

  bool get altKey() => _ptr.altKey;

  int get button() => _ptr.button;

  int get clientX() => _ptr.clientX;

  int get clientY() => _ptr.clientY;

  bool get ctrlKey() => _ptr.ctrlKey;

  Node get fromElement() => LevelDom.wrapNode(_ptr.fromElement);

  bool get metaKey() => _ptr.metaKey;

  int get offsetX() => _ptr.offsetX;

  int get offsetY() => _ptr.offsetY;

  EventTarget get relatedTarget() => LevelDom.wrapEventTarget(_ptr.relatedTarget);

  int get screenX() => _ptr.screenX;

  int get screenY() => _ptr.screenY;

  bool get shiftKey() => _ptr.shiftKey;

  Node get toElement() => LevelDom.wrapNode(_ptr.toElement);

  int get x() => _ptr.x;

  int get y() => _ptr.y;
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

class MutationEventWrappingImplementation extends EventWrappingImplementation implements MutationEvent {
  MutationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory MutationEventWrappingImplementation(String type, Node relatedNode,
      String prevValue, String newValue, String attrName, int attrChange,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("MutationEvent");
    e.initMutationEvent(type, canBubble, cancelable,
        LevelDom.unwrap(relatedNode), prevValue, newValue, attrName,
        attrChange);
    return LevelDom.wrapMutationEvent(e);
  }

  int get attrChange() => _ptr.attrChange;

  String get attrName() => _ptr.attrName;

  String get newValue() => _ptr.newValue;

  String get prevValue() => _ptr.prevValue;

  Node get relatedNode() => LevelDom.wrapNode(_ptr.relatedNode);
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

class _ChildrenNodeList implements NodeList {
  // Raw node.
  final _node;
  final _childNodes;

  _ChildrenNodeList._wrap(var node)
    : _childNodes = node.childNodes,
      _node = node;

  List<Node> _toList() {
    final output = new List(_childNodes.length);
    for (int i = 0, len = _childNodes.length; i < len; i++) {
      output[i] = LevelDom.wrapNode(_childNodes[i]);
    }
    return output;
  }

  Node get first() {
    return LevelDom.wrapNode(_node.firstChild);
  }

  void forEach(void f(Node element)) {
    for (var node in _childNodes) {
      f(LevelDom.wrapNode(node));
    }
  }

  Collection<Node> filter(bool f(Node element)) {
    List<Node> output = new List<Node>();
    forEach((Node element) {
      if (f(element)) {
        output.add(element);
      }
    });
    return output;
  }

  bool every(bool f(Node element)) {
    for(Node element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool some(bool f(Node element)) {
    for(Node element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  /** @domName Node.hasChildNodes */
  bool isEmpty() {
    return !_node.hasChildNodes();
  }

  int get length() {
    return _childNodes.length;
  }

  Node operator [](int index) {
    return LevelDom.wrapNode(_childNodes[index]);
  }

  void operator []=(int index, Node value) {
    _childNodes[index] = LevelDom.unwrap(value);
  }

   void set length(int newLength) {
     throw new UnsupportedOperationException('');
   }

  /** @domName Node.appendChild */
  Node add(Node value) {
    _node.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Node addLast(Node value) {
    _node.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Iterator<Node> iterator() {
    return _toList().iterator();
  }

  void addAll(Collection<Node> collection) {
    for (Node node in collection) {
      _node.appendChild(LevelDom.unwrap(node));
    }
  }

  void sort(int compare(Node a, Node b)) {
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

  List getRange(int start, int length) {
    throw const NotImplementedException();
  }

  int indexOf(Node element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Node element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    _node.textContent = '';
  }

  Node removeLast() {
    final last = this.last();
    if (last != null) {
      _node.removeChild(LevelDom.unwrap(last));
    }
    return last;
  }

  Node last() {
    return LevelDom.wrapNode(_node.lastChild);
  }
}

class NodeWrappingImplementation extends EventTargetWrappingImplementation implements Node {
  NodeList _nodes;

  NodeWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  void set nodes(Collection<Node> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    nodes.clear();
    nodes.addAll(copy);
  }

  NodeList get nodes() {
    if (_nodes === null) {
      _nodes = new _ChildrenNodeList._wrap(_ptr);
    }
    return _nodes;
  }

  Node get nextNode() => LevelDom.wrapNode(_ptr.nextSibling);

  Document get document() => LevelDom.wrapDocument(_ptr.ownerDocument);

  Node get parent() => LevelDom.wrapNode(_ptr.parentNode);

  Node get previousNode() => LevelDom.wrapNode(_ptr.previousSibling);

  String get text() => _ptr.textContent;

  void set text(String value) { _ptr.textContent = value; }

  // New methods implemented.
  Node replaceWith(Node otherNode) {
    try {
      _ptr.parentNode.replaceChild(LevelDom.unwrap(otherNode), _ptr);
    } catch(var e) {
      // TODO(jacobr): what should we return on failure?
    }
    return this;
  }

  Node remove() {
    // TODO(jacobr): should we throw an exception if parent is already null?
    if (_ptr.parentNode !== null) {
      _ptr.parentNode.removeChild(_ptr);
    }
    return this;
  }

  /** @domName contains */
  bool contains(Node otherNode) {
    // TODO: Feature detect and use built in.
    while (otherNode != null && otherNode != this) {
      otherNode = otherNode.parent;
    }
    return otherNode == this;
  }

  // TODO(jacobr): remove when/if List supports a method similar to
  // insertBefore or we switch NodeList to implement LinkedList rather than
  // array.
  Node insertBefore(Node newChild, Node refChild) {
    return LevelDom.wrapNode(_ptr.insertBefore(
        LevelDom.unwrap(newChild), LevelDom.unwrap(refChild)));
  }

  Node clone(bool deep) {
    return LevelDom.wrapNode(_ptr.cloneNode(deep));
  }
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

// TODO(jacobr) add custom Events class.
class NotificationWrappingImplementation extends EventTargetWrappingImplementation implements Notification {
  NotificationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get dir() { return _ptr.dir; }

  void set dir(String value) { _ptr.dir = value; }

  EventListener get onclick() { return LevelDom.wrapEventListener(_ptr.onclick); }

  void set onclick(EventListener value) { _ptr.onclick = LevelDom.unwrap(value); }

  EventListener get onclose() { return LevelDom.wrapEventListener(_ptr.onclose); }

  void set onclose(EventListener value) { _ptr.onclose = LevelDom.unwrap(value); }

  EventListener get ondisplay() { return LevelDom.wrapEventListener(_ptr.ondisplay); }

  void set ondisplay(EventListener value) { _ptr.ondisplay = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  String get replaceId() { return _ptr.replaceId; }

  void set replaceId(String value) { _ptr.replaceId = value; }

  void cancel() {
    _ptr.cancel();
    return;
  }

  void show() {
    _ptr.show();
    return;
  }

  String get typeName() { return "Notification"; }
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

class OverflowEventWrappingImplementation extends EventWrappingImplementation implements OverflowEvent {
  OverflowEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  /** @domName OverflowEvent.initOverflowEvent */
  factory OverflowEventWrappingImplementation(int orient,
      bool horizontalOverflow, bool verticalOverflow) {
    final e = dom.document.createEvent("OverflowEvent");
    e.initOverflowEvent(orient, horizontalOverflow, verticalOverflow);
    return LevelDom.wrapOverflowEvent(e);
  }

  bool get horizontalOverflow() => _ptr.horizontalOverflow;

  int get orient() => _ptr.orient;

  bool get verticalOverflow() => _ptr.verticalOverflow;
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

class PageTransitionEventWrappingImplementation extends EventWrappingImplementation implements PageTransitionEvent {
  PageTransitionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory PageTransitionEventWrappingImplementation(String type,
      [bool canBubble = true, bool cancelable = true,
      bool persisted = false]) {
    final e = dom.document.createEvent("PageTransitionEvent");
    e.initPageTransitionEvent(type, canBubble, cancelable, persisted);
    return LevelDom.wrapPageTransitionEvent(e);
  }

  bool get persisted() => _ptr.persisted;
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

class PopStateEventWrappingImplementation extends EventWrappingImplementation implements PopStateEvent {
  PopStateEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory PopStateEventWrappingImplementation(String type, Object state,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("PopStateEvent");
    e.initPopStateEvent(type, canBubble, cancelable, state);
    return LevelDom.wrapPopStateEvent(e);
  }

  String get state() => _ptr.state;
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

class ProgressEventWrappingImplementation extends EventWrappingImplementation implements ProgressEvent {
  ProgressEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory ProgressEventWrappingImplementation(String type, int loaded,
      [bool canBubble = true, bool cancelable = true,
      bool lengthComputable = false, int total = 0]) {
    final e = dom.document.createEvent("ProgressEvent");
    e.initProgressEvent(type, canBubble, cancelable, lengthComputable, loaded,
        total);
    return LevelDom.wrapProgressEvent(e);
  }

  bool get lengthComputable() => _ptr.lengthComputable;

  int get loaded() => _ptr.loaded;

  int get total() => _ptr.total;
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

class SharedWorkerWrappingImplementation extends AbstractWorkerWrappingImplementation implements SharedWorker {
  SharedWorkerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  MessagePort get port() { return LevelDom.wrapMessagePort(_ptr.port); }
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

class StorageEventWrappingImplementation extends EventWrappingImplementation implements StorageEvent {
  StorageEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory StorageEventWrappingImplementation(String type, String key,
      String url, Storage storageArea, [bool canBubble = true,
      bool cancelable = true, String oldValue = null,
      String newValue = null]) {
    final e = dom.document.createEvent("StorageEvent");
    e.initStorageEvent(type, canBubble, cancelable, key, oldValue, newValue,
        url, LevelDom.unwrap(storageArea));
    return LevelDom.wrapStorageEvent(e);
  }

  String get key() => _ptr.key;

  String get newValue() => _ptr.newValue;

  String get oldValue() => _ptr.oldValue;

  Storage get storageArea() => LevelDom.wrapStorage(_ptr.storageArea);

  String get url() => _ptr.url;
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

class TextEventWrappingImplementation extends UIEventWrappingImplementation implements TextEvent {
  TextEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory TextEventWrappingImplementation(String type, Window view, String data,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("TextEvent");
    e.initTextEvent(type, canBubble, cancelable, LevelDom.unwrap(view), data);
    return LevelDom.wrapTextEvent(e);
  }

  String get data() => _ptr.data;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TextWrappingImplementation extends CharacterDataWrappingImplementation implements Text {
  /** @domName Document.createTextNode */
  factory TextWrappingImplementation(String content) {
    return new TextWrappingImplementation._wrap(
        dom.document.createTextNode(content));
  }

  TextWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  String get wholeText() => _ptr.wholeText;

  Text replaceWholeText([String content = null]) {
    if (content === null) {
      return LevelDom.wrapText(_ptr.replaceWholeText());
    } else {
      return LevelDom.wrapText(_ptr.replaceWholeText(content));
    }
  }

  Text splitText([int offset = null]) {
    if (offset === null) {
      return LevelDom.wrapText(_ptr.splitText());
    } else {
      return LevelDom.wrapText(_ptr.splitText(offset));
    }
  }
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

class TouchEventWrappingImplementation extends UIEventWrappingImplementation implements TouchEvent {
  TouchEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory TouchEvent(TouchList touches, TouchList targetTouches,
      TouchList changedTouches, String type, Window view, int screenX,
      int screenY, int clientX, int clientY, [bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false]) {
    final e = dom.document.createEvent("TouchEvent");
    e.initTouchEvent(LevelDom.unwrap(touches), LevelDom.unwrap(targetTouches),
        LevelDom.unwrap(changedTouches), type, LevelDom.unwrap(view), screenX,
        screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return LevelDom.wrapTouchEvent(e);
  }

  bool get altKey() => _ptr.altKey;

  TouchList get changedTouches() => LevelDom.wrapTouchList(_ptr.changedTouches);

  bool get ctrlKey() => _ptr.ctrlKey;

  bool get metaKey() => _ptr.metaKey;

  bool get shiftKey() => _ptr.shiftKey;

  TouchList get targetTouches() => LevelDom.wrapTouchList(_ptr.targetTouches);

  TouchList get touches() => LevelDom.wrapTouchList(_ptr.touches);
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

class TransitionEventWrappingImplementation extends EventWrappingImplementation implements TransitionEvent {
  static String _name;

  TransitionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  static String get _eventName() {
    if (_name != null) return _name;

    try {
      dom.document.createEvent("WebKitTransitionEvent");
      _name = "WebKitTransitionEvent";
    } catch (var e) {
      _name = "TransitionEvent";
    }
    return _name;
  }

  factory TransitionEventWrappingImplementation(String type,
      String propertyName, double elapsedTime, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent(_eventName);
    e.initWebKitTransitionEvent(type, canBubble, cancelable, propertyName,
        elapsedTime);
    return LevelDom.wrapTransitionEvent(e);
  }

  num get elapsedTime() => _ptr.elapsedTime;

  String get propertyName() => _ptr.propertyName;
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

class UIEventWrappingImplementation extends EventWrappingImplementation implements UIEvent {
  UIEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory UIEventWrappingImplementation(String type, Window view, int detail,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("UIEvent");
    e.initUIEvent(type, canBubble, cancelable, LevelDom.unwrap(view), detail);
    return LevelDom.wrapUIEvent(e);
  }

  int get charCode() => _ptr.charCode;

  int get detail() => _ptr.detail;

  int get keyCode() => _ptr.keyCode;

  int get layerX() => _ptr.layerX;

  int get layerY() => _ptr.layerY;

  int get pageX() => _ptr.pageX;

  int get pageY() => _ptr.pageY;

  Window get view() => LevelDom.wrapWindow(_ptr.view);

  int get which() => _ptr.which;
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

// TODO(jacobr) add events.
class WebSocketWrappingImplementation extends EventTargetWrappingImplementation implements WebSocket {
  WebSocketWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get URL() { return _ptr.URL; }

  String get binaryType() { return _ptr.binaryType; }

  void set binaryType(String value) { _ptr.binaryType = value; }

  int get bufferedAmount() { return _ptr.bufferedAmount; }

  EventListener get onclose() { return LevelDom.wrapEventListener(_ptr.onclose); }

  void set onclose(EventListener value) { _ptr.onclose = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onmessage() { return LevelDom.wrapEventListener(_ptr.onmessage); }

  void set onmessage(EventListener value) { _ptr.onmessage = LevelDom.unwrap(value); }

  EventListener get onopen() { return LevelDom.wrapEventListener(_ptr.onopen); }

  void set onopen(EventListener value) { _ptr.onopen = LevelDom.unwrap(value); }

  String get protocol() { return _ptr.protocol; }

  int get readyState() { return _ptr.readyState; }

  void close() {
    _ptr.close();
    return;
  }

  bool send(String data) {
    return _ptr.send(data);
  }

  String get typeName() { return "WebSocket"; }
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

class WheelEventWrappingImplementation extends UIEventWrappingImplementation implements WheelEvent {
  WheelEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory WheelEventWrappingImplementation(int deltaX, int deltaY, Window view,
      int screenX, int screenY, int clientX, int clientY, [bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false]) {
    final e = dom.document.createEvent("WheelEvent");
    e.initWebKitWheelEvent(deltaX, deltaY, LevelDom.unwrap(view), screenX, screenY,
        clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return LevelDom.wrapWheelEvent(e);
  }

  bool get altKey() => _ptr.altKey;

  int get clientX() => _ptr.clientX;

  int get clientY() => _ptr.clientY;

  bool get ctrlKey() => _ptr.ctrlKey;

  bool get metaKey() => _ptr.metaKey;

  int get offsetX() => _ptr.offsetX;

  int get offsetY() => _ptr.offsetY;

  int get screenX() => _ptr.screenX;

  int get screenY() => _ptr.screenY;

  bool get shiftKey() => _ptr.shiftKey;

  int get wheelDelta() => _ptr.wheelDelta;

  int get wheelDeltaX() => _ptr.wheelDeltaX;

  int get wheelDeltaY() => _ptr.wheelDeltaY;

  int get x() => _ptr.x;

  int get y() => _ptr.y;
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

// TODO(jacobr): define a base class containing the overlap between
// this class and ElementEvents.
class WindowEventsImplementation extends EventsImplementation
      implements WindowEvents {
  WindowEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get('abort');
  EventListenerList get beforeUnload() => _get('beforeunload');
  EventListenerList get blur() => _get('blur');
  EventListenerList get canPlay() => _get('canplay');
  EventListenerList get canPlayThrough() => _get('canplaythrough');
  EventListenerList get change() => _get('change');
  EventListenerList get click() => _get('click');
  EventListenerList get contextMenu() => _get('contextmenu');
  EventListenerList get dblClick() => _get('dblclick');
  EventListenerList get deviceMotion() => _get('devicemotion');
  EventListenerList get deviceOrientation() => _get('deviceorientation');
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
  EventListenerList get loadedData() => _get('loadeddata');
  EventListenerList get loadedMetaData() => _get('loadedmetadata');
  EventListenerList get loadStart() => _get('loadstart');
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
  EventListenerList get unLoad() => _get('unload');
  EventListenerList get volumeChange() => _get('volumechange');
  EventListenerList get waiting() => _get('waiting');
  EventListenerList get animationEnd() => _get('webkitAnimationEnd');
  EventListenerList get animationIteration() => _get('webkitAnimationIteration');
  EventListenerList get animationStart() => _get('webkitAnimationStart');
  EventListenerList get transitionEnd() => _get('webkitTransitionEnd');
  EventListenerList get contentLoaded() => _get('DOMContentLoaded');
}

/** @domName Window */
class WindowWrappingImplementation extends EventTargetWrappingImplementation implements Window {
  WindowWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  DOMApplicationCache get applicationCache() => LevelDom.wrapDOMApplicationCache(_ptr.applicationCache);

  Navigator get clientInformation() => LevelDom.wrapNavigator(_ptr.clientInformation);

  void set clientInformation(Navigator value) { _ptr.clientInformation = LevelDom.unwrap(value); }

  bool get closed() => _ptr.closed;

  Console get console() => LevelDom.wrapConsole(_ptr.console);

  void set console(Console value) { _ptr.console = LevelDom.unwrap(value); }

  Crypto get crypto() => LevelDom.wrapCrypto(_ptr.crypto);

  String get defaultStatus() => _ptr.defaultStatus;

  void set defaultStatus(String value) { _ptr.defaultStatus = value; }

  num get devicePixelRatio() => _ptr.devicePixelRatio;

  void set devicePixelRatio(num value) { _ptr.devicePixelRatio = value; }

  Document get document() => LevelDom.wrapDocument(_ptr.document);

  Event get event() => LevelDom.wrapEvent(_ptr.event);

  void set event(Event value) { _ptr.event = LevelDom.unwrap(value); }

  Element get frameElement() => LevelDom.wrapElement(_ptr.frameElement);

  Window get frames() => LevelDom.wrapWindow(_ptr.frames);

  void set frames(Window value) { _ptr.frames = LevelDom.unwrap(value); }

  History get history() => LevelDom.wrapHistory(_ptr.history);

  void set history(History value) { _ptr.history = LevelDom.unwrap(value); }

  int get innerHeight() => _ptr.innerHeight;

  void set innerHeight(int value) { _ptr.innerHeight = value; }

  int get innerWidth() => _ptr.innerWidth;

  void set innerWidth(int value) { _ptr.innerWidth = value; }

  int get length() => _ptr.length;

  void set length(int value) { _ptr.length = value; }

  Storage get localStorage() => LevelDom.wrapStorage(_ptr.localStorage);

  Location get location() => LevelDom.wrapLocation(_ptr.location);

  void set location(Location value) { _ptr.location = LevelDom.unwrap(value); }

  BarInfo get locationbar() => LevelDom.wrapBarInfo(_ptr.locationbar);

  void set locationbar(BarInfo value) { _ptr.locationbar = LevelDom.unwrap(value); }

  BarInfo get menubar() => LevelDom.wrapBarInfo(_ptr.menubar);

  void set menubar(BarInfo value) { _ptr.menubar = LevelDom.unwrap(value); }

  String get name() => _ptr.name;

  void set name(String value) { _ptr.name = value; }

  Navigator get navigator() => LevelDom.wrapNavigator(_ptr.navigator);

  void set navigator(Navigator value) { _ptr.navigator = LevelDom.unwrap(value); }

  bool get offscreenBuffering() => _ptr.offscreenBuffering;

  void set offscreenBuffering(bool value) { _ptr.offscreenBuffering = value; }

  EventListener get onabort() => LevelDom.wrapEventListener(_ptr.onabort);

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get onbeforeunload() => LevelDom.wrapEventListener(_ptr.onbeforeunload);

  void set onbeforeunload(EventListener value) { _ptr.onbeforeunload = LevelDom.unwrap(value); }

  EventListener get onblur() => LevelDom.wrapEventListener(_ptr.onblur);

  void set onblur(EventListener value) { _ptr.onblur = LevelDom.unwrap(value); }

  EventListener get oncanplay() => LevelDom.wrapEventListener(_ptr.oncanplay);

  void set oncanplay(EventListener value) { _ptr.oncanplay = LevelDom.unwrap(value); }

  EventListener get oncanplaythrough() => LevelDom.wrapEventListener(_ptr.oncanplaythrough);

  void set oncanplaythrough(EventListener value) { _ptr.oncanplaythrough = LevelDom.unwrap(value); }

  EventListener get onchange() => LevelDom.wrapEventListener(_ptr.onchange);

  void set onchange(EventListener value) { _ptr.onchange = LevelDom.unwrap(value); }

  EventListener get onclick() => LevelDom.wrapEventListener(_ptr.onclick);

  void set onclick(EventListener value) { _ptr.onclick = LevelDom.unwrap(value); }

  EventListener get oncontextmenu() => LevelDom.wrapEventListener(_ptr.oncontextmenu);

  void set oncontextmenu(EventListener value) { _ptr.oncontextmenu = LevelDom.unwrap(value); }

  EventListener get ondblclick() => LevelDom.wrapEventListener(_ptr.ondblclick);

  void set ondblclick(EventListener value) { _ptr.ondblclick = LevelDom.unwrap(value); }

  EventListener get ondevicemotion() => LevelDom.wrapEventListener(_ptr.ondevicemotion);

  void set ondevicemotion(EventListener value) { _ptr.ondevicemotion = LevelDom.unwrap(value); }

  EventListener get ondeviceorientation() => LevelDom.wrapEventListener(_ptr.ondeviceorientation);

  void set ondeviceorientation(EventListener value) { _ptr.ondeviceorientation = LevelDom.unwrap(value); }

  EventListener get ondrag() => LevelDom.wrapEventListener(_ptr.ondrag);

  void set ondrag(EventListener value) { _ptr.ondrag = LevelDom.unwrap(value); }

  EventListener get ondragend() => LevelDom.wrapEventListener(_ptr.ondragend);

  void set ondragend(EventListener value) { _ptr.ondragend = LevelDom.unwrap(value); }

  EventListener get ondragenter() => LevelDom.wrapEventListener(_ptr.ondragenter);

  void set ondragenter(EventListener value) { _ptr.ondragenter = LevelDom.unwrap(value); }

  EventListener get ondragleave() => LevelDom.wrapEventListener(_ptr.ondragleave);

  void set ondragleave(EventListener value) { _ptr.ondragleave = LevelDom.unwrap(value); }

  EventListener get ondragover() => LevelDom.wrapEventListener(_ptr.ondragover);

  void set ondragover(EventListener value) { _ptr.ondragover = LevelDom.unwrap(value); }

  EventListener get ondragstart() => LevelDom.wrapEventListener(_ptr.ondragstart);

  void set ondragstart(EventListener value) { _ptr.ondragstart = LevelDom.unwrap(value); }

  EventListener get ondrop() => LevelDom.wrapEventListener(_ptr.ondrop);

  void set ondrop(EventListener value) { _ptr.ondrop = LevelDom.unwrap(value); }

  EventListener get ondurationchange() => LevelDom.wrapEventListener(_ptr.ondurationchange);

  void set ondurationchange(EventListener value) { _ptr.ondurationchange = LevelDom.unwrap(value); }

  EventListener get onemptied() => LevelDom.wrapEventListener(_ptr.onemptied);

  void set onemptied(EventListener value) { _ptr.onemptied = LevelDom.unwrap(value); }

  EventListener get onended() => LevelDom.wrapEventListener(_ptr.onended);

  void set onended(EventListener value) { _ptr.onended = LevelDom.unwrap(value); }

  EventListener get onerror() => LevelDom.wrapEventListener(_ptr.onerror);

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onfocus() => LevelDom.wrapEventListener(_ptr.onfocus);

  void set onfocus(EventListener value) { _ptr.onfocus = LevelDom.unwrap(value); }

  EventListener get onhashchange() => LevelDom.wrapEventListener(_ptr.onhashchange);

  void set onhashchange(EventListener value) { _ptr.onhashchange = LevelDom.unwrap(value); }

  EventListener get oninput() => LevelDom.wrapEventListener(_ptr.oninput);

  void set oninput(EventListener value) { _ptr.oninput = LevelDom.unwrap(value); }

  EventListener get oninvalid() => LevelDom.wrapEventListener(_ptr.oninvalid);

  void set oninvalid(EventListener value) { _ptr.oninvalid = LevelDom.unwrap(value); }

  EventListener get onkeydown() => LevelDom.wrapEventListener(_ptr.onkeydown);

  void set onkeydown(EventListener value) { _ptr.onkeydown = LevelDom.unwrap(value); }

  EventListener get onkeypress() => LevelDom.wrapEventListener(_ptr.onkeypress);

  void set onkeypress(EventListener value) { _ptr.onkeypress = LevelDom.unwrap(value); }

  EventListener get onkeyup() => LevelDom.wrapEventListener(_ptr.onkeyup);

  void set onkeyup(EventListener value) { _ptr.onkeyup = LevelDom.unwrap(value); }

  EventListener get onload() => LevelDom.wrapEventListener(_ptr.onload);

  void set onload(EventListener value) { _ptr.onload = LevelDom.unwrap(value); }

  EventListener get onloadeddata() => LevelDom.wrapEventListener(_ptr.onloadeddata);

  void set onloadeddata(EventListener value) { _ptr.onloadeddata = LevelDom.unwrap(value); }

  EventListener get onloadedmetadata() => LevelDom.wrapEventListener(_ptr.onloadedmetadata);

  void set onloadedmetadata(EventListener value) { _ptr.onloadedmetadata = LevelDom.unwrap(value); }

  EventListener get onloadstart() => LevelDom.wrapEventListener(_ptr.onloadstart);

  void set onloadstart(EventListener value) { _ptr.onloadstart = LevelDom.unwrap(value); }

  EventListener get onmessage() => LevelDom.wrapEventListener(_ptr.onmessage);

  void set onmessage(EventListener value) { _ptr.onmessage = LevelDom.unwrap(value); }

  EventListener get onmousedown() => LevelDom.wrapEventListener(_ptr.onmousedown);

  void set onmousedown(EventListener value) { _ptr.onmousedown = LevelDom.unwrap(value); }

  EventListener get onmousemove() => LevelDom.wrapEventListener(_ptr.onmousemove);

  void set onmousemove(EventListener value) { _ptr.onmousemove = LevelDom.unwrap(value); }

  EventListener get onmouseout() => LevelDom.wrapEventListener(_ptr.onmouseout);

  void set onmouseout(EventListener value) { _ptr.onmouseout = LevelDom.unwrap(value); }

  EventListener get onmouseover() => LevelDom.wrapEventListener(_ptr.onmouseover);

  void set onmouseover(EventListener value) { _ptr.onmouseover = LevelDom.unwrap(value); }

  EventListener get onmouseup() => LevelDom.wrapEventListener(_ptr.onmouseup);

  void set onmouseup(EventListener value) { _ptr.onmouseup = LevelDom.unwrap(value); }

  EventListener get onmousewheel() => LevelDom.wrapEventListener(_ptr.onmousewheel);

  void set onmousewheel(EventListener value) { _ptr.onmousewheel = LevelDom.unwrap(value); }

  EventListener get onoffline() => LevelDom.wrapEventListener(_ptr.onoffline);

  void set onoffline(EventListener value) { _ptr.onoffline = LevelDom.unwrap(value); }

  EventListener get ononline() => LevelDom.wrapEventListener(_ptr.ononline);

  void set ononline(EventListener value) { _ptr.ononline = LevelDom.unwrap(value); }

  EventListener get onpagehide() => LevelDom.wrapEventListener(_ptr.onpagehide);

  void set onpagehide(EventListener value) { _ptr.onpagehide = LevelDom.unwrap(value); }

  EventListener get onpageshow() => LevelDom.wrapEventListener(_ptr.onpageshow);

  void set onpageshow(EventListener value) { _ptr.onpageshow = LevelDom.unwrap(value); }

  EventListener get onpause() => LevelDom.wrapEventListener(_ptr.onpause);

  void set onpause(EventListener value) { _ptr.onpause = LevelDom.unwrap(value); }

  EventListener get onplay() => LevelDom.wrapEventListener(_ptr.onplay);

  void set onplay(EventListener value) { _ptr.onplay = LevelDom.unwrap(value); }

  EventListener get onplaying() => LevelDom.wrapEventListener(_ptr.onplaying);

  void set onplaying(EventListener value) { _ptr.onplaying = LevelDom.unwrap(value); }

  EventListener get onpopstate() => LevelDom.wrapEventListener(_ptr.onpopstate);

  void set onpopstate(EventListener value) { _ptr.onpopstate = LevelDom.unwrap(value); }

  EventListener get onprogress() => LevelDom.wrapEventListener(_ptr.onprogress);

  void set onprogress(EventListener value) { _ptr.onprogress = LevelDom.unwrap(value); }

  EventListener get onratechange() => LevelDom.wrapEventListener(_ptr.onratechange);

  void set onratechange(EventListener value) { _ptr.onratechange = LevelDom.unwrap(value); }

  EventListener get onreset() => LevelDom.wrapEventListener(_ptr.onreset);

  void set onreset(EventListener value) { _ptr.onreset = LevelDom.unwrap(value); }

  EventListener get onresize() => LevelDom.wrapEventListener(_ptr.onresize);

  void set onresize(EventListener value) { _ptr.onresize = LevelDom.unwrap(value); }

  EventListener get onscroll() => LevelDom.wrapEventListener(_ptr.onscroll);

  void set onscroll(EventListener value) { _ptr.onscroll = LevelDom.unwrap(value); }

  EventListener get onsearch() => LevelDom.wrapEventListener(_ptr.onsearch);

  void set onsearch(EventListener value) { _ptr.onsearch = LevelDom.unwrap(value); }

  EventListener get onseeked() => LevelDom.wrapEventListener(_ptr.onseeked);

  void set onseeked(EventListener value) { _ptr.onseeked = LevelDom.unwrap(value); }

  EventListener get onseeking() => LevelDom.wrapEventListener(_ptr.onseeking);

  void set onseeking(EventListener value) { _ptr.onseeking = LevelDom.unwrap(value); }

  EventListener get onselect() => LevelDom.wrapEventListener(_ptr.onselect);

  void set onselect(EventListener value) { _ptr.onselect = LevelDom.unwrap(value); }

  EventListener get onstalled() => LevelDom.wrapEventListener(_ptr.onstalled);

  void set onstalled(EventListener value) { _ptr.onstalled = LevelDom.unwrap(value); }

  EventListener get onstorage() => LevelDom.wrapEventListener(_ptr.onstorage);

  void set onstorage(EventListener value) { _ptr.onstorage = LevelDom.unwrap(value); }

  EventListener get onsubmit() => LevelDom.wrapEventListener(_ptr.onsubmit);

  void set onsubmit(EventListener value) { _ptr.onsubmit = LevelDom.unwrap(value); }

  EventListener get onsuspend() => LevelDom.wrapEventListener(_ptr.onsuspend);

  void set onsuspend(EventListener value) { _ptr.onsuspend = LevelDom.unwrap(value); }

  EventListener get ontimeupdate() => LevelDom.wrapEventListener(_ptr.ontimeupdate);

  void set ontimeupdate(EventListener value) { _ptr.ontimeupdate = LevelDom.unwrap(value); }

  EventListener get ontouchcancel() => LevelDom.wrapEventListener(_ptr.ontouchcancel);

  void set ontouchcancel(EventListener value) { _ptr.ontouchcancel = LevelDom.unwrap(value); }

  EventListener get ontouchend() => LevelDom.wrapEventListener(_ptr.ontouchend);

  void set ontouchend(EventListener value) { _ptr.ontouchend = LevelDom.unwrap(value); }

  EventListener get ontouchmove() => LevelDom.wrapEventListener(_ptr.ontouchmove);

  void set ontouchmove(EventListener value) { _ptr.ontouchmove = LevelDom.unwrap(value); }

  EventListener get ontouchstart() => LevelDom.wrapEventListener(_ptr.ontouchstart);

  void set ontouchstart(EventListener value) { _ptr.ontouchstart = LevelDom.unwrap(value); }

  EventListener get onunload() => LevelDom.wrapEventListener(_ptr.onunload);

  void set onunload(EventListener value) { _ptr.onunload = LevelDom.unwrap(value); }

  EventListener get onvolumechange() => LevelDom.wrapEventListener(_ptr.onvolumechange);

  void set onvolumechange(EventListener value) { _ptr.onvolumechange = LevelDom.unwrap(value); }

  EventListener get onwaiting() => LevelDom.wrapEventListener(_ptr.onwaiting);

  void set onwaiting(EventListener value) { _ptr.onwaiting = LevelDom.unwrap(value); }

  EventListener get onwebkitanimationend() => LevelDom.wrapEventListener(_ptr.onwebkitanimationend);

  void set onwebkitanimationend(EventListener value) { _ptr.onwebkitanimationend = LevelDom.unwrap(value); }

  EventListener get onwebkitanimationiteration() => LevelDom.wrapEventListener(_ptr.onwebkitanimationiteration);

  void set onwebkitanimationiteration(EventListener value) { _ptr.onwebkitanimationiteration = LevelDom.unwrap(value); }

  EventListener get onwebkitanimationstart() => LevelDom.wrapEventListener(_ptr.onwebkitanimationstart);

  void set onwebkitanimationstart(EventListener value) { _ptr.onwebkitanimationstart = LevelDom.unwrap(value); }

  EventListener get onwebkittransitionend() => LevelDom.wrapEventListener(_ptr.onwebkittransitionend);

  void set onwebkittransitionend(EventListener value) { _ptr.onwebkittransitionend = LevelDom.unwrap(value); }

  Window get opener() => LevelDom.wrapWindow(_ptr.opener);

  void set opener(Window value) { _ptr.opener = LevelDom.unwrap(value); }

  int get outerHeight() => _ptr.outerHeight;

  void set outerHeight(int value) { _ptr.outerHeight = value; }

  int get outerWidth() => _ptr.outerWidth;

  void set outerWidth(int value) { _ptr.outerWidth = value; }

  int get pageXOffset() => _ptr.pageXOffset;

  int get pageYOffset() => _ptr.pageYOffset;

  Window get parent() => LevelDom.wrapWindow(_ptr.parent);

  void set parent(Window value) { _ptr.parent = LevelDom.unwrap(value); }

  BarInfo get personalbar() => LevelDom.wrapBarInfo(_ptr.personalbar);

  void set personalbar(BarInfo value) { _ptr.personalbar = LevelDom.unwrap(value); }

  Screen get screen() => LevelDom.wrapScreen(_ptr.screen);

  void set screen(Screen value) { _ptr.screen = LevelDom.unwrap(value); }

  int get screenLeft() => _ptr.screenLeft;

  void set screenLeft(int value) { _ptr.screenLeft = value; }

  int get screenTop() => _ptr.screenTop;

  void set screenTop(int value) { _ptr.screenTop = value; }

  int get screenX() => _ptr.screenX;

  void set screenX(int value) { _ptr.screenX = value; }

  int get screenY() => _ptr.screenY;

  void set screenY(int value) { _ptr.screenY = value; }

  int get scrollX() => _ptr.scrollX;

  void set scrollX(int value) { _ptr.scrollX = value; }

  int get scrollY() => _ptr.scrollY;

  void set scrollY(int value) { _ptr.scrollY = value; }

  BarInfo get scrollbars() => LevelDom.wrapBarInfo(_ptr.scrollbars);

  void set scrollbars(BarInfo value) { _ptr.scrollbars = LevelDom.unwrap(value); }

  Window get self() => LevelDom.wrapWindow(_ptr.self);

  void set self(Window value) { _ptr.self = LevelDom.unwrap(value); }

  Storage get sessionStorage() => LevelDom.wrapStorage(_ptr.sessionStorage);

  String get status() => _ptr.status;

  void set status(String value) { _ptr.status = value; }

  BarInfo get statusbar() => LevelDom.wrapBarInfo(_ptr.statusbar);

  void set statusbar(BarInfo value) { _ptr.statusbar = LevelDom.unwrap(value); }

  StyleMedia get styleMedia() => LevelDom.wrapStyleMedia(_ptr.styleMedia);

  BarInfo get toolbar() => LevelDom.wrapBarInfo(_ptr.toolbar);

  void set toolbar(BarInfo value) { _ptr.toolbar = LevelDom.unwrap(value); }

  Window get top() => LevelDom.wrapWindow(_ptr.top);

  void set top(Window value) { _ptr.top = LevelDom.unwrap(value); }

  NotificationCenter get webkitNotifications() => LevelDom.wrapNotificationCenter(_ptr.webkitNotifications);

  void alert([String message = null]) {
    if (message === null) {
      _ptr.alert();
    } else {
      _ptr.alert(message);
    }
  }

  String atob([String string = null]) {
    if (string === null) {
      return _ptr.atob();
    } else {
      return _ptr.atob(string);
    }
  }

  void blur() {
    _ptr.blur();
  }

  String btoa([String string = null]) {
    if (string === null) {
      return _ptr.btoa();
    } else {
      return _ptr.btoa(string);
    }
  }

  void captureEvents() {
    _ptr.captureEvents();
  }

  void clearInterval([int handle = null]) {
    if (handle === null) {
      _ptr.clearInterval();
    } else {
      _ptr.clearInterval(handle);
    }
  }

  void clearTimeout([int handle = null]) {
    if (handle === null) {
      _ptr.clearTimeout();
    } else {
      _ptr.clearTimeout(handle);
    }
  }

  void close() {
    _ptr.close();
  }

  bool confirm([String message = null]) {
    if (message === null) {
      return _ptr.confirm();
    } else {
      return _ptr.confirm(message);
    }
  }

  FileReader createFileReader() =>
    LevelDom.wrapFileReader(_ptr.createFileReader());

  CSSMatrix createCSSMatrix([String cssValue = null]) {
    if (cssValue === null) {
      return LevelDom.wrapCSSMatrix(_ptr.createWebKitCSSMatrix());
    } else {
      return LevelDom.wrapCSSMatrix(_ptr.createWebKitCSSMatrix(cssValue));
    }
  }

  bool find([String string = null, bool caseSensitive = null, bool backwards = null, bool wrap = null, bool wholeWord = null, bool searchInFrames = null, bool showDialog = null]) {
    if (string === null) {
      if (caseSensitive === null) {
        if (backwards === null) {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find();
                }
              }
            }
          }
        }
      }
    } else {
      if (caseSensitive === null) {
        if (backwards === null) {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string);
                }
              }
            }
          }
        }
      } else {
        if (backwards === null) {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive);
                }
              }
            }
          }
        } else {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards);
                }
              }
            }
          } else {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards, wrap);
                }
              }
            } else {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards, wrap, wholeWord);
                }
              } else {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards, wrap, wholeWord, searchInFrames);
                } else {
                  return _ptr.find(string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog);
                }
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void focus() {
    _ptr.focus();
  }

  DOMSelection getSelection() =>
    LevelDom.wrapDOMSelection(_ptr.getSelection());

  MediaQueryList matchMedia(String query) {
    return LevelDom.wrapMediaQueryList(_ptr.matchMedia(query));
  }

  void moveBy(num x, num y) {
    _ptr.moveBy(x, y);
  }

  void moveTo(num x, num y) {
    _ptr.moveTo(x, y);
  }

  Window open(String url, String target, [String features = null]) {
    if (features === null) {
      return LevelDom.wrapWindow(_ptr.open(url, target));
    } else {
      return LevelDom.wrapWindow(_ptr.open(url, target, features));
    }
  }

  // TODO(jacobr): cleanup.
  void postMessage(String message, [var messagePort = null, var targetOrigin = null]) {
    if (targetOrigin === null) {
      if (messagePort === null) {
        _ptr.postMessage(message);
        return;
      } else {
        // messagePort is really the targetOrigin string.
        _ptr.postMessage(message, messagePort);
        return;
      }
    } else {
      _ptr.postMessage(message, LevelDom.unwrap(messagePort), targetOrigin);
      return;
    }
    throw "Incorrect number or type of arguments";
  }

  void print() {
    _ptr.print();
  }

  String prompt([String message = null, String defaultValue = null]) {
    if (message === null) {
      if (defaultValue === null) {
        return _ptr.prompt();
      }
    } else {
      if (defaultValue === null) {
        return _ptr.prompt(message);
      } else {
        return _ptr.prompt(message, defaultValue);
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void releaseEvents() {
    _ptr.releaseEvents();
  }

  void resizeBy(num x, num y) {
    _ptr.resizeBy(x, y);
  }

  void resizeTo(num width, num height) {
    _ptr.resizeTo(width, height);
  }

  void scroll(int x, int y) {
    _ptr.scroll(x, y);
  }

  void scrollBy(int x, int y) {
    _ptr.scrollBy(x, y);
  }

  void scrollTo(int x, int y) {
    _ptr.scrollTo(x, y);
  }

  int setInterval(TimeoutHandler handler, int timeout) =>
    _ptr.setInterval(handler, timeout);

  int setTimeout(TimeoutHandler handler, int timeout) =>
    _ptr.setTimeout(handler, timeout);

  Object showModalDialog(String url, [Object dialogArgs = null, String featureArgs = null]) {
    if (dialogArgs === null) {
      if (featureArgs === null) {
        return _ptr.showModalDialog(url);
      }
    } else {
      if (featureArgs === null) {
        return _ptr.showModalDialog(url, LevelDom.unwrap(dialogArgs));
      } else {
        return _ptr.showModalDialog(url, LevelDom.unwrap(dialogArgs),
                                    featureArgs);
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void stop() {
    _ptr.stop();
  }

  void webkitCancelRequestAnimationFrame(int id) {
    _ptr.webkitCancelRequestAnimationFrame(id);
  }

  Point webkitConvertPointFromNodeToPage([Node node = null, Point p = null]) {
    if (node === null) {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromNodeToPage());
      }
    } else {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromNodeToPage(LevelDom.unwrap(node)));
      } else {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromNodeToPage(LevelDom.unwrap(node), LevelDom.unwrap(p)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  Point webkitConvertPointFromPageToNode([Node node = null, Point p = null]) {
    if (node === null) {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromPageToNode());
      }
    } else {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromPageToNode(LevelDom.unwrap(node)));
      } else {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromPageToNode(LevelDom.unwrap(node), LevelDom.unwrap(p)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, [Element element = null]) {
    if (element === null) {
      return _ptr.webkitRequestAnimationFrame(callback);
    } else {
      return _ptr.webkitRequestAnimationFrame(
          callback, LevelDom.unwrap(element));
    }
  }

  void requestLayoutFrame(TimeoutHandler callback) {
    _addMeasurementFrameCallback(callback);
  }

  WindowEvents get on() {
    if (_on === null) {
      _on = new WindowEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
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

class WorkerEventsImplementation extends AbstractWorkerEventsImplementation
    implements WorkerEvents {
  WorkerEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get message() => _get('message');
}

class WorkerWrappingImplementation extends EventTargetWrappingImplementation implements Worker {
  WorkerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void postMessage(String message, [MessagePort messagePort = null]) {
    if (messagePort === null) {
      _ptr.postMessage(message);
      return;
    } else {
      _ptr.postMessage(message, LevelDom.unwrap(messagePort));
      return;
    }
  }

  void terminate() {
    _ptr.terminate();
    return;
  }

  WorkerEvents get on() {
    if (_on === null) {
      _on = new WorkerEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
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

class XMLHttpRequestProgressEventWrappingImplementation extends ProgressEventWrappingImplementation implements XMLHttpRequestProgressEvent {
  XMLHttpRequestProgressEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory XMLHttpRequestProgressEventWrappingImplementation(String type,
      int loaded, [bool canBubble = true, bool cancelable = true,
      bool lengthComputable = false, int total = 0]) {
    final e = dom.document.createEvent("XMLHttpRequestProgressEvent");
    e.initProgressEvent(type, canBubble, cancelable, lengthComputable, loaded,
        total);
    return LevelDom.wrapProgressEvent(e);
  }

  int get position() => _ptr.position;

  int get totalSize() => _ptr.totalSize;
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
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class XMLHttpRequestUploadEventsImplementation extends EventsImplementation
    implements XMLHttpRequestUploadEvents {
  XMLHttpRequestUploadEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get('abort');
  EventListenerList get error() => _get('error');
  EventListenerList get load() => _get('load');
  EventListenerList get loadStart() => _get('loadstart');
  EventListenerList get progress() => _get('progress');
}

class XMLHttpRequestUploadWrappingImplementation extends EventTargetWrappingImplementation implements XMLHttpRequestUpload {
  XMLHttpRequestUploadWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  XMLHttpRequestUploadEvents get on() {
    if (_on === null) {
      _on = new XMLHttpRequestUploadEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class XMLHttpRequestEventsImplementation extends EventsImplementation
    implements XMLHttpRequestEvents {
  XMLHttpRequestEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get('abort');
  EventListenerList get error() => _get('error');
  EventListenerList get load() => _get('load');
  EventListenerList get loadStart() => _get('loadstart');
  EventListenerList get progress() => _get('progress');
  EventListenerList get readyStateChange() => _get('readystatechange');
}

class XMLHttpRequestWrappingImplementation extends EventTargetWrappingImplementation implements XMLHttpRequest {
  XMLHttpRequestWrappingImplementation._wrap(
      dom.XMLHttpRequest ptr) : super._wrap(ptr);

  /** @domName Window.createXMLHttpRequest */
  factory XMLHttpRequestWrappingImplementation() {
    return new XMLHttpRequestWrappingImplementation._wrap(
        new dom.XMLHttpRequest());
  }

  factory XMLHttpRequestWrappingImplementation.getTEMPNAME(String url,
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

  int get readyState() => _ptr.readyState;

  String get responseText() => _ptr.responseText;

  String get responseType() => _ptr.responseType;

  void set responseType(String value) { _ptr.responseType = value; }

  Document get responseXML() => LevelDom.wrapDocument(_ptr.responseXML);

  int get status() => _ptr.status;

  String get statusText() => _ptr.statusText;

  XMLHttpRequestUpload get upload() => LevelDom.wrapXMLHttpRequestUpload(_ptr.upload);

  bool get withCredentials() => _ptr.withCredentials;

  void set withCredentials(bool value) { _ptr.withCredentials = value; }

  void abort() {
    _ptr.abort();
    return;
  }

  String getAllResponseHeaders() {
    return _ptr.getAllResponseHeaders();
  }

  String getResponseHeader(String header) {
    return _ptr.getResponseHeader(header);
  }

  void open(String method, String url, bool async, [String user = null, String password = null]) {
    if (user === null) {
      if (password === null) {
        _ptr.open(method, url, async);
        return;
      }
    } else {
      if (password === null) {
        _ptr.open(method, url, async, user);
        return;
      } else {
        _ptr.open(method, url, async, user, password);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void overrideMimeType(String mime) {
    _ptr.overrideMimeType(mime);
  }

  void send([var data = null]) {
    if (data === null) {
      _ptr.send();
      return;
    } else {
      if (data is Document) {
        _ptr.send(LevelDom.unwrapMaybePrimitive(data));
        return;
      } else {
        if (data is String) {
          _ptr.send(LevelDom.unwrapMaybePrimitive(data));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setRequestHeader(String header, String value) {
    _ptr.setRequestHeader(header, value);
  }

  XMLHttpRequestEvents get on() {
    if (_on === null) {
      _on = new XMLHttpRequestEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
