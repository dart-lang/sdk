// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test use of noSuchMethod in relation to abstract methods in
// concrete classes.

abstract class A {
  method6(); //# 06: compile-time error
  method7(); //# 07: compile-time error
  method8(); //# 08: ok
}

abstract class I {
  method9(); //# 09: compile-time error
  method10(); //# 10: compile-time error
  method11(); //# 11: ok
}

class Class1 extends A implements I {
  method1(); //# 01: compile-time error

  noSuchMethod(_) => null; //# 03: ok
  method3(); //# 03: continued

  noSuchMethod(_, [__]) => null; //# 04: ok
  method4(); //# 04: continued

  noSuchMethod(_); //# 05: compile-time error
  method5(); //# 05: continued

  noSuchMethod(_) => null; //# 08: continued

  noSuchMethod(_) => null; //# 11: continued
}

class B {
  method12(); //# 12: compile-time error

  noSuchMethod(_) => null; //# 13: ok
  method13(); //# 13: continued
}

class Class2 extends B {}

main() {
  new Class1();
  new Class2();
}
