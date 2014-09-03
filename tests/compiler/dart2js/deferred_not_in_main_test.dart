// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the graph segmentation algorithm used by deferred loading
// to determine which elements can be deferred and which libraries
// much be included in the initial download (loaded eagerly).

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';
import "dart:async";

import 'package:compiler/implementation/dart2jslib.dart'
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
    lookupLibrary(name) {
      return compiler.libraryLoader.lookupLibrary(Uri.parse(name));
    }

    var main = compiler.mainApp.find(dart2js.Compiler.MAIN);
    var outputUnitForElement = compiler.deferredLoadTask.outputUnitForElement;

    var mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
    var backend = compiler.backend;
    var classes = backend.emitter.neededClasses;
    var lib1 = lookupLibrary("memory:lib1.dart");
    var lib2 = lookupLibrary("memory:lib2.dart");
    var foo1 = lib1.find("foo1");
    var foo2 = lib2.find("foo2");

    var outputClassLists = backend.emitter.outputClassLists;

    Expect.notEquals(mainOutputUnit, outputUnitForElement(foo2));
  }));
}

// lib1 imports lib2 deferred. But mainlib never uses DeferredLibrary.
// Test that this case works.
const Map MEMORY_SOURCE_FILES = const {
  "main.dart":"""
library mainlib;

import 'lib1.dart' as lib1;

void main() {
  lib1.foo1();
}
""",
  "lib1.dart":"""
library lib1;

import 'lib2.dart' deferred as lib2;

const def = const DeferredLibrary('lib2');

void foo1() {
  lib1.loadLibrary().then((_) => lib2.foo2());
}
""",
  "lib2.dart":"""
library lib2;

void foo2() {}
""",
};
