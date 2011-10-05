// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CloseEventWrappingImplementation extends EventWrappingImplementation implements CloseEvent {
  CloseEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get reason() { return _ptr.reason; }

  bool get wasClean() { return _ptr.wasClean; }

  void initCloseEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool wasCleanArg, int codeArg, String reasonArg) {
    _ptr.initCloseEvent(typeArg, canBubbleArg, cancelableArg, wasCleanArg, codeArg, reasonArg);
    return;
  }

  String get typeName() { return "CloseEvent"; }
}
