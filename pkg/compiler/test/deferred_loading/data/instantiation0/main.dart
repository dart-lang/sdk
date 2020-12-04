// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test instantiation used only in a deferred library.

/*class: global#Instantiation:class_unit=1{b},type_unit=1{b}*/
/*class: global#Instantiation1:class_unit=1{b},type_unit=1{b}*/

import 'lib1.dart' deferred as b;

/*member: main:member_unit=main{}*/
main() async {
  await b.loadLibrary();
  print(b.m(3));
}
