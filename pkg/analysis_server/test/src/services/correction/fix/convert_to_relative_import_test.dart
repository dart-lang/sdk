// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToRelativeImportBulkTest);
    defineReflectiveTests(ConvertToRelativeImportTest);
  });
}

@reflectiveTest
class ConvertToRelativeImportBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_relative_imports;

  Future<void> test_singleFile() async {
    newFile('$testPackageLibPath/foo.dart', '''
class C {}
''');
    newFile('$testPackageLibPath/bar.dart', '''
class D {}
''');
    testFilePath = convertPath('$testPackageLibPath/src/test.dart');

    await resolveTestCode('''
import 'package:test/bar.dart';
import 'package:test/foo.dart';
C c;
D d;
''');
    await assertHasFix('''
import '../bar.dart';
import '../foo.dart';
C c;
D d;
''');
  }
}

@reflectiveTest
class ConvertToRelativeImportTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_RELATIVE_IMPORT;

  @override
  String get lintCode => LintNames.prefer_relative_imports;

  Future<void> test_relativeImport() async {
    newFile('$testPackageLibPath/foo.dart', '''
class C {}
''');
    testFilePath = convertPath('$testPackageLibPath/src/test.dart');
    await resolveTestCode('''
import 'package:test/foo.dart';
C? c;
''');

    await assertHasFix('''
import '../foo.dart';
C? c;
''');
  }

  Future<void> test_relativeImportDifferentPackages() async {
    // Validate we don't get a fix with imports referencing different packages.
    newFile('/home/test1/lib/foo.dart', '');
    testFilePath = convertPath('/home/test2/lib/bar.dart');
    await resolveTestCode('''
import 'package:test1/foo.dart';
''');

    await assertNoFix();
  }

  Future<void> test_relativeImportGarbledUri() async {
    newFile('$testPackageLibPath/foo.dart', '');
    testFilePath = convertPath('$testPackageLibPath/bar.dart');
    await resolveTestCode('''
import 'package:test/foo';
''');

    await assertHasFix('''
import 'foo';
''',
        errorFilter: (error) =>
            error.errorCode != CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  Future<void> test_relativeImportRespectQuoteStyle() async {
    newFile('$testPackageLibPath/foo.dart', '''
class C {}
''');
    testFilePath = convertPath('$testPackageLibPath/bar.dart');
    await resolveTestCode('''
import "package:test/foo.dart";
C? c;
''');

    await assertHasFix('''
import "foo.dart";
C? c;
''');
  }

  Future<void> test_relativeImportSameDirectory() async {
    newFile('$testPackageLibPath/foo.dart', '''
class C {}
''');
    testFilePath = convertPath('$testPackageLibPath/bar.dart');
    await resolveTestCode('''
import 'package:test/foo.dart';
C? c;
''');

    await assertHasFix('''
import 'foo.dart';
C? c;
''');
  }

  Future<void> test_relativeImportSubDirectory() async {
    newFile('$testPackageLibPath/baz/foo.dart', '''
class C {}
''');
    testFilePath = convertPath('$testPackageLibPath/test.dart');
    await resolveTestCode('''
import 'package:test/baz/foo.dart';
C? c;
''');

    await assertHasFix('''
import 'baz/foo.dart';
C? c;
''');
  }
}
