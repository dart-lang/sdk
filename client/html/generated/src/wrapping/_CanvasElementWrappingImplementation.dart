// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasElementWrappingImplementation extends ElementWrappingImplementation implements CanvasElement {
  CanvasElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get height() { return _ptr.height; }

  void set height(int value) { _ptr.height = value; }

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }

  CanvasRenderingContext getContext([String contextId = null]) {
    return LevelDom.wrapCanvasRenderingContext(_ptr.getContext(contextId));
  }

  String toDataURL([String type = null]) {
    return _ptr.toDataURL(type);
  }

  String get typeName() { return "CanvasElement"; }
}
