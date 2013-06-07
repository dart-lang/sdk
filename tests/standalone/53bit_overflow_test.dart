// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--throw_on_javascript_int_overflow --optimization_counter_threshold=10


import "package:expect/expect.dart";
import 'dart:typed_data';


double dti_arg;
int double_to_int() {
  return dti_arg.toInt();
}


int ia_arg1;
int ia_arg2;
int integer_add() {
  return ia_arg1 + ia_arg2;
}


int is_arg;
int integer_shift() {
  return is_arg << 1;
}


int max_add_throws() {
  return 0xFFFFFFFFFFFFF + 1;
}


int min_sub_throws() {
  return -0xFFFFFFFFFFFFF - 2;
}


int n_arg;
int negate() {
  return -n_arg;
}


int max_literal() {
  return 0xFFFFFFFFFFFFF;
}


int min_literal() {
  var min_literal = -0xFFFFFFFFFFFFF - 1;
  return min_literal;
}


main() {
  Expect.equals(0xFFFFFFFFFFFFF, max_literal());
  Expect.equals(-0xFFFFFFFFFFFFF - 1, min_literal());

  // Run the tests once before optimizations.
  dti_arg = 1.9e16;
  Expect.throws(double_to_int, (e) => e is FiftyThreeBitOverflowError);

  ia_arg1 = (1 << 51);
  ia_arg2 = (1 << 51);
  Expect.throws(integer_add, (e) => e is FiftyThreeBitOverflowError);

  n_arg = -0xFFFFFFFFFFFFF - 1;
  Expect.throws(negate, (e) => e is FiftyThreeBitOverflowError);

  is_arg = (1 << 51);
  Expect.throws(integer_shift, (e) => e is FiftyThreeBitOverflowError);

  Expect.throws(max_add_throws, (e) => e is FiftyThreeBitOverflowError);
  Expect.throws(min_sub_throws, (e) => e is FiftyThreeBitOverflowError);

  for (int i = 0; i < 20; i++) {
    dti_arg = i.toDouble();
    // Expect.throws calls through the closure, so we have to here, too.
    var f = double_to_int;
    Expect.equals(i, f());

    ia_arg1 = i;
    ia_arg2 = i;
    f = integer_add;
    Expect.equals(i + i, f());

    n_arg = i;
    f = negate;
    Expect.equals(-i, f());

    is_arg = i;
    f = integer_shift;
    Expect.equals(i << 1, f());
  }

  // The optimized functions should now deoptimize and throw the error.
  dti_arg = 1.9e16;
  Expect.throws(double_to_int, (e) => e is FiftyThreeBitOverflowError);

  ia_arg1 = (1 << 51);
  ia_arg2 = (1 << 51);
  Expect.throws(integer_add, (e) => e is FiftyThreeBitOverflowError);

  n_arg = -0xFFFFFFFFFFFFF - 1;
  Expect.throws(negate, (e) => e is FiftyThreeBitOverflowError);

  is_arg = (1 << 51);
  Expect.throws(integer_shift, (e) => e is FiftyThreeBitOverflowError);

  Expect.throws(max_add_throws, (e) => e is FiftyThreeBitOverflowError);
  Expect.throws(min_sub_throws, (e) => e is FiftyThreeBitOverflowError);
}
