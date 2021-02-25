// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'shared.dart';
import 'lib2.dart' deferred as l2;

const c2 = const C(2);

const c3 = const C(3);

/*member: m1:
 constants=[
  ConstructedConstant(C(x=IntConstant(1)))=main{},
  ConstructedConstant(C(x=IntConstant(2)))=1{l1},
  ConstructedConstant(C(x=IntConstant(3)))=1{l1},
  ConstructedConstant(C(x=IntConstant(4)))=2{l2}],
 member_unit=1{l1}
*/
m1() async {
  print(c2);
  print(c3);
  await l2.loadLibrary();
  l2.m2();
  print(l2.c3);
  print(l2.c4);
}
