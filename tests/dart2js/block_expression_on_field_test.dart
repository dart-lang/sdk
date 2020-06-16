// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for #36864
///
/// Block expressions in top-level fields used to crash the compiler.
import "package:expect/expect.dart";

final _a = {
  ...{1}
};

class B {
  static Set _b = {
    ...{2}
  };
  Set _c = {
    ...{3}
  };
}

main() {
  Expect.setEquals({1}, _a);
  Expect.setEquals({2}, B._b);
  Expect.setEquals({3}, (new B()._c));
}
