// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int if1() {
  if (true) {
    return 499;
  }
  return 3;
}

int if2() {
  if (true) {
    return 499;
  }
}

int if3() {
  if (false) {
    return 42;
  } else {
    if (true) {
      return 499;
    }
    Expect.fail('unreachable');
  }
}

int if4() {
  if (true) {
    return 499;
  } else {
    return 42;
  }
}

int if5() {
  if (true) {
    if (false) return 42;
  } else {}
  return 499;
}

int if6() {
  if (true) {
    if (false) return 42;
  }
  return 499;
}

void main() {
  Expect.equals(499, if1());
  Expect.equals(499, if2());
  Expect.equals(499, if3());
  Expect.equals(499, if4());
  Expect.equals(499, if5());
  Expect.equals(499, if6());
}
