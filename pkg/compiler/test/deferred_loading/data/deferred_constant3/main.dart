// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 output_units=[
  f1: {units: [1{l1}], usedBy: [], needs: []},
  f2: {units: [2{l2}], usedBy: [], needs: []}],
 steps=[
  l1=(f1),
  l2=(f2)]
*/

// @dart = 2.7

import 'shared.dart';
import 'lib1.dart' deferred as l1;

const c1 = const C(1);

/*member: main:
 constants=[
  ConstructedConstant(C(x=IntConstant(1)))=main{},
  ConstructedConstant(C(x=IntConstant(2)))=1{l1}],
 member_unit=main{}
*/
main() async {
  print(c1.x);
  await l1.loadLibrary();
  l1.m1();
  print(l1.c2);
}
