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

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       as dart2js;

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
    var main = compiler.mainApp.find(dart2js.Compiler.MAIN);
    var outputUnitForElement = compiler.deferredLoadTask.outputUnitForElement;

    var mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
    var classes = compiler.backend.emitter.neededClasses;
    var lib1 = compiler.libraries["memory:lib1.dart"];
    var lib2 = compiler.libraries["memory:lib2.dart"];
    var mathLib = compiler.libraries["dart:math"];
    var sin = mathLib.find('sin');
    var foo1 = lib1.find("foo1");
    var foo2 = lib2.find("foo2");

    var outputClassLists = compiler.backend.emitter.outputClassLists;

    Expect.notEquals(mainOutputUnit, outputUnitForElement(foo1));
    Expect.equals(outputUnitForElement(foo1), outputUnitForElement(sin));
  }));
}

// "lib1.dart" uses mirrors without a MirrorsUsed annotation, so everything
// should be put in the "lib1" output unit.
const Map MEMORY_SOURCE_FILES = const {
  "main.dart":"""
import "dart:async";
import "dart:math";

@def1 import 'lib1.dart' as lib1;
@def2 import 'lib2.dart' as lib2;

const def1 = const DeferredLibrary("lib1");
const def2 = const DeferredLibrary("lib2");

void main() {
  def1.load().then((_) {
    lib1.foo1();
  });
  def2.load().then((_) {
    lib2.foo2();
  });
}
""",
  "lib1.dart":"""
library lib1;
import "dart:mirrors";

const field1 = 42;

void foo1() {
  var mirror = reflect(field1);
  mirror.invoke(null, null);
}
""",
  "lib2.dart":"""
library lib2;
@MirrorsUsed(targets: "field2") import "dart:mirrors";

const field2 = 42;

void foo2() {
  var mirror = reflect(field2);
  mirror.invoke(null, null);
}
""",
};
