
class _OESVertexArrayObjectJs extends _DOMTypeJs implements OESVertexArrayObject native "*OESVertexArrayObject" {

  static final int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  void bindVertexArrayOES(_WebGLVertexArrayObjectOESJs arrayObject) native;

  _WebGLVertexArrayObjectOESJs createVertexArrayOES() native;

  void deleteVertexArrayOES(_WebGLVertexArrayObjectOESJs arrayObject) native;

  bool isVertexArrayOES(_WebGLVertexArrayObjectOESJs arrayObject) native;
}
