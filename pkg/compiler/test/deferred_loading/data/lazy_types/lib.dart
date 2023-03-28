// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Foo:
 class_unit=4{libB},
 type_unit=2{libA, libB, libC}
*/
class Foo {
  /*member: Foo.x:member_unit=4{libB}*/
  int? x;
  /*member: Foo.:member_unit=4{libB}*/
  Foo() {
    x = DateTime.now().millisecond;
  }
  /*member: Foo.method:member_unit=4{libB}*/
  @pragma('dart2js:noInline')
  int method() => x!;
}

/*member: isFoo:member_unit=2{libA, libB, libC}*/
@pragma('dart2js:noInline')
bool isFoo(o) {
  return o is Foo;
}

/*member: callFooMethod:member_unit=4{libB}*/
@pragma('dart2js:noInline')
int callFooMethod() {
  return Foo().method();
}

typedef int FunFoo(Foo a);
typedef int FunFunFoo(FunFoo b, int c);

/*member: isFunFunFoo:member_unit=2{libA, libB, libC}*/
@pragma('dart2js:noInline')
bool isFunFunFoo(o) {
  return o is FunFunFoo;
}

/*class: Aoo:
 class_unit=none,
 type_unit=6{libC}
*/
class Aoo<T> {}

/*class: Boo:
 class_unit=6{libC},
 type_unit=6{libC}
*/
mixin Boo<T> implements Aoo<T> {}

/*class: Coo:
 class_unit=6{libC},
 type_unit=6{libC}
*/
/*member: Coo.:member_unit=6{libC}*/
class Coo<T> {}

/*class: Doo:
 class_unit=6{libC},
 type_unit=5{libB, libC}
*/
/*member: Doo.:member_unit=6{libC}*/
class Doo<T> extends Coo<T> with Boo<T> {}

/*member: createDooFunFunFoo:member_unit=6{libC}*/
@pragma('dart2js:noInline')
createDooFunFunFoo() => Doo<FunFunFoo>();

/*class: B:
 class_unit=6{libC},
 type_unit=6{libC}
*/
/*member: B.:member_unit=6{libC}*/
class B {}

/*class: B2:
 class_unit=6{libC},
 type_unit=3{libA, libC}
*/
/*member: B2.:member_unit=6{libC}*/
class B2 extends B {}

/*class: C1:
 class_unit=6{libC},
 type_unit=6{libC}
*/
mixin C1 {}

/*class: C2:
 class_unit=6{libC},
 type_unit=6{libC}
*/
/*member: C2.:member_unit=6{libC}*/
class C2 {}

/*class: C3:
 class_unit=6{libC},
 type_unit=3{libA, libC}
*/
/*member: C3.:member_unit=6{libC}*/
class C3 extends C2 with C1 {}

/*class: D1:
 class_unit=6{libC},
 type_unit=6{libC}
*/
mixin D1 {}

/*class: D2:
 class_unit=6{libC},
 type_unit=6{libC}
*/
/*member: D2.:member_unit=6{libC}*/
class D2 {}

/*class: D3:
 class_unit=6{libC},
 type_unit=3{libA, libC}
*/
class D3 = D2 with D1;

/*member: isMega:member_unit=1{libA}*/
@pragma('dart2js:noInline')
bool isMega(o) {
  return o is B2 || o is C3 || o is D3;
}
