// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MouseEventWrappingImplementation extends UIEventWrappingImplementation implements MouseEvent {
  MouseEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory MouseEventWrappingImplementation(String type, Window view, int detail,
      int screenX, int screenY, int clientX, int clientY, int button,
      [bool canBubble = true, bool cancelable = true, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) {
    final e = dom.document.createEvent("MouseEvent");
    e.initMouseEvent(type, canBubble, cancelable, LevelDom.unwrap(view), detail,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey,
        button, LevelDom.unwrap(relatedTarget));
    return LevelDom.wrapMouseEvent(e);
  }

  bool get altKey() => _ptr.altKey;

  int get button() => _ptr.button;

  int get clientX() => _ptr.clientX;

  int get clientY() => _ptr.clientY;

  bool get ctrlKey() => _ptr.ctrlKey;

  Node get fromElement() => LevelDom.wrapNode(_ptr.fromElement);

  bool get metaKey() => _ptr.metaKey;

  int get offsetX() => _ptr.offsetX;

  int get offsetY() => _ptr.offsetY;

  EventTarget get relatedTarget() => LevelDom.wrapEventTarget(_ptr.relatedTarget);

  int get screenX() => _ptr.screenX;

  int get screenY() => _ptr.screenY;

  bool get shiftKey() => _ptr.shiftKey;

  Node get toElement() => LevelDom.wrapNode(_ptr.toElement);

  int get x() => _ptr.x;

  int get y() => _ptr.y;
}
