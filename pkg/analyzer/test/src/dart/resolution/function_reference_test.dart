// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionReferenceResolutionTest);
    defineReflectiveTests(
        FunctionReferenceResolutionTest_genericFunctionInstantiation);
    defineReflectiveTests(
        FunctionReferenceResolutionTest_WithoutConstructorTearoffs);
  });
}

@reflectiveTest
class FunctionReferenceResolutionTest extends PubPackageResolutionTest {
  test_constructorFunction_named() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo() {}
}

var x = (A.foo)<int>;
''');

    assertResolvedNodeText(findNode.functionReference('(A.foo)<int>;'), r'''
FunctionReference
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: ConstructorReference
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibraryFragment>::@class::A
          element2: <testLibraryFragment>::@class::A#element
          type: null
        period: .
        name: SimpleIdentifier
          token: foo
          staticElement: <testLibraryFragment>::@class::A::@constructor::foo
          element: <testLibraryFragment>::@class::A::@constructor::foo#element
          staticType: null
        staticElement: <testLibraryFragment>::@class::A::@constructor::foo
        element: <testLibraryFragment>::@class::A::@constructor::foo#element
      staticType: A<T> Function<T>()
    rightParenthesis: )
    staticType: A<T> Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: A<int> Function()
  typeArgumentTypes
    int
''');
  }

  test_constructorFunction_unnamed() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}

var x = (A.new)<int>;
''');

    assertResolvedNodeText(findNode.functionReference('(A.new)<int>;'), r'''
FunctionReference
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: ConstructorReference
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibraryFragment>::@class::A
          element2: <testLibraryFragment>::@class::A#element
          type: null
        period: .
        name: SimpleIdentifier
          token: new
          staticElement: <testLibraryFragment>::@class::A::@constructor::new
          element: <testLibraryFragment>::@class::A::@constructor::new#element
          staticType: null
        staticElement: <testLibraryFragment>::@class::A::@constructor::new
        element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: A<T> Function<T>()
    rightParenthesis: )
    staticType: A<T> Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: A<int> Function()
  typeArgumentTypes
    int
''');
  }

  test_constructorReference() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo() {}
}

var x = A.foo<int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 42,
          5,
          messageContains: ["'A.foo'"]),
    ]);

    assertResolvedNodeText(findNode.functionReference('A.foo<int>;'), r'''
FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibraryFragment>::@class::A
        element2: <testLibraryFragment>::@class::A#element
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@class::A::@constructor::foo
        element: <testLibraryFragment>::@class::A::@constructor::foo#element
        staticType: null
      staticElement: <testLibraryFragment>::@class::A::@constructor::foo
      element: <testLibraryFragment>::@class::A::@constructor::foo#element
    staticType: A<T> Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_constructorReference_prefixed() async {
    await assertErrorsInCode('''
import 'dart:async' as a;
var x = a.Future.delayed<int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 50,
          5,
          messageContains: ["'a.Future.delayed'"]),
    ]);
    assertResolvedNodeText(
        findNode.functionReference('a.Future.delayed<int>;'), r'''
FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        importPrefix: ImportPrefixReference
          name: a
          period: .
          element: <testLibraryFragment>::@prefix::a
          element2: <testLibraryFragment>::@prefix2::a
        name: Future
        element: dart:async::<fragment>::@class::Future
        element2: dart:async::<fragment>::@class::Future#element
        type: null
      period: .
      name: SimpleIdentifier
        token: delayed
        staticElement: dart:async::<fragment>::@class::Future::@constructor::delayed
        element: dart:async::<fragment>::@class::Future::@constructor::delayed#element
        staticType: null
      staticElement: dart:async::<fragment>::@class::Future::@constructor::delayed
      element: dart:async::<fragment>::@class::Future::@constructor::delayed#element
    staticType: Future<T> Function<T>(Duration, [FutureOr<T> Function()?])
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_dynamicTyped() async {
    await assertErrorsInCode('''
dynamic i = 1;

void bar() {
  i<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 31, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('i<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: i
    staticElement: <testLibraryFragment>::@getter::i
    element: <testLibraryFragment>::@getter::i#element
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_dynamicTyped_targetOfMethodCall() async {
    await assertErrorsInCode('''
dynamic i = 1;

void bar() {
  i<int>.foo();
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 31, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('i<int>.foo();'), r'''
FunctionReference
  function: SimpleIdentifier
    token: i
    staticElement: <testLibraryFragment>::@getter::i
    element: <testLibraryFragment>::@getter::i#element
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_explicitReceiver_dynamicTyped() async {
    await assertErrorsInCode('''
dynamic f() => 1;

foo() {
  f().instanceMethod<int>;
}
''', [
      error(CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
          29, 23),
    ]);

    assertResolvedNodeText(
        findNode.functionReference('f().instanceMethod<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: MethodInvocation
      methodName: SimpleIdentifier
        token: f
        staticElement: <testLibraryFragment>::@function::f
        element: <testLibraryFragment>::@function::f#element
        staticType: dynamic Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: instanceMethod
      staticElement: <null>
      element: <null>
      staticType: dynamic
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_explicitReceiver_unknown() async {
    await assertErrorsInCode('''
bar() {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <null>
      element: <null>
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_explicitReceiver_unknown_multipleProperties() async {
    await assertErrorsInCode('''
bar() {
  a.b.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 1),
    ]);

    var node = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        staticElement: <null>
        element: <null>
        staticType: InvalidType
      period: .
      identifier: SimpleIdentifier
        token: b
        staticElement: <null>
        element: <null>
        staticType: InvalidType
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_extension() async {
    await assertErrorsInCode('''
extension E<T> on String {}

void foo() {
  E<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 44, 1),
    ]);

    var reference = findNode.functionReference('E<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: E
    staticElement: <testLibraryFragment>::@extension::E
    element: <testLibraryFragment>::@extension::E#element
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_extension_prefixed() async {
    newFile('$testPackageLibPath/a.dart', '''
extension E<T> on String {}
''');
    await assertErrorsInCode('''
import 'a.dart' as a;

void foo() {
  a.E<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 38, 3),
    ]);

    var reference = findNode.functionReference('E<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@prefix::a
      element: <testLibraryFragment>::@prefix2::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: E
      staticElement: package:test/a.dart::<fragment>::@extension::E
      element: package:test/a.dart::<fragment>::@extension::E#element
      staticType: InvalidType
    staticElement: package:test/a.dart::<fragment>::@extension::E
    element: package:test/a.dart::<fragment>::@extension::E#element
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_extensionGetter_extensionOverride() async {
    await assertErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
}

bar(A a) {
  E(a).foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 67, 8),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::bar::@parameter::a
            element: <testLibraryFragment>::@function::bar::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@getter::foo
      element: <testLibraryFragment>::@extension::E::@getter::foo#element
      staticType: int
    staticType: int
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_extensionMethod() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_explicitReceiver_this() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  void foo<T>(T a) {}

  bar() {
    this.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@method::foo
      element: <testLibraryFragment>::@extension::E::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

extension E on A {
  void foo<T>(T a) {}
}

bar(A a) {
  E(a).foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::bar::@parameter::a
            element: <testLibraryFragment>::@function::bar::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@method::foo
      element: <testLibraryFragment>::@extension::E::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride_cascade() async {
    await assertErrorsInCode('''
class A {
  int foo = 0;
}

extension E on A {
  void foo<T>(T a) {}
}

bar(A a) {
  E(a)..foo<int>;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE, 85, 1),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@method::foo
      element: <testLibraryFragment>::@extension::E::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride_static() async {
    await assertErrorsInCode('''
class A {}

extension E on A {
  static void foo<T>(T a) {}
}

bar(A a) {
  E(a).foo<int>;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER, 81,
          3),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::bar::@parameter::a
            element: <testLibraryFragment>::@function::bar::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@method::foo
      element: <testLibraryFragment>::@extension::E::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride_unknown() async {
    await assertErrorsInCode('''
class A {}

extension E on A {}

bar(A a) {
  E(a).foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER, 51, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::bar::@parameter::a
            element: <testLibraryFragment>::@function::bar::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_extensionMethod_fromClassDeclaration() async {
    await assertNoErrorsInCode('''
class A {
  bar() {
    foo<int>;
  }
}

extension E on A {
  void foo<T>(T a) {}
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_unknown() async {
    await assertErrorsInCode('''
extension on double {
  bar() {
    foo<int>;
  }
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 24, 3),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 36, 3,
          messageContains: ["for the type 'double'"]),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_function_call() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo.call<int>;
}
''');

    assertResolvedNodeText(findNode.functionReference('foo.call<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@function::foo
      element: <testLibraryFragment>::@function::foo#element
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_function_call_tooFewTypeArgs() async {
    await assertErrorsInCode('''
void foo<T, U>(T a, U b) {}

void bar() {
  foo.call<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 52, 5),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo.call<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@function::foo
      element: <testLibraryFragment>::@function::foo#element
      staticType: void Function<T, U>(T, U)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(dynamic, dynamic)
  typeArgumentTypes
    dynamic
    dynamic
''');
  }

  test_function_call_tooManyTypeArgs() async {
    await assertErrorsInCode('''
void foo(String a) {}

void bar() {
  foo.call<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 46, 5),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo.call<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@function::foo
      element: <testLibraryFragment>::@function::foo#element
      staticType: void Function(String)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(String)
''');
  }

  test_function_call_typeArgNotMatchingBound() async {
    await assertNoErrorsInCode('''
void foo<T extends num>(T a) {}

void bar() {
  foo.call<String>;
}
''');

    assertResolvedNodeText(findNode.functionReference('foo.call<String>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@function::foo
      element: <testLibraryFragment>::@function::foo#element
      staticType: void Function<T extends num>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::<fragment>::@class::String
        element2: dart:core::<fragment>::@class::String#element
        type: String
    rightBracket: >
  staticType: void Function(String)
  typeArgumentTypes
    String
''');
  }

  test_function_extensionOnFunction() async {
    // TODO(srawlins): Test extension on function type, like
    // `extension on void Function<T>(T)`.
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo.m<int>;
}

extension on Function {
  void m<T>(T t) {}
}
''');

    assertResolvedNodeText(findNode.functionReference('foo.m<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@function::foo
      element: <testLibraryFragment>::@function::foo#element
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: m
      staticElement: <testLibraryFragment>::@extension::0::@method::m
      element: <testLibraryFragment>::@extension::0::@method::m#element
      staticType: null
    staticElement: <testLibraryFragment>::@extension::0::@method::m
    element: <testLibraryFragment>::@extension::0::@method::m#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_function_extensionOnFunction_static() async {
    await assertErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo.m<int>;
}

extension E on Function {
  static void m<T>(T t) {}
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 40, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo.m<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@function::foo
      element: <testLibraryFragment>::@function::foo#element
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: m
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_implicitCallTearoff() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

foo() {
  C()<int>;
}
''');

    var node = findNode.implicitCallReference('C()<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibraryFragment>::@class::C
        element2: <testLibraryFragment>::@class::C#element
        type: C
      staticElement: <testLibraryFragment>::@class::C::@constructor::new
      element: <testLibraryFragment>::@class::C::@constructor::new#element
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticElement: <testLibraryFragment>::@class::C::@method::call
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallTearoff_class_staticGetter() async {
    await assertNoErrorsInCode('''
class C {
  static const v = C();
  const C();
  T call<T>(T t) => t;
}

void f() {
  C.v<int>;
}
''');

    var node = findNode.implicitCallReference('C.v<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      staticElement: <testLibraryFragment>::@class::C
      element: <testLibraryFragment>::@class::C#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: v
      staticElement: <testLibraryFragment>::@class::C::@getter::v
      element: <testLibraryFragment>::@class::C::@getter::v#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::C::@getter::v
    element: <testLibraryFragment>::@class::C::@getter::v#element
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticElement: <testLibraryFragment>::@class::C::@method::call
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallTearoff_extensionOnNullable() async {
    await assertNoErrorsInCode('''
Object? v = null;
extension E on Object? {
  void call<R, S>(R r, S s) {}
}
void foo() {
  v<int, String>;
}

''');

    var node = findNode.implicitCallReference('v<int, String>;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: v
    staticElement: <testLibraryFragment>::@getter::v
    element: <testLibraryFragment>::@getter::v#element
    staticType: Object?
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
      NamedType
        name: String
        element: dart:core::<fragment>::@class::String
        element2: dart:core::<fragment>::@class::String#element
        type: String
    rightBracket: >
  staticElement: <testLibraryFragment>::@extension::E::@method::call
  element: <testLibraryFragment>::@extension::E::@method::call#element
  staticType: void Function(int, String)
  typeArgumentTypes
    int
    String
''');
  }

  test_implicitCallTearoff_extensionType() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  void call() {}
}

void g(Function f) {}

void f(A a) {
  g(a);
}
''');

    var node = findNode.implicitCallReference('a);');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  parameter: <testLibraryFragment>::@function::g::@parameter::f
  staticElement: <testLibraryFragment>::@extensionType::A::@method::call
  element: <testLibraryFragment>::@extensionType::A::@method::call#element
  staticType: void Function()
''');
  }

  test_implicitCallTearoff_prefix_class_staticGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static const v = C();
  const C();
  T call<T>(T t) => t;
}
''');

    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

void f() {
  prefix.C.v<int>;
}
''');

    var node = findNode.implicitCallReference('C.v<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: <testLibraryFragment>::@prefix::prefix
        element: <testLibraryFragment>::@prefix2::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        staticElement: package:test/a.dart::<fragment>::@class::C
        element: package:test/a.dart::<fragment>::@class::C#element
        staticType: null
      staticElement: package:test/a.dart::<fragment>::@class::C
      element: package:test/a.dart::<fragment>::@class::C#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: v
      staticElement: package:test/a.dart::<fragment>::@class::C::@getter::v
      element: package:test/a.dart::<fragment>::@class::C::@getter::v#element
      staticType: C
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticElement: package:test/a.dart::<fragment>::@class::C::@method::call
  element: package:test/a.dart::<fragment>::@class::C::@method::call#element
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallTearoff_prefixed() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {
  T call<T>(T t) => t;
}
C c = C();
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.c<int>;
}
''');

    var node = findNode.implicitCallReference('c<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: c
      staticElement: package:test/a.dart::<fragment>::@getter::c
      element: package:test/a.dart::<fragment>::@getter::c#element
      staticType: C
    staticElement: package:test/a.dart::<fragment>::@getter::c
    element: package:test/a.dart::<fragment>::@getter::c#element
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticElement: package:test/a.dart::<fragment>::@class::C::@method::call
  element: package:test/a.dart::<fragment>::@class::C::@method::call#element
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallTearoff_tooFewTypeArguments() async {
    await assertErrorsInCode('''
class C {
  void call<T, U>(T t, U u) {}
}

foo() {
  C()<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 57, 5),
    ]);

    var node = findNode.implicitCallReference('C()<int>;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibraryFragment>::@class::C
        element2: <testLibraryFragment>::@class::C#element
        type: C
      staticElement: <testLibraryFragment>::@class::C::@constructor::new
      element: <testLibraryFragment>::@class::C::@constructor::new#element
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticElement: <testLibraryFragment>::@class::C::@method::call
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(dynamic, dynamic)
  typeArgumentTypes
    dynamic
    dynamic
''');
  }

  test_implicitCallTearoff_tooManyTypeArguments() async {
    await assertErrorsInCode('''
class C {
  int call(int t) => t;
}

foo() {
  C()<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 50, 5),
    ]);

    var node = findNode.implicitCallReference('C()<int>;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibraryFragment>::@class::C
        element2: <testLibraryFragment>::@class::C#element
        type: C
      staticElement: <testLibraryFragment>::@class::C::@constructor::new
      element: <testLibraryFragment>::@class::C::@constructor::new#element
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticElement: <testLibraryFragment>::@class::C::@method::call
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: int Function(int)
''');
  }

  test_instanceGetter_explicitReceiver() async {
    await assertNoErrorsInCode('''
class A {
  late void Function<T>(T) foo;
}

bar(A a) {
  a.foo<int>;
}
''');

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::bar::@parameter::a
      element: <testLibraryFragment>::@function::bar::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceGetter_functionTyped() async {
    await assertNoErrorsInCode('''
abstract class A {
  late void Function<T>(T) foo;

  bar() {
    foo<int>;
  }
}

''');

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceGetter_functionTyped_inherited() async {
    await assertNoErrorsInCode('''
abstract class A {
  late void Function<T>(T) foo;
}
abstract class B extends A {
  bar() {
    foo<int>;
  }
}

''');

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceGetter_nonFunctionType() async {
    await assertErrorsInCode('''
abstract class A {
  List<int> get f;
}

void foo(A a) {
  a.f<String>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 61, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('f<String>'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::foo::@parameter::a
      element: <testLibraryFragment>::@function::foo::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@class::A::@getter::f
      element: <testLibraryFragment>::@class::A::@getter::f#element
      staticType: List<int>
    staticElement: <testLibraryFragment>::@class::A::@getter::f
    element: <testLibraryFragment>::@class::A::@getter::f#element
    staticType: List<int>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::<fragment>::@class::String
        element2: dart:core::<fragment>::@class::String#element
        type: String
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceGetter_nonFunctionType_propertyAccess() async {
    await assertErrorsInCode('''
abstract class A {
  List<int> get f;
}

void foo(A a) {
  (a).f<String>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 63, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('f<String>'), r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: <testLibraryFragment>::@function::foo::@parameter::a
        element: <testLibraryFragment>::@function::foo::@parameter::a#element
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@class::A::@getter::f
      element: <testLibraryFragment>::@class::A::@getter::f#element
      staticType: List<int>
    staticType: List<int>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::<fragment>::@class::String
        element2: dart:core::<fragment>::@class::String#element
        type: String
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_call() async {
    await assertNoErrorsInCode('''
class C {
  void foo<T>(T a) {}

  void bar() {
    foo.call<int>;
  }
}
''');

    var reference = findNode.functionReference('foo.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::C::@method::foo
      element: <testLibraryFragment>::@class::C::@method::foo#element
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_call() async {
    await assertNoErrorsInCode('''
class C {
  void foo<T>(T a) {}
}

void bar(C c) {
  c.foo.call<int>;
}
''');

    var reference = findNode.functionReference('foo.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: c
        staticElement: <testLibraryFragment>::@function::bar::@parameter::c
        element: <testLibraryFragment>::@function::bar::@parameter::c#element
        staticType: C
      period: .
      identifier: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@class::C::@method::foo
        element: <testLibraryFragment>::@class::C::@method::foo#element
        staticType: void Function<T>(T)
      staticElement: <testLibraryFragment>::@class::C::@method::foo
      element: <testLibraryFragment>::@class::C::@method::foo#element
      staticType: void Function<T>(T)
    operator: .
    propertyName: SimpleIdentifier
      token: call
      staticElement: <null>
      element: <null>
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_field() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

class B {
  A a;
  B(this.a);
  bar() {
    a.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@class::B::@getter::a
      element: <testLibraryFragment>::@class::B::@getter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_getter_wrongNumberOfTypeArguments() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(A a) {
  // Extra `()` to force reading the type.
  ((a).foo<double>);
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 97, 3),
    ]);

    var reference = findNode.functionReference('foo<double>');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: int
    staticType: int
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: double
        element: dart:core::<fragment>::@class::double
        element2: dart:core::<fragment>::@class::double#element
        type: double
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod_explicitReceiver_otherExpression() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

void f(A? a, A b) {
  (a ?? b).foo<int>;
}
''');

    assertResolvedNodeText(
        findNode.functionReference('(a ?? b).foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A?
        operator: ??
        rightOperand: SimpleIdentifier
          token: b
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::b
          element: <testLibraryFragment>::@function::f::@parameter::b#element
          staticType: A
        staticElement: <null>
        element: <null>
        staticInvokeType: null
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_parameter_promoted() async {
    // Based on https://github.com/dart-lang/sdk/issues/51853.
    await assertNoErrorsInCode('''
void f(num x) {
  if (x is int) {
    x.expectStaticType<Exactly<int>>;
  }
}

extension StaticType<T> on T {
  void expectStaticType<X extends Exactly<T>>() {}
}

typedef Exactly<T> = T Function(T);
''');

    var reference =
        findNode.functionReference('expectStaticType<Exactly<int>>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: int
    period: .
    identifier: SimpleIdentifier
      token: expectStaticType
      staticElement: MethodMember
        base: <testLibraryFragment>::@extension::StaticType::@method::expectStaticType
        substitution: {T: int, X: X}
      element: <testLibraryFragment>::@extension::StaticType::@method::expectStaticType#element
      staticType: null
    staticElement: MethodMember
      base: <testLibraryFragment>::@extension::StaticType::@method::expectStaticType
      substitution: {T: int, X: X}
    element: <testLibraryFragment>::@extension::StaticType::@method::expectStaticType#element
    staticType: void Function<X extends int Function(int)>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: Exactly
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
          rightBracket: >
        element: <testLibraryFragment>::@typeAlias::Exactly
        element2: <testLibraryFragment>::@typeAlias::Exactly#element
        type: int Function(int)
          alias: <testLibraryFragment>::@typeAlias::Exactly
            typeArguments
              int
    rightBracket: >
  staticType: void Function()
  typeArgumentTypes
    int Function(int)
      alias: <testLibraryFragment>::@typeAlias::Exactly
        typeArguments
          int
''');
  }

  test_instanceMethod_explicitReceiver_receiverIsNotIdentifier_call() async {
    await assertNoErrorsInCode('''
extension on List<Object?> {
  void foo<T>(T a) {}
}

var a = [].foo.call<int>;
''');

    var reference = findNode.functionReference('foo.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PropertyAccess
      target: ListLiteral
        leftBracket: [
        rightBracket: ]
        staticType: List<dynamic>
      operator: .
      propertyName: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@extension::0::@method::foo
        element: <testLibraryFragment>::@extension::0::@method::foo#element
        staticType: void Function<T>(T)
      staticType: void Function<T>(T)
    operator: .
    propertyName: SimpleIdentifier
      token: call
      staticElement: <null>
      element: <null>
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_super() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}
class B extends A {
  bar() {
    super.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_super_noMethod() async {
    await assertErrorsInCode('''
class A {
  bar() {
    super.foo<int>;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_GETTER, 30, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod_explicitReceiver_super_noSuper() async {
    await assertErrorsInCode('''
bar() {
  super.foo<int>;
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 10, 5),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod_explicitReceiver_targetOfFunctionCall() async {
    await assertNoErrorsInCode('''
extension on Function {
  void m() {}
}
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a.foo<int>.m();
}
''');

    var reference = findNode.functionReference('foo<int>');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::bar::@parameter::a
      element: <testLibraryFragment>::@function::bar::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_this() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    this.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_topLevelVariable() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}
var a = A();

void bar() {
  a.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@getter::a
      element: <testLibraryFragment>::@getter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_topLevelVariable_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  void foo<T>(T a) {}
}
var a = A();
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: <testLibraryFragment>::@prefix::prefix
        element: <testLibraryFragment>::@prefix2::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: a
        staticElement: package:test/a.dart::<fragment>::@getter::a
        element: package:test/a.dart::<fragment>::@getter::a#element
        staticType: A
      staticElement: package:test/a.dart::<fragment>::@getter::a
      element: package:test/a.dart::<fragment>::@getter::a#element
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@class::A::@method::foo
      element: package:test/a.dart::<fragment>::@class::A::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_topLevelVariable_prefix_unknown() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
var a = A();
''');
    await assertErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 47, 3),
    ]);

    var node = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: <testLibraryFragment>::@prefix::prefix
        element: <testLibraryFragment>::@prefix2::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: a
        staticElement: package:test/a.dart::<fragment>::@getter::a
        element: package:test/a.dart::<fragment>::@getter::a#element
        staticType: A
      staticElement: package:test/a.dart::<fragment>::@getter::a
      element: package:test/a.dart::<fragment>::@getter::a#element
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod_explicitReceiver_typeParameter() async {
    await assertErrorsInCode('''
bar<T>() {
  T.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 15, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: T
      staticElement: T@4
      element: <not-implemented>
      staticType: Type
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod_explicitReceiver_variable() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::bar::@parameter::a
      element: <testLibraryFragment>::@function::bar::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_variable_cascade() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a..foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_variable_promoted() async {
    // Based on https://github.com/dart-lang/sdk/issues/51853.
    await assertNoErrorsInCode('''
void f(num n) {
  num x = n;
  if (x is int) {
    x.expectStaticType<Exactly<int>>;
  }
}

extension StaticType<T> on T {
  void expectStaticType<X extends Exactly<T>>() {}
}

typedef Exactly<T> = T Function(T);
''');

    var reference =
        findNode.functionReference('expectStaticType<Exactly<int>>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
      staticElement: x@22
      element: x@22
      staticType: int
    period: .
    identifier: SimpleIdentifier
      token: expectStaticType
      staticElement: MethodMember
        base: <testLibraryFragment>::@extension::StaticType::@method::expectStaticType
        substitution: {T: int, X: X}
      element: <testLibraryFragment>::@extension::StaticType::@method::expectStaticType#element
      staticType: null
    staticElement: MethodMember
      base: <testLibraryFragment>::@extension::StaticType::@method::expectStaticType
      substitution: {T: int, X: X}
    element: <testLibraryFragment>::@extension::StaticType::@method::expectStaticType#element
    staticType: void Function<X extends int Function(int)>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: Exactly
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
          rightBracket: >
        element: <testLibraryFragment>::@typeAlias::Exactly
        element2: <testLibraryFragment>::@typeAlias::Exactly#element
        type: int Function(int)
          alias: <testLibraryFragment>::@typeAlias::Exactly
            typeArguments
              int
    rightBracket: >
  staticType: void Function()
  typeArgumentTypes
    int Function(int)
      alias: <testLibraryFragment>::@typeAlias::Exactly
        typeArguments
          int
''');
  }

  test_instanceMethod_inherited() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

class B extends A {
  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_targetOfFunctionCall() async {
    await assertNoErrorsInCode('''
extension on Function {
  void m() {}
}
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int>.m();
  }
}
''');

    var reference = findNode.functionReference('foo<int>');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_unknown() async {
    await assertErrorsInCode('''
class A {
  bar() {
    foo<int>;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 24, 3,
          messageContains: ["for the type 'A'"]),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_loadLibrary() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertErrorsInCode('''
import 'a.dart' deferred as prefix;

void f() {
  prefix.loadLibrary;
}
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 8),
    ]);

    var node = findNode.expressionStatement('prefix.loadLibrary');
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: loadLibrary
      staticElement: loadLibrary@-1
      element: loadLibrary@-1
      staticType: Future<dynamic> Function()
    staticElement: loadLibrary@-1
    element: loadLibrary@-1
    staticType: Future<dynamic> Function()
  semicolon: ;
''');
  }

  test_localFunction() async {
    await assertNoErrorsInCode('''
void bar() {
  void foo<T>(T a) {}

  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: foo@20
    element: foo@20
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable() async {
    await assertNoErrorsInCode('''
void bar(void Function<T>(T a) foo) {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::bar::@parameter::foo
    element: <testLibraryFragment>::@function::bar::@parameter::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable_call() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  var fn = foo;
  fn.call<int>;
}
''');

    var reference = findNode.functionReference('fn.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: fn
      staticElement: fn@40
      element: fn@40
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable_call_tooManyTypeArgs() async {
    await assertErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  void Function(int) fn = foo;
  fn.call<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 74, 5),
    ]);

    var reference = findNode.functionReference('fn.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('fn')` here, we must change the
    // policy over there.
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: fn
      staticElement: fn@55
      element: fn@55
      staticType: void Function(int)
    period: .
    identifier: SimpleIdentifier
      token: call
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: void Function(int)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
''');
  }

  test_localVariable_typeVariable_boundToFunction() async {
    await assertErrorsInCode('''
void bar<T extends Function>(T foo) {
  foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 40, 3),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::bar::@parameter::foo
    element: <testLibraryFragment>::@function::bar::@parameter::foo#element
    staticType: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_localVariable_typeVariable_functionTyped() async {
    await assertNoErrorsInCode('''
void bar<T extends void Function<U>(U)>(T foo) {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::bar::@parameter::foo
    element: <testLibraryFragment>::@function::bar::@parameter::foo#element
    staticType: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable_typeVariable_nonFunction() async {
    await assertErrorsInCode('''
void bar<T>(T foo) {
  foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 23, 3),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::bar::@parameter::foo
    element: <testLibraryFragment>::@function::bar::@parameter::foo#element
    staticType: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_neverTyped() async {
    await assertErrorsInCode('''
external Never get i;

void bar() {
  i<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 38, 1),
    ]);

    assertResolvedNodeText(findNode.functionReference('i<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: i
    staticElement: <testLibraryFragment>::@getter::i
    element: <testLibraryFragment>::@getter::i#element
    staticType: Never
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_nonGenericFunction() async {
    await assertErrorsInCode('''
class A {
  void foo() {}

  bar() {
    foo<int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 44, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function()
''');
  }

  test_otherExpression() async {
    await assertNoErrorsInCode('''
void f(void Function<T>(T a) foo, void Function<T>(T a) bar) {
  (1 == 2 ? foo : bar)<int>;
}
''');

    var reference = findNode.functionReference('(1 == 2 ? foo : bar)<int>;');
    assertType(reference, 'void Function(int)');
    // A ParenthesizedExpression has no element to assert on.
  }

  test_otherExpression_wrongNumberOfTypeArguments() async {
    await assertErrorsInCode('''
void f(void Function<T>(T a) foo, void Function<T>(T a) bar) {
  (1 == 2 ? foo : bar)<int, String>;
}
''', [
      error(
          CompileTimeErrorCode
              .WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION,
          85,
          13),
    ]);

    var reference =
        findNode.functionReference('(1 == 2 ? foo : bar)<int, String>;');
    assertType(reference, 'void Function(dynamic)');
    // A ParenthesizedExpression has no element to assert on.
  }

  test_receiverIsDynamic() async {
    await assertErrorsInCode('''
bar(dynamic a) {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
          19, 5),
    ]);

    assertResolvedNodeText(findNode.functionReference('a.foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::bar::@parameter::a
      element: <testLibraryFragment>::@function::bar::@parameter::a#element
      staticType: dynamic
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_recordField_explicitReceiver_named() async {
    await assertErrorsInCode(r'''
void f(({T Function<T>(T) f1, String f2}) r) {
  int Function(int) v = r.f1;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 67, 1),
    ]);

    var node = findNode.functionReference(r'.f1;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({T Function<T>(T) f1, String f2})
    operator: .
    propertyName: SimpleIdentifier
      token: f1
      staticElement: <null>
      element: <null>
      staticType: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_recordField_explicitReceiver_positional() async {
    await assertErrorsInCode(r'''
void f((T Function<T>(T), String) r) {
  int Function(int) v = r.$1;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 59, 1),
    ]);

    var node = findNode.functionReference(r'.$1;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: (T Function<T>(T), String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      element: <null>
      staticType: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}
}

bar() {
  A.foo<int>;
}
''');

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static void foo<T>(T a) {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

bar() {
  a.A.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        staticElement: <testLibraryFragment>::@prefix::a
        element: <testLibraryFragment>::@prefix2::a
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: package:test/a.dart::<fragment>::@class::A
        element: package:test/a.dart::<fragment>::@class::A#element
        staticType: null
      staticElement: package:test/a.dart::<fragment>::@class::A
      element: package:test/a.dart::<fragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@class::A::@method::foo
      element: package:test/a.dart::<fragment>::@class::A::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static void foo<T>(T a) {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.A.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: <testLibraryFragment>::@prefix::prefix
        element: <testLibraryFragment>::@prefix2::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: package:test/a.dart::<fragment>::@class::A
        element: package:test/a.dart::<fragment>::@class::A#element
        staticType: null
      staticElement: package:test/a.dart::<fragment>::@class::A
      element: package:test/a.dart::<fragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@class::A::@method::foo
      element: package:test/a.dart::<fragment>::@class::A::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver_prefix_typeAlias() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static void foo<T>(T a) {}
}
typedef TA = A;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.TA.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: <testLibraryFragment>::@prefix::prefix
        element: <testLibraryFragment>::@prefix2::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: TA
        staticElement: package:test/a.dart::<fragment>::@typeAlias::TA
        element: package:test/a.dart::<fragment>::@typeAlias::TA#element
        staticType: Type
      staticElement: package:test/a.dart::<fragment>::@typeAlias::TA
      element: package:test/a.dart::<fragment>::@typeAlias::TA#element
      staticType: Type
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@class::A::@method::foo
      element: package:test/a.dart::<fragment>::@class::A::@method::foo#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver_typeAlias() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}
}
typedef TA = A;

bar() {
  TA.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: TA
      staticElement: <testLibraryFragment>::@typeAlias::TA
      element: <testLibraryFragment>::@typeAlias::TA#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_superExpression() async {
    await assertErrorsInCode(r'''
class A {
  void call<T>() {}
}

class B extends A {
  void f() {
    super<int>;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 70, 5),
    ]);

    var node = findNode.singleImplicitCallReference;
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SuperExpression
    superKeyword: super
    staticType: B
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticElement: <testLibraryFragment>::@class::A::@method::call
  element: <testLibraryFragment>::@class::A::@method::call#element
  staticType: void Function()
  typeArgumentTypes
    int
''');
  }

  test_tooFewTypeArguments() async {
    await assertErrorsInCode('''
class A {
  void foo<T, U>(T a, U b) {}

  bar() {
    foo<int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 58, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T, U>(T, U)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(dynamic, dynamic)
  typeArgumentTypes
    dynamic
    dynamic
''');
  }

  test_tooManyTypeArguments() async {
    await assertErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int, int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 50, 10),
    ]);

    var reference = findNode.functionReference('foo<int, int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(dynamic)
  typeArgumentTypes
    dynamic
''');
  }

  test_topLevelFunction() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelFunction_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
void foo<T>(T arg) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

void bar() {
  a.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@prefix::a
      element: <testLibraryFragment>::@prefix2::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@function::foo
      element: package:test/a.dart::<fragment>::@function::foo#element
      staticType: void Function<T>(T)
    staticElement: package:test/a.dart::<fragment>::@function::foo
    element: package:test/a.dart::<fragment>::@function::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelFunction_importPrefix_asTargetOfFunctionCall() async {
    newFile('$testPackageLibPath/a.dart', '''
void foo<T>(T arg) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

extension on Function {
  void m() {}
}
void bar() {
  a.foo<int>.m();
}
''');

    var reference = findNode.functionReference('foo<int>');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@prefix::a
      element: <testLibraryFragment>::@prefix2::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@function::foo
      element: package:test/a.dart::<fragment>::@function::foo#element
      staticType: void Function<T>(T)
    staticElement: package:test/a.dart::<fragment>::@function::foo
    element: package:test/a.dart::<fragment>::@function::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelFunction_prefix_unknownPrefix() async {
    await assertErrorsInCode('''
bar() {
  prefix.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 6),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: <null>
      element: <null>
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_topLevelFunction_targetOfCall() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo<int>.call;
}
''');

    var node = findNode.propertyAccess('.call');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: FunctionReference
    function: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@function::foo
      element: <testLibraryFragment>::@function::foo#element
      staticType: void Function<T>(T)
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    staticType: void Function(int)
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: call
    staticElement: <null>
    element: <null>
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }

  test_topLevelFunction_targetOfFunctionCall() async {
    await assertNoErrorsInCode('''
void foo<T>(T arg) {}

extension on Function {
  void m() {}
}
void bar() {
  foo<int>.m();
}
''');

    assertResolvedNodeText(findNode.functionReference('foo<int>'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelVariable_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
void Function<T>(T) foo = <T>(T arg) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.foo<int>;
}
''');

    var node = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@getter::foo
      element: package:test/a.dart::<fragment>::@getter::foo#element
      staticType: void Function<T>(T)
    staticElement: package:test/a.dart::<fragment>::@getter::foo
    element: package:test/a.dart::<fragment>::@getter::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelVariable_prefix_unknownIdentifier() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 45, 1),
    ]);

    var node = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: <testLibraryFragment>::@prefix::prefix
        element: <testLibraryFragment>::@prefix2::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: a
        staticElement: <null>
        element: <null>
        staticType: InvalidType
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_typeAlias_function_unknownProperty() async {
    await assertErrorsInCode('''
typedef Cb = void Function();

var a = Cb.foo<int>;
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 42, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: Cb
      staticElement: <testLibraryFragment>::@typeAlias::Cb
      element: <testLibraryFragment>::@typeAlias::Cb#element
      staticType: Type
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_typeAlias_typeVariable_unknownProperty() async {
    await assertErrorsInCode('''
typedef T<E> = E;

var a = T.foo<int>;
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 29, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: T
      staticElement: <testLibraryFragment>::@typeAlias::T
      element: <testLibraryFragment>::@typeAlias::T#element
      staticType: Type
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_unknownIdentifier() async {
    await assertErrorsInCode('''
void bar() {
  foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 15, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_unknownIdentifier_explicitReceiver() async {
    await assertErrorsInCode('''
class A {}

class B {
  bar(A a) {
    a.foo<int>;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 41, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@class::B::@method::bar::@parameter::a
      element: <testLibraryFragment>::@class::B::@method::bar::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_unknownIdentifier_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertErrorsInCode('''
import 'a.dart' as a;

void bar() {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 40, 3),
    ]);

    assertResolvedNodeText(findNode.functionReference('foo<int>;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@prefix::a
      element: <testLibraryFragment>::@prefix2::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }
}

@reflectiveTest
class FunctionReferenceResolutionTest_genericFunctionInstantiation
    extends PubPackageResolutionTest {
  test_asExpression() async {
    await assertNoErrorsInCode('''
void Function(int) foo(void Function<T>(T) f) {
  return (f as dynamic) as void Function<T>(T);
}
''');

    assertResolvedNodeText(
        findNode.functionReference('as void Function<T>(T);'), r'''
FunctionReference
  function: AsExpression
    expression: ParenthesizedExpression
      leftParenthesis: (
      expression: AsExpression
        expression: SimpleIdentifier
          token: f
          staticElement: <testLibraryFragment>::@function::foo::@parameter::f
          element: <testLibraryFragment>::@function::foo::@parameter::f#element
          staticType: void Function<T>(T)
        asOperator: as
        type: NamedType
          name: dynamic
          element: dynamic@-1
          element2: dynamic@-1
          type: dynamic
        staticType: dynamic
      rightParenthesis: )
      staticType: dynamic
    asOperator: as
    type: GenericFunctionType
      returnType: NamedType
        name: void
        element: <null>
        element2: <null>
        type: void
      functionKeyword: Function
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: T@89
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: T
            element: T@89
            element2: <not-implemented>
            type: T
          declaredElement: @-1
            type: T
        rightParenthesis: )
      declaredElement: GenericFunctionTypeElement
        parameters
          <empty>
            kind: required positional
            type: T
        returnType: void
        type: void Function<T>(T)
      type: void Function<T>(T)
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_assignmentExpression() async {
    await assertNoErrorsInCode('''
late void Function<T>(T) g;
void Function(int) foo(void Function<T>(T) f) {
  return g = f;
}
''');

    assertResolvedNodeText(findNode.functionReference('g = f;'), r'''
FunctionReference
  function: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: g
      staticElement: <null>
      element: <null>
      staticType: null
    operator: =
    rightHandSide: SimpleIdentifier
      token: f
      parameter: <testLibraryFragment>::@setter::g::@parameter::_g
      staticElement: <testLibraryFragment>::@function::foo::@parameter::f
      element: <testLibraryFragment>::@function::foo::@parameter::f#element
      staticType: void Function<T>(T)
    readElement: <null>
    readElement2: <null>
    readType: null
    writeElement: <testLibraryFragment>::@setter::g
    writeElement2: <testLibraryFragment>::@setter::g#element
    writeType: void Function<T>(T)
    staticElement: <null>
    element: <null>
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_assignmentExpression_compound() async {
    await assertNoErrorsInCode('''
extension on void Function<T>(T) {
  void Function<T>(T) operator +(int i) {
    return this;
  }
}

void Function(int) foo(void Function<T>(T) f) {
  return f += 1;
}
''');

    assertResolvedNodeText(findNode.functionReference('f += 1'), r'''
FunctionReference
  function: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::foo::@parameter::f
      element: <testLibraryFragment>::@function::foo::@parameter::f#element
      staticType: null
    operator: +=
    rightHandSide: IntegerLiteral
      literal: 1
      parameter: <testLibraryFragment>::@extension::0::@method::+::@parameter::i
      staticType: int
    readElement: <testLibraryFragment>::@function::foo::@parameter::f
    readElement2: <testLibraryFragment>::@function::foo::@parameter::f#element
    readType: void Function<T>(T)
    writeElement: <testLibraryFragment>::@function::foo::@parameter::f
    writeElement2: <testLibraryFragment>::@function::foo::@parameter::f#element
    writeType: void Function<T>(T)
    staticElement: <testLibraryFragment>::@extension::0::@method::+
    element: <testLibraryFragment>::@extension::0::@method::+#element
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_awaitExpression() async {
    await assertNoErrorsInCode('''
Future<void Function(int)> foo(Future<void Function<T>(T)> f) async {
  return await f;
}
''');

    assertResolvedNodeText(findNode.functionReference('await f'), r'''
FunctionReference
  function: AwaitExpression
    awaitKeyword: await
    expression: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::foo::@parameter::f
      element: <testLibraryFragment>::@function::foo::@parameter::f#element
      staticType: Future<void Function<T>(T)>
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_binaryExpression() async {
    await assertNoErrorsInCode('''
class C {
  void Function<T>(T) operator +(int i) {
    return <T>(T a) {};
  }
}

void Function(int) foo(C c) {
  return c + 1;
}
''');

    assertResolvedNodeText(findNode.functionReference('c + 1'), r'''
FunctionReference
  function: BinaryExpression
    leftOperand: SimpleIdentifier
      token: c
      staticElement: <testLibraryFragment>::@function::foo::@parameter::c
      element: <testLibraryFragment>::@function::foo::@parameter::c#element
      staticType: C
    operator: +
    rightOperand: IntegerLiteral
      literal: 1
      parameter: <testLibraryFragment>::@class::C::@method::+::@parameter::i
      staticType: int
    staticElement: <testLibraryFragment>::@class::C::@method::+
    element: <testLibraryFragment>::@class::C::@method::+#element
    staticInvokeType: void Function<T>(T) Function(int)
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_cascadeExpression() async {
    await assertNoErrorsInCode('''
void Function(int) foo(void Function<T>(T) f) {
  return f..toString();
}
''');

    assertResolvedNodeText(findNode.functionReference('f..toString()'), r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::foo::@parameter::f
    element: <testLibraryFragment>::@function::foo::@parameter::f#element
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_constructorReference() async {
    await assertNoErrorsInCode('''
class C<T> {
  C(T a);
}
C<int> Function(int) foo() {
  return C.new;
}
''');

    // TODO(srawlins): Leave the constructor reference uninstantiated, then
    // perform generic function instantiation as a wrapping node.
    assertResolvedNodeText(findNode.constructorReference('C.new'), r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: C
      element: <testLibraryFragment>::@class::C
      element2: <testLibraryFragment>::@class::C#element
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: <testLibraryFragment>::@class::C::@constructor::new
      element: <testLibraryFragment>::@class::C::@constructor::new#element
      staticType: null
      tearOffTypeArgumentTypes
        int
    staticElement: <testLibraryFragment>::@class::C::@constructor::new
    element: <testLibraryFragment>::@class::C::@constructor::new#element
  staticType: C<int> Function(int)
''');
  }

  test_functionExpression() async {
    await assertNoErrorsInCode('''
Null Function(int) foo() {
  return <T>(T a) {};
}
''');

    assertResolvedNodeText(findNode.functionReference('<T>(T a) {};'), r'''
FunctionReference
  function: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredElement: T@37
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: T
          element: T@37
          element2: <not-implemented>
          type: T
        name: a
        declaredElement: @36::@parameter::a
          type: T
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredElement: @36
      type: Null Function<T>(T)
    staticType: Null Function<T>(T)
  staticType: Null Function(int)
  typeArgumentTypes
    int
''');
  }

  test_functionExpressionInvocation() async {
    await assertNoErrorsInCode('''
void Function(int) foo(void Function<T>(T) Function() f) {
  return (f)();
}
''');

    assertResolvedNodeText(findNode.functionReference('(f)()'), r'''
FunctionReference
  function: FunctionExpressionInvocation
    function: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: f
        staticElement: <testLibraryFragment>::@function::foo::@parameter::f
        element: <testLibraryFragment>::@function::foo::@parameter::f#element
        staticType: void Function<T>(T) Function()
      rightParenthesis: )
      staticType: void Function<T>(T) Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    element: <null>
    staticInvokeType: void Function<T>(T) Function()
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_functionReference() async {
    await assertNoErrorsInCode('''
typedef Fn = void Function<U>(U);

void Function(int) foo(Fn f) {
  return f;
}
''');

    assertResolvedNodeText(findNode.functionReference('f;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::foo::@parameter::f
    element: <testLibraryFragment>::@function::foo::@parameter::f#element
    staticType: void Function<U>(U)
      alias: <testLibraryFragment>::@typeAlias::Fn
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallReference() async {
    await assertNoErrorsInCode('''
class C {
  void call<T>(T a) {}
}

void Function(int) foo(C c) {
  return c;
}
''');

    var node = findNode.implicitCallReference('c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::foo::@parameter::c
    element: <testLibraryFragment>::@function::foo::@parameter::c#element
    staticType: C
  staticElement: <testLibraryFragment>::@class::C::@method::call
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_indexExpression() async {
    await assertNoErrorsInCode('''
void Function(int) foo(List<void Function<T>(T)> f) {
  return f[0];
}
''');

    assertResolvedNodeText(findNode.functionReference('f[0];'), r'''
FunctionReference
  function: IndexExpression
    target: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::foo::@parameter::f
      element: <testLibraryFragment>::@function::foo::@parameter::f#element
      staticType: List<void Function<T>(T)>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: ParameterMember
        base: dart:core::<fragment>::@class::List::@method::[]::@parameter::index
        substitution: {E: void Function<T>(T)}
      staticType: int
    rightBracket: ]
    staticElement: MethodMember
      base: dart:core::<fragment>::@class::List::@method::[]
      substitution: {E: void Function<T>(T)}
    element: dart:core::<fragment>::@class::List::@method::[]#element
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_methodInvocation() async {
    await assertNoErrorsInCode('''
class C {
  late void Function<T>(T) f;
  void Function<T>(T) m() => f;
}

void Function(int) foo(C c) {
  return c.m();
}
''');

    assertResolvedNodeText(findNode.functionReference('c.m();'), r'''
FunctionReference
  function: MethodInvocation
    target: SimpleIdentifier
      token: c
      staticElement: <testLibraryFragment>::@function::foo::@parameter::c
      element: <testLibraryFragment>::@function::foo::@parameter::c#element
      staticType: C
    operator: .
    methodName: SimpleIdentifier
      token: m
      staticElement: <testLibraryFragment>::@class::C::@method::m
      element: <testLibraryFragment>::@class::C::@method::m#element
      staticType: void Function<T>(T) Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: void Function<T>(T) Function()
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_postfixExpression_compound() async {
    await assertNoErrorsInCode('''
extension on void Function<T>(T) {
  void Function<T>(T) operator +(int i) {
    return this;
  }
}

void Function(int) foo(void Function<T>(T) f) {
  return f++;
}
''');

    assertResolvedNodeText(findNode.functionReference('f++'), r'''
FunctionReference
  function: PostfixExpression
    operand: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::foo::@parameter::f
      element: <testLibraryFragment>::@function::foo::@parameter::f#element
      staticType: null
    operator: ++
    readElement: <testLibraryFragment>::@function::foo::@parameter::f
    readElement2: <testLibraryFragment>::@function::foo::@parameter::f#element
    readType: void Function<T>(T)
    writeElement: <testLibraryFragment>::@function::foo::@parameter::f
    writeElement2: <testLibraryFragment>::@function::foo::@parameter::f#element
    writeType: void Function<T>(T)
    staticElement: <testLibraryFragment>::@extension::0::@method::+
    element: <testLibraryFragment>::@extension::0::@method::+#element
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
class C {
  late void Function<T>(T) f;
}

void Function(int) foo(C c) {
  return c.f;
}
''');

    assertResolvedNodeText(findNode.functionReference('c.f;'), r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      staticElement: <testLibraryFragment>::@function::foo::@parameter::c
      element: <testLibraryFragment>::@function::foo::@parameter::c#element
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@class::C::@getter::f
      element: <testLibraryFragment>::@class::C::@getter::f#element
      staticType: void Function<T>(T)
    staticElement: <testLibraryFragment>::@class::C::@getter::f
    element: <testLibraryFragment>::@class::C::@getter::f#element
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_prefixExpression_compound() async {
    await assertNoErrorsInCode('''
extension on void Function<T>(T) {
  void Function<T>(T) operator +(int i) {
    return this;
  }
}

void Function(int) foo(void Function<T>(T) f) {
  return ++f;
}
''');

    assertResolvedNodeText(findNode.functionReference('++f'), r'''
FunctionReference
  function: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::foo::@parameter::f
      element: <testLibraryFragment>::@function::foo::@parameter::f#element
      staticType: null
    readElement: <testLibraryFragment>::@function::foo::@parameter::f
    readElement2: <testLibraryFragment>::@function::foo::@parameter::f#element
    readType: void Function<T>(T)
    writeElement: <testLibraryFragment>::@function::foo::@parameter::f
    writeElement2: <testLibraryFragment>::@function::foo::@parameter::f#element
    writeType: void Function<T>(T)
    staticElement: <testLibraryFragment>::@extension::0::@method::+
    element: <testLibraryFragment>::@extension::0::@method::+#element
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_propertyAccess() async {
    await assertNoErrorsInCode('''
class C {
  late void Function<T>(T) f;
}

void Function(int) foo(C c) {
  return (c).f;
}
''');

    assertResolvedNodeText(findNode.functionReference('(c).f;'), r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        staticElement: <testLibraryFragment>::@function::foo::@parameter::c
        element: <testLibraryFragment>::@function::foo::@parameter::c#element
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@class::C::@getter::f
      element: <testLibraryFragment>::@class::C::@getter::f#element
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_simpleIdentifier() async {
    await assertNoErrorsInCode('''
void Function(int) foo(void Function<T>(T) f) {
  return f;
}
''');

    assertResolvedNodeText(findNode.functionReference('f;'), r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::foo::@parameter::f
    element: <testLibraryFragment>::@function::foo::@parameter::f#element
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }
}

@reflectiveTest
class FunctionReferenceResolutionTest_WithoutConstructorTearoffs
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_localVariable() async {
    // This code includes a disallowed type instantiation (local variable),
    // but in the case that the experiment is not enabled, we suppress the
    // associated error.
    await assertErrorsInCode('''
void bar(void Function<T>(T a) foo) {
  foo<int>;
}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 43, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertResolvedNodeText(reference, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::bar::@parameter::foo
    element: <testLibraryFragment>::@function::bar::@parameter::foo#element
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }
}
