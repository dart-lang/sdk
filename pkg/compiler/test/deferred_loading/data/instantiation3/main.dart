// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test instantiation used only in a deferred library.

/*class: global#Instantiation:OutputUnit(1, {b})*/
/*class: global#Instantiation1:OutputUnit(1, {b})*/

/*member: global#instantiate1:OutputUnit(1, {b})*/

import 'lib1.dart' deferred as b;

/*member: main:OutputUnit(main, {})*/
main() async {
  await b.loadLibrary();
  print(b.m(3));
}
