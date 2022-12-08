// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclaredVariablePatternResolutionTest);
  });
}

@reflectiveTest
class DeclaredVariablePatternResolutionTest extends PubPackageResolutionTest {
  test_final_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final y:
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  name: _
''');
  }

  test_var_demoteType() async {
    await assertNoErrorsInCode(r'''
void f<T>(T x) {
  if (x is int) {
    if (x case var y) {}
  }
}
''');

    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@54
    type: T
''');
  }

  test_var_fromLegacy() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.10
final x = <int>[];
''');
    await assertNoErrorsInCode(r'''
// ignore:import_of_legacy_library_into_null_safe
import 'a.dart';
void f() {
  if (x case var y) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@95
    type: List<int>
''');
  }

  test_var_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case var y) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@33
    type: int
''');
  }

  test_var_nullOrEquivalent_neverQuestion() async {
    await assertNoErrorsInCode(r'''
void f(Never? x) {
  if (x case var y) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@36
    type: dynamic
''');
  }

  test_var_nullOrEquivalent_nullNone() async {
    await assertNoErrorsInCode(r'''
void f(Null x) {
  if (x case var y) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@34
    type: dynamic
''');
  }

  test_var_nullOrEquivalent_nullStar() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.10
Null x = null;
''');
    await assertNoErrorsInCode(r'''
// ignore:import_of_legacy_library_into_null_safe
import 'a.dart';
void f() {
  if (x case var y) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@95
    type: dynamic
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: DeclaredVariablePattern
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
