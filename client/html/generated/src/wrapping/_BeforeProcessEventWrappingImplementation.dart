// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BeforeProcessEventWrappingImplementation extends EventWrappingImplementation implements BeforeProcessEvent {
  BeforeProcessEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get text() { return _ptr.text; }

  void set text(String value) { _ptr.text = value; }

  void initBeforeProcessEvent(String type, bool canBubble, bool cancelable) {
    _ptr.initBeforeProcessEvent(type, canBubble, cancelable);
    return;
  }

  String get typeName() { return "BeforeProcessEvent"; }
}
