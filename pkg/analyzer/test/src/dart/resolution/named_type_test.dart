// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedTypeResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NamedTypeResolutionTest extends PubPackageResolutionTest {
  test_class() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

f(A a) {}
''');

    var node = result.findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: <testLibrary>::@class::A
  type: A
''');
  }

  test_class_generic_toBounds() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T extends num> {}

f(A a) {}
''');

    var node = result.findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: <testLibrary>::@class::A
  type: A<num>
''');
  }

  test_class_generic_toBounds_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

f(A a) {}
''');

    var node = result.findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: <testLibrary>::@class::A
  type: A<dynamic>
''');
  }

  test_class_generic_typeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

f(A<int> a) {}
''');

    var node = result.findNode.namedType('A<int> a');
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
  element: <testLibrary>::@class::A
  type: A<int>
''');
  }

  test_dynamic_explicitCore() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core';

dynamic a;
''');

    var node = result.findNode.namedType('dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: dynamic
  element: dynamic
  type: dynamic
''');
  }

  test_dynamic_explicitCore_withPrefix() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as myCore;

myCore.dynamic a;
''');

    var node = result.findNode.namedType('myCore.dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: myCore
    period: .
    element: <testLibraryFragment>::@prefix::myCore
  name: dynamic
  element: dynamic
  type: dynamic
''');
  }

  test_dynamic_explicitCore_withPrefix_referenceWithout() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as myCore;

dynamic a;
// [diag.undefinedClass][column 1][length 7] Undefined class 'dynamic'.
''');

    var node = result.findNode.namedType('dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: dynamic
  element: <null>
  type: InvalidType
''');
  }

  test_dynamic_implicitCore() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
dynamic a;
''');

    var node = result.findNode.namedType('dynamic a;');
    assertResolvedNodeText(node, r'''
NamedType
  name: dynamic
  element: dynamic
  type: dynamic
''');
  }

  test_extendsClause_genericClass() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

class B extends A<int> {}
''');

    var node = result.findNode.namedType('A<int>');
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
  element: <testLibrary>::@class::A
  type: A<int>
''');
  }

  test_extendsClause_genericClass_tooFewArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T, U> {}

class B extends A<int> {}
//              ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'A' is declared with 2 type parameters, but 1 type arguments were given.
''');

    var node = result.findNode.namedType('A<int>');
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
  element: <testLibrary>::@class::A
  type: A<InvalidType, InvalidType>
''');
  }

  test_extendsClause_genericClass_tooManyArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

class B extends A<int, String> {}
//              ^^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'A' is declared with 1 type parameters, but 2 type arguments were given.
''');

    var node = result.findNode.namedType('A<int, String>');
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
  element: <testLibrary>::@class::A
  type: A<InvalidType>
''');
  }

  test_extendsClause_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> extends T<int> {}
//                 ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'T' is declared with 0 type parameters, but 1 type arguments were given.
//                 ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');

    var node = result.findNode.namedType('T<int>');
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
  element: #E0 T
  type: InvalidType
''');
  }

  test_extensionType_generic_toBounds() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T extends num>(List<T> it) {}
void f(A a) {}
''');

    var node = result.findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: <testLibrary>::@extensionType::A
  type: A<num>
''');
  }

  test_extensionType_generic_toBounds_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(List<T> it) {}
void f(A a) {}
''');

    var node = result.findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: <testLibrary>::@extensionType::A
  type: A<dynamic>
''');
  }

  test_extensionType_generic_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(List<T> it) {}
void f(A<int> a) {}
''');

    var node = result.findNode.namedType('A<int>');
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
  element: <testLibrary>::@extensionType::A
  type: A<int>
''');
  }

  test_functionTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = int Function();

f(F a) {}
''');

    var node = result.findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: <testLibrary>::@typeAlias::F
  type: int Function()
    alias: <testLibrary>::@typeAlias::F
''');
  }

  test_functionTypeAlias_generic_toBounds() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T extends num> = T Function();

f(F a) {}
''');

    var node = result.findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: <testLibrary>::@typeAlias::F
  type: num Function()
    alias: <testLibrary>::@typeAlias::F
      typeArguments
        num
''');
  }

  test_functionTypeAlias_generic_toBounds_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = T Function();

f(F a) {}
''');

    var node = result.findNode.namedType('F a');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: <testLibrary>::@typeAlias::F
  type: dynamic Function()
    alias: <testLibrary>::@typeAlias::F
      typeArguments
        dynamic
''');
  }

  test_functionTypeAlias_generic_typeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = T Function();

f(F<int> a) {}
''');

    var node = result.findNode.namedType('F<int> a');
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
  element: <testLibrary>::@typeAlias::F
  type: int Function()
    alias: <testLibrary>::@typeAlias::F
      typeArguments
        int
''');
  }

  test_importPrefix_genericClass() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' as async;

void f(async.Future<int> a) {}
''');

    var node = result.findNode.namedType('async.Future');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: async
    period: .
    element: <testLibraryFragment>::@prefix::async
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as math;

void f(math.Unresolved<int> a) {}
//     ^^^^^^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
''');

    var node = result.findNode.namedType('math.Unresolved');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element: <testLibraryFragment>::@prefix::math
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
  type: InvalidType
''');
  }

  test_instanceCreation_explicitNew_prefix_unresolvedClass() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as math;

main() {
  new math.A();
//         ^
// [diag.newWithNonType] The name 'A' isn't a class.
}
''');

    var node = result.findNode.namedType('A();');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: math
    period: .
    element: <testLibraryFragment>::@prefix::math
  name: A
  element: <null>
  type: InvalidType
''');
  }

  test_instanceCreation_explicitNew_resolvedClass() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

main() {
  new A();
}
''');

    var node = result.findNode.namedType('A();');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: <testLibrary>::@class::A
  type: A
''');
  }

  test_instanceCreation_explicitNew_unresolvedClass() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  new A();
//    ^
// [diag.newWithNonType] The name 'A' isn't a class.
}
''');

    var node = result.findNode.namedType('A();');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: <null>
  type: InvalidType
''');
  }

  test_invalid_deferredImportPrefix_identifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async' deferred as async;

void f() {
  async.Future<int> v;
//^^^^^^^^^^^^^^^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'async.Future' can't be used in a declaration, cast, or type test.
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var node = result.findNode.namedType('async.Future<int>');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: async
    period: .
    element: <testLibraryFragment>::@prefix::async
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as prefix;
//                    ^^^^^^
// [context 1] The declaration of 'prefix' is here.

void f(prefix a) {}
//     ^^^^^^
// [diag.notAType][context 1] prefix isn't a type.
''');

    var node = result.findNode.namedType('prefix a');
    assertResolvedNodeText(node, r'''
NamedType
  name: prefix
  element: <testLibraryFragment>::@prefix::prefix
  type: InvalidType
''');
  }

  test_invalid_importPrefix_withTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as prefix;
//                    ^^^^^^
// [context 1] The declaration of 'prefix' is here.

void f(prefix<int> a) {}
//     ^^^^^^
// [diag.notAType][context 1] prefix isn't a type.
''');

    var node = result.findNode.namedType('prefix<int>');
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
  element: <testLibraryFragment>::@prefix::prefix
  type: InvalidType
''');
  }

  test_invalid_prefixedIdentifier_instanceCreation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  new int.double.other();
//    ^^^^^^^^^^
// [diag.newWithNonType] The name 'double' isn't a class.
}
''');

    var node = result.findNode.namedType('int.double');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: int
    period: .
    element: dart:core::@class::int
  name: double
  element: <null>
  type: InvalidType
''');
  }

  test_invalid_prefixedIdentifier_literal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  0 as int.double;
//     ^^^^^^^^^^
// [diag.notAType] int.double isn't a type.
}
''');

    var node = result.findNode.namedType('int.double;');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: int
    period: .
    element: dart:core::@class::int
  name: double
  element: <null>
  type: InvalidType
''');
  }

  test_invalid_topLevelFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(T a) {}
//     ^
// [diag.notAType][context 1] T isn't a type.

void T() {}
//   ^
// [context 1] The declaration of 'T' is here.
''');

    var node = result.findNode.namedType('T a');
    assertResolvedNodeText(node, r'''
NamedType
  name: T
  element: <testLibrary>::@function::T
  type: InvalidType
''');
  }

  test_invalid_topLevelFunction_withTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(T<int> a) {}
//     ^
// [diag.notAType][context 1] T isn't a type.

void T() {}
//   ^
// [context 1] The declaration of 'T' is here.
''');

    var node = result.findNode.namedType('T<int>');
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
  element: <testLibrary>::@function::T
  type: InvalidType
''');
  }

  test_invalid_typeParameter_identifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>(T.name<int> a) {}
//        ^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'T' can't be used here because it's shadowed by a local declaration.
''');

    var node = result.findNode.namedType('T.name<int>');
    assertResolvedNodeText(node, r'''
NamedType
  importPrefix: ImportPrefixReference
    name: T
    period: .
    element: #E0 T
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f(A a) {}
//     ^
// [diag.ambiguousImport] The name 'A' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
''');

    var node = result.findNode.namedType('A a');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: multiplyDefinedElement
    package:test/a.dart::@class::A
    package:test/b.dart::@class::A
  type: InvalidType
''');
  }

  test_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(Never a) {}
''');

    var node = result.findNode.namedType('Never a');
    assertResolvedNodeText(node, r'''
NamedType
  name: Never
  element: Never
  type: Never
''');
  }

  test_typeAlias_asInstanceCreation_explicitNew_typeArguments_interfaceType_none() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

typedef X<T> = A<T>;

void f() {
  new X<int>();
}
''');

    var node = result.findNode.namedType('X<int>()');
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
  element: <testLibrary>::@typeAlias::X
  type: A<int>
''');
  }

  test_typeAlias_asInstanceCreation_implicitNew_toBounds_noTypeParameters_interfaceType_none() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

typedef X = A<int>;

void f() {
  X();
}
''');

    var node = result.findNode.namedType('X()');
    assertResolvedNodeText(node, r'''
NamedType
  name: X
  element: <testLibrary>::@typeAlias::X
  type: A<int>
''');
  }

  test_typeAlias_asInstanceCreation_implicitNew_typeArguments_interfaceType_none() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

typedef X<T> = A<T>;

void f() {
  X<int>();
}
''');

    var node = result.findNode.namedType('X<int>()');
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
  element: <testLibrary>::@typeAlias::X
  type: A<int>
''');
  }

  test_typeAlias_asParameterType_interfaceType_none() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef X<T> = Map<int, T>;
void f(X<String> a, X<String?> b) {}
''');

    var node1 = result.findNode.namedType('X<String>');
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
  element: <testLibrary>::@typeAlias::X
  type: Map<int, String>
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        String
''');

    var node2 = result.findNode.namedType('X<String?>');
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
  element: <testLibrary>::@typeAlias::X
  type: Map<int, String?>
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        String?
''');
  }

  test_typeAlias_asParameterType_interfaceType_question() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef X<T> = List<T?>;
void f(X<int> a, X<int?> b) {}
''');

    var node1 = result.findNode.namedType('X<int>');
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
  element: <testLibrary>::@typeAlias::X
  type: List<int?>
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        int
''');

    var node2 = result.findNode.namedType('X<int?>');
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
  element: <testLibrary>::@typeAlias::X
  type: List<int?>
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        int?
''');
  }

  test_typeAlias_asParameterType_Never_none() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef X = Never;
void f(X a, X? b) {}
''');

    var node1 = result.findNode.namedType('X a');
    assertResolvedNodeText(node1, r'''
NamedType
  name: X
  element: <testLibrary>::@typeAlias::X
  type: Never
    alias: <testLibrary>::@typeAlias::X
''');

    var node2 = result.findNode.namedType('X? b');
    assertResolvedNodeText(node2, r'''
NamedType
  name: X
  question: ?
  element: <testLibrary>::@typeAlias::X
  type: Never?
    alias: <testLibrary>::@typeAlias::X
      nullabilitySuffix: NullabilitySuffix.question
''');
  }

  test_typeAlias_asParameterType_Never_question() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef X = Never?;
void f(X a, X? b) {}
''');

    var node1 = result.findNode.namedType('X a');
    assertResolvedNodeText(node1, r'''
NamedType
  name: X
  element: <testLibrary>::@typeAlias::X
  type: Never?
    alias: <testLibrary>::@typeAlias::X
''');

    var node2 = result.findNode.namedType('X? b');
    assertResolvedNodeText(node2, r'''
NamedType
  name: X
  question: ?
  element: <testLibrary>::@typeAlias::X
  type: Never?
    alias: <testLibrary>::@typeAlias::X
      nullabilitySuffix: NullabilitySuffix.question
''');
  }

  test_typeAlias_asParameterType_question() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef X<T> = T?;
void f(X<int> a) {}
''');

    var node = result.findNode.namedType('X<int>');
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
  element: <testLibrary>::@typeAlias::X
  type: int?
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        int
''');
  }

  test_typeAlias_asReturnType_interfaceType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef X<T> = Map<int, T>;
X<String> f() => {};
''');

    var node = result.findNode.namedType('X<String>');
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
  element: <testLibrary>::@typeAlias::X
  type: Map<int, String>
    alias: <testLibrary>::@typeAlias::X
      typeArguments
        String
''');
  }

  test_typeAlias_asReturnType_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef Nothing = void;
Nothing f() {}
''');

    var node = result.findNode.namedType('Nothing f()');
    assertResolvedNodeText(node, r'''
NamedType
  name: Nothing
  element: <testLibrary>::@typeAlias::Nothing
  type: void
    alias: <testLibrary>::@typeAlias::Nothing
''');
  }

  test_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Unresolved<int> a) {}
//     ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
''');

    var node = result.findNode.namedType('Unresolved<int>');
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
  type: InvalidType
''');
  }

  test_unresolved_identifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(unresolved.List<int> a) {}
//     ^^^^^^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'List'.
''');

    var node = result.findNode.namedType('unresolved.List');
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
  type: InvalidType
''');
  }
}
