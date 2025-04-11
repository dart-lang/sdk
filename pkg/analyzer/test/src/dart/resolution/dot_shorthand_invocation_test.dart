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
  test_dotShorthand_basic() async {
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

  test_dotShorthand_basic_generic() async {
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

  test_dotShorthand_basic_parameter() async {
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
}
