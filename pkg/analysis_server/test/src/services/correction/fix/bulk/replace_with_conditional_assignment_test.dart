// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithConditionalAssignmentTest);
  });
}

@reflectiveTest
class ReplaceWithConditionalAssignmentTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_conditional_assignment;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class Person {
  String _fullName;
  void foo() {
    if (_fullName == null) {
      _fullName = getFullUserName(this);
    }
  }
  void bar() {
    if (_fullName == null)
      _fullName = getFullUserName(this);
  }
  String getFullUserName(Person p) => '';
}
''');
    await assertHasFix('''
class Person {
  String _fullName;
  void foo() {
    _fullName ??= getFullUserName(this);
  }
  void bar() {
    _fullName ??= getFullUserName(this);
  }
  String getFullUserName(Person p) => '';
}
''');
  }
}
