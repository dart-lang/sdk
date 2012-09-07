// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class WheelEventWrappingImplementation extends UIEventWrappingImplementation implements WheelEvent {
  WheelEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory WheelEventWrappingImplementation(int deltaX, int deltaY, Window view,
      int screenX, int screenY, int clientX, int clientY, [bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false]) {
    final e = dom.document.createEvent("WheelEvent");
    e.initWebKitWheelEvent(deltaX, deltaY, LevelDom.unwrap(view), screenX, screenY,
        clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return LevelDom.wrapWheelEvent(e);
  }

  bool get altKey => _ptr.altKey;

  int get clientX => _ptr.clientX;

  int get clientY => _ptr.clientY;

  bool get ctrlKey => _ptr.ctrlKey;

  bool get metaKey => _ptr.metaKey;

  int get offsetX => _ptr.offsetX;

  int get offsetY => _ptr.offsetY;

  int get screenX => _ptr.screenX;

  int get screenY => _ptr.screenY;

  bool get shiftKey => _ptr.shiftKey;

  int get wheelDelta => _ptr.wheelDelta;

  int get wheelDeltaX => _ptr.wheelDeltaX;

  int get wheelDeltaY => _ptr.wheelDeltaY;

  int get x => _ptr.x;

  int get y => _ptr.y;
}
