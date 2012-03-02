
class _OESVertexArrayObjectImpl implements OESVertexArrayObject native "*OESVertexArrayObject" {

  static final int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  void bindVertexArrayOES(_WebGLVertexArrayObjectOESImpl arrayObject) native;

  _WebGLVertexArrayObjectOESImpl createVertexArrayOES() native;

  void deleteVertexArrayOES(_WebGLVertexArrayObjectOESImpl arrayObject) native;

  bool isVertexArrayOES(_WebGLVertexArrayObjectOESImpl arrayObject) native;
}
