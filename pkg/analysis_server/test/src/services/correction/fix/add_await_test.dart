// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddAwaitTest);
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
