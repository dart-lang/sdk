// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _IDBKeyRangeWrappingImplementation extends DOMWrapperBase implements IDBKeyRange {
  _IDBKeyRangeWrappingImplementation() : super() {}

  static create__IDBKeyRangeWrappingImplementation() native {
    return new _IDBKeyRangeWrappingImplementation();
  }

  IDBKey get lower() { return _get__IDBKeyRange_lower(this); }
  static IDBKey _get__IDBKeyRange_lower(var _this) native;

  bool get lowerOpen() { return _get__IDBKeyRange_lowerOpen(this); }
  static bool _get__IDBKeyRange_lowerOpen(var _this) native;

  IDBKey get upper() { return _get__IDBKeyRange_upper(this); }
  static IDBKey _get__IDBKeyRange_upper(var _this) native;

  bool get upperOpen() { return _get__IDBKeyRange_upperOpen(this); }
  static bool _get__IDBKeyRange_upperOpen(var _this) native;

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen = null, bool upperOpen = null]) {
    if (lowerOpen === null) {
      if (upperOpen === null) {
        return _bound(this, lower, upper);
      }
    } else {
      if (upperOpen === null) {
        return _bound_2(this, lower, upper, lowerOpen);
      } else {
        return _bound_3(this, lower, upper, lowerOpen, upperOpen);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static IDBKeyRange _bound(receiver, lower, upper) native;
  static IDBKeyRange _bound_2(receiver, lower, upper, lowerOpen) native;
  static IDBKeyRange _bound_3(receiver, lower, upper, lowerOpen, upperOpen) native;

  IDBKeyRange lowerBound(IDBKey bound, [bool open = null]) {
    if (open === null) {
      return _lowerBound(this, bound);
    } else {
      return _lowerBound_2(this, bound, open);
    }
  }
  static IDBKeyRange _lowerBound(receiver, bound) native;
  static IDBKeyRange _lowerBound_2(receiver, bound, open) native;

  IDBKeyRange only(IDBKey value) {
    return _only(this, value);
  }
  static IDBKeyRange _only(receiver, value) native;

  IDBKeyRange upperBound(IDBKey bound, [bool open = null]) {
    if (open === null) {
      return _upperBound(this, bound);
    } else {
      return _upperBound_2(this, bound, open);
    }
  }
  static IDBKeyRange _upperBound(receiver, bound) native;
  static IDBKeyRange _upperBound_2(receiver, bound, open) native;

  String get typeName() { return "IDBKeyRange"; }
}
