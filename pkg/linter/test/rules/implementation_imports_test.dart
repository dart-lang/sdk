// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementationImportsTest);
  });
}

@reflectiveTest
class ImplementationImportsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.implementation_imports;

  test_differentPackage_lib() async {
    newPackage('foo').addFile('lib/foo.dart', '');
    writeTestPackageConfig2();
    await assertNoDiagnostics(r'''
import 'package:foo/foo.dart';
// ignore_for_file: unused_import
''');
  }

  test_differentPackage_lib_inPart() async {
    newPackage('foo').addFile('lib/foo.dart', '');
    writeTestPackageConfig2();
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');
    await assertNoDiagnostics(r'''
part of 'a.dart';

import 'package:foo/foo.dart';
// ignore_for_file: unused_import
''');
  }

  test_differentPackage_src() async {
    newPackage('foo').addFile('lib/src/foo.dart', '');
    writeTestPackageConfig2();
    await assertDiagnosticsFromMarkup(r'''
import [!'package:foo/src/foo.dart'!];
// ignore_for_file: unused_import
''');
  }

  test_differentPackage_src_inPart() async {
    newPackage('foo').addFile('lib/src/foo.dart', '');
    writeTestPackageConfig2();
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');
    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

import [!'package:foo/src/foo.dart'!];
// ignore_for_file: unused_import
''');
  }

  test_differentPackage_src_inSubpart() async {
    newPackage('foo').addFile('lib/src/foo.dart', '');
    writeTestPackageConfig2();
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');
    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'test.dart';
''');
    await assertDiagnosticsFromMarkup(r'''
part of 'b.dart';

import [!'package:foo/src/foo.dart'!];
// ignore_for_file: unused_import
''');
  }

  test_samePackage_src() async {
    newFile('$testPackageLibPath/src/foo.dart', '');
    await assertNoDiagnostics(r'''
import 'package:test/src/foo.dart';
// ignore_for_file: unused_import
''');
  }

  test_samePackage_src_inPart() async {
    newFile('$testPackageLibPath/src/foo.dart', '');
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');
    await assertNoDiagnostics(r'''
part of 'a.dart';

import 'package:test/src/foo.dart';
// ignore_for_file: unused_import
''');
  }

  test_samePackage_src_inSubpart() async {
    newFile('$testPackageLibPath/src/foo.dart', '');
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');
    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'test.dart';
''');
    await assertNoDiagnostics(r'''
part of 'b.dart';

import 'package:test/src/foo.dart';
// ignore_for_file: unused_import
''');
  }
}
