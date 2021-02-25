// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library lib1;

/*class: ConstClass:
 class_unit=2{lib1, lib2},
 type_unit=2{lib1, lib2}
*/
class ConstClass {
  /*member: ConstClass.x:member_unit=2{lib1, lib2}*/
  final x;

  const ConstClass(this.x);
}

/*member: x:
 constants=[ConstructedConstant(ConstClass(x=ConstructedConstant(ConstClass(x=IntConstant(1)))))=2{lib1, lib2}],
 member_unit=2{lib1, lib2}
*/
var x = const ConstClass(const ConstClass(1));

/*class: C:
 class_unit=1{lib1},
 type_unit=1{lib1}
*/
class C {
  /*member: C.foo:member_unit=3{lib2}*/
  static foo() {
    /*closure_unit=3{lib2}*/ () {}(); // Hack to avoid inlining.
    return 1;
  }

  /*member: C.:member_unit=1{lib1}*/
  C();

  /*member: C.bar:member_unit=1{lib1}*/
  bar() {
    /*closure_unit=1{lib1}*/ () {}(); // Hack to avoid inlining.
    return 1;
  }
}

/*class: C1:
 class_unit=none,
 type_unit=none
*/
class C1 {
  /*member: C1.foo:
   constants=[MapConstant({})=3{lib2}],
   member_unit=3{lib2}
  */
  static var foo = const {};
  var bar = const {};
}

/*class: C2:
 class_unit=1{lib1},
 type_unit=1{lib1}
*/
class C2 {
  /*member: C2.foo:member_unit=3{lib2}*/
  static var foo = new Map<int, int>.from({1: 2});

  /*member: C2.bar:member_unit=1{lib1}*/
  var bar = new Map<int, int>.from({1: 2});

  /*member: C2.:member_unit=1{lib1}*/
  C2();
}

/*class: C3:
 class_unit=1{lib1},
 type_unit=1{lib1}
*/
class C3 {
  /*member: C3.foo:
   constants=[ConstructedConstant(ConstClass(x=ConstructedConstant(ConstClass(x=IntConstant(1)))))=2{lib1, lib2}],
   member_unit=3{lib2}
  */
  static final foo = const ConstClass(const ConstClass(1));

  /*member: C3.bar:
   constants=[ConstructedConstant(ConstClass(x=ConstructedConstant(ConstClass(x=IntConstant(1)))))=2{lib1, lib2}],
   member_unit=1{lib1}
  */
  final bar = const ConstClass(const ConstClass(1));

  /*member: C3.:member_unit=1{lib1}*/
  C3();
}

/*class: C4:
 class_unit=1{lib1},
 type_unit=1{lib1}
*/
class C4 {
  /*member: C4.foo:member_unit=3{lib2}*/
  static final foo = new Map<ConstClass, ConstClass>.from({x: x});

  /*member: C4.bar:member_unit=1{lib1}*/
  final bar = new Map<ConstClass, ConstClass>.from({x: x});

  /*member: C4.:member_unit=1{lib1}*/
  C4();
}

/*class: C5:
 class_unit=1{lib1},
 type_unit=1{lib1}
*/
class C5 {
  static const foo = const [
    const {1: 3}
  ];

  /*member: C5.:member_unit=1{lib1}*/
  C5();

  /*member: C5.bar:member_unit=1{lib1}*/
  bar() {
    /*closure_unit=1{lib1}*/ () {}(); // Hack to avoid inlining.
    return 1;
  }
}
