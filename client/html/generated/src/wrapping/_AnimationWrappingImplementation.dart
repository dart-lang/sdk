// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AnimationWrappingImplementation extends DOMWrapperBase implements Animation {
  AnimationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get delay() { return _ptr.delay; }

  int get direction() { return _ptr.direction; }

  num get duration() { return _ptr.duration; }

  num get elapsedTime() { return _ptr.elapsedTime; }

  void set elapsedTime(num value) { _ptr.elapsedTime = value; }

  bool get ended() { return _ptr.ended; }

  int get fillMode() { return _ptr.fillMode; }

  int get iterationCount() { return _ptr.iterationCount; }

  String get name() { return _ptr.name; }

  bool get paused() { return _ptr.paused; }

  void pause() {
    _ptr.pause();
    return;
  }

  void play() {
    _ptr.play();
    return;
  }

  String get typeName() { return "Animation"; }
}
