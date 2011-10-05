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

  ImageData createImageData(var imagedata_OR_sw, num sh = null);

  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1);

  CanvasPattern createPattern(var canvas_OR_image, String repetitionType);

  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1);

  void drawImage(var canvas_OR_image, num sx_OR_x, num sy_OR_y, num sw_OR_width = null, num height_OR_sh = null, num dx = null, num dy = null, num dw = null, num dh = null);

  void drawImageFromRect(HTMLImageElement image, num sx = null, num sy = null, num sw = null, num sh = null, num dx = null, num dy = null, num dw = null, num dh = null, String compositeOperation = null);

  void fill();

  void fillRect(num x, num y, num width, num height);

  void fillText(String text, num x, num y, num maxWidth = null);

  ImageData getImageData(num sx, num sy, num sw, num sh);

  bool isPointInPath(num x, num y);

  void lineTo(num x, num y);

  TextMetrics measureText(String text);

  void moveTo(num x, num y);

  void putImageData(ImageData imagedata, num dx, num dy, num dirtyX = null, num dirtyY = null, num dirtyWidth = null, num dirtyHeight = null);

  void quadraticCurveTo(num cpx, num cpy, num x, num y);

  void rect(num x, num y, num width, num height);

  void restore();

  void rotate(num angle);

  void save();

  void scale(num sx, num sy);

  void setAlpha(num alpha);

  void setCompositeOperation(String compositeOperation);

  void setFillColor(var c_OR_color_OR_grayLevel_OR_r, num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null);

  void setFillStyle(var color_OR_gradient_OR_pattern);

  void setLineCap(String cap);

  void setLineJoin(String join);

  void setLineWidth(num width);

  void setMiterLimit(num limit);

  void setShadow(num width, num height, num blur, var c_OR_color_OR_grayLevel_OR_r = null, num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null);

  void setStrokeColor(var c_OR_color_OR_grayLevel_OR_r, num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null);

  void setStrokeStyle(var color_OR_gradient_OR_pattern);

  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy);

  void stroke();

  void strokeRect(num x, num y, num width, num height, num lineWidth = null);

  void strokeText(String text, num x, num y, num maxWidth = null);

  void transform(num m11, num m12, num m21, num m22, num dx, num dy);

  void translate(num tx, num ty);
}
