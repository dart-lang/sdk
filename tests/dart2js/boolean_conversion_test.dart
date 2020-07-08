// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--omit-implicit-checks

// Note: --omit-implicit-checks causes Expect.isNull to misbehave, so we use
// Expect.equals(null, ...) instead.

import 'package:expect/expect.dart';

void main() {
  conditionalTest();
  orTest();
  andTest();
  ifTest();
  forTest();
  whileTest();
  doTest();
  notTest();
  ifElementTest();
  forElementTest();
}

void conditionalTest() {
  bool x = null as dynamic;
  Expect.isFalse(x ? true : false);
}

void orTest() {
  bool x = null as dynamic;
  Expect.equals(null, x || x);
  Expect.isFalse(x || false);
  Expect.isTrue(x || true);
  Expect.equals(null, false || x);
  Expect.isTrue(true || x);
}

void andTest() {
  bool x = null as dynamic;
  Expect.isFalse(x && x);
  Expect.isFalse(x && false);
  Expect.isFalse(x && true);
  Expect.isFalse(false && x);
  Expect.equals(null, true && x);
}

void ifTest() {
  bool x = null as dynamic;
  Expect.isFalse(() {
    if (x) {
      return true;
    } else {
      return false;
    }
  }());
}

void forTest() {
  bool x = null as dynamic;
  Expect.isFalse(() {
    for (; x;) {
      return true;
    }
    return false;
  }());
}

void whileTest() {
  bool x = null as dynamic;
  Expect.isFalse(() {
    while (x) {
      return true;
    }
    return false;
  }());
}

void doTest() {
  bool x = null as dynamic;
  Expect.equals(1, () {
    int n = 0;
    do {
      n++;
    } while (x);
    return n;
  }());
}

void notTest() {
  bool x = null as dynamic;
  Expect.isTrue(!x);
}

void ifElementTest() {
  bool x = null as dynamic;
  Expect.listEquals([], [if (x) 1]);
}

void forElementTest() {
  bool x = null as dynamic;
  Expect.listEquals([], [for (var i = 0; x; i++) i]);
}
