
class CanvasRenderingContext2DJs extends CanvasRenderingContextJs implements CanvasRenderingContext2D native "*CanvasRenderingContext2D" {

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

  ImageDataJs createImageData(var imagedata_OR_sw, [num sh = null]) native;

  CanvasGradientJs createLinearGradient(num x0, num y0, num x1, num y1) native;

  CanvasPatternJs createPattern(var canvas_OR_image, String repetitionType) native;

  CanvasGradientJs createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) native;

  void drawImage(var canvas_OR_image_OR_video, num sx_OR_x, num sy_OR_y, [num sw_OR_width = null, num height_OR_sh = null, num dx = null, num dy = null, num dw = null, num dh = null]) native;

  void drawImageFromRect(HTMLImageElementJs image, [num sx = null, num sy = null, num sw = null, num sh = null, num dx = null, num dy = null, num dw = null, num dh = null, String compositeOperation = null]) native;

  void fill() native;

  void fillRect(num x, num y, num width, num height) native;

  void fillText(String text, num x, num y, [num maxWidth = null]) native;

  ImageDataJs getImageData(num sx, num sy, num sw, num sh) native;

  bool isPointInPath(num x, num y) native;

  void lineTo(num x, num y) native;

  TextMetricsJs measureText(String text) native;

  void moveTo(num x, num y) native;

  void putImageData(ImageDataJs imagedata, num dx, num dy, [num dirtyX = null, num dirtyY = null, num dirtyWidth = null, num dirtyHeight = null]) native;

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
