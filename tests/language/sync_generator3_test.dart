// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test program for sync* generator functions and yielding in try blocks.

import "package:expect/expect.dart";

f() sync* {
  try {
    yield 1;
    throw "three";
  } catch (e) {
    yield 2;
    yield e;
  } finally {
    yield 4;
  }
}

test1() {
  var s = f().toString();
  Expect.equals("(1, 2, three, 4)", s);
  print(s);
}

g() sync* {
  try {
    yield "a";
    throw "pow!";
  } finally {
    yield "b";
  }
}

test2() {
  Iterator i = g().iterator;
  Expect.isTrue(i.moveNext());
  Expect.equals("a", i.current);
  Expect.isTrue(i.moveNext());
  Expect.equals("b", i.current);
  Expect.throws(() => i.moveNext(), (error) => error == "pow!");
}

main() {
  test1(); // //# test1: ok
  test2(); // //# test2: ok
}
