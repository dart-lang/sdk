// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the graph segmentation algorithm used by deferred loading
// to determine which elements can be deferred and which libraries
// much be included in the initial download (loaded eagerly).

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/deferred_load.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

void main() {
  asyncTest(() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    Compiler compiler = result.compiler;

    var closedWorld = compiler.backendClosedWorldForTesting;
    var env = closedWorld.elementEnvironment;
    lookupLibrary(name) => env.lookupLibrary(Uri.parse(name));
    var main = env.mainFunction;
    Expect.isNotNull(main, "Could not find 'main'");

    var outputUnitForMember = closedWorld.outputUnitData.outputUnitForMember;
    var outputUnitForClass = closedWorld.outputUnitData.outputUnitForClass;

    var mainOutputUnit = closedWorld.outputUnitData.mainOutputUnit;
    var backendStrategy = compiler.backendStrategy;
    var classes = backendStrategy.emitterTask.neededClasses;
    var inputElement = classes.where((e) => e.name == 'InputElement').single;
    dynamic lib1 = lookupLibrary("memory:lib1.dart");
    var foo1 = env.lookupLibraryMember(lib1, "foo1");
    dynamic lib2 = lookupLibrary("memory:lib2.dart");
    var foo2 = env.lookupLibraryMember(lib2, "foo2");
    dynamic lib3 = lookupLibrary("memory:lib3.dart");
    var foo3 = env.lookupLibraryMember(lib3, "foo3");
    dynamic lib4 = lookupLibrary("memory:lib4.dart");
    var bar1 = env.lookupLibraryMember(lib4, "bar1");
    var bar2 = env.lookupLibraryMember(lib4, "bar2");

    OutputUnit ou_lib1 = outputUnitForMember(foo1);
    OutputUnit ou_lib2 = outputUnitForMember(foo2);
    OutputUnit ou_lib1_lib2 = outputUnitForMember(foo3);
    OutputUnit ou_lib4_1 = outputUnitForMember(bar1);
    OutputUnit ou_lib4_2 = outputUnitForMember(bar2);

    Expect.equals(mainOutputUnit, outputUnitForMember(main));
    Expect.notEquals(mainOutputUnit, outputUnitForMember(foo1));
    Expect.notEquals(ou_lib1, ou_lib1_lib2);
    Expect.notEquals(ou_lib2, ou_lib1_lib2);
    Expect.notEquals(ou_lib1, ou_lib2);
    Expect.notEquals(ou_lib4_1, ou_lib4_2);
    Expect.notEquals(ou_lib1, ou_lib4_2);
    // InputElement is native, so it should be in the mainOutputUnit.
    Expect.equals(mainOutputUnit, outputUnitForClass(inputElement));

    var hunksToLoad = closedWorld.outputUnitData.hunksToLoad;

    var hunksLib1 = hunksToLoad["lib1"];
    var hunksLib2 = hunksToLoad["lib2"];
    var hunksLib4_1 = hunksToLoad["lib4_1"];
    var hunksLib4_2 = hunksToLoad["lib4_2"];
    Expect.listEquals([ou_lib1_lib2, ou_lib1], hunksLib1);
    Expect.listEquals([ou_lib1_lib2, ou_lib2], hunksLib2);
    Expect.listEquals([ou_lib4_1], hunksLib4_1);
    Expect.listEquals([ou_lib4_2], hunksLib4_2);
    Expect.equals(hunksToLoad["main"], null);
  });
}

// The main library imports lib1 and lib2 deferred and use lib1.foo1 and
// lib2.foo2.  This should trigger seperate output units for main, lib1 and
// lib2.
//
// Both lib1 and lib2 import lib3 directly and
// both use lib3.foo3.  Therefore a shared output unit for lib1 and lib2 should
// be created.
//
// lib1 and lib2 also import lib4 deferred, but lib1 uses lib4.bar1 and lib2
// uses lib4.bar2.  So two output units should be created for lib4, one for each
// import.
const Map<String, String> MEMORY_SOURCE_FILES = const {
  "main.dart": """
import "dart:async";
import 'lib1.dart' deferred as lib1;
import 'lib2.dart' deferred as lib2;

void main() {
  lib1.loadLibrary().then((_) {
        lib1.foo1();
        new lib1.C();
    lib2.loadLibrary().then((_) {
        lib2.foo2();
    });
  });
}
""",
  "lib1.dart": """
library lib1;
import "dart:async";
import "dart:html";

import "lib3.dart" as l3;
import "lib4.dart" deferred as lib4_1;

class C {}

foo1() {
  new InputElement();
  lib4_1.loadLibrary().then((_) {
    lib4_1.bar1();
  });
  return () {return 1 + l3.foo3();} ();
}
""",
  "lib2.dart": """
library lib2;
import "dart:async";
import "lib3.dart" as l3;
import "lib4.dart" deferred as lib4_2;

foo2() {
  lib4_2.loadLibrary().then((_) {
    lib4_2.bar2();
  });
  return () {return 2+l3.foo3();} ();
}
""",
  "lib3.dart": """
library lib3;

foo3() {
  return () {return 3;} ();
}
""",
  "lib4.dart": """
library lib4;

bar1() {
  return "hello";
}

bar2() {
  return 2;
}
""",
};
