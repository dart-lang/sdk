// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class B {
  void f(num x) {}
}

abstract class I<T> {
  void f(T x);
}

class C extends B implements I<num> {
  // This method is a "forwarding semi-stub"--the front end needs to add an
  // implementation to it that performs type checking and forwards to B::f.
  void f(num x);
}

main() {
  I<Object> i = new C();
  Expect.throwsTypeError(() {
    i.f('oops');
  });
}
