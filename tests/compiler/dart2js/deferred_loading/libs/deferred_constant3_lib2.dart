// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred_constant3_shared.dart';

/*strong.member: c3:OutputUnit(2, {l2})*/
const c3 = /*strong.OutputUnit(main, {})*/ const C(1);

/*strong.member: c4:OutputUnit(2, {l2})*/
const c4 = /*strong.OutputUnit(2, {l2})*/ const C(4);

/*strong.member: c5:OutputUnit(2, {l2})*/
const c5 = /*strong.OutputUnit(2, {l2})*/ const C(5);

/*strong.member: m2:OutputUnit(2, {l2})*/
/*strongConst.member: m2:
 OutputUnit(2, {l2}),
 constants=[
  ConstructedConstant(C(x=IntConstant(1)))=OutputUnit(main, {}),
  ConstructedConstant(C(x=IntConstant(4)))=OutputUnit(2, {l2}),
  ConstructedConstant(C(x=IntConstant(5)))=OutputUnit(2, {l2})]
*/
m2() async {
  print(c3);
  print(c4);
  print(c5);
}
