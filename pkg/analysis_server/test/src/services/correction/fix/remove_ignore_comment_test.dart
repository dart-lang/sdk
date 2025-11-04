// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryIgnoreCommentTest);
    defineReflectiveTests(RemoveUnnecessaryIgnoreCommentBulkTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryIgnoreCommentBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_ignore;

  Future<void> test_file() async {
    await resolveTestCode('''
// ignore_for_file: unused_local_variable
// ignore_for_file: return_of_invalid_type
void f(){}
''');
    await assertHasFix('''
void f(){}
''');
  }

  Future<void> test_line() async {
    await resolveTestCode('''
class C {
  // ignore: unused_local_variable
  // ignore: return_of_invalid_type
  void f(){}
}
''');
    await assertHasFix('''
class C {
  void f(){}
}
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryIgnoreCommentTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeUnnecessaryIgnoreComment;
  @override
  String get lintCode => LintNames.unnecessary_ignore;
  Future<void> test_file() async {
    await resolveTestCode('''
// ignore_for_file: unused_local_variable
void f(){}
''');
    await assertHasFix('''
void f(){}
''');
  }

  Future<void> test_line() async {
    await resolveTestCode('''
class C {
  // ignore: unused_local_variable
  void f(){}
}
''');
    await assertHasFix('''
class C {
  void f(){}
}
''');
  }

  Future<void> test_line_eol() async {
    await resolveTestCode('''
class C {
  void f(){} // ignore: unused_local_variable
}
''');
    await assertHasFix('''
class C {
  void f(){}
}
''');
  }
}
