// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperConstructorInvocationResolutionTest);
  });
}

@reflectiveTest
class SuperConstructorInvocationResolutionTest
    extends PubPackageResolutionTest {
  test_named() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named(int a);
}

class B extends A {
  B() : super.named(0);
}
''');

    final node = findNode.singleSuperConstructorInvocation;
    assertResolvedNodeText(node, r'''
SuperConstructorInvocation
  superKeyword: super
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: self::@class::A::@constructor::named
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::named::@parameter::a
        staticType: int
    rightParenthesis: )
  staticElement: self::@class::A::@constructor::named
''');
  }

  test_named_unresolved() async {
    await assertErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B() : super.named(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER, 53, 14),
    ]);

    final node = findNode.singleSuperConstructorInvocation;
    assertResolvedNodeText(node, r'''
SuperConstructorInvocation
  superKeyword: super
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: <null>
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticElement: <null>
''');
  }

  test_nonConst_fromConst() async {
    await assertErrorsInCode('''
class A {
  final a;
  A(this.a);
}

class B extends A {
  const B() : super(5);
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER, 71, 8),
    ]);

    final node = findNode.singleSuperConstructorInvocation;
    assertResolvedNodeText(node, r'''
SuperConstructorInvocation
  superKeyword: super
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 5
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticElement: self::@class::A::@constructor::new
''');
  }

  test_unnamed() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B() : super(0);
}
''');

    final node = findNode.singleSuperConstructorInvocation;
    assertResolvedNodeText(node, r'''
SuperConstructorInvocation
  superKeyword: super
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticElement: self::@class::A::@constructor::new
''');
  }

  test_unnamed_unresolved() async {
    await assertErrorsInCode(r'''
class A {
  A.named(int a);
}

class B extends A {
  B() : super(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          59, 8),
    ]);

    final node = findNode.singleSuperConstructorInvocation;
    assertResolvedNodeText(node, r'''
SuperConstructorInvocation
  superKeyword: super
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticElement: <null>
''');
  }
}
