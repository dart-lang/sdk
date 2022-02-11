// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:convert';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler.dart';
import '../helpers/memory_compiler.dart';

void testLoadMap() async {
  var collector = new OutputCollector();
  await runCompiler(
      memorySourceFiles: MEMORY_SOURCE_FILES,
      options: ['--deferred-map=deferred_map.json'],
      outputProvider: collector);
  // Ensure a mapping file is output.
  var deferredMap =
      collector.getOutput("deferred_map.json", OutputType.deferredMap);
  Expect.isNotNull(deferredMap);
  var mapping = jsonDecode(deferredMap);

  // Test structure of mapping.
  Expect.equals("<unnamed>", mapping["main.dart"]["name"]);
  Expect.equals(2, mapping["main.dart"]["imports"]["lib1"].length);
  Expect.equals(2, mapping["main.dart"]["imports"]["lib2"].length);
  Expect.equals(1, mapping["main.dart"]["imports"]["convert"].length);
  Expect.equals("lib1", mapping["memory:lib1.dart"]["name"]);
  Expect.equals(1, mapping["memory:lib1.dart"]["imports"]["lib4_1"].length);
  Expect.equals(1, mapping["memory:lib2.dart"]["imports"]["lib4_2"].length);
}

void testDumpDeferredGraph() async {
  var collector = new OutputCollector();
  await runCompiler(
      memorySourceFiles: MEMORY_SOURCE_FILES,
      options: ['--dump-deferred-graph=deferred_graph.txt'],
      outputProvider: collector);
  var actual =
      collector.getOutput("deferred_graph.txt", OutputType.debug).split('\n');

  // This program has 5 deferred imports `convert`, `lib1`, `lib2`, `lib4_1`,
  // and `lib4_2`. Most are independent of one another, except for `lib1`
  // and `lib2`, that happen to both use common code (foo3 in lib3). As a
  // result we expect to have an 6 output files:
  //  * one for code that is only use by an individual deferred import, and
  //  * an extra one for the intersection of lib1 and lib2.
  var expected = ['10000', '01000', '00100', '00010', '00001', '00110'];
  expected.sort();
  actual.sort();
  Expect.listEquals(expected, actual);
}

void main() {
  asyncTest(() async {
    testLoadMap();
    testDumpDeferredGraph();
  });
}

const Map<String, String> MEMORY_SOURCE_FILES = const {
  "main.dart": """
import 'dart:convert' deferred as convert;
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
  convert.loadLibrary().then((_) {
    new convert.JsonCodec();
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
