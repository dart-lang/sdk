// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that constants depended on by other constants are correctly deferred.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/implementation/constants/values.dart';
import 'package:expect/expect.dart';
import 'memory_source_file_helper.dart';


class FakeOutputStream<T> extends EventSink<T> {
  void add(T event) {}
  void addError(T event, [StackTrace stackTrace]) {}
  void close() {}
}

void main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var handler = new FormattingDiagnosticHandler(provider);

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   (name, extension) => new FakeOutputStream(),
                                   handler.diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   [],
                                   {});
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    var outputUnitForElement = compiler.deferredLoadTask.outputUnitForElement;
    var outputUnitForConstant = compiler.deferredLoadTask.outputUnitForConstant;
    var mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
    var lib =
        compiler.libraryLoader.lookupLibrary(Uri.parse("memory:lib.dart"));
    var backend = compiler.backend;
    List<Constant> allConstants = [];

    addConstantWithDependendencies(Constant c) {
      allConstants.add(c);
      c.getDependencies().forEach(addConstantWithDependendencies);
    }

    backend.constants.compiledConstants.forEach(addConstantWithDependendencies);
    for (String stringValue in ["cA", "cB", "cC"]) {
      Constant constant = allConstants.firstWhere((constant) {
        return constant is StringConstant
            && constant.value.slowToString() == stringValue;
      });
      Expect.notEquals(null, outputUnitForConstant(constant));
      Expect.notEquals(mainOutputUnit, outputUnitForConstant(constant));
    }
  }));
}

// The main library imports lib1 and lib2 deferred and use lib1.foo1 and
// lib2.foo2.  This should trigger seperate outputunits for main, lib1 and lib2.
//
// Both lib1 and lib2 import lib3 directly and
// both use lib3.foo3.  Therefore a shared output unit for lib1 and lib2 should
// be created.
//
// lib1 and lib2 also import lib4 deferred, but lib1 uses lib4.bar1 and lib2
// uses lib4.bar2.  So two output units should be created for lib4, one for each
// import.
const Map MEMORY_SOURCE_FILES = const {"main.dart": """
import 'lib.dart' deferred as lib;

void main() {
  print(lib.L);
}
""", "lib.dart": """
class C {
  final a;
  const C(this.a);
}

const L = const {"cA": const C(const {"cB": "cC"})};
""",};