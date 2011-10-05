// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PageTransitionEventWrappingImplementation extends EventWrappingImplementation implements PageTransitionEvent {
  PageTransitionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get persisted() { return _ptr.persisted; }

  void initPageTransitionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool persisted) {
    _ptr.initPageTransitionEvent(typeArg, canBubbleArg, cancelableArg, persisted);
    return;
  }

  String get typeName() { return "PageTransitionEvent"; }
}
