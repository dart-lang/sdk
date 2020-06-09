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
      // Test that the deferred globals are not inlined into the main file.
      'ConstructedConstant(C(field=StringConstant("string1")))': {'lib1'},
      'ConstructedConstant(C(field=StringConstant("string2")))': {'lib1'},
      'DeferredGlobalConstant(ConstructedConstant(C(field=StringConstant("string1"))))':
          {'lib1'},
    };

    await run(
        MEMORY_SOURCE_FILES,
        const [OutputUnitDescriptor('memory:lib1.dart', 'finalVar', 'lib1')],
        expectedOutputUnits);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

// Make sure that deferred constants are not inlined into the main hunk.
const Map<String, String> MEMORY_SOURCE_FILES = const {
  "main.dart": """
import "dart:async";

import 'lib1.dart' deferred as lib1;

void main() {
  lib1.loadLibrary().then((_) {
    print(lib1.finalVar);
    print(lib1.globalVar);
    lib1.globalVar = "foobar";
    print(lib1.globalVar);
  });
}
""",
  "lib1.dart": """
import "main.dart" as main;

class C {
  final field;
  const C(this.field);
}

final finalVar = const C("string1");
dynamic globalVar = const C("string2");
"""
};
