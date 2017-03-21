// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  method1(); /// 01: ok
  method5(); /// 05: ok
  method6(); /// 06: ok
  method7(); /// 07: static type warning
  get getter8; /// 08: static type warning
  set setter9(_); /// 09: static type warning
  method10(); /// 10: static type warning
  get getter11; /// 11: static type warning
  set setter12(_); /// 12: static type warning
  get field13; /// 13: static type warning
  set field14(_); /// 14: static type warning
  method18() {} /// 18: ok
  method27() {} /// 27: ok
}

abstract class I {
  method10() {} /// 10: continued
  get getter11 => 0; /// 11: continued
  set setter12(_) {} /// 12: continued
  var field13; /// 13: continued
  var field14; /// 14: continued
  method15() {} /// 15: ok
  method16() {} /// 16: ok
  method17() {} /// 17: static type warning
  method18() {} /// 18: continued
  var member19; /// 19: static type warning
  var member20; /// 20: static type warning
  var member21; /// 21: static type warning
  get member22 => 0; /// 22: static type warning
  set member23(_) {} /// 23: static type warning
  var member24; /// 24: static type warning
  var field25; /// 25: static type warning
  var member26; /// 26: static type warning
}

abstract class J {
  get member20 => null; /// 20: continued
  set member20(_) {} /// 20: continued
  var member21; /// 21: continued
}

class Class extends A implements I, J {
  method1() {} /// 01: continued
  method2(); /// 02: static type warning
  get getter3; /// 03: static type warning
  set setter4(_); /// 04: static type warning
  method5() {} /// 05: continued
  method6([a]) {} /// 06: continued
  set field13(_) {} /// 13: continued
  get field14 => 0; /// 14: continued
  method15() {} /// 15: continued
  method16([a]) {} /// 16: continued
  get member24 => 0; /// 24: continued
  final field25 = 0; /// 25: continued
  set member26(_) {} /// 26: continued
  method27(); /// 27: continued
}

main() {
  new Class();
}
