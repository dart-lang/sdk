// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
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

  test_withCodeBeforeAndAfter() async {
    await resolveTestUnit('''
class Person {
  String _fullName;
  void foo() {
    print('hi');
    /*LINT*/if (_fullName == null) {
      _fullName = getFullUserName(this);
    }
    print('hi');
  }
}
''');
    await assertHasFix('''
class Person {
  String _fullName;
  void foo() {
    print('hi');
    /*LINT*/_fullName ??= getFullUserName(this);
    print('hi');
  }
}
''');
  }

  test_withOneBlock() async {
    await resolveTestUnit('''
class Person {
  String _fullName;
  void foo() {
    /*LINT*/if (_fullName == null) {
      _fullName = getFullUserName(this);
    }
  }
}
''');
    await assertHasFix('''
class Person {
  String _fullName;
  void foo() {
    /*LINT*/_fullName ??= getFullUserName(this);
  }
}
''');
  }

  test_withoutBlock() async {
    await resolveTestUnit('''
class Person {
  String _fullName;
  void foo() {
    /*LINT*/if (_fullName == null)
      _fullName = getFullUserName(this);
  }
}
''');
    await assertHasFix('''
class Person {
  String _fullName;
  void foo() {
    /*LINT*/_fullName ??= getFullUserName(this);
  }
}
''');
  }

  test_withTwoBlock() async {
    await resolveTestUnit('''
class Person {
  String _fullName;
  void foo() {
    /*LINT*/if (_fullName == null) {{
      _fullName = getFullUserName(this);
    }}
  }
}
''');
    await assertHasFix('''
class Person {
  String _fullName;
  void foo() {
    /*LINT*/_fullName ??= getFullUserName(this);
  }
}
''');
  }
}
