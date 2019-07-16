// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test deoptimization on an optimistically hoisted smi check.
// VMOptions=--optimization-counter-threshold=10  --no-background-compilation --enable-inlining-annotations

// Test that lazy deoptimization works if the program returns to a function
// that is scheduled for lazy deoptimization via an exception.

import 'package:expect/expect.dart';

class C {
  dynamic x = 42;
}

const NeverInline = "NeverInline";

@NeverInline
AA(C c, bool b) {
  if (b) {
    c.x = 2.5;
    throw 123;
  }
}

@NeverInline
T1(C c, bool b) {
  try {
    AA(c, b);
  } on dynamic catch (e, st) {
    print(e);
    print(st);
    Expect.isTrue(st is StackTrace, "is StackTrace");
  }
  return c.x + 1;
}

@NeverInline
T2(C c, bool b) {
  try {
    AA(c, b);
  } on String catch (e, st) {
    print(e);
    print(st);
    Expect.isTrue(st is StackTrace, "is StackTrace");
    Expect.isTrue(false);
  } on int catch (e, st) {
    Expect.equals(e, 123);
    Expect.equals(b, true);
    Expect.equals(c.x, 2.5);
    print(st);
    Expect.isTrue(st is StackTrace, "is StackTrace");
  }
  return c.x + 1;
}

main() {
  var c = new C();
  for (var i = 0; i < 10000; ++i) {
    T1(c, false);
    T2(c, false);
  }
  Expect.equals(43, T1(c, false));
  Expect.equals(43, T2(c, false));
  Expect.equals(3.5, T1(c, true));
  Expect.equals(3.5, T2(c, true));
}
