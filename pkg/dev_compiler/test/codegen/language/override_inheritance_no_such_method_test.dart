// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test use of @proxy and noSuchMethod in relation to abstract methods in
// concrete classes.

abstract class A {
  method6(); /// 06: static type warning
  method7(); /// 07: static type warning
  method8(); /// 08: ok
}

abstract class I {
  method9(); /// 09: static type warning
  method10(); /// 10: static type warning
  method11(); /// 11: ok
}

@proxy /// 02: static type warning
@proxy /// 07: continued
@proxy /// 10: continued
class Class1 extends A implements I {
  method1(); /// 01: static type warning

  method2(); /// 02: continued

  noSuchMethod(_) => null; /// 03: ok
  method3(); /// 03: continued

  noSuchMethod(_, [__]) => null; /// 04: ok
  method4(); /// 04: continued

  noSuchMethod(_); /// 05: ok
  method5(); /// 05: continued

  noSuchMethod(_) => null; /// 08: continued

  noSuchMethod(_) => null; /// 11: continued
}

@proxy /// 12: static type warning
class B {
  method12(); /// 12: continued

  noSuchMethod(_) => null; /// 13: static type warning
  method13(); /// 13: continued
}

class Class2 extends B {
}

main() {
  new Class1();
  new Class2();
}
