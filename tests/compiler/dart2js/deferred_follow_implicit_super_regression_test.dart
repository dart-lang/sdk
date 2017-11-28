// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'memory_compiler.dart';

import 'package:compiler/src/compiler.dart' as dart2js;

void main() {
  asyncTest(() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    dart2js.Compiler compiler = result.compiler;

    lookupLibrary(name) {
      return compiler.libraryLoader.lookupLibrary(Uri.parse(name));
    }

    var outputUnitForEntity =
        compiler.backend.outputUnitData.outputUnitForEntity;

    dynamic lib = lookupLibrary("memory:lib.dart");
    var a = lib.find("a");
    var b = lib.find("b");
    var c = lib.find("c");
    var d = lib.find("d");
    Expect.equals(outputUnitForEntity(a), outputUnitForEntity(b));
    Expect.equals(outputUnitForEntity(a), outputUnitForEntity(c));
    Expect.equals(outputUnitForEntity(a), outputUnitForEntity(d));
  });
}

// Make sure that the implicit references to supers are found by the deferred
// loading dependency mechanism.
const Map MEMORY_SOURCE_FILES = const {
  "main.dart": """
import "lib.dart" deferred as lib;

void main() {
  lib.loadLibrary().then((_) {
    new lib.A2();
    new lib.B2();
    new lib.C3();
    new lib.D3(10);
  });
}
""",
  "lib.dart": """
a() => print("123");

b() => print("123");

c() => print("123");

d() => print("123");

class B {
  B() {
    b();
  }
}

class B2 extends B {
  // No constructor creates a synthetic constructor that has an implicit
  // super-call.
}

class A {
  A() {
    a();
  }
}

class A2 extends A {
  // Implicit super call.
  A2();
}

class C1 {}

class C2 {
  C2() {
    c();
  }
}

class C2p {
  C2() {
    c();
  }
}

class C3 extends C2 with C1 {
  // Implicit redirecting "super" call via mixin.
}

class D1 {
}

class D2 {
  D2(x) {
    d();
  }
}

// Implicit redirecting "super" call with a parameter via mixin.
class D3 = D2 with D1;
""",
};
