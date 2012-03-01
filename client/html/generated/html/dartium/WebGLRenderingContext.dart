
class _WebGLRenderingContextImpl extends _CanvasRenderingContextImpl implements WebGLRenderingContext {
  _WebGLRenderingContextImpl._wrap(ptr) : super._wrap(ptr);

  int get drawingBufferHeight() => _wrap(_ptr.drawingBufferHeight);

  int get drawingBufferWidth() => _wrap(_ptr.drawingBufferWidth);

  void activeTexture(int texture) {
    _ptr.activeTexture(_unwrap(texture));
    return;
  }

  void attachShader(WebGLProgram program, WebGLShader shader) {
    _ptr.attachShader(_unwrap(program), _unwrap(shader));
    return;
  }

  void bindAttribLocation(WebGLProgram program, int index, String name) {
    _ptr.bindAttribLocation(_unwrap(program), _unwrap(index), _unwrap(name));
    return;
  }

  void bindBuffer(int target, WebGLBuffer buffer) {
    _ptr.bindBuffer(_unwrap(target), _unwrap(buffer));
    return;
  }

  void bindFramebuffer(int target, WebGLFramebuffer framebuffer) {
    _ptr.bindFramebuffer(_unwrap(target), _unwrap(framebuffer));
    return;
  }

  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer) {
    _ptr.bindRenderbuffer(_unwrap(target), _unwrap(renderbuffer));
    return;
  }

  void bindTexture(int target, WebGLTexture texture) {
    _ptr.bindTexture(_unwrap(target), _unwrap(texture));
    return;
  }

  void blendColor(num red, num green, num blue, num alpha) {
    _ptr.blendColor(_unwrap(red), _unwrap(green), _unwrap(blue), _unwrap(alpha));
    return;
  }

  void blendEquation(int mode) {
    _ptr.blendEquation(_unwrap(mode));
    return;
  }

  void blendEquationSeparate(int modeRGB, int modeAlpha) {
    _ptr.blendEquationSeparate(_unwrap(modeRGB), _unwrap(modeAlpha));
    return;
  }

  void blendFunc(int sfactor, int dfactor) {
    _ptr.blendFunc(_unwrap(sfactor), _unwrap(dfactor));
    return;
  }

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) {
    _ptr.blendFuncSeparate(_unwrap(srcRGB), _unwrap(dstRGB), _unwrap(srcAlpha), _unwrap(dstAlpha));
    return;
  }

  void bufferData(int target, var data_OR_size, int usage) {
    if (data_OR_size is ArrayBuffer) {
      _ptr.bufferData(_unwrap(target), _unwrap(data_OR_size), _unwrap(usage));
      return;
    } else {
      if (data_OR_size is ArrayBufferView) {
        _ptr.bufferData(_unwrap(target), _unwrap(data_OR_size), _unwrap(usage));
        return;
      } else {
        if (data_OR_size is int) {
          _ptr.bufferData(_unwrap(target), _unwrap(data_OR_size), _unwrap(usage));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void bufferSubData(int target, int offset, var data) {
    if (data is ArrayBuffer) {
      _ptr.bufferSubData(_unwrap(target), _unwrap(offset), _unwrap(data));
      return;
    } else {
      if (data is ArrayBufferView) {
        _ptr.bufferSubData(_unwrap(target), _unwrap(offset), _unwrap(data));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  int checkFramebufferStatus(int target) {
    return _wrap(_ptr.checkFramebufferStatus(_unwrap(target)));
  }

  void clear(int mask) {
    _ptr.clear(_unwrap(mask));
    return;
  }

  void clearColor(num red, num green, num blue, num alpha) {
    _ptr.clearColor(_unwrap(red), _unwrap(green), _unwrap(blue), _unwrap(alpha));
    return;
  }

  void clearDepth(num depth) {
    _ptr.clearDepth(_unwrap(depth));
    return;
  }

  void clearStencil(int s) {
    _ptr.clearStencil(_unwrap(s));
    return;
  }

  void colorMask(bool red, bool green, bool blue, bool alpha) {
    _ptr.colorMask(_unwrap(red), _unwrap(green), _unwrap(blue), _unwrap(alpha));
    return;
  }

  void compileShader(WebGLShader shader) {
    _ptr.compileShader(_unwrap(shader));
    return;
  }

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, ArrayBufferView data) {
    _ptr.compressedTexImage2D(_unwrap(target), _unwrap(level), _unwrap(internalformat), _unwrap(width), _unwrap(height), _unwrap(border), _unwrap(data));
    return;
  }

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, ArrayBufferView data) {
    _ptr.compressedTexSubImage2D(_unwrap(target), _unwrap(level), _unwrap(xoffset), _unwrap(yoffset), _unwrap(width), _unwrap(height), _unwrap(format), _unwrap(data));
    return;
  }

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) {
    _ptr.copyTexImage2D(_unwrap(target), _unwrap(level), _unwrap(internalformat), _unwrap(x), _unwrap(y), _unwrap(width), _unwrap(height), _unwrap(border));
    return;
  }

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) {
    _ptr.copyTexSubImage2D(_unwrap(target), _unwrap(level), _unwrap(xoffset), _unwrap(yoffset), _unwrap(x), _unwrap(y), _unwrap(width), _unwrap(height));
    return;
  }

  WebGLBuffer createBuffer() {
    return _wrap(_ptr.createBuffer());
  }

  WebGLFramebuffer createFramebuffer() {
    return _wrap(_ptr.createFramebuffer());
  }

  WebGLProgram createProgram() {
    return _wrap(_ptr.createProgram());
  }

  WebGLRenderbuffer createRenderbuffer() {
    return _wrap(_ptr.createRenderbuffer());
  }

  WebGLShader createShader(int type) {
    return _wrap(_ptr.createShader(_unwrap(type)));
  }

  WebGLTexture createTexture() {
    return _wrap(_ptr.createTexture());
  }

  void cullFace(int mode) {
    _ptr.cullFace(_unwrap(mode));
    return;
  }

  void deleteBuffer(WebGLBuffer buffer) {
    _ptr.deleteBuffer(_unwrap(buffer));
    return;
  }

  void deleteFramebuffer(WebGLFramebuffer framebuffer) {
    _ptr.deleteFramebuffer(_unwrap(framebuffer));
    return;
  }

  void deleteProgram(WebGLProgram program) {
    _ptr.deleteProgram(_unwrap(program));
    return;
  }

  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer) {
    _ptr.deleteRenderbuffer(_unwrap(renderbuffer));
    return;
  }

  void deleteShader(WebGLShader shader) {
    _ptr.deleteShader(_unwrap(shader));
    return;
  }

  void deleteTexture(WebGLTexture texture) {
    _ptr.deleteTexture(_unwrap(texture));
    return;
  }

  void depthFunc(int func) {
    _ptr.depthFunc(_unwrap(func));
    return;
  }

  void depthMask(bool flag) {
    _ptr.depthMask(_unwrap(flag));
    return;
  }

  void depthRange(num zNear, num zFar) {
    _ptr.depthRange(_unwrap(zNear), _unwrap(zFar));
    return;
  }

  void detachShader(WebGLProgram program, WebGLShader shader) {
    _ptr.detachShader(_unwrap(program), _unwrap(shader));
    return;
  }

  void disable(int cap) {
    _ptr.disable(_unwrap(cap));
    return;
  }

  void disableVertexAttribArray(int index) {
    _ptr.disableVertexAttribArray(_unwrap(index));
    return;
  }

  void drawArrays(int mode, int first, int count) {
    _ptr.drawArrays(_unwrap(mode), _unwrap(first), _unwrap(count));
    return;
  }

  void drawElements(int mode, int count, int type, int offset) {
    _ptr.drawElements(_unwrap(mode), _unwrap(count), _unwrap(type), _unwrap(offset));
    return;
  }

  void enable(int cap) {
    _ptr.enable(_unwrap(cap));
    return;
  }

  void enableVertexAttribArray(int index) {
    _ptr.enableVertexAttribArray(_unwrap(index));
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
    _ptr.framebufferRenderbuffer(_unwrap(target), _unwrap(attachment), _unwrap(renderbuffertarget), _unwrap(renderbuffer));
    return;
  }

  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level) {
    _ptr.framebufferTexture2D(_unwrap(target), _unwrap(attachment), _unwrap(textarget), _unwrap(texture), _unwrap(level));
    return;
  }

  void frontFace(int mode) {
    _ptr.frontFace(_unwrap(mode));
    return;
  }

  void generateMipmap(int target) {
    _ptr.generateMipmap(_unwrap(target));
    return;
  }

  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index) {
    return _wrap(_ptr.getActiveAttrib(_unwrap(program), _unwrap(index)));
  }

  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index) {
    return _wrap(_ptr.getActiveUniform(_unwrap(program), _unwrap(index)));
  }

  List getAttachedShaders(WebGLProgram program) {
    return _wrap(_ptr.getAttachedShaders(_unwrap(program)));
  }

  int getAttribLocation(WebGLProgram program, String name) {
    return _wrap(_ptr.getAttribLocation(_unwrap(program), _unwrap(name)));
  }

  Object getBufferParameter(int target, int pname) {
    return _wrap(_ptr.getBufferParameter(_unwrap(target), _unwrap(pname)));
  }

  WebGLContextAttributes getContextAttributes() {
    return _wrap(_ptr.getContextAttributes());
  }

  int getError() {
    return _wrap(_ptr.getError());
  }

  Object getExtension(String name) {
    return _wrap(_ptr.getExtension(_unwrap(name)));
  }

  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) {
    return _wrap(_ptr.getFramebufferAttachmentParameter(_unwrap(target), _unwrap(attachment), _unwrap(pname)));
  }

  Object getParameter(int pname) {
    return _wrap(_ptr.getParameter(_unwrap(pname)));
  }

  String getProgramInfoLog(WebGLProgram program) {
    return _wrap(_ptr.getProgramInfoLog(_unwrap(program)));
  }

  Object getProgramParameter(WebGLProgram program, int pname) {
    return _wrap(_ptr.getProgramParameter(_unwrap(program), _unwrap(pname)));
  }

  Object getRenderbufferParameter(int target, int pname) {
    return _wrap(_ptr.getRenderbufferParameter(_unwrap(target), _unwrap(pname)));
  }

  String getShaderInfoLog(WebGLShader shader) {
    return _wrap(_ptr.getShaderInfoLog(_unwrap(shader)));
  }

  Object getShaderParameter(WebGLShader shader, int pname) {
    return _wrap(_ptr.getShaderParameter(_unwrap(shader), _unwrap(pname)));
  }

  String getShaderSource(WebGLShader shader) {
    return _wrap(_ptr.getShaderSource(_unwrap(shader)));
  }

  Object getTexParameter(int target, int pname) {
    return _wrap(_ptr.getTexParameter(_unwrap(target), _unwrap(pname)));
  }

  Object getUniform(WebGLProgram program, WebGLUniformLocation location) {
    return _wrap(_ptr.getUniform(_unwrap(program), _unwrap(location)));
  }

  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) {
    return _wrap(_ptr.getUniformLocation(_unwrap(program), _unwrap(name)));
  }

  Object getVertexAttrib(int index, int pname) {
    return _wrap(_ptr.getVertexAttrib(_unwrap(index), _unwrap(pname)));
  }

  int getVertexAttribOffset(int index, int pname) {
    return _wrap(_ptr.getVertexAttribOffset(_unwrap(index), _unwrap(pname)));
  }

  void hint(int target, int mode) {
    _ptr.hint(_unwrap(target), _unwrap(mode));
    return;
  }

  bool isBuffer(WebGLBuffer buffer) {
    return _wrap(_ptr.isBuffer(_unwrap(buffer)));
  }

  bool isContextLost() {
    return _wrap(_ptr.isContextLost());
  }

  bool isEnabled(int cap) {
    return _wrap(_ptr.isEnabled(_unwrap(cap)));
  }

  bool isFramebuffer(WebGLFramebuffer framebuffer) {
    return _wrap(_ptr.isFramebuffer(_unwrap(framebuffer)));
  }

  bool isProgram(WebGLProgram program) {
    return _wrap(_ptr.isProgram(_unwrap(program)));
  }

  bool isRenderbuffer(WebGLRenderbuffer renderbuffer) {
    return _wrap(_ptr.isRenderbuffer(_unwrap(renderbuffer)));
  }

  bool isShader(WebGLShader shader) {
    return _wrap(_ptr.isShader(_unwrap(shader)));
  }

  bool isTexture(WebGLTexture texture) {
    return _wrap(_ptr.isTexture(_unwrap(texture)));
  }

  void lineWidth(num width) {
    _ptr.lineWidth(_unwrap(width));
    return;
  }

  void linkProgram(WebGLProgram program) {
    _ptr.linkProgram(_unwrap(program));
    return;
  }

  void pixelStorei(int pname, int param) {
    _ptr.pixelStorei(_unwrap(pname), _unwrap(param));
    return;
  }

  void polygonOffset(num factor, num units) {
    _ptr.polygonOffset(_unwrap(factor), _unwrap(units));
    return;
  }

  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels) {
    _ptr.readPixels(_unwrap(x), _unwrap(y), _unwrap(width), _unwrap(height), _unwrap(format), _unwrap(type), _unwrap(pixels));
    return;
  }

  void releaseShaderCompiler() {
    _ptr.releaseShaderCompiler();
    return;
  }

  void renderbufferStorage(int target, int internalformat, int width, int height) {
    _ptr.renderbufferStorage(_unwrap(target), _unwrap(internalformat), _unwrap(width), _unwrap(height));
    return;
  }

  void sampleCoverage(num value, bool invert) {
    _ptr.sampleCoverage(_unwrap(value), _unwrap(invert));
    return;
  }

  void scissor(int x, int y, int width, int height) {
    _ptr.scissor(_unwrap(x), _unwrap(y), _unwrap(width), _unwrap(height));
    return;
  }

  void shaderSource(WebGLShader shader, String string) {
    _ptr.shaderSource(_unwrap(shader), _unwrap(string));
    return;
  }

  void stencilFunc(int func, int ref, int mask) {
    _ptr.stencilFunc(_unwrap(func), _unwrap(ref), _unwrap(mask));
    return;
  }

  void stencilFuncSeparate(int face, int func, int ref, int mask) {
    _ptr.stencilFuncSeparate(_unwrap(face), _unwrap(func), _unwrap(ref), _unwrap(mask));
    return;
  }

  void stencilMask(int mask) {
    _ptr.stencilMask(_unwrap(mask));
    return;
  }

  void stencilMaskSeparate(int face, int mask) {
    _ptr.stencilMaskSeparate(_unwrap(face), _unwrap(mask));
    return;
  }

  void stencilOp(int fail, int zfail, int zpass) {
    _ptr.stencilOp(_unwrap(fail), _unwrap(zfail), _unwrap(zpass));
    return;
  }

  void stencilOpSeparate(int face, int fail, int zfail, int zpass) {
    _ptr.stencilOpSeparate(_unwrap(face), _unwrap(fail), _unwrap(zfail), _unwrap(zpass));
    return;
  }

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels_OR_video, [int format = null, int type = null, ArrayBufferView pixels = null]) {
    if (border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData) {
      if (format === null) {
        if (type === null) {
          if (pixels === null) {
            _ptr.texImage2D(_unwrap(target), _unwrap(level), _unwrap(internalformat), _unwrap(format_OR_width), _unwrap(height_OR_type), _unwrap(border_OR_canvas_OR_image_OR_pixels_OR_video));
            return;
          }
        }
      }
    } else {
      if (border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement) {
        if (format === null) {
          if (type === null) {
            if (pixels === null) {
              _ptr.texImage2D(_unwrap(target), _unwrap(level), _unwrap(internalformat), _unwrap(format_OR_width), _unwrap(height_OR_type), _unwrap(border_OR_canvas_OR_image_OR_pixels_OR_video));
              return;
            }
          }
        }
      } else {
        if (border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement) {
          if (format === null) {
            if (type === null) {
              if (pixels === null) {
                _ptr.texImage2D(_unwrap(target), _unwrap(level), _unwrap(internalformat), _unwrap(format_OR_width), _unwrap(height_OR_type), _unwrap(border_OR_canvas_OR_image_OR_pixels_OR_video));
                return;
              }
            }
          }
        } else {
          if (border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement) {
            if (format === null) {
              if (type === null) {
                if (pixels === null) {
                  _ptr.texImage2D(_unwrap(target), _unwrap(level), _unwrap(internalformat), _unwrap(format_OR_width), _unwrap(height_OR_type), _unwrap(border_OR_canvas_OR_image_OR_pixels_OR_video));
                  return;
                }
              }
            }
          } else {
            if (border_OR_canvas_OR_image_OR_pixels_OR_video is int) {
              _ptr.texImage2D(_unwrap(target), _unwrap(level), _unwrap(internalformat), _unwrap(format_OR_width), _unwrap(height_OR_type), _unwrap(border_OR_canvas_OR_image_OR_pixels_OR_video), _unwrap(format), _unwrap(type), _unwrap(pixels));
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void texParameterf(int target, int pname, num param) {
    _ptr.texParameterf(_unwrap(target), _unwrap(pname), _unwrap(param));
    return;
  }

  void texParameteri(int target, int pname, int param) {
    _ptr.texParameteri(_unwrap(target), _unwrap(pname), _unwrap(param));
    return;
  }

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels_OR_video, [int type = null, ArrayBufferView pixels = null]) {
    if (canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData) {
      if (type === null) {
        if (pixels === null) {
          _ptr.texSubImage2D(_unwrap(target), _unwrap(level), _unwrap(xoffset), _unwrap(yoffset), _unwrap(format_OR_width), _unwrap(height_OR_type), _unwrap(canvas_OR_format_OR_image_OR_pixels_OR_video));
          return;
        }
      }
    } else {
      if (canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement) {
        if (type === null) {
          if (pixels === null) {
            _ptr.texSubImage2D(_unwrap(target), _unwrap(level), _unwrap(xoffset), _unwrap(yoffset), _unwrap(format_OR_width), _unwrap(height_OR_type), _unwrap(canvas_OR_format_OR_image_OR_pixels_OR_video));
            return;
          }
        }
      } else {
        if (canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement) {
          if (type === null) {
            if (pixels === null) {
              _ptr.texSubImage2D(_unwrap(target), _unwrap(level), _unwrap(xoffset), _unwrap(yoffset), _unwrap(format_OR_width), _unwrap(height_OR_type), _unwrap(canvas_OR_format_OR_image_OR_pixels_OR_video));
              return;
            }
          }
        } else {
          if (canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement) {
            if (type === null) {
              if (pixels === null) {
                _ptr.texSubImage2D(_unwrap(target), _unwrap(level), _unwrap(xoffset), _unwrap(yoffset), _unwrap(format_OR_width), _unwrap(height_OR_type), _unwrap(canvas_OR_format_OR_image_OR_pixels_OR_video));
                return;
              }
            }
          } else {
            if (canvas_OR_format_OR_image_OR_pixels_OR_video is int) {
              _ptr.texSubImage2D(_unwrap(target), _unwrap(level), _unwrap(xoffset), _unwrap(yoffset), _unwrap(format_OR_width), _unwrap(height_OR_type), _unwrap(canvas_OR_format_OR_image_OR_pixels_OR_video), _unwrap(type), _unwrap(pixels));
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void uniform1f(WebGLUniformLocation location, num x) {
    _ptr.uniform1f(_unwrap(location), _unwrap(x));
    return;
  }

  void uniform1fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform1fv(_unwrap(location), _unwrap(v));
    return;
  }

  void uniform1i(WebGLUniformLocation location, int x) {
    _ptr.uniform1i(_unwrap(location), _unwrap(x));
    return;
  }

  void uniform1iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform1iv(_unwrap(location), _unwrap(v));
    return;
  }

  void uniform2f(WebGLUniformLocation location, num x, num y) {
    _ptr.uniform2f(_unwrap(location), _unwrap(x), _unwrap(y));
    return;
  }

  void uniform2fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform2fv(_unwrap(location), _unwrap(v));
    return;
  }

  void uniform2i(WebGLUniformLocation location, int x, int y) {
    _ptr.uniform2i(_unwrap(location), _unwrap(x), _unwrap(y));
    return;
  }

  void uniform2iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform2iv(_unwrap(location), _unwrap(v));
    return;
  }

  void uniform3f(WebGLUniformLocation location, num x, num y, num z) {
    _ptr.uniform3f(_unwrap(location), _unwrap(x), _unwrap(y), _unwrap(z));
    return;
  }

  void uniform3fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform3fv(_unwrap(location), _unwrap(v));
    return;
  }

  void uniform3i(WebGLUniformLocation location, int x, int y, int z) {
    _ptr.uniform3i(_unwrap(location), _unwrap(x), _unwrap(y), _unwrap(z));
    return;
  }

  void uniform3iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform3iv(_unwrap(location), _unwrap(v));
    return;
  }

  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w) {
    _ptr.uniform4f(_unwrap(location), _unwrap(x), _unwrap(y), _unwrap(z), _unwrap(w));
    return;
  }

  void uniform4fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform4fv(_unwrap(location), _unwrap(v));
    return;
  }

  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w) {
    _ptr.uniform4i(_unwrap(location), _unwrap(x), _unwrap(y), _unwrap(z), _unwrap(w));
    return;
  }

  void uniform4iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform4iv(_unwrap(location), _unwrap(v));
    return;
  }

  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _ptr.uniformMatrix2fv(_unwrap(location), _unwrap(transpose), _unwrap(array));
    return;
  }

  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _ptr.uniformMatrix3fv(_unwrap(location), _unwrap(transpose), _unwrap(array));
    return;
  }

  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _ptr.uniformMatrix4fv(_unwrap(location), _unwrap(transpose), _unwrap(array));
    return;
  }

  void useProgram(WebGLProgram program) {
    _ptr.useProgram(_unwrap(program));
    return;
  }

  void validateProgram(WebGLProgram program) {
    _ptr.validateProgram(_unwrap(program));
    return;
  }

  void vertexAttrib1f(int indx, num x) {
    _ptr.vertexAttrib1f(_unwrap(indx), _unwrap(x));
    return;
  }

  void vertexAttrib1fv(int indx, Float32Array values) {
    _ptr.vertexAttrib1fv(_unwrap(indx), _unwrap(values));
    return;
  }

  void vertexAttrib2f(int indx, num x, num y) {
    _ptr.vertexAttrib2f(_unwrap(indx), _unwrap(x), _unwrap(y));
    return;
  }

  void vertexAttrib2fv(int indx, Float32Array values) {
    _ptr.vertexAttrib2fv(_unwrap(indx), _unwrap(values));
    return;
  }

  void vertexAttrib3f(int indx, num x, num y, num z) {
    _ptr.vertexAttrib3f(_unwrap(indx), _unwrap(x), _unwrap(y), _unwrap(z));
    return;
  }

  void vertexAttrib3fv(int indx, Float32Array values) {
    _ptr.vertexAttrib3fv(_unwrap(indx), _unwrap(values));
    return;
  }

  void vertexAttrib4f(int indx, num x, num y, num z, num w) {
    _ptr.vertexAttrib4f(_unwrap(indx), _unwrap(x), _unwrap(y), _unwrap(z), _unwrap(w));
    return;
  }

  void vertexAttrib4fv(int indx, Float32Array values) {
    _ptr.vertexAttrib4fv(_unwrap(indx), _unwrap(values));
    return;
  }

  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) {
    _ptr.vertexAttribPointer(_unwrap(indx), _unwrap(size), _unwrap(type), _unwrap(normalized), _unwrap(stride), _unwrap(offset));
    return;
  }

  void viewport(int x, int y, int width, int height) {
    _ptr.viewport(_unwrap(x), _unwrap(y), _unwrap(width), _unwrap(height));
    return;
  }
}
