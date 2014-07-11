// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';
import 'package:compiler/implementation/dump_info.dart';
import 'dart:convert';

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
    var dumpTask = compiler.dumpInfoTask;
    dumpTask.collectInfo();
    var info = dumpTask.infoCollector;

    StringBuffer sb = new StringBuffer();
    dumpTask.dumpInfoJson(sb);
    String json = sb.toString();
    Map<String, dynamic> map = JSON.decode(json);
    Expect.isTrue(map.isNotEmpty);
    Expect.isTrue(map['elements'].isNotEmpty);
    Expect.isTrue(map['elements']['function'].isNotEmpty);
    Expect.isTrue(map['elements']['library'].isNotEmpty);

    Expect.isTrue(map['elements']['library'].values.any((lib) {
      return lib['name'] == "main";
    }));
    Expect.isTrue(map['elements']['class'].values.any((clazz) {
      return clazz['name'] == "c";
    }));
    Expect.isTrue(map['elements']['function'].values.any((fun) {
      return fun['name'] == 'f';
    }));
  }));
}
