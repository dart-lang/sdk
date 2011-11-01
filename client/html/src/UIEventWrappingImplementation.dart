// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class UIEventWrappingImplementation extends EventWrappingImplementation implements UIEvent {
  UIEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory UIEventWrappingImplementation(String type, Window view, int detail,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("UIEvent");
    e.initUIEvent(type, canBubble, cancelable, LevelDom.unwrap(view), detail);
    return LevelDom.wrapUIEvent(e);
  }

  int get charCode() => _ptr.charCode;

  int get detail() => _ptr.detail;

  int get keyCode() => _ptr.keyCode;

  int get layerX() => _ptr.layerX;

  int get layerY() => _ptr.layerY;

  int get pageX() => _ptr.pageX;

  int get pageY() => _ptr.pageY;

  Window get view() => LevelDom.wrapWindow(_ptr.view);

  int get which() => _ptr.which;
}
