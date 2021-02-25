// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToNullAwareTest);
  });
}

@reflectiveTest
class ConvertToNullAwareTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_NULL_AWARE;

  Future<void> test_equal_differentTarget() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a1, A a2) => a1 == null ? null : a2.m();
''');
    await assertNoAssistAt('?');
  }

  Future<void> test_equal_notComparedToNull() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a1, A a2) => a1 == a2 ? a2.m() : a1.m();
''');
    await assertNoAssistAt('?');
  }

  Future<void> test_equal_notIdentifier() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a) => a.m() == null ? 0 : a.m();
''');
    await assertNoAssistAt('?');
  }

  Future<void> test_equal_notInvocation() async {
    await resolveTestCode('''
abstract class A {
  int m();
  int operator +(A a);
}
int f(A a1) => a1 == null ? null : a1 + a1;
''');
    await assertNoAssistAt('?');
  }

  Future<void> test_equal_notNullPreserving() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a1, A a2) => a1 == null ? a2.m() : a1.m();
''');
    await assertNoAssistAt('?');
  }

  Future<void> test_equal_notPeriod() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a1) => a1 == null ? null : a1?.m();
''');
    await assertNoAssistAt('? ');
  }

  Future<void> test_equal_nullOnLeft() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a) => null == a ? null : a.m();
''');
    await assertHasAssistAt('?', '''
abstract class A {
  int m();
}
int f(A a) => a?.m();
''');
  }

  Future<void> test_equal_nullOnLeft_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_null_aware_operators]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a) => null == a ? null : a.m();
''');
    await assertNoAssist();
  }

  Future<void> test_equal_nullOnRight() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a) => a == null ? null : a.m();
''');
    await assertHasAssistAt('?', '''
abstract class A {
  int m();
}
int f(A a) => a?.m();
''');
  }

  Future<void> test_equal_prefixedIdentifier() async {
    await resolveTestCode('''
class A {
  int p;
}
int f(A a) => null == a ? null : a.p;
''');
    await assertHasAssistAt('?', '''
class A {
  int p;
}
int f(A a) => a?.p;
''');
  }

  Future<void> test_notEqual_noTarget() async {
    // https://github.com/dart-lang/sdk/issues/44173
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
foo() {
  var range = 1;
  var rangeStart = range != null ? toOffset() : null;
}
''');
    await assertNoAssistAt(' null;');
  }

  Future<void> test_notEqual_notNullPreserving() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a1, A a2) => a1 != null ? a1.m() : a2.m();
''');
    await assertNoAssistAt('?');
  }

  Future<void> test_notEqual_nullOnLeft() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a) => null != a ? a.m() : null;
''');
    await assertHasAssistAt('?', '''
abstract class A {
  int m();
}
int f(A a) => a?.m();
''');
  }

  Future<void> test_notEqual_nullOnRight() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int f(A a) => a != null ? a.m() : null;
''');
    await assertHasAssistAt('?', '''
abstract class A {
  int m();
}
int f(A a) => a?.m();
''');
  }
}
