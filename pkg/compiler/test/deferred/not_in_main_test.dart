// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test of the graph segmentation algorithm used by deferred loading
// to determine which elements can be deferred and which libraries
// much be included in the initial download (loaded eagerly).

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

void main() {
  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await deferredTest1();
    await deferredTest2();
    await deferredTest3();
    await deferredTest4();
    await deferredTest5();
  });
}

deferredTest1() async {
  CompilationResult result = await runCompiler(memorySourceFiles: TEST1);

  Compiler compiler = result.compiler;
  var closedWorld = compiler.backendClosedWorldForTesting;
  var env = closedWorld.elementEnvironment;
  var outputUnitForMember = closedWorld.outputUnitData.outputUnitForMember;
  var mainOutputUnit = closedWorld.outputUnitData.mainOutputUnit;
  lookupLibrary(name) => env.lookupLibrary(Uri.parse(name));
  dynamic lib1 = lookupLibrary("memory:lib1.dart");
  dynamic lib2 = lookupLibrary("memory:lib2.dart");
  env.lookupLibraryMember(lib1, "foo1");
  var foo2 = env.lookupLibraryMember(lib2, "foo2");

  Expect.notEquals(mainOutputUnit, outputUnitForMember(foo2));
}

deferredTest2() async {
  CompilationResult result = await runCompiler(memorySourceFiles: TEST2);

  Compiler compiler = result.compiler;
  var closedWorld = compiler.backendClosedWorldForTesting;
  var env = closedWorld.elementEnvironment;
  var outputUnitForClass = closedWorld.outputUnitData.outputUnitForClass;
  var outputUnitForClassType =
      closedWorld.outputUnitData.outputUnitForClassType;
  lookupLibrary(name) => env.lookupLibrary(Uri.parse(name));
  dynamic shared = lookupLibrary("memory:shared.dart");
  var a = env.lookupClass(shared, "A");

  Expect.equals("OutputUnit(1, {import(def: deferred)})",
      outputUnitForClass(a).toString());
  Expect.equals("OutputUnit(1, {import(def: deferred)})",
      outputUnitForClassType(a).toString());
}

deferredTest3() async {
  CompilationResult result = await runCompiler(memorySourceFiles: TEST3);

  Compiler compiler = result.compiler;
  var closedWorld = compiler.backendClosedWorldForTesting;
  var env = closedWorld.elementEnvironment;
  var outputUnitForClass = closedWorld.outputUnitData.outputUnitForClass;
  var outputUnitForClassType =
      closedWorld.outputUnitData.outputUnitForClassType;
  var mainOutputUnit = closedWorld.outputUnitData.mainOutputUnit;
  lookupLibrary(name) => env.lookupLibrary(Uri.parse(name));
  dynamic shared = lookupLibrary("memory:shared.dart");
  var a = env.lookupClass(shared, "A");

  Expect.equals(mainOutputUnit, outputUnitForClass(a));
  Expect.equals(mainOutputUnit, outputUnitForClassType(a));
}

deferredTest4() async {
  CompilationResult result = await runCompiler(memorySourceFiles: TEST4);

  Compiler compiler = result.compiler;
  var closedWorld = compiler.backendClosedWorldForTesting;
  var env = closedWorld.elementEnvironment;
  var outputUnitForClass = closedWorld.outputUnitData.outputUnitForClass;
  var outputUnitForClassType =
      closedWorld.outputUnitData.outputUnitForClassType;
  var mainOutputUnit = closedWorld.outputUnitData.mainOutputUnit;
  lookupLibrary(name) => env.lookupLibrary(Uri.parse(name));
  dynamic shared = lookupLibrary("memory:shared.dart");
  var a = env.lookupClass(shared, "A");

  Expect.equals("OutputUnit(1, {import(def: deferred)})",
      outputUnitForClass(a).toString());
  Expect.equals(mainOutputUnit, outputUnitForClassType(a));
}

deferredTest5() async {
  CompilationResult result = await runCompiler(memorySourceFiles: TEST5);

  Compiler compiler = result.compiler;
  var closedWorld = compiler.backendClosedWorldForTesting;
  var env = closedWorld.elementEnvironment;
  var outputUnitForClass = closedWorld.outputUnitData.outputUnitForClass;
  var outputUnitForClassType =
      closedWorld.outputUnitData.outputUnitForClassType;
  lookupLibrary(name) => env.lookupLibrary(Uri.parse(name));
  dynamic shared = lookupLibrary("memory:shared.dart");
  var a = env.lookupClass(shared, "A");
  Expect.equals(
      "OutputUnit(1, {import(def2: deferred), import(def3: deferred)})",
      outputUnitForClass(a).toString());
  Expect.equals(
      "OutputUnit(2, {import(def1: deferred), "
      "import(def2: deferred), "
      "import(def3: deferred)})",
      outputUnitForClassType(a).toString());
}

// lib1 imports lib2 deferred. But mainlib never uses DeferredLibrary.
// Test that this case works.
const Map<String, String> TEST1 = const {
  "main.dart": """
library mainlib;

import 'lib1.dart' as lib1;

void main() {
  lib1.foo1();
}
""",
  "lib1.dart": """
library lib1;

import 'lib2.dart' deferred as lib2;

void foo1() {
  lib2.loadLibrary().then((_) => lib2.foo2());
}
""",
  "lib2.dart": """
library lib2;

void foo2() {}
""",
};

// A's type should be in main.
const Map<String, String> TEST2 = const {
  "main.dart": """
import 'def.dart' deferred as def;
import 'shared.dart';

typedef void F(x);

main() {
  print(getFoo() is F);
  def.loadLibrary().then((_) {
    def.toto();
  });
}
""",
  "def.dart": """
import 'shared.dart';

toto() { print(new A()); }
""",
  "shared.dart": """
class A {}
class B extends A {}
foo(B b) => null;
getFoo() => foo;
""",
};

// main directly uses class A from shared. A should be included in the
// main fragment.
const Map<String, String> TEST3 = const {
  "main.dart": """
import 'def.dart' deferred as def;
import 'shared.dart';

main() {
  print(A());
  def.loadLibrary().then((_) {
    def.toto();
  });
}
""",
  "def.dart": """
import 'shared.dart';

toto() { print(new A()); }
""",
  "shared.dart": """
class A {}
class B extends A {}
""",
};

// main directly uses class A's type from shared. A's type but not class
// should be included in main.
const Map<String, String> TEST4 = const {
  "main.dart": """
import 'def.dart' deferred as def;
import 'shared.dart';

main() {
  var v = 5;
  print(v is A);
  def.loadLibrary().then((_) {
    def.toto();
  });
}
""",
  "def.dart": """
import 'shared.dart';

toto() { print(new A()); }
""",
  "shared.dart": """
class A {}
""",
};

// main doesn't directly use A's class or type, but does so indirectly.
const Map<String, String> TEST5 = const {
  "main.dart": """
import 'def1.dart' deferred as def1;
import 'def2.dart' deferred as def2;
import 'def3.dart' deferred as def3;

main() {
  def1.loadLibrary().then((_) {
    def2.loadLibrary().then((_) {
      def3.loadLibrary().then((_) {
        def1.toto(null);
        def2.toto();
        def3.toto(null);
      });
    });
  });
}
""",
  "def1.dart": """
import 'shared.dart';

toto(x) => x is A;
""",
  "def2.dart": """
import 'shared.dart';

toto() { print(A()); }
""",
  "def3.dart": """
import 'shared.dart';

toto(x) {
  print(new A());
  return x is A;
}
""",
  "shared.dart": """
class A {}
""",
};
