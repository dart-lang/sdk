// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library android_extension;

class CanvasElement {
  int _height;
  int _width;

  get height => _height;
  get width => _width;

  CanvasRenderingContext2D _context2d;
  WebGLRenderingContext _context3d;

  // For use with drawImage, we want to support a src property
  // like ImageElement, which maps to the context handle in native
  // code.
  get src => "context2d://${_context2d.handle}";

  CanvasElement({int width, int height}) {
    _width = (width == null) ? getDeviceScreenWidth() : width;
    _height = (height == null) ? getDeviceScreenHeight() : height;
  }

  CanvasRenderingContext getContext(String contextId) {
    if (contextId == "2d") {
      if (_context2d == null) {
        _context2d = new CanvasRenderingContext2D(this, _width, _height);
      }
      return _context2d;
    } else if (contextId == "webgl" || 
               contextId == "experimental-webgl") {
      if (_context3d == null) {
        _context3d = new WebGLRenderingContext(this);
      }
      return _context3d;
    }
  }
}

class CanvasRenderingContext {
  final CanvasElement canvas;

  CanvasRenderingContext(this.canvas);
}

// The simplest way to call native code: top-level functions.
int systemRand() native "SystemRand";
void systemSrand(int seed) native "SystemSrand";
void log(String what) native "Log";

int getDeviceScreenWidth() native "GetDeviceScreenWidth";
int getDeviceScreenHeight() native "GetDeviceScreenHeight";

// EGL functions.
void glSwapBuffers() native "SwapBuffers";

// GL functions.
void glAttachShader(int program, int shader) native "GLAttachShader";
void glBindBuffer(int target, int buffer) native "GLBindBuffer";
void glBufferData(int target, List data, int usage) native "GLBufferData";
void glClearColor(num r, num g, num b, num alpha) native "GLClearColor";
void glClearDepth(num depth) native "GLClearDepth";
void glClear(int mask) native "GLClear";
void glCompileShader(int shader) native "GLCompileShader";
int glCreateBuffer() native "GLCreateBuffer";
int glCreateProgram() native "GLCreateProgram";
int glCreateShader(int shaderType) native "GLCreateShader";
void glDrawArrays(int mode, int first, int count) native "GLDrawArrays";
void glEnableVertexAttribArray(int index) native "GLEnableVertexAttribArray";
int glGetAttribLocation(int program, String name) native "GLGetAttribLocation";
int glGetError() native "GLGetError";
int glGetProgramParameter(int program, int param)
    native "GLGetProgramParameter";
int glGetShaderParameter(int shader, int param) native "GLGetShaderParameter";
int glGetUniformLocation(int program, String name)
    native "GLGetUniformLocation";
void glLinkProgram(int program) native "GLLinkProgram";
void glShaderSource(int shader, String source) native "GLShaderSource";
void glUniform1f(int location, double v0) native "GLUniform1f";
void glUniform2f(int location, double v0, double v1) native "GLUniform2f";
void glUniform3f(int location, double v0, double v1, double v2)
    native "GLUniform3f";
void glUniform4f(int location, double v0, double v1, double v2, double v3)
    native "GLUniform4f";
void glUniform1i(int location, int v0) native "GLUniform1i";
void glUniform2i(int location, int v0, int v1) native "GLUniform2i";
void glUniform3i(int location, int v0, int v1, int v2) native "GLUniform3i";
void glUniform4i(int location, int v0, int v1, int v2, int v3)
    native "GLUniform4i";
void glUniform1fv(int location, List values) native "GLUniform1fv";
void glUniform2fv(int location, List values) native "GLUniform2fv";
void glUniform3fv(int location, List values) native "GLUniform3fv";
void glUniform4fv(int location, List values) native "GLUniform4fv";
void glUniform1iv(int location, List values) native "GLUniform1iv";
void glUniform2iv(int location, List values) native "GLUniform2iv";
void glUniform3iv(int location, List values) native "GLUniform3iv";
void glUniform4iv(int location, List values) native "GLUniform4iv";
void glUseProgram(int program) native "GLUseProgram";
void glVertexAttribPointer(int index, int size, int type, bool normalized,
    int stride, int pointer) native "GLVertexAttribPointer";
void glViewport(int x, int y, int width, int height) native "GLViewport";

int glArrayBuffer() native "GLArrayBuffer";
int glColorBufferBit() native "GLColorBufferBit";
int glCompileStatus() native "GLCompileStatus";
int glDeleteStatus() native "GLDeleteStatus";
int glDepthBufferBit() native "GLDepthBufferBit";
int glFloat() native "GLFloat";
int glFragmentShader() native "GLFragmentShader";
int glLinkStatus() native "GLLinkStatus";
int glStaticDraw() native "GLStaticDraw";
int glTriangleStrip() native "GLTriangleStrip";
int glTriangles() native "GLTriangles";
int glTrue() native "GLTrue";
int glValidateStatus() native "GLValidateStatus";
int glVertexShader() native "GLVertexShader";

String glGetShaderInfoLog(int shader) native "GLGetShaderInfoLog";
String glGetProgramInfoLog(int program) native "GLGetProgramInfoLog";

class WebGLRenderingContext extends CanvasRenderingContext {
  WebGLRenderingContext(canvas) : super(canvas);

  static get ARRAY_BUFFER => glArrayBuffer();
  static get COLOR_BUFFER_BIT => glColorBufferBit();
  static get COMPILE_STATUS => glCompileStatus();
  static get DELETE_STATUS => glDeleteStatus();
  static get DEPTH_BUFFER_BIT => glDepthBufferBit();
  static get FLOAT => glFloat();
  static get FRAGMENT_SHADER => glFragmentShader();
  static get LINK_STATUS => glLinkStatus();
  static get STATIC_DRAW => glStaticDraw();
  static get TRUE => glTrue();
  static get TRIANGLE_STRIP => glTriangleStrip();
  static get TRIANGLES => glTriangles();
  static get VALIDATE_STATUS => glValidateStatus();
  static get VERTEX_SHADER => glVertexShader();

  attachShader(program, shader) => glAttachShader(program, shader);
  bindBuffer(target, buffer) => glBindBuffer(target, buffer);
  bufferData(target, data, usage) => glBufferData(target, data, usage);
  clearColor(r, g, b, alpha) => glClearColor(r, g, b, alpha);
  clearDepth(depth) => glClearDepth(depth);
  clear(mask) => glClear(mask);
  compileShader(shader) => glCompileShader(shader);
  createBuffer() => glCreateBuffer();
  createProgram() => glCreateProgram();
  createShader(shaderType) => glCreateShader(shaderType);
  drawArrays(mode, first, count) => glDrawArrays(mode, first, count);
  enableVertexAttribArray(index) => glEnableVertexAttribArray(index);
  getAttribLocation(program, name) => glGetAttribLocation(program, name);
  getError() => glGetError();
  getProgramParameter(program, name) {
    var rtn = glGetProgramParameter(program, name);
    if (name == DELETE_STATUS ||
        name == LINK_STATUS ||
        name == VALIDATE_STATUS) {
      return (rtn == 0) ? false : true;
    }
    return rtn;
  }
  getShaderParameter(shader, name) {
    var rtn = glGetShaderParameter(shader, name);
    if (name == DELETE_STATUS || name == COMPILE_STATUS) {
      return (rtn == 0) ? false : true;
    }
    return rtn;
  }
  getUniformLocation(program, name) => glGetUniformLocation(program, name);
  linkProgram(program) => glLinkProgram(program);
  shaderSource(shader, source) => glShaderSource(shader, source);
  uniform1f(location, v0) => glUniform1f(location, v0);
  uniform2f(location, v0, v1) => glUniform2f(location, v0, v1);
  uniform3f(location, v0, v1, v2) => glUniform3f(location, v0, v1, v2);
  uniform4f(location, v0, v1, v2, v3) => glUniform4f(location, v0, v1, v2, v3);
  uniform1i(location, v0) => glUniform1i(location, v0);
  uniform2i(location, v0, v1) => glUniform2i(location, v0, v1);
  uniform3i(location, v0, v1, v2) => glUniform3i(location, v0, v1, v2);
  uniform4i(location, v0, v1, v2, v3) => glUniform4i(location, v0, v1, v2, v3);
  uniform1fv(location, values) => glUniform1fv(location, values);
  uniform2fv(location, values) => glUniform2fv(location, values);
  uniform3fv(location, values) => glUniform3fv(location, values);
  uniform4fv(location, values) => glUniform4fv(location, values);
  uniform1iv(location, values) => glUniform1iv(location, values);
  uniform2iv(location, values) => glUniform2iv(location, values);
  uniform3iv(location, values) => glUniform3iv(location, values);
  uniform4iv(location, values) => glUniform4iv(location, values);
  useProgram(program) => glUseProgram(program);
  vertexAttribPointer(index, size, type, normalized, stride, pointer) =>
    glVertexAttribPointer(index, size, type, normalized, stride, pointer);
  viewport(x, y, width, height) => glViewport(x, y, width, height);
  getShaderInfoLog(shader) => glGetShaderInfoLog(shader);
  getProgramInfoLog(program) => glGetProgramInfoLog(program);

  // TODO(vsm): Kill.
  noSuchMethod(invocation) {
      throw new Exception('Unimplemented ${invocation.memberName}');
  }
}

//------------------------------------------------------------------
// Simple audio support.

void playBackground(String path) native "PlayBackground";
void stopBackground() native "StopBackground";

//-------------------------------------------------------------------
// Set up print().

get _printClosure => (s) {
  try {
    log(s);
  } catch (_) {
    throw(s);
  }
};

//------------------------------------------------------------------
// Temp hack for compat with WebGL.

class Float32Array extends List<double> {
  Float32Array.fromList(List a) {
    addAll(a);
  }
}

//------------------------------------------------------------------
// 2D canvas support

int C2DSetWidth(int handle, int width)
    native "C2DSetWidth";
int C2DSetHeight(int handle, int height)
    native "C2DSetHeight";

double C2DSetGlobalAlpha(int handle, double globalAlpha)
    native "C2DSetGlobalAlpha";
void C2DSetFillStyle(int handle, fs)
    native "C2DSetFillStyle";
String C2DSetFont(int handle, String font)
    native "C2DSetFont";
void C2DSetGlobalCompositeOperation(int handle, String op)
    native "C2DSetGlobalCompositeOperation";
C2DSetLineCap(int handle, String lc)
    native "C2DSetLineCap";
C2DSetLineJoin(int handle, String lj)
    native "C2DSetLineJoin";
C2DSetLineWidth(int handle, double w)
    native "C2DSetLineWidth";
C2DSetMiterLimit(int handle, double limit)
    native "C2DSetMiterLimit";
C2DSetShadowBlur(int handle, double blur)
    native "C2DSetShadowBlur";
C2DSetShadowColor(int handle, String color)
    native "C2DSetShadowColor";
C2DSetShadowOffsetX(int handle, double offset)
    native "C2DSetShadowOffsetX";
C2DSetShadowOffsetY(int handle, double offset)
    native "C2DSetShadowOffsetY";
void C2DSetStrokeStyle(int handle, ss)
    native "C2DSetStrokeStyle";
String C2DSetTextAlign(int handle, String align)
    native "C2DSetTextAlign";
String C2DSetTextBaseline(int handle, String baseline)
    native "C2DSetTextBaseline";
C2DGetBackingStorePixelRatio(int handle)
    native "C2DGetBackingStorePixelRatio";
void C2DSetImageSmoothingEnabled(int handle, bool ise)
    native "C2DSetImageSmoothingEnabled";    
void C2DSetLineDash(int handle, List v)
    native "C2DSetLineDash";
C2DSetLineDashOffset(int handle, int v)
    native "C2DSetLineDashOffset";
void C2DArc(int handle, double x, double y, double radius,
    double startAngle, double endAngle, [bool anticlockwise = false])
    native "C2DArc";
void C2DArcTo(int handle, double x1, double y1,
              double x2, double y2, double radius)
    native "C2DArcTo"; 
void C2DArcTo2(int handle, double x1, double y1,
               double x2, double y2, double radiusX,
    double radiusY, double rotation)
    native "C2DArcTo2"; 
void C2DBeginPath(int handle)
    native "C2DBeginPath";
void C2DBezierCurveTo(int handle, double cp1x, double cp1y,
                      double cp2x, double cp2y, double x, double y)
    native "C2DBezierCurveTo";
void C2DClearRect(int handle, double x, double y, double w, double h)
    native "C2DClearRect";
void C2DClip(int handle)
    native "C2DClip";
void C2DClosePath(int handle)
    native "C2DClosePath";
ImageData C2DCreateImageDataFromDimensions(int handle, num w, num h)
    native "C2DCreateImageDataFromDimensions";
void C2DDrawImage(int handle, String src_url,
                  int sx, int sy,
                  bool has_src_dimensions, int sw, int sh,
                  int dx, int dy,
                  bool has_dst_dimensions, int dw, int dh)
    native "C2DDrawImage";
void C2DFill(int handle)
    native "C2DFill";
void C2DFillRect(int handle, double x, double y, double w, double h)
    native "C2DFillRect";
void C2DFillText(int handle, String text, double x, double y, double maxWidth)
    native "C2DFillText";
ImageData C2DGetImageData(num sx, num sy, num sw, num sh)
    native "C2DGetImageData";    
void C2DLineTo(int handle, double x, double y)
    native "C2DLineTo";
double C2DMeasureText(int handle, String text)
    native "C2DMeasureText";
void C2DMoveTo(int handle, double x, double y)
    native "C2DMoveTo";
void C2DPutImageData(int handle, ImageData imagedata, double dx, double dy)
    native "C2DPutImageData";    
void C2DQuadraticCurveTo(int handle, double cpx, double cpy, double x, double y)
    native "C2DQuadraticCurveTo";
void C2DRect(int handle, double x, double y, double w, double h)
    native "C2DRect";
void C2DRestore(int handle)
    native "C2DRestore";
void C2DRotate(int handle, double a)
    native "C2DRotate";
void C2DSave(int handle)
    native "C2DSave";
void C2DScale(int handle, double sx, double sy)
    native "C2DScale";
void C2DSetTransform(int handle, double m11, double m12,
                     double m21, double m22, double dx, double dy)
    native "C2DSetTransform";
void C2DStroke(int handle)
    native "C2DStroke";
void C2DStrokeRect(int handle, double x, double y, double w, double h)
    native "C2DStrokeRect";    
void C2DStrokeText(int handle, String text, double x, double y, double maxWidth)
    native "C2DStrokeText";
void C2DTransform(int handle, double m11, double m12,
                  double m21, double m22, double dx, double dy)
    native "C2DTransform";
void C2DTranslate(int handle, double x, double y)
    native "C2DTranslate";

void C2DCreateNativeContext(int handle, int width, int height)
    native "C2DCreateNativeContext";

class ElementEvents {
  final List load;
  ElementEvents()
    : load =new List() {
  }
}

class ImageElement {
  ElementEvents on;
  String _src;
  int _width;
  int _height;

  get src => _src;
  set src(String v) {
    _src = v;
    for (var e in on.load) {
      e(this);
    }
  }

  get width => _width;
  set width(int widthp) => _width = widthp;

  get height => _height;
  set height(int heightp) => _height = heightp;

  ImageElement({String srcp, int widthp, int heightp})
    : on = new ElementEvents(),
      _src = srcp,
      _width = widthp,
      _height = heightp {
  }
}

class ImageData {
  final Uint8ClampedArray data;
  final int height;
  final int width;
  ImageData(this.height, this.width, this.data);
}

class TextMetrics {
  final num width;
  TextMetrics(this.width);
}

void shutdown() {
  CanvasRenderingContext2D.next_handle = 0;
}

class CanvasRenderingContext2D extends CanvasRenderingContext {
  // TODO(gram): We need to support multiple contexts, for cached content
  // prerendered to an offscreen buffer. For this we will use handles, with
  // handle 0 being the physical display.
  static int next_handle = 0;
  int _handle = 0;
  get handle => _handle;

  int _width, _height;
  set width(int w) { _width = C2DSetWidth(_handle, w); }
  get width => _width;
  set height(int h) { _height = C2DSetHeight(_handle, h); }
  get height => _height;

  CanvasRenderingContext2D(canvas, width, height) : super(canvas) {
    _width = width;
    _height = height;
    C2DCreateNativeContext(_handle = next_handle++, width, height);
  }

  double _alpha = 1.0;
  set globalAlpha(num a) {
    _alpha = C2DSetGlobalAlpha(_handle, a.toDouble());
  }
  get globalAlpha => _alpha;

  // TODO(gram): make sure we support compound assignments like:
  // fillStyle = strokeStyle = "red"
  var _fillStyle = "#000";
  set fillStyle(fs) {
    C2DSetFillStyle(_handle, _fillStyle = fs);
  }
  get fillStyle => _fillStyle;

  String _font = "10px sans-serif";
  set font(String f) { _font = C2DSetFont(_handle, f); }
  get font => _font;

  String _globalCompositeOperation = "source-over";
  set globalCompositeOperation(String o) =>
      C2DSetGlobalCompositeOperation(_handle, _globalCompositeOperation = o);
  get globalCompositeOperation => _globalCompositeOperation;

  String _lineCap = "butt"; // "butt", "round", "square"
  get lineCap => _lineCap;
  set lineCap(String lc) => C2DSetLineCap(_handle, _lineCap = lc);

  int _lineDashOffset = 0;
  get lineDashOffset => _lineDashOffset;
  set lineDashOffset(num v) {
    _lineDashOffset = v.toInt();
    C2DSetLineDashOffset(_handle, _lineDashOffset);
  }

  String _lineJoin = "miter"; // "round", "bevel", "miter"
  get lineJoin => _lineJoin;
  set lineJoin(String lj) =>  C2DSetLineJoin(_handle, _lineJoin = lj);

  num _lineWidth = 1.0;
  get lineWidth => _lineWidth;
  set lineWidth(num w) {
    C2DSetLineWidth(_handle, w.toDouble());
    _lineWidth = w;
  }

  num _miterLimit = 10.0; // (default 10)
  get miterLimit => _miterLimit;
  set miterLimit(num limit) {
    C2DSetMiterLimit(_handle, limit.toDouble());
    _miterLimit = limit;
  }

  num _shadowBlur;
  get shadowBlur =>  _shadowBlur;
  set shadowBlur(num blur) {
    _shadowBlur = blur;
    C2DSetShadowBlur(_handle, blur.toDouble());
  }

  String _shadowColor;
  get shadowColor => _shadowColor;
  set shadowColor(String color) =>
      C2DSetShadowColor(_handle, _shadowColor = color);
  
  num _shadowOffsetX;
  get shadowOffsetX => _shadowOffsetX;
  set shadowOffsetX(num offset) {
    _shadowOffsetX = offset;
    C2DSetShadowOffsetX(_handle, offset.toDouble());
  }

  num _shadowOffsetY;
  get shadowOffsetY => _shadowOffsetY;
  set shadowOffsetY(num offset) {
    _shadowOffsetY = offset;
    C2DSetShadowOffsetY(_handle, offset.toDouble());
  }

  var _strokeStyle = "#000";
  get strokeStyle => _strokeStyle;
  set strokeStyle(ss) {
    C2DSetStrokeStyle(_handle, _strokeStyle = ss);
  }

  String _textAlign = "start";
  get textAlign => _textAlign;
  set textAlign(String a) { _textAlign = C2DSetTextAlign(_handle, a); }

  String _textBaseline = "alphabetic";
  get textBaseline => _textBaseline;
  set textBaseline(String b) { _textBaseline = C2DSetTextBaseline(_handle, b); }

  get webkitBackingStorePixelRatio => C2DGetBackingStorePixelRatio(_handle);

  bool _webkitImageSmoothingEnabled;
  get webkitImageSmoothingEnabled => _webkitImageSmoothingEnabled;
  set webkitImageSmoothingEnabled(bool v) =>
     C2DSetImageSmoothingEnabled(_webkitImageSmoothingEnabled = v);

  get webkitLineDash => lineDash;
  set webkitLineDash(List v) => lineDash = v;

  get webkitLineDashOffset => lineDashOffset;
  set webkitLineDashOffset(num v) => lineDashOffset = v;

  // Methods

  void arc(num x, num y, num radius, num a1, num a2, bool anticlockwise) {
    if (radius < 0) {
      // throw IndexSizeError
    } else {
      C2DArc(_handle, x.toDouble(), y.toDouble(), radius.toDouble(), a1.toDouble(), a2.toDouble(), anticlockwise);
    }
  }

  // Note - looking at the Dart docs it seems Dart doesn't support
  // the second form in the browser.
  void arcTo(num x1, num y1, num x2, num y2,
    num radiusX, [num radiusY, num rotation]) {
    if (radiusY == null) {
      C2DArcTo(_handle, x1.toDouble(), y1.toDouble(),
                        x2.toDouble(), y2.toDouble(), radiusX.toDouble());
    } else {
      C2DArcTo2(_handle, x1.toDouble(), y1.toDouble(),
                         x2.toDouble(), y2.toDouble(),
                         radiusX.toDouble(), radiusY.toDouble(),
                         rotation.toDouble());
    }
  }

  void beginPath() => C2DBeginPath(_handle);

  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y,
    num x, num y) =>
    C2DBezierCurveTo(_handle, cp1x.toDouble(), cp1y.toDouble(),
                              cp2x.toDouble(), cp2y.toDouble(),
                              x.toDouble(), y.toDouble());

  void clearRect(num x, num y, num w, num h) =>
    C2DClearRect(_handle, x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());

  void clip() => C2DClip(_handle);

  void closePath() => C2DClosePath(_handle);

  ImageData createImageData(var imagedata_OR_sw, [num sh = null]) {
    if (sh == null) {
      throw new Exception('Unimplemented createImageData(imagedata)');
    } else {
      return C2DCreateImageDataFromDimensions(_handle, imagedata_OR_sw, sh);
    }
  }

  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) {
    throw new Exception('Unimplemented createLinearGradient');
  }

  CanvasPattern createPattern(canvas_OR_image, String repetitionType) {
    throw new Exception('Unimplemented createPattern');
  }

  CanvasGradient createRadialGradient(num x0, num y0, num x1, num y1, num r1) {
    throw new Exception('Unimplemented createRadialGradient');
  }

  void drawImage(element, num x1, num y1,
                [num w1, num h1, num x2, num y2, num w2, num h2]) {
    var w = (element.width == null) ? 0 : element.width;
    var h = (element.height == null) ?  0 : element.height;
    if (!?w1) { // drawImage(element, dx, dy)
      C2DDrawImage(_handle, element.src, 0, 0, false, w, h,
                   x1.toInt(), y1.toInt(), false, 0, 0);
    } else if (!?x2) {  // drawImage(element, dx, dy, dw, dh)
      C2DDrawImage(_handle, element.src, 0, 0, false, w, h,
                   x1.toInt(), y1.toInt(), true, w1.toInt(), h1.toInt());
    } else {  // drawImage(image, sx, sy, sw, sh, dx, dy, dw, dh)
      C2DDrawImage(_handle, element.src, 
                   x1.toInt(), y1.toInt(), true, w1.toInt(), h1.toInt(),
                   x2.toInt(), y2.toInt(), true, w2.toInt(), h2.toInt());
    }
  }

  void fill() => C2DFill(_handle);

  void fillRect(num x, num y, num w, num h) =>
    C2DFillRect(_handle, x.toDouble(), y.toDouble(),
                         w.toDouble(), h.toDouble());

  void fillText(String text, num x, num y, [num maxWidth = -1]) =>
      C2DFillText(_handle, text, x.toDouble(), y.toDouble(),
                                 maxWidth.toDouble());

  ImageData getImageData(num sx, num sy, num sw, num sh) =>
    C2DGetImageData(sx, sy, sw, sh);

  List<double> _lineDash = null;
  List<num> getLineDash() {
    if (_lineDash == null) return [];
    return _lineDash;  // TODO(gram): should we return a copy?
  }

  bool isPointInPath(num x, num y) {
    throw new Exception('Unimplemented isPointInPath');
  }

  void lineTo(num x, num y) {
    C2DLineTo(_handle, x.toDouble(), y.toDouble());
  }

  TextMetrics measureText(String text) {
    double w = C2DMeasureText(_handle, text);
    return new TextMetrics(w);
  }

  void moveTo(num x, num y) =>
    C2DMoveTo(_handle, x.toDouble(), y.toDouble());

  void putImageData(ImageData imagedata, num dx, num dy,
                   [num dirtyX, num dirtyY, num dirtyWidth, num dirtyHeight]) {
    if (dirtyX != null || dirtyY != null) {
      throw new Exception('Unimplemented putImageData');
    } else {
      C2DPutImageData(_handle, imagedata, dx, dy);
    }
  }

  void quadraticCurveTo(num cpx, num cpy, num x, num y) =>
    C2DQuadraticCurveTo(_handle, cpx.toDouble(), cpy.toDouble(),
                        x.toDouble(), y.toDouble());

  void rect(num x, num y, num w, num h) =>
    C2DRect(_handle, x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());

  void restore() => C2DRestore(_handle);

  void rotate(num angle) => C2DRotate(_handle, angle.toDouble());

  void save() => C2DSave(_handle);

  void scale(num x, num y) => C2DScale(_handle, x.toDouble(), y.toDouble());

  void setFillColorHsl(int h, num s, num l, [num a = 1]) {
    throw new Exception('Unimplemented setFillColorHsl');
  }

  void setFillColorRgb(int r, int g, int b, [num a = 1]) {
    throw new Exception('Unimplemented setFillColorRgb');
  }

  void setLineDash(List<num> dash) {
    var valid = true;
    var new_dash;
    if (dash.length % 2 == 1) {
      new_dash = new List<double>(2 * dash.length);
      for (int i = 0; i < dash.length; i++) {
        double v = dash[i].toDouble();
        if (v < 0) {
          valid = false;
          break;
        }
        new_dash[i] = new_dash[i + dash.length] = v;
      }
    } else {
      new_dash = new List<double>(dash.length);
      for (int i = 0; i < dash.length; i++) {
        double v = dash[i].toDouble();
        if (v < 0) {
          valid = false;
          break;
        }
        new_dash[i] = v;
      }
    }
    if (valid) {
      C2DSetLineDash(_handle, _lineDash = new_dash);
    }
  }

  void setStrokeColorHsl(int h, num s, num l, [num a = 1]) {
    throw new Exception('Unimplemented setStrokeColorHsl');
  }

  void setStrokeColorRgb(int r, int g, int b, [num a = 1]) {
    throw new Exception('Unimplemented setStrokeColorRgb');
  }

  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy) =>
          C2DSetTransform(_handle, m11.toDouble(), m12.toDouble(),
                                   m21.toDouble(), m22.toDouble(),
                                   dx.toDouble(), dy.toDouble());

  void stroke() => C2DStroke(_handle);

  void strokeRect(num x, num y, num w, num h, [num lineWidth]) =>
    C2DStrokeRect(_handle, x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());

  void strokeText(String text, num x, num y, [num maxWidth = -1]) =>
      C2DStrokeText(_handle, text, x.toDouble(), y.toDouble(),
                                 maxWidth.toDouble());

  void transform(num m11, num m12, num m21, num m22, num dx, num dy) =>
          C2DTransform(_handle, m11.toDouble(), m12.toDouble(),
                       m21.toDouble(), m22.toDouble(),
                       dx.toDouble(), dy.toDouble());

  void translate(num x, num y) =>
      C2DTranslate(_handle, x.toDouble(), y.toDouble());

  ImageData webkitGetImageDataHD(num sx, num sy, num sw, num sh) {
    throw new Exception('Unimplemented webkitGetImageDataHD');
  }

  void webkitPutImageDataHD(ImageData imagedata, num dx, num dy,
                           [num dirtyX, num dirtyY,
                            num dirtyWidth, num dirtyHeight]) {
    throw new Exception('Unimplemented webkitGetImageDataHD');
  }

  // TODO(vsm): Kill.
  noSuchMethod(invocation) {
      throw new Exception('Unimplemented/unknown ${invocation.memberName}');
  }
}

