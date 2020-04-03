// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

main() {
  final a = new A();
  for (int i = 0; i < 20; i++) {
    final r = interpolIt(a);
    Expect.stringEquals("hello home", r);
  }
  final b = new B();
  // Deoptimize "interpolIt".
  final r = interpolIt(b);
  Expect.stringEquals("hello world", r);
}

String interpolIt(v) {
  // String interpolation will be constant folded.
  return "hello ${v.foo()}";
}

class A {
  foo() => "home";
}

class B {
  foo() => "world";
}
