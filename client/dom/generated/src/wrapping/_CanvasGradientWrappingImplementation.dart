// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CanvasGradientWrappingImplementation extends DOMWrapperBase implements CanvasGradient {
  _CanvasGradientWrappingImplementation() : super() {}

  static create__CanvasGradientWrappingImplementation() native {
    return new _CanvasGradientWrappingImplementation();
  }

  void addColorStop(num offset = null, String color = null) {
    if (offset === null) {
      if (color === null) {
        _addColorStop(this);
        return;
      }
    } else {
      if (color === null) {
        _addColorStop_2(this, offset);
        return;
      } else {
        _addColorStop_3(this, offset, color);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _addColorStop(receiver) native;
  static void _addColorStop_2(receiver, offset) native;
  static void _addColorStop_3(receiver, offset, color) native;

  String get typeName() { return "CanvasGradient"; }
}
