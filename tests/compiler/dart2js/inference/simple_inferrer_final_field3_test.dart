// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Port this test to use the equivalence framework.

// Test that we are analyzing field parameters correctly.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import 'type_mask_test_helper.dart';
import '../memory_compiler.dart';

const String TEST = """

class A {
  final dynamicField;
  A() : dynamicField = 42;
  A.bar(this.dynamicField);
}

main() {
  new A();
  new A.bar('foo');
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
      Expect.equals(
          type, simplify(typesInferrer.getTypeOfMember(element), closedWorld));
    }

    checkFieldTypeInClass(
        'A', 'dynamicField', interceptorOrComparable(closedWorld));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
