// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec|three-frag.class: Foo:
 class_unit=1{libB},
 type_unit=3{libA, libB, libC}
*/
/*two-frag.class: Foo:
 class_unit=1{libB, libA},
 type_unit=3{libA, libB, libC}
*/
class Foo {
  /*spec|three-frag.member: Foo.x:member_unit=1{libB}*/
  /*two-frag.member: Foo.x:member_unit=1{libB, libA}*/
  int x;
  /*spec|three-frag.member: Foo.:member_unit=1{libB}*/
  /*two-frag.member: Foo.:member_unit=1{libB, libA}*/
  Foo() {
    x = DateTime.now().millisecond;
  }
  /*spec|three-frag.member: Foo.method:member_unit=1{libB}*/
  /*two-frag.member: Foo.method:member_unit=1{libB, libA}*/
  int method() => x;
}

/*member: isFoo:member_unit=3{libA, libB, libC}*/
bool isFoo(o) {
  return o is Foo;
}

/*spec|three-frag.member: callFooMethod:member_unit=1{libB}*/
/*two-frag.member: callFooMethod:member_unit=1{libB, libA}*/
int callFooMethod() {
  return Foo().method();
}

typedef int FunFoo(Foo a);
typedef int FunFunFoo(FunFoo b, int c);

/*member: isFunFunFoo:member_unit=3{libA, libB, libC}*/
bool isFunFunFoo(o) {
  return o is FunFunFoo;
}

/*class: Aoo:
 class_unit=none,
 type_unit=2{libC}
*/
class Aoo<T> {}

/*class: Boo:
 class_unit=2{libC},
 type_unit=2{libC}
*/
class Boo<T> implements Aoo<T> {}

/*class: Coo:
 class_unit=2{libC},
 type_unit=2{libC}
*/
/*member: Coo.:member_unit=2{libC}*/
class Coo<T> {}

/*spec|three-frag.class: Doo:
 class_unit=2{libC},
 type_unit=5{libB, libC}
*/
/*two-frag.class: Doo:
 class_unit=2{libC},
 type_unit=5{libB, libC, libA}
*/
/*member: Doo.:member_unit=2{libC}*/
class Doo<T> extends Coo<T> with Boo<T> {}

/*member: createDooFunFunFoo:member_unit=2{libC}*/
createDooFunFunFoo() => Doo<FunFunFoo>();

/*class: B:
 class_unit=2{libC},
 type_unit=2{libC}
*/
/*member: B.:member_unit=2{libC}*/
class B {}

/*class: B2:
 class_unit=2{libC},
 type_unit=4{libA, libC}
*/
/*member: B2.:member_unit=2{libC}*/
class B2 extends B {}

/*class: C1:
 class_unit=2{libC},
 type_unit=2{libC}
*/
class C1 {}

/*class: C2:
 class_unit=2{libC},
 type_unit=2{libC}
*/
/*member: C2.:member_unit=2{libC}*/
class C2 {}

/*class: C3:
 class_unit=2{libC},
 type_unit=4{libA, libC}
*/
/*member: C3.:member_unit=2{libC}*/
class C3 extends C2 with C1 {}

/*class: D1:
 class_unit=2{libC},
 type_unit=2{libC}
*/
class D1 {}

/*class: D2:
 class_unit=2{libC},
 type_unit=2{libC}
*/
/*member: D2.:member_unit=2{libC}*/
class D2 {}

/*class: D3:
 class_unit=2{libC},
 type_unit=4{libA, libC}
*/
class D3 = D2 with D1;

/*member: isMega:member_unit=6{libA}*/
bool isMega(o) {
  return o is B2 || o is C3 || o is D3;
}
