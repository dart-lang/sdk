// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantSetElementTest);
  });
}

@reflectiveTest
class NonConstantSetElementTest extends PubPackageResolutionTest
    with NonConstantSetElementTestCases {}

mixin NonConstantSetElementTestCases on PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_finalElse() async {
    await assertErrorsInCode(
      '''
final dynamic a = 0;
var v = const <int>{if (1 < 0) 0 else a};
''',
      [error(CompileTimeErrorCode.nonConstantSetElement, 59, 1)],
    );
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await assertErrorsInCode(
      '''
final dynamic a = 0;
var v = const <int>{if (1 < 0) a else 0};
''',
      [error(CompileTimeErrorCode.nonConstantSetElement, 52, 1)],
    );
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await assertErrorsInCode(
      '''
final dynamic a = 0;
var v = const <int>{if (1 > 0) 0 else a};
''',
      [error(CompileTimeErrorCode.nonConstantSetElement, 59, 1)],
    );
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await assertErrorsInCode(
      '''
final dynamic a = 0;
var v = const <int>{if (1 > 0) a else 0};
''',
      [error(CompileTimeErrorCode.nonConstantSetElement, 52, 1)],
    );
  }

  test_const_ifElement_thenFalse_constThen() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int>{if (1 < 0) a};
''');
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await assertErrorsInCode(
      '''
final dynamic a = 0;
var v = const <int>{if (1 < 0) a};
''',
      [error(CompileTimeErrorCode.nonConstantSetElement, 52, 1)],
    );
  }

  test_const_ifElement_thenTrue_constThen() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int>{if (1 > 0) a};
''');
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await assertErrorsInCode(
      '''
final dynamic a = 0;
var v = const <int>{if (1 > 0) a};
''',
      [error(CompileTimeErrorCode.nonConstantSetElement, 52, 1)],
    );
  }

  test_const_parameter() async {
    await assertErrorsInCode(
      r'''
f(a) {
  return const {a};
}''',
      [error(CompileTimeErrorCode.nonConstantSetElement, 23, 1)],
    );
  }

  test_const_spread_final() async {
    await assertErrorsInCode(
      r'''
final Set x = {};
var v = const {...x};
''',
      [error(CompileTimeErrorCode.nonConstantSetElement, 36, 1)],
    );
  }

  test_const_topVar() async {
    await assertErrorsInCode(
      '''
final dynamic a = 0;
var v = const <int>{a};
''',
      [error(CompileTimeErrorCode.nonConstantSetElement, 41, 1)],
    );
  }

  test_nonConst_topVar() async {
    await assertNoErrorsInCode('''
final dynamic a = 0;
var v = <int>{a};
''');
  }
}
