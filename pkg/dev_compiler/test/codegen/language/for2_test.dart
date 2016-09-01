// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing for statement which captures loop variable.

import "package:expect/expect.dart";

var f;

main() {
  // Capture the loop variable, ensure we capture the right value.
  for (int i = 0; i < 10; i++) {
    if (i == 7) {
      f = () => "i = $i";
    }
  }
  Expect.equals("i = 7", f());

  // There is only one instance of k. The captured variable continues
  // to change.
  int k;
  for (k = 0; k < 10; k++) {
    if (k == 7) {
      f = () => "k = $k";
    }
  }
  Expect.equals("k = 10", f());

  // l gets modified after it's captured. n++ is executed on the
  // newly introduced instance of n (i.e. the instance of the loop
  // iteration after the value is captured).
  for (int n = 0; n < 10; n++) {
    var l = n;
    if (l == 7) {
      f = () => "l = $l, n = $n";
    }
    l++;
  }
  Expect.equals("l = 8, n = 7", f());

  // Loop variable is incremented in loop body instead of the increment.
  // expression. Thus, the captured value is incremented by one before
  // a new loop variable instance is created.
  for (int i = 0; i < 10; /*nothing*/) {
    if (i == 7) {
      f = () => "i = $i";
    }
    i++;
  }
  Expect.equals("i = 8", f());

  // Make sure continue still ensures the loop variable is captured correctly.
  for (int i = 0; i < 10; i++) {
    if (i == 7) {
      f = () => "i = $i";
    }
    continue;
    i++;
  }
  Expect.equals("i = 7", f());

  // Nested loops with captured variables.
  for (int k = 0; k < 5; k++) {
    for (int i = 0; i < 10; i++) {
      if (k == 3 && i == 7) {
        f = () => "k = $k, i = $i";
      }
    }
  }
  Expect.equals("k = 3, i = 7", f());
}
