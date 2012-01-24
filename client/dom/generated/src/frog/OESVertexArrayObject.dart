
class OESVertexArrayObjectJs extends DOMTypeJs implements OESVertexArrayObject native "*OESVertexArrayObject" {

  static final int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  void bindVertexArrayOES(WebGLVertexArrayObjectOESJs arrayObject) native;

  WebGLVertexArrayObjectOESJs createVertexArrayOES() native;

  void deleteVertexArrayOES(WebGLVertexArrayObjectOESJs arrayObject) native;

  bool isVertexArrayOES(WebGLVertexArrayObjectOESJs arrayObject) native;
}
