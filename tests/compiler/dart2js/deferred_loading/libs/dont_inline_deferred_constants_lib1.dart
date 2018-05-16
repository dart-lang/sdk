// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dont_inline_deferred_constants_main.dart" show C;
import "dont_inline_deferred_constants_main.dart" as main;

/*element: C1:OutputUnit(1, {lib1})*/
const C1 = "string1";

/*element: C1b:OutputUnit(1, {lib1})*/
const C1b = /*OutputUnit(1, {lib1})*/ const C("string1");

/*element: C2:OutputUnit(1, {lib1})*/
const C2 = 1010;

/*element: C2b:OutputUnit(1, {lib1})*/
const C2b = /*OutputUnit(1, {lib1})*/ const C(1010);

/*class: D:OutputUnit(main, {})*/
class D {
  /*element: D.C3:OutputUnit(1, {lib1})*/
  static const C3 = "string2";

  /*element: D.C3b:OutputUnit(1, {lib1})*/
  static const C3b = /*OutputUnit(1, {lib1})*/ const C("string2");
}

/*element: C4:OutputUnit(1, {lib1})*/
const C4 = "string4";

/*element: C5:OutputUnit(1, {lib1})*/
const C5 = /*OutputUnit(main, {})*/ const C(1);

/*element: C6:OutputUnit(1, {lib1})*/
const C6 = /*OutputUnit(2, {lib1, lib2})*/ const C(2);

/*element: foo:OutputUnit(1, {lib1})*/
foo() {
  print("lib1");
  main.foo();
}
