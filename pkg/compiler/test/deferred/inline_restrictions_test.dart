// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that we do not accidentally leak code from deferred libraries but do
// allow inlining of empty functions and from main.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/compiler.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

void main() {
  asyncTest(() async {
    OutputCollector collector = new OutputCollector();
    CompilationResult result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, outputProvider: collector);
    Compiler compiler = result.compiler;
    var closedWorld = compiler.backendClosedWorldForTesting;
    var env = closedWorld.elementEnvironment;
    var outputUnitForMember = closedWorld.outputUnitData.outputUnitForMember;
    lookupLibrary(name) => env.lookupLibrary(Uri.parse(name));
    dynamic lib1 = lookupLibrary("memory:lib1.dart");
    var inlineMeAway = env.lookupLibraryMember(lib1, "inlineMeAway");
    var ou_lib1 = outputUnitForMember(inlineMeAway);

    dynamic lib3 = lookupLibrary("memory:lib3.dart");
    var sameContextInline = env.lookupLibraryMember(lib3, "sameContextInline");
    var ou_lib3 = outputUnitForMember(sameContextInline);

    // Test that we actually got different output units.
    Expect.notEquals(ou_lib1.name, ou_lib3.name);

    String mainOutput = collector.getOutput("", OutputType.js);
    String lib1Output =
        collector.getOutput("out_${ou_lib1.name}", OutputType.jsPart);
    String lib3Output =
        collector.getOutput("out_${ou_lib3.name}", OutputType.jsPart);

    // Test that inlineMeAway was inlined and its argument thus dropped.
    //
    // TODO(sigmund): reenable, this commented test changed after porting
    // deferred loading to the new common frontend.
    // RegExp re1 = new RegExp(r"inlined as empty");
    // Expect.isFalse(re1.hasMatch(mainOutput));

    // Test that inlineFromMain was inlined and thus the string moved to lib1.
    RegExp re2 = new RegExp(r"inlined from main");
    Expect.isFalse(re2.hasMatch(mainOutput));
    Expect.isTrue(re2.hasMatch(lib1Output));

    // Test that inlineFromLib1 was not inlined into main.
    RegExp re3 = new RegExp(r"inlined from lib1");
    Expect.isFalse(re3.hasMatch(mainOutput));
    Expect.isTrue(re3.hasMatch(lib1Output));

    // Test that inlineSameContext was inlined into lib1.
    RegExp re4 = new RegExp(r"inline same context");
    // Output can be null when it contains no code.
    Expect.isTrue(lib3Output == null || !re4.hasMatch(lib3Output));
    Expect.isTrue(re4.hasMatch(lib1Output));
  });
}

// Make sure that empty functions are inlined and that functions from
// main also are inlined (assuming normal heuristics).
const Map<String, String> MEMORY_SOURCE_FILES = const {
  "main.dart": """
import "dart:async";

import 'lib1.dart' deferred as lib1;
import 'lib2.dart' deferred as lib2;

inlineFromMain(x) => "inlined from main" + x;

void main() {
  lib1.loadLibrary().then((_) {
    lib2.loadLibrary().then((_) {
      lib1.test();
      lib2.test();
      print(lib1.inlineMeAway("inlined as empty"));
      print(lib1.inlineFromLib1("should stay"));
    });
  });
}
""",
  "lib1.dart": """
import "main.dart" as main;
import "lib3.dart" as lib3;

inlineMeAway(x) {}

inlineFromLib1(x) => "inlined from lib1" + x;

test() {
  print(main.inlineFromMain("should be inlined"));
  print(lib3.sameContextInline("should be inlined"));
}
""",
  "lib2.dart": """
import "lib3.dart" as lib3;

test() {
  print(lib3.sameContextInline("should be inlined"));
}
""",
  "lib3.dart": """
sameContextInline(x) => "inline same context" + x;
"""
};
