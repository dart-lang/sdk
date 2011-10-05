// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LoseContextWrappingImplementation extends DOMWrapperBase implements LoseContext {
  LoseContextWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void loseContext() {
    _ptr.loseContext();
    return;
  }

  void restoreContext() {
    _ptr.restoreContext();
    return;
  }

  String get typeName() { return "LoseContext"; }
}
