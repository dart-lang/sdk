// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--generic-method-syntax

/// Dart test verifying that the parser can handle certain cases where
/// grammar ambiguity is resolved in favor of generic sends, not
/// relational expressions.

library generic_sends_test;

f(arg1, [arg2]) => null;
g<X, Y>(arg) => null;

main() {
  // Generic invocations.
  f(g<int, String>(3));
  f(g<int, List<String>>(3));
  f(g<int, String>(3), 4);
  f(g<int, List<String>>(3), 4);

  // Relational expressions.
  int a = 0, b = 1, c = 2, d = 3;
  f(a < b, c > 3);
  f(a < b, c >> 3);
  f(a < b, c < d >> 3);
}
