// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

void while1() {
  bool cond = true;
  var result = 0;
  var x = 0;
  while (cond) {
    if (x == 10) cond = false;
    result += x;
    x = x + 1;
  }
  Expect.equals(55, result);
}

void while2() {
  var t = 0;
  var i = 0;
  while (i == 0) {
    t = t + 10;
    i++;
  }
  Expect.equals(10, t);
}

void while3() {
  var i = 0;
  while (i == 1) {
    Expect.fail('unreachable');
  }
}

void while4() {
  var cond1 = true;
  var result = 0;
  var i = 0;
  while (cond1) {
    if (i == 9) cond1 = false;
    var cond2 = true;
    var j = 0;
    while (cond2) {
      if (j == 9) cond2 = false;
      result = result + 1;
      j = j + 1;
    }
    i = i + 1;
  }
  Expect.equals(100, result);
}

int while5_2() {
  // The while condition dominates 3 blocks: the body, the block after the loop
  // and the exit block.
  while (true) {
    if (true) {
      return 499;
    }
  }
  return 0;
}

void while5() {
  Expect.equals(499, while5_2());
}

void main() {
  while1();
  while2();
  while3();
  while4();
  while5();
}
