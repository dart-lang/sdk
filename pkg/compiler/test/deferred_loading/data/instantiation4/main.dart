// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test instantiations with different type argument count used only in two
// deferred libraries.

/*class: global#Instantiation:class_unit=2{b, c},type_unit=2{b, c}*/
/*class: global#Instantiation1:class_unit=1{b},type_unit=1{b}*/
/*class: global#Instantiation2:class_unit=3{c},type_unit=3{c}*/

/*member: global#instantiate1:member_unit=1{b}*/
/*member: global#instantiate2:member_unit=3{c}*/

import 'lib1.dart' deferred as b;
import 'lib2.dart' deferred as c;

/*member: main:member_unit=main{}*/
main() async {
  await b.loadLibrary();
  await c.loadLibrary();
  print(b.m(3));
  print(c.m(3, 4));
}
