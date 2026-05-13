// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BinaryOperatorWrittenOutTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BinaryOperatorWrittenOutTest extends PubPackageResolutionTest {
  test_using_and() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x, y) {
  return x and y;
//         ^^^
// [diag.binaryOperatorWrittenOut] Binary operator 'and' is written as '&' instead of the written out word.
}
''');
  }

  test_using_and_no_error() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x, y) {
  return x & y;
}
''');
  }

  test_using_or() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x, y) {
  return x or y;
//         ^^
// [diag.binaryOperatorWrittenOut] Binary operator 'or' is written as '|' instead of the written out word.
}
''');
  }

  test_using_or_no_error() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x, y) {
  return x | y;
}
''');
  }

  test_using_shl() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x) {
  return x shl 2;
//         ^^^
// [diag.binaryOperatorWrittenOut] Binary operator 'shl' is written as '<<' instead of the written out word.
}
''');
  }

  test_using_shl_no_error() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x) {
  return x << 2;
}
''');
  }

  test_using_shr() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x) {
  return x shr 2;
//         ^^^
// [diag.binaryOperatorWrittenOut] Binary operator 'shr' is written as '>>' instead of the written out word.
}
''');
  }

  test_using_shr_no_error() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x) {
  return x >> 2;
}
''');
  }

  test_using_xor() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x, y) {
  return x xor y;
//         ^^^
// [diag.binaryOperatorWrittenOut] Binary operator 'xor' is written as '^' instead of the written out word.
}
''');
  }

  test_using_xor_no_error() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x, y) {
  return x ^ y;
}
''');
  }
}
