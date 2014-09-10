// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the graph segmentation algorithm used by deferred loading
// to determine which elements can be deferred and which libraries
// much be included in the initial download (loaded eagerly).

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';
import "dart:async";

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
    var mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
    var lib =
        compiler.libraryLoader.lookupLibrary(Uri.parse("memory:lib.dart"));
    var f1 = lib.find("f1");
    var f2 = lib.find("f2");
    Expect.notEquals(mainOutputUnit, outputUnitForElement(f1));
    Expect.equals(mainOutputUnit, outputUnitForElement(f2));
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
import "dart:async";

import 'lib.dart' deferred as lib show f1;
import 'lib.dart' show f2;

void main() {
  print(f2());
  lib.loadLibrary().then((_) {
    print(lib.f1());
  });
}
""", "lib.dart": """
int f1 () {
  return 1;
}

int f2 () {
  return 2;
}
""",};
