// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/cps_ir/octagon.dart';
import 'package:expect/expect.dart';

Octagon octagon;
SignedVariable v1, v2, v3, v4;

setup() {
  octagon = new Octagon();
  v1 = octagon.makeVariable();
  v2 = octagon.makeVariable();
  v3 = octagon.makeVariable();
  v4 = octagon.makeVariable();
}

Constraint pushConstraint(SignedVariable w1, SignedVariable w2, int k) {
  Constraint c = new Constraint(w1, w2, k);
  octagon.pushConstraint(c);
  return c;
}

void popConstraint(Constraint c) {
  octagon.popConstraint(c);
}

negative_loop1() {
  setup();
  // Create the contradictory constraint:
  //  v1 <= v2 <= v1 - 1 (loop weight = -1)
  //
  // As difference bounds:
  //  v1 - v2 <= 0
  //  v2 - v1 <= -1
  pushConstraint(v1, v2.negated, 0);
  Expect.isTrue(octagon.isSolvable, 'v1 <= v2: should be solvable');
  var c = pushConstraint(v2, v1.negated, -1);
  Expect.isTrue(octagon.isUnsolvable, 'v2 <= v1 - 1: should become unsolvable');

  // Check that pop restores solvability.
  popConstraint(c);
  Expect.isTrue(octagon.isSolvable, 'Should be solvable without v2 <= v1 - 1');
}

negative_loop2() {
  setup();
  // Create a longer contradiction, and add the middle constraint last:
  //  v1 <= v2 <= v3 <= v1 - 1
  pushConstraint(v1, v2.negated, 0);
  Expect.isTrue(octagon.isSolvable, 'v1 <= v2: should be solvable');
  pushConstraint(v3, v1.negated, -1);
  Expect.isTrue(octagon.isSolvable, 'v3 <= v1 - 1: should be solvable');
  var c = pushConstraint(v2, v3.negated, 0);
  Expect.isTrue(octagon.isUnsolvable, 'v2 <= v3: should become unsolvable');

  // Check that pop restores solvability.
  popConstraint(c);
  Expect.isTrue(octagon.isSolvable, 'Should be solvable without v2 <= v3');
}

negative_loop3() {
  setup();
  // Add a circular constraint with offsets and negative weight:
  //   v1 <= v2 - 1 <= v3 + 2 <= v1 - 1
  // As difference bounds:
  //   v1 - v2 <= -1
  //   v2 - v3 <=  3
  //   v3 - v1 <= -3
  pushConstraint(v1, v2.negated, -1);
  Expect.isTrue(octagon.isSolvable, 'v1 <= v2 - 1: should be solvable');
  pushConstraint(v2, v3.negated, 3);
  Expect.isTrue(octagon.isSolvable, 'v2 - 1 <= v3 + 2: should be solvable');
  var c = pushConstraint(v3, v1.negated, -3);
  Expect.isTrue(octagon.isUnsolvable, 'v3 + 2 <= v1 - 1: should become unsolvable');

  // Check that pop restores solvability.
  popConstraint(c);
  Expect.isTrue(octagon.isSolvable, 'Should be solvable without v3 + 2 <= v1 - 1');
}

zero_loop1() {
  setup();
  // Add the circular constraint with zero weight:
  //   v1 <= v2 <= v3 <= v1
  pushConstraint(v1, v2.negated, 0);
  Expect.isTrue(octagon.isSolvable, 'v1 <= v2: should be solvable');
  pushConstraint(v2, v3.negated, 0);
  Expect.isTrue(octagon.isSolvable, 'v2 <= v3: should be solvable');
  pushConstraint(v3, v1.negated, 0);
  Expect.isTrue(octagon.isSolvable, 'v3 <= v1: should be solvable');
}

zero_loop2() {
  setup();
  // Add a circular constraint with offsets:
  //   v1 <= v2 - 1 <= v3 + 2 <= v1
  // As difference bounds:
  //   v1 - v2 <= -1
  //   v2 - v3 <=  3
  //   v3 - v1 <= -2
  pushConstraint(v1, v2.negated, -1);
  Expect.isTrue(octagon.isSolvable, 'v1 <= v2 - 1: should be solvable');
  pushConstraint(v2, v3.negated, 3);
  Expect.isTrue(octagon.isSolvable, 'v2 - 1 <= v3 + 2: should be solvable');
  pushConstraint(v3, v1.negated, -2);
  Expect.isTrue(octagon.isSolvable, 'v3 + 2 <= v1: should be solvable');
}

positive_loop1() {
  setup();
  // Add constraints with some slack (positive-weight loop):
  //   v1 <= v2 <= v3 <= v1 + 1
  pushConstraint(v1, v2.negated, 0);
  Expect.isTrue(octagon.isSolvable, 'v1 <= v2: should be solvable');
  pushConstraint(v2, v3.negated, 0);
  Expect.isTrue(octagon.isSolvable, 'v2 <= v3: should be solvable');
  pushConstraint(v3, v1.negated, 1);
  Expect.isTrue(octagon.isSolvable, 'v3 <= v1 + 1: should be solvable');
}

positive_loop2() {
  setup();
  // Add constraints with offsets and slack at the end:
  //   v1 <= v2 - 1 <= v3 + 2 <= v1 + 1
  // As difference bounds:
  //   v1 - v2 <= -1
  //   v2 - v3 <=  3
  //   v3 - v1 <= -1
  pushConstraint(v1, v2.negated, -1);
  Expect.isTrue(octagon.isSolvable, 'v1 <= v2 - 1: should be solvable');
  pushConstraint(v2, v3.negated, 3);
  Expect.isTrue(octagon.isSolvable, 'v2 - 1 <= v3 + 2: should be solvable');
  pushConstraint(v3, v1.negated, -1);
  Expect.isTrue(octagon.isSolvable, 'v3 + 2 <= v1: should be solvable');
}

positive_and_negative_loops1() {
  setup();
  //  v1 <= v2 <= v3 <= v1 + 1
  //  v2 <= v3 - 2  (unsolvable: v3 - 2 <= (v1 + 1) - 2 = v1 - 1)
  pushConstraint(v1, v2.negated, 0);
  pushConstraint(v2, v3.negated, 0);
  pushConstraint(v3, v1.negated, 1);
  Expect.isTrue(octagon.isSolvable, 'should be solvable');
  pushConstraint(v2, v3.negated, -2);
  Expect.isTrue(octagon.isUnsolvable, 'v2 <= v3 - 2: should become unsolvable');
}

positive_and_negative_loops2() {
  setup();
  // Same as above, but constraints are added in a different order.
  pushConstraint(v2, v3.negated, -2);
  pushConstraint(v2, v3.negated, 0);
  pushConstraint(v3, v1.negated, 1);
  Expect.isTrue(octagon.isSolvable, 'should be solvable');
  pushConstraint(v1, v2.negated, 0);
  Expect.isTrue(octagon.isUnsolvable, 'v1 <= v2: should become unsolvable');
}

positive_and_negative_loops3() {
  setup();
  // Same as above, but constraints are added in a different order.
  pushConstraint(v2, v3.negated, 0);
  pushConstraint(v2, v3.negated, -2);
  pushConstraint(v3, v1.negated, 1);
  Expect.isTrue(octagon.isSolvable, 'should be solvable');
  pushConstraint(v1, v2.negated, 0);
  Expect.isTrue(octagon.isUnsolvable, 'v1 <= v2: should become unsolvable');
}

plus_minus1() {
  setup();
  // Given:
  //   v1 = v2 + 1    (modeled as: v1 <= v2 + 1 <= v1)
  //   v3 = v4 + 1
  //   v1 <= v3
  // prove:
  //   v2 <= v4
  pushConstraint(v1, v2.negated,  1); // v1 <= v2 + 1
  pushConstraint(v2, v1.negated, -1); // v2 <= v1 - 1
  pushConstraint(v3, v4.negated,  1); // v3 <= v4 + 1
  pushConstraint(v4, v3.negated, -1); // v4 <= v3 - 1
  pushConstraint(v1, v3.negated,  0); // v1 <= v3
  Expect.isTrue(octagon.isSolvable, 'should be solvable');
  // Push the negated constraint: v2 > v4 <=> v4 - v2 <= -1
  pushConstraint(v4, v2.negated, -1);
  Expect.isTrue(octagon.isUnsolvable, 'should be unsolvable');
}

constant1() {
  setup();
  // Given:
  //   v1 = 10
  //   v2 <= v3
  //   v3 + v1 <= 3   (i.e. v2 <= v3 <= -v1 + 3 = 7)
  // prove:
  //   v2 <= 7  (modeled as: v2 + v2 <= 14)
  pushConstraint(v1, v1, 20); // v1 + v1 <= 20
  pushConstraint(v1.negated, v1.negated, -20); // -v1 - v1 <= -20
  pushConstraint(v2, v3.negated, 0); // v2 <= v3
  pushConstraint(v3, v1,  3); // v3 + v1 <= 3
  Expect.isTrue(octagon.isSolvable, 'should be solvable');
  // Push the negated constraint: v2 + v2 > 14 <=> -v2 - v2 <= -15
  var c = pushConstraint(v2.negated, v2.negated, -15);
  Expect.isTrue(octagon.isUnsolvable, 'should be unsolvable');
  popConstraint(c);
  // Push the thing we are trying to prove.
  pushConstraint(v2, v2, 14);
  Expect.isTrue(octagon.isSolvable, 'v2 + v2 <= 14: should be solvable');
}

contradict1() {
  setup();
  // v1 < v1  (v1 - v1 <= -1)
  pushConstraint(v1, v1.negated, -1);
  Expect.isTrue(octagon.isUnsolvable, 'v1 < v1: should be unsolvable');
}

contradict2() {
  setup();
  // v1 = 2
  // v2 = 0
  // v1 <= v2
  pushConstraint(v1, v1, 2);
  pushConstraint(v1.negated, v1.negated, -2);
  pushConstraint(v2, v2, 0);
  pushConstraint(v2.negated, v2.negated, 0);
  Expect.isTrue(octagon.isSolvable, 'should be solvable');
  pushConstraint(v1, v2.negated, 0);
  Expect.isTrue(octagon.isUnsolvable, 'v1 <= v2: should be unsolvable');
}

lower_bounds_check() {
  SignedVariable w = octagon.makeVariable(0, 1000);
  pushConstraint(w, w, -1);
  Expect.isTrue(octagon.isUnsolvable, 'Value in range 0..1000 is not <= -1');
}

upper_bounds_check() {
  SignedVariable w = octagon.makeVariable(0, 1000);
  pushConstraint(w.negated, w.negated, -5000);
  Expect.isTrue(octagon.isUnsolvable, 'Value in range 0..1000 is not >= 5000');
}

void main() {
  negative_loop1();
  negative_loop2();
  negative_loop3();
  zero_loop1();
  zero_loop2();
  positive_loop1();
  positive_loop2();
  positive_and_negative_loops1();
  positive_and_negative_loops2();
  positive_and_negative_loops3();
  plus_minus1();
  constant1();
  contradict1();
  contradict2();
  lower_bounds_check();
  upper_bounds_check();
}
