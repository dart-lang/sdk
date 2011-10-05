// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class UIEventWrappingImplementation extends EventWrappingImplementation implements UIEvent {
  UIEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get charCode() { return _ptr.charCode; }

  int get detail() { return _ptr.detail; }

  int get keyCode() { return _ptr.keyCode; }

  int get layerX() { return _ptr.layerX; }

  int get layerY() { return _ptr.layerY; }

  int get pageX() { return _ptr.pageX; }

  int get pageY() { return _ptr.pageY; }

  Window get view() { return LevelDom.wrapWindow(_ptr.view); }

  int get which() { return _ptr.which; }

  void initUIEvent(String type, bool canBubble, bool cancelable, Window view, int detail) {
    _ptr.initUIEvent(type, canBubble, cancelable, LevelDom.unwrap(view), detail);
    return;
  }

  String get typeName() { return "UIEvent"; }
}
