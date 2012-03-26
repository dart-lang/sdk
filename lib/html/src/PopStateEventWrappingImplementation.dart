// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PopStateEventWrappingImplementation extends EventWrappingImplementation implements PopStateEvent {
  PopStateEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory PopStateEventWrappingImplementation(String type, Object state,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("PopStateEvent");
    e.initPopStateEvent(type, canBubble, cancelable, state);
    return LevelDom.wrapPopStateEvent(e);
  }

  String get state() => _ptr.state;
}
