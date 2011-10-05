// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CanvasRenderingContext2DWrappingImplementation extends _CanvasRenderingContextWrappingImplementation implements CanvasRenderingContext2D {
  _CanvasRenderingContext2DWrappingImplementation() : super() {}

  static create__CanvasRenderingContext2DWrappingImplementation() native {
    return new _CanvasRenderingContext2DWrappingImplementation();
  }

  String get font() { return _get__CanvasRenderingContext2D_font(this); }
  static String _get__CanvasRenderingContext2D_font(var _this) native;

  void set font(String value) { _set__CanvasRenderingContext2D_font(this, value); }
  static void _set__CanvasRenderingContext2D_font(var _this, String value) native;

  num get globalAlpha() { return _get__CanvasRenderingContext2D_globalAlpha(this); }
  static num _get__CanvasRenderingContext2D_globalAlpha(var _this) native;

  void set globalAlpha(num value) { _set__CanvasRenderingContext2D_globalAlpha(this, value); }
  static void _set__CanvasRenderingContext2D_globalAlpha(var _this, num value) native;

  String get globalCompositeOperation() { return _get__CanvasRenderingContext2D_globalCompositeOperation(this); }
  static String _get__CanvasRenderingContext2D_globalCompositeOperation(var _this) native;

  void set globalCompositeOperation(String value) { _set__CanvasRenderingContext2D_globalCompositeOperation(this, value); }
  static void _set__CanvasRenderingContext2D_globalCompositeOperation(var _this, String value) native;

  String get lineCap() { return _get__CanvasRenderingContext2D_lineCap(this); }
  static String _get__CanvasRenderingContext2D_lineCap(var _this) native;

  void set lineCap(String value) { _set__CanvasRenderingContext2D_lineCap(this, value); }
  static void _set__CanvasRenderingContext2D_lineCap(var _this, String value) native;

  String get lineJoin() { return _get__CanvasRenderingContext2D_lineJoin(this); }
  static String _get__CanvasRenderingContext2D_lineJoin(var _this) native;

  void set lineJoin(String value) { _set__CanvasRenderingContext2D_lineJoin(this, value); }
  static void _set__CanvasRenderingContext2D_lineJoin(var _this, String value) native;

  num get lineWidth() { return _get__CanvasRenderingContext2D_lineWidth(this); }
  static num _get__CanvasRenderingContext2D_lineWidth(var _this) native;

  void set lineWidth(num value) { _set__CanvasRenderingContext2D_lineWidth(this, value); }
  static void _set__CanvasRenderingContext2D_lineWidth(var _this, num value) native;

  num get miterLimit() { return _get__CanvasRenderingContext2D_miterLimit(this); }
  static num _get__CanvasRenderingContext2D_miterLimit(var _this) native;

  void set miterLimit(num value) { _set__CanvasRenderingContext2D_miterLimit(this, value); }
  static void _set__CanvasRenderingContext2D_miterLimit(var _this, num value) native;

  num get shadowBlur() { return _get__CanvasRenderingContext2D_shadowBlur(this); }
  static num _get__CanvasRenderingContext2D_shadowBlur(var _this) native;

  void set shadowBlur(num value) { _set__CanvasRenderingContext2D_shadowBlur(this, value); }
  static void _set__CanvasRenderingContext2D_shadowBlur(var _this, num value) native;

  String get shadowColor() { return _get__CanvasRenderingContext2D_shadowColor(this); }
  static String _get__CanvasRenderingContext2D_shadowColor(var _this) native;

  void set shadowColor(String value) { _set__CanvasRenderingContext2D_shadowColor(this, value); }
  static void _set__CanvasRenderingContext2D_shadowColor(var _this, String value) native;

  num get shadowOffsetX() { return _get__CanvasRenderingContext2D_shadowOffsetX(this); }
  static num _get__CanvasRenderingContext2D_shadowOffsetX(var _this) native;

  void set shadowOffsetX(num value) { _set__CanvasRenderingContext2D_shadowOffsetX(this, value); }
  static void _set__CanvasRenderingContext2D_shadowOffsetX(var _this, num value) native;

  num get shadowOffsetY() { return _get__CanvasRenderingContext2D_shadowOffsetY(this); }
  static num _get__CanvasRenderingContext2D_shadowOffsetY(var _this) native;

  void set shadowOffsetY(num value) { _set__CanvasRenderingContext2D_shadowOffsetY(this, value); }
  static void _set__CanvasRenderingContext2D_shadowOffsetY(var _this, num value) native;

  String get textAlign() { return _get__CanvasRenderingContext2D_textAlign(this); }
  static String _get__CanvasRenderingContext2D_textAlign(var _this) native;

  void set textAlign(String value) { _set__CanvasRenderingContext2D_textAlign(this, value); }
  static void _set__CanvasRenderingContext2D_textAlign(var _this, String value) native;

  String get textBaseline() { return _get__CanvasRenderingContext2D_textBaseline(this); }
  static String _get__CanvasRenderingContext2D_textBaseline(var _this) native;

  void set textBaseline(String value) { _set__CanvasRenderingContext2D_textBaseline(this, value); }
  static void _set__CanvasRenderingContext2D_textBaseline(var _this, String value) native;

  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise) {
    _arc(this, x, y, radius, startAngle, endAngle, anticlockwise);
    return;
  }
  static void _arc(receiver, x, y, radius, startAngle, endAngle, anticlockwise) native;

  void arcTo(num x1, num y1, num x2, num y2, num radius) {
    _arcTo(this, x1, y1, x2, y2, radius);
    return;
  }
  static void _arcTo(receiver, x1, y1, x2, y2, radius) native;

  void beginPath() {
    _beginPath(this);
    return;
  }
  static void _beginPath(receiver) native;

  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) {
    _bezierCurveTo(this, cp1x, cp1y, cp2x, cp2y, x, y);
    return;
  }
  static void _bezierCurveTo(receiver, cp1x, cp1y, cp2x, cp2y, x, y) native;

  void clearRect(num x, num y, num width, num height) {
    _clearRect(this, x, y, width, height);
    return;
  }
  static void _clearRect(receiver, x, y, width, height) native;

  void clearShadow() {
    _clearShadow(this);
    return;
  }
  static void _clearShadow(receiver) native;

  void clip() {
    _clip(this);
    return;
  }
  static void _clip(receiver) native;

  void closePath() {
    _closePath(this);
    return;
  }
  static void _closePath(receiver) native;

  ImageData createImageData(var imagedata_OR_sw, num sh = null) {
    if (imagedata_OR_sw is ImageData) {
      if (sh === null) {
        return _createImageData(this, imagedata_OR_sw);
      }
    } else {
      if (imagedata_OR_sw is num) {
        return _createImageData_2(this, imagedata_OR_sw, sh);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static ImageData _createImageData(receiver, imagedata_OR_sw) native;
  static ImageData _createImageData_2(receiver, imagedata_OR_sw, sh) native;

  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) {
    return _createLinearGradient(this, x0, y0, x1, y1);
  }
  static CanvasGradient _createLinearGradient(receiver, x0, y0, x1, y1) native;

  CanvasPattern createPattern(var canvas_OR_image, String repetitionType) {
    if (canvas_OR_image is HTMLCanvasElement) {
      return _createPattern(this, canvas_OR_image, repetitionType);
    } else {
      if (canvas_OR_image is HTMLImageElement) {
        return _createPattern_2(this, canvas_OR_image, repetitionType);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static CanvasPattern _createPattern(receiver, canvas_OR_image, repetitionType) native;
  static CanvasPattern _createPattern_2(receiver, canvas_OR_image, repetitionType) native;

  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) {
    return _createRadialGradient(this, x0, y0, r0, x1, y1, r1);
  }
  static CanvasGradient _createRadialGradient(receiver, x0, y0, r0, x1, y1, r1) native;

  void drawImage(var canvas_OR_image, num sx_OR_x, num sy_OR_y, num sw_OR_width = null, num height_OR_sh = null, num dx = null, num dy = null, num dw = null, num dh = null) {
    if (canvas_OR_image is HTMLImageElement) {
      if (sw_OR_width === null) {
        if (height_OR_sh === null) {
          if (dx === null) {
            if (dy === null) {
              if (dw === null) {
                if (dh === null) {
                  _drawImage(this, canvas_OR_image, sx_OR_x, sy_OR_y);
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
                _drawImage_2(this, canvas_OR_image, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
                return;
              }
            }
          }
        } else {
          _drawImage_3(this, canvas_OR_image, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
          return;
        }
      }
    } else {
      if (canvas_OR_image is HTMLCanvasElement) {
        if (sw_OR_width === null) {
          if (height_OR_sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    _drawImage_4(this, canvas_OR_image, sx_OR_x, sy_OR_y);
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
                  _drawImage_5(this, canvas_OR_image, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
                  return;
                }
              }
            }
          } else {
            _drawImage_6(this, canvas_OR_image, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _drawImage(receiver, canvas_OR_image, sx_OR_x, sy_OR_y) native;
  static void _drawImage_2(receiver, canvas_OR_image, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native;
  static void _drawImage_3(receiver, canvas_OR_image, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native;
  static void _drawImage_4(receiver, canvas_OR_image, sx_OR_x, sy_OR_y) native;
  static void _drawImage_5(receiver, canvas_OR_image, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native;
  static void _drawImage_6(receiver, canvas_OR_image, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native;

  void drawImageFromRect(HTMLImageElement image, num sx = null, num sy = null, num sw = null, num sh = null, num dx = null, num dy = null, num dw = null, num dh = null, String compositeOperation = null) {
    if (sx === null) {
      if (sy === null) {
        if (sw === null) {
          if (sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _drawImageFromRect(this, image);
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
                      _drawImageFromRect_2(this, image, sx);
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
                      _drawImageFromRect_3(this, image, sx, sy);
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
                      _drawImageFromRect_4(this, image, sx, sy, sw);
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
                      _drawImageFromRect_5(this, image, sx, sy, sw, sh);
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
                      _drawImageFromRect_6(this, image, sx, sy, sw, sh, dx);
                      return;
                    }
                  }
                }
              } else {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _drawImageFromRect_7(this, image, sx, sy, sw, sh, dx, dy);
                      return;
                    }
                  }
                } else {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _drawImageFromRect_8(this, image, sx, sy, sw, sh, dx, dy, dw);
                      return;
                    }
                  } else {
                    if (compositeOperation === null) {
                      _drawImageFromRect_9(this, image, sx, sy, sw, sh, dx, dy, dw, dh);
                      return;
                    } else {
                      _drawImageFromRect_10(this, image, sx, sy, sw, sh, dx, dy, dw, dh, compositeOperation);
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
  static void _drawImageFromRect(receiver, image) native;
  static void _drawImageFromRect_2(receiver, image, sx) native;
  static void _drawImageFromRect_3(receiver, image, sx, sy) native;
  static void _drawImageFromRect_4(receiver, image, sx, sy, sw) native;
  static void _drawImageFromRect_5(receiver, image, sx, sy, sw, sh) native;
  static void _drawImageFromRect_6(receiver, image, sx, sy, sw, sh, dx) native;
  static void _drawImageFromRect_7(receiver, image, sx, sy, sw, sh, dx, dy) native;
  static void _drawImageFromRect_8(receiver, image, sx, sy, sw, sh, dx, dy, dw) native;
  static void _drawImageFromRect_9(receiver, image, sx, sy, sw, sh, dx, dy, dw, dh) native;
  static void _drawImageFromRect_10(receiver, image, sx, sy, sw, sh, dx, dy, dw, dh, compositeOperation) native;

  void fill() {
    _fill(this);
    return;
  }
  static void _fill(receiver) native;

  void fillRect(num x, num y, num width, num height) {
    _fillRect(this, x, y, width, height);
    return;
  }
  static void _fillRect(receiver, x, y, width, height) native;

  void fillText(String text, num x, num y, num maxWidth = null) {
    if (maxWidth === null) {
      _fillText(this, text, x, y);
      return;
    } else {
      _fillText_2(this, text, x, y, maxWidth);
      return;
    }
  }
  static void _fillText(receiver, text, x, y) native;
  static void _fillText_2(receiver, text, x, y, maxWidth) native;

  ImageData getImageData(num sx, num sy, num sw, num sh) {
    return _getImageData(this, sx, sy, sw, sh);
  }
  static ImageData _getImageData(receiver, sx, sy, sw, sh) native;

  bool isPointInPath(num x, num y) {
    return _isPointInPath(this, x, y);
  }
  static bool _isPointInPath(receiver, x, y) native;

  void lineTo(num x, num y) {
    _lineTo(this, x, y);
    return;
  }
  static void _lineTo(receiver, x, y) native;

  TextMetrics measureText(String text) {
    return _measureText(this, text);
  }
  static TextMetrics _measureText(receiver, text) native;

  void moveTo(num x, num y) {
    _moveTo(this, x, y);
    return;
  }
  static void _moveTo(receiver, x, y) native;

  void putImageData(ImageData imagedata, num dx, num dy, num dirtyX = null, num dirtyY = null, num dirtyWidth = null, num dirtyHeight = null) {
    if (dirtyX === null) {
      if (dirtyY === null) {
        if (dirtyWidth === null) {
          if (dirtyHeight === null) {
            _putImageData(this, imagedata, dx, dy);
            return;
          }
        }
      }
    } else {
      _putImageData_2(this, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
      return;
    }
    throw "Incorrect number or type of arguments";
  }
  static void _putImageData(receiver, imagedata, dx, dy) native;
  static void _putImageData_2(receiver, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native;

  void quadraticCurveTo(num cpx, num cpy, num x, num y) {
    _quadraticCurveTo(this, cpx, cpy, x, y);
    return;
  }
  static void _quadraticCurveTo(receiver, cpx, cpy, x, y) native;

  void rect(num x, num y, num width, num height) {
    _rect(this, x, y, width, height);
    return;
  }
  static void _rect(receiver, x, y, width, height) native;

  void restore() {
    _restore(this);
    return;
  }
  static void _restore(receiver) native;

  void rotate(num angle) {
    _rotate(this, angle);
    return;
  }
  static void _rotate(receiver, angle) native;

  void save() {
    _save(this);
    return;
  }
  static void _save(receiver) native;

  void scale(num sx, num sy) {
    _scale(this, sx, sy);
    return;
  }
  static void _scale(receiver, sx, sy) native;

  void setAlpha(num alpha) {
    _setAlpha(this, alpha);
    return;
  }
  static void _setAlpha(receiver, alpha) native;

  void setCompositeOperation(String compositeOperation) {
    _setCompositeOperation(this, compositeOperation);
    return;
  }
  static void _setCompositeOperation(receiver, compositeOperation) native;

  void setFillColor(var c_OR_color_OR_grayLevel_OR_r, num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null) {
    if (c_OR_color_OR_grayLevel_OR_r is String) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _setFillColor(this, c_OR_color_OR_grayLevel_OR_r);
              return;
            }
          }
        }
      } else {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _setFillColor_2(this, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m);
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
                _setFillColor_3(this, c_OR_color_OR_grayLevel_OR_r);
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _setFillColor_4(this, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m);
                return;
              }
            }
          } else {
            if (a === null) {
              _setFillColor_5(this, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k);
              return;
            } else {
              _setFillColor_6(this, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setFillColor(receiver, c_OR_color_OR_grayLevel_OR_r) native;
  static void _setFillColor_2(receiver, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m) native;
  static void _setFillColor_3(receiver, c_OR_color_OR_grayLevel_OR_r) native;
  static void _setFillColor_4(receiver, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m) native;
  static void _setFillColor_5(receiver, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k) native;
  static void _setFillColor_6(receiver, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k, a) native;

  void setFillStyle(var color_OR_gradient_OR_pattern) {
    if (color_OR_gradient_OR_pattern is String) {
      _setFillStyle(this, color_OR_gradient_OR_pattern);
      return;
    } else {
      if (color_OR_gradient_OR_pattern is CanvasGradient) {
        _setFillStyle_2(this, color_OR_gradient_OR_pattern);
        return;
      } else {
        if (color_OR_gradient_OR_pattern is CanvasPattern) {
          _setFillStyle_3(this, color_OR_gradient_OR_pattern);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setFillStyle(receiver, color_OR_gradient_OR_pattern) native;
  static void _setFillStyle_2(receiver, color_OR_gradient_OR_pattern) native;
  static void _setFillStyle_3(receiver, color_OR_gradient_OR_pattern) native;

  void setLineCap(String cap) {
    _setLineCap(this, cap);
    return;
  }
  static void _setLineCap(receiver, cap) native;

  void setLineJoin(String join) {
    _setLineJoin(this, join);
    return;
  }
  static void _setLineJoin(receiver, join) native;

  void setLineWidth(num width) {
    _setLineWidth(this, width);
    return;
  }
  static void _setLineWidth(receiver, width) native;

  void setMiterLimit(num limit) {
    _setMiterLimit(this, limit);
    return;
  }
  static void _setMiterLimit(receiver, limit) native;

  void setShadow(num width, num height, num blur, var c_OR_color_OR_grayLevel_OR_r = null, num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null) {
    if (c_OR_color_OR_grayLevel_OR_r === null) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _setShadow(this, width, height, blur);
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
                _setShadow_2(this, width, height, blur, c_OR_color_OR_grayLevel_OR_r);
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _setShadow_3(this, width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m);
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
                  _setShadow_4(this, width, height, blur, c_OR_color_OR_grayLevel_OR_r);
                  return;
                }
              }
            }
          } else {
            if (b_OR_y === null) {
              if (a_OR_k === null) {
                if (a === null) {
                  _setShadow_5(this, width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m);
                  return;
                }
              }
            } else {
              if (a === null) {
                _setShadow_6(this, width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k);
                return;
              } else {
                _setShadow_7(this, width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
                return;
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setShadow(receiver, width, height, blur) native;
  static void _setShadow_2(receiver, width, height, blur, c_OR_color_OR_grayLevel_OR_r) native;
  static void _setShadow_3(receiver, width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m) native;
  static void _setShadow_4(receiver, width, height, blur, c_OR_color_OR_grayLevel_OR_r) native;
  static void _setShadow_5(receiver, width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m) native;
  static void _setShadow_6(receiver, width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k) native;
  static void _setShadow_7(receiver, width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k, a) native;

  void setStrokeColor(var c_OR_color_OR_grayLevel_OR_r, num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null) {
    if (c_OR_color_OR_grayLevel_OR_r is String) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _setStrokeColor(this, c_OR_color_OR_grayLevel_OR_r);
              return;
            }
          }
        }
      } else {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _setStrokeColor_2(this, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m);
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
                _setStrokeColor_3(this, c_OR_color_OR_grayLevel_OR_r);
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _setStrokeColor_4(this, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m);
                return;
              }
            }
          } else {
            if (a === null) {
              _setStrokeColor_5(this, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k);
              return;
            } else {
              _setStrokeColor_6(this, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setStrokeColor(receiver, c_OR_color_OR_grayLevel_OR_r) native;
  static void _setStrokeColor_2(receiver, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m) native;
  static void _setStrokeColor_3(receiver, c_OR_color_OR_grayLevel_OR_r) native;
  static void _setStrokeColor_4(receiver, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m) native;
  static void _setStrokeColor_5(receiver, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k) native;
  static void _setStrokeColor_6(receiver, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k, a) native;

  void setStrokeStyle(var color_OR_gradient_OR_pattern) {
    if (color_OR_gradient_OR_pattern is String) {
      _setStrokeStyle(this, color_OR_gradient_OR_pattern);
      return;
    } else {
      if (color_OR_gradient_OR_pattern is CanvasGradient) {
        _setStrokeStyle_2(this, color_OR_gradient_OR_pattern);
        return;
      } else {
        if (color_OR_gradient_OR_pattern is CanvasPattern) {
          _setStrokeStyle_3(this, color_OR_gradient_OR_pattern);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setStrokeStyle(receiver, color_OR_gradient_OR_pattern) native;
  static void _setStrokeStyle_2(receiver, color_OR_gradient_OR_pattern) native;
  static void _setStrokeStyle_3(receiver, color_OR_gradient_OR_pattern) native;

  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy) {
    _setTransform(this, m11, m12, m21, m22, dx, dy);
    return;
  }
  static void _setTransform(receiver, m11, m12, m21, m22, dx, dy) native;

  void stroke() {
    _stroke(this);
    return;
  }
  static void _stroke(receiver) native;

  void strokeRect(num x, num y, num width, num height, num lineWidth = null) {
    if (lineWidth === null) {
      _strokeRect(this, x, y, width, height);
      return;
    } else {
      _strokeRect_2(this, x, y, width, height, lineWidth);
      return;
    }
  }
  static void _strokeRect(receiver, x, y, width, height) native;
  static void _strokeRect_2(receiver, x, y, width, height, lineWidth) native;

  void strokeText(String text, num x, num y, num maxWidth = null) {
    if (maxWidth === null) {
      _strokeText(this, text, x, y);
      return;
    } else {
      _strokeText_2(this, text, x, y, maxWidth);
      return;
    }
  }
  static void _strokeText(receiver, text, x, y) native;
  static void _strokeText_2(receiver, text, x, y, maxWidth) native;

  void transform(num m11, num m12, num m21, num m22, num dx, num dy) {
    _transform(this, m11, m12, m21, m22, dx, dy);
    return;
  }
  static void _transform(receiver, m11, m12, m21, m22, dx, dy) native;

  void translate(num tx, num ty) {
    _translate(this, tx, ty);
    return;
  }
  static void _translate(receiver, tx, ty) native;

  String get typeName() { return "CanvasRenderingContext2D"; }
}
