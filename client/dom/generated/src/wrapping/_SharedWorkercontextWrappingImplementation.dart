// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SharedWorkercontextWrappingImplementation extends _WorkerContextWrappingImplementation implements SharedWorkercontext {
  _SharedWorkercontextWrappingImplementation() : super() {}

  static create__SharedWorkercontextWrappingImplementation() native {
    return new _SharedWorkercontextWrappingImplementation();
  }

  String get name() { return _get__SharedWorkercontext_name(this); }
  static String _get__SharedWorkercontext_name(var _this) native;

  EventListener get onconnect() { return _get__SharedWorkercontext_onconnect(this); }
  static EventListener _get__SharedWorkercontext_onconnect(var _this) native;

  void set onconnect(EventListener value) { _set__SharedWorkercontext_onconnect(this, value); }
  static void _set__SharedWorkercontext_onconnect(var _this, EventListener value) native;

  String get typeName() { return "SharedWorkercontext"; }
}
