// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'dart:async';
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';

const String TEST_ONE = r"""
library main;

int a = 2;

class c {
  final int m;
  c(this.m);
}

void f() {
  () {} (); // TODO (sigurdm): Empty closure, hack to avoid inlining.
  a = 2;
}

main() {
  f();
  new c(2);
}
""";

main() {
  var compiler = compilerFor({'main.dart': TEST_ONE});
  asyncTest(() => compiler.runCompiler(Uri.parse('memory:main.dart')).then((_) {
    var info = compiler.dumpInfoTask.collectDumpInfo();
    var mainlib = info.libraries[0];
    Expect.stringEquals("main", mainlib.name);
    var contents = mainlib.contents;
    Expect.stringEquals("main", mainlib.name);
    Expect.stringEquals("a", contents[0].name);
    Expect.stringEquals("c", contents[1].name);
    Expect.stringEquals("f", contents[2].name);
    Expect.stringEquals("main", contents[3].name);
    Expect.stringEquals("library", mainlib.kind);
    Expect.stringEquals("field", contents[0].kind);
    Expect.stringEquals("class", contents[1].kind);
    Expect.stringEquals("function", contents[2].kind);
    Expect.stringEquals("function", contents[3].kind);
  }));
}
