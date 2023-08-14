// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsRepeatedTest);
  });
}

@reflectiveTest
class ImplementsRepeatedTest extends PubPackageResolutionTest {
  test_class_implements_2times() async {
    await assertErrorsInCode(r'''
class A {}
class B implements A, A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 33, 1),
    ]);

    final node = findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: A
      element: self::@class::A
      type: A
    NamedType
      name: A
      element: self::@class::A
      type: A
''');
  }

  test_class_implements_2times_viaTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
typedef B = A;
class C implements A, B {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 48, 1),
    ]);

    final node = findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: A
      element: self::@class::A
      type: A
    NamedType
      name: B
      element: self::@typeAlias::B
      type: A
        alias: self::@typeAlias::B
''');
  }

  test_class_implements_4times() async {
    await assertErrorsInCode(r'''
class A {} class C{}
class B implements A, A, A, A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 43, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 46, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 49, 1),
    ]);
  }

  test_enum_implements_2times() async {
    await assertErrorsInCode(r'''
class A {}
enum E implements A, A {
  v
}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 32, 1),
    ]);

    final node = findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: A
      element: self::@class::A
      type: A
    NamedType
      name: A
      element: self::@class::A
      type: A
''');
  }

  test_enum_implements_2times_viaTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
typedef B = A;
enum E implements A, B {
  v
}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 47, 1),
    ]);

    final node = findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: A
      element: self::@class::A
      type: A
    NamedType
      name: B
      element: self::@typeAlias::B
      type: A
        alias: self::@typeAlias::B
''');
  }

  test_enum_implements_4times() async {
    await assertErrorsInCode(r'''
class A {} class C{}
enum E implements A, A, A, A {
  v
}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 42, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 45, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 48, 1),
    ]);
  }

  test_mixin_implements_2times() async {
    await assertErrorsInCode(r'''
class A {}
mixin M implements A, A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 33, 1),
    ]);
  }

  test_mixin_implements_4times() async {
    await assertErrorsInCode(r'''
class A {}
mixin M implements A, A, A, A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 33, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 36, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_REPEATED, 39, 1),
    ]);
  }
}
