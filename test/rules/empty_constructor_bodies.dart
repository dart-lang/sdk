// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N empty_constructor_bodies`

class A {
  int a;
  A(this.a);
}

class B {
  B() {} //LINT [7:2]
}

class C {
  C();
}

class D {
  D() {
    print('hi');
  }
}

class E {
  E() {
    // Comments make this OK!
  }
}
