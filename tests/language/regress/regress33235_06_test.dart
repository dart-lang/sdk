// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for complience with tables at
// https://github.com/dart-lang/sdk/issues/33235#issue-326617285
// Files 01 to 16 should be compile time errors, files 17 to 21 should not.

class A {
  int n() => 43;
}

class B extends A {
  static int get n => 42;
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] Can't declare a member that conflicts with an inherited one.
}

abstract class B2 implements A {
  static int get n => 42;
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] Can't declare a member that conflicts with an inherited one.
}

class C {
  static int get n => 42;
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE

  int n() => 43;
  //  ^
  // [cfe] 'n' is already declared in this scope.
}

main() {
  print(C);
  print(B);
  print(B2);
}
