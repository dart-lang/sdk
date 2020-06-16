// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

var global;

setGlobal(v) {
  global = v;
}

check_true_true(x, y, v) {
  if (x) {
    if (y) {
      setGlobal(v);
    }
  }
}

check_false_true(x, y, v) {
  if (x) {} else {
    if (y) {
      setGlobal(v);
    }
  }
}

check_true_false(x, y, v) {
  if (x) {
    if (y) {} else {
      setGlobal(v);
    }
  }
}

check_false_false(x, y, v) {
  if (x) {} else {
    if (y) {} else {
      setGlobal(v);
    }
  }
}

main() {
  check_true_true(true, true, 4);
  check_true_true(false, false, 1);
  check_true_true(false, true, 2);
  check_true_true(true, false, 3);

  Expect.equals(4, global);

  check_true_false(false, false, 1);
  check_true_false(false, true, 2);
  check_true_false(true, false, 3);
  check_true_false(true, true, 4);

  Expect.equals(3, global);

  check_false_true(false, false, 1);
  check_false_true(false, true, 2);
  check_false_true(true, false, 3);
  check_false_true(true, true, 4);

  Expect.equals(2, global);

  check_false_false(false, false, 1);
  check_false_false(false, true, 2);
  check_false_false(true, false, 3);
  check_false_false(true, true, 4);

  Expect.equals(1, global);
}
