// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionReferenceResolutionTest);
    defineReflectiveTests(
      FunctionReferenceResolutionTest_genericFunctionInstantiation,
    );
    defineReflectiveTests(
      FunctionReferenceResolutionTest_WithoutConstructorTearoffs,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FunctionReferenceResolutionTest extends PubPackageResolutionTest {
  test_constructorFunction_named() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo() {}
}

var x = (A.foo)<int>;
''');

    var node = result.findNode.functionReference('(A.foo)<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: ConstructorReference
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@class::A
          type: null
        period: .
        name: SimpleIdentifier
          token: foo
          element: <testLibrary>::@class::A::@constructor::foo
          staticType: null
        element: <testLibrary>::@class::A::@constructor::foo
      staticType: A<T> Function<T>()
    rightParenthesis: )
    staticType: A<T> Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: A<int> Function()
  typeArgumentTypes
    int
''');
  }

  test_constructorFunction_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A();
}

var x = (A.new)<int>;
''');

    var node = result.findNode.functionReference('(A.new)<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: ConstructorReference
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@class::A
          type: null
        period: .
        name: SimpleIdentifier
          token: new
          element: <testLibrary>::@class::A::@constructor::new
          staticType: null
        element: <testLibrary>::@class::A::@constructor::new
      staticType: A<T> Function<T>()
    rightParenthesis: )
    staticType: A<T> Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: A<int> Function()
  typeArgumentTypes
    int
''');
  }

  test_constructorReference() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo() {}
}

var x = A.foo<int>;
//           ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
''');

    var node = result.findNode.functionReference('A.foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <testLibrary>::@class::A::@constructor::foo
        staticType: null
      element: <testLibrary>::@class::A::@constructor::foo
    staticType: A<T> Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_constructorReference_prefixed() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async' as a;
var x = a.Future.delayed<int>;
//                      ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'a.Future.delayed' doesn't have type parameters.
''');
    var node = result.findNode.functionReference('a.Future.delayed<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        importPrefix: ImportPrefixReference
          name: a
          period: .
          element: <testLibraryFragment>::@prefix::a
        name: Future
        element: dart:async::@class::Future
        type: null
      period: .
      name: SimpleIdentifier
        token: delayed
        element: dart:async::@class::Future::@constructor::delayed
        staticType: null
      element: dart:async::@class::Future::@constructor::delayed
    staticType: Future<T> Function<T>(Duration, [FutureOr<T> Function()?])
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_dynamicTyped() async {
    var result = await resolveTestCodeWithDiagnostics('''
dynamic i = 1;

void bar() {
  i<int>;
//^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    var node = result.findNode.functionReference('i<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: i
    element: <testLibrary>::@getter::i
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_dynamicTyped_targetOfMethodCall() async {
    var result = await resolveTestCodeWithDiagnostics('''
dynamic i = 1;

void bar() {
  i<int>.foo();
//^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    var node = result.findNode.functionReference('i<int>.foo();');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: i
    element: <testLibrary>::@getter::i
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_explicitReceiver_dynamicTyped() async {
    var result = await resolveTestCodeWithDiagnostics('''
dynamic f() => 1;

foo() {
  f().instanceMethod<int>;
//^^^^^^^^^^^^^^^^^^^^^^^
// [diag.genericMethodTypeInstantiationOnDynamic] A method tear-off on a receiver whose type is 'dynamic' can't have type arguments.
}
''');

    var node = result.findNode.functionReference('f().instanceMethod<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: MethodInvocation
      methodName: SimpleIdentifier
        token: f
        element: <testLibrary>::@function::f
        staticType: dynamic Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: dynamic Function()
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: instanceMethod
      element: <null>
      staticType: dynamic
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_explicitReceiver_unknown() async {
    var result = await resolveTestCodeWithDiagnostics('''
bar() {
  a.foo<int>;
//^
// [diag.undefinedIdentifier] Undefined name 'a'.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_explicitReceiver_unknown_multipleProperties() async {
    var result = await resolveTestCodeWithDiagnostics('''
bar() {
  a.b.foo<int>;
//^
// [diag.undefinedIdentifier] Undefined name 'a'.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        element: <null>
        staticType: InvalidType
      period: .
      identifier: SimpleIdentifier
        token: b
        element: <null>
        staticType: InvalidType
      element: <null>
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_extension() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E<T> on String {}

void foo() {
  E<int>;
//^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    var node = result.findNode.functionReference('E<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: E
    element: <testLibrary>::@extension::E
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_extension_prefixed() async {
    newFile('$testPackageLibPath/a.dart', '''
extension E<T> on String {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void foo() {
  a.E<int>;
//^^^
// [diag.extensionAsExpression] Extension 'a.E' can't be used as an expression.
}
''');

    var node = result.findNode.functionReference('E<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: E
      element: package:test/a.dart::@extension::E
      staticType: dynamic
    element: package:test/a.dart::@extension::E
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_extensionGetter_extensionOverride() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {
  int get foo => 0;
}

bar(A a) {
  E(a).foo<int>;
//^^^^^^^^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::bar::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@getter::foo
      staticType: int
    staticType: int
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_extensionMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {
  void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_explicitReceiver_this() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {
  void foo<T>(T a) {}

  bar() {
    this.foo<int>;
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::bar::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride_cascade() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = 0;
}

extension E on A {
  void foo<T>(T a) {}
}

bar(A a) {
  E(a)..foo<int>;
//^
// [diag.extensionOverrideWithCascade] Extension overrides have no value so they can't be used as the receiver of a cascade expression.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {
  static void foo<T>(T a) {}
}

bar(A a) {
  E(a).foo<int>;
//     ^^^
// [diag.extensionOverrideAccessToStaticMember] An extension override can't be used to access a static member from an extension.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::bar::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_extensionOverride_unknown() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {}

bar(A a) {
  E(a).foo<int>;
//     ^^^
// [diag.undefinedExtensionGetter] The getter 'foo' isn't defined for the extension 'E'.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::bar::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_extensionMethod_fromClassDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  bar() {
    foo<int>;
  }
}

extension E on A {
  void foo<T>(T a) {}
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_extensionMethod_unknown() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on double {
  bar() {
//^^^
// [diag.unusedElement] The declaration 'bar' isn't referenced.
    foo<int>;
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'double'.
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_function_call() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T a) {}

void bar() {
  foo.call<int>;
}
''');

    var node = result.findNode.functionReference('foo.call<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      element: <null>
      staticType: void Function<T>(T)
    element: <null>
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_function_call_tooFewTypeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T, U>(T a, U b) {}

void bar() {
  foo.call<int>;
//        ^^^^^
// [diag.wrongNumberOfTypeArgumentsFunction] The type of this function is 'void Function<T, U>(T, U)', which has 2 type parameters, but 1 type arguments were given.
}
''');

    var node = result.findNode.functionReference('foo.call<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: void Function<T, U>(T, U)
    period: .
    identifier: SimpleIdentifier
      token: call
      element: <null>
      staticType: void Function<T, U>(T, U)
    element: <null>
    staticType: void Function<T, U>(T, U)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(dynamic, dynamic)
  typeArgumentTypes
    dynamic
    dynamic
''');
  }

  test_function_call_tooManyTypeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo(String a) {}

void bar() {
  foo.call<int>;
//        ^^^^^
// [diag.wrongNumberOfTypeArgumentsFunction] The type of this function is 'void Function(String)', which has 0 type parameters, but 1 type arguments were given.
}
''');

    var node = result.findNode.functionReference('foo.call<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: void Function(String)
    period: .
    identifier: SimpleIdentifier
      token: call
      element: <null>
      staticType: void Function(String)
    element: <null>
    staticType: void Function(String)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(String)
''');
  }

  test_function_call_typeArgNotMatchingBound() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T extends num>(T a) {}

void bar() {
  foo.call<String>;
//         ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');

    var node = result.findNode.functionReference('foo.call<String>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: void Function<T extends num>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      element: <null>
      staticType: void Function<T extends num>(T)
    element: <null>
    staticType: void Function<T extends num>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::@class::String
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
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T a) {}

void bar() {
  foo.m<int>;
}

extension on Function {
  void m<T>(T t) {}
}
''');

    var node = result.findNode.functionReference('foo.m<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: m
      element: <testLibrary>::@extension::#0::@method::m
      staticType: void Function<T>(T)
    element: <testLibrary>::@extension::#0::@method::m
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_function_extensionOnFunction_static() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T a) {}

void bar() {
  foo.m<int>;
//    ^
// [diag.undefinedGetter] The getter 'm' isn't defined for the type 'void Function<T>(T)'.
}

extension E on Function {
  static void m<T>(T t) {}
}
''');

    var node = result.findNode.functionReference('foo.m<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: m
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_implicitCallTearoff() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  T call<T>(T t) => t;
}

foo() {
  C()<int>;
}
''');

    var node = result.findNode.implicitCallReference('C()<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallTearoff_class_staticGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static const v = C();
  const C();
  T call<T>(T t) => t;
}

void f() {
  C.v<int>;
}
''');

    var node = result.findNode.implicitCallReference('C.v<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@class::C::@getter::v
      staticType: C
    element: <testLibrary>::@class::C::@getter::v
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallTearoff_extensionOnNullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
Object? v = null;
extension E on Object? {
  void call<R, S>(R r, S s) {}
}
void foo() {
  v<int, String>;
}

''');

    var node = result.findNode.implicitCallReference('v<int, String>;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: v
    element: <testLibrary>::@getter::v
    staticType: Object?
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
  element: <testLibrary>::@extension::E::@method::call
  staticType: void Function(int, String)
  typeArgumentTypes
    int
    String
''');
  }

  test_implicitCallTearoff_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  void call() {}
}

void g(Function f) {}

void f(A a) {
  g(a);
}
''');

    var node = result.findNode.implicitCallReference('a);');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  correspondingParameter: <testLibrary>::@function::g::@formalParameter::f
  element: <testLibrary>::@extensionType::A::@method::call
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

    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

void f() {
  prefix.C.v<int>;
}
''');

    var node = result.findNode.implicitCallReference('C.v<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        element: <testLibraryFragment>::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        element: package:test/a.dart::@class::C
        staticType: null
      element: package:test/a.dart::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: v
      element: package:test/a.dart::@class::C::@getter::v
      staticType: C
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: package:test/a.dart::@class::C::@method::call
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

bar() {
  prefix.c<int>;
}
''');

    var node = result.findNode.implicitCallReference('c<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: c
      element: package:test/a.dart::@getter::c
      staticType: C
    element: package:test/a.dart::@getter::c
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: package:test/a.dart::@class::C::@method::call
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallTearoff_tooFewTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  void call<T, U>(T t, U u) {}
}

foo() {
  C()<int>;
//   ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'call' is declared with 2 type parameters, but 1 type arguments are given.
}
''');

    var node = result.findNode.implicitCallReference('C()<int>;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(dynamic, dynamic)
  typeArgumentTypes
    dynamic
    dynamic
''');
  }

  test_implicitCallTearoff_tooManyTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int call(int t) => t;
}

foo() {
  C()<int>;
//   ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'call' is declared with 0 type parameters, but 1 type arguments are given.
}
''');

    var node = result.findNode.implicitCallReference('C()<int>;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
''');
  }

  test_instanceGetter_explicitReceiver() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  late void Function<T>(T) foo;
}

bar(A a) {
  a.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::bar::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: void Function<T>(T)
    element: <testLibrary>::@class::A::@getter::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceGetter_functionTyped_class_self() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  late void Function<T>(T) foo;

  bar() {
    foo<int>;
  }
}

''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceGetter_functionTyped_class_superClass() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  late void Function<T>(T) foo;
}

abstract class B extends A {
  void f() {
    foo<int>;
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceGetter_nonFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  List<int> get f;
}

void foo(A a) {
  a.f<String>;
//  ^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    var node = result.findNode.functionReference('f<String>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::foo::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: f
      element: <testLibrary>::@class::A::@getter::f
      staticType: List<int>
    element: <testLibrary>::@class::A::@getter::f
    staticType: List<int>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceGetter_nonFunctionType_propertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  List<int> get f;
}

void foo(A a) {
  (a).f<String>;
//    ^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    var node = result.findNode.functionReference('f<String>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::foo::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: f
      element: <testLibrary>::@class::A::@getter::f
      staticType: List<int>
    staticType: List<int>
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_call() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  void foo<T>(T a) {}

  void bar() {
    foo.call<int>;
  }
}
''');

    var node = result.findNode.functionReference('foo.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::C::@method::foo
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      element: <null>
      staticType: void Function<T>(T)
    element: <null>
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_call() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  void foo<T>(T a) {}
}

void bar(C c) {
  c.foo.call<int>;
}
''');

    var node = result.findNode.functionReference('foo.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: c
        element: <testLibrary>::@function::bar::@formalParameter::c
        staticType: C
      period: .
      identifier: SimpleIdentifier
        token: foo
        element: <testLibrary>::@class::C::@method::foo
        staticType: void Function<T>(T)
      element: <testLibrary>::@class::C::@method::foo
      staticType: void Function<T>(T)
    operator: .
    propertyName: SimpleIdentifier
      token: call
      element: <null>
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_field() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@class::B::@getter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_getter_wrongNumberOfTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

void f(A a) {
  // Extra `()` to force reading the type.
  ((a).foo<double>);
//     ^^^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    var node = result.findNode.functionReference('foo<double>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: int
    staticType: int
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: double
        element: dart:core::@class::double
        type: double
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod_explicitReceiver_otherExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo<T>(T a) {}
}

void f(A? a, A b) {
  (a ?? b).foo<int>;
}
''');

    var node = result.findNode.functionReference('(a ?? b).foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A?
        operator: ??
        rightOperand: SimpleIdentifier
          token: b
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::b
          staticType: A
        element: <null>
        staticInvokeType: null
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_parameter_promoted() async {
    // Based on https://github.com/dart-lang/sdk/issues/51853.
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.functionReference(
      'expectStaticType<Exactly<int>>;',
    );
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: int
    period: .
    identifier: SimpleIdentifier
      token: expectStaticType
      element: SubstitutedMethodElementImpl
        baseElement: <testLibrary>::@extension::StaticType::@method::expectStaticType
        substitution: {T: int, X: X}
      staticType: void Function<X extends int Function(int)>()
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@extension::StaticType::@method::expectStaticType
      substitution: {T: int, X: X}
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
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::Exactly
        type: int Function(int)
          alias: <testLibrary>::@typeAlias::Exactly
            typeArguments
              int
    rightBracket: >
  staticType: void Function()
  typeArgumentTypes
    int Function(int)
      alias: <testLibrary>::@typeAlias::Exactly
        typeArguments
          int
''');
  }

  test_instanceMethod_explicitReceiver_receiverIsNotIdentifier_call() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on List<Object?> {
  void foo<T>(T a) {}
}

var a = [].foo.call<int>;
''');

    var node = result.findNode.functionReference('foo.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(node, r'''
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
        element: <testLibrary>::@extension::#0::@method::foo
        staticType: void Function<T>(T)
      staticType: void Function<T>(T)
    operator: .
    propertyName: SimpleIdentifier
      token: call
      element: <null>
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_super() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo<T>(T a) {}
}
class B extends A {
  bar() {
    super.foo<int>;
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_super_noMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  bar() {
    super.foo<int>;
//        ^^^
// [diag.undefinedSuperGetter] The getter 'foo' isn't defined in a superclass of 'A'.
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod_explicitReceiver_super_noSuper() async {
    var result = await resolveTestCodeWithDiagnostics('''
bar() {
  super.foo<int>;
//^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod_explicitReceiver_targetOfFunctionCall() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.functionReference('foo<int>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::bar::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_this() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo<T>(T a) {}

  bar() {
    this.foo<int>;
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_topLevelVariable() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo<T>(T a) {}
}
var a = A();

void bar() {
  a.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@getter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        element: <testLibraryFragment>::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: a
        element: package:test/a.dart::@getter::a
        staticType: A
      element: package:test/a.dart::@getter::a
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
//         ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'A'.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        element: <testLibraryFragment>::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: a
        element: package:test/a.dart::@getter::a
        staticType: A
      element: package:test/a.dart::@getter::a
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod_explicitReceiver_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics('''
bar<T>() {
  T.foo<int>;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'Type'.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: T
      element: #E0 T
      staticType: Type
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_instanceMethod_explicitReceiver_variable() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::bar::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_variable_cascade() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a..foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_explicitReceiver_variable_promoted() async {
    // Based on https://github.com/dart-lang/sdk/issues/51853.
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.functionReference(
      'expectStaticType<Exactly<int>>;',
    );
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
      element: x@22
      staticType: int
    period: .
    identifier: SimpleIdentifier
      token: expectStaticType
      element: SubstitutedMethodElementImpl
        baseElement: <testLibrary>::@extension::StaticType::@method::expectStaticType
        substitution: {T: int, X: X}
      staticType: void Function<X extends int Function(int)>()
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@extension::StaticType::@method::expectStaticType
      substitution: {T: int, X: X}
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
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::Exactly
        type: int Function(int)
          alias: <testLibrary>::@typeAlias::Exactly
            typeArguments
              int
    rightBracket: >
  staticType: void Function()
  typeArgumentTypes
    int Function(int)
      alias: <testLibrary>::@typeAlias::Exactly
        typeArguments
          int
''');
  }

  test_instanceMethod_inherited() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo<T>(T a) {}
}

class B extends A {
  bar() {
    foo<int>;
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_prefixedIdentifier_fromExtension() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void bar<T>() {}
}

extension on B {
  A get foo => A();
}

abstract class B {
  void f() {
    foo.bar<int>;
  }
}
''');

    var node = result.findNode.singleFunctionReference;
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::#0::@getter::foo
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: bar
      element: <testLibrary>::@class::A::@method::bar
      staticType: void Function<T>()
    element: <testLibrary>::@class::A::@method::bar
    staticType: void Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function()
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_prefixedIdentifier_fromSuper() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void bar<T>() {}
}

abstract class B {
  A get foo;
}

abstract class C extends B {
  void f() {
    foo.bar<int>;
  }
}
''');

    var node = result.findNode.singleFunctionReference;
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::B::@getter::foo
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: bar
      element: <testLibrary>::@class::A::@method::bar
      staticType: void Function<T>()
    element: <testLibrary>::@class::A::@method::bar
    staticType: void Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function()
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_prefixedIdentifier_fromThis() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void bar<T>() {}
}

abstract class B {
  A get foo;
  void f() {
    foo.bar<int>;
  }
}
''');

    var node = result.findNode.singleFunctionReference;
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::B::@getter::foo
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: bar
      element: <testLibrary>::@class::A::@method::bar
      staticType: void Function<T>()
    element: <testLibrary>::@class::A::@method::bar
    staticType: void Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function()
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_targetOfFunctionCall_class_self() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.functionReference('foo<int>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_targetOfFunctionCall_class_superClass() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on Function {
  void m() {}
}
class A {
  void foo<T>(T a) {}
}
class B extends A {
  bar() {
    foo<int>.m();
  }
}
''');

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: FunctionReference
    function: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    staticType: void Function(int)
    typeArgumentTypes
      int
  operator: .
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@extension::#0::@method::m
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instanceMethod_targetOfFunctionCall_enum_mixin() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on Function {
  void bar() {}
}
mixin A {
  void foo<T>(T a) {}
}
enum B with A {
  v;
  void f() {
    foo<int>.bar();
  }
}
''');

    var node = result.findNode.functionReference('foo<int>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_targetOfFunctionCall_enum_self() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on Function {
  void bar() {}
}
enum A {
  v;
  void foo<T>(T a) {}
  void f() {
    foo<int>.bar();
  }
}
''');

    var node = result.findNode.functionReference('foo<int>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_targetOfFunctionCall_extension() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on Function {
  void m() {}
}
extension E on int {
  void foo<T>(T a) {}
  void bar() {
    foo<int>.m();
  }
}
''');

    var node = result.findNode.functionReference('foo<int>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_targetOfFunctionCall_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on Function {
  void bar() {}
}
extension type A(int it) {
  void foo<T>(T a) {}
  void f() {
    foo<int>.bar();
  }
}
''');

    var node = result.findNode.functionReference('foo<int>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_targetOfFunctionCall_mixin_constraint() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on Function {
  void m() {}
}
class A {
  void foo<T>(T a) {}
}
mixin M on A {
  void bar() {
    foo<int>.m();
  }
}
''');

    var node = result.findNode.functionReference('foo<int>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_targetOfFunctionCall_mixin_self() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on Function {
  void m() {}
}
mixin M {
  void foo<T>(T a) {}
  void bar() {
    foo<int>.m();
  }
}
''');

    var node = result.findNode.functionReference('foo<int>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_instanceMethod_unknown() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  bar() {
    foo<int>;
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'A'.
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_loadLibrary() async {
    newFile('$testPackageLibPath/a.dart', '');

    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as prefix;
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.

void f() {
  prefix.loadLibrary;
}
''');

    var node = result.findNode.expressionStatement('prefix.loadLibrary');
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: loadLibrary
      element: package:test/a.dart::@function::loadLibrary
      staticType: Future<dynamic> Function()
    element: package:test/a.dart::@function::loadLibrary
    staticType: Future<dynamic> Function()
  semicolon: ;
''');
  }

  test_localFunction() async {
    var result = await resolveTestCodeWithDiagnostics('''
void bar() {
  void foo<T>(T a) {}

  foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: foo@20
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable() async {
    var result = await resolveTestCodeWithDiagnostics('''
void bar(void Function<T>(T a) foo) {
  foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::bar::@formalParameter::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable_call() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T a) {}

void bar() {
  var fn = foo;
  fn.call<int>;
}
''');

    var node = result.findNode.functionReference('fn.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('foo')` here, we must change the
    // policy over there.
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: fn
      element: fn@40
      staticType: void Function<T>(T)
    period: .
    identifier: SimpleIdentifier
      token: call
      element: <null>
      staticType: void Function<T>(T)
    element: <null>
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable_call_tooManyTypeArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T a) {}

void bar() {
  void Function(int) fn = foo;
  fn.call<int>;
//       ^^^^^
// [diag.wrongNumberOfTypeArgumentsFunction] The type of this function is 'void Function(int)', which has 0 type parameters, but 1 type arguments were given.
}
''');

    var node = result.findNode.functionReference('fn.call<int>;');
    // TODO(srawlins): PropertyElementResolver does not return an element for
    // `.call`. If we want `findElement.method('fn')` here, we must change the
    // policy over there.
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: fn
      element: fn@55
      staticType: void Function(int)
    period: .
    identifier: SimpleIdentifier
      token: call
      element: <null>
      staticType: void Function(int)
    element: <null>
    staticType: void Function(int)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
''');
  }

  test_localVariable_typeVariable_boundToFunction() async {
    var result = await resolveTestCodeWithDiagnostics('''
void bar<T extends Function>(T foo) {
  foo<int>;
//^^^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::bar::@formalParameter::foo
    staticType: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_localVariable_typeVariable_functionTyped() async {
    var result = await resolveTestCodeWithDiagnostics('''
void bar<T extends void Function<U>(U)>(T foo) {
  foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::bar::@formalParameter::foo
    staticType: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_localVariable_typeVariable_nonFunction() async {
    var result = await resolveTestCodeWithDiagnostics('''
void bar<T>(T foo) {
  foo<int>;
//^^^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::bar::@formalParameter::foo
    staticType: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_neverTyped() async {
    var result = await resolveTestCodeWithDiagnostics('''
external Never get i;

void bar() {
  i<int>;
//^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');

    var node = result.findNode.functionReference('i<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: i
    element: <testLibrary>::@getter::i
    staticType: Never
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_nonGenericFunction() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}

  bar() {
    foo<int>;
//     ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'foo' is declared with 0 type parameters, but 1 type arguments are given.
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function()
''');
  }

  test_otherExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(void Function<T>(T a) foo, void Function<T>(T a) bar) {
  (1 == 2 ? foo : bar)<int>;
}
''');

    var reference = result.findNode.functionReference(
      '(1 == 2 ? foo : bar)<int>;',
    );
    assertType(reference, 'void Function(int)');
    // A ParenthesizedExpression has no element to assert on.
  }

  test_otherExpression_wrongNumberOfTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(void Function<T>(T a) foo, void Function<T>(T a) bar) {
  (1 == 2 ? foo : bar)<int, String>;
//                    ^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsFunction] The type of this function is 'void Function<T>(T)', which has 1 type parameters, but 2 type arguments were given.
}
''');

    var reference = result.findNode.functionReference(
      '(1 == 2 ? foo : bar)<int, String>;',
    );
    assertType(reference, 'void Function(dynamic)');
    // A ParenthesizedExpression has no element to assert on.
  }

  test_receiverIsDynamic() async {
    var result = await resolveTestCodeWithDiagnostics('''
bar(dynamic a) {
  a.foo<int>;
//^^^^^
// [diag.genericMethodTypeInstantiationOnDynamic] A method tear-off on a receiver whose type is 'dynamic' can't have type arguments.
}
''');

    var node = result.findNode.functionReference('a.foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::bar::@formalParameter::a
      staticType: dynamic
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: dynamic
    element: <null>
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_recordField_explicitReceiver_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({T Function<T>(T) f1, String f2}) r) {
  int Function(int) v = r.f1;
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var node = result.findNode.functionReference(r'.f1;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({T Function<T>(T) f1, String f2})
    operator: .
    propertyName: SimpleIdentifier
      token: f1
      element: <null>
      staticType: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_recordField_explicitReceiver_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((T Function<T>(T), String) r) {
  int Function(int) v = r.$1;
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var node = result.findNode.functionReference(r'.$1;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (T Function<T>(T), String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo<T>(T a) {}
}

bar() {
  A.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

bar() {
  a.A.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        element: <testLibraryFragment>::@prefix::a
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: package:test/a.dart::@class::A
        staticType: null
      element: package:test/a.dart::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

bar() {
  prefix.A.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        element: <testLibraryFragment>::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: package:test/a.dart::@class::A
        staticType: null
      element: package:test/a.dart::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

bar() {
  prefix.TA.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        element: <testLibraryFragment>::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: TA
        element: package:test/a.dart::@typeAlias::TA
        staticType: Type
      element: package:test/a.dart::@typeAlias::TA
      staticType: Type
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@class::A::@method::foo
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_staticMethod_explicitReceiver_typeAlias() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo<T>(T a) {}
}
typedef TA = A;

bar() {
  TA.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: TA
      element: <testLibrary>::@typeAlias::TA
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: void Function<T>(T)
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_superExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void call<T>() {}
}

class B extends A {
  void f() {
    super<int>;
//  ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.singleImplicitCallReference;
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibrary>::@class::A::@method::call
  staticType: void Function()
  typeArgumentTypes
    int
''');
  }

  test_tooFewTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo<T, U>(T a, U b) {}

  bar() {
    foo<int>;
//     ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'foo' is declared with 2 type parameters, but 1 type arguments are given.
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T, U>(T, U)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(dynamic, dynamic)
  typeArgumentTypes
    dynamic
    dynamic
''');
  }

  test_tooManyTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int, int>;
//     ^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'foo' is declared with 1 type parameters, but 2 type arguments are given.
  }
}
''');

    var node = result.findNode.functionReference('foo<int, int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(dynamic)
  typeArgumentTypes
    dynamic
''');
  }

  test_topLevelFunction() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T a) {}

void bar() {
  foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void bar() {
  a.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@function::foo
      staticType: void Function<T>(T)
    element: package:test/a.dart::@function::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

extension on Function {
  void m() {}
}
void bar() {
  a.foo<int>.m();
}
''');

    var node = result.findNode.functionReference('foo<int>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@function::foo
      staticType: void Function<T>(T)
    element: package:test/a.dart::@function::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelFunction_prefix_unknownPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
bar() {
  prefix.foo<int>;
//^^^^^^
// [diag.undefinedIdentifier] Undefined name 'prefix'.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <null>
      staticType: InvalidType
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_topLevelFunction_targetOfCall() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T a) {}

void bar() {
  foo<int>.call;
}
''');

    var node = result.findNode.propertyAccess('.call');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: FunctionReference
    function: SimpleIdentifier
      token: foo
      element: <testLibrary>::@function::foo
      staticType: void Function<T>(T)
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    staticType: void Function(int)
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: call
    element: <null>
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }

  test_topLevelFunction_targetOfFunctionCall() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T arg) {}

extension on Function {
  void m() {}
}
void bar() {
  foo<int>.m();
}
''');

    var node = result.findNode.functionReference('foo<int>');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

bar() {
  prefix.foo<int>;
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@getter::foo
      staticType: void Function<T>(T)
    element: package:test/a.dart::@getter::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelVariable_prefix_unknownIdentifier() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
//       ^
// [diag.undefinedPrefixedName] The name 'a' is being referenced through the prefix 'prefix', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        element: <testLibraryFragment>::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: a
        element: <null>
        staticType: InvalidType
      element: <null>
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_typeAlias_function_unknownProperty() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Cb = void Function();

var a = Cb.foo<int>;
//         ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'Type'.
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: Cb
      element: <testLibrary>::@typeAlias::Cb
      staticType: Type
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_typeAlias_typeVariable_unknownProperty() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef T<E> = E;

var a = T.foo<int>;
//        ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'Type'.
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: T
      element: <testLibrary>::@typeAlias::T
      staticType: Type
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_unknownIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
void bar() {
  foo<int>;
//^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_unknownIdentifier_explicitReceiver() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

class B {
  bar(A a) {
    a.foo<int>;
//    ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'A'.
  }
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@class::B::@method::bar::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_unknownIdentifier_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as a;

void bar() {
  a.foo<int>;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'a', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@prefix::a
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics('''
void Function(int) foo(void Function<T>(T) f) {
  return (f as dynamic) as void Function<T>(T);
}
''');

    var node = result.findNode.functionReference('as void Function<T>(T);');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: AsExpression
    expression: ParenthesizedExpression
      leftParenthesis: (
      expression: AsExpression
        expression: SimpleIdentifier
          token: f
          element: <testLibrary>::@function::foo::@formalParameter::f
          staticType: void Function<T>(T)
        asOperator: as
        type: NamedType
          name: dynamic
          element: dynamic
          type: dynamic
        staticType: dynamic
      rightParenthesis: )
      staticType: dynamic
    asOperator: as
    type: GenericFunctionType
      returnType: NamedType
        name: void
        element: <null>
        type: void
      functionKeyword: Function
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredFragment: <testLibraryFragment> T@89
              defaultType: null
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: RegularFormalParameter
          type: NamedType
            name: T
            element: #E0 T
            type: T
          declaredFragment: <testLibraryFragment> null@null
            element: isPrivate
              type: T
        rightParenthesis: )
      declaredFragment: GenericFunctionTypeElement
        parameters
          <empty>
            kind: required positional
            element:
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
    var result = await resolveTestCodeWithDiagnostics('''
late void Function<T>(T) g;
void Function(int) foo(void Function<T>(T) f) {
  return g = f;
}
''');

    var node = result.findNode.functionReference('g = f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: g
      element: <null>
      staticType: null
    operator: =
    rightHandSide: SimpleIdentifier
      token: f
      correspondingParameter: <testLibrary>::@setter::g::@formalParameter::value
      element: <testLibrary>::@function::foo::@formalParameter::f
      staticType: void Function<T>(T)
    readElement: <null>
    readType: null
    writeElement: <testLibrary>::@setter::g
    writeType: void Function<T>(T)
    element: <null>
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_assignmentExpression_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on void Function<T>(T) {
  void Function<T>(T) operator +(int i) {
    return this;
  }
}

void Function(int) foo(void Function<T>(T) f) {
  return f += 1;
}
''');

    var node = result.findNode.functionReference('f += 1');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::foo::@formalParameter::f
      staticType: null
    operator: +=
    rightHandSide: IntegerLiteral
      literal: 1
      correspondingParameter: <testLibrary>::@extension::#0::@method::+::@formalParameter::i
      staticType: int
    readElement: <testLibrary>::@function::foo::@formalParameter::f
    readType: void Function<T>(T)
    writeElement: <testLibrary>::@function::foo::@formalParameter::f
    writeType: void Function<T>(T)
    element: <testLibrary>::@extension::#0::@method::+
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_awaitExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
Future<void Function(int)> foo(Future<void Function<T>(T)> f) async {
  return await f;
}
''');

    var node = result.findNode.functionReference('await f');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: AwaitExpression
    awaitKeyword: await
    expression: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::foo::@formalParameter::f
      staticType: Future<void Function<T>(T)>
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_binaryExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  void Function<T>(T) operator +(int i) {
    return <T>(T a) {};
  }
}

void Function(int) foo(C c) {
  return c + 1;
}
''');

    var node = result.findNode.functionReference('c + 1');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: BinaryExpression
    leftOperand: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::foo::@formalParameter::c
      staticType: C
    operator: +
    rightOperand: IntegerLiteral
      literal: 1
      correspondingParameter: <testLibrary>::@class::C::@method::+::@formalParameter::i
      staticType: int
    element: <testLibrary>::@class::C::@method::+
    staticInvokeType: void Function<T>(T) Function(int)
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_cascadeExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
void Function(int) foo(void Function<T>(T) f) {
  return f..toString();
}
''');

    var node = result.findNode.functionReference('f..toString()');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::foo::@formalParameter::f
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_constructorReference() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  C(T a);
}
C<int> Function(int) foo() {
  return C.new;
}
''');

    // TODO(srawlins): Leave the constructor reference uninstantiated, then
    // perform generic function instantiation as a wrapping node.
    var node = result.findNode.constructorReference('C.new');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: C
      element: <testLibrary>::@class::C
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
      tearOffTypeArgumentTypes
        int
    element: <testLibrary>::@class::C::@constructor::new
  staticType: C<int> Function(int)
''');
  }

  test_functionExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
Null Function(int) foo() {
  return <T>(T a) {};
}
''');

    var node = result.findNode.functionReference('<T>(T a) {};');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@37
            defaultType: dynamic
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: T
          element: #E0 T
          type: T
        name: a
        declaredFragment: <testLibraryFragment> a@42
          element: isPublic
            type: T
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> null@null
      element: null@null
        type: Null Function<T>(T)
    staticType: Null Function<T>(T)
  staticType: Null Function(int)
  typeArgumentTypes
    int
''');
  }

  test_functionExpressionInvocation() async {
    var result = await resolveTestCodeWithDiagnostics('''
void Function(int) foo(void Function<T>(T) Function() f) {
  return (f)();
}
''');

    var node = result.findNode.functionReference('(f)()');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: FunctionExpressionInvocation
    function: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: f
        element: <testLibrary>::@function::foo::@formalParameter::f
        staticType: void Function<T>(T) Function()
      rightParenthesis: )
      staticType: void Function<T>(T) Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: void Function<T>(T) Function()
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_functionReference() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef Fn = void Function<U>(U);

void Function(int) foo(Fn f) {
  return f;
}
''');

    var node = result.findNode.functionReference('f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::foo::@formalParameter::f
    staticType: void Function<U>(U)
      alias: <testLibrary>::@typeAlias::Fn
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_implicitCallReference() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  void call<T>(T a) {}
}

void Function(int) foo(C c) {
  return c;
}
''');

    var node = result.findNode.implicitCallReference('c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::foo::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_indexExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
void Function(int) foo(List<void Function<T>(T)> f) {
  return f[0];
}
''');

    var node = result.findNode.functionReference('f[0];');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: IndexExpression
    target: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::foo::@formalParameter::f
      staticType: List<void Function<T>(T)>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: SubstitutedFormalParameterElementImpl
        baseElement: dart:core::@class::List::@method::[]::@formalParameter::index
        substitution: {E: void Function<T>(T)}
      staticType: int
    rightBracket: ]
    element: SubstitutedMethodElementImpl
      baseElement: dart:core::@class::List::@method::[]
      substitution: {E: void Function<T>(T)}
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_methodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  late void Function<T>(T) f;
  void Function<T>(T) m() => f;
}

void Function(int) foo(C c) {
  return c.m();
}
''');

    var node = result.findNode.functionReference('c.m();');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: MethodInvocation
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::foo::@formalParameter::c
      staticType: C
    operator: .
    methodName: SimpleIdentifier
      token: m
      element: <testLibrary>::@class::C::@method::m
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
    var result = await resolveTestCodeWithDiagnostics('''
extension on void Function<T>(T) {
  void Function<T>(T) operator +(int i) {
    return this;
  }
}

void Function(int) foo(void Function<T>(T) f) {
  return f++;
}
''');

    var node = result.findNode.functionReference('f++');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PostfixExpression
    operand: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::foo::@formalParameter::f
      staticType: null
    operator: ++
    readElement: <testLibrary>::@function::foo::@formalParameter::f
    readType: void Function<T>(T)
    writeElement: <testLibrary>::@function::foo::@formalParameter::f
    writeType: void Function<T>(T)
    element: <testLibrary>::@extension::#0::@method::+
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_prefixedIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  late void Function<T>(T) f;
}

void Function(int) foo(C c) {
  return c.f;
}
''');

    var node = result.findNode.functionReference('c.f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::foo::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: f
      element: <testLibrary>::@class::C::@getter::f
      staticType: void Function<T>(T)
    element: <testLibrary>::@class::C::@getter::f
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_prefixExpression_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension on void Function<T>(T) {
  void Function<T>(T) operator +(int i) {
    return this;
  }
}

void Function(int) foo(void Function<T>(T) f) {
  return ++f;
}
''');

    var node = result.findNode.functionReference('++f');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::foo::@formalParameter::f
      staticType: null
    readElement: <testLibrary>::@function::foo::@formalParameter::f
    readType: void Function<T>(T)
    writeElement: <testLibrary>::@function::foo::@formalParameter::f
    writeType: void Function<T>(T)
    element: <testLibrary>::@extension::#0::@method::+
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_propertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  late void Function<T>(T) f;
}

void Function(int) foo(C c) {
  return (c).f;
}
''');

    var node = result.findNode.functionReference('(c).f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        element: <testLibrary>::@function::foo::@formalParameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: f
      element: <testLibrary>::@class::C::@getter::f
      staticType: void Function<T>(T)
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }

  test_simpleIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
void Function(int) foo(void Function<T>(T) f) {
  return f;
}
''');

    var node = result.findNode.functionReference('f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::foo::@formalParameter::f
    staticType: void Function<T>(T)
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }
}

@reflectiveTest
class FunctionReferenceResolutionTest_WithoutConstructorTearoffs
    extends PubPackageResolutionTest
    with WithoutConstructorTearoffsMixin {
  test_localVariable() async {
    // This code includes a disallowed type instantiation (local variable),
    // but in the case that the experiment is not enabled, we suppress the
    // associated error.
    var result = await resolveTestCodeWithDiagnostics('''
void bar(void Function<T>(T a) foo) {
  foo<int>;
//   ^^^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
}
''');

    var node = result.findNode.functionReference('foo<int>;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::bar::@formalParameter::foo
    staticType: void Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: void Function(int)
  typeArgumentTypes
    int
''');
  }
}
