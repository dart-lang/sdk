// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the graph segmentation algorithm used by deferred loading
// to determine which elements can be deferred and which libraries
// much be included in the initial download (loaded eagerly).

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

void main() {
  deferredTest1();
  deferredTest2();
}

void deferredTest1() {
  asyncTest(() async {
    CompilationResult result = await runCompiler(memorySourceFiles: TEST1);
    Compiler compiler = result.compiler;

    lookupLibrary(name) {
      return compiler.libraryLoader.lookupLibrary(Uri.parse(name));
    }

    var main = compiler.frontendStrategy.elementEnvironment.mainFunction;
    var outputUnitForElement = compiler.deferredLoadTask.outputUnitForElement;

    var mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
    var backend = compiler.backend;
    var lib1 = lookupLibrary("memory:lib1.dart");
    var lib2 = lookupLibrary("memory:lib2.dart");
    var foo1 = lib1.find("foo1");
    var foo2 = lib2.find("foo2");

    Expect.notEquals(mainOutputUnit, outputUnitForElement(foo2));
  });
}

void deferredTest2() {
  asyncTest(() async {
    CompilationResult result = await runCompiler(memorySourceFiles: TEST2);
    Compiler compiler = result.compiler;

    lookupLibrary(name) {
      return compiler.libraryLoader.lookupLibrary(Uri.parse(name));
    }

    var main = compiler.frontendStrategy.elementEnvironment.mainFunction;
    var outputUnitForElement = compiler.deferredLoadTask.outputUnitForElement;

    var mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
    var shared = lookupLibrary("memory:shared.dart");
    var a = shared.find("A");

    Expect.equals(mainOutputUnit, outputUnitForElement(a));
  });
}

// lib1 imports lib2 deferred. But mainlib never uses DeferredLibrary.
// Test that this case works.
const Map TEST1 = const {
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

const def = const DeferredLibrary('lib2');

void foo1() {
  lib1.loadLibrary().then((_) => lib2.foo2());
}
""",
  "lib2.dart": """
library lib2;

void foo2() {}
""",
};

// main indirectly uses class A from shared. A should still be included in the
// main fragment.
const Map TEST2 = const {
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
