// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dont_inline_deferred_constants_main.dart" show C;
import "dont_inline_deferred_constants_main.dart" as main;

/*element: C4:OutputUnit(3, {lib2})*/
const C4 = "string4";

/*element: C5:OutputUnit(3, {lib2})*/
const C5 = /*OutputUnit(main, {})*/ const C(1);

/*element: C6:OutputUnit(3, {lib2})*/
const C6 = /*OutputUnit(2, {lib1, lib2})*/ const C(2);

/*element: foo:OutputUnit(3, {lib2})*/
foo() {
  print("lib2");
  main.foo();
}
