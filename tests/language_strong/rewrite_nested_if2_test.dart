// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

check_true_true(x, y) {
  if (x) {
    if (y) {
      return true;
    }
  }
  return false;
}

check_false_true(x, y) {
  if (x) {} else {
    if (y) {
      return true;
    }
  }
  return false;
}

check_true_false(x, y) {
  if (x) {
    if (y) {} else {
      return true;
    }
  }
  return false;
}

check_false_false(x, y) {
  if (x) {} else {
    if (y) {} else {
      return true;
    }
  }
  return false;
}

main() {
  Expect.equals(true, check_true_true(true, true));
  Expect.equals(false, check_true_true(true, false));
  Expect.equals(false, check_true_true(false, true));
  Expect.equals(false, check_true_true(false, false));

  Expect.equals(false, check_true_false(true, true));
  Expect.equals(true, check_true_false(true, false));
  Expect.equals(false, check_true_false(false, true));
  Expect.equals(false, check_true_false(false, false));

  Expect.equals(false, check_false_true(true, true));
  Expect.equals(false, check_false_true(true, false));
  Expect.equals(true, check_false_true(false, true));
  Expect.equals(false, check_false_true(false, false));

  Expect.equals(false, check_false_false(true, true));
  Expect.equals(false, check_false_false(true, false));
  Expect.equals(false, check_false_false(false, true));
  Expect.equals(true, check_false_false(false, false));
}
