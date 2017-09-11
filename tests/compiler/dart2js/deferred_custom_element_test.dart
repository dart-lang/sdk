// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
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
  asyncTest(() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    Compiler compiler = result.compiler;
    var outputUnitForEntity = compiler.deferredLoadTask.outputUnitForEntity;
    var mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
    dynamic lib =
        compiler.libraryLoader.lookupLibrary(Uri.parse("memory:lib.dart"));
    var customType = lib.find("CustomType");
    var foo = lib.find("foo");
    Expect.notEquals(mainOutputUnit, outputUnitForEntity(foo));
    // Native elements are not deferred
    Expect.equals(mainOutputUnit, outputUnitForEntity(customType));
  });
}

// The main library imports a file defining a custom element.
// Registering this class implicitly causes the constructors to be
// live. Check that this is handled.
const Map MEMORY_SOURCE_FILES = const {
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
