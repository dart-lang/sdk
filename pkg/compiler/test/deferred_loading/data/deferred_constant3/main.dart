// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'shared.dart';
import 'lib1.dart' deferred as l1;

const c1 = const C(1);

/*member: main:
 OutputUnit(main, {}),
 constants=[
  ConstructedConstant(C(x=IntConstant(1)))=OutputUnit(main, {}),
  ConstructedConstant(C(x=IntConstant(2)))=OutputUnit(1, {l1})]
*/
main() async {
  print(c1.x);
  await l1.loadLibrary();
  l1.m1();
  print(l1.c2);
}
