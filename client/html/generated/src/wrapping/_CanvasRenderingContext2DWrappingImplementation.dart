// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasRenderingContext2DWrappingImplementation extends CanvasRenderingContextWrappingImplementation implements CanvasRenderingContext2D {
  CanvasRenderingContext2DWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Object get fillStyle() { return LevelDom.wrapObject(_ptr.fillStyle); }

  void set fillStyle(Object value) { _ptr.fillStyle = LevelDom.unwrapMaybePrimitive(value); }

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

  Object get strokeStyle() { return LevelDom.wrapObject(_ptr.strokeStyle); }

  void set strokeStyle(Object value) { _ptr.strokeStyle = LevelDom.unwrapMaybePrimitive(value); }

  String get textAlign() { return _ptr.textAlign; }

  void set textAlign(String value) { _ptr.textAlign = value; }

  String get textBaseline() { return _ptr.textBaseline; }

  void set textBaseline(String value) { _ptr.textBaseline = value; }

  List get webkitLineDash() { return _ptr.webkitLineDash; }

  void set webkitLineDash(List value) { _ptr.webkitLineDash = value; }

  num get webkitLineDashOffset() { return _ptr.webkitLineDashOffset; }

  void set webkitLineDashOffset(num value) { _ptr.webkitLineDashOffset = value; }

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
        return LevelDom.wrapImageData(_ptr.createImageData(LevelDom.unwrapMaybePrimitive(imagedata_OR_sw)));
      }
    } else {
      if (imagedata_OR_sw is num) {
        return LevelDom.wrapImageData(_ptr.createImageData(LevelDom.unwrapMaybePrimitive(imagedata_OR_sw), sh));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) {
    return LevelDom.wrapCanvasGradient(_ptr.createLinearGradient(x0, y0, x1, y1));
  }

  CanvasPattern createPattern(var canvas_OR_image, String repetitionType) {
    if (canvas_OR_image is CanvasElement) {
      return LevelDom.wrapCanvasPattern(_ptr.createPattern(LevelDom.unwrapMaybePrimitive(canvas_OR_image), repetitionType));
    } else {
      if (canvas_OR_image is ImageElement) {
        return LevelDom.wrapCanvasPattern(_ptr.createPattern(LevelDom.unwrapMaybePrimitive(canvas_OR_image), repetitionType));
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
                  _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y);
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
                _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
                return;
              }
            }
          }
        } else {
          _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
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
                    _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y);
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
                  _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
                  return;
                }
              }
            }
          } else {
            _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
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
              _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
              return;
            }
          }
        }
      } else {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
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
                _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                return;
              }
            }
          } else {
            if (a === null) {
              _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k);
              return;
            } else {
              _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
              return;
            }
          }
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
                _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
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
                  _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
                  return;
                }
              }
            }
          } else {
            if (b_OR_y === null) {
              if (a_OR_k === null) {
                if (a === null) {
                  _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                  return;
                }
              }
            } else {
              if (a === null) {
                _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k);
                return;
              } else {
                _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
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
              _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
              return;
            }
          }
        }
      } else {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
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
                _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                return;
              }
            }
          } else {
            if (a === null) {
              _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k);
              return;
            } else {
              _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
              return;
            }
          }
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
