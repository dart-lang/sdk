// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalForElementTest);
  });
}

@reflectiveTest
class ConstEvalForElementTest extends PubPackageResolutionTest {
  test_listLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = [for (int i = 0; i < 3; i++) i];
//        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalForElement] Constant expressions don't support 'for' elements.
''');
  }

  test_listLiteral_forIn() async {
    await resolveTestCodeWithDiagnostics(r'''
const Set set = {};
const x = [for(final i in set) i];
//        ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//         ^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalForElement] Constant expressions don't support 'for' elements.
''');
  }

  test_mapLiteral_forIn() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = {for (final i in const []) i: null};
//        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalForElement] Constant expressions don't support 'for' elements.
''');
  }

  test_mapLiteral_forIn_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = {if (true) for (final i in const []) i: null};
//        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalForElement] Constant expressions don't support 'for' elements.
''');
  }

  test_setLiteral_forIn() async {
    await resolveTestCodeWithDiagnostics(r'''
const Set set = {};
const x = {for (final i in set) i};
//        ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//         ^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalForElement] Constant expressions don't support 'for' elements.
''');
  }
}
