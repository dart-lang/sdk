// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

// Test OSR in different places of a try-catch.

import "package:expect/expect.dart";

maythrow(x) {
  try {
    if (x == null) throw 42;
    return 99;
  } finally { }
}

f1() {
  var s = 0, t = "abc";
  for (var i = 0; i < 21; ++i) {
    s += i;
  }
  try {
    maythrow(null);
  } catch (e) {
    Expect.equals("abc", t);
    Expect.equals(42, e);
    s++;
  }
  return s;
}

f2([x = 1]) {
  var s = 0, t = "abc";
  try {
    try {
      for (var i = 0; i < 20; ++i) {
        if (i == 18) maythrow(null);
        s += x;
      }
    } catch (e) {
      Expect.equals(1, x);
      Expect.equals("abc", t);
      Expect.equals(42, e);
      s++;
    }
  } catch (e) { }
  return s;
}

f3() {
  var s = 0, t = "abc";
  try {
    maythrow(null);
  } catch (e) {
    Expect.equals("abc", t);
    for (var i = 0; i < 21; ++i) {
      s += i;
    }
    Expect.equals("abc", t);
    Expect.equals(42, e);
    return s;
  }
}

f4() {
  var s = 0, t = "abc";
  try {
    for (var i = 0; i < 21; ++i) {
      if (i == 18) maythrow(null);
      s += i;
    }
  } catch (e) {
    Expect.equals("abc", t);
    Expect.equals(42, e);
    s++;
  }
  return s;
}

f5() {
  var s, t = "abc";
  try {
    maythrow(null);
  } catch (e) {
    Expect.equals("abc", t);
    Expect.equals(42, e);
    s = 0;
  }
  for (var i = 0; i < 21; ++i) {
    s += i;
  }
  Expect.equals("abc", t);
  return s;
}

main() {
  Expect.equals(211, f1());
  Expect.equals(19, f2());
  Expect.equals(210, f3());
  Expect.equals(9 * 17 + 1, f4());
  Expect.equals(210, f5());
}
