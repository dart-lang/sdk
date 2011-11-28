
class OESVertexArrayObject native "*OESVertexArrayObject" {

  static final int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  WebGLVertexArrayObjectOES createVertexArrayOES() native;

  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
