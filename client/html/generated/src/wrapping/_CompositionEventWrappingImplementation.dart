// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CompositionEventWrappingImplementation extends UIEventWrappingImplementation implements CompositionEvent {
  CompositionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get data() { return _ptr.data; }

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Window viewArg, String dataArg) {
    _ptr.initCompositionEvent(typeArg, canBubbleArg, cancelableArg, LevelDom.unwrap(viewArg), dataArg);
    return;
  }
}
