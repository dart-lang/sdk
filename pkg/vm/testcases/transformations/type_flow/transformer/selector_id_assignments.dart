// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Validate the partitioning of methods for selector ID assignment.
// Two members should get the same selector ID(s) iff they have the same name
// and are defined in classes with the same number.

class X {}

class A1 {
  void foo() {
    print("A1");
  }
}

class B1 extends A1 {}

class C1 extends B1 {
  void foo() {
    print("C1");
  }
}

class A2 {
  void foo() {
    print("A2");
  }
}

class B2 extends A2 implements X {
  void foo() {
    print("B2");
  }
}

abstract class A3 {
  void foo();
}

class B3 extends A3 implements X {
  void foo() {
    print("B3");
  }
}

class C3 implements A3 {
  void foo() {
    print("C3");
  }
}

class A4 {
  void foo() {
    print("A4");
  }
}

class B4 {
  void foo() {
    print("B4");
  }
}

class C4 {
  void foo() {
    print("C4");
  }
}

class D4 extends A4 implements B4 {
  void foo() {
    print("D4");
  }
}

class E4 extends C4 implements B4 {}

main() {
  List<A1> x1 = [A1(), B1(), C1()];
  for (A1 o in x1) o.foo();
  List<A2> x2 = [A2(), B2()];
  for (A2 o in x2) o.foo();
  List<A3> x3 = [B3(), C3()];
  for (A3 o in x3) o.foo();
  List<A4> x4 = [A4(), D4()];
  for (A4 o in x4) o.foo();
  List<B4> y4 = [B4(), D4(), E4()];
  for (B4 o in y4) o.foo();
  List<C4> z4 = [C4(), E4()];
  for (C4 o in z4) o.foo();
}
