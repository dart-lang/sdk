// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test instantiations with different type argument count used only in two
// deferred libraries.

/*class: global#Instantiation:OutputUnit(2, {b, c}), type=OutputUnit(2, {b, c})*/
/*class: global#Instantiation1:OutputUnit(1, {b}), type=OutputUnit(1, {b})*/
/*class: global#Instantiation2:OutputUnit(3, {c}), type=OutputUnit(3, {c})*/

/*member: global#instantiate1:OutputUnit(1, {b})*/
/*member: global#instantiate2:OutputUnit(3, {c})*/

import 'lib1.dart' deferred as b;
import 'lib2.dart' deferred as c;

/*member: main:OutputUnit(main, {})*/
main() async {
  await b.loadLibrary();
  await c.loadLibrary();
  print(b.m(3));
  print(c.m(3, 4));
}
