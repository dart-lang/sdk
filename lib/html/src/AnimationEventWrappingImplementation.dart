// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AnimationEventWrappingImplementation extends EventWrappingImplementation implements AnimationEvent {
  static String _name;

  AnimationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  static String get _eventName() {
    if (_name != null) return _name;

    try {
      dom.document.createEvent("WebKitAnimationEvent");
      _name = "WebKitAnimationEvent";
    } catch (var e) {
      _name = "AnimationEvent";
    }
    return _name;
  }

  factory AnimationEventWrappingImplementation(String type, String propertyName,
      double elapsedTime, [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent(_eventName);
    e.initWebKitAnimationEvent(
        type, canBubble, cancelable, propertyName, elapsedTime);
    return LevelDom.wrapAnimationEvent(e);
  }

  String get animationName() => _ptr.animationName;

  num get elapsedTime() => _ptr.elapsedTime;
}
