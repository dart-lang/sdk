// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddAwaitTest);
    defineReflectiveTests(AddAwaitTestArgumentAndAssignment);
  });
}

@reflectiveTest
class AddAwaitTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_AWAIT;

  @override
  String get lintCode => LintNames.unawaited_futures;

  Future<void> test_cascadeExpression() async {
    await resolveTestCode('''
class C {
  Future<String> something() {
    return Future.value('hello');
  }
}

void main() async {
  C()..something(); 
}
''');
    await assertNoFix();
  }

  Future<void> test_methodInvocation() async {
    await resolveTestCode('''
Future doSomething() => Future.value('');

void f() async {
  doSomething();
}
''');
    await assertHasFix('''
Future doSomething() => Future.value('');

void f() async {
  await doSomething();
}
''');
  }

  Future<void> test_methodInvocationWithParserError() async {
    await resolveTestCode('''
Future doSomething() => Future.value('');

void f() async {
  doSomething()
}
''');
    await assertHasFix('''
Future doSomething() => Future.value('');

void f() async {
  await doSomething()
}
''', errorFilter: (error) => error.errorCode != ParserErrorCode.EXPECTED_TOKEN);
  }

  Future<void> test_nonBoolCondition_futureBool() async {
    await resolveTestCode('''
Future<bool> doSomething() async => true;

Future<void> f() async {
  if (doSomething()) {
  }
}
''');
    await assertHasFix('''
Future<bool> doSomething() async => true;

Future<void> f() async {
  if (await doSomething()) {
  }
}
''');
  }

  Future<void> test_nonBoolCondition_futureInt() async {
    await resolveTestCode('''
Future<int> doSomething() async => 0;

Future<void> f() async {
  if (doSomething()) {
  }
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class AddAwaitTestArgumentAndAssignment extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_AWAIT;

  Future<void> test_stringNamedParameter_futureInt() async {
    await resolveTestCode('''
void foo({required String s}) {}

Future<int> bar() async => 0;

void baz() {
  foo(s: bar());
}
''');
    await assertNoFix();
  }

  Future<void> test_stringNamedParameter_futureString() async {
    await resolveTestCode('''
void foo({required String s}) {}

Future<String> bar() async => '';

void baz() {
  foo(s: bar());
}
''');
    await assertHasFix('''
void foo({required String s}) {}

Future<String> bar() async => '';

void baz() {
  foo(s: await bar());
}
''');
  }

  Future<void> test_stringParameter_futureInt() async {
    await resolveTestCode('''
void foo(String s) {}

Future<int> bar() async => 0;

void baz() {
  foo(bar());
}
''');
    await assertNoFix();
  }

  Future<void> test_stringParameter_futureString() async {
    await resolveTestCode('''
void foo(String s) {}

Future<String> bar() async => '';

void baz() {
  foo(bar());
}
''');
    await assertHasFix('''
void foo(String s) {}

Future<String> bar() async => '';

void baz() {
  foo(await bar());
}
''');
  }

  Future<void> test_stringVariable_assignment_futureString() async {
    await resolveTestCode('''
Future<String> bar() async => '';

void baz() {
  String? variable;
  variable = bar();
}
''');
    await assertHasFix(
      '''
Future<String> bar() async => '';

void baz() {
  String? variable;
  variable = await bar();
}
''',
      errorFilter:
          (error) => error.errorCode == CompileTimeErrorCode.INVALID_ASSIGNMENT,
    );
  }

  Future<void> test_stringVariable_futureInt() async {
    await resolveTestCode('''
Future<int> bar() async => 0;

void baz() {
  String variable = bar();
}
''');
    await assertNoFix(
      errorFilter:
          (error) => error.errorCode == CompileTimeErrorCode.INVALID_ASSIGNMENT,
    );
  }

  Future<void> test_stringVariable_futureString() async {
    await resolveTestCode('''
Future<String> bar() async => '';

void baz() {
  String variable = bar();
}
''');
    await assertHasFix(
      '''
Future<String> bar() async => '';

void baz() {
  String variable = await bar();
}
''',
      errorFilter:
          (error) => error.errorCode == CompileTimeErrorCode.INVALID_ASSIGNMENT,
    );
  }
}
