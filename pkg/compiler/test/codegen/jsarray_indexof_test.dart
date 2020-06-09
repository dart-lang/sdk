// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that `length` access in JSArray.indexOf is encoding using `.length` and
// not `.get$length()`.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/world.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/universe/selector.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';
import '../helpers/element_lookup.dart';
import '../helpers/program_lookup.dart';

const String source = '''
import 'package:expect/expect.dart';

@pragma('dart2js:noInline')
test(o, a) => o.indexOf(a);
main() {
  test([1, 2, 3], 2);
  test(['1', '2', '3'], '2');
}
''';

main() {
  asyncTest(() async {
    print('--test from kernel (strong mode)----------------------------------');
    await runTest([]);
    print('--test from kernel (strong mode, omit-implicit-checks)------------');
    await runTest([Flags.omitImplicitChecks]);
  });
}

runTest(List<String> options) async {
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': source}, options: options);
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  JsBackendStrategy backendStrategy = compiler.backendStrategy;
  JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
  MemberEntity jsArrayIndexOf =
      findClassMember(closedWorld, 'JSArray', 'indexOf');
  ProgramLookup programLookup = new ProgramLookup(backendStrategy);

  Selector getLengthSelector = new Selector.getter(const PublicName('length'));
  js.Name getLengthName =
      backendStrategy.namerForTesting.invocationName(getLengthSelector);

  Method method = programLookup.getMethod(jsArrayIndexOf);
  int lengthCount = 0;
  forEachNode(method.code, onCall: (js.Call node) {
    js.Node target = node.target;
    Expect.isFalse(
        target is js.PropertyAccess && target.selector == getLengthName,
        "Unexpected .get\$length access ${js.nodeToString(node)} in\n"
        "${js.nodeToString(method.code, pretty: true)}");
  }, onPropertyAccess: (js.PropertyAccess node) {
    js.Node selector = node.selector;
    if (selector is js.LiteralString && selector.value == '"length"') {
      lengthCount++;
    }
  });
  Expect.equals(
      2,
      lengthCount,
      "Unexpected .length access in\n"
      "${js.nodeToString(method.code, pretty: true)}");
}
