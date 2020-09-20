// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  method1();
  method5();
  method6();
  method7();
  get getter8;
  set setter9(_);
  method10();
  get getter11;
  set setter12(_);
  get field13;
  set field14(_);
  method18() {}
  method27() {}
}

abstract class I {
  method10() {}
  get getter11 => 0;
  set setter12(_) {}
  var field13;
  var field14;
  method15() {}
  method16() {}
  method17() {}
  method18() {}
  var member19;
  var member20;
  var member21;
  get member22 => 0;
  set member23(_) {}
  var member24;
  var field25;
  var member26;
}

abstract class J {
  get member20 => null;
  set member20(_) {}
  var member21;
}

class Class extends A implements I, J {
//    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
// [cfe] The non-abstract class 'Class' is missing implementations for these members:
  method1() {}
  method2();
//^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
  get getter3;
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
  set setter4(_);
//^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
  method5() {}
  method6([a]) {}
  set field13(_) {}
  get field14 => 0;
  method15() {}
  method16([a]) {}
  get member24 => 0;
  final field25 = 0;
  set member26(_) {}
  method27();
}

main() {
  new Class();
}
