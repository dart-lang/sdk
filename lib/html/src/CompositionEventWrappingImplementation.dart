// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CompositionEventWrappingImplementation extends UIEventWrappingImplementation implements CompositionEvent {
  CompositionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory CompositionEventWrappingImplementation(String type, Window view,
      String data, [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("CompositionEvent");
    e.initCompositionEvent(type, canBubble, cancelable, LevelDom.unwrap(view),
        data);
    return LevelDom.wrapCompositionEvent(e);
  }

  String get data => _ptr.data;
}
