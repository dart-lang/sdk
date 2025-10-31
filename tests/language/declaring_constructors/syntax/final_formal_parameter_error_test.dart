// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Declaring any formal parameters with the `final` modifier is a compile-time
// error.

// SharedOptions=--enable-experiment=declaring-constructors

class C {
  void method(final int x, [final int y = 1]) {}
  //          ^
  // [analyzer] unspecified
  // [cfe] unspecified
  //                        ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

enum E(var int x) {
  e(1);
  void method(final int x, {required final int y = 1}) {}
  //          ^
  // [analyzer] unspecified
  // [cfe] unspecified
  //                                 ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type ET(final int x) {
  void method(final int x, {final int y = 1}) {}
  //          ^
  // [analyzer] unspecified
  // [cfe] unspecified
  //                        ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void main() {
  [1, 4, 6, 8].forEach((final value) => print(value + 2));
  //                    ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
