// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/deferred_constant3_shared.dart';
import '../libs/deferred_constant3_lib1.dart' deferred as l1;

/*strong.member: c1:OutputUnit(main, {})*/
const c1 = /*strong.OutputUnit(main, {})*/ const C(1);

/*strong.member: main:OutputUnit(main, {})*/
/*strongConst.member: main:
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
