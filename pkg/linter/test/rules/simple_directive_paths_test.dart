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
    await assertDiagnostics(
      r'''
export 'package:test/./a.dart';
''',
      [lint(7, 23)],
    );
  }

  Future<void> test_export_relative_minimal() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertNoDiagnostics(r'''
export 'a.dart';
''');
  }

  Future<void> test_export_relative_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnostics(
      r'''
export './a.dart';
''',
      [lint(7, 10)],
    );
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
    await assertDiagnostics(
      r'''
export 'a.dart' if (dart.library.io) './b.dart';
''',
      [lint(37, 10)],
    );
  }

  Future<void> test_import_escape() async {
    newFile('$testPackageLibPath/A.dart', '');
    await assertDiagnostics(
      r'''
export '%41.dart';
''',
      [lint(7, 10)],
    );
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
    var part = newFile('$testPackageLibPath/src/part.dart', r'''
part of 'lib.dart';
export './../a.dart';
''');
    await assertDiagnosticsInFile(part.path, [lint(27, 13)]);
  }

  Future<void> test_import_inTest_package_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    var b = newFile('$testPackageRootPath/test/b.dart', r'''
import 'package:test/./a.dart';
A? a;
''');
    await assertDiagnosticsInFile(b.path, [lint(7, 23)]);
  }

  Future<void> test_import_inTest_relative_nonMinimal() async {
    newFile('$testPackageRootPath/test/a.dart', 'class A {}');
    var b = newFile('$testPackageRootPath/test/b.dart', r'''
import './a.dart';
A? a;
''');
    await assertDiagnosticsInFile(b.path, [lint(7, 10)]);
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
    await assertDiagnostics(
      r'''
import 'package:test/./a.dart';
A? a;
''',
      [lint(7, 23)],
    );
  }

  Future<void> test_import_package_nonMinimal_backtracking() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    await assertDiagnostics(
      r'''
import 'package:test/src/../a.dart';
A? a;
''',
      [lint(7, 28)],
    );
  }

  Future<void> test_import_query() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnostics(
      r'''
export 'a.dart?key=val';
''',
      [lint(7, 16)],
    );
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
    await assertDiagnostics(
      r'''
import './a.dart';
A? a;
''',
      [lint(7, 10)],
    );
  }

  Future<void> test_import_relative_nonMinimal_backtracking() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    var b = newFile('$testPackageLibPath/src/b.dart', r'''
import '../src/../a.dart';
A? a;
''');
    await assertDiagnosticsInFile(b.path, [lint(7, 18)]);
  }

  Future<void> test_part() async {
    newFile('$testPackageLibPath/a.dart', 'part of "test.dart";');
    await assertDiagnostics(
      r'''
part './a.dart';
''',
      [lint(5, 10)],
    );
  }

  Future<void> test_partOf() async {
    newFile('$testPackageLibPath/test.dart', 'part "a.dart";');
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of './test.dart';
''');
    await assertDiagnosticsInFile(a.path, [lint(8, 13)]);
  }

  Future<void> test_raw_string() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnostics(
      r'''
export r'./a.dart';
''',
      [lint(7, 11)],
    );
  }

  Future<void> test_triple_quotes() async {
    newFile('$testPackageLibPath/a.dart', '');
    await assertDiagnostics("export '''./a.dart''';", [lint(7, 14)]);
  }
}
