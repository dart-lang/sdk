// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the graph segmentation algorithm used by deferred loading
// to determine which elements can be deferred and which libraries
// much be included in the initial download (loaded eagerly).

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'memory_compiler.dart';

Future runTest(String mainScript, test) async {
  CompilationResult result = await runCompiler(
      entryPoint: Uri.parse(mainScript),
      memorySourceFiles: MEMORY_SOURCE_FILES);
  test(result.compiler);
}

lookupLibrary(compiler, name) {
  return compiler.libraryLoader.lookupLibrary(Uri.parse(name));
}

void main() {
  asyncTest(runTests);
}

runTests() async {
  await runTest('memory:main.dart', (compiler) {
    var main = compiler.frontendStrategy.elementEnvironment.mainFunction;
    Expect.isNotNull(main, "Could not find 'main'");
    var outputUnitForEntity =
        compiler.backend.outputUnitData.outputUnitForEntity;

    var lib1 = lookupLibrary(compiler, "memory:lib1.dart");
    var lib2 = lookupLibrary(compiler, "memory:lib2.dart");
    var mathLib = lookupLibrary(compiler, "dart:math");
    var sin = mathLib.find('sin');
    var foo1 = lib1.find("foo1");
    var foo2 = lib2.find("foo2");
    var field2 = lib2.find("field2");

    Expect.notEquals(outputUnitForEntity(main), outputUnitForEntity(foo1));
    Expect.equals(outputUnitForEntity(main), outputUnitForEntity(sin));
    Expect.equals(outputUnitForEntity(foo2), outputUnitForEntity(field2));
  });
  await runTest('memory:main2.dart', (compiler) {
    // Just check that the compile runs.
    // This is a regression test.
    Expect.isTrue(true);
  });
  await runTest('memory:main3.dart', (compiler) {
    var main = compiler.frontendStrategy.elementEnvironment.mainFunction;
    Expect.isNotNull(main, "Could not find 'main'");
    var outputUnitForEntity =
        compiler.backend.outputUnitData.outputUnitForEntity;

    Expect.isFalse(compiler.backend.mirrorsData.hasInsufficientMirrorsUsed);
    var mainLib = lookupLibrary(compiler, "memory:main3.dart");
    var lib3 = lookupLibrary(compiler, "memory:lib3.dart");
    var C = mainLib.find("C");
    var foo = lib3.find("foo");

    Expect.notEquals(outputUnitForEntity(main), outputUnitForEntity(foo));
    Expect.equals(outputUnitForEntity(main), outputUnitForEntity(C));
  });
  await runTest('memory:main4.dart', (compiler) {
    var main = compiler.frontendStrategy.elementEnvironment.mainFunction;
    Expect.isNotNull(main, "Could not find 'main'");
    var outputUnitForEntity =
        compiler.backend.outputUnitData.outputUnitForEntity;

    lookupLibrary(compiler, "memory:main4.dart");
    lookupLibrary(compiler, "memory:lib4.dart");
    var lib5 = lookupLibrary(compiler, "memory:lib5.dart");
    var lib6 = lookupLibrary(compiler, "memory:lib6.dart");
    var foo5 = lib5.find("foo");
    var foo6 = lib6.find("foo");

    Expect.notEquals(outputUnitForEntity(main), outputUnitForEntity(foo5));
    Expect.equals(outputUnitForEntity(foo5), outputUnitForEntity(foo6));
  });
}

// "lib1.dart" uses mirrors without a MirrorsUsed annotation, so everything
// should be put in the "lib1" output unit.
const Map MEMORY_SOURCE_FILES = const {
  "main.dart": """
import "dart:math";

import 'lib1.dart' deferred as lib1;
import 'lib2.dart' deferred as lib2;

void main() {
  lib1.loadLibrary().then((_) {
    lib1.foo1();
  });
  lib2.loadLibrary().then((_) {
    lib2.foo2();
  });
}
""",
  "lib1.dart": """
library lib1;
import "dart:mirrors";

const field1 = 42;

void foo1() {
  var mirror = reflect(field1);
  mirror.invoke(null, null);
}
""",
  "lib2.dart": """
library lib2;
@MirrorsUsed(targets: "field2") import "dart:mirrors";

const field2 = 42;

void foo2() {
  var mirror = reflect(field2);
  mirror.invoke(null, null);
}
""",
// The elements C and f are named as targets, but there is no actual use of
// mirrors.
  "main2.dart": """
import "lib.dart" deferred as lib;

@MirrorsUsed(targets: const ["C", "f"])
import "dart:mirrors";

class C {}

var f = 3;

void main() {

}
""",
  "lib.dart": """ """,
// Lib3 has a MirrorsUsed annotation with a library.
// Check that that is handled correctly.
  "main3.dart": """
library main3;

import "lib3.dart" deferred as lib;

class C {}

class D {}

f() {}

void main() {
  lib.loadLibrary().then((_) {
    lib.foo();
  });
}
""",
  "lib3.dart": """
@MirrorsUsed(targets: const ["main3.C"])
import "dart:mirrors";

foo() {
  currentMirrorSystem().findLibrary(#main3);
}
""",
// Check that exports and imports are handled correctly with mirrors.
  "main4.dart": """
library main3;

@MirrorsUsed(targets: const ["lib5.foo","lib6.foo"])
import "dart:mirrors";

import "lib4.dart" deferred as lib;

void main() {
  lib.loadLibrary().then((_) {
    currentMirrorSystem().findLibrary(#lib5);
  });
}
""",
  "lib4.dart": """
import "lib5.dart";
export "lib6.dart";

""",
  "lib5.dart": """
library lib5;

foo() {}
""",
  "lib6.dart": """
library lib6;

foo() {}
""",
};
