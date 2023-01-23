// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  external A();
}

class B {
  external const B();
}

class C {
  external C.named();
}

class D {
  external const D.named();
}

class E {
  external E() : super();
  external E.redirect() : this();
}

class F {
  external F() {
    print("I have a body");
  }
}