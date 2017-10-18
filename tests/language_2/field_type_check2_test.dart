// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A a;

  bar(c) {
    c.a = 2; //# 01: runtime error
  }
}

class B {
  int a;
}

main() {
  new A().bar(new A()); //# 01: continued
  new A().bar(new B());
}
