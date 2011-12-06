// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TouchEventWrappingImplementation extends UIEventWrappingImplementation implements TouchEvent {
  TouchEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory TouchEventWrappingImplementation(TouchList touches, TouchList targetTouches,
      TouchList changedTouches, String type, Window view, int screenX,
      int screenY, int clientX, int clientY, [bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false]) {
    final e = dom.document.createEvent("TouchEvent");
    e.initTouchEvent(LevelDom.unwrap(touches), LevelDom.unwrap(targetTouches),
        LevelDom.unwrap(changedTouches), type, LevelDom.unwrap(view), screenX,
        screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return LevelDom.wrapTouchEvent(e);
  }

  bool get altKey() => _ptr.altKey;

  TouchList get changedTouches() => LevelDom.wrapTouchList(_ptr.changedTouches);

  bool get ctrlKey() => _ptr.ctrlKey;

  bool get metaKey() => _ptr.metaKey;

  bool get shiftKey() => _ptr.shiftKey;

  TouchList get targetTouches() => LevelDom.wrapTouchList(_ptr.targetTouches);

  TouchList get touches() => LevelDom.wrapTouchList(_ptr.touches);
}
