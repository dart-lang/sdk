// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the additional runtime type support is output to the right
// Files when using deferred loading.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/deferred_load.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';
import '../helpers/output_collector.dart';
import '../helpers/program_lookup.dart';

void main() {
  runTest({bool useCFEConstants: false}) async {
    OutputCollector collector = new OutputCollector();
    CompilationResult result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES,
        outputProvider: collector,
        options: useCFEConstants
            ? ['${Flags.enableLanguageExperiments}=constant-update-2018']
            : ['${Flags.enableLanguageExperiments}=no-constant-update-2018']);

    Compiler compiler = result.compiler;
    ProgramLookup lookup = new ProgramLookup(compiler);
    var closedWorld = compiler.backendClosedWorldForTesting;
    var elementEnvironment = closedWorld.elementEnvironment;

    lookupLibrary(name) {
      return elementEnvironment.lookupLibrary(Uri.parse(name));
    }

    OutputUnit Function(MemberEntity) outputUnitForMember =
        closedWorld.outputUnitData.outputUnitForMember;

    LibraryEntity lib1 = lookupLibrary("memory:lib1.dart");
    MemberEntity foo1 =
        elementEnvironment.lookupLibraryMember(lib1, "finalVar");
    OutputUnit ou_lib1 = outputUnitForMember(foo1);

    Map<String, Set<String>> expectedOutputUnits = {
      // Test that the deferred globals are not inlined into the main file.
      'ConstructedConstant(C(field=StringConstant("string1")))': {'lib1'},
      'ConstructedConstant(C(field=StringConstant("string2")))': {'lib1'},
    };

    Map<String, Set<String>> actualOutputUnits = {};

    void processFragment(Fragment fragment, String fragmentName) {
      for (Constant constant in fragment.constants) {
        String text;
        if (constant.value is DeferredGlobalConstantValue) {
          DeferredGlobalConstantValue deferred = constant.value;
          text = deferred.referenced.toStructuredText();
        } else {
          text = constant.value.toStructuredText();
        }
        Set<String> expectedConstantUnit = expectedOutputUnits[text];
        if (expectedConstantUnit == null) {
          if (constant.value is DeferredGlobalConstantValue) {
            print('No expectancy for $constant found in $fragmentName');
          }
        } else {
          (actualOutputUnits[text] ??= <String>{}).add(fragmentName);
        }
      }
    }

    processFragment(lookup.program.mainFragment, 'main');
    processFragment(lookup.getFragment(ou_lib1), 'lib1');

    expectedOutputUnits.forEach((String constant, Set<String> expectedSet) {
      Set<String> actualSet = actualOutputUnits[constant] ?? const <String>{};
      Expect.setEquals(
          expectedSet,
          actualSet,
          "Constant $constant found in $actualSet, expected "
          "$expectedSet");
    });
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
    print('--test from kernel with CFE constants-----------------------------');
    await runTest(useCFEConstants: true);
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
