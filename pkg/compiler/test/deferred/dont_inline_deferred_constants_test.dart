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
      // Test that the deferred constants are not inlined into the main file.
      'DeferredGlobalConstant(IntConstant(1010))': {'lib1'},
      'DeferredGlobalConstant(StringConstant("string1"))': {'lib1'},
      'DeferredGlobalConstant(StringConstant("string2"))': {'lib1'},
      // "string4" is shared between lib1 and lib2, but it can be inlined.
      'DeferredGlobalConstant(StringConstant("string4"))': {},
      // C(1) is shared between main, lib1 and lib2. Test that lib1 and lib2
      // each has a reference to it. It is defined in the main output file.
      'ConstructedConstant(C(p=IntConstant(1)))': {'main'},
      'DeferredGlobalConstant(ConstructedConstant(C(p=IntConstant(1))))':
          // With CFE constants, the references are inlined, so the constant
          // only occurs in main.
          {},
      // C(2) is shared between lib1 and lib2, each of them has their own
      // reference to it.
      'ConstructedConstant(C(p=IntConstant(2)))': {'lib12'},
      'DeferredGlobalConstant(ConstructedConstant(C(p=IntConstant(2))))':
          // With CFE constants, the references are inlined, so the constant
          // occurs in lib12.
          {'lib12'},
      // Test that the non-deferred constant is inlined.
      'ConstructedConstant(C(p=IntConstant(5)))': {'main'},
    };
    await run(
        MEMORY_SOURCE_FILES,
        const [
          OutputUnitDescriptor('memory:lib1.dart', 'foo', 'lib1'),
          OutputUnitDescriptor('memory:lib2.dart', 'foo', 'lib2'),
          OutputUnitDescriptor('memory:main.dart', 'foo', 'lib12')
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
import "dart:async";

import 'lib1.dart' deferred as lib1;
import 'lib2.dart' deferred as lib2;

const c = "string3";

class C {
  final p;
  const C(this.p);

  String toString() => 'C($p)';
}

foo() => print("main");

void main() {
  lib1.loadLibrary().then((_) {
    lib2.loadLibrary().then((_) {
      lib1.foo();
      lib2.foo();
      print(lib1.C1);
      print(lib1.C2);
      print(lib1.C.C3);
      print(c);
      print(lib1.C4);
      print(lib2.C4);
      print(lib1.C5);
      print(lib2.C5);
      print(lib1.C6);
      print(lib2.C6);
      print("string4");
      print(const C(5));
      print(const C(1));
    });
  });
}
""",
  "lib1.dart": """
import "main.dart" as main;
const C1 = "string1";
const C2 = 1010;
class C {
  static const C3 = "string2";
}
const C4 = "string4";
const C5 = const main.C(1);
const C6 = const main.C(2);
foo() {
  print("lib1");
  main.foo();
}
""",
  "lib2.dart": """
import "main.dart" as main;
const C4 = "string4";
const C5 = const main.C(1);
const C6 = const main.C(2);
foo() {
  print("lib2");
  main.foo();
}
"""
};
