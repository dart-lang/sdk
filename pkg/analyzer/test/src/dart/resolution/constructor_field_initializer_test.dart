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
    staticElement: <testLibraryFragment>::@class::A::@field::f
    element: <testLibraryFragment>::@class::A::@field::f#element
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a
    element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
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
    staticElement: <testLibraryFragment>::@class::A::@field::x
    element: <testLibraryFragment>::@class::A::@field::x#element
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
                    staticElement: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a
                    element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
                    staticType: int
                  operator: +
                  rightOperand: IntegerLiteral
                    literal: 1
                    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
                    staticType: int
                  staticElement: dart:core::<fragment>::@class::num::@method::+
                  element: dart:core::<fragment>::@class::num::@method::+#element
                  staticInvokeType: num Function(num)
                  staticType: int
                semicolon: ;
            rightBracket: }
        declaredElement: @39
          type: int Function()
        staticType: int Function()
      rightParenthesis: )
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@class::A::@field::x
    element: <testLibraryFragment>::@class::A::@field::x#element
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
              staticElement: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a
              element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
              staticType: int
            operator: +
            rightOperand: IntegerLiteral
              literal: 1
              parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
              staticType: int
            staticElement: dart:core::<fragment>::@class::num::@method::+
            element: dart:core::<fragment>::@class::num::@method::+#element
            staticInvokeType: num Function(num)
            staticType: int
        declaredElement: @43
          type: int Function()
        staticType: int Function()
      rightParenthesis: )
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    element: <null>
    staticInvokeType: int Function()
    staticType: int
''');
  }

  test_invalid_declarationAndInitializer() async {
    await assertErrorsInCode('''
class A {
  final x = 0;
  const A() : x = a;
}
const a = 0;
''', [
      error(
          CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
          39,
          1),
    ]);

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@class::A::@field::x
    element: <testLibraryFragment>::@class::A::@field::x#element
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: int
''');
  }

  test_invalid_notField_class() async {
    await assertErrorsInCode('''
class A {
  const A() : X = a;
}
const a = 0;
class X {}
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 24, 5),
    ]);

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: X
    staticElement: <null>
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: int
''');
  }

  test_invalid_notField_getter() async {
    await assertErrorsInCode('''
class A {
  A() : x = a;
  int get x => 0;
}
const a = 0;
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 5),
    ]);

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@class::A::@field::x
    element: <testLibraryFragment>::@class::A::@field::x#element
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: int
''');
  }

  test_invalid_notField_importPrefix() async {
    await assertErrorsInCode('''
import 'dart:async' as x;
class A {
  A() : x = a;
}
const a = 0;
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 12),
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 44, 5),
    ]);

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    staticElement: <null>
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: int
''');
  }

  test_invalid_notField_method() async {
    await assertErrorsInCode('''
class A {
  A() : x = a;
  void x() {}
}
const a = 0;
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 5),
    ]);

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    staticElement: <null>
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: int
''');
  }

  test_invalid_notField_setter() async {
    await assertErrorsInCode('''
class A {
  A() : x = a;
  set x(int _) {}
}
const a = 0;
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 5),
    ]);

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@class::A::@field::x
    element: <testLibraryFragment>::@class::A::@field::x#element
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: int
''');
  }

  test_invalid_notField_topLevelFunction() async {
    await assertErrorsInCode('''
class A {
  A() : x = a;
}
const a = 0;
void x() {}
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 5),
    ]);

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    staticElement: <null>
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: int
''');
  }

  test_invalid_notField_topLevelVariable() async {
    await assertErrorsInCode('''
class A {
  A() : x = a;
}
const a = 0;
var x = 0;
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 5),
    ]);

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    staticElement: <null>
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: int
''');
  }

  test_invalid_notField_typeParameter() async {
    await assertErrorsInCode('''
class A<T> {
  A() : T = a;
}
const a = 0;
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 21, 5),
    ]);

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: T
    staticElement: <null>
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: int
''');
  }

  test_invalid_notField_unresolved() async {
    await assertErrorsInCode('''
class A {
  A() : x = a;
}
const a = 0;
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 5),
    ]);

    var node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    staticElement: <null>
    element: <null>
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: int
''');
  }
}
