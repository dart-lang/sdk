// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library object_property_access_test;

main() {
  var a1 = new A();
  print(a1.a);
  print(a1.b);

  a1.a = 3;
  print(a1.doubleA);

  var a2 = new A.withArgs(1, 2);
  print(a2.a);
  print(a2.b);

  print(a2.doubleA);
  a2.setA = 42;
  print(a2.a);
}

class A {
  int a;
  int b = 42;

  A();
  A.withArgs(this.a, this.b);

  int get doubleA => a + a;

  void set setA(int a) {
    this.a = a;
  }
}
