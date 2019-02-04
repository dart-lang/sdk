// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the additional runtime type support is output to the right
// Files when using deferred loading.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/compiler.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';
import '../helpers/output_collector.dart';

void main() {
  runTest() async {
    OutputCollector collector = new OutputCollector();
    CompilationResult result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, outputProvider: collector);
    Compiler compiler = result.compiler;
    var closedWorld = compiler.backendClosedWorldForTesting;
    var elementEnvironment = closedWorld.elementEnvironment;

    lookupLibrary(name) {
      return elementEnvironment.lookupLibrary(Uri.parse(name));
    }

    var outputUnitForMember = closedWorld.outputUnitData.outputUnitForMember;

    dynamic lib1 = lookupLibrary("memory:lib1.dart");
    var foo1 = elementEnvironment.lookupLibraryMember(lib1, "foo");
    var ou_lib1 = outputUnitForMember(foo1);

    dynamic lib2 = lookupLibrary("memory:lib2.dart");
    var foo2 = elementEnvironment.lookupLibraryMember(lib2, "foo");
    var ou_lib2 = outputUnitForMember(foo2);

    dynamic mainApp = elementEnvironment.mainLibrary;
    var fooMain = elementEnvironment.lookupLibraryMember(mainApp, "foo");
    var ou_lib1_lib2 = outputUnitForMember(fooMain);

    String mainOutput = collector.getOutput("", OutputType.js);
    String lib1Output =
        collector.getOutput("out_${ou_lib1.name}", OutputType.jsPart);
    String lib2Output =
        collector.getOutput("out_${ou_lib2.name}", OutputType.jsPart);
    String lib12Output =
        collector.getOutput("out_${ou_lib1_lib2.name}", OutputType.jsPart);
    // Test that the deferred constants are not inlined into the main file.
    RegExp re1 = new RegExp(r"= .string1");
    RegExp re2 = new RegExp(r"= .string2");
    RegExp re3 = new RegExp(r"= 1010");
    Expect.isTrue(re1.hasMatch(lib1Output));
    Expect.isTrue(re2.hasMatch(lib1Output));
    Expect.isTrue(re3.hasMatch(lib1Output));
    Expect.isFalse(re1.hasMatch(mainOutput));
    Expect.isFalse(re2.hasMatch(mainOutput));
    Expect.isFalse(re3.hasMatch(mainOutput));
    // Test that the non-deferred constant is inlined.
    Expect.isTrue(new RegExp(r"print\(.string3.\)").hasMatch(mainOutput));
    Expect.isFalse(new RegExp(r"= .string3").hasMatch(mainOutput));
    Expect.isTrue(new RegExp(r"print\(.string4.\)").hasMatch(mainOutput));

    // C(1) is shared between main, lib1 and lib2. Test that lib1 and lib2 each
    // has a reference to it. It is defined in the main output file.
    Expect.isTrue(new RegExp(r"C.C_1 =").hasMatch(mainOutput));
    Expect.isFalse(new RegExp(r"= C.C_1").hasMatch(mainOutput));

    Expect.isTrue(new RegExp(r"= C.C_1").hasMatch(lib1Output));
    Expect.isTrue(new RegExp(r"= C.C_1").hasMatch(lib2Output));

    // C(2) is shared between lib1 and lib2, each of them has their own
    // reference to it.
    Expect.isFalse(new RegExp(r"= C.C_2").hasMatch(mainOutput));

    Expect.isTrue(new RegExp(r"= C.C_2").hasMatch(lib1Output));
    Expect.isTrue(new RegExp(r"= C.C_2").hasMatch(lib2Output));
    Expect.isTrue(new RegExp(r"C.C_2 =").hasMatch(lib12Output));

    // "string4" is shared between lib1 and lib2, but it can be inlined.
    Expect.isTrue(new RegExp(r"= .string4").hasMatch(lib1Output));
    Expect.isTrue(new RegExp(r"= .string4").hasMatch(lib2Output));
    Expect.isFalse(new RegExp(r"= .string4").hasMatch(lib12Output));
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
import 'lib2.dart' deferred as lib2;

const c = "string3";

class C {
  final p;
  const C(this.p);
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
