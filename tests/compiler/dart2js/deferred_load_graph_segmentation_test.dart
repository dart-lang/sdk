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
    var main = compiler.mainApp.find(dart2js.Compiler.MAIN);
    Expect.isNotNull(main, "Could not find 'main'");
    compiler.deferredLoadTask.onResolutionComplete(main);

    var outputUnitForElement = compiler.deferredLoadTask.outputUnitForElement;

    var mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
    var backend = compiler.backend;
    var classes = backend.emitter.neededClasses;
    var inputElement = classes.where((e) => e.name == 'InputElement').single;
    var lib1 = compiler.libraries["memory:lib1.dart"];
    var foo1 = lib1.find("foo1");
    var lib2 = compiler.libraries["memory:lib2.dart"];
    var foo2 = lib2.find("foo2");
    var lib3 = compiler.libraries["memory:lib3.dart"];
    var foo3 = lib3.find("foo3");
    var lib4 = compiler.libraries["memory:lib4.dart"];
    var bar1 = lib4.find("bar1");
    var bar2 = lib4.find("bar2");
    var outputClassLists = backend.emitter.outputClassLists;

    Expect.equals(mainOutputUnit, outputUnitForElement(main));
    Expect.notEquals(mainOutputUnit, outputUnitForElement(foo1));
    Expect.notEquals(outputUnitForElement(foo1), outputUnitForElement(foo3));
    Expect.notEquals(outputUnitForElement(foo2), outputUnitForElement(foo3));
    Expect.notEquals(outputUnitForElement(foo1), outputUnitForElement(foo2));
    Expect.notEquals(outputUnitForElement(bar1), outputUnitForElement(bar2));
    // InputElement is native, so it should not appear on a classList
    Expect.isFalse(outputClassLists[outputUnitForElement(inputElement)]
        .contains(inputElement));

    var hunksToLoad = compiler.deferredLoadTask.hunksToLoad;

    mapToNames(id) {
      return hunksToLoad[id].map((l) {
        return new Set.from(l.map((o) => o.name));
      }).toList();
    }

    var hunksLib1 = mapToNames("lib1");
    var hunksLib2 = mapToNames("lib2");
    var hunksLib4_1 = mapToNames("lib4_1");
    var hunksLib4_2 = mapToNames("lib4_2");
    Expect.equals(hunksLib1.length, 2);
    Expect.equals(hunksLib1[0].length, 1);
    Expect.equals(hunksLib1[1].length, 1);
    Expect.isTrue(hunksLib1[0].contains("lib1_lib2") ||
                  hunksLib1[0].contains("lib2_lib1"));
    Expect.isTrue(hunksLib1[1].contains("lib1"));
    Expect.equals(hunksLib2.length, 2);
    Expect.equals(hunksLib2[0].length, 1);
    Expect.equals(hunksLib2[1].length, 1);
    Expect.isTrue(hunksLib2[0].contains("lib1_lib2") ||
                  hunksLib2[0].contains("lib2_lib1"));
    Expect.isTrue(hunksLib2[1].contains("lib2"));
    Expect.equals(hunksLib4_1.length, 1);
    Expect.equals(hunksLib4_1[0].length, 1);
    Expect.isTrue(hunksLib4_1[0].contains("lib4_1"));
    Expect.equals(hunksLib4_2.length, 1);
    Expect.equals(hunksLib4_2[0].length, 1);
    Expect.isTrue(hunksLib4_2[0].contains("lib4_2"));
    Expect.equals(hunksToLoad["main"], null);
  }));
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
const Map MEMORY_SOURCE_FILES = const {
  "main.dart":"""
import "dart:async";
@def_main_1 import 'lib1.dart' as l1;
@def_main_2 import 'lib2.dart' as l2;

const def_main_1 = const DeferredLibrary("lib1");
const def_main_2 = const DeferredLibrary("lib2");

void main() {
  def_main_1.load().then((_) {
        l1.foo1();
        new l1.C();
    def_main_2.load().then((_) {
        l2.foo2();
    });
  });
}
""",
  "lib1.dart":"""
library lib1;
import "dart:async";
import "dart:html";

import "lib3.dart" as l3;
@def_1_1 import "lib4.dart" as l4;

const def_1_1 = const DeferredLibrary("lib4_1");

class C {}

foo1() {
  new InputElement();
  def_1_1.load().then((_) {
    l4.bar1();
  });
  return () {return 1 + l3.foo3();} ();
}
""",
  "lib2.dart":"""
library lib2;
import "dart:async";
import "lib3.dart" as l3;
@def_2_1 import "lib4.dart" as l4;

const def_2_1 = const DeferredLibrary("lib4_2");

foo2() {
  def_2_1.load().then((_) {
    l4.bar2();
  });
  return () {return 2+l3.foo3();} ();
}
""",
  "lib3.dart":"""
library lib3;

foo3() {
  return () {return 3;} ();
}
""",
  "lib4.dart":"""
library lib4;

bar1() {
  return "hello";
}

bar2() {
  return 2;
}
""",
};
