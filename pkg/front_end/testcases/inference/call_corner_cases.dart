// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A {
  int call() => 0;
}

class B {
  A get call => new A();
}

class D {
  A fieldA = new A();
  A get getA => new A();
  B fieldB = new B();
  B get getB => new B();
}

test() {
  var callA = new A()();
  var callFieldA = new D().fieldA();
  var callGetA = new D().getA();
  var callFieldB = new D().fieldB();
  var callGetB = new D().getB();
}

main() {}
