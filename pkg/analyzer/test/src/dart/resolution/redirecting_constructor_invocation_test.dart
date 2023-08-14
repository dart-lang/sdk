// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectingConstructorInvocationResolutionTest);
  });
}

@reflectiveTest
class RedirectingConstructorInvocationResolutionTest
    extends PubPackageResolutionTest {
  test_named() async {
    await assertNoErrorsInCode(r'''
class C {
  C.named(int a);
  C.other() : this.named(0);
}
''');

    final node = findNode.singleRedirectingConstructorInvocation;
    assertResolvedNodeText(node, r'''
RedirectingConstructorInvocation
  thisKeyword: this
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: self::@class::C::@constructor::named
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::C::@constructor::named::@parameter::a
        staticType: int
    rightParenthesis: )
  staticElement: self::@class::C::@constructor::named
''');
  }

  test_named_unresolved() async {
    await assertErrorsInCode(r'''
class C {
  C.other() : this.named(0);
}
''', [
      error(CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR, 24,
          13),
    ]);

    final node = findNode.singleRedirectingConstructorInvocation;
    assertResolvedNodeText(node, r'''
RedirectingConstructorInvocation
  thisKeyword: this
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

  test_unnamed() async {
    await assertNoErrorsInCode(r'''
class C {
  C(int a);
  C.other() : this(0);
}
''');

    final node = findNode.singleRedirectingConstructorInvocation;
    assertResolvedNodeText(node, r'''
RedirectingConstructorInvocation
  thisKeyword: this
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::C::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  staticElement: self::@class::C::@constructor::new
''');
  }

  test_unnamed_unresolved() async {
    await assertErrorsInCode(r'''
class C {
  C.named();
  C.other() : this(0);
}
''', [
      error(CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR, 37,
          7),
    ]);

    final node = findNode.singleRedirectingConstructorInvocation;
    assertResolvedNodeText(node, r'''
RedirectingConstructorInvocation
  thisKeyword: this
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
