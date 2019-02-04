// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that constants depended on by other constants are correctly deferred.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

void main() {
  runTest() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    Compiler compiler = result.compiler;
    var closedWorld = compiler.backendClosedWorldForTesting;
    var outputUnitForConstant =
        closedWorld.outputUnitData.outputUnitForConstant;
    var mainOutputUnit = closedWorld.outputUnitData.mainOutputUnit;
    List<ConstantValue> allConstants = [];

    addConstantWithDependendencies(ConstantValue c) {
      allConstants.add(c);
      c.getDependencies().forEach(addConstantWithDependendencies);
    }

    dynamic codegenWorldBuilder = compiler.codegenWorldBuilder;
    codegenWorldBuilder.compiledConstants
        .forEach(addConstantWithDependendencies);
    for (String stringValue in ["cA", "cB", "cC"]) {
      StringConstantValue constant =
          allConstants.firstWhere((dynamic constant) {
        return constant.isString && constant.stringValue == stringValue;
      });
      Expect.notEquals(null, outputUnitForConstant(constant),
          "Constant value ${constant.toStructuredText()} has no output unit.");
      Expect.notEquals(
          mainOutputUnit,
          outputUnitForConstant(constant),
          "Constant value ${constant.toStructuredText()} "
          "is in the main output unit.");
    }
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

// The main library imports lib1 and lib2 deferred and use lib1.foo1 and
// lib2.foo2.  This should trigger seperate outputunits for main, lib1 and lib2.
//
// Both lib1 and lib2 import lib3 directly and
// both use lib3.foo3.  Therefore a shared output unit for lib1 and lib2 should
// be created.
//
// lib1 and lib2 also import lib4 deferred, but lib1 uses lib4.bar1 and lib2
// uses lib4.bar2.  So two output units should be created for lib4, one for each
// import.
const Map<String, String> MEMORY_SOURCE_FILES = const {
  "main.dart": """
import 'lib.dart' deferred as lib;

void main() {
  print(lib.L);
}
""",
  "lib.dart": """
class C {
  final a;
  const C(this.a);
}

const L = const {"cA": const C(const {"cB": "cC"})};
""",
};
