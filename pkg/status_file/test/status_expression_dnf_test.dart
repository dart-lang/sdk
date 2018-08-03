// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:status_file/src/expression.dart";
import 'package:status_file/src/disjunctive.dart';

main() {
  testDnf();
}

void shouldDnfTo(String input, String expected) {
  var expression = Expression.parse(input);
  Expect.equals(expected, toDisjunctiveNormalForm(expression).toString());
}

void shouldDnfToExact(String input, Expression expected) {
  var expression = Expression.parse(input);
  Expect.equals(expected, toDisjunctiveNormalForm(expression));
}

void shouldBeSame(String input) {
  shouldDnfTo(input, input);
}

void testDnf() {
  shouldBeSame(r'$a');
  shouldBeSame(r'$a || $b');
  shouldBeSame(r'$a || $b && $c');
  shouldBeSame(r'$a && $b || $b && $c');
  shouldBeSame(r'$a && $b && $c');
  shouldBeSame(r'$a || $b || $c');
  shouldBeSame(r'!$a');
  shouldBeSame(r'!$a && $b');
  shouldBeSame(r'$a && !$b');
  shouldBeSame(r'$a && $b');
  shouldBeSame(r'!$a && !$b');

  // Testing True.
  shouldDnfToExact(r'$a || !$a', T);
  shouldDnfToExact(r'!$a || !$b || $a && $b', T);

  // Testing False
  shouldDnfToExact(r'$a && !$a', F);
  shouldDnfToExact(r'($a || $b) && !$a && !$b', F);

  // Testing dnf and simple minimization (duplicates).
  shouldDnfTo(r'$a && ($b || $c)', r'$a && $b || $a && $c');
  shouldDnfTo(r'($a || $b) && ($c || $d)',
      r'$a && $c || $a && $d || $b && $c || $b && $d');

  // Testing minimizing by complementation
  // The following two examples can be found here:
  // https://en.wikipedia.org/wiki/Quine%E2%80%93McCluskey_algorithm
  shouldDnfTo(
      r"$a && !$b && !$c && !$d || $a && !$b && !$c && $d || "
      r"$a && !$b && $c && !$d || $a && !$b && $c && $d",
      r"$a && !$b");

  shouldDnfTo(
      r"!$a && $b && !$c && !$d || $a && !$b && !$c && !$d || "
      r"$a && !$b && $c && !$d || $a && !$b && $c && $d || $a && $b && !$c && !$d ||"
      r" $a && $b && $c && $d || $a && !$b && !$c && $d || $a && $b && $c && !$d",
      r"$a && !$b || $a && $c || $b && !$c && !$d");

  // Test that an expression is converted to dnf and minified correctly.
  shouldDnfTo(r'($a || $b) && ($a || $c)', r'$a || $b && $c');
  shouldDnfTo(r'(!$a || $b) && ($a || $b)', r'$b');
  shouldDnfTo(r'($a || $b || $c) && (!$a || !$b)',
      r'$a && !$b || !$a && $b || !$b && $c');
}
