// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that the additional runtime type support is output to the right
// Files when using deferred loading.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';
import '../helpers/output_collector.dart';

void main() {
  runTest() async {
    OutputCollector collector = new OutputCollector();
    CompilationResult result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, outputProvider: collector);
    Compiler compiler = result.compiler;
    String mainOutput = collector.getOutput('', OutputType.js);
    String deferredOutput = collector.getOutput('out_1', OutputType.jsPart);
    JsBackendStrategy backendStrategy = compiler.backendStrategy;
    String isPrefix =
        backendStrategy.namerForTesting.fixedNames.operatorIsPrefix;
    Expect.isTrue(
        deferredOutput.contains('${isPrefix}A: 1'),
        "Deferred output doesn't contain '${isPrefix}A: 1':\n"
        "$deferredOutput");
    Expect.isFalse(mainOutput.contains('${isPrefix}A: 1'));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

// We force additional runtime type support to be output for A by instantiating
// it with a type argument, and testing for the type. The extra support should
// go to the deferred hunk.
const Map<String, String> MEMORY_SOURCE_FILES = const {
  "main.dart": """
import 'lib.dart' deferred as lib show f, A, instance;

void main() {
  lib.loadLibrary().then((_) {
    print(lib.f(lib.instance));
  });
}
""",
  "lib.dart": """
class A<T> {}

class B<T> implements A<T> {}

B<B> instance = new B<B>();

bool f (Object o) {
  return o is A<A>;
}
""",
};
