// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TouchEventWrappingImplementation extends UIEventWrappingImplementation implements TouchEvent {
  TouchEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get altKey() { return _ptr.altKey; }

  TouchList get changedTouches() { return LevelDom.wrapTouchList(_ptr.changedTouches); }

  bool get ctrlKey() { return _ptr.ctrlKey; }

  bool get metaKey() { return _ptr.metaKey; }

  bool get shiftKey() { return _ptr.shiftKey; }

  TouchList get targetTouches() { return LevelDom.wrapTouchList(_ptr.targetTouches); }

  TouchList get touches() { return LevelDom.wrapTouchList(_ptr.touches); }

  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) {
    _ptr.initTouchEvent(LevelDom.unwrap(touches), LevelDom.unwrap(targetTouches), LevelDom.unwrap(changedTouches), type, LevelDom.unwrap(view), screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return;
  }

  String get typeName() { return "TouchEvent"; }
}
