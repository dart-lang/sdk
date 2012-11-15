// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class _IDBKeyRangeFactoryProvider {

  static IDBKeyRange createIDBKeyRange_only(/*IDBKey*/ value) =>
      _only(_class(), _translateKey(value));

  static IDBKeyRange createIDBKeyRange_lowerBound(
      /*IDBKey*/ bound, [bool open = false]) =>
      _lowerBound(_class(), _translateKey(bound), open);

  static IDBKeyRange createIDBKeyRange_upperBound(
      /*IDBKey*/ bound, [bool open = false]) =>
      _upperBound(_class(), _translateKey(bound), open);

  static IDBKeyRange createIDBKeyRange_bound(/*IDBKey*/ lower, /*IDBKey*/ upper,
      [bool lowerOpen = false, bool upperOpen = false]) =>
      _bound(_class(), _translateKey(lower), _translateKey(upper),
             lowerOpen, upperOpen);

  static var _cachedClass;

  static _class() {
    if (_cachedClass != null) return _cachedClass;
    return _cachedClass = _uncachedClass();
  }

  static _uncachedClass() =>
    JS('var',
       '''window.webkitIDBKeyRange || window.mozIDBKeyRange ||
          window.msIDBKeyRange || window.IDBKeyRange''');

  static _translateKey(idbkey) => idbkey;  // TODO: fixme.

  static IDBKeyRange _only(cls, value) =>
       JS('IDBKeyRange', '#.only(#)', cls, value);

  static IDBKeyRange _lowerBound(cls, bound, open) =>
       JS('IDBKeyRange', '#.lowerBound(#, #)', cls, bound, open);

  static IDBKeyRange _upperBound(cls, bound, open) =>
       JS('IDBKeyRange', '#.upperBound(#, #)', cls, bound, open);

  static IDBKeyRange _bound(cls, lower, upper, lowerOpen, upperOpen) =>
       JS('IDBKeyRange', '#.bound(#, #, #, #)',
          cls, lower, upper, lowerOpen, upperOpen);
}
