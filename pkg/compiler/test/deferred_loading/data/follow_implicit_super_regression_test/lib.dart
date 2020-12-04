// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: a:member_unit=1{lib}*/
a() => print("123");

/*member: b:member_unit=1{lib}*/
b() => print("123");

/*member: c:member_unit=1{lib}*/
c() => print("123");

/*member: d:member_unit=1{lib}*/
d() => print("123");

/*class: B:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class B {
  /*member: B.:member_unit=1{lib}*/
  B() {
    b();
  }
}

/*class: B2:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: B2.:member_unit=1{lib}*/
class B2 extends B {
  // No constructor creates a synthetic constructor that has an implicit
  // super-call.
}

/*class: A:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class A {
  /*member: A.:member_unit=1{lib}*/
  A() {
    a();
  }
}

/*class: A2:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class A2 extends A {
  // Implicit super call.
  /*member: A2.:member_unit=1{lib}*/
  A2();
}

/*class: C1:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class C1 {}

/*class: C2:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class C2 {
  /*member: C2.:member_unit=1{lib}*/
  C2() {
    c();
  }
}

/*class: C2p:
 class_unit=none,
 type_unit=none
*/
class C2p {
  C2() {
    c();
  }
}

/*class: C3:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: C3.:member_unit=1{lib}*/
class C3 extends C2 with C1 {
  // Implicit redirecting "super" call via mixin.
}

/*class: E:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class E {}

/*class: F:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class F {}

/*class: G:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: G.:member_unit=1{lib}*/
class G extends C3 with C1, E, F {}

/*class: D1:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class D1 {}

/*class: D2:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class D2 {
  /*member: D2.:member_unit=1{lib}*/
  D2(x) {
    d();
  }
}

// Implicit redirecting "super" call with a parameter via mixin.
/*class: D3:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class D3 = D2 with D1;
