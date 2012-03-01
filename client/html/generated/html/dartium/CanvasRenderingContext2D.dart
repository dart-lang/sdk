
class _CanvasRenderingContext2DImpl extends _CanvasRenderingContextImpl implements CanvasRenderingContext2D {
  _CanvasRenderingContext2DImpl._wrap(ptr) : super._wrap(ptr);

  Dynamic get fillStyle() => _wrap(_ptr.fillStyle);

  void set fillStyle(Dynamic value) { _ptr.fillStyle = _unwrap(value); }

  String get font() => _wrap(_ptr.font);

  void set font(String value) { _ptr.font = _unwrap(value); }

  num get globalAlpha() => _wrap(_ptr.globalAlpha);

  void set globalAlpha(num value) { _ptr.globalAlpha = _unwrap(value); }

  String get globalCompositeOperation() => _wrap(_ptr.globalCompositeOperation);

  void set globalCompositeOperation(String value) { _ptr.globalCompositeOperation = _unwrap(value); }

  String get lineCap() => _wrap(_ptr.lineCap);

  void set lineCap(String value) { _ptr.lineCap = _unwrap(value); }

  String get lineJoin() => _wrap(_ptr.lineJoin);

  void set lineJoin(String value) { _ptr.lineJoin = _unwrap(value); }

  num get lineWidth() => _wrap(_ptr.lineWidth);

  void set lineWidth(num value) { _ptr.lineWidth = _unwrap(value); }

  num get miterLimit() => _wrap(_ptr.miterLimit);

  void set miterLimit(num value) { _ptr.miterLimit = _unwrap(value); }

  num get shadowBlur() => _wrap(_ptr.shadowBlur);

  void set shadowBlur(num value) { _ptr.shadowBlur = _unwrap(value); }

  String get shadowColor() => _wrap(_ptr.shadowColor);

  void set shadowColor(String value) { _ptr.shadowColor = _unwrap(value); }

  num get shadowOffsetX() => _wrap(_ptr.shadowOffsetX);

  void set shadowOffsetX(num value) { _ptr.shadowOffsetX = _unwrap(value); }

  num get shadowOffsetY() => _wrap(_ptr.shadowOffsetY);

  void set shadowOffsetY(num value) { _ptr.shadowOffsetY = _unwrap(value); }

  Dynamic get strokeStyle() => _wrap(_ptr.strokeStyle);

  void set strokeStyle(Dynamic value) { _ptr.strokeStyle = _unwrap(value); }

  String get textAlign() => _wrap(_ptr.textAlign);

  void set textAlign(String value) { _ptr.textAlign = _unwrap(value); }

  String get textBaseline() => _wrap(_ptr.textBaseline);

  void set textBaseline(String value) { _ptr.textBaseline = _unwrap(value); }

  List get webkitLineDash() => _wrap(_ptr.webkitLineDash);

  void set webkitLineDash(List value) { _ptr.webkitLineDash = _unwrap(value); }

  num get webkitLineDashOffset() => _wrap(_ptr.webkitLineDashOffset);

  void set webkitLineDashOffset(num value) { _ptr.webkitLineDashOffset = _unwrap(value); }

  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise) {
    _ptr.arc(_unwrap(x), _unwrap(y), _unwrap(radius), _unwrap(startAngle), _unwrap(endAngle), _unwrap(anticlockwise));
    return;
  }

  void arcTo(num x1, num y1, num x2, num y2, num radius) {
    _ptr.arcTo(_unwrap(x1), _unwrap(y1), _unwrap(x2), _unwrap(y2), _unwrap(radius));
    return;
  }

  void beginPath() {
    _ptr.beginPath();
    return;
  }

  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) {
    _ptr.bezierCurveTo(_unwrap(cp1x), _unwrap(cp1y), _unwrap(cp2x), _unwrap(cp2y), _unwrap(x), _unwrap(y));
    return;
  }

  void clearRect(num x, num y, num width, num height) {
    _ptr.clearRect(_unwrap(x), _unwrap(y), _unwrap(width), _unwrap(height));
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
        return _wrap(_ptr.createImageData(_unwrap(imagedata_OR_sw)));
      }
    } else {
      if (imagedata_OR_sw is num) {
        return _wrap(_ptr.createImageData(_unwrap(imagedata_OR_sw), _unwrap(sh)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) {
    return _wrap(_ptr.createLinearGradient(_unwrap(x0), _unwrap(y0), _unwrap(x1), _unwrap(y1)));
  }

  CanvasPattern createPattern(var canvas_OR_image, String repetitionType) {
    if (canvas_OR_image is CanvasElement) {
      return _wrap(_ptr.createPattern(_unwrap(canvas_OR_image), _unwrap(repetitionType)));
    } else {
      if (canvas_OR_image is ImageElement) {
        return _wrap(_ptr.createPattern(_unwrap(canvas_OR_image), _unwrap(repetitionType)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) {
    return _wrap(_ptr.createRadialGradient(_unwrap(x0), _unwrap(y0), _unwrap(r0), _unwrap(x1), _unwrap(y1), _unwrap(r1)));
  }

  void drawImage(var canvas_OR_image_OR_video, num sx_OR_x, num sy_OR_y, [num sw_OR_width = null, num height_OR_sh = null, num dx = null, num dy = null, num dw = null, num dh = null]) {
    if (canvas_OR_image_OR_video is ImageElement) {
      if (sw_OR_width === null) {
        if (height_OR_sh === null) {
          if (dx === null) {
            if (dy === null) {
              if (dw === null) {
                if (dh === null) {
                  _ptr.drawImage(_unwrap(canvas_OR_image_OR_video), _unwrap(sx_OR_x), _unwrap(sy_OR_y));
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
                _ptr.drawImage(_unwrap(canvas_OR_image_OR_video), _unwrap(sx_OR_x), _unwrap(sy_OR_y), _unwrap(sw_OR_width), _unwrap(height_OR_sh));
                return;
              }
            }
          }
        } else {
          _ptr.drawImage(_unwrap(canvas_OR_image_OR_video), _unwrap(sx_OR_x), _unwrap(sy_OR_y), _unwrap(sw_OR_width), _unwrap(height_OR_sh), _unwrap(dx), _unwrap(dy), _unwrap(dw), _unwrap(dh));
          return;
        }
      }
    } else {
      if (canvas_OR_image_OR_video is CanvasElement) {
        if (sw_OR_width === null) {
          if (height_OR_sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    _ptr.drawImage(_unwrap(canvas_OR_image_OR_video), _unwrap(sx_OR_x), _unwrap(sy_OR_y));
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
                  _ptr.drawImage(_unwrap(canvas_OR_image_OR_video), _unwrap(sx_OR_x), _unwrap(sy_OR_y), _unwrap(sw_OR_width), _unwrap(height_OR_sh));
                  return;
                }
              }
            }
          } else {
            _ptr.drawImage(_unwrap(canvas_OR_image_OR_video), _unwrap(sx_OR_x), _unwrap(sy_OR_y), _unwrap(sw_OR_width), _unwrap(height_OR_sh), _unwrap(dx), _unwrap(dy), _unwrap(dw), _unwrap(dh));
            return;
          }
        }
      } else {
        if (canvas_OR_image_OR_video is VideoElement) {
          if (sw_OR_width === null) {
            if (height_OR_sh === null) {
              if (dx === null) {
                if (dy === null) {
                  if (dw === null) {
                    if (dh === null) {
                      _ptr.drawImage(_unwrap(canvas_OR_image_OR_video), _unwrap(sx_OR_x), _unwrap(sy_OR_y));
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
                    _ptr.drawImage(_unwrap(canvas_OR_image_OR_video), _unwrap(sx_OR_x), _unwrap(sy_OR_y), _unwrap(sw_OR_width), _unwrap(height_OR_sh));
                    return;
                  }
                }
              }
            } else {
              _ptr.drawImage(_unwrap(canvas_OR_image_OR_video), _unwrap(sx_OR_x), _unwrap(sy_OR_y), _unwrap(sw_OR_width), _unwrap(height_OR_sh), _unwrap(dx), _unwrap(dy), _unwrap(dw), _unwrap(dh));
              return;
            }
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
                      _ptr.drawImageFromRect(_unwrap(image));
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
                      _ptr.drawImageFromRect(_unwrap(image), _unwrap(sx));
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
                      _ptr.drawImageFromRect(_unwrap(image), _unwrap(sx), _unwrap(sy));
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
                      _ptr.drawImageFromRect(_unwrap(image), _unwrap(sx), _unwrap(sy), _unwrap(sw));
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
                      _ptr.drawImageFromRect(_unwrap(image), _unwrap(sx), _unwrap(sy), _unwrap(sw), _unwrap(sh));
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
                      _ptr.drawImageFromRect(_unwrap(image), _unwrap(sx), _unwrap(sy), _unwrap(sw), _unwrap(sh), _unwrap(dx));
                      return;
                    }
                  }
                }
              } else {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(_unwrap(image), _unwrap(sx), _unwrap(sy), _unwrap(sw), _unwrap(sh), _unwrap(dx), _unwrap(dy));
                      return;
                    }
                  }
                } else {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(_unwrap(image), _unwrap(sx), _unwrap(sy), _unwrap(sw), _unwrap(sh), _unwrap(dx), _unwrap(dy), _unwrap(dw));
                      return;
                    }
                  } else {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(_unwrap(image), _unwrap(sx), _unwrap(sy), _unwrap(sw), _unwrap(sh), _unwrap(dx), _unwrap(dy), _unwrap(dw), _unwrap(dh));
                      return;
                    } else {
                      _ptr.drawImageFromRect(_unwrap(image), _unwrap(sx), _unwrap(sy), _unwrap(sw), _unwrap(sh), _unwrap(dx), _unwrap(dy), _unwrap(dw), _unwrap(dh), _unwrap(compositeOperation));
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
    _ptr.fillRect(_unwrap(x), _unwrap(y), _unwrap(width), _unwrap(height));
    return;
  }

  void fillText(String text, num x, num y, [num maxWidth = null]) {
    if (maxWidth === null) {
      _ptr.fillText(_unwrap(text), _unwrap(x), _unwrap(y));
      return;
    } else {
      _ptr.fillText(_unwrap(text), _unwrap(x), _unwrap(y), _unwrap(maxWidth));
      return;
    }
  }

  ImageData getImageData(num sx, num sy, num sw, num sh) {
    return _wrap(_ptr.getImageData(_unwrap(sx), _unwrap(sy), _unwrap(sw), _unwrap(sh)));
  }

  bool isPointInPath(num x, num y) {
    return _wrap(_ptr.isPointInPath(_unwrap(x), _unwrap(y)));
  }

  void lineTo(num x, num y) {
    _ptr.lineTo(_unwrap(x), _unwrap(y));
    return;
  }

  TextMetrics measureText(String text) {
    return _wrap(_ptr.measureText(_unwrap(text)));
  }

  void moveTo(num x, num y) {
    _ptr.moveTo(_unwrap(x), _unwrap(y));
    return;
  }

  void putImageData(ImageData imagedata, num dx, num dy, [num dirtyX = null, num dirtyY = null, num dirtyWidth = null, num dirtyHeight = null]) {
    if (dirtyX === null) {
      if (dirtyY === null) {
        if (dirtyWidth === null) {
          if (dirtyHeight === null) {
            _ptr.putImageData(_unwrap(imagedata), _unwrap(dx), _unwrap(dy));
            return;
          }
        }
      }
    } else {
      _ptr.putImageData(_unwrap(imagedata), _unwrap(dx), _unwrap(dy), _unwrap(dirtyX), _unwrap(dirtyY), _unwrap(dirtyWidth), _unwrap(dirtyHeight));
      return;
    }
    throw "Incorrect number or type of arguments";
  }

  void quadraticCurveTo(num cpx, num cpy, num x, num y) {
    _ptr.quadraticCurveTo(_unwrap(cpx), _unwrap(cpy), _unwrap(x), _unwrap(y));
    return;
  }

  void rect(num x, num y, num width, num height) {
    _ptr.rect(_unwrap(x), _unwrap(y), _unwrap(width), _unwrap(height));
    return;
  }

  void restore() {
    _ptr.restore();
    return;
  }

  void rotate(num angle) {
    _ptr.rotate(_unwrap(angle));
    return;
  }

  void save() {
    _ptr.save();
    return;
  }

  void scale(num sx, num sy) {
    _ptr.scale(_unwrap(sx), _unwrap(sy));
    return;
  }

  void setAlpha(num alpha) {
    _ptr.setAlpha(_unwrap(alpha));
    return;
  }

  void setCompositeOperation(String compositeOperation) {
    _ptr.setCompositeOperation(_unwrap(compositeOperation));
    return;
  }

  void setFillColor(var c_OR_color_OR_grayLevel_OR_r, [num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) {
    if (c_OR_color_OR_grayLevel_OR_r is String) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setFillColor(_unwrap(c_OR_color_OR_grayLevel_OR_r));
              return;
            }
          }
        }
      } else {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setFillColor(_unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m));
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
                _ptr.setFillColor(_unwrap(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setFillColor(_unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m));
                return;
              }
            }
          } else {
            if (a === null) {
              _ptr.setFillColor(_unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m), _unwrap(b_OR_y), _unwrap(a_OR_k));
              return;
            } else {
              _ptr.setFillColor(_unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m), _unwrap(b_OR_y), _unwrap(a_OR_k), _unwrap(a));
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setLineCap(String cap) {
    _ptr.setLineCap(_unwrap(cap));
    return;
  }

  void setLineJoin(String join) {
    _ptr.setLineJoin(_unwrap(join));
    return;
  }

  void setLineWidth(num width) {
    _ptr.setLineWidth(_unwrap(width));
    return;
  }

  void setMiterLimit(num limit) {
    _ptr.setMiterLimit(_unwrap(limit));
    return;
  }

  void setShadow(num width, num height, num blur, [var c_OR_color_OR_grayLevel_OR_r = null, num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) {
    if (c_OR_color_OR_grayLevel_OR_r === null) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setShadow(_unwrap(width), _unwrap(height), _unwrap(blur));
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
                _ptr.setShadow(_unwrap(width), _unwrap(height), _unwrap(blur), _unwrap(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setShadow(_unwrap(width), _unwrap(height), _unwrap(blur), _unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m));
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
                  _ptr.setShadow(_unwrap(width), _unwrap(height), _unwrap(blur), _unwrap(c_OR_color_OR_grayLevel_OR_r));
                  return;
                }
              }
            }
          } else {
            if (b_OR_y === null) {
              if (a_OR_k === null) {
                if (a === null) {
                  _ptr.setShadow(_unwrap(width), _unwrap(height), _unwrap(blur), _unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m));
                  return;
                }
              }
            } else {
              if (a === null) {
                _ptr.setShadow(_unwrap(width), _unwrap(height), _unwrap(blur), _unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m), _unwrap(b_OR_y), _unwrap(a_OR_k));
                return;
              } else {
                _ptr.setShadow(_unwrap(width), _unwrap(height), _unwrap(blur), _unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m), _unwrap(b_OR_y), _unwrap(a_OR_k), _unwrap(a));
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
              _ptr.setStrokeColor(_unwrap(c_OR_color_OR_grayLevel_OR_r));
              return;
            }
          }
        }
      } else {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setStrokeColor(_unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m));
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
                _ptr.setStrokeColor(_unwrap(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setStrokeColor(_unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m));
                return;
              }
            }
          } else {
            if (a === null) {
              _ptr.setStrokeColor(_unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m), _unwrap(b_OR_y), _unwrap(a_OR_k));
              return;
            } else {
              _ptr.setStrokeColor(_unwrap(c_OR_color_OR_grayLevel_OR_r), _unwrap(alpha_OR_g_OR_m), _unwrap(b_OR_y), _unwrap(a_OR_k), _unwrap(a));
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy) {
    _ptr.setTransform(_unwrap(m11), _unwrap(m12), _unwrap(m21), _unwrap(m22), _unwrap(dx), _unwrap(dy));
    return;
  }

  void stroke() {
    _ptr.stroke();
    return;
  }

  void strokeRect(num x, num y, num width, num height, [num lineWidth = null]) {
    if (lineWidth === null) {
      _ptr.strokeRect(_unwrap(x), _unwrap(y), _unwrap(width), _unwrap(height));
      return;
    } else {
      _ptr.strokeRect(_unwrap(x), _unwrap(y), _unwrap(width), _unwrap(height), _unwrap(lineWidth));
      return;
    }
  }

  void strokeText(String text, num x, num y, [num maxWidth = null]) {
    if (maxWidth === null) {
      _ptr.strokeText(_unwrap(text), _unwrap(x), _unwrap(y));
      return;
    } else {
      _ptr.strokeText(_unwrap(text), _unwrap(x), _unwrap(y), _unwrap(maxWidth));
      return;
    }
  }

  void transform(num m11, num m12, num m21, num m22, num dx, num dy) {
    _ptr.transform(_unwrap(m11), _unwrap(m12), _unwrap(m21), _unwrap(m22), _unwrap(dx), _unwrap(dy));
    return;
  }

  void translate(num tx, num ty) {
    _ptr.translate(_unwrap(tx), _unwrap(ty));
    return;
  }
}
