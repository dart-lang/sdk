// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

// This test can be deleted when we stop supporting language versions <3.0.
//
// Tests front-end bug allowing `Type` (which doesn't have primitive equality)
// expressions in `switch` statements.
//
// This is a bug but all backends support it with language version < 3.0.

import "package:expect/expect.dart";

class C<T> {
  T v;

  C(this.v);

  Type? get nullableRuntimeType => returnNull ? null : runtimeType;
}

bool returnNull = false;

String test1(Object? v) {
  switch (v.runtimeType) {
    case C<int>:
      return 'int';
    case C<String>:
      return 'String';
    default:
      return 'unknown';
  }
}

String test2(dynamic v) {
  switch (v.nullableRuntimeType) {
    case C<int>:
      return 'int';
    case C<String>:
      return 'String';
    case null:
      return 'null';
    default:
      return 'unknown';
  }
}

main() {
  final arr = ["int", C(1), "String", C("")];

  for (var i = 0; i < arr.length; i += 2) {
    final t = arr[i];
    final v = arr[i + 1];
    Expect.equals(t, test1(v));
  }

  for (var i = 0; i < arr.length; i += 2) {
    final t = arr[i];
    final v = arr[i + 1];
    Expect.equals(t, test2(v));
  }

  returnNull = true;

  for (var i = 0; i < arr.length; i += 2) {
    final v = arr[i + 1];
    Expect.equals('null', test2(v));
  }
}
