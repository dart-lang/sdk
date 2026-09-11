// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnqualifiedNameAssignmentTargetResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnqualifiedNameAssignmentTargetResolutionTest
    extends PubPackageResolutionTest {
  test_compound_topLevelGetter_ambiguous() async {
    // TODO(scheglov): Report the ambiguous getter instead of unused imports.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.
import 'b.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'b.dart'.
import 'c.dart';

void f() {
  foo += 1;
}
''');

    var node = result.findNode.compoundAssignment('foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Also report the missing setter.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  foo += 1;
//^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Also report the missing setter.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo() => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  foo += 1;
//^^^
// [diag.ambiguousImport] The name 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@function::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@function::foo
      recovery: <null>
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';
import 'c.dart';
import 'd.dart';

void f() {
  foo += 1;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.compoundAssignment('foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/c.dart::@setter::foo
          package:test/d.dart::@setter::foo
      recovery: <null>
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous read as well as the setter.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo() => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';
import 'c.dart';
import 'd.dart';

void f() {
  foo += 1;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.compoundAssignment('foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@function::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/c.dart::@setter::foo
          package:test/d.dart::@setter::foo
      recovery: <null>
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(int value) {}
''');
    newFile('$testPackageLibPath/b.dart', '''
int get foo => 1;
set foo(int value) {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';
import 'a.dart';

void f() {
  foo += 1;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@getter::foo
          package:test/a.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@setter::foo
          package:test/a.dart::@setter::foo
      recovery: <null>
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  foo += 1;
}
''');

    var node = result.findNode.compoundAssignment('foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
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
  leftHandSide: SimpleIdentifier
    token: foo
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
import 'a.dart';
import 'b.dart';
import 'c.dart';

void f() {
  foo += 1;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/b.dart' and 'package:test/c.dart'.
}
''');

    var node = result.findNode.compoundAssignment('foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@setter::foo
          package:test/c.dart::@setter::foo
      recovery: <null>
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report a missing getter instead of an undefined name.
    newFile('$testPackageLibPath/a.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/b.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  foo += 1;
//^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@setter::foo
          package:test/b.dart::@setter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@setter::foo
          package:test/b.dart::@setter::foo
      recovery: <null>
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', 'int foo = 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo = 0;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  foo += 1;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.compoundAssignment('foo += 1');
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@setter::foo
          package:test/b.dart::@setter::foo
      recovery: <null>
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
  leftHandSide: SimpleIdentifier
    token: foo
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
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.
import 'b.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'b.dart'.
import 'c.dart';

void f() {
  foo = 0;
}
''');

    var node = result.findNode.directAssignment('foo = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the missing setter instead of getter ambiguity.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  foo = 0;
//^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.directAssignment('foo = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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
import 'a.dart';
import 'b.dart';
import 'c.dart';
import 'd.dart';

void f() {
  foo = 0;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.directAssignment('foo = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/c.dart::@setter::foo
          package:test/d.dart::@setter::foo
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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
import 'b.dart';
import 'a.dart';

void f() {
  foo = 0;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.directAssignment('foo = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@setter::foo
          package:test/a.dart::@setter::foo
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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
import 'a.dart';
import 'b.dart';
import 'c.dart';

void f() {
  foo = 0;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/b.dart' and 'package:test/c.dart'.
}
''');

    var node = result.findNode.directAssignment('foo = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@setter::foo
          package:test/c.dart::@setter::foo
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  foo = [];
}
''');

    var node = result.findNode.directAssignment('foo = []');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
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
  leftHandSide: SimpleIdentifier
    token: foo
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
import 'a.dart';
import 'b.dart';

void f() {
  foo = 0;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.directAssignment('foo = 0');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@setter::foo
          package:test/b.dart::@setter::foo
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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

  test_direct_topLevelVariable_final() async {
    newFile('$testPackageLibPath/a.dart', 'final foo = 0;');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  foo = 1;
//^^^
// [diag.assignmentToFinal] 'foo' can't be used as a setter because it's final.
}
''');

    var node = result.findNode.directAssignment('foo = 1');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: package:test/a.dart::@getter::foo
      recovery: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  foo = 1;
//^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
}
''');

    var node = result.findNode.directAssignment('foo = 1');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter instead of unused imports.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.
import 'b.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'b.dart'.
import 'c.dart';

void f() {
  foo ??= 1;
}
''');

    var node = result.findNode.ifNullAssignment('foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Also report the missing setter.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  foo ??= 1;
//^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.ifNullAssignment('foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report a missing setter instead of a final variable.
    newFile('$testPackageLibPath/a.dart', 'int? get foo => null;');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  foo ??= 1;
//^^^
// [diag.assignmentToFinal] 'foo' can't be used as a setter because it's final.
}
''');

    var node = result.findNode.ifNullAssignment('foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: package:test/a.dart::@getter::foo
      recovery: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';
import 'c.dart';
import 'd.dart';

void f() {
  foo ??= 1;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.ifNullAssignment('foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/c.dart::@setter::foo
          package:test/d.dart::@setter::foo
      recovery: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(int value) {}
''');
    newFile('$testPackageLibPath/b.dart', '''
int get foo => 1;
set foo(int value) {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';
import 'a.dart';

void f() {
  foo ??= 1;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.ifNullAssignment('foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@getter::foo
          package:test/a.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@setter::foo
          package:test/a.dart::@setter::foo
      recovery: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  foo ??= 1;
}
''');

    var node = result.findNode.ifNullAssignment('foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
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
  leftHandSide: SimpleIdentifier
    token: foo
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
import 'a.dart';
import 'b.dart';
import 'c.dart';

void f() {
  foo ??= 1;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/b.dart' and 'package:test/c.dart'.
}
''');

    var node = result.findNode.ifNullAssignment('foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@setter::foo
          package:test/c.dart::@setter::foo
      recovery: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report a missing getter instead of an undefined name.
    newFile('$testPackageLibPath/a.dart', 'set foo(int value) {}');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  foo ??= 1;
//^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
}
''');

    var node = result.findNode.ifNullAssignment('foo ??= 1');
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: package:test/a.dart::@setter::foo
      recovery: ExecutableTearOffResolution
        element: package:test/a.dart::@setter::foo
        type: void Function(int)
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
  leftHandSide: SimpleIdentifier
    token: foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  foo--;
}
''');

    var node = result.findNode.incrementOrDecrement('foo--');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
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
  operand: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter instead of unused imports.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.
import 'b.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'b.dart'.
import 'c.dart';

void f() {
  foo++;
}
''');

    var node = result.findNode.incrementOrDecrement('foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
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
  operand: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Also report the missing setter.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  foo++;
//^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';
import 'c.dart';
import 'd.dart';

void f() {
  foo++;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/c.dart::@setter::foo
          package:test/d.dart::@setter::foo
      recovery: <null>
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(int value) {}
''');
    newFile('$testPackageLibPath/b.dart', '''
int get foo => 1;
set foo(int value) {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';
import 'a.dart';

void f() {
  foo++;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@getter::foo
          package:test/a.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@setter::foo
          package:test/a.dart::@setter::foo
      recovery: <null>
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
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
import 'a.dart';
import 'b.dart';
import 'c.dart';

void f() {
  foo++;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/b.dart' and 'package:test/c.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@setter::foo
          package:test/c.dart::@setter::foo
      recovery: <null>
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', 'int foo = 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo = 0;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  foo++;
//^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('foo++');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@setter::foo
          package:test/b.dart::@setter::foo
      recovery: <null>
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter instead of unused imports.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.
import 'b.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'b.dart'.
import 'c.dart';

void f() {
  ++foo;
}
''');

    var node = result.findNode.incrementOrDecrement('++foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
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
  operand: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Also report the missing setter.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  ++foo;
//  ^^^
// [diag.ambiguousImport] The getter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
  operation: increment
  position: prefix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', 'int get foo => 0;');
    newFile('$testPackageLibPath/b.dart', 'int get foo => 1;');
    newFile('$testPackageLibPath/c.dart', 'set foo(int value) {}');
    newFile('$testPackageLibPath/d.dart', 'set foo(int value) {}');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';
import 'c.dart';
import 'd.dart';

void f() {
  ++foo;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/c.dart' and 'package:test/d.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/c.dart::@setter::foo
          package:test/d.dart::@setter::foo
      recovery: <null>
  operation: increment
  position: prefix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
set foo(int value) {}
''');
    newFile('$testPackageLibPath/b.dart', '''
int get foo => 1;
set foo(int value) {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';
import 'a.dart';

void f() {
  ++foo;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@getter::foo
          package:test/a.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@setter::foo
          package:test/a.dart::@setter::foo
      recovery: <null>
  operation: increment
  position: prefix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
void f() {
  ++foo;
}
''');

    var node = result.findNode.incrementOrDecrement('++foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: UnqualifiedNameAssignmentTarget
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
  operand: SimpleIdentifier
    token: foo
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
import 'a.dart';
import 'b.dart';
import 'c.dart';

void f() {
  ++foo;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/b.dart' and 'package:test/c.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/b.dart::@setter::foo
          package:test/c.dart::@setter::foo
      recovery: <null>
  operation: increment
  position: prefix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: foo
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
    // TODO(scheglov): Report the ambiguous getter as well as the setter.
    newFile('$testPackageLibPath/a.dart', 'int foo = 0;');
    newFile('$testPackageLibPath/b.dart', 'int foo = 0;');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  ++foo;
//  ^^^
// [diag.ambiguousImport] The setter 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.incrementOrDecrement('++foo');
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@getter::foo
          package:test/b.dart::@getter::foo
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: multiplyDefinedElement
          package:test/a.dart::@setter::foo
          package:test/b.dart::@setter::foo
      recovery: <null>
  operation: increment
  position: prefix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: foo
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
