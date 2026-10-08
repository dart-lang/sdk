// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedExtensionMemberWriteTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedExtensionMemberWriteTest extends PubPackageResolutionTest {
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

  test_found_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
  set foo(int _) {}
}

void f() {
  E(0).foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
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
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::E::@setter::foo
      acceptedType: int
  operator: =
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  set foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.E(0).foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
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
    read: <null>
    write: SetterInvocationResolution
      element: package:test/a.dart::@extension::E::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
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
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@extension::E::@setter::foo
  writeType: int
  element: <null>
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

  test_getterOnly_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
}

void f() {
  E(0).foo += 1;
//     ^^^
// [diag.undefinedExtensionMemberWriteGetterOnly] There's a getter 'foo' in the extension 'E', but no setter.
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
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
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
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_getterOnly_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
}

void f() {
  E(0).foo = 1;
//     ^^^
// [diag.undefinedExtensionMemberWriteGetterOnly] There's a getter 'foo' in the extension 'E', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
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
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int? get foo => null;
}

void f() {
  E(0).foo ??= 1;
//     ^^^
// [diag.undefinedExtensionMemberWriteGetterOnly] There's a getter 'foo' in the extension 'E', but no setter.
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
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
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
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
}

void f() {
  E(0).foo++;
//     ^^^
// [diag.undefinedExtensionMemberWriteGetterOnly] There's a getter 'foo' in the extension 'E', but no setter.
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
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
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
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_instanceField_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  final int foo = 0;
//          ^^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
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
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
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
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_instanceField_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  final int foo = 0;
//          ^^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}

void f() {
  E(0).foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
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
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_instanceField_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  final int? foo = null;
//           ^^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
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
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
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
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_instanceField_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  final int foo = 0;
//          ^^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
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
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
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
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_notFound_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E(0).foo = 1;
//     ^^^
// [diag.undefinedExtensionMemberWriteNotFound] The extension 'E' doesn't have an instance setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
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
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_extendedTypeHasSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}

extension E on A {}

void f(A a) {
  E(a).foo = 1;
//     ^^^
// [diag.undefinedExtensionMemberWriteNotFound] The extension 'E' doesn't have an instance setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
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
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
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
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.E(0).foo = 1;
//       ^^^
// [diag.undefinedExtensionMemberWriteNotFound] The extension 'E' doesn't have an instance setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
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
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
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
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_private_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  E(0)._foo = 1;
//     ^^^^
// [diag.undefinedExtensionMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
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
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
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
      element: package:test/a.dart::@extension::E
      extendedType: int
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_static_directAssignment_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int foo = 0;
}

void f() {
  E(0).foo = 1;
//     ^^^
// [diag.extensionOverrideAccessToStaticMember] An extension override can't be used to access a static member from an extension.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
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
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::E::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::value
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_static_directAssignment_finalField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static final int foo = 0;
}

void f() {
  E(0).foo = 1;
//     ^^^
// [diag.extensionOverrideAccessToStaticMember] An extension override can't be used to access a static member from an extension.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
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
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_static_directAssignment_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo => 0;
}

void f() {
  E(0).foo = 1;
//     ^^^
// [diag.extensionOverrideAccessToStaticMember] An extension override can't be used to access a static member from an extension.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
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
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}

void f() {
  E(0).foo += 1;
//     ^^^
// [diag.undefinedExtensionMemberWriteWrongKind] The method 'foo' in the extension 'E' can't be assigned to.
//         ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'void Function()'.
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
    read: ExecutableTearOffResolution
      element: <testLibrary>::@extension::E::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@method::foo
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
  readElement: <testLibrary>::@extension::E::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@extension::E::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}

void f() {
  E(0).foo = 1;
//     ^^^
// [diag.undefinedExtensionMemberWriteWrongKind] The method 'foo' in the extension 'E' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
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
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
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
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}

void f() {
  E(0).foo ??= 1;
//     ^^^
// [diag.undefinedExtensionMemberWriteWrongKind] The method 'foo' in the extension 'E' can't be assigned to.
//             ^^
// [diag.deadCode] Dead code.
//             ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
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
    read: ExecutableTearOffResolution
      element: <testLibrary>::@extension::E::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@method::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: Object
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
  readElement: <testLibrary>::@extension::E::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@extension::E::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: Object
''');
  }

  test_wrongKind_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}

void f() {
  E(0).foo++;
//     ^^^
// [diag.undefinedExtensionMemberWriteWrongKind] The method 'foo' in the extension 'E' can't be assigned to.
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
    read: ExecutableTearOffResolution
      element: <testLibrary>::@extension::E::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@method::foo
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: void Function()
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
  readElement: <testLibrary>::@extension::E::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@extension::E::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: void Function()
''');
  }
}
