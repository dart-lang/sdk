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
  test_assert_lhs() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int x;
  const C.named(this.x);
}

class CAssert {
  const CAssert.regular(C ctor)
    : assert(const .named(1) == ctor);
//           ^^^^^^^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation2
  constKeyword: const
  period: .
  name: named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  element: <null>
  staticType: dynamic
V1: DotShorthandConstructorInvocation
  constKeyword: const
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <null>
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  staticType: dynamic
''');
  }

  test_basic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandInvocation
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
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
    arguments2
      IntegerLiteral
        literal: 1
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::C::@method::member::@formalParameter::x
          substitution: {U: int}
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C<dynamic>
    lookupType: C<dynamic>
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C<dynamic> Function(int)
    type: C<dynamic>
  staticType: C<dynamic>
  typeArgumentTypes
    int
V1: DotShorthandInvocation
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@method::member::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C Function(int)
    type: C
  staticType: C
V1: DotShorthandInvocation
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

  test_chain_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandInvocation
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandInvocation
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@method::member::@formalParameter::x
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C Function(int)
    type: C
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: C
V1: DotShorthandInvocation
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

  test_equality_extensionOverride() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0) == .member();
//     ^^
// [diag.undefinedExtensionOperator] The operator '==' isn't defined for the extension 'E'.
//        ^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_equality_extensionOverride_neq() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0) != .member();
//     ^^
// [diag.undefinedExtensionOperator] The operator '==' isn't defined for the extension 'E'.
//        ^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_equality_indexExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C(this.x);
  static List<C> instances() => [C(1)];
}

void main() {
  print(C(1) == .instances()[0]);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: instances
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::instances
    invokeType: List<C> Function()
    type: List<C>
  staticType: List<C>
V1: DotShorthandInvocation
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

  test_equality_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

class B extends A {
  const B();
  static B member() => B();
  bool test() => super == .member();
//                        ^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_equality_super_neq() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

class B extends A {
  const B();
  static B member() => B();
  bool test() => super != .member();
//                        ^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_context_invalid() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C { }

void main() {
  C Function() c = .member();
//                  ^^^^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'member' isn't defined for the context type 'C Function()'.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: C Function()
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_context_none() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void main() {
  var c = .member();
//        ^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_notStatic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C foo() => C();
}

void main() {
  final C c = .foo();
//             ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'foo' isn't defined for the context type 'C'.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C { }

void main() {
  C c = .member();
//       ^^^^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'member' isn't defined for the context type 'C'.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_unresolved_new() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C.named();
}

void main() {
  C c = .new();
//       ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'new' isn't defined for the context type 'C'.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: new
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type C(int integer) {
  static C one() => C(1);
}

void main() {
  C c = .one();
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: one
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@extensionType::C::@method::one
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandInvocation
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

  test_functionExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C member() => C();
}

void main() {
  final C _ = .member()();
//            ^^^^^^^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandInvocation
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

  test_functionExpression_call() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C member() => C();
  C call() => this;
}

void main() {
  final C _ = .member()();
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandMethodInvocation
    period: .
    name: member
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@class::C::@method::member
      invokeType: C Function()
      type: C
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::call
    invokeType: C Function()
    type: C
  staticType: C
V1: FunctionExpressionInvocation
  function: DotShorthandInvocation
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
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_functionExpression_call_argument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C member() => C();
  C call(int a) => this;
}

void main() {
  final C _ = .member()(1);
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandMethodInvocation
    period: .
    name: member
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@class::C::@method::member
      invokeType: C Function()
      type: C
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@method::call::@formalParameter::a
        staticType: int
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::call
    invokeType: C Function(int)
    type: C
  staticType: C
V1: FunctionExpressionInvocation
  function: DotShorthandInvocation
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
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::C::@method::call::@formalParameter::a
        staticType: int
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function(int)
  staticType: C
''');
  }

  test_functionExpression_call_extension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C member() => C();
}

extension CallC on C {
  C call() => this;
}

void main() {
  final C _ = .member()();
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandMethodInvocation
    period: .
    name: member
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@class::C::@method::member
      invokeType: C Function()
      type: C
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@extension::CallC::@method::call
    invokeType: C Function()
    type: C
  staticType: C
V1: FunctionExpressionInvocation
  function: DotShorthandInvocation
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
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@extension::CallC::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_functionExpression_call_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C member() => C();
  C call<T>(T t) => this;
}

void main() {
  final C _ = .member()<int>(1);
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandMethodInvocation
    period: .
    name: member
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@class::C::@method::member
      invokeType: C Function()
      type: C
    staticType: C
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
    arguments2
      IntegerLiteral
        literal: 1
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::C::@method::call::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::call
    invokeType: C Function(int)
    type: C
  staticType: C
  typeArgumentTypes
    int
V1: FunctionExpressionInvocation
  function: DotShorthandInvocation
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::C::@method::call::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function(int)
  staticType: C
  typeArgumentTypes
    int
''');
  }

  test_functionExpression_call_nested() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C member(C c) => C();
  static C one() => C(); 
  C call() => this;
}

void main() {
  C _ = .member(.one())();
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandMethodInvocation
    period: .
    name: member
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        DotShorthandMethodInvocation
          period: .
          name: one
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          isDotShorthand: true
          shorthandContext: ValidDotShorthandContextResolution
            contextType: C
            lookupType: C
          resolution: ExecutableInvocationResolution
            element: <testLibrary>::@class::C::@method::one
            invokeType: C Function()
            type: C
          correspondingParameter: <testLibrary>::@class::C::@method::member::@formalParameter::c
          staticType: C
      rightParenthesis: )
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@class::C::@method::member
      invokeType: C Function(C)
      type: C
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::call
    invokeType: C Function()
    type: C
  staticType: C
V1: FunctionExpressionInvocation
  function: DotShorthandInvocation
    period: .
    memberName: SimpleIdentifier
      token: member
      element: <testLibrary>::@class::C::@method::member
      staticType: C Function(C)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        DotShorthandInvocation
          period: .
          memberName: SimpleIdentifier
            token: one
            element: <testLibrary>::@class::C::@method::one
            staticType: C Function()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          isDotShorthand: true
          correspondingParameter: <testLibrary>::@class::C::@method::member::@formalParameter::c
          staticInvokeType: C Function()
          staticType: C
      rightParenthesis: )
    isDotShorthand: false
    staticInvokeType: C Function(C)
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_functionExpression_nested() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C member(C c) => C();
  static C one() => C(); 
}

void main() {
  C _ = .member(.one())();
//      ^^^^^^^^^^^^^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');

    var node = result.findNode.dotShorthandMethodInvocation('.member');
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      DotShorthandMethodInvocation
        period: .
        name: one
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        isDotShorthand: true
        shorthandContext: ValidDotShorthandContextResolution
          contextType: C
          lookupType: C
        resolution: ExecutableInvocationResolution
          element: <testLibrary>::@class::C::@method::one
          invokeType: C Function()
          type: C
        correspondingParameter: <testLibrary>::@class::C::@method::member::@formalParameter::c
        staticType: C
    rightParenthesis: )
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C Function(C)
    type: C
  staticType: C
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C Function(C)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DotShorthandInvocation
        period: .
        memberName: SimpleIdentifier
          token: one
          element: <testLibrary>::@class::C::@method::one
          staticType: C Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        isDotShorthand: true
        correspondingParameter: <testLibrary>::@class::C::@method::member::@formalParameter::c
        staticInvokeType: C Function()
        staticType: C
    rightParenthesis: )
  isDotShorthand: false
  staticInvokeType: C Function(C)
  staticType: C
''');
  }

  test_futureOr() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: FutureOr<C>
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandInvocation
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: FutureOr<FutureOr<C>>
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandInvocation
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: mixinOne
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: CMixin
    lookupType: CMixin
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@mixin::CMixin::@method::mixinOne
    invokeType: CMixin Function()
    type: CMixin
  staticType: CMixin
V1: DotShorthandInvocation
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.dotShorthandMethodInvocation('.memberType');
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: memberType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      DotShorthandConstructorInvocation2
        period: .
        name: new
        argumentList: ArgumentList
          leftParenthesis: (
          arguments2
            DotShorthandMethodInvocation
              period: .
              name: member
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              isDotShorthand: true
              shorthandContext: ValidDotShorthandContextResolution
                contextType: C<dynamic>
                lookupType: C<dynamic>
              resolution: ExecutableInvocationResolution
                element: <testLibrary>::@class::C::@method::member
                invokeType: C<int> Function()
                type: C<int>
              correspondingParameter: SubstitutedFieldFormalParameterElementImpl
                baseElement: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                substitution: {T: C<dynamic>}
              staticType: C<int>
          rightParenthesis: )
        isDotShorthand: true
        shorthandContext: ValidDotShorthandContextResolution
          contextType: C<C<dynamic>>
          lookupType: C<C<dynamic>>
        element: SubstitutedConstructorElementImpl
          baseElement: <testLibrary>::@class::C::@constructor::new
          substitution: {T: C<dynamic>}
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::C::@method::memberType::@formalParameter::u
          substitution: {U: C<C<dynamic>>, V: dynamic}
        staticType: C<C<dynamic>>
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C<C<C<dynamic>>>
    lookupType: C<C<C<dynamic>>>
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::memberType
    invokeType: C<C<C<dynamic>>> Function(C<C<dynamic>>)
    type: C<C<C<dynamic>>>
  staticType: C<C<C<dynamic>>>
  typeArgumentTypes
    C<C<dynamic>>
    dynamic
V1: DotShorthandInvocation
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
          element: SubstitutedConstructorElementImpl
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
              correspondingParameter: SubstitutedFieldFormalParameterElementImpl
                baseElement: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
                substitution: {T: C<dynamic>}
              staticInvokeType: C<int> Function()
              staticType: C<int>
          rightParenthesis: )
        isDotShorthand: true
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C member() => C(1);
  int x;
  C(this.x);
}

void main() {
  C c = .member()++;
//      ^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
//               ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_prefixOperator() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C member() => C(1);
  int x;
  C(this.x);
}

void main() {
  C c = ++.member();
//        ^^^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
//                ^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .new();
//     ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'new' isn't defined for the context type '_Private'.
  x = .named();
//     ^^^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'named' isn't defined for the context type '_Private'.
  print(x);
}
''');

    var node = result.findNode.dotShorthandMethodInvocation('.new');
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: new
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');

    var namedNode = result.findNode.dotShorthandMethodInvocation('.named');
    assertResolvedNodeText(namedNode, r'''
DotShorthandMethodInvocation
  period: .
  name: named
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: named
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_privateClass_otherLibrary_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class _Private {
  static _Private instance() => _Private();
}

typedef Public = _Private;
final Public p = _Private();
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .instance();
//     ^^^^^^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'instance' isn't defined for the context type '_Private'.
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: instance
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: instance
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_privateClass_sameLibrary_constructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation2
  period: .
  name: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  element: <testLibrary>::@class::_Private::@constructor::new
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandConstructorInvocation
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
''');
  }

  test_privateClass_sameLibrary_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: instance
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::_Private::@method::instance
    invokeType: _Private Function()
    type: _Private
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandInvocation
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .a();
//     ^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'a' isn't defined for the context type '_Private'.
  print(x);
}
''');

    var node = result.findNode.dotShorthandMethodInvocation('.a');
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: a
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: a
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .instance();
//     ^^^^^^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'instance' isn't defined for the context type '_Private'.
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: instance
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: instance
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_privateEnum_sameLibrary_constructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation2
  period: .
  name: a
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  element: <testLibrary>::@enum::_Private::@constructor::a
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandConstructorInvocation
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
''');
  }

  test_privateEnum_sameLibrary_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: instance
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@enum::_Private::@method::instance
    invokeType: _Private Function()
    type: _Private
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandInvocation
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .new(1);
//     ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'new' isn't defined for the context type '_Private'.
  x = .named(1);
//     ^^^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'named' isn't defined for the context type '_Private'.
  print(x);
}
''');

    var node = result.findNode.dotShorthandMethodInvocation('.new');
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: new
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');

    var namedNode = result.findNode.dotShorthandMethodInvocation('.named');
    assertResolvedNodeText(namedNode, r'''
DotShorthandMethodInvocation
  period: .
  name: named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: named
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_privateExtensionType_otherLibrary_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension type _Private(int it) {
  static _Private instance() => _Private(0);
}

typedef Public = _Private;
final Public p = _Private(1);
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .instance();
//     ^^^^^^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'instance' isn't defined for the context type '_Private'.
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: instance
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: instance
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_privateExtensionType_sameLibrary_constructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type _Private(int i) {}

typedef Public = _Private;
final Public p = _Private(1);

void main() {
  var x = p;
  x = .new(1);
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandConstructorInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandConstructorInvocation2
  period: .
  name: new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@extensionType::_Private::@constructor::new::@formalParameter::i
        staticType: int
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  element: <testLibrary>::@extensionType::_Private::@constructor::new
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandConstructorInvocation
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
''');
  }

  test_privateExtensionType_sameLibrary_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: instance
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@extensionType::_Private::@method::instance
    invokeType: _Private Function()
    type: _Private
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandInvocation
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .instance();
//     ^^^^^^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'instance' isn't defined for the context type '_Private'.
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: instance
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: instance
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_privateMixin_sameLibrary_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: instance
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@mixin::_Private::@method::instance
    invokeType: _Private Function()
    type: _Private
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandInvocation
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C member({required int x}) => C(x);
  int x;
  C(this.x);
}

void main() {
  C c = .member();
//       ^^^^^^
// [diag.missingRequiredArgument] The named parameter 'x' is required, but there's no corresponding argument.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C Function({required int x})
    type: C
  staticType: C
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C Function({required int x})
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: C Function({required int x})
  staticType: C
''');
  }

  test_typeParameters_inference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  static C<X> foo<X>(X x) => new C<X>();
  C<U> cast<U>() => new C<U>();
}
void main() {
  C<bool> c = .foo("String").cast();
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      SimpleStringLiteral
        literal: "String"
    rightParenthesis: )
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C<bool>
    lookupType: C<bool>
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::foo
    invokeType: C<String> Function(String)
    type: C<String>
  staticType: C<String>
  typeArgumentTypes
    String
V1: DotShorthandInvocation
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  static C<int> member() => C(1);

  final T t;
  C(this.t);
}

void main() {
  C<bool> c = .member();
//            ^^^^^^^^^
// [diag.invalidAssignment] A value of type 'C<int>' can't be assigned to a variable of type 'C<bool>'.
  print(c);
}

''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: member
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C<bool>
    lookupType: C<bool>
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::member
    invokeType: C<int> Function()
    type: C<int>
  staticType: C<int>
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@method::member
    staticType: C<int> Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: C<int> Function()
  staticType: C<int>
''');
  }

  test_undefinedInvocation_message() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f() => .foo();
//          ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'foo' isn't defined for the context type 'int'.
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: int
    lookupType: int
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_undefinedInvocation_message_equalityRhs() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
bool f(int x) => x == .foo();
//                     ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'foo' isn't defined for the context type 'int'.
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: int
    lookupType: int
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: dart:core::@class::num::@method::==::@formalParameter::other
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
  correspondingParameter: dart:core::@class::num::@method::==::@formalParameter::other
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }
}
