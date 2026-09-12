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
  test_compound_topLevelGetter_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('p.foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: SetterInvocationResolution
      element: package:test/c.dart::@setter::foo
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: package:test/c.dart::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_compound_topLevelGetter_ambiguous_missingSetter() async {
    // TODO(scheglov): Report the missing setter instead of an undefined prefixed name.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('p.foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_compound_topLevelGetterFunction_ambiguous_missingSetter() async {
    // TODO(scheglov): Report the missing setter instead of an undefined prefixed name.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo() => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
// [diag.ambiguousImport] The name 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('p.foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@function::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@function::foo
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@function::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@function::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_compound_topLevelGetterSetter_ambiguous_differentLibraries() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;
import 'd.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.compoundAssignment('p.foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/c.dart::@setter::foo
        package:test/d.dart::@setter::foo
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/c.dart::@setter::foo
    package:test/d.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_compound_topLevelGetterSetter_ambiguous_mixedReadKinds() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo() => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;
import 'd.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.ambiguousImport] The name 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.compoundAssignment('p.foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@function::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/c.dart::@setter::foo
        package:test/d.dart::@setter::foo
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@function::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/c.dart::@setter::foo
    package:test/d.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_compound_topLevelGetterSetter_ambiguous_sameLibraries() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(int value) {}
''');
    newFile('$testPackageLibPath/b.dart', '''
int get foo => 1;
set foo(int value) {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart' as p;
import 'a.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('p.foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@getter::foo
        package:test/a.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@setter::foo
        package:test/a.dart::@setter::foo
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
  readElement: multiplyDefinedElement
    package:test/b.dart::@getter::foo
    package:test/a.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/b.dart::@setter::foo
    package:test/a.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_compound_topLevelGetterSetter_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(num value) {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.foo += 1;
}
''');

    var node = result.findNode.compoundAssignment('p.foo += 1');
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
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::foo
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
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_topLevelSetter_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/b.dart' and 'package:test/c.dart'.
}
''');

    var node = result.findNode.compoundAssignment('p.foo += 1');
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
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@setter::foo
        package:test/c.dart::@setter::foo
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
  writeElement: multiplyDefinedElement
    package:test/b.dart::@setter::foo
    package:test/c.dart::@setter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_topLevelSetter_ambiguous_missingGetter() async {
    // TODO(scheglov): Report the missing getter instead of an undefined prefixed name.
    newFile('$testPackageLibPath/a.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/b.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('p.foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@setter::foo
        package:test/b.dart::@setter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@setter::foo
        package:test/b.dart::@setter::foo
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@setter::foo
    package:test/b.dart::@setter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/a.dart::@setter::foo
    package:test/b.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_compound_topLevelVariable_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int foo = 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo = 0;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('p.foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@setter::foo
        package:test/b.dart::@setter::foo
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/a.dart::@setter::foo
    package:test/b.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_direct_topLevelGetter_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.
import 'b.dart' as p;
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'b.dart'.
import 'c.dart' as p;

void f() {
  p.foo = 0;
}
''');

    var node = result.findNode.directAssignment('p.foo = 0');
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
      element: package:test/c.dart::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/c.dart::@setter::foo::@formalParameter::value
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
    correspondingParameter: package:test/c.dart::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/c.dart::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_direct_topLevelGetter_ambiguous_missingSetter() async {
    // TODO(scheglov): Report the missing setter instead of an undefined prefixed name.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.directAssignment('p.foo = 0');
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

  test_direct_topLevelGetterSetter_ambiguous_differentLibraries() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;
import 'd.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.directAssignment('p.foo = 0');
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
        package:test/c.dart::@setter::foo
        package:test/d.dart::@setter::foo
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
    package:test/c.dart::@setter::foo
    package:test/d.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_direct_topLevelGetterSetter_ambiguous_sameLibraries() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(int value) {}
''');
    newFile('$testPackageLibPath/b.dart', '''
int get foo => 1;
set foo(int value) {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart' as p;
import 'a.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.directAssignment('p.foo = 0');
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
        package:test/b.dart::@setter::foo
        package:test/a.dart::@setter::foo
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
    package:test/b.dart::@setter::foo
    package:test/a.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_direct_topLevelSetter_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/b.dart' and 'package:test/c.dart'.
}
''');

    var node = result.findNode.directAssignment('p.foo = 0');
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
        package:test/b.dart::@setter::foo
        package:test/c.dart::@setter::foo
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
    package:test/b.dart::@setter::foo
    package:test/c.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_direct_topLevelSetter_contextType() async {
    newFile('$testPackageLibPath/a.dart', 'set foo(List<int> value) {}');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.foo = [];
}
''');

    var node = result.findNode.directAssignment('p.foo = []');
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
      acceptedType: List<int>
  operator: =
  value: ListLiteral
    leftBracket: [
    rightBracket: ]
    correspondingParameter: package:test/a.dart::@setter::foo::@formalParameter::value
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
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: ListLiteral
    leftBracket: [
    rightBracket: ]
    correspondingParameter: package:test/a.dart::@setter::foo::@formalParameter::value
    staticType: List<int>
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@setter::foo
  writeType: List<int>
  element: <null>
  staticType: List<int>
''');
  }

  test_direct_topLevelVariable_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int foo = 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo = 0;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.foo = 0;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.directAssignment('p.foo = 0');
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
        package:test/a.dart::@setter::foo
        package:test/b.dart::@setter::foo
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
    package:test/a.dart::@setter::foo
    package:test/b.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_direct_topLevelVariable_deferred() async {
    newFile('$testPackageLibPath/a.dart', 'int foo = 0;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as p;
void f() {
  p.foo = 1;
}
''');

    var node = result.findNode.directAssignment('p.foo = 1');
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
    literal: 1
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
    literal: 1
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

  test_direct_topLevelVariable_final() async {
    // TODO(scheglov): Report assignment to final instead of an undefined prefixed name.
    newFile('$testPackageLibPath/a.dart', 'final foo = 0;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.foo = 1;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.directAssignment('p.foo = 1');
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
      token: foo
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
  writeElement: package:test/a.dart::@getter::foo
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
  p.foo = 1;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.directAssignment('p.foo = 1');
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
      token: foo
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

  test_ifNull_topLevelGetter_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;

void f() {
  p.foo ??= 1;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.ifNullAssignment('p.foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: SetterInvocationResolution
      element: package:test/c.dart::@setter::foo
      acceptedType: int
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/c.dart::@setter::foo::@formalParameter::value
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
    literal: 1
    correspondingParameter: package:test/c.dart::@setter::foo::@formalParameter::value
    staticType: int
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: package:test/c.dart::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_ifNull_topLevelGetter_ambiguous_missingSetter() async {
    // TODO(scheglov): Report the missing setter instead of an undefined prefixed name.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.foo ??= 1;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.ifNullAssignment('p.foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
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
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_ifNull_topLevelGetter_missingSetter() async {
    // TODO(scheglov): Report the missing setter instead of an undefined prefixed name.
    newFile('$testPackageLibPath/a.dart', 'int? get foo => null;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.foo ??= 1;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.ifNullAssignment('p.foo ??= 1');
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
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      recoveryElement: package:test/a.dart::@getter::foo
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
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: package:test/a.dart::@getter::foo
  readType: int?
  writeElement: package:test/a.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_ifNull_topLevelGetterSetter_ambiguous_differentLibraries() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;
import 'd.dart' as p;

void f() {
  p.foo ??= 1;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.ifNullAssignment('p.foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/c.dart::@setter::foo
        package:test/d.dart::@setter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
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
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/c.dart::@setter::foo
    package:test/d.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_ifNull_topLevelGetterSetter_ambiguous_sameLibraries() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(int value) {}
''');
    newFile('$testPackageLibPath/b.dart', '''
int get foo => 1;
set foo(int value) {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart' as p;
import 'a.dart' as p;

void f() {
  p.foo ??= 1;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.ifNullAssignment('p.foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@getter::foo
        package:test/a.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@setter::foo
        package:test/a.dart::@setter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
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
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: multiplyDefinedElement
    package:test/b.dart::@getter::foo
    package:test/a.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/b.dart::@setter::foo
    package:test/a.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_ifNull_topLevelGetterSetter_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', '''
int? get foo => null;
set foo(num? value) {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.foo ??= 1;
}
''');

    var node = result.findNode.ifNullAssignment('p.foo ??= 1');
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
      invokeType: int? Function()
      type: int?
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::foo
      acceptedType: num?
  operator: ??=
  value: IntegerLiteral
    literal: 1
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
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@setter::foo::@formalParameter::value
    staticType: int
  readElement: package:test/a.dart::@getter::foo
  readType: int?
  writeElement: package:test/a.dart::@setter::foo
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_ifNull_topLevelSetter_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int? get foo => null;');
    newFile('$testPackageLibPath/b.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;

void f() {
  p.foo ??= 1;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/b.dart' and 'package:test/c.dart'.
}
''');

    var node = result.findNode.ifNullAssignment('p.foo ??= 1');
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
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@setter::foo
        package:test/c.dart::@setter::foo
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
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: package:test/a.dart::@getter::foo
  readType: int?
  writeElement: multiplyDefinedElement
    package:test/b.dart::@setter::foo
    package:test/c.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_ifNull_topLevelSetter_missingGetter() async {
    // TODO(scheglov): Report the missing getter instead of an undefined prefixed name.
    newFile('$testPackageLibPath/a.dart', 'set foo(int value) {}');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.foo ??= 1;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.ifNullAssignment('p.foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: package:test/a.dart::@setter::foo
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::foo
      acceptedType: int
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@setter::foo::@formalParameter::value
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
    literal: 1
    correspondingParameter: package:test/a.dart::@setter::foo::@formalParameter::value
    staticType: int
  readElement: package:test/a.dart::@setter::foo
  readType: InvalidType
  writeElement: package:test/a.dart::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_postfixDecrement_topLevelGetterSetter_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(num value) {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.foo--;
}
''');

    var node = result.findNode.incrementOrDecrement('p.foo--');
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
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::foo
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
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: --
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@setter::foo
  writeType: num
  element: dart:core::@class::num::@method::-
  staticType: int
''');
  }

  test_postfixIncrement_topLevelGetter_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('p.foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: SetterInvocationResolution
      element: package:test/c.dart::@setter::foo
      acceptedType: int
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: package:test/c.dart::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_postfixIncrement_topLevelGetter_ambiguous_missingSetter() async {
    // TODO(scheglov): Report the missing setter instead of an undefined prefixed name.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('p.foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_postfixIncrement_topLevelGetterSetter_ambiguous_differentLibraries() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;
import 'd.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('p.foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/c.dart::@setter::foo
        package:test/d.dart::@setter::foo
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/c.dart::@setter::foo
    package:test/d.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_postfixIncrement_topLevelGetterSetter_ambiguous_sameLibraries() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(int value) {}
''');
    newFile('$testPackageLibPath/b.dart', '''
int get foo => 1;
set foo(int value) {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart' as p;
import 'a.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('p.foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@getter::foo
        package:test/a.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@setter::foo
        package:test/a.dart::@setter::foo
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
  readElement: multiplyDefinedElement
    package:test/b.dart::@getter::foo
    package:test/a.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/b.dart::@setter::foo
    package:test/a.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_postfixIncrement_topLevelSetter_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/b.dart' and 'package:test/c.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('p.foo++');
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
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@setter::foo
        package:test/c.dart::@setter::foo
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
  writeElement: multiplyDefinedElement
    package:test/b.dart::@setter::foo
    package:test/c.dart::@setter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_postfixIncrement_topLevelVariable_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int foo = 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo = 0;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('p.foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@setter::foo
        package:test/b.dart::@setter::foo
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/a.dart::@setter::foo
    package:test/b.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_prefixIncrement_topLevelGetter_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;

void f() {
  ++p.foo;
//    ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++p.foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: SetterInvocationResolution
      element: package:test/c.dart::@setter::foo
      acceptedType: int
  operation: increment
  position: prefix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: package:test/c.dart::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_prefixIncrement_topLevelGetter_ambiguous_missingSetter() async {
    // TODO(scheglov): Report the missing setter instead of an undefined prefixed name.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  ++p.foo;
//    ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++p.foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
  operation: increment
  position: prefix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_prefixIncrement_topLevelGetterSetter_ambiguous_differentLibraries() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;
import 'd.dart' as p;

void f() {
  ++p.foo;
//    ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++p.foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/c.dart::@setter::foo
        package:test/d.dart::@setter::foo
  operation: increment
  position: prefix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/c.dart::@setter::foo
    package:test/d.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_prefixIncrement_topLevelGetterSetter_ambiguous_sameLibraries() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(int value) {}
''');
    newFile('$testPackageLibPath/b.dart', '''
int get foo => 1;
set foo(int value) {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart' as p;
import 'a.dart' as p;

void f() {
  ++p.foo;
//    ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++p.foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@getter::foo
        package:test/a.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@setter::foo
        package:test/a.dart::@setter::foo
  operation: increment
  position: prefix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
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
  readElement: multiplyDefinedElement
    package:test/b.dart::@getter::foo
    package:test/a.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/b.dart::@setter::foo
    package:test/a.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_prefixIncrement_topLevelGetterSetter_differentTypes() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(num value) {}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  ++p.foo;
}
''');

    var node = result.findNode.incrementOrDecrement('++p.foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::foo
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
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: package:test/a.dart::@setter::foo
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixIncrement_topLevelSetter_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;
import 'c.dart' as p;

void f() {
  ++p.foo;
//    ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/b.dart' and 'package:test/c.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++p.foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/b.dart::@setter::foo
        package:test/c.dart::@setter::foo
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
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  readElement: package:test/a.dart::@getter::foo
  readType: int
  writeElement: multiplyDefinedElement
    package:test/b.dart::@setter::foo
    package:test/c.dart::@setter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixIncrement_topLevelVariable_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'int foo = 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo = 0;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  ++p.foo;
//    ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++p.foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: ImportPrefixedAssignmentTarget
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@getter::foo
        package:test/b.dart::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: multiplyDefinedElement
        package:test/a.dart::@setter::foo
        package:test/b.dart::@setter::foo
  operation: increment
  position: prefix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
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
  readElement: multiplyDefinedElement
    package:test/a.dart::@getter::foo
    package:test/b.dart::@getter::foo
  readType: InvalidType
  writeElement: multiplyDefinedElement
    package:test/a.dart::@setter::foo
    package:test/b.dart::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }
}
