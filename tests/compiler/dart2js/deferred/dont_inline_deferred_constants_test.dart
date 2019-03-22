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

    LibraryEntity lookupLibrary(name) {
      return elementEnvironment.lookupLibrary(Uri.parse(name));
    }

    OutputUnit Function(MemberEntity) outputUnitForMember =
        closedWorld.outputUnitData.outputUnitForMember;

    LibraryEntity lib1 = lookupLibrary("memory:lib1.dart");
    MemberEntity foo1 = elementEnvironment.lookupLibraryMember(lib1, "foo");
    OutputUnit ou_lib1 = outputUnitForMember(foo1);

    LibraryEntity lib2 = lookupLibrary("memory:lib2.dart");
    MemberEntity foo2 = elementEnvironment.lookupLibraryMember(lib2, "foo");
    OutputUnit ou_lib2 = outputUnitForMember(foo2);

    LibraryEntity mainApp = elementEnvironment.mainLibrary;
    MemberEntity fooMain =
        elementEnvironment.lookupLibraryMember(mainApp, "foo");
    OutputUnit ou_lib1_lib2 = outputUnitForMember(fooMain);

    Map<String, Set<String>> expectedOutputUnits = {
      // Test that the deferred constants are not inlined into the main file.
      'IntConstant(1010)': {'lib1'},
      'StringConstant("string1")': {'lib1'},
      'StringConstant("string2")': {'lib1'},
      // "string4" is shared between lib1 and lib2, but it can be inlined.
      'StringConstant("string4")':
          // TODO(johnniwinther): Should we inline CFE constants within deferred
          // library boundaries?
          useCFEConstants ? {'lib12'} : {'lib1', 'lib2'},
      // C(1) is shared between main, lib1 and lib2. Test that lib1 and lib2
      // each has a reference to it. It is defined in the main output file.
      'ConstructedConstant(C(p=IntConstant(1)))':
          // With CFE constants, the references are inlined, so the constant only
          // occurs in main.
          useCFEConstants ? {'main'} : {'main', 'lib1', 'lib2'},
      // C(2) is shared between lib1 and lib2, each of them has their own
      // reference to it.
      'ConstructedConstant(C(p=IntConstant(2)))':
          // With CFE constants, the references are inlined, so the constant
          // occurs in lib12.
          useCFEConstants ? {'lib12'} : {'lib1', 'lib2', 'lib12'},
      // Test that the non-deferred constant is inlined.
      'ConstructedConstant(C(p=IntConstant(5)))': {'main'},
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
    processFragment(lookup.getFragment(ou_lib2), 'lib2');
    processFragment(lookup.getFragment(ou_lib1_lib2), 'lib12');

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
