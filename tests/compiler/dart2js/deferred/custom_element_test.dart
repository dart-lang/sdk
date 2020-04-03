// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
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
    await runTest();
  });
}

runTest() async {
  CompilationResult result =
      await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
  Compiler compiler = result.compiler;
  var closedWorld = compiler.backendClosedWorldForTesting;
  var outputUnitForMember = closedWorld.outputUnitData.outputUnitForMember;
  var outputUnitForClass = closedWorld.outputUnitData.outputUnitForClass;
  var mainOutputUnit = closedWorld.outputUnitData.mainOutputUnit;
  var elementEnvironment = closedWorld.elementEnvironment;
  dynamic lib = elementEnvironment.lookupLibrary(Uri.parse("memory:lib.dart"));
  var customType = elementEnvironment.lookupClass(lib, "CustomType");
  var foo = elementEnvironment.lookupLibraryMember(lib, "foo");
  Expect.notEquals(mainOutputUnit, outputUnitForMember(foo));
  // Native elements are not deferred
  Expect.equals(mainOutputUnit, outputUnitForClass(customType));
}

// The main library imports a file defining a custom element.
// Registering this class implicitly causes the constructors to be
// live. Check that this is handled.
const Map<String, String> MEMORY_SOURCE_FILES = const {
  "main.dart": """
import "lib.dart" deferred as a;
import 'dart:html';

main() {
  document.registerElement("foo-tag", a.a);
  a.foo();
}
""",
  "lib.dart": """
import 'dart:html';
var a = CustomType;

class CustomType extends HtmlElement {
  factory CustomType() => null;
  CustomType.created() : super.created() ;
}

foo() {}
""",
};
