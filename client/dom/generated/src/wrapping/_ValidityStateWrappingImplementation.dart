// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ValidityStateWrappingImplementation extends DOMWrapperBase implements ValidityState {
  _ValidityStateWrappingImplementation() : super() {}

  static create__ValidityStateWrappingImplementation() native {
    return new _ValidityStateWrappingImplementation();
  }

  bool get customError() { return _get__ValidityState_customError(this); }
  static bool _get__ValidityState_customError(var _this) native;

  bool get patternMismatch() { return _get__ValidityState_patternMismatch(this); }
  static bool _get__ValidityState_patternMismatch(var _this) native;

  bool get rangeOverflow() { return _get__ValidityState_rangeOverflow(this); }
  static bool _get__ValidityState_rangeOverflow(var _this) native;

  bool get rangeUnderflow() { return _get__ValidityState_rangeUnderflow(this); }
  static bool _get__ValidityState_rangeUnderflow(var _this) native;

  bool get stepMismatch() { return _get__ValidityState_stepMismatch(this); }
  static bool _get__ValidityState_stepMismatch(var _this) native;

  bool get tooLong() { return _get__ValidityState_tooLong(this); }
  static bool _get__ValidityState_tooLong(var _this) native;

  bool get typeMismatch() { return _get__ValidityState_typeMismatch(this); }
  static bool _get__ValidityState_typeMismatch(var _this) native;

  bool get valid() { return _get__ValidityState_valid(this); }
  static bool _get__ValidityState_valid(var _this) native;

  bool get valueMissing() { return _get__ValidityState_valueMissing(this); }
  static bool _get__ValidityState_valueMissing(var _this) native;

  String get typeName() { return "ValidityState"; }
}
