// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariablePatternResolutionTest);
  });
}

@reflectiveTest
class VariablePatternResolutionTest extends PatternsResolutionTest {
  test_final_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final y:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
VariablePattern
  keyword: final
  name: y
  declaredElement: hasImplicitType isFinal y@46
    type: int
''');
  }

  test_final_typed_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case final int y:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
VariablePattern
  keyword: final
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  name: y
  declaredElement: isFinal y@46
    type: int
''');
  }

  test_typed_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int y:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
VariablePattern
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  name: y
  declaredElement: y@40
    type: int
''');
  }

  test_typed_wildcard_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int _:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
VariablePattern
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  name: _
''');
  }

  test_var_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case var y) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
VariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@33
    type: int
''');
  }

  test_var_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case var y:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
VariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@44
    type: int
''');
  }

  test_var_switchCase_cast() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case var y as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@44
      type: Object
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
      staticElement: dart:core::@class::Object
      staticType: null
    type: Object
''');
  }
}
