// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoAnnotationConstructorArgumentsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NoAnnotationConstructorArgumentsTest extends PubPackageResolutionTest {
  test_missingArgumentList() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}
@A
// [diag.noAnnotationConstructorArguments][column 1][length 2] Annotation creation must have arguments.
main() {
}
''');
  }
}
