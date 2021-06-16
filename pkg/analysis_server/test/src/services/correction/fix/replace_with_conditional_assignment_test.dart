// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithConditionalAssignmentTest);
  });
}

@reflectiveTest
class ReplaceWithConditionalAssignmentTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT;

  @override
  String get lintCode => LintNames.prefer_conditional_assignment;

  Future<void> test_withCodeBeforeAndAfter() async {
    await resolveTestCode('''
class Person {
  String _fullName;
  void foo() {
    print('hi');
    if (_fullName == null) {
      _fullName = getFullUserName(this);
    }
    print('hi');
  }
  String getFullUserName(Person p) => '';
}
''');
    await assertHasFix('''
class Person {
  String _fullName;
  void foo() {
    print('hi');
    _fullName ??= getFullUserName(this);
    print('hi');
  }
  String getFullUserName(Person p) => '';
}
''');
  }

  Future<void> test_withOneBlock() async {
    await resolveTestCode('''
class Person {
  String _fullName;
  void foo() {
    if (_fullName == null) {
      _fullName = getFullUserName(this);
    }
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
  String getFullUserName(Person p) => '';
}
''');
  }

  Future<void> test_withoutBlock() async {
    await resolveTestCode('''
class Person {
  String _fullName;
  void foo() {
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
  String getFullUserName(Person p) => '';
}
''');
  }

  Future<void> test_withTwoBlock() async {
    await resolveTestCode('''
class Person {
  String _fullName;
  void foo() {
    if (_fullName == null) {{
      _fullName = getFullUserName(this);
    }}
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
  String getFullUserName(Person p) => '';
}
''');
  }
}
