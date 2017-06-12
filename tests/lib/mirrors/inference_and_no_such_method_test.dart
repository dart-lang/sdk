// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that did type inferencing on parameters
// whose type may change at runtime due to an invocation through
// [InstanceMirror.delegate].

library lib;

@MirrorsUsed(targets: "lib")
import 'dart:mirrors';
import 'package:expect/expect.dart';

class A {
  noSuchMethod(im) {
    reflect(new B()).delegate(im);
  }
}

class B {
  foo(a) => a + 42;
}

main() {
  Expect.equals(42, new B().foo(0));
  Expect.throws(
      () => new A().foo('foo'), (e) => e is ArgumentError || e is TypeError);
}
