
class OESVertexArrayObjectJS implements OESVertexArrayObject native "*OESVertexArrayObject" {

  static final int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  void bindVertexArrayOES(WebGLVertexArrayObjectOESJS arrayObject) native;

  WebGLVertexArrayObjectOESJS createVertexArrayOES() native;

  void deleteVertexArrayOES(WebGLVertexArrayObjectOESJS arrayObject) native;

  bool isVertexArrayOES(WebGLVertexArrayObjectOESJS arrayObject) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
