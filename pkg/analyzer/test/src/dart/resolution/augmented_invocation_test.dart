// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentedInvocationResolutionTest);
  });
}

@reflectiveTest
class AugmentedInvocationResolutionTest extends PubPackageResolutionTest {
  test_class_constructor_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  A.named(int a);
}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment A.named(int a) {
    augmented(0);
  }
}
''');

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::named::@parameter::a
        staticType: int
    rightParenthesis: )
  element: self::@class::A::@constructor::named
  staticType: A
''');
  }

  test_class_constructor_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  A(int a);
}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment A(int a) {
    augmented(0);
  }
}
''');

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  element: self::@class::A::@constructor::new
  staticType: A
''');
  }

  test_class_getter_functionTyped() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  int Function(int a) get foo => throw 0;
}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment int Function(int a) get foo {
    augmented(42);
    throw 0;
  }
}
''');

    var node = findNode.expressionStatement('augmented(');
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression: FunctionExpressionInvocation
    function: AugmentedExpression
      augmentedKeyword: augmented
      element: self::@class::A::@getter::foo
      staticType: int Function(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 42
          parameter: root::@parameter::a
          staticType: int
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: int Function(int)
    staticType: int
  semicolon: ;
''');
  }

  test_class_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  void foo(int a) {}
}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment void foo(int a) {
    augmented(0);
  }
}
''');

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::a
        staticType: int
    rightParenthesis: )
  element: self::@class::A::@method::foo
  staticType: void
''');
  }

  test_topLevel_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

void foo(int a) {}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment void foo(int a) {
  augmented(0);
}
''');

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@function::foo::@parameter::a
        staticType: int
    rightParenthesis: )
  element: self::@function::foo
  staticType: void
''');
  }

  test_topLevel_function_augments_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class foo {}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void foo() {
  augmented(0);
}
''', [
      error(CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND, 27,
          7),
    ]);

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  element: <null>
  staticType: InvalidType
''');
  }

  test_topLevel_function_generic_fromArgument() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

T foo<T>(T a) => a;
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment void foo<T2>(T2 a) {
  augmented(0);
}
''');

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@function::foo::@parameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: self::@function::foo
  staticType: int
''');
  }

  test_topLevel_function_generic_fromArguments_couldNotInfer() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

T foo<T extends num>(T a) => throw 0;
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void foo<T2 extends num>(T2 a) {
  augmented('');
}
''', [
      error(CompileTimeErrorCode.COULD_NOT_INFER, 70, 9),
    ]);

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  element: self::@function::foo
  staticType: String
''');
  }

  test_topLevel_function_generic_fromClosure() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

U foo<T, U>(T t, U Function(T) f) => throw 0;
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment U2 foo<T2, U2>(T2 t, U2 Function(T2) f) {
  augmented(0, (_) => '');
  throw 0;
}
''');

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@function::foo::@parameter::t
          substitution: {T: int, U: String}
        staticType: int
      FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: _
            declaredElement: @92::@parameter::_
              type: int
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: SimpleStringLiteral
            literal: ''
        declaredElement: @92
          type: String Function(int)
        parameter: ParameterMember
          base: self::@function::foo::@parameter::f
          substitution: {T: int, U: String}
        staticType: String Function(int)
    rightParenthesis: )
  element: self::@function::foo
  staticType: String
''');
  }

  test_topLevel_function_generic_fromContextType() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

T foo<T>() => throw 0;
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void foo<T2>() {
  int a = augmented();
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 58, 1),
    ]);

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  arguments: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: self::@function::foo
  staticType: int
''');
  }

  test_topLevel_function_generic_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

T foo<T>() => throw 0;
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment void foo<T2>() {
  augmented<int>();
}
''');

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: self::@function::foo
  staticType: int
''');
  }

  test_topLevel_function_generic_typeArguments_notMatchingBounds() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

T foo<T extends num>() => throw 0;
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void foo<T2 extends num>() {
  augmented<String>();
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 76, 6),
    ]);

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: self::@function::foo
  staticType: String
''');
  }

  test_topLevel_function_generic_typeArguments_wrongNumber() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

T foo<T>() => throw 0;
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment void foo<T2>() {
  augmented<int, String>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 63, 13),
    ]);

    var node = findNode.singleAugmentedInvocation;
    assertResolvedNodeText(node, r'''
AugmentedInvocation
  augmentedKeyword: augmented
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
  arguments: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: self::@function::foo
  staticType: dynamic
''');
  }

  test_topLevel_getter_functionTyped() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

int Function(int a) get foo => throw 0;
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment int Function(int a) get foo {
  augmented(42);
  throw 0;
}
''');

    var node = findNode.expressionStatement('augmented(');
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression: FunctionExpressionInvocation
    function: AugmentedExpression
      augmentedKeyword: augmented
      element: self::@getter::foo
      staticType: int Function(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 42
          parameter: root::@parameter::a
          staticType: int
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: int Function(int)
    staticType: int
  semicolon: ;
''');
  }

  test_topLevel_getter_notFunctionTyped() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

int get foo => 0;
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment int get foo {
  augmented();
  return 0;
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 51, 9),
    ]);

    var node = findNode.expressionStatement('augmented(');
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression: AugmentedInvocation
    augmentedKeyword: augmented
    arguments: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: self::@getter::foo
    staticType: InvalidType
  semicolon: ;
''');
  }

  test_topLevel_getter_notFunctionTyped_implicitCall() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  int call() => 0;
}

A get foo => A();
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment A get foo {
  augmented();
  return A();
}
''');

    var node = findNode.expressionStatement('augmented(');
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression: FunctionExpressionInvocation
    function: AugmentedExpression
      augmentedKeyword: augmented
      element: self::@getter::foo
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: self::@class::A::@method::call
    staticInvokeType: int Function()
    staticType: int
  semicolon: ;
''');
  }

  test_topLevel_getter_notFunctionTyped_implicitCall_fromExtension() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {}

extension E on A {
  int call() => 0;
}

A get foo => A();
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment A get foo {
  augmented();
  return A();
}
''');

    var node = findNode.expressionStatement('augmented(');
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression: FunctionExpressionInvocation
    function: AugmentedExpression
      augmentedKeyword: augmented
      element: self::@getter::foo
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: self::@extension::E::@method::call
    staticInvokeType: int Function()
    staticType: int
  semicolon: ;
''');
  }

  test_topLevel_getter_notFunctionTyped_variableClosure() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

int get foo => 0;
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment int get foo {
  var v = () {
    augmented();
  };
  return 0;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 55, 1),
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 68, 9),
    ]);

    var node = findNode.expressionStatement('augmented(');
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression: AugmentedInvocation
    augmentedKeyword: augmented
    arguments: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: self::@getter::foo
    staticType: InvalidType
  semicolon: ;
''');
  }

  test_topLevel_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

set foo(int _) {}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment set foo(int _) {
  augmented(0, 1);
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_SETTER, 54, 9),
    ]);

    var node = findNode.expressionStatement('augmented(');
    assertResolvedNodeText(node, r'''
ExpressionStatement
  expression: AugmentedInvocation
    augmentedKeyword: augmented
    arguments: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          parameter: <null>
          staticType: int
        IntegerLiteral
          literal: 1
          parameter: <null>
          staticType: int
      rightParenthesis: )
    element: self::@setter::foo
    staticType: InvalidType
  semicolon: ;
''');
  }
}
