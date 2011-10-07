// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TouchWrappingImplementation extends DOMWrapperBase implements Touch {
  TouchWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get clientX() { return _ptr.clientX; }

  int get clientY() { return _ptr.clientY; }

  int get identifier() { return _ptr.identifier; }

  int get pageX() { return _ptr.pageX; }

  int get pageY() { return _ptr.pageY; }

  int get screenX() { return _ptr.screenX; }

  int get screenY() { return _ptr.screenY; }

  EventTarget get target() { return LevelDom.wrapEventTarget(_ptr.target); }

  num get webkitForce() { return _ptr.webkitForce; }

  int get webkitRadiusX() { return _ptr.webkitRadiusX; }

  int get webkitRadiusY() { return _ptr.webkitRadiusY; }

  num get webkitRotationAngle() { return _ptr.webkitRotationAngle; }
}
