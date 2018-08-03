// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

abstract class A {
  m();
}

class B implements A {
  noSuchMethod(Invocation i) {
    return 42;
  }
}

class C extends B {
  noSuchMethod(Invocation i) => 87;

  method() => super.m();
}

void main() {
  C x = new C();
  Expect.equals(87, x.method());
}
