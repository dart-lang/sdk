// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AnimationEventWrappingImplementation extends EventWrappingImplementation implements AnimationEvent {
  AnimationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get animationName() { return _ptr.animationName; }

  num get elapsedTime() { return _ptr.elapsedTime; }

  void initWebKitAnimationEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String animationNameArg, num elapsedTimeArg) {
    _ptr.initWebKitAnimationEvent(typeArg, canBubbleArg, cancelableArg, animationNameArg, elapsedTimeArg);
    return;
  }

  String get typeName() { return "AnimationEvent"; }
}
