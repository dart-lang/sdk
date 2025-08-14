// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorFieldInitializerResolutionTest);
  });
}

@reflectiveTest
class ConstructorFieldInitializerResolutionTest
    extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_fieldOfAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int get foo;
}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

augment class A {
  final int _foo;

  const A() : _foo = 0;

  augment int get foo => _foo;
}
''');

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: _foo
    staticElement: package:test/a.dart::@fragment::package:test/test.dart::@classAugmentation::A::@field::_foo
    element: package:test/a.dart::@fragment::package:test/test.dart::@classAugmentation::A::@field::_foo#element
    staticType: null
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_formalParameter() async {
    await assertNoErrorsInCode('''
class A {
  final int f;
  A(int a) : f = a;
}
''');

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: f
    element: <testLibrary>::@class::A::@field::f
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
    staticType: int
''');
  }

  test_functionExpressionInvocation_blockBody() async {
    await resolveTestCode(r'''
class A {
  final x;
  A(int a) : x = (() {return a + 1;})();
}
''');

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::A::@field::x
    staticType: null
  equals: =
  expression: FunctionExpressionInvocation
    function: ParenthesizedExpression
      leftParenthesis: (
      expression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ReturnStatement
                returnKeyword: return
                expression: BinaryExpression
                  leftOperand: SimpleIdentifier
                    token: a
                    element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                    staticType: int
                  operator: +
                  rightOperand: IntegerLiteral
                    literal: 1
                    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
                    staticType: int
                  element: dart:core::@class::num::@method::+
                  staticInvokeType: num Function(num)
                  staticType: int
                semicolon: ;
            rightBracket: }
        declaredElement: <testLibraryFragment> null@null
          element: null@null
            type: int Function()
        staticType: int Function()
      rightParenthesis: )
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: int Function()
    staticType: int
''');
  }

  test_functionExpressionInvocation_expressionBody() async {
    await resolveTestCode(r'''
class A {
  final int x;
  A(int a) : x = (() => a + 1)();
}
''');

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::A::@field::x
    staticType: null
  equals: =
  expression: FunctionExpressionInvocation
    function: ParenthesizedExpression
      leftParenthesis: (
      expression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
              staticType: int
            operator: +
            rightOperand: IntegerLiteral
              literal: 1
              correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::+
            staticInvokeType: num Function(num)
            staticType: int
        declaredElement: <testLibraryFragment> null@null
          element: null@null
            type: int Function()
        staticType: int Function()
      rightParenthesis: )
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: int Function()
    staticType: int
''');
  }

  test_invalid_declarationAndInitializer() async {
    await assertErrorsInCode(
      '''
class A {
  final x = 0;
  const A() : x = a;
}
const a = 0;
''',
      [
        error(
          CompileTimeErrorCode.fieldInitializedInInitializerAndDeclaration,
          39,
          1,
        ),
      ],
    );

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::A::@field::x
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }

  test_invalid_notField_class() async {
    await assertErrorsInCode(
      '''
class A {
  const A() : X = a;
}
const a = 0;
class X {}
''',
      [error(CompileTimeErrorCode.initializerForNonExistentField, 24, 5)],
    );

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: X
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }

  test_invalid_notField_getter() async {
    await assertErrorsInCode(
      '''
class A {
  A() : x = a;
  int get x => 0;
}
const a = 0;
''',
      [error(CompileTimeErrorCode.initializerForNonExistentField, 18, 5)],
    );

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::A::@field::x
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }

  test_invalid_notField_importPrefix() async {
    await assertErrorsInCode(
      '''
import 'dart:async' as x;
class A {
  A() : x = a;
}
const a = 0;
''',
      [
        error(WarningCode.unusedImport, 7, 12),
        error(CompileTimeErrorCode.initializerForNonExistentField, 44, 5),
      ],
    );

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }

  test_invalid_notField_method() async {
    await assertErrorsInCode(
      '''
class A {
  A() : x = a;
  void x() {}
}
const a = 0;
''',
      [error(CompileTimeErrorCode.initializerForNonExistentField, 18, 5)],
    );

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }

  test_invalid_notField_setter() async {
    await assertErrorsInCode(
      '''
class A {
  A() : x = a;
  set x(int _) {}
}
const a = 0;
''',
      [error(CompileTimeErrorCode.initializerForNonExistentField, 18, 5)],
    );

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::A::@field::x
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }

  test_invalid_notField_topLevelFunction() async {
    await assertErrorsInCode(
      '''
class A {
  A() : x = a;
}
const a = 0;
void x() {}
''',
      [error(CompileTimeErrorCode.initializerForNonExistentField, 18, 5)],
    );

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }

  test_invalid_notField_topLevelVariable() async {
    await assertErrorsInCode(
      '''
class A {
  A() : x = a;
}
const a = 0;
var x = 0;
''',
      [error(CompileTimeErrorCode.initializerForNonExistentField, 18, 5)],
    );

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }

  test_invalid_notField_typeParameter() async {
    await assertErrorsInCode(
      '''
class A<T> {
  A() : T = a;
}
const a = 0;
''',
      [error(CompileTimeErrorCode.initializerForNonExistentField, 21, 5)],
    );

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: T
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }

  test_invalid_notField_unresolved() async {
    await assertErrorsInCode(
      '''
class A {
  A() : x = a;
}
const a = 0;
''',
      [error(CompileTimeErrorCode.initializerForNonExistentField, 18, 5)],
    );

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: int
''');
  }
}
