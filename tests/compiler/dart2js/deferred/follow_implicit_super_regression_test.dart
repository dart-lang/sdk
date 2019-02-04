// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart' as dart2js;
import 'package:expect/expect.dart';

import '../helpers/memory_compiler.dart';

void main() {
  runTest() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    dart2js.Compiler compiler = result.compiler;
    var closedWorld = compiler.backendClosedWorldForTesting;
    var elementEnvironment = closedWorld.elementEnvironment;

    lookupLibrary(name) {
      return elementEnvironment.lookupLibrary(Uri.parse(name));
    }

    var outputUnitForMember = closedWorld.outputUnitData.outputUnitForMember;

    dynamic lib = lookupLibrary("memory:lib.dart");
    var a = elementEnvironment.lookupLibraryMember(lib, "a");
    var b = elementEnvironment.lookupLibraryMember(lib, "b");
    var c = elementEnvironment.lookupLibraryMember(lib, "c");
    var d = elementEnvironment.lookupLibraryMember(lib, "d");
    Expect.equals(outputUnitForMember(a), outputUnitForMember(b));
    Expect.equals(outputUnitForMember(a), outputUnitForMember(c));
    Expect.equals(outputUnitForMember(a), outputUnitForMember(d));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

// Make sure that the implicit references to supers are found by the deferred
// loading dependency mechanism.
const Map<String, String> MEMORY_SOURCE_FILES = const {
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
