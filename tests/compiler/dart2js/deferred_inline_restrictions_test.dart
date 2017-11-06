// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we do not accidentally leak code from deferred libraries but do
// allow inlining of empty functions and from main.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/compiler.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

void main() {
  asyncTest(() async {
    OutputCollector collector = new OutputCollector();
    CompilationResult result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, outputProvider: collector);
    Compiler compiler = result.compiler;

    lookupLibrary(name) {
      return compiler.libraryLoader.lookupLibrary(Uri.parse(name));
    }

    var outputUnitForEntity =
        compiler.backend.outputUnitData.outputUnitForEntity;

    dynamic lib1 = lookupLibrary("memory:lib1.dart");
    var inlineMeAway = lib1.find("inlineMeAway");
    var ou_lib1 = outputUnitForEntity(inlineMeAway);

    dynamic lib3 = lookupLibrary("memory:lib3.dart");
    var sameContextInline = lib3.find("sameContextInline");
    var ou_lib3 = outputUnitForEntity(sameContextInline);

    // Test that we actually got different output units.
    Expect.notEquals(ou_lib1.name, ou_lib3.name);

    String mainOutput = collector.getOutput("", OutputType.js);
    String lib1Output =
        collector.getOutput("out_${ou_lib1.name}", OutputType.jsPart);
    String lib3Output =
        collector.getOutput("out_${ou_lib3.name}", OutputType.jsPart);

    RegExp re1 = new RegExp(r"inlined as empty");
    RegExp re2 = new RegExp(r"inlined from main");
    RegExp re3 = new RegExp(r"inlined from lib1");
    RegExp re4 = new RegExp(r"inline same context");

    // Test that inlineMeAway was inlined and its argument thus dropped.
    Expect.isFalse(re1.hasMatch(mainOutput));

    // Test that inlineFromMain was inlined and thus the string moved to lib1.
    Expect.isFalse(re2.hasMatch(mainOutput));
    Expect.isTrue(re2.hasMatch(lib1Output));

    // Test that inlineFromLib1 was not inlined into main.
    Expect.isFalse(re3.hasMatch(mainOutput));
    Expect.isTrue(re3.hasMatch(lib1Output));

    // Test that inlineSameContext was inlined into lib1.
    Expect.isFalse(re4.hasMatch(lib3Output));
    Expect.isTrue(re4.hasMatch(lib1Output));
  });
}

// Make sure that empty functions are inlined and that functions from
// main also are inlined (assuming normal heuristics).
const Map MEMORY_SOURCE_FILES = const {
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
