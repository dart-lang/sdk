// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  var member1; //# 01: compile-time error
  member2() {} //# 02: compile-time error
  get member3 => null; //# 03: compile-time error
  member4() {} //# 04: compile-time error
}

abstract class I {
  var member5; //# 05: ok
  var member6; //# 06: compile-time error
  get member7; //# 07: compile-time error
  get member8; //# 08: compile-time error
  get member9; //# 09: compile-time error
}

abstract class J {
  get member5; //# 05: continued
  member6() {} //# 06: continued
  member7() {} //# 07: continued
  member8() {} //# 08: continued
  member9() {} //# 09: continued
}

abstract class B extends A implements I, J {}

class Class extends B {
  member1() {} //# 01: continued
  var member2; //# 02: continued
  member3() {} //# 03: continued
  get member4 => null; //# 04: continued
  var member5; //# 05: continued
  member8() {} //# 08: continued
  get member9 => null; //# 09: continued
}

main() {
  new Class();
}
