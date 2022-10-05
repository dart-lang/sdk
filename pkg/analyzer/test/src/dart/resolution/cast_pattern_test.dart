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
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    keyword: var
    name: y
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: int
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
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: int
''');
  }
}
