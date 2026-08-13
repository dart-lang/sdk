// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/type_test_helper.dart';

main() {
  runTest() async {
    TypeEnvironment env = await TypeEnvironment.create(r"""
      main() {}
      """, testBackendWorld: true);
    JClosedWorld world = env.jClosedWorld;
    ClassEntity nullClass = env.commonElements.nullClass;
    final domain = world.abstractValueDomain as CommonMasks;
    FlatTypeMask empty = FlatTypeMask.empty(domain);
    Expect.equals(empty, FlatTypeMask.exact(nullClass, domain));
    Expect.equals(empty, FlatTypeMask.subclass(nullClass, domain));
    Expect.equals(empty, FlatTypeMask.subtype(nullClass, domain));
    Expect.equals(empty, FlatTypeMask.nonNullExact(nullClass, domain));
    Expect.equals(empty, FlatTypeMask.nonNullSubclass(nullClass, domain));
    Expect.equals(empty, FlatTypeMask.nonNullSubtype(nullClass, domain));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
