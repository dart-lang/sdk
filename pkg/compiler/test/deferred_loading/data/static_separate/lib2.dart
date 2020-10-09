// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library lib2;

import "package:expect/expect.dart";
import "lib1.dart";

/*member: foo:
 constants=[
  ListConstant(<Map<int*,int*>*>[MapConstant(<int*, int*>{IntConstant(1): IntConstant(3)})])=3{lib2},
  MapConstant(<int*, int*>{IntConstant(1): IntConstant(3)})=3{lib2}],
 member_unit=3{lib2}
*/
foo() {
  Expect.equals(1, C.foo());
  Expect.mapEquals({}, C1.foo);

  Expect.mapEquals({1: 2}, C2.foo);
  C2.foo = {1: 2};
  Expect.mapEquals({1: 2}, C2.foo);

  Expect.equals(x, C3.foo);
  Expect.mapEquals({x: x}, C4.foo);
  Expect.listEquals([
    const {1: 3}
  ], C5.foo);
}
