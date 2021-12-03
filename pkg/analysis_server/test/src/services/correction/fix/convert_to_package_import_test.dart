// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToPackageImportBulkTest);
    defineReflectiveTests(ConvertToPackageImportTest);
  });
}

@reflectiveTest
class ConvertToPackageImportBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_relative_lib_imports;

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44673')
  Future<void> test_singleFile() async {
    writeTestPackageConfig(config: PackageConfigFileBuilder());
    addSource('$testPackageLibPath/bar.dart', 'class Bar {}');

    testFile = convertPath('/home/test/tool/test.dart');

    await resolveTestCode('''
import '../lib/bar.dart';

var bar = Bar();
''');
    await assertHasFix('''
import 'package:test/foo/bar.dart';

var bar = Bar();
''');
  }
}

@reflectiveTest
class ConvertToPackageImportTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_PACKAGE_IMPORT;

  @override
  String get lintCode => LintNames.avoid_relative_lib_imports;

  /// More coverage in the `convert_to_package_import_test.dart` assist test.
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44673')
  Future<void> test_relativeImport() async {
    // This test fails because any attempt to specify a relative path that
    // includes 'lib' (which the lint requires) results in a malformed URI when
    // trying to resolve the import.
    newFile('$testPackageLibPath/foo/bar.dart', content: '''
class C {}
''');
    await resolveTestCode('''
import '../lib/foo/bar.dart';

C c;
''');

    await assertHasFix('''
import 'package:test/lib/foo.dart';

C c;
''');
  }
}
