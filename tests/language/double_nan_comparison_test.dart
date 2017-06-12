// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Tests double comparisons with NaN in different contexts.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

test_expr(a, b) => a != b;

test_conditional(a, b) => a != b ? true : false;

test_branch(a, b) {
  if (a != b) {
    return true;
  }
  return false;
}

main() {
  Expect.equals(true, test_expr(0.5, double.NAN));
  for (var i = 0; i < 20; i++) test_expr(0.5, double.NAN);
  Expect.equals(true, test_expr(0.5, double.NAN));

  Expect.equals(true, test_conditional(0.5, double.NAN));
  for (var i = 0; i < 20; i++) test_conditional(0.5, double.NAN);
  Expect.equals(true, test_conditional(0.5, double.NAN));

  Expect.equals(true, test_branch(0.5, double.NAN));
  for (var i = 0; i < 20; i++) test_branch(0.5, double.NAN);
  Expect.equals(true, test_branch(0.5, double.NAN));
}
