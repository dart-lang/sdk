// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInInvalidContextTest);
    defineReflectiveTests(SuperInInvalidContextAnonymousMethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SuperInInvalidContextAnonymousMethodTest
    extends PubPackageResolutionTest {
  @override
  List<Feature> get experimentalFeatures => [
    ...super.experimentalFeatures,
    Feature.anonymous_methods,
  ];

  test_call() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int call() => 0;
}

class B extends A {}

void f(B b) {
  b.{
    super();
//  ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
  };
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: SuperReference
    superKeyword: super
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: FunctionExpressionInvocation
  function: SuperExpression
    superKeyword: super
    staticType: B
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_index() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator [](int index) => 0;
}

class B extends A {}

void f(B b) {
  b.{
    super[0];
//  ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
  };
}
''');

    var node = result.findNode.singleReceiverIndexExpression;
    assertResolvedNodeText(node, r'''
ReceiverIndexExpression
  receiver: SuperReference
    superKeyword: super
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  resolution: InvalidIndexReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: IndexExpression
  target: SuperExpression
    superKeyword: super
    staticType: B
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: InvalidType
''');
  }

  test_unaryOperator() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator -() => 0;
}

class B extends A {}

void f(B b) {
  b.{
    -super;
//   ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
  };
}
''');

    var node = result.findNode.singleUnaryOperatorInvocation;
    assertResolvedNodeText(node, r'''
UnaryOperatorInvocation
  operator: -
  operand: SuperReference
    superKeyword: super
  unaryOperator: negate
  element: <null>
  staticType: InvalidType
V1: PrefixExpression
  operator: -
  operand: SuperExpression
    superKeyword: super
    staticType: B
  element: <null>
  staticType: InvalidType
''');
  }
}

@reflectiveTest
class SuperInInvalidContextTest extends PubPackageResolutionTest {
  test_binaryExpression() async {
    await resolveTestCodeWithDiagnostics('''
var v = super + 0;
//      ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
''');
  }

  test_class_field_instance() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

class B extends A {
  var f = super.foo;
//        ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_class_field_instance_late() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int foo() => 0;
}

class B extends A {
  late var f = super.foo();
}
''');
  }

  test_class_field_static() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

class B extends A {
  static var f = super.foo;
//               ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_class_field_static_late() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

class B extends A {
  static late var f = super.foo;
//                    ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_constructorInitializer_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m() {}
}
class B extends A {
  var f;
  B() : f = super.m();
//          ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_constructorInitializer_super() async {
    await resolveTestCodeWithDiagnostics(r'''
class S {
  final int f;
  S(this.f);
}

class C extends S {
  C() : super(super.f);
//            ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_constructorInitializer_this() async {
    await resolveTestCodeWithDiagnostics(r'''
class S {
  final int f;
  S(this.f);
}

class C extends S {
  C() : this.other(super.f);
//                 ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
  C.other(int a) : super(a);
}
''');
  }

  test_factoryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m() {}
}
class B extends A {
  factory B() {
    super.m();
//  ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
    return B._();
  }
  B._();
}
''');
  }

  test_instanceVariableInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var a;
}
class B extends A {
 var b = super.a;
//       ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_methodInvocation_extension_field_static() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {
  static final v = super.foo();
//                 ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_methodInvocation_extension_method_static() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {
  static void foo() {
    super.foo();
//  ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
  }
}
''');
  }

  test_mixin_field_instance() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

mixin M on A {
  var f = super.foo;
//        ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_mixin_field_instance_late() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

mixin M on A {
  late var f = super.foo;
}
''');
  }

  test_mixin_field_static() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

mixin M on A {
  static var f = super.foo;
//               ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_mixin_field_static_late() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

mixin M on A {
  static late var f = super.foo;
//                    ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_propertyAccess_extension_field_static() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

extension E on int {
  static var f = super.foo;
//               ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_propertyAccess_extension_field_static_late() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

extension E on int {
  static late var f = super.foo;
//                    ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static m() {}
}
class B extends A {
  static n() { return super.m(); }
//                    ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');

    var node = result.findNode.receiverMethodInvocation('super.m()');
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: m
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: InvalidType
  operator: .
  methodName: SimpleIdentifier
    token: m
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_staticVariableInitializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static int a = 0;
}
class B extends A {
  static int b = super.a;
//               ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: a
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: InvalidType
  operator: .
  propertyName: SimpleIdentifier
    token: a
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  super.f();
//^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
}
''');
  }

  test_topLevelVariableInitializer() async {
    await resolveTestCodeWithDiagnostics('''
var v = super.y;
//      ^^^^^
// [diag.superInInvalidContext] Invalid context for 'super' invocation.
''');
  }

  test_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m() {}
}
class B extends A {
  B() {
    var v = super.m();
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  }
  n() {
    var v = super.m();
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  }
}
''');
  }
}
