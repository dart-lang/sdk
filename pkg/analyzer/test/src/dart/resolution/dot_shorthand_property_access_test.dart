// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandPropertyAccessResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DotShorthandPropertyAccessResolutionTest
    extends PubPackageResolutionTest {
  test_chain_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C get member => C(1);
  int x;
  C(this.x);
  C method() => C(1);
}

void main() {
  C c = .member.method();
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@getter::member
    staticType: C
  isDotShorthand: false
  staticType: C
''');
  }

  test_chain_property() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C get member => C(1);
  int x;
  C(this.x);
  C get property => C(1);
}

void main() {
  C c = .member.property;
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@getter::member
    staticType: C
  isDotShorthand: false
  staticType: C
''');
  }

  test_class_basic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static C get member => C(1);
  int x;
  C(this.x);
}

void main() {
  C c = .member;
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@getter::member
    staticType: C
  isDotShorthand: true
  staticType: C
''');
  }

  test_const_assert_class() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class Integer {
  static const Integer one = const Integer._(1);
  final int integer;
  Integer(this.integer);
  const Integer._(this.integer);
}

class CAssert {
  const CAssert.one(Integer i): assert(i == .one);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: one
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: Integer
    lookupType: Integer
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::Integer::@getter::one
    invokeType: Integer Function()
    type: Integer
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Integer
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: one
    element: <testLibrary>::@class::Integer::@getter::one
    staticType: Integer
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Integer
''');
  }

  test_const_assert_enum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum Color { red, green, blue }

class CAssert {
  const CAssert.blue(Color color): assert(color == .blue);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: blue
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: Color
    lookupType: Color
  resolution: GetterInvocationResolution
    element: <testLibrary>::@enum::Color::@getter::blue
    invokeType: Color Function()
    type: Color
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Color
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: blue
    element: <testLibrary>::@enum::Color::@getter::blue
    staticType: Color
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: Color
''');
  }

  test_const_class() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static const C member = const C._(1);
  final int x;
  C(this.x);
  const C._(this.x);
}

void main() {
  const C c = .member;
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@getter::member
    staticType: C
  isDotShorthand: true
  staticType: C
''');
  }

  test_const_enum() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum Color { red, green, blue }

void main() {
  const Color c = .blue;
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: blue
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: Color
    lookupType: Color
  resolution: GetterInvocationResolution
    element: <testLibrary>::@enum::Color::@getter::blue
    invokeType: Color Function()
    type: Color
  staticType: Color
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: blue
    element: <testLibrary>::@enum::Color::@getter::blue
    staticType: Color
  isDotShorthand: true
  staticType: Color
''');
  }

  test_const_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type C(int x) {
  static const C member = const C._(1);
  const C._(this.x);
}

void main() {
  const C c = .member;
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extensionType::C::@getter::member
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibrary>::@extensionType::C::@getter::member
    staticType: C
  isDotShorthand: true
  staticType: C
''');
  }

  test_enum_basic() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum C { red }

void main() {
  C c = .red;
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: red
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@enum::C::@getter::red
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: red
    element: <testLibrary>::@enum::C::@getter::red
    staticType: C
  isDotShorthand: true
  staticType: C
''');
  }

  test_equality() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static C get member => C(1);
  int x;
  C(this.x);
}

void main() {
  C lhs = C.member;
  bool b = lhs == .member;
  print(b);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::member
    invokeType: C Function()
    type: C
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <testLibrary>::@class::C::@getter::member
    staticType: C
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: C
''');
  }

  test_equality_extensionOverride() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0) == .member;
//     ^^
// [diag.undefinedExtensionOperator] The operator '==' isn't defined for the extension 'E'.
//        ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: InvalidType
''');
  }

  test_equality_extensionOverride_neq() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0) != .member;
//     ^^
// [diag.undefinedExtensionOperator] The operator '==' isn't defined for the extension 'E'.
//        ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: InvalidType
''');
  }

  test_equality_indexExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C(this.x);
  static List<C> instances = [C(1)];
}

void main() {
  print(C(1) == .instances[0]);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: instances
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::instances
    invokeType: List<C> Function()
    type: List<C>
  staticType: List<C>
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: instances
    element: <testLibrary>::@class::C::@getter::instances
    staticType: List<C>
  isDotShorthand: false
  staticType: List<C>
''');
  }

  test_equality_nullAssert() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C(this.x);
  static C? nullable = C(1);
}

main() {
  print(C(1) == .nullable!);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: nullable
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::nullable
    invokeType: C? Function()
    type: C?
  staticType: C?
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: nullable
    element: <testLibrary>::@class::C::@getter::nullable
    staticType: C?
  isDotShorthand: false
  staticType: C?
''');
  }

  test_equality_nullAssert_chain() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C(this.x);
  static C? nullable = C(1);
  C? member = C(1);
}

main() {
  print(C(1) == .nullable!.member!);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: nullable
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::nullable
    invokeType: C? Function()
    type: C?
  staticType: C?
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: nullable
    element: <testLibrary>::@class::C::@getter::nullable
    staticType: C?
  isDotShorthand: false
  staticType: C?
''');
  }

  test_equality_pattern() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum Color { red, blue }

void main() {
  Color c = Color.red;
  if (c case == .blue) print('ok');
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: blue
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: Color
    lookupType: Color
  resolution: GetterInvocationResolution
    element: <testLibrary>::@enum::Color::@getter::blue
    invokeType: Color Function()
    type: Color
  staticType: Color
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: blue
    element: <testLibrary>::@enum::Color::@getter::blue
    staticType: Color
  isDotShorthand: true
  staticType: Color
''');
  }

  test_equality_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

class B extends A {
  const B();
  static const member = B();
  bool test() => super == .member;
//                        ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
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
  static const member = B();
  bool test() => super != .member;
//                        ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
  staticType: InvalidType
''');
  }

  test_error_context_invalid() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C { }

void main() {
  C Function() c = .member;
//                 ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: C Function()
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  staticType: InvalidType
''');
  }

  test_error_context_none() async {
    var result = await resolveTestCodeWithDiagnostics('''
void main() {
  var c = .member;
//        ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  staticType: InvalidType
''');
  }

  test_error_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C { }

void main() {
  C c = .getter;
//       ^^^^^^
// [diag.dotShorthandUndefinedGetter] The static getter 'getter' isn't defined for the context type 'C'.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: getter
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: getter
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  staticType: InvalidType
''');
  }

  test_error_unresolved_new() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  C.named();
}

void main() {
  C c = .new;
//       ^^^
// [diag.dotShorthandUndefinedGetter] The static getter 'new' isn't defined for the context type 'C'.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: new
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: new
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  staticType: InvalidType
''');
  }

  test_error_unresolved_setterOnly() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static set value(C value) {}
}

void main() {
  C c = .value;
//       ^^^^^
// [diag.dotShorthandUndefinedGetter] The static getter 'value' isn't defined for the context type 'C'.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: value
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: value
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  staticType: InvalidType
''');
  }

  test_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type C(int integer) {
  static C get one => C(1);
}

void main() {
  C c = .one;
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: one
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extensionType::C::@getter::one
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: one
    element: <testLibrary>::@extensionType::C::@getter::one
    staticType: C
  isDotShorthand: true
  staticType: C
''');
  }

  test_functionExpression_call_argument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static final C field = C();
  C call(int a) => this;
}

void main() {
  final C _ = .field(1);
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandNameExpression
    period: .
    name: field
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::field
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
  function: DotShorthandPropertyAccess
    period: .
    propertyName: SimpleIdentifier
      token: field
      element: <testLibrary>::@class::C::@getter::field
      staticType: C
    isDotShorthand: false
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

  test_functionExpression_call_extension_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static final C field = C();
}

extension CallC on C {
  C call() => this;
}

void main() {
  final C _ = .field();
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandNameExpression
    period: .
    name: field
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::field
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
  function: DotShorthandPropertyAccess
    period: .
    propertyName: SimpleIdentifier
      token: field
      element: <testLibrary>::@class::C::@getter::field
      staticType: C
    isDotShorthand: false
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@extension::CallC::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_functionExpression_call_extension_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C get getter => C();
}

extension CallC on C {
  C call() => this;
}

void main() {
  final C _ = .getter();
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandNameExpression
    period: .
    name: getter
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::getter
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
  function: DotShorthandPropertyAccess
    period: .
    propertyName: SimpleIdentifier
      token: getter
      element: <testLibrary>::@class::C::@getter::getter
      staticType: C
    isDotShorthand: false
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@extension::CallC::@method::call
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_functionExpression_call_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static final C field = C();
  C call() => this;
}

void main() {
  final C _ = .field();
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandNameExpression
    period: .
    name: field
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::field
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
  function: DotShorthandPropertyAccess
    period: .
    propertyName: SimpleIdentifier
      token: field
      element: <testLibrary>::@class::C::@getter::field
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

  test_functionExpression_call_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static final C field = C();
  C call<T>(T t) => this;
}

void main() {
  final C _ = .field<int>(1);
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandNameExpression
    period: .
    name: field
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::field
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
  function: DotShorthandPropertyAccess
    period: .
    propertyName: SimpleIdentifier
      token: field
      element: <testLibrary>::@class::C::@getter::field
      staticType: C
    isDotShorthand: false
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

  test_functionExpression_call_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C get getter => C();
  C call() => this;
}

void main() {
  final C _ = .getter();
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: DotShorthandNameExpression
    period: .
    name: getter
    isDotShorthand: false
    shorthandContext: ValidDotShorthandContextResolution
      contextType: C
      lookupType: C
    resolution: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::getter
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
  function: DotShorthandPropertyAccess
    period: .
    propertyName: SimpleIdentifier
      token: getter
      element: <testLibrary>::@class::C::@getter::getter
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

  test_functionExpression_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static final C field = C();
}

void main() {
  final C _ = .field();
//            ^^^^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: field
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::field
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: field
    element: <testLibrary>::@class::C::@getter::field
    staticType: C
  isDotShorthand: false
  staticType: C
''');
  }

  test_functionExpression_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C get getter => C();
}

void main() {
  final C _ = .getter();
//            ^^^^^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: getter
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::getter
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: getter
    element: <testLibrary>::@class::C::@getter::getter
    staticType: C
  isDotShorthand: false
  staticType: C
''');
  }

  test_functionReference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  static String foo<X>() => "C<$X>";

  @override
  bool operator ==(Object other) {
    return false;
  }
}

void test<T extends num>() {
  C() == .foo<T>;
}

main() {
  test<int>();
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  isDotShorthand: false
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C<dynamic>
    lookupType: C<dynamic>
  resolution: ExecutableTearOffResolution
    element: <testLibrary>::@class::C::@method::foo
    type: String Function<X>()
  staticType: String Function<X>()
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@method::foo
    staticType: String Function<X>()
  isDotShorthand: false
  staticType: String Function<X>()
''');
  }

  test_futureOr() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async';

enum C { red }

void main() {
  FutureOr<C> c = .red;
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: red
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: FutureOr<C>
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@enum::C::@getter::red
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: red
    element: <testLibrary>::@enum::C::@getter::red
    staticType: C
  isDotShorthand: true
  staticType: C
''');
  }

  test_futureOr_nested() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async';

enum C { red }

void main() {
  FutureOr<FutureOr<C>> c = .red;
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: red
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: FutureOr<FutureOr<C>>
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@enum::C::@getter::red
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: red
    element: <testLibrary>::@enum::C::@getter::red
    staticType: C
  isDotShorthand: true
  staticType: C
''');
  }

  test_mixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C(this.x);
}

mixin CMixin on C {
  static CMixin get mixinOne => _CWithMixin(1);
}

class _CWithMixin extends C with CMixin {
  _CWithMixin(super.x);
}

void main() {
  CMixin c = .mixinOne;
  print(c);
}

''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: mixinOne
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: CMixin
    lookupType: CMixin
  resolution: GetterInvocationResolution
    element: <testLibrary>::@mixin::CMixin::@getter::mixinOne
    invokeType: CMixin Function()
    type: CMixin
  staticType: CMixin
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: mixinOne
    element: <testLibrary>::@mixin::CMixin::@getter::mixinOne
    staticType: CMixin
  isDotShorthand: true
  staticType: CMixin
''');
  }

  test_postfixDecrement_indexExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static List<int> values = [1];
}

void f(Object o) {
  if (o is C) {
    o = .values[0]--;
//      ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  }
}
''');

    var node = result.findNode.incrementOrDecrement('[0]--');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ReceiverIndexExpression
      receiver: DotShorthandNameExpression
        period: .
        name: values
        isDotShorthand: false
        shorthandContext: InvalidDotShorthandContextResolution
          contextType: null
        resolution: InvalidNamedReadResolution
          type: InvalidType
          candidates
          recovery: <null>
        staticType: InvalidType
      leftBracket: [
      index: IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
      rightBracket: ]
      resolution: InvalidIndexReadResolution
        type: InvalidType
        recovery: <null>
      staticType: InvalidType
  operator: --
  operation: decrement
  position: postfix
  correspondingParameter: <null>
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: IndexExpression
    target: DotShorthandPropertyAccess
      period: .
      propertyName: SimpleIdentifier
        token: values
        element: <null>
        staticType: InvalidType
      isDotShorthand: false
      staticType: InvalidType
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: InvalidType
  operator: --
  correspondingParameter: <null>
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_postfixIncrement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C get member => C(1);
  int x;
  C(this.x);
}

void main() {
  C c = .member++;
//      ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
//             ^^
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  staticType: InvalidType
''');
  }

  test_prefixDecrement_indexExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static List<int> values = [1];
}

void f(Object o) {
  if (o is C) {
    o = --.values[0];
//        ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  }
}
''');

    var node = result.findNode.incrementOrDecrement('--.');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: --
  target: InvalidExpressionAssignmentTarget
    expression: ReceiverIndexExpression
      receiver: DotShorthandNameExpression
        period: .
        name: values
        isDotShorthand: false
        shorthandContext: InvalidDotShorthandContextResolution
          contextType: null
        resolution: InvalidNamedReadResolution
          type: InvalidType
          candidates
          recovery: <null>
        staticType: InvalidType
      leftBracket: [
      index: IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
      rightBracket: ]
      resolution: InvalidIndexReadResolution
        type: InvalidType
        recovery: <null>
      staticType: InvalidType
  operation: decrement
  position: prefix
  correspondingParameter: <null>
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: --
  operand: IndexExpression
    target: DotShorthandPropertyAccess
      period: .
      propertyName: SimpleIdentifier
        token: values
        element: <null>
        staticType: InvalidType
      isDotShorthand: false
      staticType: InvalidType
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: InvalidType
  correspondingParameter: <null>
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_prefixIncrement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C get member => C(1);
  int x;
  C(this.x);
}

void main() {
  C c = ++.member;
//        ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
//         ^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  print(c);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: member
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: null
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: member
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  staticType: InvalidType
''');
  }

  test_privateClass_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class _Private {
  static _Private get getter => _Private();
}

typedef Public = _Private;
final Public p = _Private();
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .getter;
//    ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: getter
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: getter
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: InvalidType
''');
  }

  test_privateClass_sameLibrary() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class _Private {
  static _Private get getter => _Private();
}

typedef Public = _Private;
final Public p = _Private();

void main() {
  var x = p;
  x = .getter;
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: getter
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::_Private::@getter::getter
    invokeType: _Private Function()
    type: _Private
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: getter
    element: <testLibrary>::@class::_Private::@getter::getter
    staticType: _Private
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: _Private
''');
  }

  test_privateEnum_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum _Private { one, two }

typedef Public = _Private;
final Public p = _Private.one;
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .two;
//    ^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: two
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: two
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: InvalidType
''');
  }

  test_privateEnum_sameLibrary() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum _Private { one, two }

typedef Public = _Private;
final Public p = _Private.one;

void main() {
  var x = p;
  x = .two;
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: two
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  resolution: GetterInvocationResolution
    element: <testLibrary>::@enum::_Private::@getter::two
    invokeType: _Private Function()
    type: _Private
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: two
    element: <testLibrary>::@enum::_Private::@getter::two
    staticType: _Private
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: _Private
''');
  }

  test_privateExtensionType_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension type _Private(int i) {
  static _Private get getter => _Private(0);
}

typedef Public = _Private;
final Public p = _Private(1);
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .getter;
//    ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: getter
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: getter
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: InvalidType
''');
  }

  test_privateExtensionType_sameLibrary() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type _Private(int i) {
  static _Private get getter => _Private(0);
}

typedef Public = _Private;
final Public p = _Private(1);

void main() {
  var x = p;
  x = .getter;
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: getter
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extensionType::_Private::@getter::getter
    invokeType: _Private Function()
    type: _Private
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: getter
    element: <testLibrary>::@extensionType::_Private::@getter::getter
    staticType: _Private
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: _Private
''');
  }

  test_privateMixin_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin _Private {
  static _Private get getter => C();
}

class C with _Private {}
typedef Public = _Private;
final Public p = C();
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void main() {
  var x = p;
  x = .getter;
//    ^^^^^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: getter
  isDotShorthand: true
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _Private
      alias: package:test/a.dart::@typeAlias::Public
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  correspondingParameter: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: getter
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: InvalidType
''');
  }

  test_privateMixin_sameLibrary() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin _Private {
  static _Private get getter => C();
}

class C with _Private {}
typedef Public = _Private;
final Public p = C();

void main() {
  var x = p;
  x = .getter;
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: getter
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: _Private
      alias: <testLibrary>::@typeAlias::Public
    lookupType: _Private
      alias: <testLibrary>::@typeAlias::Public
  resolution: GetterInvocationResolution
    element: <testLibrary>::@mixin::_Private::@getter::getter
    invokeType: _Private Function()
    type: _Private
  correspondingParameter: <null>
  staticType: _Private
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: getter
    element: <testLibrary>::@mixin::_Private::@getter::getter
    staticType: _Private
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: _Private
''');
  }

  test_tearOff_constructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C1 {
  C1.id();

  @override
  bool operator ==(Object other) => identical(C1.id, other);
}

main() {
  bool x = C1.id() == .id;
  print(x);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: id
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C1
    lookupType: C1
  resolution: ExecutableTearOffResolution
    element: <testLibrary>::@class::C1::@constructor::id
    type: C1 Function()
  correspondingParameter: <testLibrary>::@class::C1::@method::==::@formalParameter::other
  staticType: C1 Function()
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: id
    element: <testLibrary>::@class::C1::@constructor::id
    staticType: C1 Function()
  isDotShorthand: true
  correspondingParameter: <testLibrary>::@class::C1::@method::==::@formalParameter::other
  staticType: C1 Function()
''');
  }

  test_tearOff_constructor_abstract() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
Function fn() {
  return .new;
//       ^^^^
// [diag.tearoffOfGenerativeConstructorOfAbstractClass] A generative constructor of an abstract class can't be torn off.
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: new
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: Function
    lookupType: Function
  resolution: ExecutableTearOffResolution
    element: dart:core::@class::Function::@constructor::new
    type: Function Function()
  staticType: Function Function()
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: new
    element: dart:core::@class::Function::@constructor::new
    staticType: Function Function()
  isDotShorthand: true
  staticType: Function Function()
''');
  }

  test_tearOff_constructor_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  T t;
  C(this.t);
  C.id(this.t);
}

void main() {
  Object? o = C<int>(0);
  if (o is C<int>) {
    o = .new;
    if (o is Function) {
       o(1).t;
    }
  }
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: new
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C<int>
    lookupType: C<int>
  resolution: ExecutableTearOffResolution
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::C::@constructor::new
      substitution: {T: T}
    type: C<T> Function(T)
  correspondingParameter: <null>
  staticType: C<T> Function(T)
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: new
    element: <testLibrary>::@class::C::@constructor::new
    staticType: C<T> Function(T)
  isDotShorthand: true
  correspondingParameter: <null>
  staticType: C<T> Function(T)
''');
  }

  test_tearOff_constructor_new() async {
    var result = await resolveTestCodeWithDiagnostics('''
void main() {
  Object o = .new;
  print(o);
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: new
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: Object
    lookupType: Object
  resolution: ExecutableTearOffResolution
    element: dart:core::@class::Object::@constructor::new
    type: Object Function()
  staticType: Object Function()
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: new
    element: dart:core::@class::Object::@constructor::new
    staticType: Object Function()
  isDotShorthand: true
  staticType: Object Function()
''');
  }

  test_undefinedGetter_message() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f() => .foo;
//          ^^^
// [diag.dotShorthandUndefinedGetter] The static getter 'foo' isn't defined for the context type 'int'.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: int
    lookupType: int
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  staticType: InvalidType
''');
  }

  test_undefinedGetter_message_equalityRhs() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
bool f(int x) => x == .foo;
//                     ^^^
// [diag.dotShorthandUndefinedGetter] The static getter 'foo' isn't defined for the context type 'int'.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  isDotShorthand: true
  shorthandContext: ValidDotShorthandContextResolution
    contextType: int
    lookupType: int
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  correspondingParameter: dart:core::@class::num::@method::==::@formalParameter::other
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  isDotShorthand: true
  correspondingParameter: dart:core::@class::num::@method::==::@formalParameter::other
  staticType: InvalidType
''');
  }
}
