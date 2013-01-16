// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library android_extension;

// The simplest way to call native code: top-level functions.
int systemRand() native "SystemRand";
void systemSrand(int seed) native "SystemSrand";
void log(String what) native "Log";

// EGL functions.
void glSwapBuffers() native "SwapBuffers";

// GL functions.
void glAttachShader(int program, int shader) native "GLAttachShader";
void glBindBuffer(int target, int buffer) native "GLBindBuffer";
void glBufferData(int target, List data, int usage) native "GLBufferData";
void glClearColor(num r, num g, num b, num alpha) native "GLClearColor";
void glClearDepth(num depth) native "GLClearDepth";
void glClear(int mask) native "GLClear";
void glCompileShader(int shader) native "GLCompileShader";
int glCreateBuffer() native "GLCreateBuffer";
int glCreateProgram() native "GLCreateProgram";
int glCreateShader(int shaderType) native "GLCreateShader";
void glDrawArrays(int mode, int first, int count) native "GLDrawArrays";
void glEnableVertexAttribArray(int index) native "GLEnableVertexAttribArray";
int glGetAttribLocation(int program, String name) native "GLGetAttribLocation";
int glGetError() native "GLGetError";
int glGetProgramParameter(int program, int param)
    native "GLGetProgramParameter";
int glGetShaderParameter(int shader, int param) native "GLGetShaderParameter";
int glGetUniformLocation(int program, String name)
    native "GLGetUniformLocation";
void glLinkProgram(int program) native "GLLinkProgram";
void glShaderSource(int shader, String source) native "GLShaderSource";
void glUniform1f(int location, double v0) native "GLUniform1f";
void glUniform2f(int location, double v0, double v1) native "GLUniform2f";
void glUniform3f(int location, double v0, double v1, double v2)
    native "GLUniform3f";
void glUniform4f(int location, double v0, double v1, double v2, double v3)
    native "GLUniform4f";
void glUniform1i(int location, int v0) native "GLUniform1i";
void glUniform2i(int location, int v0, int v1) native "GLUniform2i";
void glUniform3i(int location, int v0, int v1, int v2) native "GLUniform3i";
void glUniform4i(int location, int v0, int v1, int v2, int v3)
    native "GLUniform4i";
void glUniform1fv(int location, List values) native "GLUniform1fv";
void glUniform2fv(int location, List values) native "GLUniform2fv";
void glUniform3fv(int location, List values) native "GLUniform3fv";
void glUniform4fv(int location, List values) native "GLUniform4fv";
void glUniform1iv(int location, List values) native "GLUniform1iv";
void glUniform2iv(int location, List values) native "GLUniform2iv";
void glUniform3iv(int location, List values) native "GLUniform3iv";
void glUniform4iv(int location, List values) native "GLUniform4iv";
void glUseProgram(int program) native "GLUseProgram";
void glVertexAttribPointer(int index, int size, int type, bool normalized,
    int stride, int pointer) native "GLVertexAttribPointer";
void glViewport(int x, int y, int width, int height) native "GLViewport";

int glArrayBuffer() native "GLArrayBuffer";
int glColorBufferBit() native "GLColorBufferBit";
int glCompileStatus() native "GLCompileStatus";
int glDeleteStatus() native "GLDeleteStatus";
int glDepthBufferBit() native "GLDepthBufferBit";
int glFloat() native "GLFloat";
int glFragmentShader() native "GLFragmentShader";
int glLinkStatus() native "GLLinkStatus";
int glStaticDraw() native "GLStaticDraw";
int glTriangleStrip() native "GLTriangleStrip";
int glTriangles() native "GLTriangles";
int glTrue() native "GLTrue";
int glValidateStatus() native "GLValidateStatus";
int glVertexShader() native "GLVertexShader";

String glGetShaderInfoLog(int shader) native "GLGetShaderInfoLog";
String glGetProgramInfoLog(int program) native "GLGetProgramInfoLog";

class WebGLRenderingContext {
  WebGLRenderingContext();

  static get ARRAY_BUFFER => glArrayBuffer();
  static get COLOR_BUFFER_BIT => glColorBufferBit();
  static get COMPILE_STATUS => glCompileStatus();
  static get DELETE_STATUS => glDeleteStatus();
  static get DEPTH_BUFFER_BIT => glDepthBufferBit();
  static get FLOAT => glFloat();
  static get FRAGMENT_SHADER => glFragmentShader();
  static get LINK_STATUS => glLinkStatus();
  static get STATIC_DRAW => glStaticDraw();
  static get TRUE => glTrue();
  static get TRIANGLE_STRIP => glTriangleStrip();
  static get TRIANGLES => glTriangles();
  static get VALIDATE_STATUS => glValidateStatus();
  static get VERTEX_SHADER => glVertexShader();

  attachShader(program, shader) => glAttachShader(program, shader);
  bindBuffer(target, buffer) => glBindBuffer(target, buffer);
  bufferData(target, data, usage) => glBufferData(target, data, usage);
  clearColor(r, g, b, alpha) => glClearColor(r, g, b, alpha);
  clearDepth(depth) => glClearDepth(depth);
  clear(mask) => glClear(mask);
  compileShader(shader) => glCompileShader(shader);
  createBuffer() => glCreateBuffer();
  createProgram() => glCreateProgram();
  createShader(shaderType) => glCreateShader(shaderType);
  drawArrays(mode, first, count) => glDrawArrays(mode, first, count);
  enableVertexAttribArray(index) => glEnableVertexAttribArray(index);
  getAttribLocation(program, name) => glGetAttribLocation(program, name);
  getError() => glGetError();
  getProgramParameter(program, name) {
    var rtn = glGetProgramParameter(program, name);
    if (name == DELETE_STATUS ||
        name == LINK_STATUS ||
        name == VALIDATE_STATUS) {
      return (rtn == 0) ? false : true;
    }
    return rtn;
  }
  getShaderParameter(shader, name) {
    var rtn = glGetShaderParameter(shader, name);
    if (name == DELETE_STATUS || name == COMPILE_STATUS) {
      return (rtn == 0) ? false : true;
    }
    return rtn;
  }
  getUniformLocation(program, name) => glGetUniformLocation(program, name);
  linkProgram(program) => glLinkProgram(program);
  shaderSource(shader, source) => glShaderSource(shader, source);
  uniform1f(location, v0) => glUniform1f(location, v0);
  uniform2f(location, v0, v1) => glUniform2f(location, v0, v1);
  uniform3f(location, v0, v1, v2) => glUniform3f(location, v0, v1, v2);
  uniform4f(location, v0, v1, v2, v3) => glUniform4f(location, v0, v1, v2, v3);
  uniform1i(location, v0) => glUniform1i(location, v0);
  uniform2i(location, v0, v1) => glUniform2i(location, v0, v1);
  uniform3i(location, v0, v1, v2) => glUniform3i(location, v0, v1, v2);
  uniform4i(location, v0, v1, v2, v3) => glUniform4i(location, v0, v1, v2, v3);
  uniform1fv(location, values) => glUniform1fv(location, values);
  uniform2fv(location, values) => glUniform2fv(location, values);
  uniform3fv(location, values) => glUniform3fv(location, values);
  uniform4fv(location, values) => glUniform4fv(location, values);
  uniform1iv(location, values) => glUniform1iv(location, values);
  uniform2iv(location, values) => glUniform2iv(location, values);
  uniform3iv(location, values) => glUniform3iv(location, values);
  uniform4iv(location, values) => glUniform4iv(location, values);
  useProgram(program) => glUseProgram(program);
  vertexAttribPointer(index, size, type, normalized, stride, pointer) =>
    glVertexAttribPointer(index, size, type, normalized, stride, pointer);
  viewport(x, y, width, height) => glViewport(x, y, width, height);
  getShaderInfoLog(shader) => glGetShaderInfoLog(shader);
  getProgramInfoLog(program) => glGetProgramInfoLog(program);

  // TODO(vsm): Kill.
  noSuchMethod(invocation) {
      throw new Exception('Unimplemented ${invocation.memberName}');
  }
}

var gl = new WebGLRenderingContext();

//------------------------------------------------------------------
// Simple audio support.

void playBackground(String path) native "PlayBackground";
void stopBackground() native "StopBackground";

//-------------------------------------------------------------------
// Set up print().

get _printClosure => (s) {
  try {
    log(s);
  } catch (_) {
    throw(s);
  }
};

//------------------------------------------------------------------
// Temp hack for compat with WebGL.

class Float32Array extends List<double> {
  Float32Array.fromList(List a) {
    addAll(a);
  }
}

