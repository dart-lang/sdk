// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFinalFieldsTest);
    defineReflectiveTests(PreferFinalLocalsTest);
  });
}

@reflectiveTest
class PreferFinalFieldsTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_final_fields;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  int _f = 2;
  var _f2 = 2;
  int get g => _f;
  int get g2 => _f2;
}
''');
    await assertHasFix('''
class C {
  final int _f = 2;
  final _f2 = 2;
  int get g => _f;
  int get g2 => _f2;
}
''');
  }
}

@reflectiveTest
class PreferFinalLocalsTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_final_locals;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f() {
  var x = 0;
  var y = x;
}
''');
    await assertHasFix('''
f() {
  final x = 0;
  final y = x;
}
''');
  }
}
