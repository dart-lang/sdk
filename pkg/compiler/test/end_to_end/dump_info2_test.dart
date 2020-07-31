// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:convert';

import 'package:compiler/compiler_new.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';
import 'package:dart2js_info/binary_serialization.dart' as binary;
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

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

typedef InfoCheck = void Function(AllInfo);

infoTest(String program, bool useBinary, InfoCheck check) async {
  var options = ['--out=out.js', Flags.dumpInfo];
  // Note: we always pass '--dump-info' because the memory-compiler does not
  // have the logic in dart2js.dart to imply dump-info when --dump-info=binary
  // is provided.
  if (useBinary) options.add("${Flags.dumpInfo}=binary");
  var collector = new OutputCollector();
  var result = await runCompiler(
      memorySourceFiles: {'main.dart': program},
      options: options,
      outputProvider: collector);
  var compiler = result.compiler;
  Expect.isFalse(compiler.compilationFailed);
  AllInfo info;
  if (useBinary) {
    var sink = collector.binaryOutputMap[Uri.parse('out.js.info.data')];
    info = binary.decode(sink.list);
  } else {
    info = new AllInfoJsonCodec().decode(
        json.decode(collector.getOutput("out.js", OutputType.dumpInfo)));
  }
  check(info);
}

main() {
  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests(useBinary: false);
    await runTests(useBinary: true);
  });
}

runTests({bool useBinary: false}) async {
  await infoTest(TEST_BASIC, useBinary, (info) {
    Expect.isTrue(info.functions.isNotEmpty);
    Expect.isTrue(info.libraries.isNotEmpty);
    Expect.isTrue(info.libraries.any((lib) => lib.name == "main"));
    Expect.isTrue(info.classes.any((c) => c.name == 'c'));
    Expect.isTrue(info.functions.any((f) => f.name == 'f'));
  });

  await infoTest(TEST_CLOSURES, useBinary, (info) {
    Expect.isTrue(info.functions.any((fn) {
      return fn.name == 'bar' && fn.closures.length == 11;
    }));
    Expect.isTrue(info.functions.any((fn) {
      return fn.name == 'foo' && fn.closures.length == 10;
    }));
  });

  await infoTest(TEST_STATICS, useBinary, (info) {
    Expect.isTrue(info.functions.any((fn) => fn.name == 'does_something'));
    Expect.isTrue(info.classes.any((cls) {
      return cls.name == 'ContainsStatics' && cls.functions.length >= 1;
    }));
  });

  await infoTest(TEST_INLINED_1, useBinary, (info) {
    Expect.isTrue(info.functions.any((fn) {
      return fn.name == 'double' && fn.inlinedCount == 1;
    }));
    Expect.isTrue(info.classes.any((cls) {
      return cls.name == 'Doubler' && cls.functions.length >= 1;
    }));
  });

  await infoTest(TEST_INLINED_2, useBinary, (info) {
    var main_ = info.functions.firstWhere((v) => v.name == 'main');
    var fn1 = info.functions.firstWhere((v) => v.name == 'funcA');
    var fn2 = info.functions.firstWhere((v) => v.name == 'funcB');
    Expect.isTrue(main_ != null);
    Expect.isTrue(fn1 != null);
    Expect.isTrue(fn2 != null);
    Expect.isTrue(main_.uses.any((dep) => dep.target == fn1));
    Expect.isTrue(fn1.uses.any((dep) => dep.target == fn2));
  });
}
