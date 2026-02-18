// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Declaring any formal parameters with the `final` modifier is a compile-time
// error.

// SharedOptions=--enable-experiment=primary-constructors

class C {
  void method1(final int x) {}
  //           ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'final' here.

  void method2([final int y = 1]) {}
  //            ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'final' here.
}

enum E(final int x) {
  e(1);
  void method1(final int x) {}
  //           ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'final' here.

  void method2({required final int y}) {}
  //                     ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'final' here.
}

extension type ET(final int x) {
  void method1(final int x) {}
  //           ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'final' here.

  void method2({final int y = 1}) {}
  //            ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'final' here.
}

void main() {
  [1, 4, 6, 8].forEach((final value) => print(value + 2));
  //                    ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'final' here.
}
