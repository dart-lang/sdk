// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EventWrappingImplementation extends DOMWrapperBase implements Event {
  EventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory EventWrappingImplementation(String type, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent("Event");
    e.initEvent(type, canBubble, cancelable);
    return LevelDom.wrapEvent(e);
  }

  bool get bubbles() => _ptr.bubbles;

  bool get cancelBubble() => _ptr.cancelBubble;

  void set cancelBubble(bool value) { _ptr.cancelBubble = value; }

  bool get cancelable() => _ptr.cancelable;

  EventTarget get currentTarget() => LevelDom.wrapEventTarget(_ptr.currentTarget);

  bool get defaultPrevented() => _ptr.defaultPrevented;

  int get eventPhase() => _ptr.eventPhase;

  bool get returnValue() => _ptr.returnValue;

  void set returnValue(bool value) { _ptr.returnValue = value; }

  EventTarget get srcElement() => LevelDom.wrapEventTarget(_ptr.srcElement);

  EventTarget get target() => LevelDom.wrapEventTarget(_ptr.target);

  int get timeStamp() => _ptr.timeStamp;

  String get type() => _ptr.type;

  void preventDefault() {
    _ptr.preventDefault();
    return;
  }

  void stopImmediatePropagation() {
    _ptr.stopImmediatePropagation();
    return;
  }

  void stopPropagation() {
    _ptr.stopPropagation();
    return;
  }
}
