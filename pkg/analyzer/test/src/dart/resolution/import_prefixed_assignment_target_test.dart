// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportPrefixedAssignmentTargetResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ImportPrefixedAssignmentTargetResolutionTest
    extends PubPackageResolutionTest {
  test_compound_differentGetterSetterTypes() async {
    newFile('$testPackageLibPath/a.dart', '''
int get x => 0;
set x(num value) {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.x += 1;
}
''');
    assertResolvedNodeText(result.findNode.compoundAssignment('p.x += 1'), r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: x
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::x
      acceptedType: num
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
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_direct_contextType() async {
    newFile('$testPackageLibPath/a.dart', 'set x(List<int> value) {}');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.x = [];
}
''');
    assertResolvedNodeText(result.findNode.directAssignment('p.x = []'), r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: x
    read: <null>
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::x
      acceptedType: List<int>
  operator: =
  value: ListLiteral
    leftBracket: [
    rightBracket: ]
    correspondingParameter: package:test/a.dart::@setter::x::@formalParameter::value
    staticType: List<int>
  staticType: List<int>
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: ListLiteral
    leftBracket: [
    rightBracket: ]
    correspondingParameter: package:test/a.dart::@setter::x::@formalParameter::value
    staticType: List<int>
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@setter::x
  writeType: List<int>
  element: <null>
  staticType: List<int>
''');
  }

  test_direct_deferred() async {
    newFile('$testPackageLibPath/a.dart', 'int x = 0;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as p;
void f() {
  p.x = 1;
}
''');
    assertResolvedNodeText(result.findNode.directAssignment('p.x = 1'), r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: x
    read: <null>
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::x
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@setter::x::@formalParameter::value
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
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@setter::x
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_direct_final() async {
    newFile('$testPackageLibPath/a.dart', 'final x = 0;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.x = 1;
//  ^
// [diag.undefinedPrefixedName] The name 'x' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');
    assertResolvedNodeText(result.findNode.directAssignment('p.x = 1'), r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: package:test/a.dart::@getter::x
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
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
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_direct_unresolved() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.x = 1;
//  ^
// [diag.undefinedPrefixedName] The name 'x' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');
    assertResolvedNodeText(result.findNode.directAssignment('p.x = 1'), r'''
DirectAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: x
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
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
      token: x
      element: <null>
      staticType: null
    element: <null>
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

  test_ifNull_differentGetterSetterTypes() async {
    newFile('$testPackageLibPath/a.dart', '''
int? get x => null;
set x(num? value) {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.x ??= 1;
}
''');
    assertResolvedNodeText(result.findNode.ifNullAssignment('p.x ??= 1'), r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: x
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::x
      invokeType: int? Function()
      type: int?
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::x
      acceptedType: num?
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@setter::x::@formalParameter::value
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
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@setter::x::@formalParameter::value
    staticType: int
  readElement: package:test/a.dart::@getter::x
  readType: int?
  writeElement: package:test/a.dart::@setter::x
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_ifNull_missingGetter() async {
    newFile('$testPackageLibPath/a.dart', 'set x(int value) {}');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.x ??= 1;
//  ^
// [diag.undefinedPrefixedName] The name 'x' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');
    assertResolvedNodeText(result.findNode.ifNullAssignment('p.x ??= 1'), r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: x
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: package:test/a.dart::@setter::x
      recovery: <null>
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::x
      acceptedType: int
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@setter::x::@formalParameter::value
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
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@setter::x::@formalParameter::value
    staticType: int
  readElement: package:test/a.dart::@setter::x
  readType: InvalidType
  writeElement: package:test/a.dart::@setter::x
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_ifNull_missingSetter() async {
    newFile('$testPackageLibPath/a.dart', 'int? get x => null;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.x ??= 1;
//  ^
// [diag.undefinedPrefixedName] The name 'x' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');
    assertResolvedNodeText(result.findNode.ifNullAssignment('p.x ??= 1'), r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: x
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::x
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: package:test/a.dart::@getter::x
      recovery: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 1
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
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: package:test/a.dart::@getter::x
  readType: int?
  writeElement: package:test/a.dart::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_postfix_differentGetterSetterTypes() async {
    newFile('$testPackageLibPath/a.dart', '''
int get x => 0;
set x(num value) {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.x--;
}
''');
    assertResolvedNodeText(result.findNode.incrementOrDecrement('p.x--'), r'''
IncrementOrDecrementExpression
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: x
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::x
      acceptedType: num
  operator: --
  operation: decrement
  position: postfix
  element: dart:core::@class::num::@method::-
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
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: --
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::-
  staticType: int
''');
  }

  test_prefix_differentGetterSetterTypes() async {
    newFile('$testPackageLibPath/a.dart', '''
int get x => 0;
set x(num value) {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  ++p.x;
}
''');
    assertResolvedNodeText(result.findNode.incrementOrDecrement('++p.x'), r'''
IncrementOrDecrementExpression
  operator: ++
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: x
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::x
      acceptedType: num
  operation: increment
  position: prefix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }
}
