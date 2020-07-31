// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/runtime_types_resolution.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/program_lookup.dart';
import '../helpers/memory_compiler.dart';

const String code = '''
class A<T> {
  final field;

  @pragma('dart2js:noInline')
  factory A.fact(t) => new A(t);

  @pragma('dart2js:noInline')
  A(t) : field = t is T;
}

// A call to A.fact.
@pragma('dart2js:noInline')
callAfact() => new A<int>.fact(0).runtimeType;

main() {
  callAfact();
}
''';

main() {
  asyncTest(() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: {'main.dart': code});
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    JsBackendStrategy backendStrategy = compiler.backendStrategy;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    RuntimeTypesNeed rtiNeed = closedWorld.rtiNeed;
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    ProgramLookup programLookup = new ProgramLookup(backendStrategy);

    js.Name getName(String name) {
      return backendStrategy.namerForTesting
          .globalPropertyNameForMember(lookupMember(elementEnvironment, name));
    }

    void checkParameters(String name,
        {int expectedParameterCount, bool needsTypeArguments}) {
      FunctionEntity function = lookupMember(elementEnvironment, name);

      Expect.equals(
          needsTypeArguments,
          rtiNeed.methodNeedsTypeArguments(function),
          "Unexpected type argument need for $function.");
      Method method = programLookup.getMethod(function);
      Expect.isNotNull(method, "No method found for $function");

      js.Fun fun = method.code;
      Expect.equals(expectedParameterCount, fun.params.length,
          "Unexpected parameter count on $function: ${js.nodeToString(fun)}");
    }

    // The declarations should have type parameters only when needed.
    checkParameters('A.fact',
        expectedParameterCount: 2, needsTypeArguments: false);
    checkParameters('A.', expectedParameterCount: 2, needsTypeArguments: false);

    checkArguments(String name, String targetName,
        {int expectedTypeArguments}) {
      FunctionEntity function = lookupMember(elementEnvironment, name);
      Method method = programLookup.getMethod(function);

      js.Fun fun = method.code;

      js.Name selector = getName(targetName);
      bool callFound = false;
      forEachNode(fun, onCall: (js.Call node) {
        js.Expression target = js.undefer(node.target);
        if (target is js.PropertyAccess) {
          js.Node targetSelector = js.undefer(target.selector);
          if (targetSelector is js.Name && targetSelector.key == selector.key) {
            callFound = true;
            Expect.equals(
                expectedTypeArguments,
                node.arguments.length,
                "Unexpected argument count in $function call to $targetName: "
                "${js.nodeToString(fun)}");
          }
        }
      });
      Expect.isTrue(
          callFound,
          "No call to $targetName in $function found: "
          "${js.nodeToString(fun)}");
    }

    // The declarations should have type parameters only when needed by the
    // selector.
    checkArguments('callAfact', 'A.fact', expectedTypeArguments: 2);
  });
}
