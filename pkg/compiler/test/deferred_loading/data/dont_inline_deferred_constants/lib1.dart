// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'exported_main.dart' show C;
import 'exported_main.dart' as main;

const C1 = "string1";

const C1b = const C("string1");

const C2 = 1010;

const C2b = const C(1010);

/*class: D:
 class_unit=none,
 type_unit=none
*/
class D {
  static const C3 = "string2";

  static const C3b = const C("string2");
}

const C4 = "string4";

const C5 = const C(1);

const C6 = const C(2);

/*member: foo:member_unit=1{lib1}*/
foo() {
  print("lib1");
  main.foo();
}
