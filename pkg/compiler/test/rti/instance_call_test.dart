// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/js_backend/runtime_types_resolution.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/world.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:expect/expect.dart';
import '../helpers/program_lookup.dart';
import '../helpers/memory_compiler.dart';

const String code = '''
class A {
  // Both method1 implementations need type arguments.
  @pragma('dart2js:noInline')
  method1<T>(T t) => t is T;

  // One of the method2 implementations need type arguments.
  @pragma('dart2js:noInline')
  method2<T>(T t) => t is T;

  // None of the method3 implementations need type arguments.
  @pragma('dart2js:noInline')
  method3<T>(T t) => false;
}

class B {
  @pragma('dart2js:noInline')
  method1<T>(T t) => t is T;
  @pragma('dart2js:noInline')
  method2<T>(T t) => true;
  @pragma('dart2js:noInline')
  method3<T>(T t) => true;
}

// A call to either A.method1 or B.method1.
@pragma('dart2js:noInline')
call1(c) => c.method1<int>(0);

// A call to A.method1.
@pragma('dart2js:noInline')
call1a() => new A().method1<int>(0);

// A call to B.method1.
@pragma('dart2js:noInline')
call1b() => new B().method1<int>(0);

// A call to either A.method2 or B.method2.
@pragma('dart2js:noInline')
call2(c) => c.method2<int>(0);

// A call to A.method2.
@pragma('dart2js:noInline')
call2a() => new A().method2<int>(0);

// A call to B.method2.
@pragma('dart2js:noInline')
call2b() => new B().method2<int>(0);

// A call to either A.method3 or B.method3.
@pragma('dart2js:noInline')
call3(c) => c.method3<int>(0);

// A call to A.method3.
@pragma('dart2js:noInline')
call3a() => new A().method3<int>(0);

// A call to B.method3.
@pragma('dart2js:noInline')
call3b() => new B().method3<int>(0);

main() {
  call1(new A());
  call1(new B());
  call1a();
  call1b();
  call2(new A());
  call2(new B());
  call2a();
  call2b();
  call3(new A());
  call3(new B());
  call3a();
  call3b();
}
''';

main() {
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': code},
        options: [Flags.omitImplicitChecks]);
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    JsBackendStrategy backendStrategy = compiler.backendStrategy;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    RuntimeTypesNeed rtiNeed = closedWorld.rtiNeed;
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    ProgramLookup programLookup = new ProgramLookup(backendStrategy);

    js.Name getName(String name, int typeArguments) {
      return backendStrategy.namerForTesting.invocationName(new Selector.call(
          new PublicName(name),
          new CallStructure(1, const <String>[], typeArguments)));
    }

    void checkParameters(String name,
        {int expectedParameterCount, bool needsTypeArguments}) {
      FunctionEntity function = lookupMember(elementEnvironment, name);

      Expect.equals(
          needsTypeArguments,
          rtiNeed.methodNeedsTypeArguments(function),
          "Unexpected type argument need for $function.");
      Method method = programLookup.getMethod(function);

      js.Fun fun = method.code;
      Expect.equals(expectedParameterCount, fun.params.length,
          "Unexpected parameter count on $function: ${js.nodeToString(fun)}");
    }

    // The declarations should have type parameters only when needed.
    checkParameters('A.method1',
        expectedParameterCount: 2, needsTypeArguments: true);
    checkParameters('B.method1',
        expectedParameterCount: 2, needsTypeArguments: true);
    checkParameters('A.method2',
        expectedParameterCount: 2, needsTypeArguments: true);
    checkParameters('B.method2',
        expectedParameterCount: 1, needsTypeArguments: false);
    checkParameters('A.method3',
        expectedParameterCount: 1, needsTypeArguments: false);
    checkParameters('B.method3',
        expectedParameterCount: 1, needsTypeArguments: false);

    checkArguments(String name, String targetName,
        {int expectedTypeArguments}) {
      FunctionEntity function = lookupMember(elementEnvironment, name);
      Method method = programLookup.getMethod(function);

      js.Fun fun = method.code;

      js.Name selector = getName(targetName, expectedTypeArguments);
      bool callFound = false;
      forEachNode(fun, onCall: (js.Call node) {
        js.Expression target = js.undefer(node.target);
        if (target is js.PropertyAccess) {
          js.Node targetSelector = js.undefer(target.selector);
          if (targetSelector is js.Name && targetSelector.key == selector.key) {
            callFound = true;
            Expect.equals(
                1 + expectedTypeArguments,
                node.arguments.length,
                "Unexpected argument count in $function call to $targetName: "
                "${js.nodeToString(fun)}");
          }
        }
      });
      Expect.isTrue(callFound,
          "No call to $targetName as '${selector.key}' in $function found.");
    }

    // The declarations should have type parameters only when needed by the
    // selector.
    checkArguments('call1', 'method1', expectedTypeArguments: 1);
    checkArguments('call1a', 'method1', expectedTypeArguments: 1);
    checkArguments('call1b', 'method1', expectedTypeArguments: 1);
    checkArguments('call2', 'method2', expectedTypeArguments: 1);
    checkArguments('call2a', 'method2', expectedTypeArguments: 1);
    checkArguments('call2b', 'method2', expectedTypeArguments: 1);
    checkArguments('call3', 'method3', expectedTypeArguments: 0);
    checkArguments('call3a', 'method3', expectedTypeArguments: 0);
    checkArguments('call3b', 'method3', expectedTypeArguments: 0);
  });
}
