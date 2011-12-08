// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebGLRenderingContextWrappingImplementation extends _CanvasRenderingContextWrappingImplementation implements WebGLRenderingContext {
  _WebGLRenderingContextWrappingImplementation() : super() {}

  static create__WebGLRenderingContextWrappingImplementation() native {
    return new _WebGLRenderingContextWrappingImplementation();
  }

  int get drawingBufferHeight() { return _get_drawingBufferHeight(this); }
  static int _get_drawingBufferHeight(var _this) native;

  int get drawingBufferWidth() { return _get_drawingBufferWidth(this); }
  static int _get_drawingBufferWidth(var _this) native;

  void activeTexture(int texture) {
    _activeTexture(this, texture);
    return;
  }
  static void _activeTexture(receiver, texture) native;

  void attachShader(WebGLProgram program, WebGLShader shader) {
    _attachShader(this, program, shader);
    return;
  }
  static void _attachShader(receiver, program, shader) native;

  void bindAttribLocation(WebGLProgram program, int index, String name) {
    _bindAttribLocation(this, program, index, name);
    return;
  }
  static void _bindAttribLocation(receiver, program, index, name) native;

  void bindBuffer(int target, WebGLBuffer buffer) {
    _bindBuffer(this, target, buffer);
    return;
  }
  static void _bindBuffer(receiver, target, buffer) native;

  void bindFramebuffer(int target, WebGLFramebuffer framebuffer) {
    _bindFramebuffer(this, target, framebuffer);
    return;
  }
  static void _bindFramebuffer(receiver, target, framebuffer) native;

  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer) {
    _bindRenderbuffer(this, target, renderbuffer);
    return;
  }
  static void _bindRenderbuffer(receiver, target, renderbuffer) native;

  void bindTexture(int target, WebGLTexture texture) {
    _bindTexture(this, target, texture);
    return;
  }
  static void _bindTexture(receiver, target, texture) native;

  void blendColor(num red, num green, num blue, num alpha) {
    _blendColor(this, red, green, blue, alpha);
    return;
  }
  static void _blendColor(receiver, red, green, blue, alpha) native;

  void blendEquation(int mode) {
    _blendEquation(this, mode);
    return;
  }
  static void _blendEquation(receiver, mode) native;

  void blendEquationSeparate(int modeRGB, int modeAlpha) {
    _blendEquationSeparate(this, modeRGB, modeAlpha);
    return;
  }
  static void _blendEquationSeparate(receiver, modeRGB, modeAlpha) native;

  void blendFunc(int sfactor, int dfactor) {
    _blendFunc(this, sfactor, dfactor);
    return;
  }
  static void _blendFunc(receiver, sfactor, dfactor) native;

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) {
    _blendFuncSeparate(this, srcRGB, dstRGB, srcAlpha, dstAlpha);
    return;
  }
  static void _blendFuncSeparate(receiver, srcRGB, dstRGB, srcAlpha, dstAlpha) native;

  void bufferData(int target, var data_OR_size, int usage) {
    if (data_OR_size is ArrayBuffer) {
      _bufferData(this, target, data_OR_size, usage);
      return;
    } else {
      if (data_OR_size is ArrayBufferView) {
        _bufferData_2(this, target, data_OR_size, usage);
        return;
      } else {
        if (data_OR_size is int) {
          _bufferData_3(this, target, data_OR_size, usage);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _bufferData(receiver, target, data_OR_size, usage) native;
  static void _bufferData_2(receiver, target, data_OR_size, usage) native;
  static void _bufferData_3(receiver, target, data_OR_size, usage) native;

  void bufferSubData(int target, int offset, var data) {
    if (data is ArrayBuffer) {
      _bufferSubData(this, target, offset, data);
      return;
    } else {
      if (data is ArrayBufferView) {
        _bufferSubData_2(this, target, offset, data);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _bufferSubData(receiver, target, offset, data) native;
  static void _bufferSubData_2(receiver, target, offset, data) native;

  int checkFramebufferStatus(int target) {
    return _checkFramebufferStatus(this, target);
  }
  static int _checkFramebufferStatus(receiver, target) native;

  void clear(int mask) {
    _clear(this, mask);
    return;
  }
  static void _clear(receiver, mask) native;

  void clearColor(num red, num green, num blue, num alpha) {
    _clearColor(this, red, green, blue, alpha);
    return;
  }
  static void _clearColor(receiver, red, green, blue, alpha) native;

  void clearDepth(num depth) {
    _clearDepth(this, depth);
    return;
  }
  static void _clearDepth(receiver, depth) native;

  void clearStencil(int s) {
    _clearStencil(this, s);
    return;
  }
  static void _clearStencil(receiver, s) native;

  void colorMask(bool red, bool green, bool blue, bool alpha) {
    _colorMask(this, red, green, blue, alpha);
    return;
  }
  static void _colorMask(receiver, red, green, blue, alpha) native;

  void compileShader(WebGLShader shader) {
    _compileShader(this, shader);
    return;
  }
  static void _compileShader(receiver, shader) native;

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) {
    _copyTexImage2D(this, target, level, internalformat, x, y, width, height, border);
    return;
  }
  static void _copyTexImage2D(receiver, target, level, internalformat, x, y, width, height, border) native;

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) {
    _copyTexSubImage2D(this, target, level, xoffset, yoffset, x, y, width, height);
    return;
  }
  static void _copyTexSubImage2D(receiver, target, level, xoffset, yoffset, x, y, width, height) native;

  WebGLBuffer createBuffer() {
    return _createBuffer(this);
  }
  static WebGLBuffer _createBuffer(receiver) native;

  WebGLFramebuffer createFramebuffer() {
    return _createFramebuffer(this);
  }
  static WebGLFramebuffer _createFramebuffer(receiver) native;

  WebGLProgram createProgram() {
    return _createProgram(this);
  }
  static WebGLProgram _createProgram(receiver) native;

  WebGLRenderbuffer createRenderbuffer() {
    return _createRenderbuffer(this);
  }
  static WebGLRenderbuffer _createRenderbuffer(receiver) native;

  WebGLShader createShader(int type) {
    return _createShader(this, type);
  }
  static WebGLShader _createShader(receiver, type) native;

  WebGLTexture createTexture() {
    return _createTexture(this);
  }
  static WebGLTexture _createTexture(receiver) native;

  void cullFace(int mode) {
    _cullFace(this, mode);
    return;
  }
  static void _cullFace(receiver, mode) native;

  void deleteBuffer(WebGLBuffer buffer) {
    _deleteBuffer(this, buffer);
    return;
  }
  static void _deleteBuffer(receiver, buffer) native;

  void deleteFramebuffer(WebGLFramebuffer framebuffer) {
    _deleteFramebuffer(this, framebuffer);
    return;
  }
  static void _deleteFramebuffer(receiver, framebuffer) native;

  void deleteProgram(WebGLProgram program) {
    _deleteProgram(this, program);
    return;
  }
  static void _deleteProgram(receiver, program) native;

  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer) {
    _deleteRenderbuffer(this, renderbuffer);
    return;
  }
  static void _deleteRenderbuffer(receiver, renderbuffer) native;

  void deleteShader(WebGLShader shader) {
    _deleteShader(this, shader);
    return;
  }
  static void _deleteShader(receiver, shader) native;

  void deleteTexture(WebGLTexture texture) {
    _deleteTexture(this, texture);
    return;
  }
  static void _deleteTexture(receiver, texture) native;

  void depthFunc(int func) {
    _depthFunc(this, func);
    return;
  }
  static void _depthFunc(receiver, func) native;

  void depthMask(bool flag) {
    _depthMask(this, flag);
    return;
  }
  static void _depthMask(receiver, flag) native;

  void depthRange(num zNear, num zFar) {
    _depthRange(this, zNear, zFar);
    return;
  }
  static void _depthRange(receiver, zNear, zFar) native;

  void detachShader(WebGLProgram program, WebGLShader shader) {
    _detachShader(this, program, shader);
    return;
  }
  static void _detachShader(receiver, program, shader) native;

  void disable(int cap) {
    _disable(this, cap);
    return;
  }
  static void _disable(receiver, cap) native;

  void disableVertexAttribArray(int index) {
    _disableVertexAttribArray(this, index);
    return;
  }
  static void _disableVertexAttribArray(receiver, index) native;

  void drawArrays(int mode, int first, int count) {
    _drawArrays(this, mode, first, count);
    return;
  }
  static void _drawArrays(receiver, mode, first, count) native;

  void drawElements(int mode, int count, int type, int offset) {
    _drawElements(this, mode, count, type, offset);
    return;
  }
  static void _drawElements(receiver, mode, count, type, offset) native;

  void enable(int cap) {
    _enable(this, cap);
    return;
  }
  static void _enable(receiver, cap) native;

  void enableVertexAttribArray(int index) {
    _enableVertexAttribArray(this, index);
    return;
  }
  static void _enableVertexAttribArray(receiver, index) native;

  void finish() {
    _finish(this);
    return;
  }
  static void _finish(receiver) native;

  void flush() {
    _flush(this);
    return;
  }
  static void _flush(receiver) native;

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, WebGLRenderbuffer renderbuffer) {
    _framebufferRenderbuffer(this, target, attachment, renderbuffertarget, renderbuffer);
    return;
  }
  static void _framebufferRenderbuffer(receiver, target, attachment, renderbuffertarget, renderbuffer) native;

  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level) {
    _framebufferTexture2D(this, target, attachment, textarget, texture, level);
    return;
  }
  static void _framebufferTexture2D(receiver, target, attachment, textarget, texture, level) native;

  void frontFace(int mode) {
    _frontFace(this, mode);
    return;
  }
  static void _frontFace(receiver, mode) native;

  void generateMipmap(int target) {
    _generateMipmap(this, target);
    return;
  }
  static void _generateMipmap(receiver, target) native;

  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index) {
    return _getActiveAttrib(this, program, index);
  }
  static WebGLActiveInfo _getActiveAttrib(receiver, program, index) native;

  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index) {
    return _getActiveUniform(this, program, index);
  }
  static WebGLActiveInfo _getActiveUniform(receiver, program, index) native;

  void getAttachedShaders(WebGLProgram program) {
    _getAttachedShaders(this, program);
    return;
  }
  static void _getAttachedShaders(receiver, program) native;

  int getAttribLocation(WebGLProgram program, String name) {
    return _getAttribLocation(this, program, name);
  }
  static int _getAttribLocation(receiver, program, name) native;

  Object getBufferParameter(int target, int pname) {
    return _getBufferParameter(this, target, pname);
  }
  static Object _getBufferParameter(receiver, target, pname) native;

  WebGLContextAttributes getContextAttributes() {
    return _getContextAttributes(this);
  }
  static WebGLContextAttributes _getContextAttributes(receiver) native;

  int getError() {
    return _getError(this);
  }
  static int _getError(receiver) native;

  Object getExtension(String name) {
    return _getExtension(this, name);
  }
  static Object _getExtension(receiver, name) native;

  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) {
    return _getFramebufferAttachmentParameter(this, target, attachment, pname);
  }
  static Object _getFramebufferAttachmentParameter(receiver, target, attachment, pname) native;

  Object getParameter(int pname) {
    return _getParameter(this, pname);
  }
  static Object _getParameter(receiver, pname) native;

  String getProgramInfoLog(WebGLProgram program) {
    return _getProgramInfoLog(this, program);
  }
  static String _getProgramInfoLog(receiver, program) native;

  Object getProgramParameter(WebGLProgram program, int pname) {
    return _getProgramParameter(this, program, pname);
  }
  static Object _getProgramParameter(receiver, program, pname) native;

  Object getRenderbufferParameter(int target, int pname) {
    return _getRenderbufferParameter(this, target, pname);
  }
  static Object _getRenderbufferParameter(receiver, target, pname) native;

  String getShaderInfoLog(WebGLShader shader) {
    return _getShaderInfoLog(this, shader);
  }
  static String _getShaderInfoLog(receiver, shader) native;

  Object getShaderParameter(WebGLShader shader, int pname) {
    return _getShaderParameter(this, shader, pname);
  }
  static Object _getShaderParameter(receiver, shader, pname) native;

  String getShaderSource(WebGLShader shader) {
    return _getShaderSource(this, shader);
  }
  static String _getShaderSource(receiver, shader) native;

  Object getTexParameter(int target, int pname) {
    return _getTexParameter(this, target, pname);
  }
  static Object _getTexParameter(receiver, target, pname) native;

  Object getUniform(WebGLProgram program, WebGLUniformLocation location) {
    return _getUniform(this, program, location);
  }
  static Object _getUniform(receiver, program, location) native;

  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) {
    return _getUniformLocation(this, program, name);
  }
  static WebGLUniformLocation _getUniformLocation(receiver, program, name) native;

  Object getVertexAttrib(int index, int pname) {
    return _getVertexAttrib(this, index, pname);
  }
  static Object _getVertexAttrib(receiver, index, pname) native;

  int getVertexAttribOffset(int index, int pname) {
    return _getVertexAttribOffset(this, index, pname);
  }
  static int _getVertexAttribOffset(receiver, index, pname) native;

  void hint(int target, int mode) {
    _hint(this, target, mode);
    return;
  }
  static void _hint(receiver, target, mode) native;

  bool isBuffer(WebGLBuffer buffer) {
    return _isBuffer(this, buffer);
  }
  static bool _isBuffer(receiver, buffer) native;

  bool isContextLost() {
    return _isContextLost(this);
  }
  static bool _isContextLost(receiver) native;

  bool isEnabled(int cap) {
    return _isEnabled(this, cap);
  }
  static bool _isEnabled(receiver, cap) native;

  bool isFramebuffer(WebGLFramebuffer framebuffer) {
    return _isFramebuffer(this, framebuffer);
  }
  static bool _isFramebuffer(receiver, framebuffer) native;

  bool isProgram(WebGLProgram program) {
    return _isProgram(this, program);
  }
  static bool _isProgram(receiver, program) native;

  bool isRenderbuffer(WebGLRenderbuffer renderbuffer) {
    return _isRenderbuffer(this, renderbuffer);
  }
  static bool _isRenderbuffer(receiver, renderbuffer) native;

  bool isShader(WebGLShader shader) {
    return _isShader(this, shader);
  }
  static bool _isShader(receiver, shader) native;

  bool isTexture(WebGLTexture texture) {
    return _isTexture(this, texture);
  }
  static bool _isTexture(receiver, texture) native;

  void lineWidth(num width) {
    _lineWidth(this, width);
    return;
  }
  static void _lineWidth(receiver, width) native;

  void linkProgram(WebGLProgram program) {
    _linkProgram(this, program);
    return;
  }
  static void _linkProgram(receiver, program) native;

  void pixelStorei(int pname, int param) {
    _pixelStorei(this, pname, param);
    return;
  }
  static void _pixelStorei(receiver, pname, param) native;

  void polygonOffset(num factor, num units) {
    _polygonOffset(this, factor, units);
    return;
  }
  static void _polygonOffset(receiver, factor, units) native;

  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels) {
    _readPixels(this, x, y, width, height, format, type, pixels);
    return;
  }
  static void _readPixels(receiver, x, y, width, height, format, type, pixels) native;

  void releaseShaderCompiler() {
    _releaseShaderCompiler(this);
    return;
  }
  static void _releaseShaderCompiler(receiver) native;

  void renderbufferStorage(int target, int internalformat, int width, int height) {
    _renderbufferStorage(this, target, internalformat, width, height);
    return;
  }
  static void _renderbufferStorage(receiver, target, internalformat, width, height) native;

  void sampleCoverage(num value, bool invert) {
    _sampleCoverage(this, value, invert);
    return;
  }
  static void _sampleCoverage(receiver, value, invert) native;

  void scissor(int x, int y, int width, int height) {
    _scissor(this, x, y, width, height);
    return;
  }
  static void _scissor(receiver, x, y, width, height) native;

  void shaderSource(WebGLShader shader, String string) {
    _shaderSource(this, shader, string);
    return;
  }
  static void _shaderSource(receiver, shader, string) native;

  void stencilFunc(int func, int ref, int mask) {
    _stencilFunc(this, func, ref, mask);
    return;
  }
  static void _stencilFunc(receiver, func, ref, mask) native;

  void stencilFuncSeparate(int face, int func, int ref, int mask) {
    _stencilFuncSeparate(this, face, func, ref, mask);
    return;
  }
  static void _stencilFuncSeparate(receiver, face, func, ref, mask) native;

  void stencilMask(int mask) {
    _stencilMask(this, mask);
    return;
  }
  static void _stencilMask(receiver, mask) native;

  void stencilMaskSeparate(int face, int mask) {
    _stencilMaskSeparate(this, face, mask);
    return;
  }
  static void _stencilMaskSeparate(receiver, face, mask) native;

  void stencilOp(int fail, int zfail, int zpass) {
    _stencilOp(this, fail, zfail, zpass);
    return;
  }
  static void _stencilOp(receiver, fail, zfail, zpass) native;

  void stencilOpSeparate(int face, int fail, int zfail, int zpass) {
    _stencilOpSeparate(this, face, fail, zfail, zpass);
    return;
  }
  static void _stencilOpSeparate(receiver, face, fail, zfail, zpass) native;

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels, [int format = null, int type = null, ArrayBufferView pixels = null]) {
    if (border_OR_canvas_OR_image_OR_pixels is ImageData) {
      if (format === null) {
        if (type === null) {
          if (pixels === null) {
            _texImage2D(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels);
            return;
          }
        }
      }
    } else {
      if (border_OR_canvas_OR_image_OR_pixels is HTMLImageElement) {
        if (format === null) {
          if (type === null) {
            if (pixels === null) {
              _texImage2D_2(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels);
              return;
            }
          }
        }
      } else {
        if (border_OR_canvas_OR_image_OR_pixels is HTMLCanvasElement) {
          if (format === null) {
            if (type === null) {
              if (pixels === null) {
                _texImage2D_3(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels);
                return;
              }
            }
          }
        } else {
          if (border_OR_canvas_OR_image_OR_pixels is int) {
            _texImage2D_4(this, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels, format, type, pixels);
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _texImage2D(receiver, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels) native;
  static void _texImage2D_2(receiver, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels) native;
  static void _texImage2D_3(receiver, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels) native;
  static void _texImage2D_4(receiver, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels, format, type, pixels) native;

  void texParameterf(int target, int pname, num param) {
    _texParameterf(this, target, pname, param);
    return;
  }
  static void _texParameterf(receiver, target, pname, param) native;

  void texParameteri(int target, int pname, int param) {
    _texParameteri(this, target, pname, param);
    return;
  }
  static void _texParameteri(receiver, target, pname, param) native;

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels, [int type = null, ArrayBufferView pixels = null]) {
    if (canvas_OR_format_OR_image_OR_pixels is ImageData) {
      if (type === null) {
        if (pixels === null) {
          _texSubImage2D(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels);
          return;
        }
      }
    } else {
      if (canvas_OR_format_OR_image_OR_pixels is HTMLImageElement) {
        if (type === null) {
          if (pixels === null) {
            _texSubImage2D_2(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels);
            return;
          }
        }
      } else {
        if (canvas_OR_format_OR_image_OR_pixels is HTMLCanvasElement) {
          if (type === null) {
            if (pixels === null) {
              _texSubImage2D_3(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels);
              return;
            }
          }
        } else {
          if (canvas_OR_format_OR_image_OR_pixels is int) {
            _texSubImage2D_4(this, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels, type, pixels);
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _texSubImage2D(receiver, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels) native;
  static void _texSubImage2D_2(receiver, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels) native;
  static void _texSubImage2D_3(receiver, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels) native;
  static void _texSubImage2D_4(receiver, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels, type, pixels) native;

  void uniform1f(WebGLUniformLocation location, num x) {
    _uniform1f(this, location, x);
    return;
  }
  static void _uniform1f(receiver, location, x) native;

  void uniform1fv(WebGLUniformLocation location, Float32Array v) {
    _uniform1fv(this, location, v);
    return;
  }
  static void _uniform1fv(receiver, location, v) native;

  void uniform1i(WebGLUniformLocation location, int x) {
    _uniform1i(this, location, x);
    return;
  }
  static void _uniform1i(receiver, location, x) native;

  void uniform1iv(WebGLUniformLocation location, Int32Array v) {
    _uniform1iv(this, location, v);
    return;
  }
  static void _uniform1iv(receiver, location, v) native;

  void uniform2f(WebGLUniformLocation location, num x, num y) {
    _uniform2f(this, location, x, y);
    return;
  }
  static void _uniform2f(receiver, location, x, y) native;

  void uniform2fv(WebGLUniformLocation location, Float32Array v) {
    _uniform2fv(this, location, v);
    return;
  }
  static void _uniform2fv(receiver, location, v) native;

  void uniform2i(WebGLUniformLocation location, int x, int y) {
    _uniform2i(this, location, x, y);
    return;
  }
  static void _uniform2i(receiver, location, x, y) native;

  void uniform2iv(WebGLUniformLocation location, Int32Array v) {
    _uniform2iv(this, location, v);
    return;
  }
  static void _uniform2iv(receiver, location, v) native;

  void uniform3f(WebGLUniformLocation location, num x, num y, num z) {
    _uniform3f(this, location, x, y, z);
    return;
  }
  static void _uniform3f(receiver, location, x, y, z) native;

  void uniform3fv(WebGLUniformLocation location, Float32Array v) {
    _uniform3fv(this, location, v);
    return;
  }
  static void _uniform3fv(receiver, location, v) native;

  void uniform3i(WebGLUniformLocation location, int x, int y, int z) {
    _uniform3i(this, location, x, y, z);
    return;
  }
  static void _uniform3i(receiver, location, x, y, z) native;

  void uniform3iv(WebGLUniformLocation location, Int32Array v) {
    _uniform3iv(this, location, v);
    return;
  }
  static void _uniform3iv(receiver, location, v) native;

  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w) {
    _uniform4f(this, location, x, y, z, w);
    return;
  }
  static void _uniform4f(receiver, location, x, y, z, w) native;

  void uniform4fv(WebGLUniformLocation location, Float32Array v) {
    _uniform4fv(this, location, v);
    return;
  }
  static void _uniform4fv(receiver, location, v) native;

  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w) {
    _uniform4i(this, location, x, y, z, w);
    return;
  }
  static void _uniform4i(receiver, location, x, y, z, w) native;

  void uniform4iv(WebGLUniformLocation location, Int32Array v) {
    _uniform4iv(this, location, v);
    return;
  }
  static void _uniform4iv(receiver, location, v) native;

  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _uniformMatrix2fv(this, location, transpose, array);
    return;
  }
  static void _uniformMatrix2fv(receiver, location, transpose, array) native;

  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _uniformMatrix3fv(this, location, transpose, array);
    return;
  }
  static void _uniformMatrix3fv(receiver, location, transpose, array) native;

  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _uniformMatrix4fv(this, location, transpose, array);
    return;
  }
  static void _uniformMatrix4fv(receiver, location, transpose, array) native;

  void useProgram(WebGLProgram program) {
    _useProgram(this, program);
    return;
  }
  static void _useProgram(receiver, program) native;

  void validateProgram(WebGLProgram program) {
    _validateProgram(this, program);
    return;
  }
  static void _validateProgram(receiver, program) native;

  void vertexAttrib1f(int indx, num x) {
    _vertexAttrib1f(this, indx, x);
    return;
  }
  static void _vertexAttrib1f(receiver, indx, x) native;

  void vertexAttrib1fv(int indx, Float32Array values) {
    _vertexAttrib1fv(this, indx, values);
    return;
  }
  static void _vertexAttrib1fv(receiver, indx, values) native;

  void vertexAttrib2f(int indx, num x, num y) {
    _vertexAttrib2f(this, indx, x, y);
    return;
  }
  static void _vertexAttrib2f(receiver, indx, x, y) native;

  void vertexAttrib2fv(int indx, Float32Array values) {
    _vertexAttrib2fv(this, indx, values);
    return;
  }
  static void _vertexAttrib2fv(receiver, indx, values) native;

  void vertexAttrib3f(int indx, num x, num y, num z) {
    _vertexAttrib3f(this, indx, x, y, z);
    return;
  }
  static void _vertexAttrib3f(receiver, indx, x, y, z) native;

  void vertexAttrib3fv(int indx, Float32Array values) {
    _vertexAttrib3fv(this, indx, values);
    return;
  }
  static void _vertexAttrib3fv(receiver, indx, values) native;

  void vertexAttrib4f(int indx, num x, num y, num z, num w) {
    _vertexAttrib4f(this, indx, x, y, z, w);
    return;
  }
  static void _vertexAttrib4f(receiver, indx, x, y, z, w) native;

  void vertexAttrib4fv(int indx, Float32Array values) {
    _vertexAttrib4fv(this, indx, values);
    return;
  }
  static void _vertexAttrib4fv(receiver, indx, values) native;

  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) {
    _vertexAttribPointer(this, indx, size, type, normalized, stride, offset);
    return;
  }
  static void _vertexAttribPointer(receiver, indx, size, type, normalized, stride, offset) native;

  void viewport(int x, int y, int width, int height) {
    _viewport(this, x, y, width, height);
    return;
  }
  static void _viewport(receiver, x, y, width, height) native;

  String get typeName() { return "WebGLRenderingContext"; }
}
