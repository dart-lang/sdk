
class _WebGLContextAttributesImpl extends _DOMTypeBase implements WebGLContextAttributes {
  _WebGLContextAttributesImpl._wrap(ptr) : super._wrap(ptr);

  bool get alpha() => _wrap(_ptr.alpha);

  void set alpha(bool value) { _ptr.alpha = _unwrap(value); }

  bool get antialias() => _wrap(_ptr.antialias);

  void set antialias(bool value) { _ptr.antialias = _unwrap(value); }

  bool get depth() => _wrap(_ptr.depth);

  void set depth(bool value) { _ptr.depth = _unwrap(value); }

  bool get premultipliedAlpha() => _wrap(_ptr.premultipliedAlpha);

  void set premultipliedAlpha(bool value) { _ptr.premultipliedAlpha = _unwrap(value); }

  bool get preserveDrawingBuffer() => _wrap(_ptr.preserveDrawingBuffer);

  void set preserveDrawingBuffer(bool value) { _ptr.preserveDrawingBuffer = _unwrap(value); }

  bool get stencil() => _wrap(_ptr.stencil);

  void set stencil(bool value) { _ptr.stencil = _unwrap(value); }
}
