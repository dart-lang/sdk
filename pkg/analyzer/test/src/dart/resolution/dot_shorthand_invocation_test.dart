// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    element: <testLibraryFragment>::@class::C::@method::member#element
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
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
    element: <testLibraryFragment>::@class::C::@method::member#element
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
          baseElement: <testLibraryFragment>::@class::C::@method::member::@parameter::x#element
          substitution: {U: int}
        staticType: int
    rightParenthesis: )
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
    element: <testLibraryFragment>::@class::C::@method::member#element
    staticType: C Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@method::member::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticInvokeType: C Function(int)
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
    element: <testLibraryFragment>::@class::C::@method::member#element
    staticType: C Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@method::member::@parameter::x#element
        staticType: int
    rightParenthesis: )
  correspondingParameter: dart:core::<fragment>::@class::Object::@method::==::@parameter::other#element
  staticInvokeType: C Function(int)
  staticType: C
''');
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
    element: <testLibraryFragment>::@extensionType::C::@method::one#element
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
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
    element: <testLibraryFragment>::@class::C::@method::member#element
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
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
    element: <testLibraryFragment>::@class::C::@method::member#element
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
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
    element: <testLibraryFragment>::@mixin::CMixin::@method::mixinOne#element
    staticType: CMixin Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
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
    element: <testLibraryFragment>::@class::C::@method::memberType#element
    staticType: C<U> Function<U, V>(U)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DotShorthandConstructorInvocation
        period: .
        constructorName: SimpleIdentifier
          token: new
          element: ConstructorMember
            baseElement: <testLibraryFragment>::@class::C::@constructor::new#element
            substitution: {T: C<dynamic>}
          staticType: null
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            DotShorthandInvocation
              period: .
              memberName: SimpleIdentifier
                token: member
                element: <testLibraryFragment>::@class::C::@method::member#element
                staticType: C<int> Function()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: FieldFormalParameterMember
                baseElement: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
                substitution: {T: C<dynamic>}
              staticInvokeType: C<int> Function()
              staticType: C<int>
          rightParenthesis: )
        correspondingParameter: ParameterMember
          baseElement: <testLibraryFragment>::@class::C::@method::memberType::@parameter::u#element
          substitution: {U: C<C<dynamic>>, V: dynamic}
        staticType: C<C<dynamic>>
    rightParenthesis: )
  staticInvokeType: C<C<C<dynamic>>> Function(C<C<dynamic>>)
  staticType: C<C<C<dynamic>>>
  typeArgumentTypes
    C<C<dynamic>>
    dynamic
''');
  }
}
