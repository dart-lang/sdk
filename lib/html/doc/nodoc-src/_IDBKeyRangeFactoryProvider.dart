// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _IDBKeyRangeFactoryProvider {

  factory IDBKeyRange.only(/*IDBKey*/ value) => null;

  factory IDBKeyRange.lowerBound(/*IDBKey*/ bound, [bool open = false]) => null;

  factory IDBKeyRange.upperBound(/*IDBKey*/ bound, [bool open = false]) => null;

  factory IDBKeyRange.bound(/*IDBKey*/ lower, /*IDBKey*/ upper,
                            [bool lowerOpen = false, bool upperOpen = false]) =>
      null;
}
