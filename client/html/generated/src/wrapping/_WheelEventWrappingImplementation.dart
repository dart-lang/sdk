// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WheelEventWrappingImplementation extends UIEventWrappingImplementation implements WheelEvent {
  WheelEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get altKey() { return _ptr.altKey; }

  int get clientX() { return _ptr.clientX; }

  int get clientY() { return _ptr.clientY; }

  bool get ctrlKey() { return _ptr.ctrlKey; }

  bool get metaKey() { return _ptr.metaKey; }

  int get offsetX() { return _ptr.offsetX; }

  int get offsetY() { return _ptr.offsetY; }

  int get screenX() { return _ptr.screenX; }

  int get screenY() { return _ptr.screenY; }

  bool get shiftKey() { return _ptr.shiftKey; }

  int get wheelDelta() { return _ptr.wheelDelta; }

  int get wheelDeltaX() { return _ptr.wheelDeltaX; }

  int get wheelDeltaY() { return _ptr.wheelDeltaY; }

  int get x() { return _ptr.x; }

  int get y() { return _ptr.y; }

  void initWheelEvent(int wheelDeltaX, int wheelDeltaY, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) {
    _ptr.initWheelEvent(wheelDeltaX, wheelDeltaY, LevelDom.unwrap(view), screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return;
  }

  String get typeName() { return "WheelEvent"; }
}
