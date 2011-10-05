// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SharedWorkerWrappingImplementation extends _AbstractWorkerWrappingImplementation implements SharedWorker {
  _SharedWorkerWrappingImplementation() : super() {}

  static create__SharedWorkerWrappingImplementation() native {
    return new _SharedWorkerWrappingImplementation();
  }

  MessagePort get port() { return _get__SharedWorker_port(this); }
  static MessagePort _get__SharedWorker_port(var _this) native;

  String get typeName() { return "SharedWorker"; }
}
