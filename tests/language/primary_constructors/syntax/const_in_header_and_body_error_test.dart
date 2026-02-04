// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error to have the `const` keyword on both the header and body
// part of a declaring constructor.

// SharedOptions=--enable-experiment=primary-constructors

class const C1(final int x) {
  const this : assert(1 != 2);
  //^
  // [analyzer] unspecified
  // [cfe] unspecified
}

sealed class const C2(final int x) {
  const this : assert(1 != 2);
  //^
  // [analyzer] unspecified
  // [cfe] unspecified
}

extension type const C(int x) {
  const this : assert(1 != 2);
  //^
  // [analyzer] unspecified
  // [cfe] unspecified
}

enum const E1(final int x) {
  one(x: 1);
  const this : assert(x != 2);
  //^
  // [analyzer] unspecified
  // [cfe] unspecified
}
