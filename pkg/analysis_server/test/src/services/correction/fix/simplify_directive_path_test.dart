// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimplifyDirectivePathBulkTest);
    defineReflectiveTests(SimplifyDirectivePathTest);
  });
}

@reflectiveTest
class SimplifyDirectivePathBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => 'simple_directive_paths';

  Future<void> test_bulk() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    testFilePath = convertPath('$testPackageLibPath/test.dart');

    await resolveTestCode('''
export './a.dart';
export './b.dart';
''');
    await assertHasFix('''
export 'a.dart';
export 'b.dart';
''');
  }
}

@reflectiveTest
class SimplifyDirectivePathTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.simplifyDirectivePath;

  @override
  String get lintCode => 'simple_directive_paths';

  Future<void> test_absolute_backtracking() async {
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export '/src/../a.dart';
''');

    await assertHasFix(
      '''
export '/a.dart';
''',
      filter: (error) =>
          error.diagnosticCode.lowerCaseName == 'simple_directive_paths',
    );
  }

  Future<void> test_absolute_unnormalized() async {
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export '/./a.dart';
''');

    await assertHasFix(
      '''
export '/a.dart';
''',
      filter: (error) =>
          error.diagnosticCode.lowerCaseName == 'simple_directive_paths',
    );
  }

  Future<void> test_adjacentStrings() async {
    newFile('$testPackageLibPath/a.dart', '');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export './' 'a.dart';
''');

    await assertHasFix('''
export 'a.dart';
''');
  }

  Future<void> test_conditional() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');
    testFilePath = convertPath('$testPackageLibPath/test.dart');
    await resolveTestCode('''
export 'a.dart' if (dart.library.io) './b.dart';
''');

    await assertHasFix('''
export 'a.dart' if (dart.library.io) 'b.dart';
''');
  }

  Future<void> test_escape() async {
    newFile('$testPackageLibPath/A.dart', '');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export '%41.dart';
''');

    await assertHasFix('''
export 'A.dart';
''');
  }

  Future<void> test_export_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', '');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export './a.dart';
''');

    await assertHasFix('''
export 'a.dart';
''');
  }

  Future<void> test_export_nonMinimal_backtracking() async {
    newFile('$testPackageLibPath/a.dart', '');
    testFilePath = convertPath('$testPackageLibPath/src/b.dart');
    await resolveTestCode('''
export '../src/../a.dart';
''');

    await assertHasFix('''
export '../a.dart';
''');
  }

  Future<void> test_export_nonMinimal_sameDirectory() async {
    newFile('$testPackageLibPath/a.dart', '');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export './a.dart';
''');

    await assertHasFix('''
export 'a.dart';
''');
  }

  Future<void> test_export_package_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', '');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export 'package:test/./a.dart';
''');

    await assertHasFix('''
export 'package:test/a.dart';
''');
  }

  Future<void> test_fragment() async {
    newFile('$testPackageLibPath/a.dart', '');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export 'a.dart#frag';
''');

    await assertHasFix(
      '''
export 'a.dart';
''',
      filter: (error) =>
          error.diagnosticCode.lowerCaseName == 'simple_directive_paths',
    );
  }

  Future<void> test_import_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
import './a.dart';
A? a;
''');

    await assertHasFix('''
import 'a.dart';
A? a;
''');
  }

  Future<void> test_in_part_relative_nonMinimal() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/src/lib.dart', "part 'part.dart';");
    testFilePath = convertPath('$testPackageLibPath/src/part.dart');
    await resolveTestCode(r'''
part of 'lib.dart';
export './../a.dart';
''');

    await assertHasFix(r'''
part of 'lib.dart';
export '../a.dart';
''');
  }

  Future<void> test_inTest_relative_nonMinimal() async {
    newFile('$testPackageRootPath/test/a.dart', 'class A {}');
    testFilePath = convertPath('$testPackageRootPath/test/b.dart');
    await resolveTestCode('''
import './a.dart';
A? a;
''');

    await assertHasFix('''
import 'a.dart';
A? a;
''');
  }

  Future<void> test_package_backtracking() async {
    newFile('$testPackageLibPath/a.dart', '');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export 'package:test/src/../a.dart';
''');

    await assertHasFix('''
export 'package:test/a.dart';
''');
  }

  Future<void> test_part() async {
    newFile('$testPackageLibPath/a.dart', 'part of "test.dart";');
    testFilePath = convertPath('$testPackageLibPath/test.dart');
    await resolveTestCode('''
part './a.dart';
''');

    await assertHasFix('''
part 'a.dart';
''');
  }

  Future<void> test_partOf() async {
    newFile('$testPackageLibPath/test.dart', 'part "a.dart";');
    testFilePath = convertPath('$testPackageLibPath/a.dart');
    await resolveTestCode('''
part of './test.dart';
''');

    await assertHasFix('''
part of 'test.dart';
''');
  }

  Future<void> test_query() async {
    newFile('$testPackageLibPath/a.dart', '');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export 'a.dart?key=val';
''');

    await assertHasFix('''
export 'a.dart';
''');
  }

  Future<void> test_raw_string() async {
    newFile('$testPackageLibPath/a.dart', '');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export r'./a.dart';
''');

    await assertHasFix('''
export r'a.dart';
''');
  }

  Future<void> test_triple_quotes() async {
    newFile('$testPackageLibPath/a.dart', '');
    testFilePath = convertPath('$testPackageLibPath/b.dart');
    await resolveTestCode('''
export \'\'\'./a.dart\'\'\';
''');

    await assertHasFix('''
export \'\'\'a.dart\'\'\';
''');
  }
}
