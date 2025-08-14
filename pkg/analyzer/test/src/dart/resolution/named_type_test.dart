// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedTypeResolutionTest);
  });
}

@reflectiveTest
class NamedTypeResolutionTest extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
class A {}

f(A a) {}
''');

    var node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element2: <testLibrary>::@class::A
  type: A
''');
  }

  test_class_generic_toBounds() async {
    await assertNoErrorsInCode(r'''
class A<T extends num> {}

f(A a) {}
''');

    var node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element2: <testLibrary>::@class::A
  type: A<num>
''');
  }

  test_class_generic_toBounds_dynamic() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

f(A a) {}
''');

    var node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element2: <testLibrary>::@class::A
  type: A<dynamic>
''');
  }

  test_class_generic_typeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

f(A<int> a) {}
''');

    var node = findNode.namedType('A<int> a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@class::A
  type: A<int>
''');
  }

  test_dynamic_explicitCore() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';

dynamic a;
''');

    var node = findNode.namedType('dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: dynamic
  element2: dynamic
  type: dynamic
''');
  }

  test_dynamic_explicitCore_withPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core' as myCore;

myCore.dynamic a;
''');

    var node = findNode.namedType('myCore.dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: myCore
    period: .
    element2: <testLibraryFragment>::@prefix2::myCore
  name: dynamic
  element2: dynamic
  type: dynamic
''');
  }

  test_dynamic_explicitCore_withPrefix_referenceWithout() async {
    await assertErrorsInCode(
      r'''
import 'dart:core' as myCore;

dynamic a;
''',
      [error(CompileTimeErrorCode.undefinedClass, 31, 7)],
    );

    var node = findNode.namedType('dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: dynamic
  element2: <null>
  type: InvalidType
''');
  }

  test_dynamic_implicitCore() async {
    await assertNoErrorsInCode(r'''
dynamic a;
''');

    var node = findNode.namedType('dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: dynamic
  element2: dynamic
  type: dynamic
''');
  }

  test_extendsClause_genericClass() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

class B extends A<int> {}
''');

    var node = findNode.namedType('A<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@class::A
  type: A<int>
''');
  }

  test_extendsClause_genericClass_tooFewArguments() async {
    await assertErrorsInCode(
      r'''
class A<T, U> {}

class B extends A<int> {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 34, 6)],
    );

    var node = findNode.namedType('A<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@class::A
  type: A<InvalidType, InvalidType>
''');
  }

  test_extendsClause_genericClass_tooManyArguments() async {
    await assertErrorsInCode(
      r'''
class A<T> {}

class B extends A<int, String> {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 31, 14)],
    );

    var node = findNode.namedType('A<int, String>');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  element2: <testLibrary>::@class::A
  type: A<InvalidType>
''');
  }

  test_extendsClause_typeParameter() async {
    await assertErrorsInCode(
      r'''
class A<T> extends T<int> {}
''',
      [
        error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 19, 6),
        error(CompileTimeErrorCode.extendsNonClass, 19, 1),
      ],
    );

    var node = findNode.namedType('T<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: #E0 T
  type: T
''');
  }

  test_extensionType_generic_toBounds() async {
    await assertNoErrorsInCode(r'''
extension type A<T extends num>(List<T> it) {}
void f(A a) {}
''');

    var node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element2: <testLibrary>::@extensionType::A
  type: A<num>
''');
  }

  test_extensionType_generic_toBounds_dynamic() async {
    await assertNoErrorsInCode(r'''
extension type A<T>(List<T> it) {}
void f(A a) {}
''');

    var node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element2: <testLibrary>::@extensionType::A
  type: A<dynamic>
''');
  }

  test_extensionType_generic_typeParameters() async {
    await assertNoErrorsInCode(r'''
extension type A<T>(List<T> it) {}
void f(A<int> a) {}
''');

    var node = findNode.namedType('A<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@extensionType::A
  type: A<int>
''');
  }

  test_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef F = int Function();

f(F a) {}
''');

    var node = findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element2: <testLibrary>::@typeAlias::F
  type: int Function()
    alias: <testLibrary>::@typeAlias::F
''');
  }

  test_functionTypeAlias_generic_toBounds() async {
    await assertNoErrorsInCode(r'''
typedef F<T extends num> = T Function();

f(F a) {}
''');

    var node = findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element2: <testLibrary>::@typeAlias::F
  type: num Function()
    alias: <testLibrary>::@typeAlias::F
      typeArguments
        num
''');
  }

  test_functionTypeAlias_generic_toBounds_dynamic() async {
    await assertNoErrorsInCode(r'''
typedef F<T> = T Function();

f(F a) {}
''');

    var node = findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element2: <testLibrary>::@typeAlias::F
  type: dynamic Function()
    alias: <testLibrary>::@typeAlias::F
      typeArguments
        dynamic
''');
  }

  test_functionTypeAlias_generic_typeArguments() async {
    await assertNoErrorsInCode(r'''
typedef F<T> = T Function();

f(F<int> a) {}
''');

    var node = findNode.namedType('F<int> a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@typeAlias::F
  type: int Function()
    alias: <testLibrary>::@typeAlias::F
      typeArguments
        int
''');
  }

  test_importPrefix_genericClass() async {
    await assertNoErrorsInCode(r'''
import 'dart:async' as async;

void f(async.Future<int> a) {}
''');

    var node = findNode.namedType('async.Future');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: async
    period: .
    element2: <testLibraryFragment>::@prefix2::async
  name: Future
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: dart:async::@class::Future
  type: Future<int>
''');
  }

  test_importPrefix_unresolved() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as math;

void f(math.Unresolved<int> a) {}
''',
      [error(CompileTimeErrorCode.undefinedClass, 36, 15)],
    );

    var node = findNode.namedType('math.Unresolved');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element2: <testLibraryFragment>::@prefix2::math
  name: Unresolved
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <null>
  type: InvalidType
''');
  }

  test_instanceCreation_explicitNew_prefix_unresolvedClass() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as math;

main() {
  new math.A();
}
''',
      [error(CompileTimeErrorCode.newWithNonType, 49, 1)],
    );

    var node = findNode.namedType('A();');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element2: <testLibraryFragment>::@prefix2::math
  name: A
  element2: <null>
  type: InvalidType
''');
  }

  test_instanceCreation_explicitNew_resolvedClass() async {
    await assertNoErrorsInCode(r'''
class A {}

main() {
  new A();
}
''');

    var node = findNode.namedType('A();');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element2: <testLibrary>::@class::A
  type: A
''');
  }

  test_instanceCreation_explicitNew_unresolvedClass() async {
    await assertErrorsInCode(
      r'''
main() {
  new A();
}
''',
      [error(CompileTimeErrorCode.newWithNonType, 15, 1)],
    );

    var node = findNode.namedType('A();');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element2: <null>
  type: InvalidType
''');
  }

  test_invalid_deferredImportPrefix_identifier() async {
    await assertErrorsInCode(
      r'''
import 'dart:async' deferred as async;

void f() {
  async.Future<int> v;
}
''',
      [
        error(CompileTimeErrorCode.typeAnnotationDeferredClass, 53, 17),
        error(WarningCode.unusedLocalVariable, 71, 1),
      ],
    );

    var node = findNode.namedType('async.Future');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: async
    period: .
    element2: <testLibraryFragment>::@prefix2::async
  name: Future
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: dart:async::@class::Future
  type: Future<int>
''');
  }

  test_invalid_importPrefix() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as prefix;

void f(prefix a) {}
''',
      [
        error(
          CompileTimeErrorCode.notAType,
          38,
          6,
          contextMessages: [message(testFile, 22, 6)],
        ),
      ],
    );

    var node = findNode.namedType('prefix a');
    assertResolvedNodeText(node, r'''
NamedType
  name: prefix
  element2: <testLibraryFragment>::@prefix2::prefix
  type: InvalidType
''');
  }

  test_invalid_importPrefix_withTypeArguments() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as prefix;

void f(prefix<int> a) {}
''',
      [
        error(
          CompileTimeErrorCode.notAType,
          38,
          6,
          contextMessages: [message(testFile, 22, 6)],
        ),
      ],
    );

    var node = findNode.namedType('prefix<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: prefix
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibraryFragment>::@prefix2::prefix
  type: InvalidType
''');
  }

  test_invalid_prefixedIdentifier_instanceCreation() async {
    await assertErrorsInCode(
      r'''
void f() {
  new int.double.other();
}
''',
      [error(CompileTimeErrorCode.newWithNonType, 17, 10)],
    );

    var node = findNode.namedType('int.double');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: int
    period: .
    element2: dart:core::@class::int
  name: double
  element2: <null>
  type: InvalidType
''');
  }

  test_invalid_prefixedIdentifier_literal() async {
    await assertErrorsInCode(
      r'''
void f() {
  0 as int.double;
}
''',
      [error(CompileTimeErrorCode.notAType, 18, 10)],
    );

    var node = findNode.namedType('int.double');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: int
    period: .
    element2: dart:core::@class::int
  name: double
  element2: <null>
  type: InvalidType
''');
  }

  test_invalid_topLevelFunction() async {
    await assertErrorsInCode(
      r'''
void f(T a) {}

void T() {}
''',
      [
        error(
          CompileTimeErrorCode.notAType,
          7,
          1,
          contextMessages: [message(testFile, 21, 1)],
        ),
      ],
    );

    var node = findNode.namedType('T a');
    assertResolvedNodeText(node, r'''
NamedType
  name: T
  element2: <testLibrary>::@function::T
  type: InvalidType
''');
  }

  test_invalid_topLevelFunction_withTypeArguments() async {
    await assertErrorsInCode(
      r'''
void f(T<int> a) {}

void T() {}
''',
      [
        error(
          CompileTimeErrorCode.notAType,
          7,
          1,
          contextMessages: [message(testFile, 26, 1)],
        ),
      ],
    );

    var node = findNode.namedType('T<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@function::T
  type: InvalidType
''');
  }

  test_invalid_typeParameter_identifier() async {
    await assertErrorsInCode(
      r'''
void f<T>(T.name<int> a) {}
''',
      [error(CompileTimeErrorCode.prefixShadowedByLocalDeclaration, 10, 1)],
    );

    var node = findNode.namedType('T.name<int>');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: T
    period: .
    element2: #E0 T
  name: name
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <null>
  type: InvalidType
''');
  }

  test_multiplyDefined() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
class A {}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
import 'b.dart';

void f(A a) {}
''',
      [error(CompileTimeErrorCode.ambiguousImport, 42, 1)],
    );

    var node = findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element2: multiplyDefinedElement
    package:test/a.dart::@class::A
    package:test/b.dart::@class::A
  type: InvalidType
''');
  }

  test_never() async {
    await assertNoErrorsInCode(r'''
f(Never a) {}
''');

    var node = findNode.namedType('Never a');
    assertResolvedNodeText(node, r'''
NamedType
  name: Never
  element2: Never
  type: Never
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

    var node = findNode.namedType('X<int>()');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@typeAlias::X
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

    var node = findNode.namedType('X()');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  element2: <testLibrary>::@typeAlias::X
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

    var node = findNode.namedType('X<int>()');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@typeAlias::X
  type: A<int>
''');
  }

  test_typeAlias_asParameterType_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = Map<int, T>;
void f(X<String> a, X<String?> b) {}
''');

    var node1 = findNode.namedType('X<String>');
    assertResolvedNodeText(node1, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  element2: <testLibrary>::@typeAlias::X
  type: Map<int, String>
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        String
''');

    var node2 = findNode.namedType('X<String?>');
    assertResolvedNodeText(node2, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        question: ?
        element2: dart:core::@class::String
        type: String?
    rightBracket: >
  element2: <testLibrary>::@typeAlias::X
  type: Map<int, String?>
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        String?
''');
  }

  test_typeAlias_asParameterType_interfaceType_question() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = List<T?>;
void f(X<int> a, X<int?> b) {}
''');

    var node1 = findNode.namedType('X<int>');
    assertResolvedNodeText(node1, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@typeAlias::X
  type: List<int?>
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        int
''');

    var node2 = findNode.namedType('X<int?>');
    assertResolvedNodeText(node2, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        question: ?
        element2: dart:core::@class::int
        type: int?
    rightBracket: >
  element2: <testLibrary>::@typeAlias::X
  type: List<int?>
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        int?
''');
  }

  test_typeAlias_asParameterType_Never_none() async {
    await assertNoErrorsInCode(r'''
typedef X = Never;
void f(X a, X? b) {}
''');

    var node1 = findNode.namedType('X a');
    assertResolvedNodeText(node1, r'''
NamedType
  name: X
  element2: <testLibrary>::@typeAlias::X
  type: Never
''');

    var node2 = findNode.namedType('X? b');
    assertResolvedNodeText(node2, r'''
NamedType
  name: X
  question: ?
  element2: <testLibrary>::@typeAlias::X
  type: Never?
''');
  }

  test_typeAlias_asParameterType_Never_question() async {
    await assertNoErrorsInCode(r'''
typedef X = Never?;
void f(X a, X? b) {}
''');

    var node1 = findNode.namedType('X a');
    assertResolvedNodeText(node1, r'''
NamedType
  name: X
  element2: <testLibrary>::@typeAlias::X
  type: Never?
''');

    var node2 = findNode.namedType('X? b');
    assertResolvedNodeText(node2, r'''
NamedType
  name: X
  question: ?
  element2: <testLibrary>::@typeAlias::X
  type: Never?
''');
  }

  test_typeAlias_asParameterType_question() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = T?;
void f(X<int> a) {}
''');

    var node = findNode.namedType('X<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@typeAlias::X
  type: int?
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        int
''');
  }

  test_typeAlias_asReturnType_interfaceType() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = Map<int, T>;
X<String> f() => {};
''');

    var node = findNode.namedType('X<String>');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  element2: <testLibrary>::@typeAlias::X
  type: Map<int, String>
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        String
''');
  }

  test_typeAlias_asReturnType_void() async {
    await assertNoErrorsInCode(r'''
typedef Nothing = void;
Nothing f() {}
''');

    var node = findNode.namedType('Nothing f()');
    assertResolvedNodeText(node, r'''
NamedType
  name: Nothing
  element2: <testLibrary>::@typeAlias::Nothing
  type: void
''');
  }

  test_unresolved() async {
    await assertErrorsInCode(
      r'''
void f(Unresolved<int> a) {}
''',
      [error(CompileTimeErrorCode.undefinedClass, 7, 10)],
    );

    var node = findNode.namedType('Unresolved');
    assertResolvedNodeText(node, r'''
NamedType
  name: Unresolved
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <null>
  type: InvalidType
''');
  }

  test_unresolved_identifier() async {
    await assertErrorsInCode(
      r'''
void f(unresolved.List<int> a) {}
''',
      [error(CompileTimeErrorCode.undefinedClass, 7, 15)],
    );

    var node = findNode.namedType('unresolved.List');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: unresolved
    period: .
    element2: <null>
  name: List
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <null>
  type: InvalidType
''');
  }
}
