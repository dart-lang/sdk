// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib1;

/*class: ConstClass:OutputUnit(2, {lib1, lib2})*/
class ConstClass {
  /*element: ConstClass.x:OutputUnit(2, {lib1, lib2})*/
  final x;

  /*element: ConstClass.:OutputUnit(2, {lib1, lib2})*/
  const ConstClass(this.x);
}

/*element: x:OutputUnit(2, {lib1, lib2})*/
var x = const ConstClass(const ConstClass(1));

/*class: C:OutputUnit(1, {lib1})*/
class C {
  /*element: C.foo:OutputUnit(3, {lib2})*/
  static foo() {
    /*OutputUnit(3, {lib2})*/ () {}(); // Hack to avoid inlining.
    return 1;
  }

  /*element: C.:OutputUnit(1, {lib1})*/
  C();

  /*element: C.bar:OutputUnit(1, {lib1})*/
  bar() {
    /*OutputUnit(1, {lib1})*/ () {}(); // Hack to avoid inlining.
    return 1;
  }
}

/*class: C1:OutputUnit(main, {})*/
class C1 {
  /*element: C1.foo:OutputUnit(3, {lib2})*/
  static var foo = const {};
  var bar = const {};
}

/*class: C2:OutputUnit(1, {lib1})*/
class C2 {
  /*element: C2.foo:OutputUnit(3, {lib2})*/
  static var foo = new Map<int, int>.from({1: 2});

  /*element: C2.bar:OutputUnit(1, {lib1})*/
  var bar = new Map<int, int>.from({1: 2});

  /*element: C2.:OutputUnit(1, {lib1})*/
  C2();
}

/*class: C3:OutputUnit(1, {lib1})*/
class C3 {
  /*element: C3.foo:OutputUnit(3, {lib2})*/
  static final foo = const ConstClass(const ConstClass(1));

  /*element: C3.bar:OutputUnit(1, {lib1})*/
  final bar = const ConstClass(const ConstClass(1));

  /*element: C3.:OutputUnit(1, {lib1})*/
  C3();
}

/*class: C4:OutputUnit(1, {lib1})*/
class C4 {
  /*element: C4.foo:OutputUnit(3, {lib2})*/
  static final foo = new Map<ConstClass, ConstClass>.from({x: x});

  /*element: C4.bar:OutputUnit(1, {lib1})*/
  final bar = new Map<ConstClass, ConstClass>.from({x: x});

  /*element: C4.:OutputUnit(1, {lib1})*/
  C4();
}

/*class: C5:OutputUnit(1, {lib1})*/
class C5 {
  /*element: C5.foo:OutputUnit(3, {lib2})*/
  static const foo = /*OutputUnit(3, {lib2})*/ const [
    const {1: 3}
  ];

  /*element: C5.:OutputUnit(1, {lib1})*/
  C5();

  /*element: C5.bar:OutputUnit(1, {lib1})*/
  bar() {
    /*OutputUnit(1, {lib1})*/ () {}(); // Hack to avoid inlining.
    return 1;
  }
}
