// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PostfixPatternResolutionTest);
  });
}

@reflectiveTest
class PostfixPatternResolutionTest extends PatternsResolutionTest {
  test_nullAssert_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  if (x case var y!) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@34
      type: int
  operator: !
''');
  }

  test_nullAssert_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  switch (x) {
    case var y!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@45
      type: int
  operator: !
''');
  }

  test_nullCheck_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  if (x case var y?) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@34
      type: int
  operator: ?
''');
  }

  test_nullCheck_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  switch (x) {
    case var y?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@45
      type: int
  operator: ?
''');
  }
}
