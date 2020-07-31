// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

/// Test instance checks and casts in constants may use potentially constant
/// types, and cause compile time errors when the casts fail.

class C1<T> {
  final t;

  /// Check casts to T
  const C1.test(dynamic x) : t = x as T;
}

class C2<T> {
  final l;

  /// Check casts to List<T>
  const C2.test(dynamic x) : l = x as List<T>;
}

void main() {
  const c1 = C1<int>.test("hello");
  //         ^
  // [analyzer] unspecified
  // [cfe] Constant evaluation error:
  const c2 = C1<int>.test(null);
  //         ^
  // [analyzer] unspecified
  // [cfe] unspecified
  const c3 = C2<int>.test(<num>[0]);
  //         ^
  // [analyzer] unspecified
  // [cfe] Constant evaluation error:
  const c4 = C2<int>.test("hello");
  //         ^
  // [analyzer] unspecified
  // [cfe] Constant evaluation error:
  const c5 = C2<int>.test(null);
  //         ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
