// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedTypeResolutionTest);
    defineReflectiveTests(NamedTypeResolutionTest_WithoutNullSafety);
  });
}

@reflectiveTest
class NamedTypeResolutionTest extends PubPackageResolutionTest
    with TypeNameResolutionTestCases {
  ImportFindElement get import_a {
    return findElement.importFind('package:test/a.dart');
  }

  test_extendsClause_genericClass() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

class B extends A<int> {}
''');

    final node = findNode.namedType('A<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: self::@class::A
  type: A<int>
''');
  }

  test_extendsClause_genericClass_tooFewArguments() async {
    await assertErrorsInCode(r'''
class A<T, U> {}

class B extends A<int> {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 34, 6),
    ]);

    final node = findNode.namedType('A<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: self::@class::A
  type: A<dynamic, dynamic>
''');
  }

  test_extendsClause_genericClass_tooManyArguments() async {
    await assertErrorsInCode(r'''
class A<T> {}

class B extends A<int, String> {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 31, 14),
    ]);

    final node = findNode.namedType('A<int, String>');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  element: self::@class::A
  type: A<dynamic>
''');
  }

  test_extendsClause_typeParameter() async {
    await assertErrorsInCode(r'''
class A<T> extends T<int> {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 19, 6),
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 19, 1),
    ]);

    final node = findNode.namedType('T<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: T@8
  type: T
''');
  }

  test_importPrefix_genericClass() async {
    await assertNoErrorsInCode(r'''
import 'dart:async' as async;

void f(async.Future<int> a) {}
''');

    final node = findNode.namedType('async.Future');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: async
    period: .
    element: self::@prefix::async
  name: Future
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: dart:async::@class::Future
  type: Future<int>
''');
  }

  test_importPrefix_unresolved() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

void f(math.Unresolved<int> a) {}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 36, 15),
    ]);

    final node = findNode.namedType('math.Unresolved');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element: self::@prefix::math
  name: Unresolved
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <null>
  type: dynamic
''');
  }

  test_invalid_deferredImportPrefix_identifier() async {
    await assertErrorsInCode(r'''
import 'dart:async' deferred as async;

void f() {
  async.Future<int> v;
}
''', [
      error(CompileTimeErrorCode.TYPE_ANNOTATION_DEFERRED_CLASS, 53, 17),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 71, 1),
    ]);

    final node = findNode.namedType('async.Future');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: async
    period: .
    element: self::@prefix::async
  name: Future
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: dart:async::@class::Future
  type: Future<int>
''');
  }

  test_invalid_importPrefix() async {
    await assertErrorsInCode(r'''
import 'dart:math' as prefix;

void f(prefix<int> a) {}
''', [
      error(CompileTimeErrorCode.NOT_A_TYPE, 38, 6),
    ]);

    final node = findNode.namedType('prefix<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: prefix
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: self::@prefix::prefix
  type: dynamic
''');
  }

  test_invalid_topLevelFunction() async {
    await assertErrorsInCode(r'''
void f(T<int> a) {}

void T() {}
''', [
      error(CompileTimeErrorCode.NOT_A_TYPE, 7, 1),
    ]);

    final node = findNode.namedType('T<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: self::@function::T
  type: dynamic
''');
  }

  test_invalid_typeParameter_identifier() async {
    await assertErrorsInCode(r'''
void f<T>(T.name<int> a) {}
''', [
      error(CompileTimeErrorCode.PREFIX_SHADOWED_BY_LOCAL_DECLARATION, 10, 1),
    ]);

    final node = findNode.namedType('T.name<int>');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: T
    period: .
    element: T@7
  name: name
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <null>
  type: dynamic
''');
  }

  test_optIn_fromOptOut_class() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {}
''');

    final node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: package:test/a.dart::@class::A
  type: A*
''');
  }

  test_optIn_fromOptOut_class_generic_toBounds() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A<T extends num> {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {}
''');

    final node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: package:test/a.dart::@class::A
  type: A<num*>*
''');
  }

  test_optIn_fromOptOut_class_generic_toBounds_dynamic() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {}
''');

    final node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: package:test/a.dart::@class::A
  type: A<dynamic>*
''');
  }

  test_optIn_fromOptOut_class_generic_typeArguments() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A<int> a) {}
''');

    final node = findNode.namedType('A<int> a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int*
    rightBracket: >
  element: package:test/a.dart::@class::A
  type: A<int*>*
''');
  }

  test_optIn_fromOptOut_functionTypeAlias() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
typedef F = int Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    final node = findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: package:test/a.dart::@typeAlias::F
  type: int* Function(bool*)*
    alias: package:test/a.dart::@typeAlias::F
''');
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_dynamic() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
typedef F<T> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    final node = findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: package:test/a.dart::@typeAlias::F
  type: dynamic Function(bool*)*
    alias: package:test/a.dart::@typeAlias::F
      typeArguments
        dynamic
''');
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_toBounds() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
typedef F<T extends num> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    final node = findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: package:test/a.dart::@typeAlias::F
  type: num* Function(bool*)*
    alias: package:test/a.dart::@typeAlias::F
      typeArguments
        num*
''');
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_typeArguments() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
typedef F<T> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F<int> a) {}
''');

    final node = findNode.namedType('F<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int*
    rightBracket: >
  element: package:test/a.dart::@typeAlias::F
  type: int* Function(bool*)*
    alias: package:test/a.dart::@typeAlias::F
      typeArguments
        int*
''');
  }

  test_optOut_fromOptIn_class() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    final node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: package:test/a.dart::@class::A
  type: A
''');
  }

  test_optOut_fromOptIn_class_generic_toBounds() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
class A<T extends num> {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    final node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: package:test/a.dart::@class::A
  type: A<num*>
''');
  }

  test_optOut_fromOptIn_class_generic_toBounds_dynamic() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
class A<T> {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    final node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: package:test/a.dart::@class::A
  type: A<dynamic>
''');
  }

  test_optOut_fromOptIn_class_generic_typeArguments() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
class A<T> {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A<int> a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    final node = findNode.namedType('A<int> a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: package:test/a.dart::@class::A
  type: A<int>
''');
  }

  test_optOut_fromOptIn_functionTypeAlias() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
typedef F = int Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    final node = findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: package:test/a.dart::@typeAlias::F
  type: int* Function()
    alias: package:test/a.dart::@typeAlias::F
''');
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_toBounds() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
typedef F<T extends num> = T Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    final node = findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: package:test/a.dart::@typeAlias::F
  type: num* Function()
    alias: package:test/a.dart::@typeAlias::F
      typeArguments
        num*
''');
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_toBounds_dynamic() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
typedef F<T> = T Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    final node = findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: package:test/a.dart::@typeAlias::F
  type: dynamic Function()
    alias: package:test/a.dart::@typeAlias::F
      typeArguments
        dynamic
''');
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_typeArguments() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
typedef F<T> = T Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F<int> a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    final node = findNode.namedType('F<int> a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: package:test/a.dart::@typeAlias::F
  type: int* Function()
    alias: package:test/a.dart::@typeAlias::F
      typeArguments
        int
''');
  }

  test_typeAlias_asInstanceCreation_explicitNew_typeArguments_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

typedef X<T> = A<T>;

void f() {
  new X<int>();
}
''');

    final node = findNode.namedType('X<int>()');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: self::@typeAlias::X
  type: A<int>
''');
  }

  test_typeAlias_asInstanceCreation_implicitNew_toBounds_noTypeParameters_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

typedef X = A<int>;

void f() {
  X();
}
''');

    final node = findNode.namedType('X()');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  element: self::@typeAlias::X
  type: A<int>
''');
  }

  test_typeAlias_asInstanceCreation_implicitNew_typeArguments_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

typedef X<T> = A<T>;

void f() {
  X<int>();
}
''');

    final node = findNode.namedType('X<int>()');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: self::@typeAlias::X
  type: A<int>
''');
  }

  test_typeAlias_asParameterType_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = Map<int, T>;
void f(X<String> a, X<String?> b) {}
''');

    final node1 = findNode.namedType('X<String>');
    assertResolvedNodeText(node1, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  element: self::@typeAlias::X
  type: Map<int, String>
    alias: self::@typeAlias::X
      typeArguments
        String
''');

    final node2 = findNode.namedType('X<String?>');
    assertResolvedNodeText(node2, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        question: ?
        element: dart:core::@class::String
        type: String?
    rightBracket: >
  element: self::@typeAlias::X
  type: Map<int, String?>
    alias: self::@typeAlias::X
      typeArguments
        String?
''');
  }

  test_typeAlias_asParameterType_interfaceType_none_inLegacy() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
typedef X<T> = Map<int, T>;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';
void f(X<String> a) {}
''');

    final node = findNode.namedType('X<String>');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::@class::String
        type: String*
    rightBracket: >
  element: package:test/a.dart::@typeAlias::X
  type: Map<int*, String*>*
    alias: package:test/a.dart::@typeAlias::X
      typeArguments
        String*
''');
  }

  test_typeAlias_asParameterType_interfaceType_question() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = List<T?>;
void f(X<int> a, X<int?> b) {}
''');

    final node1 = findNode.namedType('X<int>');
    assertResolvedNodeText(node1, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: self::@typeAlias::X
  type: List<int?>
    alias: self::@typeAlias::X
      typeArguments
        int
''');

    final node2 = findNode.namedType('X<int?>');
    assertResolvedNodeText(node2, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        question: ?
        element: dart:core::@class::int
        type: int?
    rightBracket: >
  element: self::@typeAlias::X
  type: List<int?>
    alias: self::@typeAlias::X
      typeArguments
        int?
''');
  }

  test_typeAlias_asParameterType_interfaceType_question_inLegacy() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
typedef X<T> = List<T?>;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';
void f(X<int> a) {}
''');

    final node = findNode.namedType('X<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int*
    rightBracket: >
  element: package:test/a.dart::@typeAlias::X
  type: List<int*>*
    alias: package:test/a.dart::@typeAlias::X
      typeArguments
        int*
''');
  }

  test_typeAlias_asParameterType_Never_none() async {
    await assertNoErrorsInCode(r'''
typedef X = Never;
void f(X a, X? b) {}
''');

    final node1 = findNode.namedType('X a');
    assertResolvedNodeText(node1, r'''
NamedType
  name: X
  element: self::@typeAlias::X
  type: Never
''');

    final node2 = findNode.namedType('X? b');
    assertResolvedNodeText(node2, r'''
NamedType
  name: X
  question: ?
  element: self::@typeAlias::X
  type: Never?
''');
  }

  test_typeAlias_asParameterType_Never_none_inLegacy() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
typedef X = Never;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';
void f(X a) {}
''');

    final node = findNode.namedType('X a');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  element: package:test/a.dart::@typeAlias::X
  type: Null*
''');
  }

  test_typeAlias_asParameterType_Never_question() async {
    await assertNoErrorsInCode(r'''
typedef X = Never?;
void f(X a, X? b) {}
''');

    final node1 = findNode.namedType('X a');
    assertResolvedNodeText(node1, r'''
NamedType
  name: X
  element: self::@typeAlias::X
  type: Never?
''');

    final node2 = findNode.namedType('X? b');
    assertResolvedNodeText(node2, r'''
NamedType
  name: X
  question: ?
  element: self::@typeAlias::X
  type: Never?
''');
  }

  test_typeAlias_asParameterType_question() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = T?;
void f(X<int> a) {}
''');

    final node = findNode.namedType('X<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: self::@typeAlias::X
  type: int?
    alias: self::@typeAlias::X
      typeArguments
        int
''');
  }

  test_typeAlias_asReturnType_interfaceType() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = Map<int, T>;
X<String> f() => {};
''');

    final node = findNode.namedType('X<String>');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  element: self::@typeAlias::X
  type: Map<int, String>
    alias: self::@typeAlias::X
      typeArguments
        String
''');
  }

  test_typeAlias_asReturnType_void() async {
    await assertNoErrorsInCode(r'''
typedef Nothing = void;
Nothing f() {}
''');

    final node = findNode.namedType('Nothing f()');
    assertResolvedNodeText(node, r'''
NamedType
  name: Nothing
  element: self::@typeAlias::Nothing
  type: void
''');
  }

  test_unresolved() async {
    await assertErrorsInCode(r'''
void f(Unresolved<int> a) {}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 7, 10),
    ]);

    final node = findNode.namedType('Unresolved');
    assertResolvedNodeText(node, r'''
NamedType
  name: Unresolved
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <null>
  type: dynamic
''');
  }

  test_unresolved_identifier() async {
    await assertErrorsInCode(r'''
void f(unresolved.List<int> a) {}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 7, 15),
    ]);

    final node = findNode.namedType('unresolved.List');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: unresolved
    period: .
    element: <null>
  name: List
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <null>
  type: dynamic
''');
  }
}

@reflectiveTest
class NamedTypeResolutionTest_WithoutNullSafety extends PubPackageResolutionTest
    with TypeNameResolutionTestCases, WithoutNullSafetyMixin {}

mixin TypeNameResolutionTestCases on PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
class A {}

f(A a) {}
''');

    final node = findNode.namedType('A a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@class::A
  type: A
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@class::A
  type: A*
''');
    }
  }

  test_class_generic_toBounds() async {
    await assertNoErrorsInCode(r'''
class A<T extends num> {}

f(A a) {}
''');

    final node = findNode.namedType('A a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@class::A
  type: A<num>
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@class::A
  type: A<num*>*
''');
    }
  }

  test_class_generic_toBounds_dynamic() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

f(A a) {}
''');

    final node = findNode.namedType('A a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@class::A
  type: A<dynamic>
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@class::A
  type: A<dynamic>*
''');
    }
  }

  test_class_generic_typeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

f(A<int> a) {}
''');

    final node = findNode.namedType('A<int> a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: self::@class::A
  type: A<int>
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int*
    rightBracket: >
  element: self::@class::A
  type: A<int*>*
''');
    }
  }

  test_dynamic_explicitCore() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';

dynamic a;
''');

    final node = findNode.namedType('dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: dynamic
  element: dynamic@-1
  type: dynamic
''');
  }

  test_dynamic_explicitCore_withPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core' as myCore;

myCore.dynamic a;
''');

    final node = findNode.namedType('myCore.dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: myCore
    period: .
    element: self::@prefix::myCore
  name: dynamic
  element: dynamic@-1
  type: dynamic
''');
  }

  test_dynamic_explicitCore_withPrefix_referenceWithout() async {
    await assertErrorsInCode(r'''
import 'dart:core' as myCore;

dynamic a;
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 31, 7),
    ]);

    final node = findNode.namedType('dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: dynamic
  element: <null>
  type: dynamic
''');
  }

  test_dynamic_implicitCore() async {
    await assertNoErrorsInCode(r'''
dynamic a;
''');

    final node = findNode.namedType('dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: dynamic
  element: dynamic@-1
  type: dynamic
''');
  }

  test_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef F = int Function();

f(F a) {}
''');

    final node = findNode.namedType('F a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: self::@typeAlias::F
  type: int Function()
    alias: self::@typeAlias::F
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: self::@typeAlias::F
  type: int* Function()*
    alias: self::@typeAlias::F
''');
    }
  }

  test_functionTypeAlias_generic_toBounds() async {
    await assertNoErrorsInCode(r'''
typedef F<T extends num> = T Function();

f(F a) {}
''');

    final node = findNode.namedType('F a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: self::@typeAlias::F
  type: num Function()
    alias: self::@typeAlias::F
      typeArguments
        num
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: self::@typeAlias::F
  type: num* Function()*
    alias: self::@typeAlias::F
      typeArguments
        num*
''');
    }
  }

  test_functionTypeAlias_generic_toBounds_dynamic() async {
    await assertNoErrorsInCode(r'''
typedef F<T> = T Function();

f(F a) {}
''');

    final node = findNode.namedType('F a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: self::@typeAlias::F
  type: dynamic Function()
    alias: self::@typeAlias::F
      typeArguments
        dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: self::@typeAlias::F
  type: dynamic Function()*
    alias: self::@typeAlias::F
      typeArguments
        dynamic
''');
    }
  }

  test_functionTypeAlias_generic_typeArguments() async {
    await assertNoErrorsInCode(r'''
typedef F<T> = T Function();

f(F<int> a) {}
''');

    final node = findNode.namedType('F<int> a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: F
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: self::@typeAlias::F
  type: int Function()
    alias: self::@typeAlias::F
      typeArguments
        int
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: F
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int*
    rightBracket: >
  element: self::@typeAlias::F
  type: int* Function()*
    alias: self::@typeAlias::F
      typeArguments
        int*
''');
    }
  }

  test_instanceCreation_explicitNew_prefix_unresolvedClass() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  new math.A();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 49, 1),
    ]);

    final node = findNode.namedType('A();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element: self::@prefix::math
  name: A
  element: <null>
  type: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element: self::@prefix::math
  name: A
  element: <null>
  type: dynamic
''');
    }
  }

  test_instanceCreation_explicitNew_resolvedClass() async {
    await assertNoErrorsInCode(r'''
class A {}

main() {
  new A();
}
''');

    final node = findNode.namedType('A();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@class::A
  type: A
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: self::@class::A
  type: A*
''');
    }
  }

  test_instanceCreation_explicitNew_unresolvedClass() async {
    await assertErrorsInCode(r'''
main() {
  new A();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 15, 1),
    ]);

    final node = findNode.namedType('A();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: <null>
  type: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: <null>
  type: dynamic
''');
    }
  }

  test_invalid_prefixedIdentifier_instanceCreation() async {
    await assertErrorsInCode(r'''
void f() {
  new int.double.other();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 17, 10),
    ]);

    final node = findNode.namedType('int.double');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: int
    period: .
    element: dart:core::@class::int
  name: double
  element: <null>
  type: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: int
    period: .
    element: dart:core::@class::int
  name: double
  element: <null>
  type: dynamic
''');
    }
  }

  test_invalid_prefixedIdentifier_literal() async {
    await assertErrorsInCode(r'''
void f() {
  0 as int.double;
}
''', [
      error(CompileTimeErrorCode.NOT_A_TYPE, 18, 10),
    ]);

    final node = findNode.namedType('int.double');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: int
    period: .
    element: dart:core::@class::int
  name: double
  element: <null>
  type: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: int
    period: .
    element: dart:core::@class::int
  name: double
  element: <null>
  type: dynamic
''');
    }
  }

  test_never() async {
    await assertNoErrorsInCode(r'''
f(Never a) {}
''');

    final node = findNode.namedType('Never a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
NamedType
  name: Never
  element: Never@-1
  type: Never
''');
    } else {
      assertResolvedNodeText(node, r'''
NamedType
  name: Never
  element: Never@-1
  type: Null*
''');
    }
  }
}
