// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that the additional runtime type support is output to the right
// Files when using deferred loading.

import 'package:async_helper/async_helper.dart';
import 'constant_emission_test_helper.dart';

void main() {
  runTest() async {
    Map<String, Set<String>> expectedOutputUnits = {
      'ConstructedConstant(C(x=IntConstant(1)))': {'main'},
      'DeferredGlobalConstant(ConstructedConstant(C(x=IntConstant(1))))':
          // With CFE constants, the references are inlined, so the constant
          // only occurs in main.
          {},
      'ConstructedConstant(C(x=IntConstant(2)))': {'lib1'},
      'DeferredGlobalConstant(ConstructedConstant(C(x=IntConstant(2))))': {
        'lib1'
      },
      'ConstructedConstant(C(x=IntConstant(3)))': {'lib1'},
      'ConstructedConstant(C(x=IntConstant(4)))': {'lib2'},
      'DeferredGlobalConstant(ConstructedConstant(C(x=IntConstant(4))))': {
        'lib2'
      },
      'ConstructedConstant(C(x=IntConstant(5)))': {'lib2'},
    };
    await run(
        MEMORY_SOURCE_FILES,
        const [
          OutputUnitDescriptor('memory:lib1.dart', 'm1', 'lib1'),
          OutputUnitDescriptor('memory:lib2.dart', 'm2', 'lib2'),
        ],
        expectedOutputUnits);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

// Make sure that deferred constants are not inlined into the main hunk.
const Map<String, String> MEMORY_SOURCE_FILES = const {
  "main.dart": r"""
import 'c.dart';
import 'lib1.dart' deferred as l1;

const c1 = const C(1);

main() async {
  print(c1.x);
  await l1.loadLibrary();
  l1.m1();
  print(l1.c2);
}
""",
  "lib1.dart": """
import 'c.dart';
import 'lib2.dart' deferred as l2;

const c2 = const C(2);
const c3 = const C(3);

m1() async {
  print(c2);
  print(c3);
  await l2.loadLibrary();
  l2.m2();
  print(l2.c3);
  print(l2.c4);
}
""",
  "lib2.dart": """
import 'c.dart';

const c3 = const C(1);
const c4 = const C(4);
const c5 = const C(5);

m2() async {
  print(c3);
  print(c4);
  print(c5);
}
""",
  "c.dart": """
class C { const C(this.x); final x; }
""",
};
