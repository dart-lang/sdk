// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastPatternResolutionTest);
  });
}

@reflectiveTest
class CastPatternResolutionTest extends PatternsResolutionTest {
  test_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case var y as int) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@29
      type: int
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
''');
  }

  test_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x, y) {
  switch (x) {
    case y as int:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
      staticElement: self::@function::f::@parameter::y
      staticType: dynamic
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
''');
  }
}
