// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'shared.dart';

const c3 = const C(1);

const c4 = const C(4);

const c5 = const C(5);

/*member: m2:
 constants=[
  ConstructedConstant(C(x=IntConstant(1)))=main{},
  ConstructedConstant(C(x=IntConstant(4)))=2{l2},
  ConstructedConstant(C(x=IntConstant(5)))=2{l2}],
 member_unit=2{l2}
*/
m2() async {
  print(c3);
  print(c4);
  print(c5);
}
