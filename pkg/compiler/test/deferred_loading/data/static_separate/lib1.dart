// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library lib1;

/*class: ConstClass:OutputUnit(2, {lib1, lib2})*/
class ConstClass {
  /*member: ConstClass.x:OutputUnit(2, {lib1, lib2})*/
  final x;

  const ConstClass(this.x);
}

/*member: x:
 OutputUnit(2, {lib1, lib2}),
 constants=[ConstructedConstant(ConstClass(x=ConstructedConstant(ConstClass(x=IntConstant(1)))))=OutputUnit(2, {lib1, lib2})]
*/
var x = const ConstClass(const ConstClass(1));

/*class: C:OutputUnit(1, {lib1})*/
class C {
  /*member: C.foo:OutputUnit(3, {lib2})*/
  static foo() {
    /*OutputUnit(3, {lib2})*/ () {}(); // Hack to avoid inlining.
    return 1;
  }

  /*member: C.:OutputUnit(1, {lib1})*/
  C();

  /*member: C.bar:OutputUnit(1, {lib1})*/
  bar() {
    /*OutputUnit(1, {lib1})*/ () {}(); // Hack to avoid inlining.
    return 1;
  }
}

/*class: C1:null*/
class C1 {
  /*member: C1.foo:
   OutputUnit(3, {lib2}),
   constants=[MapConstant({})=OutputUnit(3, {lib2})]
  */
  static var foo = const {};
  var bar = const {};
}

/*class: C2:OutputUnit(1, {lib1})*/
class C2 {
  /*member: C2.foo:OutputUnit(3, {lib2})*/
  static var foo = new Map<int, int>.from({1: 2});

  /*member: C2.bar:OutputUnit(1, {lib1})*/
  var bar = new Map<int, int>.from({1: 2});

  /*member: C2.:OutputUnit(1, {lib1})*/
  C2();
}

/*class: C3:OutputUnit(1, {lib1})*/
class C3 {
  /*member: C3.foo:
   OutputUnit(3, {lib2}),
   constants=[ConstructedConstant(ConstClass(x=ConstructedConstant(ConstClass(x=IntConstant(1)))))=OutputUnit(2, {lib1, lib2})]
  */
  static final foo = const ConstClass(const ConstClass(1));

  /*member: C3.bar:
   OutputUnit(1, {lib1}),
   constants=[ConstructedConstant(ConstClass(x=ConstructedConstant(ConstClass(x=IntConstant(1)))))=OutputUnit(2, {lib1, lib2})]
  */
  final bar = const ConstClass(const ConstClass(1));

  /*member: C3.:OutputUnit(1, {lib1})*/
  C3();
}

/*class: C4:OutputUnit(1, {lib1})*/
class C4 {
  /*member: C4.foo:OutputUnit(3, {lib2})*/
  static final foo = new Map<ConstClass, ConstClass>.from({x: x});

  /*member: C4.bar:OutputUnit(1, {lib1})*/
  final bar = new Map<ConstClass, ConstClass>.from({x: x});

  /*member: C4.:OutputUnit(1, {lib1})*/
  C4();
}

/*class: C5:OutputUnit(1, {lib1})*/
class C5 {
  static const foo = const [
    const {1: 3}
  ];

  /*member: C5.:OutputUnit(1, {lib1})*/
  C5();

  /*member: C5.bar:OutputUnit(1, {lib1})*/
  bar() {
    /*OutputUnit(1, {lib1})*/ () {}(); // Hack to avoid inlining.
    return 1;
  }
}
