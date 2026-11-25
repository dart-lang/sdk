// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithUndefinedConstructorTest);
    defineReflectiveTests(
      NewWithUndefinedConstructorBeforeConstructorTearoffsTest,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NewWithUndefinedConstructorBeforeConstructorTearoffsTest
    extends PubPackageResolutionTest
    with BeforeConstructorTearoffsMixin {
  test_defaultViaNew() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.new() {}
//  ^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
}
f() {
  A();
}
''');
  }

  test_unnamedViaNew() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.named() {}
}
f() {
  A.new();
//  ^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named 'new'.
}
''');
  }

  test_unnamedViaNew_explicitNew() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.named() {}
}
f() {
  new A.new();
//      ^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named 'new'.
}
''');
  }
}

@reflectiveTest
class NewWithUndefinedConstructorTest extends PubPackageResolutionTest
    with NewWithUndefinedConstructorTestCases {}

mixin NewWithUndefinedConstructorTestCases on PubPackageResolutionTest {
  test_default() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.name() {}
}
f() {
  new A();
//    ^
// [diag.newWithUndefinedConstructorDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }

  test_default_noKeyword() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.name() {}
}
f() {
  A();
//^
// [diag.newWithUndefinedConstructorDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }

  test_default_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  A.name() {}
}
''');
    await resolveTestCodeWithDiagnostics('''
import 'lib1.dart' as lib1;

f() {
  new lib1.A();
//    ^^^^^^
// [diag.newWithUndefinedConstructorDefault] The class 'lib1.A' doesn't have an unnamed constructor.
}
''');
  }

  test_default_unnamedViaNew() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.name() {}
}
f() {
  A.new();
//  ^^^
// [diag.newWithUndefinedConstructorDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }

  test_defaultViaNew() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.new() {}
}
f() {
  A();
}
''');
  }

  test_defined_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.name() {}
}
f() {
  new A.name();
}
''');
  }

  test_defined_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
}
f() {
  new A();
}
''');
  }

  test_invalidAlias_invocation_objectMember_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Unknown;
//             ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A<int>.toString();
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: InvalidType
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: InvalidType
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_invalidAlias_invocation_objectMember_selfReference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = List<A<T>>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A<int>.toString();
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: dynamic
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: dynamic
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_named() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A() {}
}
f() {
  new A.name();
//      ^^^^
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named 'name'.
}
''');
  }

  test_named_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  A() {}
}
''');
    await resolveTestCodeWithDiagnostics('''
import 'lib1.dart' as lib1;
f() {
  new lib1.A.name();
//           ^^^^
// [diag.newWithUndefinedConstructor] The class 'lib1.A' doesn't have a constructor named 'name'.
}
''');
  }

  test_named_synthetic() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.named();
}
f() {
  new A.();
//      ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_named_synthetic_hasUnnamed() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A();
}
f() {
  new A.();
//      ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_named_synthetic_noKeyword() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  A.named();
}
f() {
  A.();
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_named_synthetic_noKeyword_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  A.named();
}
''');
    await resolveTestCodeWithDiagnostics('''
import 'lib1.dart' as lib1;
f() {
  lib1.A.();
//       ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_noConstructors_invocation_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension E<T> on T {
  void foo() {}
}

void f() {
  R<int>.foo();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object? {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_objectMember_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

void f() {
  A<int>.toString();
//       ^^^^^^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: dynamic
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: dynamic
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_objectMember_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.toString();
//       ^^^^^^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'F' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
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
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
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
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_objectMember_legacyGenericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void A<T>(T t);

void f() {
  A<int>.toString();
//       ^^^^^^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_objectMember_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

void f() {
  A<int>.toString();
//       ^^^^^^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: Never
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: Never
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_objectMember_nullableRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = (T,)?;

void f() {
  A<int>.toString();
//       ^^^^^^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: (int,)?
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: (int,)?
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_objectMember_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

void f() {
  R<int>.toString();
//       ^^^^^^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'R' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_objectMember_typeVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<X> = X;

void f() {
  A<int>.toString();
//^
// [diag.instantiateTypeAliasExpandsToTypeParameter] Type aliases that expand to a type parameter can't be instantiated.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: InvalidType
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: InvalidType
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_objectMember_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

void f() {
  A<int>.toString();
//       ^^^^^^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: void
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: void
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_prefixed_objectMember_functionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef F<T> = void Function(T);
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.F<int>.toString();
//         ^^^^^^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'p.F' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
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
      type: void Function(int)
        alias: package:test/a.dart::@typeAlias::F
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
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
      type: void Function(int)
        alias: package:test/a.dart::@typeAlias::F
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_prefixed_objectMember_recordType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef R<T> = (T,);
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.R<int>.toString();
//         ^^^^^^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'p.R' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@typeAlias::R
      type: (int,)
        alias: package:test/a.dart::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: toString
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@typeAlias::R
      type: (int,)
        alias: package:test/a.dart::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeArguments_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension E<T> on T {
  void foo<X>() {}
}

void f() {
  R<int>.foo<int>();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'R.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeArguments_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object? {
  void foo<X>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo<int>();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'R.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeArguments_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object {
  void foo<X>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo<int>();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'R.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeArguments_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo<int>();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: dynamic
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: dynamic
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeArguments_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F<int>.foo<int>();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'F.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
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
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
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
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeArguments_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo<int>();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: Never
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: Never
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeArguments_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo<int>();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'R.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeArguments_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo<int>();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: void
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: void
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: dynamic
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: dynamic
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F<int>.foo();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
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
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
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
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: Never
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: Never
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: void
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: void
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.foo();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
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
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
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
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noConstructors_invocation_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

void f() {
  R<int>.foo();
//       ^^^
// [diag.newWithUndefinedConstructorNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_private_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A._named() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  new A._named();
//      ^^^^^^
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named '_named'.
}
''');
  }

  test_private_named_genericClass_noTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A._named() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  new A._named();
//      ^^^^^^
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named '_named'.
}
''');
  }

  test_private_named_genericClass_withTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A._named() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  new A<int>._named();
//           ^^^^^^
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named '_named'.
}
''');
  }
}
