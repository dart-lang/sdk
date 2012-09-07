// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class KeyboardEventWrappingImplementation extends UIEventWrappingImplementation implements KeyboardEvent {
  KeyboardEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory KeyboardEventWrappingImplementation(String type, Window view,
      String keyIdentifier, int keyLocation, [bool canBubble = true,
      bool cancelable = true, bool ctrlKey = false, bool altKey = false,
      bool shiftKey = false, bool metaKey = false, bool altGraphKey = false]) {
    final e = dom.document.createEvent("KeyboardEvent");
    e.initKeyboardEvent(type, canBubble, cancelable, LevelDom.unwrap(view),
        keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey,
        altGraphKey);
    return LevelDom.wrapKeyboardEvent(e);
  }

  bool get altGraphKey => _ptr.altGraphKey;

  bool get altKey => _ptr.altKey;

  bool get ctrlKey => _ptr.ctrlKey;

  String get keyIdentifier => _ptr.keyIdentifier;

  int get keyLocation => _ptr.keyLocation;

  bool get metaKey => _ptr.metaKey;

  bool get shiftKey => _ptr.shiftKey;

  bool getModifierState(String keyIdentifierArg) {
    return _ptr.getModifierState(keyIdentifierArg);
  }
}
