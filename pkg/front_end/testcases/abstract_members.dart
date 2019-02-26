// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Interface1 {
  void interfaceMethod1() {}
}

class Interface2 {
  void interfaceMethod2() {}

  var interfaceMethod1;
}

class Interface3 {
  void interfaceMethod3() {}
}

abstract class A implements Interface1, Interface2, Interface3 {
  aMethod() {}
  abstractMethod();
  void set property1(_);
  void set property2(_);
  void set property3(_);
}

abstract class B extends A {
  final property1 = null;
  aMethod() {}
  bMethod() {}
}

class MyClass extends B {
  var property2;
  aaMethod() {}
  aMethod() {}
  bMethod() {}
  cMethod() {}
}

// This class should have no errors, as it has a non-trivial noSuchMethod.
class MyMock1 extends B {
  noSuchMethod(_) => null;
}

// This class should have no errors, as the abstract method doesn't override
// the non-trivial noSuchMethod inherited from MyMock1.
class MyMock2 extends MyMock1 {
  noSuchMethod(_);
}

// This class should have an error, the abstract method isn't considered
// non-trivial.
class MyMock3 extends B {
  noSuchMethod(_);
}

class C {
  void interfaceMethod1(_) {}
}

// This class should have an error, the method C.interfaceMethod1 conflicts
// with the field Interface2.interfaceMethod1.
abstract class D extends C implements Interface2 {}

class E {
  void set interfaceMethod1(_) {}
}

// This class should have an error, the setter E.interfaceMethod1 conflicts
// with the method Interface1.interfaceMethod1.
abstract class F extends E implements Interface1 {}

class Foo {
  void foo() {}
}

class G {
  Object get foo => null;
}

// This class should have an error, the getter G.foo conflicts with the method
// Foo.foo.
abstract class H extends G implements Foo {}

class Bar {
  Object get foo => null;
}

class I {
  Object foo() {}
}

// This class should have an error, the getter Bar.foo conflicts with the
// method I.foo.
abstract class J extends I implements Bar {}

main() {}
