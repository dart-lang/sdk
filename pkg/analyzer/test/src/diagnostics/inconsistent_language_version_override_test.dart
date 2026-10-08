// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentLanguageVersionOverrideTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InconsistentLanguageVersionOverrideTest extends PubPackageResolutionTest {
  test_0_00_000_AAA() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.10
part 'b.dart';
''',
      b: r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
// @dart = 3.10
part of 'b.dart';
''',
    });
  }

  test_0_00_000_AAB() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.10
part 'b.dart';
''',
      b: r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      c: r'''
// @dart = 3.11
part of 'b.dart';
''',
    });
  }

  test_0_00_000_AAN() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.10
part 'b.dart';
''',
      b: r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      c: r'''
part of 'b.dart';
''',
    });
  }

  test_0_00_000_ABB() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.10
part 'b.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      b: r'''
// @dart = 3.11
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
// @dart = 3.11
part of 'b.dart';
''',
    });
  }

  test_0_00_000_NAA() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      b: r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
// @dart = 3.10
part of 'b.dart';
''',
    });
  }

  test_0_00_AA() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.2
part 'b.dart';
''',
      b: r'''
// @dart = 3.2
part of 'a.dart';
''',
    });
  }

  test_0_00_AB() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.1
part 'b.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      b: r'''
// @dart = 3.2
part of 'a.dart';
''',
    });
  }

  test_0_00_NA() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      b: r'''
// @dart = 3.1
part of 'a.dart';
''',
    });
  }

  test_0_00_NN() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
''',
    });
  }

  test_partUsesLibraryLanguageVersion_partNewer() async {
    var part = getFile('$testPackageLibPath/part.dart');
    var results = await resolveFilesWithDiagnostics({
      testFile: r'''
// %before-language-feature: inference-update-2
part 'part.dart';
//   ^^^^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      part: r'''
part of 'test.dart';

class C {
  final int? _foo;
  C(this._foo);
}

void f(C c) {
  if (c._foo != null) {
    c._foo;
  }
}
''',
    });
    var result = results[part]!;

    var node = result.findNode.receiverPropertyExtraction('c._foo;');
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: _foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::_foo
    invokeType: int? Function()
    type: int?
  staticType: int?
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <testLibrary>::@class::C::@getter::_foo
    staticType: int?
  element: <testLibrary>::@class::C::@getter::_foo
  staticType: int?
''');
  }

  test_partUsesLibraryLanguageVersion_partOlder() async {
    var part = getFile('$testPackageLibPath/part.dart');
    var results = await resolveFilesWithDiagnostics({
      testFile: r'''
part 'part.dart';
//   ^^^^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      part: r'''
// %before-language-feature: inference-update-2
part of 'test.dart';

class C {
  final int? _foo;
  C(this._foo);
}

void f(C c) {
  if (c._foo != null) {
    c._foo;
  }
}
''',
    });
    var result = results[part]!;

    var node = result.findNode.receiverPropertyExtraction('c._foo;');
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: _foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::_foo
    invokeType: int? Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <testLibrary>::@class::C::@getter::_foo
    staticType: int
  element: <testLibrary>::@class::C::@getter::_foo
  staticType: int
''');
  }
}
