// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLProgressElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLProgressElement {
  _HTMLProgressElementWrappingImplementation() : super() {}

  static create__HTMLProgressElementWrappingImplementation() native {
    return new _HTMLProgressElementWrappingImplementation();
  }

  HTMLFormElement get form() { return _get__HTMLProgressElement_form(this); }
  static HTMLFormElement _get__HTMLProgressElement_form(var _this) native;

  NodeList get labels() { return _get__HTMLProgressElement_labels(this); }
  static NodeList _get__HTMLProgressElement_labels(var _this) native;

  num get max() { return _get__HTMLProgressElement_max(this); }
  static num _get__HTMLProgressElement_max(var _this) native;

  void set max(num value) { _set__HTMLProgressElement_max(this, value); }
  static void _set__HTMLProgressElement_max(var _this, num value) native;

  num get position() { return _get__HTMLProgressElement_position(this); }
  static num _get__HTMLProgressElement_position(var _this) native;

  num get value() { return _get__HTMLProgressElement_value(this); }
  static num _get__HTMLProgressElement_value(var _this) native;

  void set value(num value) { _set__HTMLProgressElement_value(this, value); }
  static void _set__HTMLProgressElement_value(var _this, num value) native;

  String get typeName() { return "HTMLProgressElement"; }
}
