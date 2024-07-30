// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentedExpressionResolutionTest);
  });
}

@reflectiveTest
class AugmentedExpressionResolutionTest extends PubPackageResolutionTest {
  test_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  num foo = 0;
}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment num foo = augmented;
}
''');

    var node = findNode.singleVariableDeclaration.initializer!;
    assertResolvedNodeText(node, r'''
AugmentedExpression
  augmentedKeyword: augmented
  element: self::@class::A::@field::foo
  staticType: int
''');
  }

  test_class_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  int get foo => 0;
}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment int get foo {
    return augmented;
  }
}
''');

    var node = findNode.singleReturnStatement;
    assertResolvedNodeText(node, r'''
ReturnStatement
  returnKeyword: return
  expression: AugmentedExpression
    augmentedKeyword: augmented
    element: self::@class::A::@getter::foo
    staticType: int
  semicolon: ;
''');
  }

  test_class_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  set foo(int _) {}
}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment set foo(int _) {
    augmented = 0;
  }
}
''');

    var node = findNode.singleBlock;
    assertResolvedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AssignmentExpression
        leftHandSide: AugmentedExpression
          augmentedKeyword: augmented
          element: self::@class::A::@setter::foo
          staticType: null
        operator: =
        rightHandSide: IntegerLiteral
          literal: 0
          parameter: self::@class::A::@setter::foo::@parameter::_
          staticType: int
        readElement: <null>
        readType: null
        writeElement: self::@class::A::@setter::foo
        writeType: int
        staticElement: <null>
        staticType: int
      semicolon: ;
  rightBracket: }
''');
  }

  test_class_setter_inGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  int foo = 0;
}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment int get foo {
    augmented = 0;
    return 0;
  }
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_NOT_SETTER, 73, 9),
    ]);

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: AugmentedExpression
    augmentedKeyword: augmented
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_class_setter_inMethod() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  void foo() {}
}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment void foo() {
    augmented = 0;
  }
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_NOT_SETTER, 72, 9),
    ]);

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: AugmentedExpression
    augmentedKeyword: augmented
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_topLevel_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

int get foo => 0;
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment int get foo {
  return augmented;
}
''');

    var node = findNode.singleReturnStatement;
    assertResolvedNodeText(node, r'''
ReturnStatement
  returnKeyword: return
  expression: AugmentedExpression
    augmentedKeyword: augmented
    element: self::@getter::foo
    staticType: int
  semicolon: ;
''');
  }

  test_topLevel_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

set foo(int _) {}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment set foo(int _) {
  augmented = 0;
}
''');

    var node = findNode.singleBlock;
    assertResolvedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: AssignmentExpression
        leftHandSide: AugmentedExpression
          augmentedKeyword: augmented
          element: self::@setter::foo
          staticType: null
        operator: =
        rightHandSide: IntegerLiteral
          literal: 0
          parameter: self::@setter::foo::@parameter::_
          staticType: int
        readElement: <null>
        readType: null
        writeElement: self::@setter::foo
        writeType: int
        staticElement: <null>
        staticType: int
      semicolon: ;
  rightBracket: }
''');
  }

  test_topLevel_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

num foo = 0;
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment num foo = augmented;
''');

    var node = findNode.singleVariableDeclaration.initializer!;
    assertResolvedNodeText(node, r'''
AugmentedExpression
  augmentedKeyword: augmented
  element: self::@variable::foo
  staticType: int
''');
  }
}
