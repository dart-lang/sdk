// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CanvasGradientWrappingImplementation extends DOMWrapperBase implements CanvasGradient {
  _CanvasGradientWrappingImplementation() : super() {}

  static create__CanvasGradientWrappingImplementation() native {
    return new _CanvasGradientWrappingImplementation();
  }

  void addColorStop(num offset, String color) {
    _addColorStop(this, offset, color);
    return;
  }
  static void _addColorStop(receiver, offset, color) native;

  String get typeName() { return "CanvasGradient"; }
}
