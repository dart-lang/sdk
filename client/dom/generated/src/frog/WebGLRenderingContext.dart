
class WebGLRenderingContext extends CanvasRenderingContext native "WebGLRenderingContext" {

  int drawingBufferHeight;

  int drawingBufferWidth;

  void activeTexture(int texture) native;

  void attachShader(WebGLProgram program, WebGLShader shader) native;

  void bindAttribLocation(WebGLProgram program, int index, String name) native;

  void bindBuffer(int target, WebGLBuffer buffer) native;

  void bindFramebuffer(int target, WebGLFramebuffer framebuffer) native;

  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer) native;

  void bindTexture(int target, WebGLTexture texture) native;

  void blendColor(num red, num green, num blue, num alpha) native;

  void blendEquation(int mode) native;

  void blendEquationSeparate(int modeRGB, int modeAlpha) native;

  void blendFunc(int sfactor, int dfactor) native;

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) native;

  void bufferData(int target, var data_OR_size, int usage) native;

  void bufferSubData(int target, int offset, var data) native;

  int checkFramebufferStatus(int target) native;

  void clear(int mask) native;

  void clearColor(num red, num green, num blue, num alpha) native;

  void clearDepth(num depth) native;

  void clearStencil(int s) native;

  void colorMask(bool red, bool green, bool blue, bool alpha) native;

  void compileShader(WebGLShader shader) native;

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) native;

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) native;

  WebGLBuffer createBuffer() native;

  WebGLFramebuffer createFramebuffer() native;

  WebGLProgram createProgram() native;

  WebGLRenderbuffer createRenderbuffer() native;

  WebGLShader createShader(int type) native;

  WebGLTexture createTexture() native;

  void cullFace(int mode) native;

  void deleteBuffer(WebGLBuffer buffer) native;

  void deleteFramebuffer(WebGLFramebuffer framebuffer) native;

  void deleteProgram(WebGLProgram program) native;

  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer) native;

  void deleteShader(WebGLShader shader) native;

  void deleteTexture(WebGLTexture texture) native;

  void depthFunc(int func) native;

  void depthMask(bool flag) native;

  void depthRange(num zNear, num zFar) native;

  void detachShader(WebGLProgram program, WebGLShader shader) native;

  void disable(int cap) native;

  void disableVertexAttribArray(int index) native;

  void drawArrays(int mode, int first, int count) native;

  void drawElements(int mode, int count, int type, int offset) native;

  void enable(int cap) native;

  void enableVertexAttribArray(int index) native;

  void finish() native;

  void flush() native;

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, WebGLRenderbuffer renderbuffer) native;

  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level) native;

  void frontFace(int mode) native;

  void generateMipmap(int target) native;

  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index) native;

  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index) native;

  void getAttachedShaders(WebGLProgram program) native;

  int getAttribLocation(WebGLProgram program, String name) native;

  void getBufferParameter() native;

  WebGLContextAttributes getContextAttributes() native;

  int getError() native;

  void getExtension(String name) native;

  void getFramebufferAttachmentParameter() native;

  void getParameter() native;

  String getProgramInfoLog(WebGLProgram program) native;

  void getProgramParameter() native;

  void getRenderbufferParameter() native;

  String getShaderInfoLog(WebGLShader shader) native;

  void getShaderParameter() native;

  String getShaderSource(WebGLShader shader) native;

  void getSupportedExtensions() native;

  void getTexParameter() native;

  void getUniform() native;

  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) native;

  void getVertexAttrib() native;

  int getVertexAttribOffset(int index, int pname) native;

  void hint(int target, int mode) native;

  bool isBuffer(WebGLBuffer buffer) native;

  bool isContextLost() native;

  bool isEnabled(int cap) native;

  bool isFramebuffer(WebGLFramebuffer framebuffer) native;

  bool isProgram(WebGLProgram program) native;

  bool isRenderbuffer(WebGLRenderbuffer renderbuffer) native;

  bool isShader(WebGLShader shader) native;

  bool isTexture(WebGLTexture texture) native;

  void lineWidth(num width) native;

  void linkProgram(WebGLProgram program) native;

  void pixelStorei(int pname, int param) native;

  void polygonOffset(num factor, num units) native;

  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels) native;

  void releaseShaderCompiler() native;

  void renderbufferStorage(int target, int internalformat, int width, int height) native;

  void sampleCoverage(num value, bool invert) native;

  void scissor(int x, int y, int width, int height) native;

  void shaderSource(WebGLShader shader, String string) native;

  void stencilFunc(int func, int ref, int mask) native;

  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  void stencilMask(int mask) native;

  void stencilMaskSeparate(int face, int mask) native;

  void stencilOp(int fail, int zfail, int zpass) native;

  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels, [int format = null, int type = null, ArrayBufferView pixels = null]) native;

  void texParameterf(int target, int pname, num param) native;

  void texParameteri(int target, int pname, int param) native;

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels, [int type = null, ArrayBufferView pixels = null]) native;

  void uniform1f(WebGLUniformLocation location, num x) native;

  void uniform1fv(WebGLUniformLocation location, Float32Array v) native;

  void uniform1i(WebGLUniformLocation location, int x) native;

  void uniform1iv(WebGLUniformLocation location, Int32Array v) native;

  void uniform2f(WebGLUniformLocation location, num x, num y) native;

  void uniform2fv(WebGLUniformLocation location, Float32Array v) native;

  void uniform2i(WebGLUniformLocation location, int x, int y) native;

  void uniform2iv(WebGLUniformLocation location, Int32Array v) native;

  void uniform3f(WebGLUniformLocation location, num x, num y, num z) native;

  void uniform3fv(WebGLUniformLocation location, Float32Array v) native;

  void uniform3i(WebGLUniformLocation location, int x, int y, int z) native;

  void uniform3iv(WebGLUniformLocation location, Int32Array v) native;

  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w) native;

  void uniform4fv(WebGLUniformLocation location, Float32Array v) native;

  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w) native;

  void uniform4iv(WebGLUniformLocation location, Int32Array v) native;

  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  void useProgram(WebGLProgram program) native;

  void validateProgram(WebGLProgram program) native;

  void vertexAttrib1f(int indx, num x) native;

  void vertexAttrib1fv(int indx, Float32Array values) native;

  void vertexAttrib2f(int indx, num x, num y) native;

  void vertexAttrib2fv(int indx, Float32Array values) native;

  void vertexAttrib3f(int indx, num x, num y, num z) native;

  void vertexAttrib3fv(int indx, Float32Array values) native;

  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  void vertexAttrib4fv(int indx, Float32Array values) native;

  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) native;

  void viewport(int x, int y, int width, int height) native;
}
