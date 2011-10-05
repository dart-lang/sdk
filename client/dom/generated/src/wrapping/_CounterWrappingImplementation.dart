// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CounterWrappingImplementation extends DOMWrapperBase implements Counter {
  _CounterWrappingImplementation() : super() {}

  static create__CounterWrappingImplementation() native {
    return new _CounterWrappingImplementation();
  }

  String get identifier() { return _get__Counter_identifier(this); }
  static String _get__Counter_identifier(var _this) native;

  String get listStyle() { return _get__Counter_listStyle(this); }
  static String _get__Counter_listStyle(var _this) native;

  String get separator() { return _get__Counter_separator(this); }
  static String _get__Counter_separator(var _this) native;

  String get typeName() { return "Counter"; }
}
