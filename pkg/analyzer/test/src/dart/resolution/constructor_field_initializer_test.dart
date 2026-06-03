// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorFieldInitializerResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConstructorFieldInitializerResolutionTest
    extends PubPackageResolutionTest {
  test_fieldOfAugmentation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo;
}

augment class A {
  final int _foo;

  const A() : _foo = 0;

  augment int get foo => _foo;
}
''');

    var node = result.findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: _foo
    element: <testLibrary>::@class::A::@field::_foo
    staticType: null
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_formalParameter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  final int f;
  A(int a) : f = a;
}
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final x;
  A(int a) : x = (() {return a + 1;})();
}
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
        declaredFragment: <testLibraryFragment> null@null
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  A(int a) : x = (() => a + 1)();
}
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
        declaredFragment: <testLibraryFragment> null@null
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  final x = 0;
  const A() : x = a;
//            ^
// [diag.fieldInitializedInInitializerAndDeclaration] Fields can't be initialized in the constructor if they are final and were already initialized at their declaration.
}
const a = 0;
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  const A() : X = a;
//            ^^^^^
// [diag.initializerForNonExistentField] 'X' isn't a field in the enclosing class.
}
const a = 0;
class X {}
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A() : x = a;
//      ^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
  int get x => 0;
}
const a = 0;
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async' as x;
//     ^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:async'.
class A {
  A() : x = a;
//      ^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
}
const a = 0;
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A() : x = a;
//      ^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
  void x() {}
}
const a = 0;
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A() : x = a;
//      ^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
  set x(int _) {}
}
const a = 0;
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A() : x = a;
//      ^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
}
const a = 0;
void x() {}
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A() : x = a;
//      ^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
}
const a = 0;
var x = 0;
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  A() : T = a;
//      ^^^^^
// [diag.initializerForNonExistentField] 'T' isn't a field in the enclosing class.
}
const a = 0;
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A() : x = a;
//      ^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
}
const a = 0;
''');

    var node = result.findNode.singleConstructorFieldInitializer;
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
