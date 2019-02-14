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

main() {}
