// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TransitionEventWrappingImplementation extends EventWrappingImplementation implements TransitionEvent {
  TransitionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get elapsedTime() { return _ptr.elapsedTime; }

  String get propertyName() { return _ptr.propertyName; }

  void initWebKitTransitionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String propertyNameArg, num elapsedTimeArg) {
    _ptr.initWebKitTransitionEvent(typeArg, canBubbleArg, cancelableArg, propertyNameArg, elapsedTimeArg);
    return;
  }
}
