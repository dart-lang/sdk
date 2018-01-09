// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'dart:convert';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

const String TEST_BASIC = r"""
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
  static final p = 20;
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

const String TEST_CLOSURES = r"""
main() {
  print(bar);
  print(bar());
  print(new X().foo);
  print(new X().foo());
}

bar() => [() => [() => [() => [() => [() => [() => [() => [() => [() => [() =>
[() => []]]]]]]]]]]];

class X {
  foo() => [() => [() => [() => [() => [() => [() => [() => [() => [() =>
[() => []]]]]]]]]]];
}
""";

const String TEST_STATICS = r"""
class ContainsStatics {
  static int does_something() {
    try {
      print('hello');
      return 1;
    } finally {
      print('world');
      return 2;
    }
  }
}

void main() {
  print(ContainsStatics.does_something());
}
""";

const String TEST_INLINED_1 = r"""
class Doubler {
  int double(int x) {
    return x + 2;
  }
}
void main() {
  var f = new Doubler();
  print(f.double(4));
}
""";

const String TEST_INLINED_2 = r"""
  funcA() => funcB();
  funcB() => print("hello");
   main() => funcA();
""";

typedef void JsonTaking(Map<String, dynamic> json);

jsonTest(String program, JsonTaking testFn, {bool useKernel}) async {
  var options = ['--out=out.js', Flags.dumpInfo];
  if (useKernel) {
    options.add(Flags.useKernel);
  }
  var result = await runCompiler(
      memorySourceFiles: {'main.dart': program}, options: options);
  var compiler = result.compiler;
  Expect.isFalse(compiler.compilationFailed);
  var dumpTask = compiler.dumpInfoTask;

  StringBuffer sb = new StringBuffer();
  dumpTask.dumpInfoJson(sb, compiler.backendClosedWorldForTesting);
  String jsonString = sb.toString();
  Map<String, dynamic> map = json.decode(jsonString);

  testFn(map);
}

main() {
  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}

runTests({bool useKernel}) async {
  await jsonTest(TEST_BASIC, (map) {
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
  }, useKernel: useKernel);

  await jsonTest(TEST_CLOSURES, (map) {
    var functions = map['elements']['function'].values;
    Expect.isTrue(functions.any((fn) {
      return fn['name'] == 'bar' && fn['children'].length == 11;
    }));
    Expect.isTrue(functions.any((fn) {
      return fn['name'] == 'foo' && fn['children'].length == 10;
    }));
  }, useKernel: useKernel);

  await jsonTest(TEST_STATICS, (map) {
    var functions = map['elements']['function'].values;
    var classes = map['elements']['class'].values;
    Expect.isTrue(functions.any((fn) {
      return fn['name'] == 'does_something';
    }));
    Expect.isTrue(classes.any((cls) {
      return cls['name'] == 'ContainsStatics' && cls['children'].length >= 1;
    }));
  }, useKernel: useKernel);

  await jsonTest(TEST_INLINED_1, (map) {
    var functions = map['elements']['function'].values;
    var classes = map['elements']['class'].values;
    Expect.isTrue(functions.any((fn) {
      return fn['name'] == 'double' && fn['inlinedCount'] == 1;
    }));
    Expect.isTrue(classes.any((cls) {
      return cls['name'] == 'Doubler' && cls['children'].length >= 1;
    }));
  }, useKernel: useKernel);

  await jsonTest(TEST_INLINED_2, (map) {
    var functions = map['elements']['function'].values;
    var deps = map['holding'];
    var main_ = functions.firstWhere((v) => v['name'] == 'main');
    var fn1 = functions.firstWhere((v) => v['name'] == 'funcA');
    var fn2 = functions.firstWhere((v) => v['name'] == 'funcB');
    Expect.isTrue(main_ != null);
    Expect.isTrue(fn1 != null);
    Expect.isTrue(fn2 != null);
    Expect.isTrue(deps.containsKey(main_['id']));
    Expect.isTrue(deps.containsKey(fn1['id']));
    Expect.isTrue(deps.containsKey(fn2['id']));
    Expect.isTrue(deps[main_['id']].any((dep) => dep['id'] == fn1['id']));
    Expect.isTrue(deps[fn1['id']].any((dep) => dep['id'] == fn2['id']));
  }, useKernel: useKernel);
}
