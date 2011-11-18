
class CanvasRenderingContext2D extends CanvasRenderingContext native "CanvasRenderingContext2D" {

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
