// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BinaryOperatorWrittenOutTest);
  });
}

@reflectiveTest
class BinaryOperatorWrittenOutTest extends PubPackageResolutionTest {
  test_using_and() async {
    await assertErrorsInCode(
      r'''
f(x, y) {
  return x and y;
}
''',
      [error(diag.binaryOperatorWrittenOut, 21, 3)],
    );
  }

  test_using_and_no_error() async {
    await assertNoErrorsInCode(r'''
f(x, y) {
  return x & y;
}
''');
  }

  test_using_or() async {
    await assertErrorsInCode(
      r'''
f(x, y) {
  return x or y;
}
''',
      [error(diag.binaryOperatorWrittenOut, 21, 2)],
    );
  }

  test_using_or_no_error() async {
    await assertNoErrorsInCode(r'''
f(x, y) {
  return x | y;
}
''');
  }

  test_using_shl() async {
    await assertErrorsInCode(
      r'''
f(x) {
  return x shl 2;
}
''',
      [error(diag.binaryOperatorWrittenOut, 18, 3)],
    );
  }

  test_using_shl_no_error() async {
    await assertNoErrorsInCode(r'''
f(x) {
  return x << 2;
}
''');
  }

  test_using_shr() async {
    await assertErrorsInCode(
      r'''
f(x) {
  return x shr 2;
}
''',
      [error(diag.binaryOperatorWrittenOut, 18, 3)],
    );
  }

  test_using_shr_no_error() async {
    await assertNoErrorsInCode(r'''
f(x) {
  return x >> 2;
}
''');
  }

  test_using_xor() async {
    await assertErrorsInCode(
      r'''
f(x, y) {
  return x xor y;
}
''',
      [error(diag.binaryOperatorWrittenOut, 21, 3)],
    );
  }

  test_using_xor_no_error() async {
    await assertNoErrorsInCode(r'''
f(x, y) {
  return x ^ y;
}
''');
  }
}
