
class _WebGLDebugShadersImpl extends _DOMTypeBase implements WebGLDebugShaders {
  _WebGLDebugShadersImpl._wrap(ptr) : super._wrap(ptr);

  String getTranslatedShaderSource(WebGLShader shader) {
    return _wrap(_ptr.getTranslatedShaderSource(_unwrap(shader)));
  }
}
