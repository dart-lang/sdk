// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:compiler/src/types/types.dart";
import "package:compiler/src/world.dart";
import 'type_test_helper.dart';

main() {
  asyncTest(() async {
    TypeEnvironment env = await TypeEnvironment.create(r"""
      class A {}
      class B {}
      """, mainSource: r"""
      main() {
        new A();
        new B();
      }
      """, compileMode: CompileMode.memory);
    ClosedWorld world = env.closedWorld;
    FlatTypeMask mask1 = new FlatTypeMask.exact(env.getClass('A'));
    FlatTypeMask mask2 = new FlatTypeMask.exact(env.getClass('B'));
    UnionTypeMask union1 = mask1.nonNullable().union(mask2, world);
    UnionTypeMask union2 = mask2.nonNullable().union(mask1, world);
    Expect.equals(union1, union2);
  });
}
