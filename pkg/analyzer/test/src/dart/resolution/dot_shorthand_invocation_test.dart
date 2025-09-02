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
        element2: dart:core::@class::int
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
