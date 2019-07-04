// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred_constant3_shared.dart';
import 'deferred_constant3_lib2.dart' deferred as l2;

/*strong.member: c2:OutputUnit(1, {l1})*/
const c2 = /*strong.OutputUnit(1, {l1})*/ const C(2);

/*strong.member: c3:OutputUnit(1, {l1})*/
const c3 = /*strong.OutputUnit(1, {l1})*/ const C(3);

/*strong.member: m1:OutputUnit(1, {l1})*/
/*strongConst.member: m1:
 OutputUnit(1, {l1}),
 constants=[
  ConstructedConstant(C(x=IntConstant(1)))=OutputUnit(main, {}),
  ConstructedConstant(C(x=IntConstant(2)))=OutputUnit(1, {l1}),
  ConstructedConstant(C(x=IntConstant(3)))=OutputUnit(1, {l1}),
  ConstructedConstant(C(x=IntConstant(4)))=OutputUnit(2, {l2})]
*/
m1() async {
  print(c2);
  print(c3);
  await l2.loadLibrary();
  l2.m2();
  print(l2.c3);
  print(l2.c4);
}
