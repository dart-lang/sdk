// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TextEventWrappingImplementation extends UIEventWrappingImplementation implements TextEvent {
  TextEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory TextEventWrappingImplementation(String type, Window view, String data,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("TextEvent");
    e.initTextEvent(type, canBubble, cancelable, LevelDom.unwrap(view), data);
    return LevelDom.wrapTextEvent(e);
  }

  String get data() => _ptr.data;
}
