// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLCanvasElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLCanvasElement {
  _HTMLCanvasElementWrappingImplementation() : super() {}

  static create__HTMLCanvasElementWrappingImplementation() native {
    return new _HTMLCanvasElementWrappingImplementation();
  }

  int get height() { return _get__HTMLCanvasElement_height(this); }
  static int _get__HTMLCanvasElement_height(var _this) native;

  void set height(int value) { _set__HTMLCanvasElement_height(this, value); }
  static void _set__HTMLCanvasElement_height(var _this, int value) native;

  int get width() { return _get__HTMLCanvasElement_width(this); }
  static int _get__HTMLCanvasElement_width(var _this) native;

  void set width(int value) { _set__HTMLCanvasElement_width(this, value); }
  static void _set__HTMLCanvasElement_width(var _this, int value) native;

  Object getContext(String contextId = null) {
    if (contextId === null) {
      return _getContext(this);
    } else {
      return _getContext_2(this, contextId);
    }
  }
  static Object _getContext(receiver) native;
  static Object _getContext_2(receiver, contextId) native;

  String toDataURL(String type = null) {
    if (type === null) {
      return _toDataURL(this);
    } else {
      return _toDataURL_2(this, type);
    }
  }
  static String _toDataURL(receiver) native;
  static String _toDataURL_2(receiver, type) native;

  String get typeName() { return "HTMLCanvasElement"; }
}
