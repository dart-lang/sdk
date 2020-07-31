// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

void do1() {
  bool cond = true;
  var result = 0;
  var x = 0;
  do {
    if (x == 10) cond = false;
    result += x;
    x = x + 1;
  } while (cond);
  Expect.equals(55, result);
}

void do2() {
  var t = 0;
  var i = 0;
  do {
    t = t + 10;
    i++;
  } while (i == 0);
  Expect.equals(10, t);
}

void do3() {
  var i = 0;
  do {
    i++;
  } while (false);
  Expect.equals(1, i);
}

void do4() {
  var cond1 = true;
  var result = 0;
  var i = 0;
  do {
    if (i == 9) cond1 = false;
    var cond2 = true;
    var j = 0;
    do {
      if (j == 9) cond2 = false;
      result = result + 1;
      j = j + 1;
    } while (cond2);
    i = i + 1;
  } while (cond1);
  Expect.equals(100, result);
}

void main() {
  do1();
  do2();
  do3();
  do4();
}
