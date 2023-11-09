// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/dart/error/todo_codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToFlutterStyleTodoBulkTest);
    defineReflectiveTests(ConvertToFlutterStyleTodoTest);
  });
}

@reflectiveTest
class ConvertToFlutterStyleTodoBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.flutter_style_todos;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
// TODO(user) msg.
void f() {
  // todo(user) msg.
}
//TODO(user): msg.
void g() { }
''');
    await assertHasFix('''
// TODO(user): msg.
void f() {
  // TODO(user): msg.
}
// TODO(user): msg.
void g() { }
''');
  }
}

@reflectiveTest
class ConvertToFlutterStyleTodoTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_FLUTTER_STYLE_TODO;

  @override
  String get lintCode => LintNames.flutter_style_todos;

  Future<void> test_extraLeadingSpace() async {
    await resolveTestCode('''
//   TODO(user) msg.
void f() { }
''');
    await assertHasFix('''
// TODO(user): msg.
void f() { }
''', errorFilter: (e) => e.errorCode != TodoCode.TODO);
  }

  Future<void> test_lowerCase() async {
    await resolveTestCode('''
// todo(user): msg.
void f() { }
''');
    await assertHasFix('''
// TODO(user): msg.
void f() { }
''');
  }

  Future<void> test_missingColon() async {
    await resolveTestCode('''
// TODO(user) msg.
void f() { }
''');
    await assertHasFix('''
// TODO(user): msg.
void f() { }
''', errorFilter: (e) => e.errorCode != TodoCode.TODO);
  }

  Future<void> test_missingColon_surroundingComments() async {
    await resolveTestCode('''
// Leading comment.
// TODO(user) msg.
// Trailing comment.
void f() { }
''');
    await assertHasFix('''
// Leading comment.
// TODO(user): msg.
// Trailing comment.
void f() { }
''', errorFilter: (e) => e.errorCode != TodoCode.TODO);
  }

  Future<void> test_missingColonAndMessage() async {
    await resolveTestCode('''
// TODO(user)
void f() {}
''');
    await assertNoFix(errorFilter: (e) => e.errorCode != TodoCode.TODO);
  }

  Future<void> test_missingLeadingSpace() async {
    await resolveTestCode('''
//TODO(user): msg.
void f() {}
''');
    await assertHasFix('''
// TODO(user): msg.
void f() {}
''', errorFilter: (e) => e.errorCode != TodoCode.TODO);
  }

  Future<void> test_todoInContent() async {
    await resolveTestCode('''
// Here's a TODO
void f() { }
''');

    await assertNoFix(errorFilter: (e) => e.errorCode != TodoCode.TODO);
  }

  Future<void> test_unwantedSpaceBeforeUser() async {
    await resolveTestCode('''
// TODO (user): msg.
void f() {}
''');
    await assertHasFix('''
// TODO(user): msg.
void f() {}
''', errorFilter: (e) => e.errorCode != TodoCode.TODO);
  }
}
