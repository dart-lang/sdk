// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MouseEventWrappingImplementation extends UIEventWrappingImplementation implements MouseEvent {
  MouseEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get altKey() { return _ptr.altKey; }

  int get button() { return _ptr.button; }

  int get clientX() { return _ptr.clientX; }

  int get clientY() { return _ptr.clientY; }

  bool get ctrlKey() { return _ptr.ctrlKey; }

  Node get fromElement() { return LevelDom.wrapNode(_ptr.fromElement); }

  bool get metaKey() { return _ptr.metaKey; }

  int get offsetX() { return _ptr.offsetX; }

  int get offsetY() { return _ptr.offsetY; }

  EventTarget get relatedTarget() { return LevelDom.wrapEventTarget(_ptr.relatedTarget); }

  int get screenX() { return _ptr.screenX; }

  int get screenY() { return _ptr.screenY; }

  bool get shiftKey() { return _ptr.shiftKey; }

  Node get toElement() { return LevelDom.wrapNode(_ptr.toElement); }

  int get x() { return _ptr.x; }

  int get y() { return _ptr.y; }

  void initMouseEvent(String type, bool canBubble, bool cancelable, Window view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) {
    _ptr.initMouseEvent(type, canBubble, cancelable, LevelDom.unwrap(view), detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, LevelDom.unwrap(relatedTarget));
    return;
  }

  String get typeName() { return "MouseEvent"; }
}
