// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PopStateEventWrappingImplementation extends EventWrappingImplementation implements PopStateEvent {
  PopStateEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get state() { return _ptr.state; }

  void initPopStateEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object stateArg) {
    _ptr.initPopStateEvent(typeArg, canBubbleArg, cancelableArg, LevelDom.unwrapMaybePrimitive(stateArg));
    return;
  }
}
