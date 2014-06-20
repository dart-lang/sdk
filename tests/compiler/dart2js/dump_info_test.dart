// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';
import 'package:compiler/implementation/dump_info.dart';

const String TEST_ONE = r"""
library main;

int a = 2;

class c {
  final int m;
  c(this.m) {
    () {} ();  // TODO (sigurdm): Empty closure, hack to avoid inlining.
    a = 1;
  }
  foo() {
    () {} ();
    k = 2;
    print(k);
    print(p);
  }
  var k = (() => 10)();
  final static p = 20;
}

void f() {
  () {} ();
  a = 3;
}

main() {
  print(a);
  f();
  print(new c(2).foo());
}
""";

main() {
  var compiler = compilerFor({'main.dart': TEST_ONE}, options: ["--dump-info"]);
  asyncTest(() => compiler.runCompiler(Uri.parse('memory:main.dart')).then((_) {
    var visitor = compiler.dumpInfoTask.infoDumpVisitor;
    var info = visitor.collectDumpInfo();
    var mainlib = info.libraries[0];
    Expect.stringEquals("main", mainlib.name);
    List contents = mainlib.contents;
    Expect.stringEquals("main", mainlib.name);
    print(mainlib.contents.map((e)=> e.name));
    var a = contents.singleWhere((e) => e.name == "a");
    var c = contents.singleWhere((e) => e.name == "c");
    var f = contents.singleWhere((e) => e.name == "f");
    var main = contents.singleWhere((e) => e.name == "main");
    Expect.stringEquals("library", mainlib.kind);
    Expect.stringEquals("field", a.kind);
    Expect.stringEquals("class", c.kind);
    var constructor = c.contents.singleWhere((e) => e.name == "c");
    Expect.stringEquals("constructor", constructor.kind);
    var method = c.contents.singleWhere((e) => e.name == "foo");
    Expect.stringEquals("method", method.kind);
    var field = c.contents.singleWhere((e) => e.name == "m");
    Expect.stringEquals("field", field.kind);
    Expect.stringEquals("function", f.kind);
    Expect.stringEquals("function", main.kind);
  }));
}
