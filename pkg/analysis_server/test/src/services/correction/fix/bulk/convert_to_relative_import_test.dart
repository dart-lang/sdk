// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToRelativeImportTest);
  });
}

@reflectiveTest
class ConvertToRelativeImportTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_relative_imports;

  Future<void> test_singleFile() async {
    addSource('/home/test/lib/foo.dart', '''
class C {}
''');
    addSource('/home/test/lib/bar.dart', '''
class D {}
''');
    testFile = convertPath('/home/test/lib/src/test.dart');

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
