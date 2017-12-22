// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that dart2js gvns dynamic getters that don't have side
// effects.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import '../compiler_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/universe/selector.dart' show Selector;
import 'package:compiler/src/world.dart';
import '../memory_compiler.dart';

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
  runTests({bool useKernel}) async {
    OutputCollector outputCollector = new OutputCollector();
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': TEST},
        outputProvider: outputCollector,
        options: useKernel ? [Flags.useKernel] : []);
    Compiler compiler = result.compiler;
    ClosedWorldBase closedWorld =
        compiler.resolutionWorldBuilder.closedWorldForTesting;
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
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}
