// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedPrefixedNameReadTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedPrefixedNameReadTest extends PubPackageResolutionTest {
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

  test_found_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo();
}
''');

    var node = result.findNode.singleImportPrefixedFunctionInvocation;
    assertResolvedNodeText(node, r'''
ImportPrefixedFunctionInvocation
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: package:test/a.dart::@function::foo
    invokeType: void Function()
    type: void
  staticType: void
V1: MethodInvocation
  target: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@function::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_found_invocation_functionTypeAlias() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef Foo = void Function();
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.Foo();
//  ^^^
// [diag.invocationOfNonFunction] 'Foo' isn't a function.
}
''');

    var node = result.findNode.singleImportPrefixedFunctionInvocation;
    assertResolvedNodeText(node, r'''
ImportPrefixedFunctionInvocation
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: Foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    candidates
      candidate: package:test/a.dart::@typeAlias::Foo
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: Foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_found_invocation_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
void Function() get foo => () {};
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo();
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: ImportPrefixedNameExpression
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    resolution: GetterInvocationResolution
      element: package:test/a.dart::@getter::foo
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
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@getter::foo
      staticType: void Function()
    element: package:test/a.dart::@getter::foo
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
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo;
}
''');

    var node = result.findNode.singleImportPrefixedNameExpression;
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: foo
  resolution: GetterInvocationResolution
    element: package:test/a.dart::@getter::foo
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@getter::foo
    staticType: int
  element: package:test/a.dart::@getter::foo
  staticType: int
''');
  }

  test_notFound_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

@p.unresolved
// ^^^^^^^^^^
// [diag.undefinedPrefixedNameReadNotFoundAnnotation] The name 'unresolved' isn't defined in the libraries imported with the prefix 'p'.
void f() {}
''');
  }

  test_notFound_annotation_syntheticName() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

@p.
void f() {}
// [diag.missingIdentifier][column 1][length 4] Expected an identifier.
''');
  }

  test_notFound_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.undefinedPrefixedNameReadNotFound] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_ifNullAssignment() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo ??= 0;
//  ^^^
// [diag.undefinedPrefixedNameReadNotFound] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
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
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_increment() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.undefinedPrefixedNameReadNotFound] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_invocation() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo();
//  ^^^
// [diag.undefinedPrefixedNameReadNotFound] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
}
''');

    var node = result.findNode.singleImportPrefixedFunctionInvocation;
    assertResolvedNodeText(node, r'''
ImportPrefixedFunctionInvocation
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
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

  test_notFound_invocation_syntheticName() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

var x = p.(0);
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  test_notFound_invocation_syntheticName_argumentsResolved() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

var x = p.(unresolved);
//        ^
// [diag.missingIdentifier] Expected an identifier.
//         ^^^^^^^^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'unresolved'.
''');
  }

  test_notFound_invocation_syntheticName_statement() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

void f() {
  p.();
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_notFound_propertyExtraction() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo;
//  ^^^
// [diag.undefinedPrefixedNameReadNotFound] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
}
''');

    var node = result.findNode.singleImportPrefixedNameExpression;
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_constant() async {
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

const x = p.foo;
//          ^^^
// [diag.undefinedPrefixedNameReadNotFoundConstant] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
''');
  }

  test_notFound_propertyExtraction_constant_receiver() async {
    // A receiver can also be a type.
    newFile('$testPackageLibPath/a.dart', '');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

const x = p.foo.bar;
//          ^^^
// [diag.undefinedPrefixedNameReadNotFound] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
''');
  }

  test_notFound_propertyExtraction_deferred() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' deferred as p;

void f() {
  p.foo;
//  ^^^
// [diag.undefinedPrefixedNameReadNotFound] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
}
''');

    var node = result.findNode.singleImportPrefixedNameExpression;
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_hidden() async {
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p hide foo;

void f() {
  p.foo;
//  ^^^
// [diag.undefinedPrefixedNameReadNotFound] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
}
''');

    var node = result.findNode.singleImportPrefixedNameExpression;
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_new() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
void f() {
  p.new;
//  ^^^
// [diag.undefinedPrefixedNameReadNotFound] The name 'new' isn't defined in the libraries imported with the prefix 'p'.
}
''');
  }

  test_notFound_propertyExtraction_privateOfOwnLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as p;

int _foo = 0;
//  ^^^^
// [diag.unusedElement] The declaration '_foo' isn't referenced.

void f() {
  p._foo;
//  ^^^^
// [diag.undefinedPrefixedNameReadNotFound] The name '_foo' isn't defined in the libraries imported with the prefix 'p'.
}
''');

    var node = result.findNode.singleImportPrefixedNameExpression;
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_syntheticName() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

var x = p.;
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  test_notFound_propertyExtraction_syntheticName_listLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

var x = p.[0];
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  test_notFound_propertyExtraction_syntheticName_setOrMapLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

var x = p.{};
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  test_notFound_propertyExtraction_syntheticName_stringLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

var x = p."s";
//        ^^^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  test_notFound_propertyExtraction_syntheticName_typedListLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

var x = p.<int>[];
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  test_notFound_typeInstantiation() async {
    newFile('$testPackageLibPath/a.dart', '');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo<int>;
//  ^^^
// [diag.undefinedPrefixedNameReadNotFound] The name 'foo' isn't defined in the libraries imported with the prefix 'p'.
}
''');

    var node = result.findNode.singleFunctionInstantiation;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ImportPrefixedNameExpression
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_private_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
int _foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p._foo += 1;
//  ^^^^
// [diag.undefinedPrefixedNameReadPrivate] The name '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
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
int _foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p._foo ??= 0;
//  ^^^^
// [diag.undefinedPrefixedNameReadPrivate] The name '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
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
    name: _foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
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
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
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
int _foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p._foo++;
//  ^^^^
// [diag.undefinedPrefixedNameReadPrivate] The name '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
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
  operand: PrefixedIdentifier
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
void _foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p._foo();
//  ^^^^
// [diag.undefinedPrefixedNameReadPrivate] The name '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleImportPrefixedFunctionInvocation;
    assertResolvedNodeText(node, r'''
ImportPrefixedFunctionInvocation
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: _foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
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
int _foo = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p._foo;
//  ^^^^
// [diag.undefinedPrefixedNameReadPrivate] The name '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleImportPrefixedNameExpression;
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class _Foo {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p._Foo;
//  ^^^^
// [diag.undefinedPrefixedNameReadPrivate] The name '_Foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleImportPrefixedNameExpression;
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: _Foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: _Foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
set _foo(int _) {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p._foo;
//  ^^^^
// [diag.undefinedPrefixedNameReadPrivate] The name '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleImportPrefixedNameExpression;
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo += 1;
//  ^^^
// [diag.undefinedPrefixedNameReadSetterOnly] There's a setter 'foo' in the libraries imported with the prefix 'p', but no getter.
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
      recoveryElement: package:test/a.dart::@setter::foo
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::foo
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
  readElement: package:test/a.dart::@setter::foo
  readType: InvalidType
  writeElement: package:test/a.dart::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_ifNullAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo ??= 0;
//  ^^^
// [diag.undefinedPrefixedNameReadSetterOnly] There's a setter 'foo' in the libraries imported with the prefix 'p', but no getter.
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
      recoveryElement: package:test/a.dart::@setter::foo
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::foo
      acceptedType: int
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/a.dart::@setter::foo::@formalParameter::_
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
    correspondingParameter: package:test/a.dart::@setter::foo::@formalParameter::_
    staticType: int
  readElement: package:test/a.dart::@setter::foo
  readType: InvalidType
  writeElement: package:test/a.dart::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_increment() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo++;
//  ^^^
// [diag.undefinedPrefixedNameReadSetterOnly] There's a setter 'foo' in the libraries imported with the prefix 'p', but no getter.
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
      recoveryElement: package:test/a.dart::@setter::foo
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::foo
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
  readElement: package:test/a.dart::@setter::foo
  readType: InvalidType
  writeElement: package:test/a.dart::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo();
//  ^^^
// [diag.undefinedPrefixedNameReadSetterOnly] There's a setter 'foo' in the libraries imported with the prefix 'p', but no getter.
}
''');

    var node = result.findNode.singleImportPrefixedFunctionInvocation;
    assertResolvedNodeText(node, r'''
ImportPrefixedFunctionInvocation
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
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
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.foo;
//  ^^^
// [diag.undefinedPrefixedNameReadSetterOnly] There's a setter 'foo' in the libraries imported with the prefix 'p', but no getter.
}
''');

    var node = result.findNode.singleImportPrefixedNameExpression;
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: package:test/a.dart::@setter::foo
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@setter::foo
    staticType: InvalidType
  element: package:test/a.dart::@setter::foo
  staticType: InvalidType
''');
  }
}
