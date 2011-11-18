// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ValidityStateWrappingImplementation extends DOMWrapperBase implements ValidityState {
  _ValidityStateWrappingImplementation() : super() {}

  static create__ValidityStateWrappingImplementation() native {
    return new _ValidityStateWrappingImplementation();
  }

  bool get customError() { return _get_customError(this); }
  static bool _get_customError(var _this) native;

  bool get patternMismatch() { return _get_patternMismatch(this); }
  static bool _get_patternMismatch(var _this) native;

  bool get rangeOverflow() { return _get_rangeOverflow(this); }
  static bool _get_rangeOverflow(var _this) native;

  bool get rangeUnderflow() { return _get_rangeUnderflow(this); }
  static bool _get_rangeUnderflow(var _this) native;

  bool get stepMismatch() { return _get_stepMismatch(this); }
  static bool _get_stepMismatch(var _this) native;

  bool get tooLong() { return _get_tooLong(this); }
  static bool _get_tooLong(var _this) native;

  bool get typeMismatch() { return _get_typeMismatch(this); }
  static bool _get_typeMismatch(var _this) native;

  bool get valid() { return _get_valid(this); }
  static bool _get_valid(var _this) native;

  bool get valueMissing() { return _get_valueMissing(this); }
  static bool _get_valueMissing(var _this) native;

  String get typeName() { return "ValidityState"; }
}
