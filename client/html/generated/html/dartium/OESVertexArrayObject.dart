
class _OESVertexArrayObjectImpl extends _DOMTypeBase implements OESVertexArrayObject {
  _OESVertexArrayObjectImpl._wrap(ptr) : super._wrap(ptr);

  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    _ptr.bindVertexArrayOES(_unwrap(arrayObject));
    return;
  }

  WebGLVertexArrayObjectOES createVertexArrayOES() {
    return _wrap(_ptr.createVertexArrayOES());
  }

  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    _ptr.deleteVertexArrayOES(_unwrap(arrayObject));
    return;
  }

  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    return _wrap(_ptr.isVertexArrayOES(_unwrap(arrayObject)));
  }
}
