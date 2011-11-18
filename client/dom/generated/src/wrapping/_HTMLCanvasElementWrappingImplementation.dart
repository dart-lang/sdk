// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLCanvasElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLCanvasElement {
  _HTMLCanvasElementWrappingImplementation() : super() {}

  static create__HTMLCanvasElementWrappingImplementation() native {
    return new _HTMLCanvasElementWrappingImplementation();
  }

  int get height() { return _get_height(this); }
  static int _get_height(var _this) native;

  void set height(int value) { _set_height(this, value); }
  static void _set_height(var _this, int value) native;

  int get width() { return _get_width(this); }
  static int _get_width(var _this) native;

  void set width(int value) { _set_width(this, value); }
  static void _set_width(var _this, int value) native;

  Object getContext(String contextId) {
    return _getContext(this, contextId);
  }
  static Object _getContext(receiver, contextId) native;

  String toDataURL(String type) {
    return _toDataURL(this, type);
  }
  static String _toDataURL(receiver, type) native;

  String get typeName() { return "HTMLCanvasElement"; }
}
