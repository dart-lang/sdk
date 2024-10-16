// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
import '../helpers/type_test_helper.dart';

main() {
  runTest() async {
    TypeEnvironment env = await TypeEnvironment.create(r"""
      class A {}
      class B {}

      main() {
        A();
        B();
      }
      """, testBackendWorld: true);
    JClosedWorld world = env.jClosedWorld;
    final commonMasks = world.abstractValueDomain as CommonMasks;
    FlatTypeMask mask1 = FlatTypeMask.exact(env.getClass('A'), world);
    FlatTypeMask mask2 = FlatTypeMask.exact(env.getClass('B'), world);
    final union1 =
        mask1.nonNullable().union(mask2, commonMasks) as UnionTypeMask;
    final union2 =
        mask2.nonNullable().union(mask1, commonMasks) as UnionTypeMask;
    Expect.equals(union1, union2);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
