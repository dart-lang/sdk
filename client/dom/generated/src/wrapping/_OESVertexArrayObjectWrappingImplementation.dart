// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _OESVertexArrayObjectWrappingImplementation extends DOMWrapperBase implements OESVertexArrayObject {
  _OESVertexArrayObjectWrappingImplementation() : super() {}

  static create__OESVertexArrayObjectWrappingImplementation() native {
    return new _OESVertexArrayObjectWrappingImplementation();
  }

  void bindVertexArrayOES([WebGLVertexArrayObjectOES arrayObject = null]) {
    if (arrayObject === null) {
      _bindVertexArrayOES(this);
      return;
    } else {
      _bindVertexArrayOES_2(this, arrayObject);
      return;
    }
  }
  static void _bindVertexArrayOES(receiver) native;
  static void _bindVertexArrayOES_2(receiver, arrayObject) native;

  WebGLVertexArrayObjectOES createVertexArrayOES() {
    return _createVertexArrayOES(this);
  }
  static WebGLVertexArrayObjectOES _createVertexArrayOES(receiver) native;

  void deleteVertexArrayOES([WebGLVertexArrayObjectOES arrayObject = null]) {
    if (arrayObject === null) {
      _deleteVertexArrayOES(this);
      return;
    } else {
      _deleteVertexArrayOES_2(this, arrayObject);
      return;
    }
  }
  static void _deleteVertexArrayOES(receiver) native;
  static void _deleteVertexArrayOES_2(receiver, arrayObject) native;

  bool isVertexArrayOES([WebGLVertexArrayObjectOES arrayObject = null]) {
    if (arrayObject === null) {
      return _isVertexArrayOES(this);
    } else {
      return _isVertexArrayOES_2(this, arrayObject);
    }
  }
  static bool _isVertexArrayOES(receiver) native;
  static bool _isVertexArrayOES_2(receiver, arrayObject) native;

  String get typeName() { return "OESVertexArrayObject"; }
}
