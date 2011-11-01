
class OESVertexArrayObject native "OESVertexArrayObject" {

  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  WebGLVertexArrayObjectOES createVertexArrayOES() native;

  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
