// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error to have the `const` keyword on both the header and body
// part of a declaring constructor.

class const C1(final int x) {
  const this : assert(1 != 2);
  // [error column 3, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'const' here.
}

sealed class const C2(final int x) {
  const this : assert(1 != 2);
  // [error column 3, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'const' here.
}

extension type const C(int x) {
  const this : assert(1 != 2);
  // [error column 3, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'const' here.
}

enum const E1(final int x) {
  one(1);
  const this : assert(x != 2);
  // [error column 3, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'const' here.
}
