// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveQuestionMarkTest);
  });
}

@reflectiveTest
class RemoveQuestionMarkTest extends BulkFixProcessorTest {
  @override
  String get lintCode =>
      LintNames.unnecessary_nullable_for_final_variable_declarations;

  @override
  String get testPackageLanguageVersion => latestLanguageVersion;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  static final int? x = 0;
  static final int? y = 0;
}
''');
    await assertHasFix('''
class C {
  static final int x = 0;
  static final int y = 0;
}
''');
  }
}
