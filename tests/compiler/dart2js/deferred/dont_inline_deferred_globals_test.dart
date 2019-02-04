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
    var foo1 = elementEnvironment.lookupLibraryMember(lib1, "finalVar");
    var ou_lib1 = outputUnitForMember(foo1);

    String mainOutput = collector.getOutput("", OutputType.js);
    String lib1Output =
        collector.getOutput("out_${ou_lib1.name}", OutputType.jsPart);
    // Test that the deferred globals are not inlined into the main file.
    RegExp re1 = new RegExp(r"= .string1");
    RegExp re2 = new RegExp(r"= .string2");
    Expect.isTrue(re1.hasMatch(lib1Output));
    Expect.isTrue(re2.hasMatch(lib1Output));
    Expect.isFalse(re1.hasMatch(mainOutput));
    Expect.isFalse(re2.hasMatch(mainOutput));
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
final finalVar = "string1";
var globalVar = "string2";
"""
};
