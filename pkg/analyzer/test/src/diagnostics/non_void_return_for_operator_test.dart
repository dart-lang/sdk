// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonVoidReturnForOperatorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonVoidReturnForOperatorTest extends PubPackageResolutionTest {
  test_indexSetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int operator []=(a, b) { return a; }
//^^^
// [diag.nonVoidReturnForOperator] The return type of the operator []= must be 'void'.
}''');
  }

  test_no_return() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator []=(a, b) {}
}
''');
  }

  test_void() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void operator []=(a, b) {}
}
''');
  }
}
