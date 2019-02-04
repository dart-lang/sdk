// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that dart2js gvns dynamic getters that don't have side
// effects.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/universe/selector.dart' show Selector;
import 'package:compiler/src/js_model/js_world.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';
import '../helpers/memory_compiler.dart';

const String TEST = r"""
class A {
  var foo;
  bar(a) {
    return a.foo + a.foo;
  }
}

main() {
  new A().bar(new Object());
}
""";

main() {
  runTests() async {
    OutputCollector outputCollector = new OutputCollector();
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': TEST},
        outputProvider: outputCollector);
    Compiler compiler = result.compiler;
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    var elementEnvironment = closedWorld.elementEnvironment;

    String generated = outputCollector.getOutput('', OutputType.js);
    RegExp regexp = new RegExp(r"get\$foo");
    Iterator matches = regexp.allMatches(generated).iterator;
    checkNumberOfMatches(matches, 1);
    dynamic cls =
        elementEnvironment.lookupClass(elementEnvironment.mainLibrary, 'A');
    Expect.isNotNull(cls);
    String name = 'foo';
    var element = elementEnvironment.lookupClassMember(cls, name);
    Expect.isNotNull(element);
    Selector selector = new Selector.getter(new PublicName(name));
    Expect.isFalse(closedWorld.hasAnyUserDefinedGetter(selector, null));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
