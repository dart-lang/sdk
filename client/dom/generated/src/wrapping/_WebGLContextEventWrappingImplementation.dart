// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebGLContextEventWrappingImplementation extends _EventWrappingImplementation implements WebGLContextEvent {
  _WebGLContextEventWrappingImplementation() : super() {}

  static create__WebGLContextEventWrappingImplementation() native {
    return new _WebGLContextEventWrappingImplementation();
  }

  String get statusMessage() { return _get__WebGLContextEvent_statusMessage(this); }
  static String _get__WebGLContextEvent_statusMessage(var _this) native;

  String get typeName() { return "WebGLContextEvent"; }
}
