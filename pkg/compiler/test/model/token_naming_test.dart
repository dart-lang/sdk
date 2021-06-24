// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:compiler/src/js_backend/js_backend.dart" show TokenScope;

import "package:expect/expect.dart";
import 'package:front_end/src/api_unstable/dart2js.dart' show $A;

String forwardN(TokenScope scope, int N) {
  for (int i = 1; i < N; ++i) {
    scope.getNextName();
  }

  return scope.getNextName();
}

void main() {
  // Test a normal scope.
  TokenScope scope = new TokenScope();

  // We start with 'a'.
  Expect.equals("a", scope.getNextName());
  // We have 24 lower case characters, as s and g are illegal.
  Expect.equals("A", forwardN(scope, 24));
  // Make it overflow by skipping all uppercase.
  Expect.equals("a_", forwardN(scope, 26));
  // Now numbers.
  Expect.equals("a0", forwardN(scope, 1));
  Expect.equals("a9", forwardN(scope, 9));
  // Then lower case letters.
  Expect.equals("aa", forwardN(scope, 1));
  Expect.equals("az", forwardN(scope, 25));
  // Then upper case letters
  Expect.equals("aA", forwardN(scope, 1));
  Expect.equals("aZ", forwardN(scope, 25));
  // Overflow to first position.
  Expect.equals("b_", forwardN(scope, 1));
  // Make sure we skipe g. We have 1 + 10 + 26 + 26 = 63 digits.
  Expect.equals("h_", forwardN(scope, 63 * 5));
  // Likewise, ensure we skip s.
  Expect.equals("t_", forwardN(scope, 63 * 11));
  // And wrap around another digit.
  Expect.equals("a__", forwardN(scope, 63 * 33));

  // Test a filtered scope.
  Set<String> illegal = new Set.from(["b", "aa"]);
  scope = new TokenScope(illegalNames: illegal);

  // We start with 'a'.
  Expect.equals("a", forwardN(scope, 1));
  // Make sure 'b' is skipped.
  Expect.equals("c", forwardN(scope, 1));
  // We have 24 lower case characters, as s and g are illegal.
  Expect.equals("A", forwardN(scope, 22));
  // Make it overflow by skipping all uppercase.
  Expect.equals("a_", forwardN(scope, 26));
  // Now numbers.
  Expect.equals("a0", forwardN(scope, 1));
  Expect.equals("a9", forwardN(scope, 9));
  // Make sure 'aa' is skipped on wrapping
  Expect.equals("ab", forwardN(scope, 1));
  Expect.equals("az", forwardN(scope, 24));

  // Test a initial char
  {
    TokenScope scope = new TokenScope(initialChar: $A);

    // We start with 'A'.
    Expect.equals("A", scope.getNextName());

    // Overflow should still start with 'A'.
    Expect.equals("A_", forwardN(scope, 26));
  }
  {
    TokenScope scope = new TokenScope(initialChar: $A + 1);

    // We start with 'A'.
    Expect.equals("B", scope.getNextName());
  }
}
