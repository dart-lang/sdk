// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import "package:compiler/src/world.dart";
import '../helpers/type_test_helper.dart';

main() {
  runTest() async {
    TypeEnvironment env = await TypeEnvironment.create(r"""
      class A {}
      class B {}

      main() {
        new A();
        new B();
      }
      """, testBackendWorld: true);
    JClosedWorld world = env.jClosedWorld;
    AbstractValueDomain commonMasks = world.abstractValueDomain;
    FlatTypeMask mask1 = new FlatTypeMask.exact(env.getClass('A'), world);
    FlatTypeMask mask2 = new FlatTypeMask.exact(env.getClass('B'), world);
    UnionTypeMask union1 = mask1.nonNullable().union(mask2, commonMasks);
    UnionTypeMask union2 = mask2.nonNullable().union(mask1, commonMasks);
    Expect.equals(union1, union2);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
