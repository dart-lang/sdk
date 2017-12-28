// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dont_inline_deferred_constants_main.dart" as main;

/*element: C1:OutputUnit(1, {lib1})*/
const C1 = /*OutputUnit(1, {lib1})*/ "string1";

/*element: C2:OutputUnit(1, {lib1})*/
const C2 = /*OutputUnit(1, {lib1})*/ 1010;

class C {
  /*element: C.C3:OutputUnit(1, {lib1})*/
  static const C3 = /*OutputUnit(1, {lib1})*/ "string2";
}

/*element: C4:OutputUnit(1, {lib1})*/
const C4 = /*OutputUnit(main, {})*/ "string4";

/*element: C5:OutputUnit(1, {lib1})*/
const C5 = /*OutputUnit(main, {})*/ const main.C(1);

/*element: C6:OutputUnit(1, {lib1})*/
const C6 = /*OutputUnit(2, {lib1, lib2})*/ const main.C(2);

/*element: foo:OutputUnit(1, {lib1})*/
foo() {
  print("lib1");
  main.foo();
}
