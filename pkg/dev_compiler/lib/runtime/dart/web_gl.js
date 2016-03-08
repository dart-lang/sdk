dart_library.library('dart/web_gl', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/html_common',
  'dart/html',
  'dart/_interceptors',
  'dart/typed_data',
  'dart/_metadata',
  'dart/_js_helper'
], /* Lazy imports */[
], function(exports, dart, core, html_common, html, _interceptors, typed_data, _metadata, _js_helper) {
  'use strict';
  let dartx = dart.dartx;
  const _getContextAttributes_1 = Symbol('_getContextAttributes_1');
  const _texImage2D_1 = Symbol('_texImage2D_1');
  const _texImage2D_2 = Symbol('_texImage2D_2');
  const _texImage2D_3 = Symbol('_texImage2D_3');
  const _texImage2D_4 = Symbol('_texImage2D_4');
  const _texImage2D_5 = Symbol('_texImage2D_5');
  const _texImage2DImageData_1 = Symbol('_texImage2DImageData_1');
  const _texSubImage2D_1 = Symbol('_texSubImage2D_1');
  const _texSubImage2D_2 = Symbol('_texSubImage2D_2');
  const _texSubImage2D_3 = Symbol('_texSubImage2D_3');
  const _texSubImage2D_4 = Symbol('_texSubImage2D_4');
  const _texSubImage2D_5 = Symbol('_texSubImage2D_5');
  const _texSubImage2DImageData_1 = Symbol('_texSubImage2DImageData_1');
  dart.defineExtensionNames([
    'activeTexture',
    'attachShader',
    'bindAttribLocation',
    'bindBuffer',
    'bindFramebuffer',
    'bindRenderbuffer',
    'bindTexture',
    'blendColor',
    'blendEquation',
    'blendEquationSeparate',
    'blendFunc',
    'blendFuncSeparate',
    'bufferByteData',
    'bufferData',
    'bufferDataTyped',
    'bufferSubByteData',
    'bufferSubData',
    'bufferSubDataTyped',
    'checkFramebufferStatus',
    'clear',
    'clearColor',
    'clearDepth',
    'clearStencil',
    'colorMask',
    'compileShader',
    'compressedTexImage2D',
    'compressedTexSubImage2D',
    'copyTexImage2D',
    'copyTexSubImage2D',
    'createBuffer',
    'createFramebuffer',
    'createProgram',
    'createRenderbuffer',
    'createShader',
    'createTexture',
    'cullFace',
    'deleteBuffer',
    'deleteFramebuffer',
    'deleteProgram',
    'deleteRenderbuffer',
    'deleteShader',
    'deleteTexture',
    'depthFunc',
    'depthMask',
    'depthRange',
    'detachShader',
    'disable',
    'disableVertexAttribArray',
    'drawArrays',
    'drawElements',
    'enable',
    'enableVertexAttribArray',
    'finish',
    'flush',
    'framebufferRenderbuffer',
    'framebufferTexture2D',
    'frontFace',
    'generateMipmap',
    'getActiveAttrib',
    'getActiveUniform',
    'getAttachedShaders',
    'getAttribLocation',
    'getBufferParameter',
    'getContextAttributes',
    'getError',
    'getExtension',
    'getFramebufferAttachmentParameter',
    'getParameter',
    'getProgramInfoLog',
    'getProgramParameter',
    'getRenderbufferParameter',
    'getShaderInfoLog',
    'getShaderParameter',
    'getShaderPrecisionFormat',
    'getShaderSource',
    'getSupportedExtensions',
    'getTexParameter',
    'getUniform',
    'getUniformLocation',
    'getVertexAttrib',
    'getVertexAttribOffset',
    'hint',
    'isBuffer',
    'isContextLost',
    'isEnabled',
    'isFramebuffer',
    'isProgram',
    'isRenderbuffer',
    'isShader',
    'isTexture',
    'lineWidth',
    'linkProgram',
    'pixelStorei',
    'polygonOffset',
    'readPixels',
    'renderbufferStorage',
    'sampleCoverage',
    'scissor',
    'shaderSource',
    'stencilFunc',
    'stencilFuncSeparate',
    'stencilMask',
    'stencilMaskSeparate',
    'stencilOp',
    'stencilOpSeparate',
    'texImage2D',
    'texImage2DCanvas',
    'texImage2DImage',
    'texImage2DImageData',
    'texImage2DVideo',
    'texParameterf',
    'texParameteri',
    'texSubImage2D',
    'texSubImage2DCanvas',
    'texSubImage2DImage',
    'texSubImage2DImageData',
    'texSubImage2DVideo',
    'uniform1f',
    'uniform1fv',
    'uniform1i',
    'uniform1iv',
    'uniform2f',
    'uniform2fv',
    'uniform2i',
    'uniform2iv',
    'uniform3f',
    'uniform3fv',
    'uniform3i',
    'uniform3iv',
    'uniform4f',
    'uniform4fv',
    'uniform4i',
    'uniform4iv',
    'uniformMatrix2fv',
    'uniformMatrix3fv',
    'uniformMatrix4fv',
    'useProgram',
    'validateProgram',
    'vertexAttrib1f',
    'vertexAttrib1fv',
    'vertexAttrib2f',
    'vertexAttrib2fv',
    'vertexAttrib3f',
    'vertexAttrib3fv',
    'vertexAttrib4f',
    'vertexAttrib4fv',
    'vertexAttribPointer',
    'viewport',
    'texImage2DUntyped',
    'texImage2DTyped',
    'texSubImage2DUntyped',
    'texSubImage2DTyped',
    'canvas',
    'drawingBufferHeight',
    'drawingBufferWidth'
  ]);
  class RenderingContext extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static get supported() {
      return !!window.WebGLRenderingContext;
    }
    get [dartx.canvas]() {
      return this.canvas;
    }
    get [dartx.drawingBufferHeight]() {
      return this.drawingBufferHeight;
    }
    get [dartx.drawingBufferWidth]() {
      return this.drawingBufferWidth;
    }
    [dartx.activeTexture](texture) {
      return this.activeTexture(texture);
    }
    [dartx.attachShader](program, shader) {
      return this.attachShader(program, shader);
    }
    [dartx.bindAttribLocation](program, index, name) {
      return this.bindAttribLocation(program, index, name);
    }
    [dartx.bindBuffer](target, buffer) {
      return this.bindBuffer(target, buffer);
    }
    [dartx.bindFramebuffer](target, framebuffer) {
      return this.bindFramebuffer(target, framebuffer);
    }
    [dartx.bindRenderbuffer](target, renderbuffer) {
      return this.bindRenderbuffer(target, renderbuffer);
    }
    [dartx.bindTexture](target, texture) {
      return this.bindTexture(target, texture);
    }
    [dartx.blendColor](red, green, blue, alpha) {
      return this.blendColor(red, green, blue, alpha);
    }
    [dartx.blendEquation](mode) {
      return this.blendEquation(mode);
    }
    [dartx.blendEquationSeparate](modeRGB, modeAlpha) {
      return this.blendEquationSeparate(modeRGB, modeAlpha);
    }
    [dartx.blendFunc](sfactor, dfactor) {
      return this.blendFunc(sfactor, dfactor);
    }
    [dartx.blendFuncSeparate](srcRGB, dstRGB, srcAlpha, dstAlpha) {
      return this.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
    }
    [dartx.bufferByteData](target, data, usage) {
      return this.bufferData(target, data, usage);
    }
    [dartx.bufferData](target, data_OR_size, usage) {
      return this.bufferData(target, data_OR_size, usage);
    }
    [dartx.bufferDataTyped](target, data, usage) {
      return this.bufferData(target, data, usage);
    }
    [dartx.bufferSubByteData](target, offset, data) {
      return this.bufferSubData(target, offset, data);
    }
    [dartx.bufferSubData](target, offset, data) {
      return this.bufferSubData(target, offset, data);
    }
    [dartx.bufferSubDataTyped](target, offset, data) {
      return this.bufferSubData(target, offset, data);
    }
    [dartx.checkFramebufferStatus](target) {
      return this.checkFramebufferStatus(target);
    }
    [dartx.clear](mask) {
      return this.clear(mask);
    }
    [dartx.clearColor](red, green, blue, alpha) {
      return this.clearColor(red, green, blue, alpha);
    }
    [dartx.clearDepth](depth) {
      return this.clearDepth(depth);
    }
    [dartx.clearStencil](s) {
      return this.clearStencil(s);
    }
    [dartx.colorMask](red, green, blue, alpha) {
      return this.colorMask(red, green, blue, alpha);
    }
    [dartx.compileShader](shader) {
      return this.compileShader(shader);
    }
    [dartx.compressedTexImage2D](target, level, internalformat, width, height, border, data) {
      return this.compressedTexImage2D(target, level, internalformat, width, height, border, data);
    }
    [dartx.compressedTexSubImage2D](target, level, xoffset, yoffset, width, height, format, data) {
      return this.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, data);
    }
    [dartx.copyTexImage2D](target, level, internalformat, x, y, width, height, border) {
      return this.copyTexImage2D(target, level, internalformat, x, y, width, height, border);
    }
    [dartx.copyTexSubImage2D](target, level, xoffset, yoffset, x, y, width, height) {
      return this.copyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
    }
    [dartx.createBuffer]() {
      return this.createBuffer();
    }
    [dartx.createFramebuffer]() {
      return this.createFramebuffer();
    }
    [dartx.createProgram]() {
      return this.createProgram();
    }
    [dartx.createRenderbuffer]() {
      return this.createRenderbuffer();
    }
    [dartx.createShader](type) {
      return this.createShader(type);
    }
    [dartx.createTexture]() {
      return this.createTexture();
    }
    [dartx.cullFace](mode) {
      return this.cullFace(mode);
    }
    [dartx.deleteBuffer](buffer) {
      return this.deleteBuffer(buffer);
    }
    [dartx.deleteFramebuffer](framebuffer) {
      return this.deleteFramebuffer(framebuffer);
    }
    [dartx.deleteProgram](program) {
      return this.deleteProgram(program);
    }
    [dartx.deleteRenderbuffer](renderbuffer) {
      return this.deleteRenderbuffer(renderbuffer);
    }
    [dartx.deleteShader](shader) {
      return this.deleteShader(shader);
    }
    [dartx.deleteTexture](texture) {
      return this.deleteTexture(texture);
    }
    [dartx.depthFunc](func) {
      return this.depthFunc(func);
    }
    [dartx.depthMask](flag) {
      return this.depthMask(flag);
    }
    [dartx.depthRange](zNear, zFar) {
      return this.depthRange(zNear, zFar);
    }
    [dartx.detachShader](program, shader) {
      return this.detachShader(program, shader);
    }
    [dartx.disable](cap) {
      return this.disable(cap);
    }
    [dartx.disableVertexAttribArray](index) {
      return this.disableVertexAttribArray(index);
    }
    [dartx.drawArrays](mode, first, count) {
      return this.drawArrays(mode, first, count);
    }
    [dartx.drawElements](mode, count, type, offset) {
      return this.drawElements(mode, count, type, offset);
    }
    [dartx.enable](cap) {
      return this.enable(cap);
    }
    [dartx.enableVertexAttribArray](index) {
      return this.enableVertexAttribArray(index);
    }
    [dartx.finish]() {
      return this.finish();
    }
    [dartx.flush]() {
      return this.flush();
    }
    [dartx.framebufferRenderbuffer](target, attachment, renderbuffertarget, renderbuffer) {
      return this.framebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer);
    }
    [dartx.framebufferTexture2D](target, attachment, textarget, texture, level) {
      return this.framebufferTexture2D(target, attachment, textarget, texture, level);
    }
    [dartx.frontFace](mode) {
      return this.frontFace(mode);
    }
    [dartx.generateMipmap](target) {
      return this.generateMipmap(target);
    }
    [dartx.getActiveAttrib](program, index) {
      return this.getActiveAttrib(program, index);
    }
    [dartx.getActiveUniform](program, index) {
      return this.getActiveUniform(program, index);
    }
    [dartx.getAttachedShaders](program) {
      return this.getAttachedShaders(program);
    }
    [dartx.getAttribLocation](program, name) {
      return this.getAttribLocation(program, name);
    }
    [dartx.getBufferParameter](target, pname) {
      return this.getBufferParameter(target, pname);
    }
    [dartx.getContextAttributes]() {
      return html_common.convertNativeToDart_ContextAttributes(this[_getContextAttributes_1]());
    }
    [_getContextAttributes_1]() {
      return this.getContextAttributes();
    }
    [dartx.getError]() {
      return this.getError();
    }
    [dartx.getExtension](name) {
      return this.getExtension(name);
    }
    [dartx.getFramebufferAttachmentParameter](target, attachment, pname) {
      return this.getFramebufferAttachmentParameter(target, attachment, pname);
    }
    [dartx.getParameter](pname) {
      return this.getParameter(pname);
    }
    [dartx.getProgramInfoLog](program) {
      return this.getProgramInfoLog(program);
    }
    [dartx.getProgramParameter](program, pname) {
      return this.getProgramParameter(program, pname);
    }
    [dartx.getRenderbufferParameter](target, pname) {
      return this.getRenderbufferParameter(target, pname);
    }
    [dartx.getShaderInfoLog](shader) {
      return this.getShaderInfoLog(shader);
    }
    [dartx.getShaderParameter](shader, pname) {
      return this.getShaderParameter(shader, pname);
    }
    [dartx.getShaderPrecisionFormat](shadertype, precisiontype) {
      return this.getShaderPrecisionFormat(shadertype, precisiontype);
    }
    [dartx.getShaderSource](shader) {
      return this.getShaderSource(shader);
    }
    [dartx.getSupportedExtensions]() {
      return this.getSupportedExtensions();
    }
    [dartx.getTexParameter](target, pname) {
      return this.getTexParameter(target, pname);
    }
    [dartx.getUniform](program, location) {
      return this.getUniform(program, location);
    }
    [dartx.getUniformLocation](program, name) {
      return this.getUniformLocation(program, name);
    }
    [dartx.getVertexAttrib](index, pname) {
      return this.getVertexAttrib(index, pname);
    }
    [dartx.getVertexAttribOffset](index, pname) {
      return this.getVertexAttribOffset(index, pname);
    }
    [dartx.hint](target, mode) {
      return this.hint(target, mode);
    }
    [dartx.isBuffer](buffer) {
      return this.isBuffer(buffer);
    }
    [dartx.isContextLost]() {
      return this.isContextLost();
    }
    [dartx.isEnabled](cap) {
      return this.isEnabled(cap);
    }
    [dartx.isFramebuffer](framebuffer) {
      return this.isFramebuffer(framebuffer);
    }
    [dartx.isProgram](program) {
      return this.isProgram(program);
    }
    [dartx.isRenderbuffer](renderbuffer) {
      return this.isRenderbuffer(renderbuffer);
    }
    [dartx.isShader](shader) {
      return this.isShader(shader);
    }
    [dartx.isTexture](texture) {
      return this.isTexture(texture);
    }
    [dartx.lineWidth](width) {
      return this.lineWidth(width);
    }
    [dartx.linkProgram](program) {
      return this.linkProgram(program);
    }
    [dartx.pixelStorei](pname, param) {
      return this.pixelStorei(pname, param);
    }
    [dartx.polygonOffset](factor, units) {
      return this.polygonOffset(factor, units);
    }
    [dartx.readPixels](x, y, width, height, format, type, pixels) {
      return this.readPixels(x, y, width, height, format, type, pixels);
    }
    [dartx.renderbufferStorage](target, internalformat, width, height) {
      return this.renderbufferStorage(target, internalformat, width, height);
    }
    [dartx.sampleCoverage](value, invert) {
      return this.sampleCoverage(value, invert);
    }
    [dartx.scissor](x, y, width, height) {
      return this.scissor(x, y, width, height);
    }
    [dartx.shaderSource](shader, string) {
      return this.shaderSource(shader, string);
    }
    [dartx.stencilFunc](func, ref, mask) {
      return this.stencilFunc(func, ref, mask);
    }
    [dartx.stencilFuncSeparate](face, func, ref, mask) {
      return this.stencilFuncSeparate(face, func, ref, mask);
    }
    [dartx.stencilMask](mask) {
      return this.stencilMask(mask);
    }
    [dartx.stencilMaskSeparate](face, mask) {
      return this.stencilMaskSeparate(face, mask);
    }
    [dartx.stencilOp](fail, zfail, zpass) {
      return this.stencilOp(fail, zfail, zpass);
    }
    [dartx.stencilOpSeparate](face, fail, zfail, zpass) {
      return this.stencilOpSeparate(face, fail, zfail, zpass);
    }
    [dartx.texImage2D](target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels) {
      if (format === void 0) format = null;
      if (type === void 0) type = null;
      if (pixels === void 0) pixels = null;
      if (pixels != null && type != null && format != null && typeof border_OR_canvas_OR_image_OR_pixels_OR_video == 'number') {
        this[_texImage2D_1](target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
        return;
      }
      if ((dart.is(border_OR_canvas_OR_image_OR_pixels_OR_video, html.ImageData) || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && format == null && type == null && pixels == null) {
        let pixels_1 = html_common.convertDartToNative_ImageData(dart.as(border_OR_canvas_OR_image_OR_pixels_OR_video, html.ImageData));
        this[_texImage2D_2](target, level, internalformat, format_OR_width, height_OR_type, pixels_1);
        return;
      }
      if (dart.is(border_OR_canvas_OR_image_OR_pixels_OR_video, html.ImageElement) && format == null && type == null && pixels == null) {
        this[_texImage2D_3](target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
        return;
      }
      if (dart.is(border_OR_canvas_OR_image_OR_pixels_OR_video, html.CanvasElement) && format == null && type == null && pixels == null) {
        this[_texImage2D_4](target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
        return;
      }
      if (dart.is(border_OR_canvas_OR_image_OR_pixels_OR_video, html.VideoElement) && format == null && type == null && pixels == null) {
        this[_texImage2D_5](target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
        return;
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [_texImage2D_1](target, level, internalformat, width, height, border, format, type, pixels) {
      return this.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
    }
    [_texImage2D_2](target, level, internalformat, format, type, pixels) {
      return this.texImage2D(target, level, internalformat, format, type, pixels);
    }
    [_texImage2D_3](target, level, internalformat, format, type, image) {
      return this.texImage2D(target, level, internalformat, format, type, image);
    }
    [_texImage2D_4](target, level, internalformat, format, type, canvas) {
      return this.texImage2D(target, level, internalformat, format, type, canvas);
    }
    [_texImage2D_5](target, level, internalformat, format, type, video) {
      return this.texImage2D(target, level, internalformat, format, type, video);
    }
    [dartx.texImage2DCanvas](target, level, internalformat, format, type, canvas) {
      return this.texImage2D(target, level, internalformat, format, type, canvas);
    }
    [dartx.texImage2DImage](target, level, internalformat, format, type, image) {
      return this.texImage2D(target, level, internalformat, format, type, image);
    }
    [dartx.texImage2DImageData](target, level, internalformat, format, type, pixels) {
      let pixels_1 = html_common.convertDartToNative_ImageData(pixels);
      this[_texImage2DImageData_1](target, level, internalformat, format, type, pixels_1);
      return;
    }
    [_texImage2DImageData_1](target, level, internalformat, format, type, pixels) {
      return this.texImage2D(target, level, internalformat, format, type, pixels);
    }
    [dartx.texImage2DVideo](target, level, internalformat, format, type, video) {
      return this.texImage2D(target, level, internalformat, format, type, video);
    }
    [dartx.texParameterf](target, pname, param) {
      return this.texParameterf(target, pname, param);
    }
    [dartx.texParameteri](target, pname, param) {
      return this.texParameteri(target, pname, param);
    }
    [dartx.texSubImage2D](target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels) {
      if (type === void 0) type = null;
      if (pixels === void 0) pixels = null;
      if (pixels != null && type != null && typeof canvas_OR_format_OR_image_OR_pixels_OR_video == 'number') {
        this[_texSubImage2D_1](target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
        return;
      }
      if ((dart.is(canvas_OR_format_OR_image_OR_pixels_OR_video, html.ImageData) || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && type == null && pixels == null) {
        let pixels_1 = html_common.convertDartToNative_ImageData(dart.as(canvas_OR_format_OR_image_OR_pixels_OR_video, html.ImageData));
        this[_texSubImage2D_2](target, level, xoffset, yoffset, format_OR_width, height_OR_type, pixels_1);
        return;
      }
      if (dart.is(canvas_OR_format_OR_image_OR_pixels_OR_video, html.ImageElement) && type == null && pixels == null) {
        this[_texSubImage2D_3](target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
        return;
      }
      if (dart.is(canvas_OR_format_OR_image_OR_pixels_OR_video, html.CanvasElement) && type == null && pixels == null) {
        this[_texSubImage2D_4](target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
        return;
      }
      if (dart.is(canvas_OR_format_OR_image_OR_pixels_OR_video, html.VideoElement) && type == null && pixels == null) {
        this[_texSubImage2D_5](target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
        return;
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [_texSubImage2D_1](target, level, xoffset, yoffset, width, height, format, type, pixels) {
      return this.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
    }
    [_texSubImage2D_2](target, level, xoffset, yoffset, format, type, pixels) {
      return this.texSubImage2D(target, level, xoffset, yoffset, format, type, pixels);
    }
    [_texSubImage2D_3](target, level, xoffset, yoffset, format, type, image) {
      return this.texSubImage2D(target, level, xoffset, yoffset, format, type, image);
    }
    [_texSubImage2D_4](target, level, xoffset, yoffset, format, type, canvas) {
      return this.texSubImage2D(target, level, xoffset, yoffset, format, type, canvas);
    }
    [_texSubImage2D_5](target, level, xoffset, yoffset, format, type, video) {
      return this.texSubImage2D(target, level, xoffset, yoffset, format, type, video);
    }
    [dartx.texSubImage2DCanvas](target, level, xoffset, yoffset, format, type, canvas) {
      return this.texSubImage2D(target, level, xoffset, yoffset, format, type, canvas);
    }
    [dartx.texSubImage2DImage](target, level, xoffset, yoffset, format, type, image) {
      return this.texSubImage2D(target, level, xoffset, yoffset, format, type, image);
    }
    [dartx.texSubImage2DImageData](target, level, xoffset, yoffset, format, type, pixels) {
      let pixels_1 = html_common.convertDartToNative_ImageData(pixels);
      this[_texSubImage2DImageData_1](target, level, xoffset, yoffset, format, type, pixels_1);
      return;
    }
    [_texSubImage2DImageData_1](target, level, xoffset, yoffset, format, type, pixels) {
      return this.texSubImage2D(target, level, xoffset, yoffset, format, type, pixels);
    }
    [dartx.texSubImage2DVideo](target, level, xoffset, yoffset, format, type, video) {
      return this.texSubImage2D(target, level, xoffset, yoffset, format, type, video);
    }
    [dartx.uniform1f](location, x) {
      return this.uniform1f(location, x);
    }
    [dartx.uniform1fv](location, v) {
      return this.uniform1fv(location, v);
    }
    [dartx.uniform1i](location, x) {
      return this.uniform1i(location, x);
    }
    [dartx.uniform1iv](location, v) {
      return this.uniform1iv(location, v);
    }
    [dartx.uniform2f](location, x, y) {
      return this.uniform2f(location, x, y);
    }
    [dartx.uniform2fv](location, v) {
      return this.uniform2fv(location, v);
    }
    [dartx.uniform2i](location, x, y) {
      return this.uniform2i(location, x, y);
    }
    [dartx.uniform2iv](location, v) {
      return this.uniform2iv(location, v);
    }
    [dartx.uniform3f](location, x, y, z) {
      return this.uniform3f(location, x, y, z);
    }
    [dartx.uniform3fv](location, v) {
      return this.uniform3fv(location, v);
    }
    [dartx.uniform3i](location, x, y, z) {
      return this.uniform3i(location, x, y, z);
    }
    [dartx.uniform3iv](location, v) {
      return this.uniform3iv(location, v);
    }
    [dartx.uniform4f](location, x, y, z, w) {
      return this.uniform4f(location, x, y, z, w);
    }
    [dartx.uniform4fv](location, v) {
      return this.uniform4fv(location, v);
    }
    [dartx.uniform4i](location, x, y, z, w) {
      return this.uniform4i(location, x, y, z, w);
    }
    [dartx.uniform4iv](location, v) {
      return this.uniform4iv(location, v);
    }
    [dartx.uniformMatrix2fv](location, transpose, array) {
      return this.uniformMatrix2fv(location, transpose, array);
    }
    [dartx.uniformMatrix3fv](location, transpose, array) {
      return this.uniformMatrix3fv(location, transpose, array);
    }
    [dartx.uniformMatrix4fv](location, transpose, array) {
      return this.uniformMatrix4fv(location, transpose, array);
    }
    [dartx.useProgram](program) {
      return this.useProgram(program);
    }
    [dartx.validateProgram](program) {
      return this.validateProgram(program);
    }
    [dartx.vertexAttrib1f](indx, x) {
      return this.vertexAttrib1f(indx, x);
    }
    [dartx.vertexAttrib1fv](indx, values) {
      return this.vertexAttrib1fv(indx, values);
    }
    [dartx.vertexAttrib2f](indx, x, y) {
      return this.vertexAttrib2f(indx, x, y);
    }
    [dartx.vertexAttrib2fv](indx, values) {
      return this.vertexAttrib2fv(indx, values);
    }
    [dartx.vertexAttrib3f](indx, x, y, z) {
      return this.vertexAttrib3f(indx, x, y, z);
    }
    [dartx.vertexAttrib3fv](indx, values) {
      return this.vertexAttrib3fv(indx, values);
    }
    [dartx.vertexAttrib4f](indx, x, y, z, w) {
      return this.vertexAttrib4f(indx, x, y, z, w);
    }
    [dartx.vertexAttrib4fv](indx, values) {
      return this.vertexAttrib4fv(indx, values);
    }
    [dartx.vertexAttribPointer](indx, size, type, normalized, stride, offset) {
      return this.vertexAttribPointer(indx, size, type, normalized, stride, offset);
    }
    [dartx.viewport](x, y, width, height) {
      return this.viewport(x, y, width, height);
    }
    [dartx.texImage2DUntyped](targetTexture, levelOfDetail, internalFormat, format, type, data) {
      return this.texImage2D(targetTexture, levelOfDetail, internalFormat, format, type, data);
    }
    [dartx.texImage2DTyped](targetTexture, levelOfDetail, internalFormat, width, height, border, format, type, data) {
      return this.texImage2D(targetTexture, levelOfDetail, internalFormat, width, height, border, format, type, data);
    }
    [dartx.texSubImage2DUntyped](targetTexture, levelOfDetail, xOffset, yOffset, format, type, data) {
      return this.texSubImage2D(targetTexture, levelOfDetail, xOffset, yOffset, format, type, data);
    }
    [dartx.texSubImage2DTyped](targetTexture, levelOfDetail, xOffset, yOffset, width, height, border, format, type, data) {
      return this.texSubImage2D(targetTexture, levelOfDetail, xOffset, yOffset, width, height, border, format, type, data);
    }
  }
  RenderingContext[dart.implements] = () => [html.CanvasRenderingContext];
  dart.setSignature(RenderingContext, {
    constructors: () => ({_: [RenderingContext, []]}),
    methods: () => ({
      [dartx.activeTexture]: [dart.void, [core.int]],
      [dartx.attachShader]: [dart.void, [Program, Shader]],
      [dartx.bindAttribLocation]: [dart.void, [Program, core.int, core.String]],
      [dartx.bindBuffer]: [dart.void, [core.int, Buffer]],
      [dartx.bindFramebuffer]: [dart.void, [core.int, Framebuffer]],
      [dartx.bindRenderbuffer]: [dart.void, [core.int, Renderbuffer]],
      [dartx.bindTexture]: [dart.void, [core.int, Texture]],
      [dartx.blendColor]: [dart.void, [core.num, core.num, core.num, core.num]],
      [dartx.blendEquation]: [dart.void, [core.int]],
      [dartx.blendEquationSeparate]: [dart.void, [core.int, core.int]],
      [dartx.blendFunc]: [dart.void, [core.int, core.int]],
      [dartx.blendFuncSeparate]: [dart.void, [core.int, core.int, core.int, core.int]],
      [dartx.bufferByteData]: [dart.void, [core.int, typed_data.ByteBuffer, core.int]],
      [dartx.bufferData]: [dart.void, [core.int, dart.dynamic, core.int]],
      [dartx.bufferDataTyped]: [dart.void, [core.int, typed_data.TypedData, core.int]],
      [dartx.bufferSubByteData]: [dart.void, [core.int, core.int, typed_data.ByteBuffer]],
      [dartx.bufferSubData]: [dart.void, [core.int, core.int, dart.dynamic]],
      [dartx.bufferSubDataTyped]: [dart.void, [core.int, core.int, typed_data.TypedData]],
      [dartx.checkFramebufferStatus]: [core.int, [core.int]],
      [dartx.clear]: [dart.void, [core.int]],
      [dartx.clearColor]: [dart.void, [core.num, core.num, core.num, core.num]],
      [dartx.clearDepth]: [dart.void, [core.num]],
      [dartx.clearStencil]: [dart.void, [core.int]],
      [dartx.colorMask]: [dart.void, [core.bool, core.bool, core.bool, core.bool]],
      [dartx.compileShader]: [dart.void, [Shader]],
      [dartx.compressedTexImage2D]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, typed_data.TypedData]],
      [dartx.compressedTexSubImage2D]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, core.int, typed_data.TypedData]],
      [dartx.copyTexImage2D]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, core.int, core.int]],
      [dartx.copyTexSubImage2D]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, core.int, core.int]],
      [dartx.createBuffer]: [Buffer, []],
      [dartx.createFramebuffer]: [Framebuffer, []],
      [dartx.createProgram]: [Program, []],
      [dartx.createRenderbuffer]: [Renderbuffer, []],
      [dartx.createShader]: [Shader, [core.int]],
      [dartx.createTexture]: [Texture, []],
      [dartx.cullFace]: [dart.void, [core.int]],
      [dartx.deleteBuffer]: [dart.void, [Buffer]],
      [dartx.deleteFramebuffer]: [dart.void, [Framebuffer]],
      [dartx.deleteProgram]: [dart.void, [Program]],
      [dartx.deleteRenderbuffer]: [dart.void, [Renderbuffer]],
      [dartx.deleteShader]: [dart.void, [Shader]],
      [dartx.deleteTexture]: [dart.void, [Texture]],
      [dartx.depthFunc]: [dart.void, [core.int]],
      [dartx.depthMask]: [dart.void, [core.bool]],
      [dartx.depthRange]: [dart.void, [core.num, core.num]],
      [dartx.detachShader]: [dart.void, [Program, Shader]],
      [dartx.disable]: [dart.void, [core.int]],
      [dartx.disableVertexAttribArray]: [dart.void, [core.int]],
      [dartx.drawArrays]: [dart.void, [core.int, core.int, core.int]],
      [dartx.drawElements]: [dart.void, [core.int, core.int, core.int, core.int]],
      [dartx.enable]: [dart.void, [core.int]],
      [dartx.enableVertexAttribArray]: [dart.void, [core.int]],
      [dartx.finish]: [dart.void, []],
      [dartx.flush]: [dart.void, []],
      [dartx.framebufferRenderbuffer]: [dart.void, [core.int, core.int, core.int, Renderbuffer]],
      [dartx.framebufferTexture2D]: [dart.void, [core.int, core.int, core.int, Texture, core.int]],
      [dartx.frontFace]: [dart.void, [core.int]],
      [dartx.generateMipmap]: [dart.void, [core.int]],
      [dartx.getActiveAttrib]: [ActiveInfo, [Program, core.int]],
      [dartx.getActiveUniform]: [ActiveInfo, [Program, core.int]],
      [dartx.getAttachedShaders]: [core.List$(Shader), [Program]],
      [dartx.getAttribLocation]: [core.int, [Program, core.String]],
      [dartx.getBufferParameter]: [core.Object, [core.int, core.int]],
      [dartx.getContextAttributes]: [ContextAttributes, []],
      [_getContextAttributes_1]: [dart.dynamic, []],
      [dartx.getError]: [core.int, []],
      [dartx.getExtension]: [core.Object, [core.String]],
      [dartx.getFramebufferAttachmentParameter]: [core.Object, [core.int, core.int, core.int]],
      [dartx.getParameter]: [core.Object, [core.int]],
      [dartx.getProgramInfoLog]: [core.String, [Program]],
      [dartx.getProgramParameter]: [core.Object, [Program, core.int]],
      [dartx.getRenderbufferParameter]: [core.Object, [core.int, core.int]],
      [dartx.getShaderInfoLog]: [core.String, [Shader]],
      [dartx.getShaderParameter]: [core.Object, [Shader, core.int]],
      [dartx.getShaderPrecisionFormat]: [ShaderPrecisionFormat, [core.int, core.int]],
      [dartx.getShaderSource]: [core.String, [Shader]],
      [dartx.getSupportedExtensions]: [core.List$(core.String), []],
      [dartx.getTexParameter]: [core.Object, [core.int, core.int]],
      [dartx.getUniform]: [core.Object, [Program, UniformLocation]],
      [dartx.getUniformLocation]: [UniformLocation, [Program, core.String]],
      [dartx.getVertexAttrib]: [core.Object, [core.int, core.int]],
      [dartx.getVertexAttribOffset]: [core.int, [core.int, core.int]],
      [dartx.hint]: [dart.void, [core.int, core.int]],
      [dartx.isBuffer]: [core.bool, [Buffer]],
      [dartx.isContextLost]: [core.bool, []],
      [dartx.isEnabled]: [core.bool, [core.int]],
      [dartx.isFramebuffer]: [core.bool, [Framebuffer]],
      [dartx.isProgram]: [core.bool, [Program]],
      [dartx.isRenderbuffer]: [core.bool, [Renderbuffer]],
      [dartx.isShader]: [core.bool, [Shader]],
      [dartx.isTexture]: [core.bool, [Texture]],
      [dartx.lineWidth]: [dart.void, [core.num]],
      [dartx.linkProgram]: [dart.void, [Program]],
      [dartx.pixelStorei]: [dart.void, [core.int, core.int]],
      [dartx.polygonOffset]: [dart.void, [core.num, core.num]],
      [dartx.readPixels]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, typed_data.TypedData]],
      [dartx.renderbufferStorage]: [dart.void, [core.int, core.int, core.int, core.int]],
      [dartx.sampleCoverage]: [dart.void, [core.num, core.bool]],
      [dartx.scissor]: [dart.void, [core.int, core.int, core.int, core.int]],
      [dartx.shaderSource]: [dart.void, [Shader, core.String]],
      [dartx.stencilFunc]: [dart.void, [core.int, core.int, core.int]],
      [dartx.stencilFuncSeparate]: [dart.void, [core.int, core.int, core.int, core.int]],
      [dartx.stencilMask]: [dart.void, [core.int]],
      [dartx.stencilMaskSeparate]: [dart.void, [core.int, core.int]],
      [dartx.stencilOp]: [dart.void, [core.int, core.int, core.int]],
      [dartx.stencilOpSeparate]: [dart.void, [core.int, core.int, core.int, core.int]],
      [dartx.texImage2D]: [dart.void, [core.int, core.int, core.int, core.int, core.int, dart.dynamic], [core.int, core.int, typed_data.TypedData]],
      [_texImage2D_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, core.int, dart.dynamic, dart.dynamic, typed_data.TypedData]],
      [_texImage2D_2]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]],
      [_texImage2D_3]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, html.ImageElement]],
      [_texImage2D_4]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, html.CanvasElement]],
      [_texImage2D_5]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, html.VideoElement]],
      [dartx.texImage2DCanvas]: [dart.void, [core.int, core.int, core.int, core.int, core.int, html.CanvasElement]],
      [dartx.texImage2DImage]: [dart.void, [core.int, core.int, core.int, core.int, core.int, html.ImageElement]],
      [dartx.texImage2DImageData]: [dart.void, [core.int, core.int, core.int, core.int, core.int, html.ImageData]],
      [_texImage2DImageData_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]],
      [dartx.texImage2DVideo]: [dart.void, [core.int, core.int, core.int, core.int, core.int, html.VideoElement]],
      [dartx.texParameterf]: [dart.void, [core.int, core.int, core.num]],
      [dartx.texParameteri]: [dart.void, [core.int, core.int, core.int]],
      [dartx.texSubImage2D]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, dart.dynamic], [core.int, typed_data.TypedData]],
      [_texSubImage2D_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, core.int, dart.dynamic, typed_data.TypedData]],
      [_texSubImage2D_2]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]],
      [_texSubImage2D_3]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, html.ImageElement]],
      [_texSubImage2D_4]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, html.CanvasElement]],
      [_texSubImage2D_5]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, html.VideoElement]],
      [dartx.texSubImage2DCanvas]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, html.CanvasElement]],
      [dartx.texSubImage2DImage]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, html.ImageElement]],
      [dartx.texSubImage2DImageData]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, html.ImageData]],
      [_texSubImage2DImageData_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]],
      [dartx.texSubImage2DVideo]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, html.VideoElement]],
      [dartx.uniform1f]: [dart.void, [UniformLocation, core.num]],
      [dartx.uniform1fv]: [dart.void, [UniformLocation, typed_data.Float32List]],
      [dartx.uniform1i]: [dart.void, [UniformLocation, core.int]],
      [dartx.uniform1iv]: [dart.void, [UniformLocation, typed_data.Int32List]],
      [dartx.uniform2f]: [dart.void, [UniformLocation, core.num, core.num]],
      [dartx.uniform2fv]: [dart.void, [UniformLocation, typed_data.Float32List]],
      [dartx.uniform2i]: [dart.void, [UniformLocation, core.int, core.int]],
      [dartx.uniform2iv]: [dart.void, [UniformLocation, typed_data.Int32List]],
      [dartx.uniform3f]: [dart.void, [UniformLocation, core.num, core.num, core.num]],
      [dartx.uniform3fv]: [dart.void, [UniformLocation, typed_data.Float32List]],
      [dartx.uniform3i]: [dart.void, [UniformLocation, core.int, core.int, core.int]],
      [dartx.uniform3iv]: [dart.void, [UniformLocation, typed_data.Int32List]],
      [dartx.uniform4f]: [dart.void, [UniformLocation, core.num, core.num, core.num, core.num]],
      [dartx.uniform4fv]: [dart.void, [UniformLocation, typed_data.Float32List]],
      [dartx.uniform4i]: [dart.void, [UniformLocation, core.int, core.int, core.int, core.int]],
      [dartx.uniform4iv]: [dart.void, [UniformLocation, typed_data.Int32List]],
      [dartx.uniformMatrix2fv]: [dart.void, [UniformLocation, core.bool, typed_data.Float32List]],
      [dartx.uniformMatrix3fv]: [dart.void, [UniformLocation, core.bool, typed_data.Float32List]],
      [dartx.uniformMatrix4fv]: [dart.void, [UniformLocation, core.bool, typed_data.Float32List]],
      [dartx.useProgram]: [dart.void, [Program]],
      [dartx.validateProgram]: [dart.void, [Program]],
      [dartx.vertexAttrib1f]: [dart.void, [core.int, core.num]],
      [dartx.vertexAttrib1fv]: [dart.void, [core.int, typed_data.Float32List]],
      [dartx.vertexAttrib2f]: [dart.void, [core.int, core.num, core.num]],
      [dartx.vertexAttrib2fv]: [dart.void, [core.int, typed_data.Float32List]],
      [dartx.vertexAttrib3f]: [dart.void, [core.int, core.num, core.num, core.num]],
      [dartx.vertexAttrib3fv]: [dart.void, [core.int, typed_data.Float32List]],
      [dartx.vertexAttrib4f]: [dart.void, [core.int, core.num, core.num, core.num, core.num]],
      [dartx.vertexAttrib4fv]: [dart.void, [core.int, typed_data.Float32List]],
      [dartx.vertexAttribPointer]: [dart.void, [core.int, core.int, core.int, core.bool, core.int, core.int]],
      [dartx.viewport]: [dart.void, [core.int, core.int, core.int, core.int]],
      [dartx.texImage2DUntyped]: [dart.void, [core.int, core.int, core.int, core.int, core.int, dart.dynamic]],
      [dartx.texImage2DTyped]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, core.int, core.int, typed_data.TypedData]],
      [dartx.texSubImage2DUntyped]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, dart.dynamic]],
      [dartx.texSubImage2DTyped]: [dart.void, [core.int, core.int, core.int, core.int, core.int, core.int, core.int, core.int, core.int, typed_data.TypedData]]
    })
  });
  RenderingContext[dart.metadata] = () => [dart.const(new _metadata.DomName('WebGLRenderingContext')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.Experimental()), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("WebGLRenderingContext"))];
  RenderingContext.ACTIVE_ATTRIBUTES = 35721;
  RenderingContext.ACTIVE_TEXTURE = 34016;
  RenderingContext.ACTIVE_UNIFORMS = 35718;
  RenderingContext.ALIASED_LINE_WIDTH_RANGE = 33902;
  RenderingContext.ALIASED_POINT_SIZE_RANGE = 33901;
  RenderingContext.ALPHA = 6406;
  RenderingContext.ALPHA_BITS = 3413;
  RenderingContext.ALWAYS = 519;
  RenderingContext.ARRAY_BUFFER = 34962;
  RenderingContext.ARRAY_BUFFER_BINDING = 34964;
  RenderingContext.ATTACHED_SHADERS = 35717;
  RenderingContext.BACK = 1029;
  RenderingContext.BLEND = 3042;
  RenderingContext.BLEND_COLOR = 32773;
  RenderingContext.BLEND_DST_ALPHA = 32970;
  RenderingContext.BLEND_DST_RGB = 32968;
  RenderingContext.BLEND_EQUATION = 32777;
  RenderingContext.BLEND_EQUATION_ALPHA = 34877;
  RenderingContext.BLEND_EQUATION_RGB = 32777;
  RenderingContext.BLEND_SRC_ALPHA = 32971;
  RenderingContext.BLEND_SRC_RGB = 32969;
  RenderingContext.BLUE_BITS = 3412;
  RenderingContext.BOOL = 35670;
  RenderingContext.BOOL_VEC2 = 35671;
  RenderingContext.BOOL_VEC3 = 35672;
  RenderingContext.BOOL_VEC4 = 35673;
  RenderingContext.BROWSER_DEFAULT_WEBGL = 37444;
  RenderingContext.BUFFER_SIZE = 34660;
  RenderingContext.BUFFER_USAGE = 34661;
  RenderingContext.BYTE = 5120;
  RenderingContext.CCW = 2305;
  RenderingContext.CLAMP_TO_EDGE = 33071;
  RenderingContext.COLOR_ATTACHMENT0 = 36064;
  RenderingContext.COLOR_BUFFER_BIT = 16384;
  RenderingContext.COLOR_CLEAR_VALUE = 3106;
  RenderingContext.COLOR_WRITEMASK = 3107;
  RenderingContext.COMPILE_STATUS = 35713;
  RenderingContext.COMPRESSED_TEXTURE_FORMATS = 34467;
  RenderingContext.CONSTANT_ALPHA = 32771;
  RenderingContext.CONSTANT_COLOR = 32769;
  RenderingContext.CONTEXT_LOST_WEBGL = 37442;
  RenderingContext.CULL_FACE = 2884;
  RenderingContext.CULL_FACE_MODE = 2885;
  RenderingContext.CURRENT_PROGRAM = 35725;
  RenderingContext.CURRENT_VERTEX_ATTRIB = 34342;
  RenderingContext.CW = 2304;
  RenderingContext.DECR = 7683;
  RenderingContext.DECR_WRAP = 34056;
  RenderingContext.DELETE_STATUS = 35712;
  RenderingContext.DEPTH_ATTACHMENT = 36096;
  RenderingContext.DEPTH_BITS = 3414;
  RenderingContext.DEPTH_BUFFER_BIT = 256;
  RenderingContext.DEPTH_CLEAR_VALUE = 2931;
  RenderingContext.DEPTH_COMPONENT = 6402;
  RenderingContext.DEPTH_COMPONENT16 = 33189;
  RenderingContext.DEPTH_FUNC = 2932;
  RenderingContext.DEPTH_RANGE = 2928;
  RenderingContext.DEPTH_STENCIL = 34041;
  RenderingContext.DEPTH_STENCIL_ATTACHMENT = 33306;
  RenderingContext.DEPTH_TEST = 2929;
  RenderingContext.DEPTH_WRITEMASK = 2930;
  RenderingContext.DITHER = 3024;
  RenderingContext.DONT_CARE = 4352;
  RenderingContext.DST_ALPHA = 772;
  RenderingContext.DST_COLOR = 774;
  RenderingContext.DYNAMIC_DRAW = 35048;
  RenderingContext.ELEMENT_ARRAY_BUFFER = 34963;
  RenderingContext.ELEMENT_ARRAY_BUFFER_BINDING = 34965;
  RenderingContext.EQUAL = 514;
  RenderingContext.FASTEST = 4353;
  RenderingContext.FLOAT = 5126;
  RenderingContext.FLOAT_MAT2 = 35674;
  RenderingContext.FLOAT_MAT3 = 35675;
  RenderingContext.FLOAT_MAT4 = 35676;
  RenderingContext.FLOAT_VEC2 = 35664;
  RenderingContext.FLOAT_VEC3 = 35665;
  RenderingContext.FLOAT_VEC4 = 35666;
  RenderingContext.FRAGMENT_SHADER = 35632;
  RenderingContext.FRAMEBUFFER = 36160;
  RenderingContext.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 36049;
  RenderingContext.FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 36048;
  RenderingContext.FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 36051;
  RenderingContext.FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 36050;
  RenderingContext.FRAMEBUFFER_BINDING = 36006;
  RenderingContext.FRAMEBUFFER_COMPLETE = 36053;
  RenderingContext.FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 36054;
  RenderingContext.FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 36057;
  RenderingContext.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 36055;
  RenderingContext.FRAMEBUFFER_UNSUPPORTED = 36061;
  RenderingContext.FRONT = 1028;
  RenderingContext.FRONT_AND_BACK = 1032;
  RenderingContext.FRONT_FACE = 2886;
  RenderingContext.FUNC_ADD = 32774;
  RenderingContext.FUNC_REVERSE_SUBTRACT = 32779;
  RenderingContext.FUNC_SUBTRACT = 32778;
  RenderingContext.GENERATE_MIPMAP_HINT = 33170;
  RenderingContext.GEQUAL = 518;
  RenderingContext.GREATER = 516;
  RenderingContext.GREEN_BITS = 3411;
  RenderingContext.HIGH_FLOAT = 36338;
  RenderingContext.HIGH_INT = 36341;
  RenderingContext.IMPLEMENTATION_COLOR_READ_FORMAT = 35739;
  RenderingContext.IMPLEMENTATION_COLOR_READ_TYPE = 35738;
  RenderingContext.INCR = 7682;
  RenderingContext.INCR_WRAP = 34055;
  RenderingContext.INT = 5124;
  RenderingContext.INT_VEC2 = 35667;
  RenderingContext.INT_VEC3 = 35668;
  RenderingContext.INT_VEC4 = 35669;
  RenderingContext.INVALID_ENUM = 1280;
  RenderingContext.INVALID_FRAMEBUFFER_OPERATION = 1286;
  RenderingContext.INVALID_OPERATION = 1282;
  RenderingContext.INVALID_VALUE = 1281;
  RenderingContext.INVERT = 5386;
  RenderingContext.KEEP = 7680;
  RenderingContext.LEQUAL = 515;
  RenderingContext.LESS = 513;
  RenderingContext.LINEAR = 9729;
  RenderingContext.LINEAR_MIPMAP_LINEAR = 9987;
  RenderingContext.LINEAR_MIPMAP_NEAREST = 9985;
  RenderingContext.LINES = 1;
  RenderingContext.LINE_LOOP = 2;
  RenderingContext.LINE_STRIP = 3;
  RenderingContext.LINE_WIDTH = 2849;
  RenderingContext.LINK_STATUS = 35714;
  RenderingContext.LOW_FLOAT = 36336;
  RenderingContext.LOW_INT = 36339;
  RenderingContext.LUMINANCE = 6409;
  RenderingContext.LUMINANCE_ALPHA = 6410;
  RenderingContext.MAX_COMBINED_TEXTURE_IMAGE_UNITS = 35661;
  RenderingContext.MAX_CUBE_MAP_TEXTURE_SIZE = 34076;
  RenderingContext.MAX_FRAGMENT_UNIFORM_VECTORS = 36349;
  RenderingContext.MAX_RENDERBUFFER_SIZE = 34024;
  RenderingContext.MAX_TEXTURE_IMAGE_UNITS = 34930;
  RenderingContext.MAX_TEXTURE_SIZE = 3379;
  RenderingContext.MAX_VARYING_VECTORS = 36348;
  RenderingContext.MAX_VERTEX_ATTRIBS = 34921;
  RenderingContext.MAX_VERTEX_TEXTURE_IMAGE_UNITS = 35660;
  RenderingContext.MAX_VERTEX_UNIFORM_VECTORS = 36347;
  RenderingContext.MAX_VIEWPORT_DIMS = 3386;
  RenderingContext.MEDIUM_FLOAT = 36337;
  RenderingContext.MEDIUM_INT = 36340;
  RenderingContext.MIRRORED_REPEAT = 33648;
  RenderingContext.NEAREST = 9728;
  RenderingContext.NEAREST_MIPMAP_LINEAR = 9986;
  RenderingContext.NEAREST_MIPMAP_NEAREST = 9984;
  RenderingContext.NEVER = 512;
  RenderingContext.NICEST = 4354;
  RenderingContext.NONE = 0;
  RenderingContext.NOTEQUAL = 517;
  RenderingContext.NO_ERROR = 0;
  RenderingContext.ONE = 1;
  RenderingContext.ONE_MINUS_CONSTANT_ALPHA = 32772;
  RenderingContext.ONE_MINUS_CONSTANT_COLOR = 32770;
  RenderingContext.ONE_MINUS_DST_ALPHA = 773;
  RenderingContext.ONE_MINUS_DST_COLOR = 775;
  RenderingContext.ONE_MINUS_SRC_ALPHA = 771;
  RenderingContext.ONE_MINUS_SRC_COLOR = 769;
  RenderingContext.OUT_OF_MEMORY = 1285;
  RenderingContext.PACK_ALIGNMENT = 3333;
  RenderingContext.POINTS = 0;
  RenderingContext.POLYGON_OFFSET_FACTOR = 32824;
  RenderingContext.POLYGON_OFFSET_FILL = 32823;
  RenderingContext.POLYGON_OFFSET_UNITS = 10752;
  RenderingContext.RED_BITS = 3410;
  RenderingContext.RENDERBUFFER = 36161;
  RenderingContext.RENDERBUFFER_ALPHA_SIZE = 36179;
  RenderingContext.RENDERBUFFER_BINDING = 36007;
  RenderingContext.RENDERBUFFER_BLUE_SIZE = 36178;
  RenderingContext.RENDERBUFFER_DEPTH_SIZE = 36180;
  RenderingContext.RENDERBUFFER_GREEN_SIZE = 36177;
  RenderingContext.RENDERBUFFER_HEIGHT = 36163;
  RenderingContext.RENDERBUFFER_INTERNAL_FORMAT = 36164;
  RenderingContext.RENDERBUFFER_RED_SIZE = 36176;
  RenderingContext.RENDERBUFFER_STENCIL_SIZE = 36181;
  RenderingContext.RENDERBUFFER_WIDTH = 36162;
  RenderingContext.RENDERER = 7937;
  RenderingContext.REPEAT = 10497;
  RenderingContext.REPLACE = 7681;
  RenderingContext.RGB = 6407;
  RenderingContext.RGB565 = 36194;
  RenderingContext.RGB5_A1 = 32855;
  RenderingContext.RGBA = 6408;
  RenderingContext.RGBA4 = 32854;
  RenderingContext.SAMPLER_2D = 35678;
  RenderingContext.SAMPLER_CUBE = 35680;
  RenderingContext.SAMPLES = 32937;
  RenderingContext.SAMPLE_ALPHA_TO_COVERAGE = 32926;
  RenderingContext.SAMPLE_BUFFERS = 32936;
  RenderingContext.SAMPLE_COVERAGE = 32928;
  RenderingContext.SAMPLE_COVERAGE_INVERT = 32939;
  RenderingContext.SAMPLE_COVERAGE_VALUE = 32938;
  RenderingContext.SCISSOR_BOX = 3088;
  RenderingContext.SCISSOR_TEST = 3089;
  RenderingContext.SHADER_TYPE = 35663;
  RenderingContext.SHADING_LANGUAGE_VERSION = 35724;
  RenderingContext.SHORT = 5122;
  RenderingContext.SRC_ALPHA = 770;
  RenderingContext.SRC_ALPHA_SATURATE = 776;
  RenderingContext.SRC_COLOR = 768;
  RenderingContext.STATIC_DRAW = 35044;
  RenderingContext.STENCIL_ATTACHMENT = 36128;
  RenderingContext.STENCIL_BACK_FAIL = 34817;
  RenderingContext.STENCIL_BACK_FUNC = 34816;
  RenderingContext.STENCIL_BACK_PASS_DEPTH_FAIL = 34818;
  RenderingContext.STENCIL_BACK_PASS_DEPTH_PASS = 34819;
  RenderingContext.STENCIL_BACK_REF = 36003;
  RenderingContext.STENCIL_BACK_VALUE_MASK = 36004;
  RenderingContext.STENCIL_BACK_WRITEMASK = 36005;
  RenderingContext.STENCIL_BITS = 3415;
  RenderingContext.STENCIL_BUFFER_BIT = 1024;
  RenderingContext.STENCIL_CLEAR_VALUE = 2961;
  RenderingContext.STENCIL_FAIL = 2964;
  RenderingContext.STENCIL_FUNC = 2962;
  RenderingContext.STENCIL_INDEX = 6401;
  RenderingContext.STENCIL_INDEX8 = 36168;
  RenderingContext.STENCIL_PASS_DEPTH_FAIL = 2965;
  RenderingContext.STENCIL_PASS_DEPTH_PASS = 2966;
  RenderingContext.STENCIL_REF = 2967;
  RenderingContext.STENCIL_TEST = 2960;
  RenderingContext.STENCIL_VALUE_MASK = 2963;
  RenderingContext.STENCIL_WRITEMASK = 2968;
  RenderingContext.STREAM_DRAW = 35040;
  RenderingContext.SUBPIXEL_BITS = 3408;
  RenderingContext.TEXTURE = 5890;
  RenderingContext.TEXTURE0 = 33984;
  RenderingContext.TEXTURE1 = 33985;
  RenderingContext.TEXTURE10 = 33994;
  RenderingContext.TEXTURE11 = 33995;
  RenderingContext.TEXTURE12 = 33996;
  RenderingContext.TEXTURE13 = 33997;
  RenderingContext.TEXTURE14 = 33998;
  RenderingContext.TEXTURE15 = 33999;
  RenderingContext.TEXTURE16 = 34000;
  RenderingContext.TEXTURE17 = 34001;
  RenderingContext.TEXTURE18 = 34002;
  RenderingContext.TEXTURE19 = 34003;
  RenderingContext.TEXTURE2 = 33986;
  RenderingContext.TEXTURE20 = 34004;
  RenderingContext.TEXTURE21 = 34005;
  RenderingContext.TEXTURE22 = 34006;
  RenderingContext.TEXTURE23 = 34007;
  RenderingContext.TEXTURE24 = 34008;
  RenderingContext.TEXTURE25 = 34009;
  RenderingContext.TEXTURE26 = 34010;
  RenderingContext.TEXTURE27 = 34011;
  RenderingContext.TEXTURE28 = 34012;
  RenderingContext.TEXTURE29 = 34013;
  RenderingContext.TEXTURE3 = 33987;
  RenderingContext.TEXTURE30 = 34014;
  RenderingContext.TEXTURE31 = 34015;
  RenderingContext.TEXTURE4 = 33988;
  RenderingContext.TEXTURE5 = 33989;
  RenderingContext.TEXTURE6 = 33990;
  RenderingContext.TEXTURE7 = 33991;
  RenderingContext.TEXTURE8 = 33992;
  RenderingContext.TEXTURE9 = 33993;
  RenderingContext.TEXTURE_2D = 3553;
  RenderingContext.TEXTURE_BINDING_2D = 32873;
  RenderingContext.TEXTURE_BINDING_CUBE_MAP = 34068;
  RenderingContext.TEXTURE_CUBE_MAP = 34067;
  RenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_X = 34070;
  RenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_Y = 34072;
  RenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_Z = 34074;
  RenderingContext.TEXTURE_CUBE_MAP_POSITIVE_X = 34069;
  RenderingContext.TEXTURE_CUBE_MAP_POSITIVE_Y = 34071;
  RenderingContext.TEXTURE_CUBE_MAP_POSITIVE_Z = 34073;
  RenderingContext.TEXTURE_MAG_FILTER = 10240;
  RenderingContext.TEXTURE_MIN_FILTER = 10241;
  RenderingContext.TEXTURE_WRAP_S = 10242;
  RenderingContext.TEXTURE_WRAP_T = 10243;
  RenderingContext.TRIANGLES = 4;
  RenderingContext.TRIANGLE_FAN = 6;
  RenderingContext.TRIANGLE_STRIP = 5;
  RenderingContext.UNPACK_ALIGNMENT = 3317;
  RenderingContext.UNPACK_COLORSPACE_CONVERSION_WEBGL = 37443;
  RenderingContext.UNPACK_FLIP_Y_WEBGL = 37440;
  RenderingContext.UNPACK_PREMULTIPLY_ALPHA_WEBGL = 37441;
  RenderingContext.UNSIGNED_BYTE = 5121;
  RenderingContext.UNSIGNED_INT = 5125;
  RenderingContext.UNSIGNED_SHORT = 5123;
  RenderingContext.UNSIGNED_SHORT_4_4_4_4 = 32819;
  RenderingContext.UNSIGNED_SHORT_5_5_5_1 = 32820;
  RenderingContext.UNSIGNED_SHORT_5_6_5 = 33635;
  RenderingContext.VALIDATE_STATUS = 35715;
  RenderingContext.VENDOR = 7936;
  RenderingContext.VERSION = 7938;
  RenderingContext.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 34975;
  RenderingContext.VERTEX_ATTRIB_ARRAY_ENABLED = 34338;
  RenderingContext.VERTEX_ATTRIB_ARRAY_NORMALIZED = 34922;
  RenderingContext.VERTEX_ATTRIB_ARRAY_POINTER = 34373;
  RenderingContext.VERTEX_ATTRIB_ARRAY_SIZE = 34339;
  RenderingContext.VERTEX_ATTRIB_ARRAY_STRIDE = 34340;
  RenderingContext.VERTEX_ATTRIB_ARRAY_TYPE = 34341;
  RenderingContext.VERTEX_SHADER = 35633;
  RenderingContext.VIEWPORT = 2978;
  RenderingContext.ZERO = 0;
  dart.registerExtension(dart.global.WebGLRenderingContext, RenderingContext);
  const ACTIVE_ATTRIBUTES = RenderingContext.ACTIVE_ATTRIBUTES;
  const ACTIVE_TEXTURE = RenderingContext.ACTIVE_TEXTURE;
  const ACTIVE_UNIFORMS = RenderingContext.ACTIVE_UNIFORMS;
  const ALIASED_LINE_WIDTH_RANGE = RenderingContext.ALIASED_LINE_WIDTH_RANGE;
  const ALIASED_POINT_SIZE_RANGE = RenderingContext.ALIASED_POINT_SIZE_RANGE;
  const ALPHA = RenderingContext.ALPHA;
  const ALPHA_BITS = RenderingContext.ALPHA_BITS;
  const ALWAYS = RenderingContext.ALWAYS;
  const ARRAY_BUFFER = RenderingContext.ARRAY_BUFFER;
  const ARRAY_BUFFER_BINDING = RenderingContext.ARRAY_BUFFER_BINDING;
  const ATTACHED_SHADERS = RenderingContext.ATTACHED_SHADERS;
  const BACK = RenderingContext.BACK;
  const BLEND = RenderingContext.BLEND;
  const BLEND_COLOR = RenderingContext.BLEND_COLOR;
  const BLEND_DST_ALPHA = RenderingContext.BLEND_DST_ALPHA;
  const BLEND_DST_RGB = RenderingContext.BLEND_DST_RGB;
  const BLEND_EQUATION = RenderingContext.BLEND_EQUATION;
  const BLEND_EQUATION_ALPHA = RenderingContext.BLEND_EQUATION_ALPHA;
  const BLEND_EQUATION_RGB = RenderingContext.BLEND_EQUATION_RGB;
  const BLEND_SRC_ALPHA = RenderingContext.BLEND_SRC_ALPHA;
  const BLEND_SRC_RGB = RenderingContext.BLEND_SRC_RGB;
  const BLUE_BITS = RenderingContext.BLUE_BITS;
  const BOOL = RenderingContext.BOOL;
  const BOOL_VEC2 = RenderingContext.BOOL_VEC2;
  const BOOL_VEC3 = RenderingContext.BOOL_VEC3;
  const BOOL_VEC4 = RenderingContext.BOOL_VEC4;
  const BROWSER_DEFAULT_WEBGL = RenderingContext.BROWSER_DEFAULT_WEBGL;
  const BUFFER_SIZE = RenderingContext.BUFFER_SIZE;
  const BUFFER_USAGE = RenderingContext.BUFFER_USAGE;
  const BYTE = RenderingContext.BYTE;
  const CCW = RenderingContext.CCW;
  const CLAMP_TO_EDGE = RenderingContext.CLAMP_TO_EDGE;
  const COLOR_ATTACHMENT0 = RenderingContext.COLOR_ATTACHMENT0;
  const COLOR_BUFFER_BIT = RenderingContext.COLOR_BUFFER_BIT;
  const COLOR_CLEAR_VALUE = RenderingContext.COLOR_CLEAR_VALUE;
  const COLOR_WRITEMASK = RenderingContext.COLOR_WRITEMASK;
  const COMPILE_STATUS = RenderingContext.COMPILE_STATUS;
  const COMPRESSED_TEXTURE_FORMATS = RenderingContext.COMPRESSED_TEXTURE_FORMATS;
  const CONSTANT_ALPHA = RenderingContext.CONSTANT_ALPHA;
  const CONSTANT_COLOR = RenderingContext.CONSTANT_COLOR;
  const CONTEXT_LOST_WEBGL = RenderingContext.CONTEXT_LOST_WEBGL;
  const CULL_FACE = RenderingContext.CULL_FACE;
  const CULL_FACE_MODE = RenderingContext.CULL_FACE_MODE;
  const CURRENT_PROGRAM = RenderingContext.CURRENT_PROGRAM;
  const CURRENT_VERTEX_ATTRIB = RenderingContext.CURRENT_VERTEX_ATTRIB;
  const CW = RenderingContext.CW;
  const DECR = RenderingContext.DECR;
  const DECR_WRAP = RenderingContext.DECR_WRAP;
  const DELETE_STATUS = RenderingContext.DELETE_STATUS;
  const DEPTH_ATTACHMENT = RenderingContext.DEPTH_ATTACHMENT;
  const DEPTH_BITS = RenderingContext.DEPTH_BITS;
  const DEPTH_BUFFER_BIT = RenderingContext.DEPTH_BUFFER_BIT;
  const DEPTH_CLEAR_VALUE = RenderingContext.DEPTH_CLEAR_VALUE;
  const DEPTH_COMPONENT = RenderingContext.DEPTH_COMPONENT;
  const DEPTH_COMPONENT16 = RenderingContext.DEPTH_COMPONENT16;
  const DEPTH_FUNC = RenderingContext.DEPTH_FUNC;
  const DEPTH_RANGE = RenderingContext.DEPTH_RANGE;
  const DEPTH_STENCIL = RenderingContext.DEPTH_STENCIL;
  const DEPTH_STENCIL_ATTACHMENT = RenderingContext.DEPTH_STENCIL_ATTACHMENT;
  const DEPTH_TEST = RenderingContext.DEPTH_TEST;
  const DEPTH_WRITEMASK = RenderingContext.DEPTH_WRITEMASK;
  const DITHER = RenderingContext.DITHER;
  const DONT_CARE = RenderingContext.DONT_CARE;
  const DST_ALPHA = RenderingContext.DST_ALPHA;
  const DST_COLOR = RenderingContext.DST_COLOR;
  const DYNAMIC_DRAW = RenderingContext.DYNAMIC_DRAW;
  const ELEMENT_ARRAY_BUFFER = RenderingContext.ELEMENT_ARRAY_BUFFER;
  const ELEMENT_ARRAY_BUFFER_BINDING = RenderingContext.ELEMENT_ARRAY_BUFFER_BINDING;
  const EQUAL = RenderingContext.EQUAL;
  const FASTEST = RenderingContext.FASTEST;
  const FLOAT = RenderingContext.FLOAT;
  const FLOAT_MAT2 = RenderingContext.FLOAT_MAT2;
  const FLOAT_MAT3 = RenderingContext.FLOAT_MAT3;
  const FLOAT_MAT4 = RenderingContext.FLOAT_MAT4;
  const FLOAT_VEC2 = RenderingContext.FLOAT_VEC2;
  const FLOAT_VEC3 = RenderingContext.FLOAT_VEC3;
  const FLOAT_VEC4 = RenderingContext.FLOAT_VEC4;
  const FRAGMENT_SHADER = RenderingContext.FRAGMENT_SHADER;
  const FRAMEBUFFER = RenderingContext.FRAMEBUFFER;
  const FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = RenderingContext.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME;
  const FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = RenderingContext.FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE;
  const FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = RenderingContext.FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE;
  const FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = RenderingContext.FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL;
  const FRAMEBUFFER_BINDING = RenderingContext.FRAMEBUFFER_BINDING;
  const FRAMEBUFFER_COMPLETE = RenderingContext.FRAMEBUFFER_COMPLETE;
  const FRAMEBUFFER_INCOMPLETE_ATTACHMENT = RenderingContext.FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
  const FRAMEBUFFER_INCOMPLETE_DIMENSIONS = RenderingContext.FRAMEBUFFER_INCOMPLETE_DIMENSIONS;
  const FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = RenderingContext.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT;
  const FRAMEBUFFER_UNSUPPORTED = RenderingContext.FRAMEBUFFER_UNSUPPORTED;
  const FRONT = RenderingContext.FRONT;
  const FRONT_AND_BACK = RenderingContext.FRONT_AND_BACK;
  const FRONT_FACE = RenderingContext.FRONT_FACE;
  const FUNC_ADD = RenderingContext.FUNC_ADD;
  const FUNC_REVERSE_SUBTRACT = RenderingContext.FUNC_REVERSE_SUBTRACT;
  const FUNC_SUBTRACT = RenderingContext.FUNC_SUBTRACT;
  const GENERATE_MIPMAP_HINT = RenderingContext.GENERATE_MIPMAP_HINT;
  const GEQUAL = RenderingContext.GEQUAL;
  const GREATER = RenderingContext.GREATER;
  const GREEN_BITS = RenderingContext.GREEN_BITS;
  class OesTextureHalfFloat extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(OesTextureHalfFloat, {
    constructors: () => ({_: [OesTextureHalfFloat, []]})
  });
  OesTextureHalfFloat[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('OESTextureHalfFloat')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("OESTextureHalfFloat"))];
  OesTextureHalfFloat.HALF_FLOAT_OES = 36193;
  dart.registerExtension(dart.global.OESTextureHalfFloat, OesTextureHalfFloat);
  const HALF_FLOAT_OES = OesTextureHalfFloat.HALF_FLOAT_OES;
  const HIGH_FLOAT = RenderingContext.HIGH_FLOAT;
  const HIGH_INT = RenderingContext.HIGH_INT;
  const INCR = RenderingContext.INCR;
  const INCR_WRAP = RenderingContext.INCR_WRAP;
  const INT = RenderingContext.INT;
  const INT_VEC2 = RenderingContext.INT_VEC2;
  const INT_VEC3 = RenderingContext.INT_VEC3;
  const INT_VEC4 = RenderingContext.INT_VEC4;
  const INVALID_ENUM = RenderingContext.INVALID_ENUM;
  const INVALID_FRAMEBUFFER_OPERATION = RenderingContext.INVALID_FRAMEBUFFER_OPERATION;
  const INVALID_OPERATION = RenderingContext.INVALID_OPERATION;
  const INVALID_VALUE = RenderingContext.INVALID_VALUE;
  const INVERT = RenderingContext.INVERT;
  const KEEP = RenderingContext.KEEP;
  const LEQUAL = RenderingContext.LEQUAL;
  const LESS = RenderingContext.LESS;
  const LINEAR = RenderingContext.LINEAR;
  const LINEAR_MIPMAP_LINEAR = RenderingContext.LINEAR_MIPMAP_LINEAR;
  const LINEAR_MIPMAP_NEAREST = RenderingContext.LINEAR_MIPMAP_NEAREST;
  const LINES = RenderingContext.LINES;
  const LINE_LOOP = RenderingContext.LINE_LOOP;
  const LINE_STRIP = RenderingContext.LINE_STRIP;
  const LINE_WIDTH = RenderingContext.LINE_WIDTH;
  const LINK_STATUS = RenderingContext.LINK_STATUS;
  const LOW_FLOAT = RenderingContext.LOW_FLOAT;
  const LOW_INT = RenderingContext.LOW_INT;
  const LUMINANCE = RenderingContext.LUMINANCE;
  const LUMINANCE_ALPHA = RenderingContext.LUMINANCE_ALPHA;
  const MAX_COMBINED_TEXTURE_IMAGE_UNITS = RenderingContext.MAX_COMBINED_TEXTURE_IMAGE_UNITS;
  const MAX_CUBE_MAP_TEXTURE_SIZE = RenderingContext.MAX_CUBE_MAP_TEXTURE_SIZE;
  const MAX_FRAGMENT_UNIFORM_VECTORS = RenderingContext.MAX_FRAGMENT_UNIFORM_VECTORS;
  const MAX_RENDERBUFFER_SIZE = RenderingContext.MAX_RENDERBUFFER_SIZE;
  const MAX_TEXTURE_IMAGE_UNITS = RenderingContext.MAX_TEXTURE_IMAGE_UNITS;
  const MAX_TEXTURE_SIZE = RenderingContext.MAX_TEXTURE_SIZE;
  const MAX_VARYING_VECTORS = RenderingContext.MAX_VARYING_VECTORS;
  const MAX_VERTEX_ATTRIBS = RenderingContext.MAX_VERTEX_ATTRIBS;
  const MAX_VERTEX_TEXTURE_IMAGE_UNITS = RenderingContext.MAX_VERTEX_TEXTURE_IMAGE_UNITS;
  const MAX_VERTEX_UNIFORM_VECTORS = RenderingContext.MAX_VERTEX_UNIFORM_VECTORS;
  const MAX_VIEWPORT_DIMS = RenderingContext.MAX_VIEWPORT_DIMS;
  const MEDIUM_FLOAT = RenderingContext.MEDIUM_FLOAT;
  const MEDIUM_INT = RenderingContext.MEDIUM_INT;
  const MIRRORED_REPEAT = RenderingContext.MIRRORED_REPEAT;
  const NEAREST = RenderingContext.NEAREST;
  const NEAREST_MIPMAP_LINEAR = RenderingContext.NEAREST_MIPMAP_LINEAR;
  const NEAREST_MIPMAP_NEAREST = RenderingContext.NEAREST_MIPMAP_NEAREST;
  const NEVER = RenderingContext.NEVER;
  const NICEST = RenderingContext.NICEST;
  const NONE = RenderingContext.NONE;
  const NOTEQUAL = RenderingContext.NOTEQUAL;
  const NO_ERROR = RenderingContext.NO_ERROR;
  const ONE = RenderingContext.ONE;
  const ONE_MINUS_CONSTANT_ALPHA = RenderingContext.ONE_MINUS_CONSTANT_ALPHA;
  const ONE_MINUS_CONSTANT_COLOR = RenderingContext.ONE_MINUS_CONSTANT_COLOR;
  const ONE_MINUS_DST_ALPHA = RenderingContext.ONE_MINUS_DST_ALPHA;
  const ONE_MINUS_DST_COLOR = RenderingContext.ONE_MINUS_DST_COLOR;
  const ONE_MINUS_SRC_ALPHA = RenderingContext.ONE_MINUS_SRC_ALPHA;
  const ONE_MINUS_SRC_COLOR = RenderingContext.ONE_MINUS_SRC_COLOR;
  const OUT_OF_MEMORY = RenderingContext.OUT_OF_MEMORY;
  const PACK_ALIGNMENT = RenderingContext.PACK_ALIGNMENT;
  const POINTS = RenderingContext.POINTS;
  const POLYGON_OFFSET_FACTOR = RenderingContext.POLYGON_OFFSET_FACTOR;
  const POLYGON_OFFSET_FILL = RenderingContext.POLYGON_OFFSET_FILL;
  const POLYGON_OFFSET_UNITS = RenderingContext.POLYGON_OFFSET_UNITS;
  const RED_BITS = RenderingContext.RED_BITS;
  const RENDERBUFFER = RenderingContext.RENDERBUFFER;
  const RENDERBUFFER_ALPHA_SIZE = RenderingContext.RENDERBUFFER_ALPHA_SIZE;
  const RENDERBUFFER_BINDING = RenderingContext.RENDERBUFFER_BINDING;
  const RENDERBUFFER_BLUE_SIZE = RenderingContext.RENDERBUFFER_BLUE_SIZE;
  const RENDERBUFFER_DEPTH_SIZE = RenderingContext.RENDERBUFFER_DEPTH_SIZE;
  const RENDERBUFFER_GREEN_SIZE = RenderingContext.RENDERBUFFER_GREEN_SIZE;
  const RENDERBUFFER_HEIGHT = RenderingContext.RENDERBUFFER_HEIGHT;
  const RENDERBUFFER_INTERNAL_FORMAT = RenderingContext.RENDERBUFFER_INTERNAL_FORMAT;
  const RENDERBUFFER_RED_SIZE = RenderingContext.RENDERBUFFER_RED_SIZE;
  const RENDERBUFFER_STENCIL_SIZE = RenderingContext.RENDERBUFFER_STENCIL_SIZE;
  const RENDERBUFFER_WIDTH = RenderingContext.RENDERBUFFER_WIDTH;
  const RENDERER = RenderingContext.RENDERER;
  const REPEAT = RenderingContext.REPEAT;
  const REPLACE = RenderingContext.REPLACE;
  const RGB = RenderingContext.RGB;
  const RGB565 = RenderingContext.RGB565;
  const RGB5_A1 = RenderingContext.RGB5_A1;
  const RGBA = RenderingContext.RGBA;
  const RGBA4 = RenderingContext.RGBA4;
  const SAMPLER_2D = RenderingContext.SAMPLER_2D;
  const SAMPLER_CUBE = RenderingContext.SAMPLER_CUBE;
  const SAMPLES = RenderingContext.SAMPLES;
  const SAMPLE_ALPHA_TO_COVERAGE = RenderingContext.SAMPLE_ALPHA_TO_COVERAGE;
  const SAMPLE_BUFFERS = RenderingContext.SAMPLE_BUFFERS;
  const SAMPLE_COVERAGE = RenderingContext.SAMPLE_COVERAGE;
  const SAMPLE_COVERAGE_INVERT = RenderingContext.SAMPLE_COVERAGE_INVERT;
  const SAMPLE_COVERAGE_VALUE = RenderingContext.SAMPLE_COVERAGE_VALUE;
  const SCISSOR_BOX = RenderingContext.SCISSOR_BOX;
  const SCISSOR_TEST = RenderingContext.SCISSOR_TEST;
  const SHADER_TYPE = RenderingContext.SHADER_TYPE;
  const SHADING_LANGUAGE_VERSION = RenderingContext.SHADING_LANGUAGE_VERSION;
  const SHORT = RenderingContext.SHORT;
  const SRC_ALPHA = RenderingContext.SRC_ALPHA;
  const SRC_ALPHA_SATURATE = RenderingContext.SRC_ALPHA_SATURATE;
  const SRC_COLOR = RenderingContext.SRC_COLOR;
  const STATIC_DRAW = RenderingContext.STATIC_DRAW;
  const STENCIL_ATTACHMENT = RenderingContext.STENCIL_ATTACHMENT;
  const STENCIL_BACK_FAIL = RenderingContext.STENCIL_BACK_FAIL;
  const STENCIL_BACK_FUNC = RenderingContext.STENCIL_BACK_FUNC;
  const STENCIL_BACK_PASS_DEPTH_FAIL = RenderingContext.STENCIL_BACK_PASS_DEPTH_FAIL;
  const STENCIL_BACK_PASS_DEPTH_PASS = RenderingContext.STENCIL_BACK_PASS_DEPTH_PASS;
  const STENCIL_BACK_REF = RenderingContext.STENCIL_BACK_REF;
  const STENCIL_BACK_VALUE_MASK = RenderingContext.STENCIL_BACK_VALUE_MASK;
  const STENCIL_BACK_WRITEMASK = RenderingContext.STENCIL_BACK_WRITEMASK;
  const STENCIL_BITS = RenderingContext.STENCIL_BITS;
  const STENCIL_BUFFER_BIT = RenderingContext.STENCIL_BUFFER_BIT;
  const STENCIL_CLEAR_VALUE = RenderingContext.STENCIL_CLEAR_VALUE;
  const STENCIL_FAIL = RenderingContext.STENCIL_FAIL;
  const STENCIL_FUNC = RenderingContext.STENCIL_FUNC;
  const STENCIL_INDEX = RenderingContext.STENCIL_INDEX;
  const STENCIL_INDEX8 = RenderingContext.STENCIL_INDEX8;
  const STENCIL_PASS_DEPTH_FAIL = RenderingContext.STENCIL_PASS_DEPTH_FAIL;
  const STENCIL_PASS_DEPTH_PASS = RenderingContext.STENCIL_PASS_DEPTH_PASS;
  const STENCIL_REF = RenderingContext.STENCIL_REF;
  const STENCIL_TEST = RenderingContext.STENCIL_TEST;
  const STENCIL_VALUE_MASK = RenderingContext.STENCIL_VALUE_MASK;
  const STENCIL_WRITEMASK = RenderingContext.STENCIL_WRITEMASK;
  const STREAM_DRAW = RenderingContext.STREAM_DRAW;
  const SUBPIXEL_BITS = RenderingContext.SUBPIXEL_BITS;
  const TEXTURE = RenderingContext.TEXTURE;
  const TEXTURE0 = RenderingContext.TEXTURE0;
  const TEXTURE1 = RenderingContext.TEXTURE1;
  const TEXTURE10 = RenderingContext.TEXTURE10;
  const TEXTURE11 = RenderingContext.TEXTURE11;
  const TEXTURE12 = RenderingContext.TEXTURE12;
  const TEXTURE13 = RenderingContext.TEXTURE13;
  const TEXTURE14 = RenderingContext.TEXTURE14;
  const TEXTURE15 = RenderingContext.TEXTURE15;
  const TEXTURE16 = RenderingContext.TEXTURE16;
  const TEXTURE17 = RenderingContext.TEXTURE17;
  const TEXTURE18 = RenderingContext.TEXTURE18;
  const TEXTURE19 = RenderingContext.TEXTURE19;
  const TEXTURE2 = RenderingContext.TEXTURE2;
  const TEXTURE20 = RenderingContext.TEXTURE20;
  const TEXTURE21 = RenderingContext.TEXTURE21;
  const TEXTURE22 = RenderingContext.TEXTURE22;
  const TEXTURE23 = RenderingContext.TEXTURE23;
  const TEXTURE24 = RenderingContext.TEXTURE24;
  const TEXTURE25 = RenderingContext.TEXTURE25;
  const TEXTURE26 = RenderingContext.TEXTURE26;
  const TEXTURE27 = RenderingContext.TEXTURE27;
  const TEXTURE28 = RenderingContext.TEXTURE28;
  const TEXTURE29 = RenderingContext.TEXTURE29;
  const TEXTURE3 = RenderingContext.TEXTURE3;
  const TEXTURE30 = RenderingContext.TEXTURE30;
  const TEXTURE31 = RenderingContext.TEXTURE31;
  const TEXTURE4 = RenderingContext.TEXTURE4;
  const TEXTURE5 = RenderingContext.TEXTURE5;
  const TEXTURE6 = RenderingContext.TEXTURE6;
  const TEXTURE7 = RenderingContext.TEXTURE7;
  const TEXTURE8 = RenderingContext.TEXTURE8;
  const TEXTURE9 = RenderingContext.TEXTURE9;
  const TEXTURE_2D = RenderingContext.TEXTURE_2D;
  const TEXTURE_BINDING_2D = RenderingContext.TEXTURE_BINDING_2D;
  const TEXTURE_BINDING_CUBE_MAP = RenderingContext.TEXTURE_BINDING_CUBE_MAP;
  const TEXTURE_CUBE_MAP = RenderingContext.TEXTURE_CUBE_MAP;
  const TEXTURE_CUBE_MAP_NEGATIVE_X = RenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_X;
  const TEXTURE_CUBE_MAP_NEGATIVE_Y = RenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_Y;
  const TEXTURE_CUBE_MAP_NEGATIVE_Z = RenderingContext.TEXTURE_CUBE_MAP_NEGATIVE_Z;
  const TEXTURE_CUBE_MAP_POSITIVE_X = RenderingContext.TEXTURE_CUBE_MAP_POSITIVE_X;
  const TEXTURE_CUBE_MAP_POSITIVE_Y = RenderingContext.TEXTURE_CUBE_MAP_POSITIVE_Y;
  const TEXTURE_CUBE_MAP_POSITIVE_Z = RenderingContext.TEXTURE_CUBE_MAP_POSITIVE_Z;
  const TEXTURE_MAG_FILTER = RenderingContext.TEXTURE_MAG_FILTER;
  const TEXTURE_MIN_FILTER = RenderingContext.TEXTURE_MIN_FILTER;
  const TEXTURE_WRAP_S = RenderingContext.TEXTURE_WRAP_S;
  const TEXTURE_WRAP_T = RenderingContext.TEXTURE_WRAP_T;
  const TRIANGLES = RenderingContext.TRIANGLES;
  const TRIANGLE_FAN = RenderingContext.TRIANGLE_FAN;
  const TRIANGLE_STRIP = RenderingContext.TRIANGLE_STRIP;
  const UNPACK_ALIGNMENT = RenderingContext.UNPACK_ALIGNMENT;
  const UNPACK_COLORSPACE_CONVERSION_WEBGL = RenderingContext.UNPACK_COLORSPACE_CONVERSION_WEBGL;
  const UNPACK_FLIP_Y_WEBGL = RenderingContext.UNPACK_FLIP_Y_WEBGL;
  const UNPACK_PREMULTIPLY_ALPHA_WEBGL = RenderingContext.UNPACK_PREMULTIPLY_ALPHA_WEBGL;
  const UNSIGNED_BYTE = RenderingContext.UNSIGNED_BYTE;
  const UNSIGNED_INT = RenderingContext.UNSIGNED_INT;
  const UNSIGNED_SHORT = RenderingContext.UNSIGNED_SHORT;
  const UNSIGNED_SHORT_4_4_4_4 = RenderingContext.UNSIGNED_SHORT_4_4_4_4;
  const UNSIGNED_SHORT_5_5_5_1 = RenderingContext.UNSIGNED_SHORT_5_5_5_1;
  const UNSIGNED_SHORT_5_6_5 = RenderingContext.UNSIGNED_SHORT_5_6_5;
  const VALIDATE_STATUS = RenderingContext.VALIDATE_STATUS;
  const VENDOR = RenderingContext.VENDOR;
  const VERSION = RenderingContext.VERSION;
  const VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = RenderingContext.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING;
  const VERTEX_ATTRIB_ARRAY_ENABLED = RenderingContext.VERTEX_ATTRIB_ARRAY_ENABLED;
  const VERTEX_ATTRIB_ARRAY_NORMALIZED = RenderingContext.VERTEX_ATTRIB_ARRAY_NORMALIZED;
  const VERTEX_ATTRIB_ARRAY_POINTER = RenderingContext.VERTEX_ATTRIB_ARRAY_POINTER;
  const VERTEX_ATTRIB_ARRAY_SIZE = RenderingContext.VERTEX_ATTRIB_ARRAY_SIZE;
  const VERTEX_ATTRIB_ARRAY_STRIDE = RenderingContext.VERTEX_ATTRIB_ARRAY_STRIDE;
  const VERTEX_ATTRIB_ARRAY_TYPE = RenderingContext.VERTEX_ATTRIB_ARRAY_TYPE;
  const VERTEX_SHADER = RenderingContext.VERTEX_SHADER;
  const VIEWPORT = RenderingContext.VIEWPORT;
  const ZERO = RenderingContext.ZERO;
  dart.defineExtensionNames([
    'name',
    'size',
    'type'
  ]);
  class ActiveInfo extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.name]() {
      return this.name;
    }
    get [dartx.size]() {
      return this.size;
    }
    get [dartx.type]() {
      return this.type;
    }
  }
  dart.setSignature(ActiveInfo, {
    constructors: () => ({_: [ActiveInfo, []]})
  });
  ActiveInfo[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLActiveInfo')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("WebGLActiveInfo"))];
  dart.registerExtension(dart.global.WebGLActiveInfo, ActiveInfo);
  dart.defineExtensionNames([
    'drawArraysInstancedAngle',
    'drawElementsInstancedAngle',
    'vertexAttribDivisorAngle'
  ]);
  class AngleInstancedArrays extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    [dartx.drawArraysInstancedAngle](mode, first, count, primcount) {
      return this.drawArraysInstancedANGLE(mode, first, count, primcount);
    }
    [dartx.drawElementsInstancedAngle](mode, count, type, offset, primcount) {
      return this.drawElementsInstancedANGLE(mode, count, type, offset, primcount);
    }
    [dartx.vertexAttribDivisorAngle](index, divisor) {
      return this.vertexAttribDivisorANGLE(index, divisor);
    }
  }
  dart.setSignature(AngleInstancedArrays, {
    constructors: () => ({_: [AngleInstancedArrays, []]}),
    methods: () => ({
      [dartx.drawArraysInstancedAngle]: [dart.void, [core.int, core.int, core.int, core.int]],
      [dartx.drawElementsInstancedAngle]: [dart.void, [core.int, core.int, core.int, core.int, core.int]],
      [dartx.vertexAttribDivisorAngle]: [dart.void, [core.int, core.int]]
    })
  });
  AngleInstancedArrays[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('ANGLEInstancedArrays')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("ANGLEInstancedArrays"))];
  AngleInstancedArrays.VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE = 35070;
  dart.registerExtension(dart.global.ANGLEInstancedArrays, AngleInstancedArrays);
  class Buffer extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(Buffer, {
    constructors: () => ({_: [Buffer, []]})
  });
  Buffer[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLBuffer')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("WebGLBuffer"))];
  dart.registerExtension(dart.global.WebGLBuffer, Buffer);
  class CompressedTextureAtc extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(CompressedTextureAtc, {
    constructors: () => ({_: [CompressedTextureAtc, []]})
  });
  CompressedTextureAtc[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLCompressedTextureATC')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WebGLCompressedTextureATC"))];
  CompressedTextureAtc.COMPRESSED_RGBA_ATC_EXPLICIT_ALPHA_WEBGL = 35987;
  CompressedTextureAtc.COMPRESSED_RGBA_ATC_INTERPOLATED_ALPHA_WEBGL = 34798;
  CompressedTextureAtc.COMPRESSED_RGB_ATC_WEBGL = 35986;
  dart.registerExtension(dart.global.WebGLCompressedTextureATC, CompressedTextureAtc);
  class CompressedTextureETC1 extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(CompressedTextureETC1, {
    constructors: () => ({_: [CompressedTextureETC1, []]})
  });
  CompressedTextureETC1[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLCompressedTextureETC1')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WebGLCompressedTextureETC1"))];
  CompressedTextureETC1.COMPRESSED_RGB_ETC1_WEBGL = 36196;
  dart.registerExtension(dart.global.WebGLCompressedTextureETC1, CompressedTextureETC1);
  class CompressedTexturePvrtc extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(CompressedTexturePvrtc, {
    constructors: () => ({_: [CompressedTexturePvrtc, []]})
  });
  CompressedTexturePvrtc[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLCompressedTexturePVRTC')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WebGLCompressedTexturePVRTC"))];
  CompressedTexturePvrtc.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG = 35843;
  CompressedTexturePvrtc.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 35842;
  CompressedTexturePvrtc.COMPRESSED_RGB_PVRTC_2BPPV1_IMG = 35841;
  CompressedTexturePvrtc.COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 35840;
  dart.registerExtension(dart.global.WebGLCompressedTexturePVRTC, CompressedTexturePvrtc);
  class CompressedTextureS3TC extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(CompressedTextureS3TC, {
    constructors: () => ({_: [CompressedTextureS3TC, []]})
  });
  CompressedTextureS3TC[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLCompressedTextureS3TC')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WebGLCompressedTextureS3TC"))];
  CompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT1_EXT = 33777;
  CompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT3_EXT = 33778;
  CompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT5_EXT = 33779;
  CompressedTextureS3TC.COMPRESSED_RGB_S3TC_DXT1_EXT = 33776;
  dart.registerExtension(dart.global.WebGLCompressedTextureS3TC, CompressedTextureS3TC);
  dart.defineExtensionNames([
    'alpha',
    'antialias',
    'depth',
    'failIfMajorPerformanceCaveat',
    'premultipliedAlpha',
    'preserveDrawingBuffer',
    'stencil'
  ]);
  class ContextAttributes extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.alpha]() {
      return this.alpha;
    }
    set [dartx.alpha](value) {
      this.alpha = value;
    }
    get [dartx.antialias]() {
      return this.antialias;
    }
    set [dartx.antialias](value) {
      this.antialias = value;
    }
    get [dartx.depth]() {
      return this.depth;
    }
    set [dartx.depth](value) {
      this.depth = value;
    }
    get [dartx.failIfMajorPerformanceCaveat]() {
      return this.failIfMajorPerformanceCaveat;
    }
    set [dartx.failIfMajorPerformanceCaveat](value) {
      this.failIfMajorPerformanceCaveat = value;
    }
    get [dartx.premultipliedAlpha]() {
      return this.premultipliedAlpha;
    }
    set [dartx.premultipliedAlpha](value) {
      this.premultipliedAlpha = value;
    }
    get [dartx.preserveDrawingBuffer]() {
      return this.preserveDrawingBuffer;
    }
    set [dartx.preserveDrawingBuffer](value) {
      this.preserveDrawingBuffer = value;
    }
    get [dartx.stencil]() {
      return this.stencil;
    }
    set [dartx.stencil](value) {
      this.stencil = value;
    }
  }
  dart.setSignature(ContextAttributes, {
    constructors: () => ({_: [ContextAttributes, []]})
  });
  ContextAttributes[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLContextAttributes')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("WebGLContextAttributes"))];
  dart.registerExtension(dart.global.WebGLContextAttributes, ContextAttributes);
  dart.defineExtensionNames([
    'statusMessage'
  ]);
  class ContextEvent extends html.Event {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.statusMessage]() {
      return this.statusMessage;
    }
  }
  dart.setSignature(ContextEvent, {
    constructors: () => ({_: [ContextEvent, []]})
  });
  ContextEvent[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLContextEvent')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("WebGLContextEvent"))];
  dart.registerExtension(dart.global.WebGLContextEvent, ContextEvent);
  class DebugRendererInfo extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(DebugRendererInfo, {
    constructors: () => ({_: [DebugRendererInfo, []]})
  });
  DebugRendererInfo[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLDebugRendererInfo')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WebGLDebugRendererInfo"))];
  DebugRendererInfo.UNMASKED_RENDERER_WEBGL = 37446;
  DebugRendererInfo.UNMASKED_VENDOR_WEBGL = 37445;
  dart.registerExtension(dart.global.WebGLDebugRendererInfo, DebugRendererInfo);
  dart.defineExtensionNames([
    'getTranslatedShaderSource'
  ]);
  class DebugShaders extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    [dartx.getTranslatedShaderSource](shader) {
      return this.getTranslatedShaderSource(shader);
    }
  }
  dart.setSignature(DebugShaders, {
    constructors: () => ({_: [DebugShaders, []]}),
    methods: () => ({[dartx.getTranslatedShaderSource]: [core.String, [Shader]]})
  });
  DebugShaders[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLDebugShaders')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WebGLDebugShaders"))];
  dart.registerExtension(dart.global.WebGLDebugShaders, DebugShaders);
  class DepthTexture extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(DepthTexture, {
    constructors: () => ({_: [DepthTexture, []]})
  });
  DepthTexture[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLDepthTexture')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WebGLDepthTexture"))];
  DepthTexture.UNSIGNED_INT_24_8_WEBGL = 34042;
  dart.registerExtension(dart.global.WebGLDepthTexture, DepthTexture);
  dart.defineExtensionNames([
    'drawBuffersWebgl'
  ]);
  class DrawBuffers extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    [dartx.drawBuffersWebgl](buffers) {
      return this.drawBuffersWEBGL(buffers);
    }
  }
  dart.setSignature(DrawBuffers, {
    constructors: () => ({_: [DrawBuffers, []]}),
    methods: () => ({[dartx.drawBuffersWebgl]: [dart.void, [core.List$(core.int)]]})
  });
  DrawBuffers[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLDrawBuffers')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WebGLDrawBuffers"))];
  DrawBuffers.COLOR_ATTACHMENT0_WEBGL = 36064;
  DrawBuffers.COLOR_ATTACHMENT10_WEBGL = 36074;
  DrawBuffers.COLOR_ATTACHMENT11_WEBGL = 36075;
  DrawBuffers.COLOR_ATTACHMENT12_WEBGL = 36076;
  DrawBuffers.COLOR_ATTACHMENT13_WEBGL = 36077;
  DrawBuffers.COLOR_ATTACHMENT14_WEBGL = 36078;
  DrawBuffers.COLOR_ATTACHMENT15_WEBGL = 36079;
  DrawBuffers.COLOR_ATTACHMENT1_WEBGL = 36065;
  DrawBuffers.COLOR_ATTACHMENT2_WEBGL = 36066;
  DrawBuffers.COLOR_ATTACHMENT3_WEBGL = 36067;
  DrawBuffers.COLOR_ATTACHMENT4_WEBGL = 36068;
  DrawBuffers.COLOR_ATTACHMENT5_WEBGL = 36069;
  DrawBuffers.COLOR_ATTACHMENT6_WEBGL = 36070;
  DrawBuffers.COLOR_ATTACHMENT7_WEBGL = 36071;
  DrawBuffers.COLOR_ATTACHMENT8_WEBGL = 36072;
  DrawBuffers.COLOR_ATTACHMENT9_WEBGL = 36073;
  DrawBuffers.DRAW_BUFFER0_WEBGL = 34853;
  DrawBuffers.DRAW_BUFFER10_WEBGL = 34863;
  DrawBuffers.DRAW_BUFFER11_WEBGL = 34864;
  DrawBuffers.DRAW_BUFFER12_WEBGL = 34865;
  DrawBuffers.DRAW_BUFFER13_WEBGL = 34866;
  DrawBuffers.DRAW_BUFFER14_WEBGL = 34867;
  DrawBuffers.DRAW_BUFFER15_WEBGL = 34868;
  DrawBuffers.DRAW_BUFFER1_WEBGL = 34854;
  DrawBuffers.DRAW_BUFFER2_WEBGL = 34855;
  DrawBuffers.DRAW_BUFFER3_WEBGL = 34856;
  DrawBuffers.DRAW_BUFFER4_WEBGL = 34857;
  DrawBuffers.DRAW_BUFFER5_WEBGL = 34858;
  DrawBuffers.DRAW_BUFFER6_WEBGL = 34859;
  DrawBuffers.DRAW_BUFFER7_WEBGL = 34860;
  DrawBuffers.DRAW_BUFFER8_WEBGL = 34861;
  DrawBuffers.DRAW_BUFFER9_WEBGL = 34862;
  DrawBuffers.MAX_COLOR_ATTACHMENTS_WEBGL = 36063;
  DrawBuffers.MAX_DRAW_BUFFERS_WEBGL = 34852;
  dart.registerExtension(dart.global.WebGLDrawBuffers, DrawBuffers);
  class ExtBlendMinMax extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(ExtBlendMinMax, {
    constructors: () => ({_: [ExtBlendMinMax, []]})
  });
  ExtBlendMinMax[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('EXTBlendMinMax')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("EXTBlendMinMax"))];
  ExtBlendMinMax.MAX_EXT = 32776;
  ExtBlendMinMax.MIN_EXT = 32775;
  dart.registerExtension(dart.global.EXTBlendMinMax, ExtBlendMinMax);
  class ExtFragDepth extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(ExtFragDepth, {
    constructors: () => ({_: [ExtFragDepth, []]})
  });
  ExtFragDepth[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('EXTFragDepth')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("EXTFragDepth"))];
  dart.registerExtension(dart.global.EXTFragDepth, ExtFragDepth);
  class ExtShaderTextureLod extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(ExtShaderTextureLod, {
    constructors: () => ({_: [ExtShaderTextureLod, []]})
  });
  ExtShaderTextureLod[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('EXTShaderTextureLOD')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("EXTShaderTextureLOD"))];
  dart.registerExtension(dart.global.EXTShaderTextureLOD, ExtShaderTextureLod);
  class ExtTextureFilterAnisotropic extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(ExtTextureFilterAnisotropic, {
    constructors: () => ({_: [ExtTextureFilterAnisotropic, []]})
  });
  ExtTextureFilterAnisotropic[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('EXTTextureFilterAnisotropic')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("EXTTextureFilterAnisotropic"))];
  ExtTextureFilterAnisotropic.MAX_TEXTURE_MAX_ANISOTROPY_EXT = 34047;
  ExtTextureFilterAnisotropic.TEXTURE_MAX_ANISOTROPY_EXT = 34046;
  dart.registerExtension(dart.global.EXTTextureFilterAnisotropic, ExtTextureFilterAnisotropic);
  class Framebuffer extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(Framebuffer, {
    constructors: () => ({_: [Framebuffer, []]})
  });
  Framebuffer[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLFramebuffer')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("WebGLFramebuffer"))];
  dart.registerExtension(dart.global.WebGLFramebuffer, Framebuffer);
  dart.defineExtensionNames([
    'loseContext',
    'restoreContext'
  ]);
  class LoseContext extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    [dartx.loseContext]() {
      return this.loseContext();
    }
    [dartx.restoreContext]() {
      return this.restoreContext();
    }
  }
  dart.setSignature(LoseContext, {
    constructors: () => ({_: [LoseContext, []]}),
    methods: () => ({
      [dartx.loseContext]: [dart.void, []],
      [dartx.restoreContext]: [dart.void, []]
    })
  });
  LoseContext[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLLoseContext')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WebGLLoseContext,WebGLExtensionLoseContext"))];
  dart.registerExtension(dart.global.WebGLLoseContext, LoseContext);
  class OesElementIndexUint extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(OesElementIndexUint, {
    constructors: () => ({_: [OesElementIndexUint, []]})
  });
  OesElementIndexUint[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('OESElementIndexUint')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("OESElementIndexUint"))];
  dart.registerExtension(dart.global.OESElementIndexUint, OesElementIndexUint);
  class OesStandardDerivatives extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(OesStandardDerivatives, {
    constructors: () => ({_: [OesStandardDerivatives, []]})
  });
  OesStandardDerivatives[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('OESStandardDerivatives')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("OESStandardDerivatives"))];
  OesStandardDerivatives.FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 35723;
  dart.registerExtension(dart.global.OESStandardDerivatives, OesStandardDerivatives);
  class OesTextureFloat extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(OesTextureFloat, {
    constructors: () => ({_: [OesTextureFloat, []]})
  });
  OesTextureFloat[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('OESTextureFloat')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("OESTextureFloat"))];
  dart.registerExtension(dart.global.OESTextureFloat, OesTextureFloat);
  class OesTextureFloatLinear extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(OesTextureFloatLinear, {
    constructors: () => ({_: [OesTextureFloatLinear, []]})
  });
  OesTextureFloatLinear[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('OESTextureFloatLinear')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("OESTextureFloatLinear"))];
  dart.registerExtension(dart.global.OESTextureFloatLinear, OesTextureFloatLinear);
  class OesTextureHalfFloatLinear extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(OesTextureHalfFloatLinear, {
    constructors: () => ({_: [OesTextureHalfFloatLinear, []]})
  });
  OesTextureHalfFloatLinear[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('OESTextureHalfFloatLinear')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("OESTextureHalfFloatLinear"))];
  dart.registerExtension(dart.global.OESTextureHalfFloatLinear, OesTextureHalfFloatLinear);
  dart.defineExtensionNames([
    'bindVertexArray',
    'createVertexArray',
    'deleteVertexArray',
    'isVertexArray'
  ]);
  class OesVertexArrayObject extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    [dartx.bindVertexArray](arrayObject) {
      return this.bindVertexArrayOES(arrayObject);
    }
    [dartx.createVertexArray]() {
      return this.createVertexArrayOES();
    }
    [dartx.deleteVertexArray](arrayObject) {
      return this.deleteVertexArrayOES(arrayObject);
    }
    [dartx.isVertexArray](arrayObject) {
      return this.isVertexArrayOES(arrayObject);
    }
  }
  dart.setSignature(OesVertexArrayObject, {
    constructors: () => ({_: [OesVertexArrayObject, []]}),
    methods: () => ({
      [dartx.bindVertexArray]: [dart.void, [VertexArrayObject]],
      [dartx.createVertexArray]: [VertexArrayObject, []],
      [dartx.deleteVertexArray]: [dart.void, [VertexArrayObject]],
      [dartx.isVertexArray]: [core.bool, [VertexArrayObject]]
    })
  });
  OesVertexArrayObject[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('OESVertexArrayObject')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("OESVertexArrayObject"))];
  OesVertexArrayObject.VERTEX_ARRAY_BINDING_OES = 34229;
  dart.registerExtension(dart.global.OESVertexArrayObject, OesVertexArrayObject);
  class Program extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(Program, {
    constructors: () => ({_: [Program, []]})
  });
  Program[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLProgram')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("WebGLProgram"))];
  dart.registerExtension(dart.global.WebGLProgram, Program);
  class Renderbuffer extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(Renderbuffer, {
    constructors: () => ({_: [Renderbuffer, []]})
  });
  Renderbuffer[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLRenderbuffer')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("WebGLRenderbuffer"))];
  dart.registerExtension(dart.global.WebGLRenderbuffer, Renderbuffer);
  class Shader extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(Shader, {
    constructors: () => ({_: [Shader, []]})
  });
  Shader[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLShader')), dart.const(new _js_helper.Native("WebGLShader"))];
  dart.registerExtension(dart.global.WebGLShader, Shader);
  dart.defineExtensionNames([
    'precision',
    'rangeMax',
    'rangeMin'
  ]);
  class ShaderPrecisionFormat extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.precision]() {
      return this.precision;
    }
    get [dartx.rangeMax]() {
      return this.rangeMax;
    }
    get [dartx.rangeMin]() {
      return this.rangeMin;
    }
  }
  dart.setSignature(ShaderPrecisionFormat, {
    constructors: () => ({_: [ShaderPrecisionFormat, []]})
  });
  ShaderPrecisionFormat[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLShaderPrecisionFormat')), dart.const(new _js_helper.Native("WebGLShaderPrecisionFormat"))];
  dart.registerExtension(dart.global.WebGLShaderPrecisionFormat, ShaderPrecisionFormat);
  class Texture extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(Texture, {
    constructors: () => ({_: [Texture, []]})
  });
  Texture[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLTexture')), dart.const(new _js_helper.Native("WebGLTexture"))];
  dart.registerExtension(dart.global.WebGLTexture, Texture);
  class UniformLocation extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(UniformLocation, {
    constructors: () => ({_: [UniformLocation, []]})
  });
  UniformLocation[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLUniformLocation')), dart.const(new _js_helper.Native("WebGLUniformLocation"))];
  dart.registerExtension(dart.global.WebGLUniformLocation, UniformLocation);
  class VertexArrayObject extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(VertexArrayObject, {
    constructors: () => ({_: [VertexArrayObject, []]})
  });
  VertexArrayObject[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLVertexArrayObjectOES')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WebGLVertexArrayObjectOES"))];
  dart.registerExtension(dart.global.WebGLVertexArrayObjectOES, VertexArrayObject);
  class _WebGLRenderingContextBase extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(_WebGLRenderingContextBase, {
    constructors: () => ({_: [_WebGLRenderingContextBase, []]})
  });
  _WebGLRenderingContextBase[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WebGLRenderingContextBase')), dart.const(new _metadata.Experimental())];
  // Exports:
  exports.RenderingContext = RenderingContext;
  exports.ACTIVE_ATTRIBUTES = ACTIVE_ATTRIBUTES;
  exports.ACTIVE_TEXTURE = ACTIVE_TEXTURE;
  exports.ACTIVE_UNIFORMS = ACTIVE_UNIFORMS;
  exports.ALIASED_LINE_WIDTH_RANGE = ALIASED_LINE_WIDTH_RANGE;
  exports.ALIASED_POINT_SIZE_RANGE = ALIASED_POINT_SIZE_RANGE;
  exports.ALPHA = ALPHA;
  exports.ALPHA_BITS = ALPHA_BITS;
  exports.ALWAYS = ALWAYS;
  exports.ARRAY_BUFFER = ARRAY_BUFFER;
  exports.ARRAY_BUFFER_BINDING = ARRAY_BUFFER_BINDING;
  exports.ATTACHED_SHADERS = ATTACHED_SHADERS;
  exports.BACK = BACK;
  exports.BLEND = BLEND;
  exports.BLEND_COLOR = BLEND_COLOR;
  exports.BLEND_DST_ALPHA = BLEND_DST_ALPHA;
  exports.BLEND_DST_RGB = BLEND_DST_RGB;
  exports.BLEND_EQUATION = BLEND_EQUATION;
  exports.BLEND_EQUATION_ALPHA = BLEND_EQUATION_ALPHA;
  exports.BLEND_EQUATION_RGB = BLEND_EQUATION_RGB;
  exports.BLEND_SRC_ALPHA = BLEND_SRC_ALPHA;
  exports.BLEND_SRC_RGB = BLEND_SRC_RGB;
  exports.BLUE_BITS = BLUE_BITS;
  exports.BOOL = BOOL;
  exports.BOOL_VEC2 = BOOL_VEC2;
  exports.BOOL_VEC3 = BOOL_VEC3;
  exports.BOOL_VEC4 = BOOL_VEC4;
  exports.BROWSER_DEFAULT_WEBGL = BROWSER_DEFAULT_WEBGL;
  exports.BUFFER_SIZE = BUFFER_SIZE;
  exports.BUFFER_USAGE = BUFFER_USAGE;
  exports.BYTE = BYTE;
  exports.CCW = CCW;
  exports.CLAMP_TO_EDGE = CLAMP_TO_EDGE;
  exports.COLOR_ATTACHMENT0 = COLOR_ATTACHMENT0;
  exports.COLOR_BUFFER_BIT = COLOR_BUFFER_BIT;
  exports.COLOR_CLEAR_VALUE = COLOR_CLEAR_VALUE;
  exports.COLOR_WRITEMASK = COLOR_WRITEMASK;
  exports.COMPILE_STATUS = COMPILE_STATUS;
  exports.COMPRESSED_TEXTURE_FORMATS = COMPRESSED_TEXTURE_FORMATS;
  exports.CONSTANT_ALPHA = CONSTANT_ALPHA;
  exports.CONSTANT_COLOR = CONSTANT_COLOR;
  exports.CONTEXT_LOST_WEBGL = CONTEXT_LOST_WEBGL;
  exports.CULL_FACE = CULL_FACE;
  exports.CULL_FACE_MODE = CULL_FACE_MODE;
  exports.CURRENT_PROGRAM = CURRENT_PROGRAM;
  exports.CURRENT_VERTEX_ATTRIB = CURRENT_VERTEX_ATTRIB;
  exports.CW = CW;
  exports.DECR = DECR;
  exports.DECR_WRAP = DECR_WRAP;
  exports.DELETE_STATUS = DELETE_STATUS;
  exports.DEPTH_ATTACHMENT = DEPTH_ATTACHMENT;
  exports.DEPTH_BITS = DEPTH_BITS;
  exports.DEPTH_BUFFER_BIT = DEPTH_BUFFER_BIT;
  exports.DEPTH_CLEAR_VALUE = DEPTH_CLEAR_VALUE;
  exports.DEPTH_COMPONENT = DEPTH_COMPONENT;
  exports.DEPTH_COMPONENT16 = DEPTH_COMPONENT16;
  exports.DEPTH_FUNC = DEPTH_FUNC;
  exports.DEPTH_RANGE = DEPTH_RANGE;
  exports.DEPTH_STENCIL = DEPTH_STENCIL;
  exports.DEPTH_STENCIL_ATTACHMENT = DEPTH_STENCIL_ATTACHMENT;
  exports.DEPTH_TEST = DEPTH_TEST;
  exports.DEPTH_WRITEMASK = DEPTH_WRITEMASK;
  exports.DITHER = DITHER;
  exports.DONT_CARE = DONT_CARE;
  exports.DST_ALPHA = DST_ALPHA;
  exports.DST_COLOR = DST_COLOR;
  exports.DYNAMIC_DRAW = DYNAMIC_DRAW;
  exports.ELEMENT_ARRAY_BUFFER = ELEMENT_ARRAY_BUFFER;
  exports.ELEMENT_ARRAY_BUFFER_BINDING = ELEMENT_ARRAY_BUFFER_BINDING;
  exports.EQUAL = EQUAL;
  exports.FASTEST = FASTEST;
  exports.FLOAT = FLOAT;
  exports.FLOAT_MAT2 = FLOAT_MAT2;
  exports.FLOAT_MAT3 = FLOAT_MAT3;
  exports.FLOAT_MAT4 = FLOAT_MAT4;
  exports.FLOAT_VEC2 = FLOAT_VEC2;
  exports.FLOAT_VEC3 = FLOAT_VEC3;
  exports.FLOAT_VEC4 = FLOAT_VEC4;
  exports.FRAGMENT_SHADER = FRAGMENT_SHADER;
  exports.FRAMEBUFFER = FRAMEBUFFER;
  exports.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = FRAMEBUFFER_ATTACHMENT_OBJECT_NAME;
  exports.FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE;
  exports.FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE;
  exports.FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL;
  exports.FRAMEBUFFER_BINDING = FRAMEBUFFER_BINDING;
  exports.FRAMEBUFFER_COMPLETE = FRAMEBUFFER_COMPLETE;
  exports.FRAMEBUFFER_INCOMPLETE_ATTACHMENT = FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
  exports.FRAMEBUFFER_INCOMPLETE_DIMENSIONS = FRAMEBUFFER_INCOMPLETE_DIMENSIONS;
  exports.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT;
  exports.FRAMEBUFFER_UNSUPPORTED = FRAMEBUFFER_UNSUPPORTED;
  exports.FRONT = FRONT;
  exports.FRONT_AND_BACK = FRONT_AND_BACK;
  exports.FRONT_FACE = FRONT_FACE;
  exports.FUNC_ADD = FUNC_ADD;
  exports.FUNC_REVERSE_SUBTRACT = FUNC_REVERSE_SUBTRACT;
  exports.FUNC_SUBTRACT = FUNC_SUBTRACT;
  exports.GENERATE_MIPMAP_HINT = GENERATE_MIPMAP_HINT;
  exports.GEQUAL = GEQUAL;
  exports.GREATER = GREATER;
  exports.GREEN_BITS = GREEN_BITS;
  exports.OesTextureHalfFloat = OesTextureHalfFloat;
  exports.HALF_FLOAT_OES = HALF_FLOAT_OES;
  exports.HIGH_FLOAT = HIGH_FLOAT;
  exports.HIGH_INT = HIGH_INT;
  exports.INCR = INCR;
  exports.INCR_WRAP = INCR_WRAP;
  exports.INT = INT;
  exports.INT_VEC2 = INT_VEC2;
  exports.INT_VEC3 = INT_VEC3;
  exports.INT_VEC4 = INT_VEC4;
  exports.INVALID_ENUM = INVALID_ENUM;
  exports.INVALID_FRAMEBUFFER_OPERATION = INVALID_FRAMEBUFFER_OPERATION;
  exports.INVALID_OPERATION = INVALID_OPERATION;
  exports.INVALID_VALUE = INVALID_VALUE;
  exports.INVERT = INVERT;
  exports.KEEP = KEEP;
  exports.LEQUAL = LEQUAL;
  exports.LESS = LESS;
  exports.LINEAR = LINEAR;
  exports.LINEAR_MIPMAP_LINEAR = LINEAR_MIPMAP_LINEAR;
  exports.LINEAR_MIPMAP_NEAREST = LINEAR_MIPMAP_NEAREST;
  exports.LINES = LINES;
  exports.LINE_LOOP = LINE_LOOP;
  exports.LINE_STRIP = LINE_STRIP;
  exports.LINE_WIDTH = LINE_WIDTH;
  exports.LINK_STATUS = LINK_STATUS;
  exports.LOW_FLOAT = LOW_FLOAT;
  exports.LOW_INT = LOW_INT;
  exports.LUMINANCE = LUMINANCE;
  exports.LUMINANCE_ALPHA = LUMINANCE_ALPHA;
  exports.MAX_COMBINED_TEXTURE_IMAGE_UNITS = MAX_COMBINED_TEXTURE_IMAGE_UNITS;
  exports.MAX_CUBE_MAP_TEXTURE_SIZE = MAX_CUBE_MAP_TEXTURE_SIZE;
  exports.MAX_FRAGMENT_UNIFORM_VECTORS = MAX_FRAGMENT_UNIFORM_VECTORS;
  exports.MAX_RENDERBUFFER_SIZE = MAX_RENDERBUFFER_SIZE;
  exports.MAX_TEXTURE_IMAGE_UNITS = MAX_TEXTURE_IMAGE_UNITS;
  exports.MAX_TEXTURE_SIZE = MAX_TEXTURE_SIZE;
  exports.MAX_VARYING_VECTORS = MAX_VARYING_VECTORS;
  exports.MAX_VERTEX_ATTRIBS = MAX_VERTEX_ATTRIBS;
  exports.MAX_VERTEX_TEXTURE_IMAGE_UNITS = MAX_VERTEX_TEXTURE_IMAGE_UNITS;
  exports.MAX_VERTEX_UNIFORM_VECTORS = MAX_VERTEX_UNIFORM_VECTORS;
  exports.MAX_VIEWPORT_DIMS = MAX_VIEWPORT_DIMS;
  exports.MEDIUM_FLOAT = MEDIUM_FLOAT;
  exports.MEDIUM_INT = MEDIUM_INT;
  exports.MIRRORED_REPEAT = MIRRORED_REPEAT;
  exports.NEAREST = NEAREST;
  exports.NEAREST_MIPMAP_LINEAR = NEAREST_MIPMAP_LINEAR;
  exports.NEAREST_MIPMAP_NEAREST = NEAREST_MIPMAP_NEAREST;
  exports.NEVER = NEVER;
  exports.NICEST = NICEST;
  exports.NONE = NONE;
  exports.NOTEQUAL = NOTEQUAL;
  exports.NO_ERROR = NO_ERROR;
  exports.ONE = ONE;
  exports.ONE_MINUS_CONSTANT_ALPHA = ONE_MINUS_CONSTANT_ALPHA;
  exports.ONE_MINUS_CONSTANT_COLOR = ONE_MINUS_CONSTANT_COLOR;
  exports.ONE_MINUS_DST_ALPHA = ONE_MINUS_DST_ALPHA;
  exports.ONE_MINUS_DST_COLOR = ONE_MINUS_DST_COLOR;
  exports.ONE_MINUS_SRC_ALPHA = ONE_MINUS_SRC_ALPHA;
  exports.ONE_MINUS_SRC_COLOR = ONE_MINUS_SRC_COLOR;
  exports.OUT_OF_MEMORY = OUT_OF_MEMORY;
  exports.PACK_ALIGNMENT = PACK_ALIGNMENT;
  exports.POINTS = POINTS;
  exports.POLYGON_OFFSET_FACTOR = POLYGON_OFFSET_FACTOR;
  exports.POLYGON_OFFSET_FILL = POLYGON_OFFSET_FILL;
  exports.POLYGON_OFFSET_UNITS = POLYGON_OFFSET_UNITS;
  exports.RED_BITS = RED_BITS;
  exports.RENDERBUFFER = RENDERBUFFER;
  exports.RENDERBUFFER_ALPHA_SIZE = RENDERBUFFER_ALPHA_SIZE;
  exports.RENDERBUFFER_BINDING = RENDERBUFFER_BINDING;
  exports.RENDERBUFFER_BLUE_SIZE = RENDERBUFFER_BLUE_SIZE;
  exports.RENDERBUFFER_DEPTH_SIZE = RENDERBUFFER_DEPTH_SIZE;
  exports.RENDERBUFFER_GREEN_SIZE = RENDERBUFFER_GREEN_SIZE;
  exports.RENDERBUFFER_HEIGHT = RENDERBUFFER_HEIGHT;
  exports.RENDERBUFFER_INTERNAL_FORMAT = RENDERBUFFER_INTERNAL_FORMAT;
  exports.RENDERBUFFER_RED_SIZE = RENDERBUFFER_RED_SIZE;
  exports.RENDERBUFFER_STENCIL_SIZE = RENDERBUFFER_STENCIL_SIZE;
  exports.RENDERBUFFER_WIDTH = RENDERBUFFER_WIDTH;
  exports.RENDERER = RENDERER;
  exports.REPEAT = REPEAT;
  exports.REPLACE = REPLACE;
  exports.RGB = RGB;
  exports.RGB565 = RGB565;
  exports.RGB5_A1 = RGB5_A1;
  exports.RGBA = RGBA;
  exports.RGBA4 = RGBA4;
  exports.SAMPLER_2D = SAMPLER_2D;
  exports.SAMPLER_CUBE = SAMPLER_CUBE;
  exports.SAMPLES = SAMPLES;
  exports.SAMPLE_ALPHA_TO_COVERAGE = SAMPLE_ALPHA_TO_COVERAGE;
  exports.SAMPLE_BUFFERS = SAMPLE_BUFFERS;
  exports.SAMPLE_COVERAGE = SAMPLE_COVERAGE;
  exports.SAMPLE_COVERAGE_INVERT = SAMPLE_COVERAGE_INVERT;
  exports.SAMPLE_COVERAGE_VALUE = SAMPLE_COVERAGE_VALUE;
  exports.SCISSOR_BOX = SCISSOR_BOX;
  exports.SCISSOR_TEST = SCISSOR_TEST;
  exports.SHADER_TYPE = SHADER_TYPE;
  exports.SHADING_LANGUAGE_VERSION = SHADING_LANGUAGE_VERSION;
  exports.SHORT = SHORT;
  exports.SRC_ALPHA = SRC_ALPHA;
  exports.SRC_ALPHA_SATURATE = SRC_ALPHA_SATURATE;
  exports.SRC_COLOR = SRC_COLOR;
  exports.STATIC_DRAW = STATIC_DRAW;
  exports.STENCIL_ATTACHMENT = STENCIL_ATTACHMENT;
  exports.STENCIL_BACK_FAIL = STENCIL_BACK_FAIL;
  exports.STENCIL_BACK_FUNC = STENCIL_BACK_FUNC;
  exports.STENCIL_BACK_PASS_DEPTH_FAIL = STENCIL_BACK_PASS_DEPTH_FAIL;
  exports.STENCIL_BACK_PASS_DEPTH_PASS = STENCIL_BACK_PASS_DEPTH_PASS;
  exports.STENCIL_BACK_REF = STENCIL_BACK_REF;
  exports.STENCIL_BACK_VALUE_MASK = STENCIL_BACK_VALUE_MASK;
  exports.STENCIL_BACK_WRITEMASK = STENCIL_BACK_WRITEMASK;
  exports.STENCIL_BITS = STENCIL_BITS;
  exports.STENCIL_BUFFER_BIT = STENCIL_BUFFER_BIT;
  exports.STENCIL_CLEAR_VALUE = STENCIL_CLEAR_VALUE;
  exports.STENCIL_FAIL = STENCIL_FAIL;
  exports.STENCIL_FUNC = STENCIL_FUNC;
  exports.STENCIL_INDEX = STENCIL_INDEX;
  exports.STENCIL_INDEX8 = STENCIL_INDEX8;
  exports.STENCIL_PASS_DEPTH_FAIL = STENCIL_PASS_DEPTH_FAIL;
  exports.STENCIL_PASS_DEPTH_PASS = STENCIL_PASS_DEPTH_PASS;
  exports.STENCIL_REF = STENCIL_REF;
  exports.STENCIL_TEST = STENCIL_TEST;
  exports.STENCIL_VALUE_MASK = STENCIL_VALUE_MASK;
  exports.STENCIL_WRITEMASK = STENCIL_WRITEMASK;
  exports.STREAM_DRAW = STREAM_DRAW;
  exports.SUBPIXEL_BITS = SUBPIXEL_BITS;
  exports.TEXTURE = TEXTURE;
  exports.TEXTURE0 = TEXTURE0;
  exports.TEXTURE1 = TEXTURE1;
  exports.TEXTURE10 = TEXTURE10;
  exports.TEXTURE11 = TEXTURE11;
  exports.TEXTURE12 = TEXTURE12;
  exports.TEXTURE13 = TEXTURE13;
  exports.TEXTURE14 = TEXTURE14;
  exports.TEXTURE15 = TEXTURE15;
  exports.TEXTURE16 = TEXTURE16;
  exports.TEXTURE17 = TEXTURE17;
  exports.TEXTURE18 = TEXTURE18;
  exports.TEXTURE19 = TEXTURE19;
  exports.TEXTURE2 = TEXTURE2;
  exports.TEXTURE20 = TEXTURE20;
  exports.TEXTURE21 = TEXTURE21;
  exports.TEXTURE22 = TEXTURE22;
  exports.TEXTURE23 = TEXTURE23;
  exports.TEXTURE24 = TEXTURE24;
  exports.TEXTURE25 = TEXTURE25;
  exports.TEXTURE26 = TEXTURE26;
  exports.TEXTURE27 = TEXTURE27;
  exports.TEXTURE28 = TEXTURE28;
  exports.TEXTURE29 = TEXTURE29;
  exports.TEXTURE3 = TEXTURE3;
  exports.TEXTURE30 = TEXTURE30;
  exports.TEXTURE31 = TEXTURE31;
  exports.TEXTURE4 = TEXTURE4;
  exports.TEXTURE5 = TEXTURE5;
  exports.TEXTURE6 = TEXTURE6;
  exports.TEXTURE7 = TEXTURE7;
  exports.TEXTURE8 = TEXTURE8;
  exports.TEXTURE9 = TEXTURE9;
  exports.TEXTURE_2D = TEXTURE_2D;
  exports.TEXTURE_BINDING_2D = TEXTURE_BINDING_2D;
  exports.TEXTURE_BINDING_CUBE_MAP = TEXTURE_BINDING_CUBE_MAP;
  exports.TEXTURE_CUBE_MAP = TEXTURE_CUBE_MAP;
  exports.TEXTURE_CUBE_MAP_NEGATIVE_X = TEXTURE_CUBE_MAP_NEGATIVE_X;
  exports.TEXTURE_CUBE_MAP_NEGATIVE_Y = TEXTURE_CUBE_MAP_NEGATIVE_Y;
  exports.TEXTURE_CUBE_MAP_NEGATIVE_Z = TEXTURE_CUBE_MAP_NEGATIVE_Z;
  exports.TEXTURE_CUBE_MAP_POSITIVE_X = TEXTURE_CUBE_MAP_POSITIVE_X;
  exports.TEXTURE_CUBE_MAP_POSITIVE_Y = TEXTURE_CUBE_MAP_POSITIVE_Y;
  exports.TEXTURE_CUBE_MAP_POSITIVE_Z = TEXTURE_CUBE_MAP_POSITIVE_Z;
  exports.TEXTURE_MAG_FILTER = TEXTURE_MAG_FILTER;
  exports.TEXTURE_MIN_FILTER = TEXTURE_MIN_FILTER;
  exports.TEXTURE_WRAP_S = TEXTURE_WRAP_S;
  exports.TEXTURE_WRAP_T = TEXTURE_WRAP_T;
  exports.TRIANGLES = TRIANGLES;
  exports.TRIANGLE_FAN = TRIANGLE_FAN;
  exports.TRIANGLE_STRIP = TRIANGLE_STRIP;
  exports.UNPACK_ALIGNMENT = UNPACK_ALIGNMENT;
  exports.UNPACK_COLORSPACE_CONVERSION_WEBGL = UNPACK_COLORSPACE_CONVERSION_WEBGL;
  exports.UNPACK_FLIP_Y_WEBGL = UNPACK_FLIP_Y_WEBGL;
  exports.UNPACK_PREMULTIPLY_ALPHA_WEBGL = UNPACK_PREMULTIPLY_ALPHA_WEBGL;
  exports.UNSIGNED_BYTE = UNSIGNED_BYTE;
  exports.UNSIGNED_INT = UNSIGNED_INT;
  exports.UNSIGNED_SHORT = UNSIGNED_SHORT;
  exports.UNSIGNED_SHORT_4_4_4_4 = UNSIGNED_SHORT_4_4_4_4;
  exports.UNSIGNED_SHORT_5_5_5_1 = UNSIGNED_SHORT_5_5_5_1;
  exports.UNSIGNED_SHORT_5_6_5 = UNSIGNED_SHORT_5_6_5;
  exports.VALIDATE_STATUS = VALIDATE_STATUS;
  exports.VENDOR = VENDOR;
  exports.VERSION = VERSION;
  exports.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = VERTEX_ATTRIB_ARRAY_BUFFER_BINDING;
  exports.VERTEX_ATTRIB_ARRAY_ENABLED = VERTEX_ATTRIB_ARRAY_ENABLED;
  exports.VERTEX_ATTRIB_ARRAY_NORMALIZED = VERTEX_ATTRIB_ARRAY_NORMALIZED;
  exports.VERTEX_ATTRIB_ARRAY_POINTER = VERTEX_ATTRIB_ARRAY_POINTER;
  exports.VERTEX_ATTRIB_ARRAY_SIZE = VERTEX_ATTRIB_ARRAY_SIZE;
  exports.VERTEX_ATTRIB_ARRAY_STRIDE = VERTEX_ATTRIB_ARRAY_STRIDE;
  exports.VERTEX_ATTRIB_ARRAY_TYPE = VERTEX_ATTRIB_ARRAY_TYPE;
  exports.VERTEX_SHADER = VERTEX_SHADER;
  exports.VIEWPORT = VIEWPORT;
  exports.ZERO = ZERO;
  exports.ActiveInfo = ActiveInfo;
  exports.AngleInstancedArrays = AngleInstancedArrays;
  exports.Buffer = Buffer;
  exports.CompressedTextureAtc = CompressedTextureAtc;
  exports.CompressedTextureETC1 = CompressedTextureETC1;
  exports.CompressedTexturePvrtc = CompressedTexturePvrtc;
  exports.CompressedTextureS3TC = CompressedTextureS3TC;
  exports.ContextAttributes = ContextAttributes;
  exports.ContextEvent = ContextEvent;
  exports.DebugRendererInfo = DebugRendererInfo;
  exports.DebugShaders = DebugShaders;
  exports.DepthTexture = DepthTexture;
  exports.DrawBuffers = DrawBuffers;
  exports.ExtBlendMinMax = ExtBlendMinMax;
  exports.ExtFragDepth = ExtFragDepth;
  exports.ExtShaderTextureLod = ExtShaderTextureLod;
  exports.ExtTextureFilterAnisotropic = ExtTextureFilterAnisotropic;
  exports.Framebuffer = Framebuffer;
  exports.LoseContext = LoseContext;
  exports.OesElementIndexUint = OesElementIndexUint;
  exports.OesStandardDerivatives = OesStandardDerivatives;
  exports.OesTextureFloat = OesTextureFloat;
  exports.OesTextureFloatLinear = OesTextureFloatLinear;
  exports.OesTextureHalfFloatLinear = OesTextureHalfFloatLinear;
  exports.OesVertexArrayObject = OesVertexArrayObject;
  exports.Program = Program;
  exports.Renderbuffer = Renderbuffer;
  exports.Shader = Shader;
  exports.ShaderPrecisionFormat = ShaderPrecisionFormat;
  exports.Texture = Texture;
  exports.UniformLocation = UniformLocation;
  exports.VertexArrayObject = VertexArrayObject;
});
