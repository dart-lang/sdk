// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CounterWrappingImplementation extends DOMWrapperBase implements Counter {
  _CounterWrappingImplementation() : super() {}

  static create__CounterWrappingImplementation() native {
    return new _CounterWrappingImplementation();
  }

  String get identifier() { return _get_identifier(this); }
  static String _get_identifier(var _this) native;

  String get listStyle() { return _get_listStyle(this); }
  static String _get_listStyle(var _this) native;

  String get separator() { return _get_separator(this); }
  static String _get_separator(var _this) native;

  String get typeName() { return "Counter"; }
}
