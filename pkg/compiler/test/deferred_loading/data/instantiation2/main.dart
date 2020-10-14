// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test instantiations with the same type argument count used only in two
// deferred libraries.

/*class: global#Instantiation:class_unit=1{b, c},type_unit=1{b, c}*/
/*class: global#Instantiation1:class_unit=1{b, c},type_unit=1{b, c}*/

import 'lib1.dart' deferred as b;
import 'lib2.dart' deferred as c;

/*member: main:member_unit=main{}*/
main() async {
  await b.loadLibrary();
  await c.loadLibrary();
  print(b.m(3));
  print(c.m(3));
}
