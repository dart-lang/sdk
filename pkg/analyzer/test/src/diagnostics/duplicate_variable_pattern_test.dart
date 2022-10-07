// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateVariablePatternTest);
  });
}

@reflectiveTest
class DuplicateVariablePatternTest extends PatternsResolutionTest {
  test_ifCase() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case var a & var a) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN, 41, 1,
          contextMessages: [message('/home/test/lib/test.dart', 33, 1)]),
    ]);
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    keyword: var
    name: a
    declaredElement: hasImplicitType a@33
      type: int
  operator: &
  rightOperand: VariablePattern
    keyword: var
    name: a
    declaredElement: a@33
''');
  }

  test_switchStatement() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case var a & var a:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN, 52, 1,
          contextMessages: [message('/home/test/lib/test.dart', 44, 1)]),
    ]);
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    keyword: var
    name: a
    declaredElement: hasImplicitType a@44
      type: int
  operator: &
  rightOperand: VariablePattern
    keyword: var
    name: a
    declaredElement: a@44
''');
  }
}
