// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EventWrappingImplementation extends DOMWrapperBase implements Event {
  EventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get bubbles() { return _ptr.bubbles; }

  bool get cancelBubble() { return _ptr.cancelBubble; }

  void set cancelBubble(bool value) { _ptr.cancelBubble = value; }

  bool get cancelable() { return _ptr.cancelable; }

  EventTarget get currentTarget() { return LevelDom.wrapEventTarget(_ptr.currentTarget); }

  bool get defaultPrevented() { return _ptr.defaultPrevented; }

  int get eventPhase() { return _ptr.eventPhase; }

  bool get returnValue() { return _ptr.returnValue; }

  void set returnValue(bool value) { _ptr.returnValue = value; }

  EventTarget get srcElement() { return LevelDom.wrapEventTarget(_ptr.srcElement); }

  EventTarget get target() { return LevelDom.wrapEventTarget(_ptr.target); }

  int get timeStamp() { return _ptr.timeStamp; }

  String get type() { return _ptr.type; }

  void initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) {
    _ptr.initEvent(eventTypeArg, canBubbleArg, cancelableArg);
    return;
  }

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
