// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandConstructorInvocationResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DotShorthandConstructorInvocationResolutionTest
    extends PubPackageResolutionTest {
  test_chain_method() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
  C method() => C(1);
}

void main() {
  C c = .new(1).method();
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: <testLibraryFragment>::@class::C::@constructor::new#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }

  test_chain_property() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
  C get property => C(1);
}

void main() {
  C c = .new(1).property;
  print(c);
}
''');

    var identifier = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: <testLibraryFragment>::@class::C::@constructor::new#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }

  test_constructor_named() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C.named(this.x);
}

void main() {
  C c = .named(1);
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibraryFragment>::@class::C::@constructor::named#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }

  test_constructor_named_futureOr() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

class C<T> {
  T value;
  C.id(this.value);
}

void main() async {
  FutureOr<C?>? c = .id(2);
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: id
    element: ConstructorMember
      baseElement: <testLibraryFragment>::@class::C::@constructor::id#element
      substitution: {T: dynamic}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibraryFragment>::@class::C::@constructor::id::@parameter::value#element
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  staticType: C<dynamic>
''');
  }

  test_equality() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C.named(this.x);
}

void main() {
  C lhs = C.named(2);
  bool b = lhs == .named(1);
  print(b);
}
''');

    var identifier = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibraryFragment>::@class::C::@constructor::named#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
        staticType: int
    rightParenthesis: )
  correspondingParameter: dart:core::<fragment>::@class::Object::@method::==::@parameter::other#element
  staticType: C
''');
  }

  test_equality_inferTypeParameters() async {
    await assertNoErrorsInCode('''
void main() {
  bool x = <int>[] == .filled(2, '2');
  print(x);
}
''');

    var identifier = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: filled
    element: ConstructorMember
      baseElement: dart:core::<fragment>::@class::List::@constructor::filled#element
      substitution: {E: String}
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        correspondingParameter: ParameterMember
          baseElement: dart:core::<fragment>::@class::List::@constructor::filled::@parameter::length#element
          substitution: {E: String}
        staticType: int
      SimpleStringLiteral
        literal: '2'
    rightParenthesis: )
  correspondingParameter: dart:core::<fragment>::@class::Object::@method::==::@parameter::other#element
  staticType: List<String>
''');
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/59835',
    reason:
        'Constant evaluation for dot shorthand constructor invocations needs '
        'to be implemented.',
  )
  test_equality_pattern() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C.named(this.x);
}

void main() {
  C c = C.named(1);
  if (c case == .named(2)) print('ok');
}
''');

    var identifier = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(identifier, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibraryFragment>::@class::C::@constructor::named#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::named::@parameter::x#element
        staticType: int
    rightParenthesis: )
  correspondingParameter: dart:core::<fragment>::@class::Object::@method::==::@parameter::other#element
  staticType: C
''');
  }

  test_nested_invocation() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  static C member() => C(1);
  T x;
  C(this.x);
}

void main() {
  C<C> c = .new(.member());
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
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
          staticType: C<dynamic> Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
          substitution: {T: C<dynamic>}
        staticInvokeType: C<dynamic> Function()
        staticType: C<dynamic>
    rightParenthesis: )
  staticType: C<C<dynamic>>
''');
  }

  test_nested_property() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  static C get member => C(1);
  T x;
  C(this.x);
}

void main() {
  C<C> c = .new(.member);
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
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
      DotShorthandPropertyAccess
        period: .
        propertyName: SimpleIdentifier
          token: member
          element: <testLibraryFragment>::@class::C::@getter::member#element
          staticType: C<dynamic>
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
          substitution: {T: C<dynamic>}
        staticType: C<dynamic>
    rightParenthesis: )
  staticType: C<C<dynamic>>
''');
  }

  test_new() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C(this.x);
}

void main() {
  C c = .new(1);
  print(c);
}
''');

    var node = findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation
  period: .
  constructorName: SimpleIdentifier
    token: new
    element: <testLibraryFragment>::@class::C::@constructor::new#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::new::@parameter::x#element
        staticType: int
    rightParenthesis: )
  staticType: C
''');
  }
}
