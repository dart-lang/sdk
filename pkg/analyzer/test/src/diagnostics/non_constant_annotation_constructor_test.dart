// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantAnnotationConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantAnnotationConstructorTest extends PubPackageResolutionTest {
  test_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.fromInt() {}
}
@A.fromInt()
// [diag.nonConstantAnnotationConstructor][column 1][length 12] Annotation creation can only call a const constructor.
main() {
}
''');
  }

  test_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
}
@A()
// [diag.nonConstantAnnotationConstructor][column 1][length 4] Annotation creation can only call a const constructor.
main() {
}
''');
  }
}
