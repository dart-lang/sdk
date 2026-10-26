// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedPrefixedNameWriteTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedPrefixedNameWriteTest extends PubPackageResolutionTest {
  test_const_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
const int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.undefinedPrefixedNameWriteConst] The constant 'foo' imported with the prefix 'p' can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
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
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_const_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
const int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteConst] The constant 'foo' imported with the prefix 'p' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_const_ifNullAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
const int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo ??= 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteConst] The constant 'foo' imported with the prefix 'p' can't be assigned to.
//          ^^
// [diag.deadCode] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_const_increment() async {
    newFile('$testPackageLibPath/a.dart', r'''
const int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.undefinedPrefixedNameWriteConst] The constant 'foo' imported with the prefix 'p' can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ++
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_final_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
final int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.undefinedPrefixedNameWriteFinal] The variable 'foo' imported with the prefix 'p' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
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
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_final_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
final int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteFinal] The variable 'foo' imported with the prefix 'p' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_ifNullAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
final int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo ??= 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteFinal] The variable 'foo' imported with the prefix 'p' is final, so it can't be assigned to.
//          ^^
// [diag.deadCode] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_increment() async {
    newFile('$testPackageLibPath/a.dart', r'''
final int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.undefinedPrefixedNameWriteFinal] The variable 'foo' imported with the prefix 'p' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ++
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_found_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo += 1;
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      type: int
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::foo
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
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_found_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo = 0;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/a.dart::@setter::foo::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/a.dart::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_setter() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library lib;
set y(int value) {}''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as x;
main() {
  x.y = 0;
}
''');
  }

  test_getterOnly_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.undefinedPrefixedNameWriteGetterOnly] There's a getter 'foo' in the libraries imported with the prefix 'p', but no setter.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
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
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_getterOnly_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteGetterOnly] There's a getter 'foo' in the libraries imported with the prefix 'p', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_ifNullAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo ??= 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteGetterOnly] There's a getter 'foo' in the libraries imported with the prefix 'p', but no setter.
//          ^^
// [diag.deadCode] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_increment() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.undefinedPrefixedNameWriteGetterOnly] There's a getter 'foo' in the libraries imported with the prefix 'p', but no setter.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ++
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_notFound_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteNotFound] The setter 'foo' isn't defined in the libraries imported with the prefix 'p'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
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

  test_notFound_directAssignment_ambiguousGetters() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');
    newFile('$testPackageLibPath/b.dart', r'''
int get foo => 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteNotFound] The setter 'foo' isn't defined in the libraries imported with the prefix 'p'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_hidden() async {
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p hide foo;

void f() {
  p.foo = 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteNotFound] The setter 'foo' isn't defined in the libraries imported with the prefix 'p'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
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

  test_notFound_directAssignment_syntheticName() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

void f() {
  p. = 0;
//   ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_private_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
int _foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p._foo = 0;
//  ^^^^
// [diag.undefinedPrefixedNameWritePrivate] The name '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
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

  test_private_directAssignment_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get _foo => 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p._foo = 0;
//  ^^^^
// [diag.undefinedPrefixedNameWritePrivate] The name '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
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
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.undefinedPrefixedNameWriteWrongKind] The function 'foo' imported with the prefix 'p' can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: package:test/a.dart::@function::foo
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@function::foo
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
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: package:test/a.dart::@function::foo
  readType: InvalidType
  writeElement: package:test/a.dart::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteWrongKind] The function 'foo' imported with the prefix 'p' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@function::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_directAssignment_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class Foo {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.Foo = 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteWrongKind] The class 'Foo' imported with the prefix 'p' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: Foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@class::Foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: Foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@class::Foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_directAssignment_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core;

void f() {
  core.dynamic = 0;
//     ^^^^^^^
// [diag.undefinedPrefixedNameWriteWrongKind] The type 'dynamic' imported with the prefix 'core' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: dynamic
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: dynamic
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: core
      element: <testLibraryFragment>::@prefix::core
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: dynamic
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: dynamic
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_directAssignment_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core;

void f() {
  core.Never = 0;
//     ^^^^^
// [diag.undefinedPrefixedNameWriteWrongKind] The type 'Never' imported with the prefix 'core' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: core
      period: .
      element: <testLibraryFragment>::@prefix::core
    name: Never
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: Never
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: core
      element: <testLibraryFragment>::@prefix::core
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: Never
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: Never
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_directAssignment_typeAlias() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef Foo = int;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.Foo = 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteWrongKind] The type alias 'Foo' imported with the prefix 'p' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: Foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@typeAlias::Foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: Foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@typeAlias::Foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_ifNullAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo ??= 0;
//  ^^^
// [diag.undefinedPrefixedNameWriteWrongKind] The function 'foo' imported with the prefix 'p' can't be assigned to.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: package:test/a.dart::@function::foo
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@function::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: package:test/a.dart::@function::foo
  readType: InvalidType
  writeElement: package:test/a.dart::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_increment() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.undefinedPrefixedNameWriteWrongKind] The function 'foo' imported with the prefix 'p' can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: package:test/a.dart::@function::foo
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@function::foo
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ++
  readElement: package:test/a.dart::@function::foo
  readType: InvalidType
  writeElement: package:test/a.dart::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }
}
