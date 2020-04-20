// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/program_lookup.dart';
import '../helpers/memory_compiler.dart';

const String code = '''
// This needs one-arg instantiation.
@pragma('dart2js:noInline')
T f1a<T>(T t) => t;

// This needs no instantiation because it is not closurized.
@pragma('dart2js:noInline')
T f1b<T>(T t1, T t2) => t1;

class Class {
  // This needs two-arg instantiation.
  @pragma('dart2js:noInline')
  bool f2a<T, S>(T t, S s) => t == s;

  // This needs no instantiation because it is not closurized.
  @pragma('dart2js:noInline')
  bool f2b<T, S>(T t, S s1, S s2) => t == s1;
}

@pragma('dart2js:noInline')
int method1(int i, int Function(int) f) => f(i);

@pragma('dart2js:noInline')
bool method2(int a, int b, bool Function(int, int) f) => f(a, b);

@pragma('dart2js:noInline')
int method3(int a, int b, int c, int Function(int, int, int) f) => f(a, b, c);

main() {
  // This needs three-arg instantiation.
  T local1<T, S, U>(T t, S s, U u) => t;

  // This needs no instantiation because but a local function is always
  // closurized so we assume it does.
  T local2<T, S, U>(T t, S s, U u1, U u2) => t;

  print(method1(42, f1a));
  print(f1b(42, 87));

  Class c = new Class();
  print(method2(0, 1, c.f2a));
  print(c.f2b(42, 87, 123));

  print(method3(0, 1, 2, local1));
  print(local2(42, 87, 123, 256));
}
''';

main() {
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': code},
        options: [Flags.omitImplicitChecks]);
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    ProgramLookup programLookup = new ProgramLookup(compiler.backendStrategy);

    void checkStubs(ClassEntity element, List<String> expectedStubs) {
      Class cls = programLookup.getClass(element);
      List<String> actualStubs = <String>[];
      if (cls != null) {
        for (StubMethod stub in cls.callStubs) {
          actualStubs.add(stub.name.key);
        }
      }
      Expect.setEquals(
          expectedStubs,
          actualStubs,
          "Unexpected stubs for $element:\n "
          "Expected: $expectedStubs\n Actual: $actualStubs");
    }

    checkStubs(closedWorld.commonElements.getInstantiationClass(1),
        [r'call$1', r'$signature']);
    checkStubs(closedWorld.commonElements.getInstantiationClass(2),
        [r'call$2', r'$signature']);
    checkStubs(closedWorld.commonElements.getInstantiationClass(3),
        [r'call$3', r'call$4', r'$signature']);
  });
}
