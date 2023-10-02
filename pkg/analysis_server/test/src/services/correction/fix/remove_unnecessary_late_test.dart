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
    defineReflectiveTests(RemoveUnnecessaryLateBulkTest);
    defineReflectiveTests(RemoveUnnecessaryLateTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryLateBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_late;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
late String s1 = '';
late final String s2 = '';
''');
    await assertHasFix('''
String s1 = '';
final String s2 = '';
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryLateTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_LATE;

  @override
  String get lintCode => LintNames.unnecessary_late;

  Future<void> test_static() async {
    await resolveTestCode('''
class C {
  static late String s1 = '';
}
''');
    await assertHasFix('''
class C {
  static String s1 = '';
}
''');
  }

  Future<void> test_topLevel() async {
    await resolveTestCode('''
late String s1 = '';
''');
    await assertHasFix('''
String s1 = '';
''');
  }

  Future<void> test_topLevel_multipleVariables_fixFirst() async {
    await resolveTestCode('''
late String s1 = '', s2 = '';
''');
    await assertHasFix('''
String s1 = '', s2 = '';
''');
  }

  Future<void> test_topLevel_multipleVariables_fixSecond() async {
    await resolveTestCode('''
late String s1 = '', s2 = '';
''');
    await assertHasFix('''
String s1 = '', s2 = '';
''');
  }
}
