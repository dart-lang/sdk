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
class DuplicateVariablePatternTest extends PubPackageResolutionTest {
  test_ifCase() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case var a && var a) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN, 42, 1,
          contextMessages: [message('/home/test/lib/test.dart', 33, 1)]),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: DeclaredVariablePattern
    keyword: var
    name: a
    declaredElement: hasImplicitType a@33
      type: int
  operator: &&
  rightOperand: DeclaredVariablePattern
    keyword: var
    name: a
    declaredElement: hasImplicitType a@42
      type: int
''');
  }

  test_switchStatement() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case var a && var a:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN, 53, 1,
          contextMessages: [message('/home/test/lib/test.dart', 44, 1)]),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: DeclaredVariablePattern
    keyword: var
    name: a
    declaredElement: hasImplicitType a@44
      type: int
  operator: &&
  rightOperand: DeclaredVariablePattern
    keyword: var
    name: a
    declaredElement: hasImplicitType a@53
      type: int
''');
  }

  test_variableDeclaration() async {
    await assertErrorsInCode(r'''
void f(x) {
  var (var a, var a) = x;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN, 30, 1,
          contextMessages: [message('/home/test/lib/test.dart', 23, 1)]),
    ]);
  }
}
