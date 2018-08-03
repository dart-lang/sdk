// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_typedef_lib1;

/*class: C:OutputUnit(1, {lib1})*/
class C {
  /*element: C.a:OutputUnit(1, {lib1})*/
  final a;

  /*element: C.b:OutputUnit(1, {lib1})*/
  final b;

  /*element: C.:OutputUnit(1, {lib1})*/
  const C(this.a, this.b);
}

typedef void MyF1();

typedef void MyF2();

/*element: topLevelMethod:OutputUnit(1, {lib1})*/
topLevelMethod() {}

/*element: cA:OutputUnit(1, {lib1})*/
const cA = /*OutputUnit(1, {lib1})*/ const C(MyF1, topLevelMethod);

/*element: cB:OutputUnit(1, {lib1})*/
const cB = /*OutputUnit(1, {lib1})*/ MyF2;
