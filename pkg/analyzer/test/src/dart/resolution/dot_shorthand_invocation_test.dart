// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandInvocationResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DotShorthandInvocationResolutionTest extends PubPackageResolutionTest {
  test_assert_lhs() async {
    await assertErrorsInCode(
      r'''
class C {
  final int x;
  const C.named(this.x);
}

class CAssert {
  const CAssert.regular(C ctor)
    : assert(const .named(1) == ctor);
}
''',
      [error(CompileTimeErrorCode.dotShorthandMissingContext, 114, 15)],
    );
  }

  test_basic() async {
    await assertNoErrorsInCode(r'''
class C {
  static C member() => C(1);
  int x;
  C(this.x);
}

void main() {
  C c = .member();
  print(c);
}
''');

    var node = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_basic_generic() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  static C member<U>(U x) => C(x);
  T x;
  C(this.x);
}

void main() {
  C c = .member<int>(1);
  print(c);
}
''');

    var node = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C<dynamic> Function<U>(U)
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
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::C::@method::member::@formalParameter::x
          substitution: {U: int}
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: C<dynamic> Function(int)
  staticType: C<dynamic>
  typeArgumentTypes
    int
''');
  }

  test_basic_parameter() async {
    await assertNoErrorsInCode(r'''
class C {
  static C member(int x) => C(x);
  int x;
  C(this.x);
}

void main() {
  C c = .member(1);
  print(c);
}
''');

    var node = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@method::member::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: C Function(int)
  staticType: C
''');
  }

  test_call_getter() async {
    await assertNoErrorsInCode(r'''
class C {
  const C();
  static C get id1 => const C();
  C call() => const C();
}

void main() {
  C c1 = .id1();
  print(c1);
}
''');

    // The [DotShorthandInvocation] is rewritten to a
    // [FunctionExpressionInvocation].
    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: DotShorthandPropertyAccess
    period: .
    propertyName: SimpleIdentifier
      token: id1
      element: <testLibrary>::@class::C::@getter::id1
      staticType: C
    isDotShorthand: false
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_call_noCallMethod() async {
    await assertErrorsInCode(
      r'''
class C {
  const C();
  static C id1 = const C();
}

void main() {
  C c1 = .id1();
  print(c1);
}
''',
      [error(CompileTimeErrorCode.invocationOfNonFunctionExpression, 77, 4)],
    );
  }

  test_call_property() async {
    await assertNoErrorsInCode(r'''
class C {
  const C();
  static C id1 = const C();
  C call() => const C();
}

void main() {
  C c1 = .id1();
  print(c1);
}
''');

    // The [DotShorthandInvocation] is rewritten to a
    // [FunctionExpressionInvocation].
    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: DotShorthandPropertyAccess
    period: .
    propertyName: SimpleIdentifier
      token: id1
      element: <testLibrary>::@class::C::@getter::id1
      staticType: C
    isDotShorthand: false
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_chain_method() async {
    await assertNoErrorsInCode(r'''
class C {
  static C member() => C(1);
  int x;
  C(this.x);
  C method() => C(1);
}

void main() {
  C c = .member().method();
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: false
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_chain_property() async {
    await assertNoErrorsInCode(r'''
class C {
  static C member() => C(1);
  int x;
  C(this.x);
  C get property => C(1);
}

void main() {
  C c = .member().property;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: false
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_equality() async {
    await assertNoErrorsInCode('''
class C {
  static C member(int x) => C(x);
  int x;
  C(this.x);
}

void main() {
  C lhs = C.member(2);
  bool b = lhs == .member(1);
  print(b);
}
''');

    var identifier = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@method::member::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticInvokeType: C Function(int)
  staticType: C
''');
  }

  test_equality_indexExpression() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
  static List<C> instances() => [C(1)];
}

void main() {
  print(C(1) == .instances()[0]);
}
''');

    var identifier = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: instances
    element: <testLibrary>::@class::C::@method::instances
    staticType: List<C> Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: false
  staticInvokeType: List<C> Function()
  staticType: List<C>
''');
  }

  test_error_context_invalid() async {
    await assertErrorsInCode(
      r'''
class C { }

void main() {
  C Function() c = .member();
  print(c);
}
''',
      [error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 47, 6)],
    );
  }

  test_error_context_none() async {
    await assertErrorsInCode(
      r'''
void main() {
  var c = .member();
  print(c);
}
''',
      [error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 25, 6)],
    );
  }

  test_error_notStatic() async {
    await assertErrorsInCode(
      r'''
class C {
  C foo() => C();
}

void main() {
  final C c = .foo();
  print(c);
}
''',
      [error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 60, 3)],
    );
  }

  test_error_unresolved() async {
    await assertErrorsInCode(
      r'''
class C { }

void main() {
  C c = .member();
  print(c);
}
''',
      [error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 36, 6)],
    );
  }

  test_error_unresolved_new() async {
    await assertErrorsInCode(
      r'''
class C {
  C.named();
}

void main() {
  C c = .new();
  print(c);
}
''',
      [error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 49, 3)],
    );
  }

  test_extensionType() async {
    await assertNoErrorsInCode(r'''
extension type C(int integer) {
  static C one() => C(1);
}

void main() {
  C c = .one();
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: one
    element: <testLibrary>::@extensionType::C::@method::one
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_futureOr() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

class C {
  static C member() => C(1);
  int x;
  C(this.x);
}

void main() {
  FutureOr<C> c = .member();
  print(c);
}
''');

    var node = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_futureOr_nested() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

class C {
  static C member() => C(1);
  int x;
  C(this.x);
}

void main() {
  FutureOr<FutureOr<C>> c = .member();
  print(c);
}
''');

    var node = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_mixin() async {
    await assertNoErrorsInCode(r'''
class C {
  static C member(int x) => C(x);
  int x;
  C(this.x);
}

mixin CMixin on C {
  static CMixin mixinOne() => _CWithMixin(1);
}

class _CWithMixin extends C with CMixin {
  _CWithMixin(super.x);
}

void main() {
  CMixin c = .mixinOne();
  print(c);
}

''');

    var identifier = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: mixinOne
    element: <testLibrary>::@mixin::CMixin::@method::mixinOne
    staticType: CMixin Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: CMixin Function()
  staticType: CMixin
''');
  }

  test_nested() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  static C<int> member() => C(1);
  static C<U> memberType<U, V>(U u) => C(u);
  T x;
  C(this.x);
}

void main() {
  C<C<C>> c = .memberType(.new(.member()));
  print(c);
}
''');

    var node = findNode.dotShorthandInvocation('.memberType');
    assertResolvedNodeText(node, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: memberType
    element: <testLibrary>::@class::C::@method::memberType
    staticType: C<U> Function<U, V>(U)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DotShorthandConstructorInvocation
        period: .
        constructorName: SimpleIdentifier
          token: new
          element: ConstructorMember
            baseElement: <testLibrary>::@class::C::@constructor::new
            substitution: {T: C<dynamic>}
          staticType: null
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            DotShorthandInvocation
              period: .
              memberName: SimpleIdentifier
                token: member
                element: <testLibrary>::@class::C::@method::member
                staticType: C<int> Function()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              isDotShorthand: true
              correspondingParameter: FieldFormalParameterMember
                baseElement: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                substitution: {T: C<dynamic>}
              staticInvokeType: C<int> Function()
              staticType: C<int>
          rightParenthesis: )
        isDotShorthand: true
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::C::@method::memberType::@formalParameter::u
          substitution: {U: C<C<dynamic>>, V: dynamic}
        staticType: C<C<dynamic>>
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: C<C<C<dynamic>>> Function(C<C<dynamic>>)
  staticType: C<C<C<dynamic>>>
  typeArgumentTypes
    C<C<dynamic>>
    dynamic
''');
  }

  test_postfixOperator() async {
    await assertErrorsInCode(
      r'''
class C {
  static C member() => C(1);
  int x;
  C(this.x);
}

void main() {
  C c = .member()++;
  print(c);
}
''',
      [
        error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 87, 6),
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 95, 2),
      ],
    );
  }

  test_prefixOperator() async {
    await assertErrorsInCode(
      r'''
class C {
  static C member() => C(1);
  int x;
  C(this.x);
}

void main() {
  C c = ++.member();
  print(c);
}
''',
      [
        error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 89, 6),
        error(ParserErrorCode.missingAssignableSelector, 96, 1),
      ],
    );
  }

  test_privateClass_otherLibrary_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class _Private {
  _Private.named();
  _Private();
}

typedef Public = _Private;
final Public p = _Private();
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
void main() {
  var x = p;
  x = .new();
  x = .named();
  print(x);
}
''',
      [
        error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 51, 3),
        error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 65, 5),
      ],
    );
  }

  test_privateClass_otherLibrary_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class _Private {
  static _Private instance() => _Private();
}

typedef Public = _Private;
final Public p = _Private();
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
void main() {
  var x = p;
  x = .instance();
  print(x);
}
''',
      [error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 51, 8)],
    );
  }

  test_privateClass_sameLibrary_constructor() async {
    await assertNoErrorsInCode(r'''
class _Private {
  _Private();
}

typedef Public = _Private;
final Public p = _Private();

void main() {
  var x = p;
  x = .new();
  print(x);
}
''');

    assertResolvedNodeText(
      findNode.singleDotShorthandConstructorInvocation,
      r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: <testLibrary>::@class::_Private::@constructor::new
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: _Private
''',
    );
  }

  test_privateClass_sameLibrary_invocation() async {
    await assertNoErrorsInCode(r'''
class _Private {
  static _Private instance() => _Private();
}

typedef Public = _Private;
final Public p = _Private();

void main() {
  var x = p;
  x = .instance();
  print(x);
}
''');

    assertResolvedNodeText(findNode.singleDotShorthandInvocation, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: instance
    element: <testLibrary>::@class::_Private::@method::instance
    staticType: _Private Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: _Private Function()
  staticType: _Private
''');
  }

  test_privateEnum_otherLibrary_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum _Private {
  one;
  factory _Private.a() => one;
}

typedef Public = _Private;
final Public p = _Private.one;
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
void main() {
  var x = p;
  x = .a();
  print(x);
}
''',
      [error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 51, 1)],
    );
  }

  test_privateEnum_otherLibrary_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum _Private {
  one;
  static _Private instance() => one;
}

typedef Public = _Private;
final Public p = _Private.one;
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
void main() {
  var x = p;
  x = .instance();
  print(x);
}
''',
      [error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 51, 8)],
    );
  }

  test_privateEnum_sameLibrary_constructor() async {
    await assertNoErrorsInCode(r'''
enum _Private {
  one;
  factory _Private.a() => one;
}

typedef Public = _Private;
final Public p = _Private.one;

void main() {
  var x = p;
  x = .a();
  print(x);
}
''');

    assertResolvedNodeText(
      findNode.singleDotShorthandConstructorInvocation,
      r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: a
    element: <testLibrary>::@enum::_Private::@constructor::a
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: _Private
''',
    );
  }

  test_privateEnum_sameLibrary_invocation() async {
    await assertNoErrorsInCode(r'''
enum _Private {
  one;
  static _Private instance() => one;
}

typedef Public = _Private;
final Public p = _Private.one;

void main() {
  var x = p;
  x = .instance();
  print(x);
}
''');

    assertResolvedNodeText(findNode.singleDotShorthandInvocation, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: instance
    element: <testLibrary>::@enum::_Private::@method::instance
    staticType: _Private Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: _Private Function()
  staticType: _Private
''');
  }

  test_privateExtensionType_otherLibrary_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension type _Private(int i) {
  _Private.named(this.i);
}

typedef Public = _Private;
final Public p = _Private(1);
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
void main() {
  var x = p;
  x = .new(1);
  x = .named(1);
  print(x);
}
''',
      [
        error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 51, 3),
        error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 66, 5),
      ],
    );
  }

  test_privateExtensionType_otherLibrary_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension type _Private(int it) {
  static _Private instance() => _Private(0);
}

typedef Public = _Private;
final Public p = _Private(1);
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
void main() {
  var x = p;
  x = .instance();
  print(x);
}
''',
      [error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 51, 8)],
    );
  }

  test_privateExtensionType_sameLibrary_constructor() async {
    await assertNoErrorsInCode(r'''
extension type _Private(int i) {}

typedef Public = _Private;
final Public p = _Private(1);

void main() {
  var x = p;
  x = .new(1);
  print(x);
}
''');

    assertResolvedNodeText(
      findNode.singleDotShorthandConstructorInvocation,
      r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: <testLibrary>::@extensionType::_Private::@constructor::new
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@extensionType::_Private::@constructor::new::@formalParameter::i
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: _Private
''',
    );
  }

  test_privateExtensionType_sameLibrary_invocation() async {
    await assertNoErrorsInCode(r'''
extension type _Private(int it) {
  static _Private instance() => _Private(0);
}

typedef Public = _Private;
final Public p = _Private(1);

void main() {
  var x = p;
  x = .instance();
  print(x);
}
''');

    assertResolvedNodeText(findNode.singleDotShorthandInvocation, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: instance
    element: <testLibrary>::@extensionType::_Private::@method::instance
    staticType: _Private Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: _Private Function()
  staticType: _Private
''');
  }

  test_privateMixin_otherLibrary_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin _Private {
  static int instance() => 0;
}

class C with _Private {}
typedef Public = _Private;
final Public p = C();
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
void main() {
  var x = p;
  x = .instance();
  print(x);
}
''',
      [error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 51, 8)],
    );
  }

  test_privateMixin_sameLibrary_invocation() async {
    await assertNoErrorsInCode(r'''
mixin _Private {
  static _Private instance() => C();
}

class C with _Private {}
typedef Public = _Private;
final Public p = C();

void main() {
  var x = p;
  x = .instance();
  print(x);
}
''');

    assertResolvedNodeText(findNode.singleDotShorthandInvocation, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: instance
    element: <testLibrary>::@mixin::_Private::@method::instance
    staticType: _Private Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: _Private Function()
  staticType: _Private
''');
  }

  test_requiredParameters_missing() async {
    await assertErrorsInCode(
      r'''
class C {
  static C member({required int x}) => C(x);
  int x;
  C(this.x);
}

void main() {
  C c = .member();
  print(c);
}
''',
      [error(CompileTimeErrorCode.missingRequiredArgument, 103, 6)],
    );
  }

  test_typeParameters_inference() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  static C<X> foo<X>(X x) => new C<X>();
  C<U> cast<U>() => new C<U>();
}
void main() {
  C<bool> c = .foo("String").cast();
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@method::foo
    staticType: C<X> Function<X>(X)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: "String"
    rightParenthesis: )
  isDotShorthand: false
  staticInvokeType: C<String> Function(String)
  staticType: C<String>
  typeArgumentTypes
    String
''');
  }

  test_typeParameters_notAssignable() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  static C<int> member() => C(1);

  final T t;
  C(this.t);
}

void main() {
  C<bool> c = .member();
  print(c);
}

''',
      [error(CompileTimeErrorCode.invalidAssignment, 105, 9)],
    );
  }
}
