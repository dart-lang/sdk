// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportPrefixedNameExpressionResolutionTest);
    defineReflectiveTests(ImportPrefixedNameBeforeConstructorTearoffsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ImportPrefixedNameBeforeConstructorTearoffsTest
    extends PubPackageResolutionTest
    with BeforeConstructorTearoffsMixin {
  test_functionInstantiation() async {
    newFile('$testPackageLibPath/a.dart', 'T id<T>(T value) => value;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
int Function(int) f() => p.id;
''');
    assertResolvedNodeText(
      result.findNode.implicitFunctionInstantiation('p.id'),
      r'''
ImplicitFunctionInstantiation
  operand: ImportPrefixedNameExpression
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: id
    resolution: ExecutableTearOffResolution
      element: package:test/a.dart::@function::id
      type: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: id
    element: package:test/a.dart::@function::id
    staticType: int Function(int)
    tearOffTypeArgumentTypes
      int
  element: package:test/a.dart::@function::id
  staticType: int Function(int)
''',
    );
  }
}

@reflectiveTest
class ImportPrefixedNameExpressionResolutionTest
    extends PubPackageResolutionTest {
  test_ambiguous() async {
    newFile('$testPackageLibPath/a.dart', 'const value = 1;');
    newFile('$testPackageLibPath/b.dart', 'const value = 2;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.value;
//  ^^^^^
// [diag.ambiguousImport] The name 'value' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');
    assertResolvedNodeText(
      result.findNode.importPrefixedNameExpression('p.value'),
      r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: value
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
      candidate: multiplyDefinedElement
        package:test/a.dart::@getter::value
        package:test/b.dart::@getter::value
    recovery: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: value
    element: multiplyDefinedElement
      package:test/a.dart::@getter::value
      package:test/b.dart::@getter::value
    staticType: InvalidType
  element: multiplyDefinedElement
    package:test/a.dart::@getter::value
    package:test/b.dart::@getter::value
  staticType: InvalidType
''',
    );
  }

  test_argument() async {
    newFile('$testPackageLibPath/a.dart', 'const value = 1;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void consume(int value) {}
void f() {
  consume(p.value);
}
''');
    assertResolvedNodeText(
      result.findNode.importPrefixedNameExpression('p.value'),
      r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: value
  resolution: GetterInvocationResolution
    element: package:test/a.dart::@getter::value
    invokeType: int Function()
    type: int
  correspondingParameter: <testLibrary>::@function::consume::@formalParameter::value
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: value
    element: package:test/a.dart::@getter::value
    staticType: int
  correspondingParameter: <testLibrary>::@function::consume::@formalParameter::value
  element: package:test/a.dart::@getter::value
  staticType: int
''',
    );
  }

  test_deferred_constant() async {
    newFile('$testPackageLibPath/a.dart', 'const value = 1;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as p;

const value = p.value;
//              ^^^^^
// [diag.constInitializedWithNonConstantValueFromDeferredLibrary] Constant values from a deferred library can't be used to initialize a 'const' variable.
''');
    assertResolvedNodeText(
      result.findNode.importPrefixedNameExpression('p.value'),
      r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: value
  resolution: GetterInvocationResolution
    element: package:test/a.dart::@getter::value
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: value
    element: package:test/a.dart::@getter::value
    staticType: int
  element: package:test/a.dart::@getter::value
  staticType: int
''',
    );
  }

  test_deferred_loadLibrary() async {
    newFile('$testPackageLibPath/a.dart', 'const value = 1;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as p;
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.

void f() {
  p.loadLibrary;
}
''');
    assertResolvedNodeText(
      result.findNode.importPrefixedNameExpression('p.loadLibrary'),
      r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: loadLibrary
  resolution: ExecutableTearOffResolution
    element: package:test/a.dart::@function::loadLibrary
    type: Future<dynamic> Function()
  staticType: Future<dynamic> Function()
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: loadLibrary
    element: package:test/a.dart::@function::loadLibrary
    staticType: Future<dynamic> Function()
  element: package:test/a.dart::@function::loadLibrary
  staticType: Future<dynamic> Function()
''',
    );
  }

  test_deferred_read() async {
    newFile('$testPackageLibPath/a.dart', 'const value = 1;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as p;

void f() {
  p.value;
}
''');
    assertResolvedNodeText(
      result.findNode.importPrefixedNameExpression('p.value'),
      r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: value
  resolution: GetterInvocationResolution
    element: package:test/a.dart::@getter::value
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: value
    element: package:test/a.dart::@getter::value
    staticType: int
  element: package:test/a.dart::@getter::value
  staticType: int
''',
    );
  }

  test_functionInstantiation() async {
    newFile('$testPackageLibPath/a.dart', 'T id<T>(T value) => value;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
int Function(int) f() => p.id;
''');
    assertResolvedNodeText(
      result.findNode.implicitFunctionInstantiation('p.id'),
      r'''
ImplicitFunctionInstantiation
  operand: ImportPrefixedNameExpression
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: id
    resolution: ExecutableTearOffResolution
      element: package:test/a.dart::@function::id
      type: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
V1: FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: id
      element: package:test/a.dart::@function::id
      staticType: T Function<T>(T)
    element: package:test/a.dart::@function::id
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''',
    );
  }

  test_functionInstantiation_explicit() async {
    newFile('$testPackageLibPath/a.dart', 'T id<T>(T value) => value;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.id<int>;
}
''');
    assertResolvedNodeText(result.findNode.functionReference('p.id'), r'''
FunctionReference
  function2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: id
      element: package:test/a.dart::@function::id
      staticType: T Function<T>(T)
    element: package:test/a.dart::@function::id
    staticType: T Function<T>(T)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_missing() async {
    newFile('$testPackageLibPath/a.dart', 'const value = 1;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.missing;
//  ^^^^^^^
// [diag.undefinedPrefixedName] The name 'missing' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');
    assertResolvedNodeText(
      result.findNode.importPrefixedNameExpression('p.missing'),
      r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: p
    period: .
    element: <testLibraryFragment>::@prefix::p
  name: missing
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: missing
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''',
    );
  }

  test_nullAware() async {
    newFile('$testPackageLibPath/a.dart', 'const value = 1;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;

void f() {
  p?.value;
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
    assertResolvedNodeText(result.findNode.propertyAccess('p?.value'), r'''
PropertyAccess
  target2: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
    staticType: InvalidType
  operator: ?.
  propertyName: SimpleIdentifier
    token: value
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_receiver() async {
    newFile('$testPackageLibPath/a.dart', 'const value = 1;');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  (p.value).isEven;
}
''');
    assertResolvedNodeText(
      result.findNode.receiverPropertyExtraction('isEven'),
      r'''
ReceiverPropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: ImportPrefixedNameExpression
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
      name: value
      resolution: GetterInvocationResolution
        element: package:test/a.dart::@getter::value
        invokeType: int Function()
        type: int
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: .
  name: isEven
  resolution: GetterInvocationResolution
    element: dart:core::@class::int::@getter::isEven
    invokeType: bool Function()
    type: bool
  staticType: bool
V1: PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: value
        element: package:test/a.dart::@getter::value
        staticType: int
      element: package:test/a.dart::@getter::value
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: .
  propertyName: SimpleIdentifier
    token: isEven
    element: dart:core::@class::int::@getter::isEven
    staticType: bool
  staticType: bool
''',
    );
  }

  test_topLevelFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

void f() {
  prefix.foo;
}
''');

    var node = result.findNode.importPrefixedNameExpression('prefix.');
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: prefix
    period: .
    element: <testLibraryFragment>::@prefix::prefix
  name: foo
  resolution: ExecutableTearOffResolution
    element: package:test/a.dart::@function::foo
    type: void Function()
  staticType: void Function()
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    element: <testLibraryFragment>::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@function::foo
    staticType: void Function()
  element: package:test/a.dart::@function::foo
  staticType: void Function()
''');
  }

  test_topLevelGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');

    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

void f() {
  prefix.foo;
}
''');

    var node = result.findNode.importPrefixedNameExpression('prefix.');
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: prefix
    period: .
    element: <testLibraryFragment>::@prefix::prefix
  name: foo
  resolution: GetterInvocationResolution
    element: package:test/a.dart::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    element: <testLibraryFragment>::@prefix::prefix
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

  test_topLevelSetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');

    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

void f() {
  prefix.foo;
//       ^^^
// [diag.undefinedPrefixedName] The name 'foo' is being referenced through the prefix 'prefix', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.importPrefixedNameExpression('prefix.foo;');
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: prefix
    period: .
    element: <testLibraryFragment>::@prefix::prefix
  name: foo
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
      candidate: package:test/a.dart::@setter::foo
    recovery: ExecutableTearOffResolution
      element: package:test/a.dart::@setter::foo
      type: void Function(int)
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    element: <testLibraryFragment>::@prefix::prefix
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

  test_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
final foo = 0;
''');

    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

void f() {
  prefix.foo;
}
''');

    var node = result.findNode.importPrefixedNameExpression('prefix.');
    assertResolvedNodeText(node, r'''
ImportPrefixedNameExpression
  importPrefix: ImportPrefixReference
    name: prefix
    period: .
    element: <testLibraryFragment>::@prefix::prefix
  name: foo
  resolution: GetterInvocationResolution
    element: package:test/a.dart::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    element: <testLibraryFragment>::@prefix::prefix
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

  test_typeLiteral() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
void f() {
  p.C;
}
''');
    assertResolvedNodeText(result.findNode.typeLiteral('p.C'), r'''
TypeLiteral
  type: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: C
    element: package:test/a.dart::@class::C
    type: C
  staticType: Type
''');
  }
}
