// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _IDBKeyRangeFactoryProvider {

  factory IDBKeyRange.only(/*IDBKey*/ value) =>
      _only(_class(), _translateKey(value));

  factory IDBKeyRange.lowerBound(/*IDBKey*/ bound, [bool open = false]) =>
      _lowerBound(_class(), _translateKey(bound), open);

  factory IDBKeyRange.upperBound(/*IDBKey*/ bound, [bool open = false]) =>
      _upperBound(_class(), _translateKey(bound), open);

  factory IDBKeyRange.bound(/*IDBKey*/ lower, /*IDBKey*/ upper,
                            [bool lowerOpen = false, bool upperOpen = false]) =>
      _bound(_class(), _translateKey(lower), _translateKey(upper),
             lowerOpen, upperOpen);

  static var _cachedClass;

  static _class() {
    if (_cachedClass != null) return _cachedClass;
    return _cachedClass = _uncachedClass();
  }

  static _uncachedClass() native '''
      return window.webkitIDBKeyRange || window.mozIDBKeyRange ||
             window.msIDBKeyRange || window.IDBKeyRange;
  ''';

  static _translateKey(idbkey) => idbkey;  // TODO: fixme.

  static _IDBKeyRangeImpl _only(cls, value) native
      '''return cls.only(value);''';

  static _IDBKeyRangeImpl _lowerBound(cls, bound, open) native
      '''return cls.lowerBound(bound, open);''';

  static _IDBKeyRangeImpl _upperBound(cls, bound, open) native
      '''return cls.upperBound(bound, open);''';

  static _IDBKeyRangeImpl _bound(cls, lower, upper, lowerOpen, upperOpen) native
      '''return cls.bound(lower, upper, lowerOpen, upperOpen);''';

}
