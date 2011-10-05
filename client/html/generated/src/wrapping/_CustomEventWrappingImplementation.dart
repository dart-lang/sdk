// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CustomEventWrappingImplementation extends EventWrappingImplementation implements CustomEvent {
  CustomEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get detail() { return _ptr.detail; }

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) {
    _ptr.initCustomEvent(typeArg, canBubbleArg, cancelableArg, LevelDom.unwrapMaybePrimitive(detailArg));
    return;
  }

  String get typeName() { return "CustomEvent"; }
}
