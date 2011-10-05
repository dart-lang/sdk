// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PointWrappingImplementation extends DOMWrapperBase implements Point {
  PointWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
  factory PointWrappingImplementation(num x, num y) {
    return LevelDom.wrapPoint(_rawWindow.createWebKitPoint(x, y));
  }

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  String get typeName() { return "Point"; }
}
