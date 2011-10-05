// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class KeyboardEventWrappingImplementation extends UIEventWrappingImplementation implements KeyboardEvent {
  KeyboardEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get altGraphKey() { return _ptr.altGraphKey; }

  bool get altKey() { return _ptr.altKey; }

  bool get ctrlKey() { return _ptr.ctrlKey; }

  String get keyIdentifier() { return _ptr.keyIdentifier; }

  int get keyLocation() { return _ptr.keyLocation; }

  bool get metaKey() { return _ptr.metaKey; }

  bool get shiftKey() { return _ptr.shiftKey; }

  bool getModifierState(String keyIdentifierArg) {
    return _ptr.getModifierState(keyIdentifierArg);
  }

  void initKeyboardEvent(String type, bool canBubble, bool cancelable, Window view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) {
    _ptr.initKeyboardEvent(type, canBubble, cancelable, LevelDom.unwrap(view), keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey, altGraphKey);
    return;
  }

  String get typeName() { return "KeyboardEvent"; }
}
