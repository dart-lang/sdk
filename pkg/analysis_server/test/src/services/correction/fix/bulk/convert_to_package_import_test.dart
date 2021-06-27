// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../fix_processor.dart';
import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToPackageImportTest);
  });
}

@reflectiveTest
class ConvertToPackageImportTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_relative_lib_imports;

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44673')
  Future<void> test_singleFile() async {
    writeTestPackageConfig(config: PackageConfigFileBuilder());
    addSource('/home/test/lib/bar.dart', 'class Bar {}');

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
