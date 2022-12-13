// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;
import "dart:ffi" show Pointer, Struct, Union;

// Stub Expando implementation to make the Expando class compile.

@patch
class Expando<T> {
  final Map<Object, T?> _expando = Map.identity();

  @patch
  Expando([String? name]) : name = name;

  void _checkValidWeakTarget(Object? object) {
    if ((object == null) ||
        (object is bool) ||
        (object is num) ||
        (object is String) ||
        (object is Record) ||
        (object is Pointer) ||
        (object is Struct) ||
        (object is Union)) {
      throw new ArgumentError.value(object,
          "Cannot be a string, number, boolean, record, null, Pointer, Struct or Union");
    }
  }

  @patch
  T? operator [](Object object) {
    _checkValidWeakTarget(object);
    return _expando[object];
  }

  @patch
  void operator []=(Object object, T? value) {
    _checkValidWeakTarget(object);
    _expando[object] = value;
  }
}
