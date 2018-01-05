// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Port this test to use the equivalence framework.

// Test that a non-used generative constructor does not prevent
// inferring types for fields.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import 'type_mask_test_helper.dart';
import '../memory_compiler.dart';

const String TEST = """

class A {
  final intField;
  final stringField;
  A() : intField = 42, stringField = 'foo';
  A.bar() : intField = 'bar', stringField = 42;
}

main() {
  new A();
}
""";

void main() {
  runTest({bool useKernel}) async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': TEST},
        options: useKernel ? [Flags.useKernel] : []);
    Expect.isTrue(result.isSuccess);
    var compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;

    checkFieldTypeInClass(String className, String fieldName, type) {
      var element = findClassMember(closedWorld, className, fieldName);
      Expect.isTrue(typesInferrer.getTypeOfMember(element).containsOnly(type));
    }

    checkFieldTypeInClass('A', 'intField',
        typesInferrer.closedWorld.commonElements.jsUInt31Class);
    checkFieldTypeInClass('A', 'stringField',
        typesInferrer.closedWorld.commonElements.jsStringClass);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
