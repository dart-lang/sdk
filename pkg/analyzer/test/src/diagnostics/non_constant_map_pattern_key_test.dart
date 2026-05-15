// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapPatternKeyTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantMapPatternKeyTest extends PubPackageResolutionTest {
  test_formalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x, int a) {
  if (x case {a: 0}) {}
//            ^
// [diag.nonConstantMapPatternKey] Key expressions in map patterns must be constants.
}
''');
  }

  test_instanceCreation_noConst() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {A(): 0}) {}
//            ^^^
// [diag.nonConstantMapPatternKey] Key expressions in map patterns must be constants.
}

class A {
  const A();
}
''');
  }

  test_integerLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {0: 1}) {}
}
''');
  }
}
