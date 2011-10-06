// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _OESVertexArrayObjectWrappingImplementation extends DOMWrapperBase implements OESVertexArrayObject {
  _OESVertexArrayObjectWrappingImplementation() : super() {}

  static create__OESVertexArrayObjectWrappingImplementation() native {
    return new _OESVertexArrayObjectWrappingImplementation();
  }

  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    _bindVertexArrayOES(this, arrayObject);
    return;
  }
  static void _bindVertexArrayOES(receiver, arrayObject) native;

  WebGLVertexArrayObjectOES createVertexArrayOES() {
    return _createVertexArrayOES(this);
  }
  static WebGLVertexArrayObjectOES _createVertexArrayOES(receiver) native;

  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    _deleteVertexArrayOES(this, arrayObject);
    return;
  }
  static void _deleteVertexArrayOES(receiver, arrayObject) native;

  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    return _isVertexArrayOES(this, arrayObject);
  }
  static bool _isVertexArrayOES(receiver, arrayObject) native;

  String get typeName() { return "OESVertexArrayObject"; }
}
