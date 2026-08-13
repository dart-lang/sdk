// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimpleDirectivePathsTest);
  });
}

@reflectiveTest
class SimpleDirectivePathsTest extends LintRuleTest {
  @override
  String get lintRule => 'simple_directive_paths';

  Future<void> test_export_authority() async {
    await assertDiagnostics(
      r'''
export '//localhost/a.dart';
''',
      [error(diag.uriDoesNotExist, 7, 20)],
    );
  }

  Future<void> test_export_package_minimal() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertNoDiagnostics(r'''
export 'package:test/a.dart';
''');
  }

  Future<void> test_export_package_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnosticsFromMarkup(r'''
export [!'package:test/./a.dart'!];
''');
  }

  Future<void> test_export_relative_minimal() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertNoDiagnostics(r'''
export 'a.dart';
''');
  }

  Future<void> test_export_relative_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnosticsFromMarkup(r'''
export [!'./a.dart'!];
''');
  }

  Future<void> test_import_absolute_backtracking() async {
    await assertDiagnostics(
      r'''
export '/src/../a.dart';
''',
      [error(diag.uriDoesNotExist, 7, 16), lint(7, 16)],
    );
  }

  Future<void> test_import_absolute_backtracking_root() async {
    await assertDiagnostics(
      r'''
export '/../a.dart';
''',
      [error(diag.uriDoesNotExist, 7, 12), lint(7, 12)],
    );
  }

  Future<void> test_import_absolute_normalized() async {
    await assertDiagnostics(
      r'''
export '/a.dart';
''',
      [error(diag.uriDoesNotExist, 7, 9)],
    );
  }

  Future<void> test_import_absolute_unnormalized() async {
    await assertDiagnostics(
      r'''
export '/./a.dart';
''',
      [error(diag.uriDoesNotExist, 7, 11), lint(7, 11)],
    );
  }

  Future<void> test_import_conditional() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    await assertDiagnosticsFromMarkup(r'''
export 'a.dart' if (dart.library.io) [!'./b.dart'!];
''');
  }

  Future<void> test_import_escape() async {
    newFile('$testPackageLibPath/A.dart', '');
    await assertDiagnosticsFromMarkup(r'''
export [!'%41.dart'!];
''');
  }

  Future<void> test_import_fragment() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnostics(
      r'''
export 'a.dart#frag';
''',
      [error(diag.uriDoesNotExist, 7, 13), lint(7, 13)],
    );
  }

  Future<void> test_import_in_part_relative_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/src/lib.dart', "part 'part.dart';");
    await assertDiagnosticsInFileNameFromMarkup('src/part.dart', r'''
part of 'lib.dart';
export [!'./../a.dart'!];
''');
  }

  Future<void> test_import_inTest_package_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await assertDiagnosticsInTestDirFromMarkup(r'''
import [!'package:test/./a.dart'!];
A? a;
''');
  }

  Future<void> test_import_inTest_relative_nonMinimal() async {
    newFile('$testPackageRootPath/test/a.dart', 'class A {}');
    await assertDiagnosticsInTestDirFromMarkup(r'''
import [!'./a.dart'!];
A? a;
''');
  }

  Future<void> test_import_package_minimal() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await assertNoDiagnostics(r'''
import 'package:test/a.dart';
A? a;
''');
  }

  Future<void> test_import_package_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await assertDiagnosticsFromMarkup(r'''
import [!'package:test/./a.dart'!];
A? a;
''');
  }

  Future<void> test_import_package_nonMinimal_backtracking() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await assertDiagnosticsFromMarkup(r'''
import [!'package:test/src/../a.dart'!];
A? a;
''');
  }

  Future<void> test_import_query() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnosticsFromMarkup(r'''
export [!'a.dart?key=val'!];
''');
  }

  Future<void> test_import_relative_minimal() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await assertNoDiagnostics(r'''
import 'a.dart';
A? a;
''');
  }

  Future<void> test_import_relative_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await assertDiagnosticsFromMarkup(r'''
import [!'./a.dart'!];
A? a;
''');
  }

  Future<void> test_import_relative_nonMinimal_backtracking() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await assertDiagnosticsInFileNameFromMarkup('src/b.dart', r'''
import [!'../src/../a.dart'!];
A? a;
''');
  }

  Future<void> test_part() async {
    newFile('$testPackageLibPath/a.dart', 'part of "test.dart";');
    await assertDiagnosticsFromMarkup(r'''
part [!'./a.dart'!];
''');
  }

  Future<void> test_partOf() async {
    newFile('$testPackageLibPath/lib.dart', 'part "test.dart";');
    await assertDiagnosticsFromMarkup(r'''
part of [!'./lib.dart'!];
''');
  }

  Future<void> test_raw_string() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnosticsFromMarkup(r'''
export [!r'./a.dart'!];
''');
  }

  Future<void> test_triple_quotes() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnosticsFromMarkup("export [!'''./a.dart'''!];");
  }
}
