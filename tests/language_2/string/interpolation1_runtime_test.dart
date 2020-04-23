// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A dollar must be followed by a "{" or an identifier.

class A {
  final String str;
  const A(this.str);
}

class StringInterpolation1NegativeTest {
  // Dollar not followed by "{" or identifier.

  static testMain() {

  }
}

main() {
  StringInterpolation1NegativeTest.testMain();
}
