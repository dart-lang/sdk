// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

// Check correct deoptimization of instance field increment.

main() {
  var a = new A();
  var aa = new A();
  for (int i = 0; i < 20; i++) {
    a.Incr();
    myIncr(aa);
    conditionalIncr(false, a);
  }
  Expect.equals(20, a.f);
  Expect.equals(20, aa.f);
  a.f = 1.0;
  // Deoptimize ++ part of instance increment.
  a.Incr();
  Expect.equals(2.0, a.f);
  var b = new B();
  // Deoptimize getfield part of instance increment.
  myIncr(b);
  Expect.equals(1.0, b.f);
  // Deoptimize since no type feedback was collected.
  var old = a.f;
  conditionalIncr(true, a);
  Expect.equals(old + 1, a.f);
}

myIncr(var a) {
  a.f++;
}

conditionalIncr(var f, var a) {
  if (f) {
    a.f++;
  }
}

class A {
  A() : f = 0;
  Incr() {
    f++;
  }

  var f;
}

class B {
  B() : f = 0;
  var f;
}
