// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitLoseContextWrappingImplementation extends DOMWrapperBase implements WebKitLoseContext {
  _WebKitLoseContextWrappingImplementation() : super() {}

  static create__WebKitLoseContextWrappingImplementation() native {
    return new _WebKitLoseContextWrappingImplementation();
  }

  void loseContext() {
    _loseContext(this);
    return;
  }
  static void _loseContext(receiver) native;

  void restoreContext() {
    _restoreContext(this);
    return;
  }
  static void _restoreContext(receiver) native;

  String get typeName() { return "WebKitLoseContext"; }
}
