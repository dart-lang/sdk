// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OESVertexArrayObjectWrappingImplementation extends DOMWrapperBase implements OESVertexArrayObject {
  OESVertexArrayObjectWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    _ptr.bindVertexArrayOES(LevelDom.unwrap(arrayObject));
    return;
  }

  WebGLVertexArrayObjectOES createVertexArrayOES() {
    return LevelDom.wrapWebGLVertexArrayObjectOES(_ptr.createVertexArrayOES());
  }

  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    _ptr.deleteVertexArrayOES(LevelDom.unwrap(arrayObject));
    return;
  }

  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    return _ptr.isVertexArrayOES(LevelDom.unwrap(arrayObject));
  }

  String get typeName() { return "OESVertexArrayObject"; }
}
