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
  var mainOutputUnit = closedWorld.outputUnitData.mainOutputUnit;
  lookupLibrary(name) => env.lookupLibrary(Uri.parse(name));
  dynamic shared = lookupLibrary("memory:shared.dart");
  var a = env.lookupClass(shared, "A");

  Expect.equals(mainOutputUnit, outputUnitForClass(a));
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

// main indirectly uses class A from shared. A should still be included in the
// main fragment.
const Map<String, String> TEST2 = const {
  "main.dart": """
import 'def.dart' deferred as def;
import 'shared.dart';

typedef void F(x);

main() {
  print(foo is F);
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
""",
};
