// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test symbol literals.

library symbol_literal_test;

import 'package:expect/expect.dart';

foo(a, b) => Expect.isTrue(identical(a, b));

var check = foo; // Indirection used to avoid inlining.

main() {
  check(const Symbol("a"), #a);
  check(const Symbol("a"), #
                            a);
  check(const Symbol("ab"), #ab);
  check(const Symbol("ab"), #
                             ab);
  check(const Symbol("a.b"), #a.b);
  check(const Symbol("a.b"), #
                              a
                               .
                                b);
  check(const Symbol("=="), #==);
  check(const Symbol("=="), # ==);
  check(const Symbol("a.toString"), #a.toString);

  // Tries to call the symbol literal #a.toString
  Expect.throws(() => #a.toString(), (e) => e is NoSuchMethodError); /// 01: static type warning
}
