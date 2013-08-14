// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--throw_on_javascript_int_overflow --optimization_counter_threshold=10 --no-use-osr


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
  return 0x20000000000000 + 1;
}


int min_sub_throws() {
  return -0x20000000000000 - 1;
}


int n_arg;
int negate() {
  return -n_arg;
}


int max_literal() {
  return 0x20000000000000;
}


int min_literal() {
  var min_literal = -0x20000000000000;
  return min_literal;
}


int doNotThrow1(a, b) {
  return (a << b) & 0xFFFFFFFF;
}

int doNotThrow2(a, b) {
  return (a << b) & 0xFFFFFFFF;
}


int doNotThrow3(a, b) {
  return (a << b) & 0x7FFFFFFF;
}


int doNotThrow4(a, b) {
  return (a << b) & 0x7FFFFFFF;
}


// We don't test for the _JavascriptIntegerOverflowError since it's not visible.
// It should not be visible since it doesn't exist on dart2js.
bool isJavascriptIntError(e) =>
    e is Error && "$e".startsWith("Javascript Integer Overflow:");

main() {
  Expect.equals(0x20000000000000, max_literal());
  Expect.equals(-0x20000000000000, min_literal());

  // Run the tests once before optimizations.
  dti_arg = 1.9e17;
  Expect.throws(double_to_int, isJavascriptIntError);

  ia_arg1 = (1 << 53);
  ia_arg2 = (1 << 53);
  Expect.throws(integer_add, isJavascriptIntError);

  n_arg = -0x20000000000000;
  Expect.equals(0x20000000000000, negate());

  is_arg = (1 << 53);
  Expect.throws(integer_shift, isJavascriptIntError);

  Expect.throws(max_add_throws, isJavascriptIntError);
  Expect.throws(min_sub_throws, isJavascriptIntError);

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
  dti_arg = 1.9e17;
  Expect.throws(double_to_int, isJavascriptIntError);

  ia_arg1 = (1 << 53);
  ia_arg2 = (1 << 53);
  Expect.throws(integer_add, isJavascriptIntError);

  n_arg = -0x20000000000000;
  Expect.equals(0x20000000000000, negate());

  is_arg = (1 << 53);
  Expect.throws(integer_shift, isJavascriptIntError);

  Expect.throws(max_add_throws, isJavascriptIntError);
  Expect.throws(min_sub_throws, isJavascriptIntError);

  for (int i = 0; i < 20; i++) {
    Expect.equals(0xAFAFA000, doNotThrow1(0xFAFAFA, 12));
    Expect.equals(0x2FAFA000, doNotThrow3(0xFAFAFA, 12));
    Expect.equals(0xABABA000, doNotThrow2(0xFAFAFAABABA, 12));
    Expect.equals(0x2BABA000, doNotThrow4(0xFAFAFAABABA, 12));
  }
  for (int i = 0; i < 20; i++) {
    Expect.equals(0xABABA000, doNotThrow1(0xFAFAFAABABA, 12));
    Expect.equals(0x2BABA000, doNotThrow3(0xFAFAFAABABA, 12));
  }

}
