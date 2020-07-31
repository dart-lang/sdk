// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/codegen_world_builder.dart';
import 'package:expect/expect.dart';

import '../helpers/memory_compiler.dart';

const String code = r'''
class Class1 {
  @pragma('dart2js:noInline')
  method1<T>() {}

  @pragma('dart2js:noInline')
  method2<T>() => T;

  @pragma('dart2js:noInline')
  method3<T>() => T;

  @pragma('dart2js:noInline')
  method4<T>() => T;

  @pragma('dart2js:noInline')
  method5<T>() => T;

  @pragma('dart2js:noInline')
  method6<T>() {}
}

class Class2 {}

class Class3 implements Class1 {
  @pragma('dart2js:noInline')
  method1<T>() {}

  @pragma('dart2js:noInline')
  method2<T>() {}

  @pragma('dart2js:noInline')
  method3<T>() {}

  @pragma('dart2js:noInline')
  method4<T>() {}

  @pragma('dart2js:noInline')
  method5<T>() {}

  @pragma('dart2js:noInline')
  method6<T>() {}
}

main(args) {
  dynamic c1 = args != null ? new Class1() : new Class2();
  c1.method1(); // No type arguments are inferred here.

  dynamic c2 = args != null ? new Class1() : new Class2();
  c2.method2<int>();

  var c3 = args != null ? new Class1() : new Class3();
  c3.method3(); // Type arguments are inferred here.

  var c4 = args != null ? new Class1() : new Class3();
  c4.method4<int>();

  dynamic c5 = args != null ? new Class1() : new Class2();
  c5.method5(); // No type arguments are inferred here.

  var c6 = args != null ? new Class1() : new Class3();
  c6.method5();  // Type arguments are inferred here.

  dynamic c7 = args != null ? new Class1() : new Class2();
  c7.method6<int>(); // Type arguments are not needed.

  var c8 = args != null ? new Class1() : new Class3();
  c8.method6(); // Type arguments are inferred here but not needed.
}
''';

main() {
  asyncTest(() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: {'main.dart': code});
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    CodegenWorld codegenWorld = compiler.codegenWorldForTesting;

    CallStructure noTypeArguments = new CallStructure(0, [], 0);
    CallStructure oneTypeArgument = new CallStructure(0, [], 1);

    Iterable<CallStructure> getCallStructures(String name) {
      return codegenWorld
              .invocationsByName(name)
              ?.keys
              ?.map((s) => s.callStructure) ??
          [];
    }

    void checkInvocationsFor(
        String methodName, List<CallStructure> expectedCallStructures) {
      Iterable<CallStructure> actualCallStructures =
          getCallStructures(methodName);
      Expect.setEquals(
          expectedCallStructures,
          actualCallStructures,
          "Unexpected call structures for '$methodName'. "
          "Expected ${expectedCallStructures}, "
          "actual ${actualCallStructures}.");
    }

    checkInvocationsFor('method1', [noTypeArguments]);
    checkInvocationsFor('method2', [oneTypeArgument]);
    checkInvocationsFor('method3', [oneTypeArgument]);
    checkInvocationsFor('method4', [oneTypeArgument]);
    checkInvocationsFor('method5', [noTypeArguments, oneTypeArgument]);
    checkInvocationsFor('method6', [noTypeArguments]);
  });
}
