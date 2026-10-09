// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedExtensionMemberReadTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedExtensionMemberReadTest extends PubPackageResolutionTest {
  test_found_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
  set foo(int _) {}
}

void f() {
  E(0).foo += 1;
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@extension::E::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::E::@setter::foo
      acceptedType: int
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_found_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int? get foo => null;
  set foo(int? _) {}
}

void f() {
  E(0).foo ??= 1;
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@extension::E::@getter::foo
      invokeType: int? Function()
      type: int?
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::E::@setter::foo
      acceptedType: int?
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int?
  element: <null>
  staticType: int
''');
  }

  test_found_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
  set foo(int _) {}
}

void f() {
  E(0).foo++;
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@extension::E::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::E::@setter::foo
      acceptedType: int
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_found_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}

void f() {
  E(0).foo();
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
  operator: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@extension::E::@method::foo
    invokeType: void Function()
    type: void
  staticType: void
V1: MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_found_invocation_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void Function() get foo => () {};
}

void f() {
  E(0).foo();
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: ReceiverPropertyExtraction
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    operator: .
    name: foo
    resolution: GetterInvocationResolution
      element: <testLibrary>::@extension::E::@getter::foo
      invokeType: void Function() Function()
      type: void Function()
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: FunctionTypeInvocationResolution
    invokeType: void Function()
    type: void
  staticType: void
V1: FunctionExpressionInvocation
  function: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@getter::foo
      staticType: void Function()
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_found_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
}

void f() {
  E(0).foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extension::E::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_found_propertyExtraction_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int get foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.E(0).foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: package:test/a.dart::@extension::E::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: ExtensionOverride
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@extension::E::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_found_propertyExtraction_privateName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get _foo => 0;
}

void f() {
  E(0)._foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
  operator: .
  name: _foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extension::E::@getter::_foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    element: <testLibrary>::@extension::E::@getter::_foo
    staticType: int
  staticType: int
''');
  }

  test_notFound_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0).foo += 1;
//     ^^^
// [diag.undefinedExtensionMemberReadNotFound] The extension 'E' doesn't have an instance member named 'foo'.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    operator: .
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0).foo ??= 1;
//     ^^^
// [diag.undefinedExtensionMemberReadNotFound] The extension 'E' doesn't have an instance member named 'foo'.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    operator: .
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0).foo++;
//     ^^^
// [diag.undefinedExtensionMemberReadNotFound] The extension 'E' doesn't have an instance member named 'foo'.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    operator: .
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0).foo();
//     ^^^
// [diag.undefinedExtensionMemberReadNotFound] The extension 'E' doesn't have an instance member named 'foo'.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
  operator: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0).foo;
//     ^^^
// [diag.undefinedExtensionMemberReadNotFound] The extension 'E' doesn't have an instance member named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_extendedTypeHasGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

extension E on A {}

void f(A a) {
  E(a).foo;
//     ^^^
// [diag.undefinedExtensionMemberReadNotFound] The extension 'E' doesn't have an instance member named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        UnqualifiedNameExpression
          name: a
          resolution: VariableReadResolution
            element: <testLibrary>::@function::f::@formalParameter::a
            type: A
          correspondingParameter: <null>
          staticType: A
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: A
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.E(0).foo;
//       ^^^
// [diag.undefinedExtensionMemberReadNotFound] The extension 'E' doesn't have an instance member named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: ExtensionOverride
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_privateName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0)._foo;
//     ^^^^
// [diag.undefinedExtensionMemberReadNotFound] The extension 'E' doesn't have an instance member named '_foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_private_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int get _foo => 0;
  set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  E(0)._foo += 1;
//     ^^^^
// [diag.undefinedExtensionMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: package:test/a.dart::@extension::E
      extendedType: int
    operator: .
    name: _foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: package:test/a.dart::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_ifNullAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int? get _foo => null;
  set _foo(int? _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  E(0)._foo ??= 1;
//     ^^^^
// [diag.undefinedExtensionMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: package:test/a.dart::@extension::E
      extendedType: int
    operator: .
    name: _foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: package:test/a.dart::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_increment() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int get _foo => 0;
  set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  E(0)._foo++;
//     ^^^^
// [diag.undefinedExtensionMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: package:test/a.dart::@extension::E
      extendedType: int
    operator: .
    name: _foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: package:test/a.dart::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  void _foo() {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  E(0)._foo();
//     ^^^^
// [diag.undefinedExtensionMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
  operator: .
  name: _foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int get _foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  E(0)._foo;
//     ^^^^
// [diag.undefinedExtensionMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction_setterOnly() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  E(0)._foo;
//     ^^^^
// [diag.undefinedExtensionMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_setterOnly_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _) {}
}

void f() {
  E(0).foo += 1;
//     ^^^
// [diag.undefinedExtensionMemberReadSetterOnly] There's a setter 'foo' in the extension 'E', but no getter.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    operator: .
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@extension::E::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::E::@setter::foo
      acceptedType: int
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int? _) {}
}

void f() {
  E(0).foo ??= 1;
//     ^^^
// [diag.undefinedExtensionMemberReadSetterOnly] There's a setter 'foo' in the extension 'E', but no getter.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    operator: .
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@extension::E::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::E::@setter::foo
      acceptedType: int?
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int?
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _) {}
}

void f() {
  E(0).foo++;
//     ^^^
// [diag.undefinedExtensionMemberReadSetterOnly] There's a setter 'foo' in the extension 'E', but no getter.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    operator: .
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@extension::E::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::E::@setter::foo
      acceptedType: int
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _) {}
}

void f() {
  E(0).foo();
//     ^^^
// [diag.undefinedExtensionMemberReadSetterOnly] There's a setter 'foo' in the extension 'E', but no getter.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
  operator: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_setterOnly_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(int _) {}
}

void f() {
  E(0).foo;
//     ^^^
// [diag.undefinedExtensionMemberReadSetterOnly] There's a setter 'foo' in the extension 'E', but no getter.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_static_propertyExtraction_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo => 0;
}

void f() {
  E(0).foo;
//     ^^^
// [diag.extensionOverrideAccessToStaticMember] An extension override can't be used to access a static member from an extension.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extension::E::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_static_propertyExtraction_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _) {}
}

void f() {
  E(0).foo;
//     ^^^
// [diag.extensionOverrideAccessToStaticMember] An extension override can't be used to access a static member from an extension.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }
}
