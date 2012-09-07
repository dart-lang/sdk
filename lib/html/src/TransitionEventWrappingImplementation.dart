// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TransitionEventWrappingImplementation extends EventWrappingImplementation implements TransitionEvent {
  static String _name;

  TransitionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  static String get _eventName {
    if (_name != null) return _name;

    try {
      dom.document.createEvent("WebKitTransitionEvent");
      _name = "WebKitTransitionEvent";
    } catch (var e) {
      _name = "TransitionEvent";
    }
    return _name;
  }

  factory TransitionEventWrappingImplementation(String type,
      String propertyName, double elapsedTime, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent(_eventName);
    e.initWebKitTransitionEvent(type, canBubble, cancelable, propertyName,
        elapsedTime);
    return LevelDom.wrapTransitionEvent(e);
  }

  num get elapsedTime => _ptr.elapsedTime;

  String get propertyName => _ptr.propertyName;
}
