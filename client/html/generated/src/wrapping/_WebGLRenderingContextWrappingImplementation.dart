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
      _ptr.bufferData(target, LevelDom.unwrapMaybePrimitive(data_OR_size), usage);
      return;
    } else {
      if (data_OR_size is ArrayBufferView) {
        _ptr.bufferData(target, LevelDom.unwrapMaybePrimitive(data_OR_size), usage);
        return;
      } else {
        if (data_OR_size is int) {
          _ptr.bufferData(target, LevelDom.unwrapMaybePrimitive(data_OR_size), usage);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void bufferSubData(int target, int offset, var data) {
    if (data is ArrayBuffer) {
      _ptr.bufferSubData(target, offset, LevelDom.unwrapMaybePrimitive(data));
      return;
    } else {
      if (data is ArrayBufferView) {
        _ptr.bufferSubData(target, offset, LevelDom.unwrapMaybePrimitive(data));
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

  Object getBufferParameter(int target, int pname) {
    return LevelDom.wrapObject(_ptr.getBufferParameter(target, pname));
  }

  WebGLContextAttributes getContextAttributes() {
    return LevelDom.wrapWebGLContextAttributes(_ptr.getContextAttributes());
  }

  int getError() {
    return _ptr.getError();
  }

  Object getExtension(String name) {
    return LevelDom.wrapObject(_ptr.getExtension(name));
  }

  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) {
    return LevelDom.wrapObject(_ptr.getFramebufferAttachmentParameter(target, attachment, pname));
  }

  Object getParameter(int pname) {
    return LevelDom.wrapObject(_ptr.getParameter(pname));
  }

  String getProgramInfoLog(WebGLProgram program) {
    return _ptr.getProgramInfoLog(LevelDom.unwrap(program));
  }

  Object getProgramParameter(WebGLProgram program, int pname) {
    return LevelDom.wrapObject(_ptr.getProgramParameter(LevelDom.unwrap(program), pname));
  }

  Object getRenderbufferParameter(int target, int pname) {
    return LevelDom.wrapObject(_ptr.getRenderbufferParameter(target, pname));
  }

  String getShaderInfoLog(WebGLShader shader) {
    return _ptr.getShaderInfoLog(LevelDom.unwrap(shader));
  }

  Object getShaderParameter(WebGLShader shader, int pname) {
    return LevelDom.wrapObject(_ptr.getShaderParameter(LevelDom.unwrap(shader), pname));
  }

  String getShaderSource(WebGLShader shader) {
    return _ptr.getShaderSource(LevelDom.unwrap(shader));
  }

  Object getTexParameter(int target, int pname) {
    return LevelDom.wrapObject(_ptr.getTexParameter(target, pname));
  }

  Object getUniform(WebGLProgram program, WebGLUniformLocation location) {
    return LevelDom.wrapObject(_ptr.getUniform(LevelDom.unwrap(program), LevelDom.unwrap(location)));
  }

  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) {
    return LevelDom.wrapWebGLUniformLocation(_ptr.getUniformLocation(LevelDom.unwrap(program), name));
  }

  Object getVertexAttrib(int index, int pname) {
    return LevelDom.wrapObject(_ptr.getVertexAttrib(index, pname));
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

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels, [int format, int type, ArrayBufferView pixels]) {
    if (border_OR_canvas_OR_image_OR_pixels is ImageData) {
      if (format === null) {
        if (type === null) {
          if (pixels === null) {
            _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(border_OR_canvas_OR_image_OR_pixels));
            return;
          }
        }
      }
    } else {
      if (border_OR_canvas_OR_image_OR_pixels is ImageElement) {
        if (format === null) {
          if (type === null) {
            if (pixels === null) {
              _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(border_OR_canvas_OR_image_OR_pixels));
              return;
            }
          }
        }
      } else {
        if (border_OR_canvas_OR_image_OR_pixels is CanvasElement) {
          if (format === null) {
            if (type === null) {
              if (pixels === null) {
                _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(border_OR_canvas_OR_image_OR_pixels));
                return;
              }
            }
          }
        } else {
          if (border_OR_canvas_OR_image_OR_pixels is int) {
            _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(border_OR_canvas_OR_image_OR_pixels), format, type, LevelDom.unwrap(pixels));
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

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels, [int type, ArrayBufferView pixels]) {
    if (canvas_OR_format_OR_image_OR_pixels is ImageData) {
      if (type === null) {
        if (pixels === null) {
          _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(canvas_OR_format_OR_image_OR_pixels));
          return;
        }
      }
    } else {
      if (canvas_OR_format_OR_image_OR_pixels is ImageElement) {
        if (type === null) {
          if (pixels === null) {
            _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(canvas_OR_format_OR_image_OR_pixels));
            return;
          }
        }
      } else {
        if (canvas_OR_format_OR_image_OR_pixels is CanvasElement) {
          if (type === null) {
            if (pixels === null) {
              _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(canvas_OR_format_OR_image_OR_pixels));
              return;
            }
          }
        } else {
          if (canvas_OR_format_OR_image_OR_pixels is int) {
            _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(canvas_OR_format_OR_image_OR_pixels), type, LevelDom.unwrap(pixels));
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
