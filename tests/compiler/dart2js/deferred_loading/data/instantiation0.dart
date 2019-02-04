// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test instantiation used only in a deferred library.

/*class: global#Instantiation:OutputUnit(1, {b})*/
/*class: global#Instantiation1:OutputUnit(1, {b})*/

import '../libs/instantiation0_strong_lib1.dart' deferred as b;

/*element: main:OutputUnit(main, {})*/
main() async {
  await b.loadLibrary();
  print(b.m(3));
}
