// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MarqueeElementWrappingImplementation extends ElementWrappingImplementation implements MarqueeElement {
  MarqueeElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get behavior() { return _ptr.behavior; }

  void set behavior(String value) { _ptr.behavior = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  String get direction() { return _ptr.direction; }

  void set direction(String value) { _ptr.direction = value; }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  int get hspace() { return _ptr.hspace; }

  void set hspace(int value) { _ptr.hspace = value; }

  int get loop() { return _ptr.loop; }

  void set loop(int value) { _ptr.loop = value; }

  int get scrollAmount() { return _ptr.scrollAmount; }

  void set scrollAmount(int value) { _ptr.scrollAmount = value; }

  int get scrollDelay() { return _ptr.scrollDelay; }

  void set scrollDelay(int value) { _ptr.scrollDelay = value; }

  bool get trueSpeed() { return _ptr.trueSpeed; }

  void set trueSpeed(bool value) { _ptr.trueSpeed = value; }

  int get vspace() { return _ptr.vspace; }

  void set vspace(int value) { _ptr.vspace = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }

  void start() {
    _ptr.start();
    return;
  }

  void stop() {
    _ptr.stop();
    return;
  }

  String get typeName() { return "MarqueeElement"; }
}
