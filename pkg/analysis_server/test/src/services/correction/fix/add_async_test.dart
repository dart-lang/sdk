// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddAsyncTest);
    defineReflectiveTests(AvoidReturningNullForFutureTest);
  });
}

@reflectiveTest
class AddAsyncTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_ASYNC;

  Future<void> test_asyncFor() async {
    await resolveTestUnit('''
import 'dart:async';
void main(Stream<String> names) {
  await for (String name in names) {
    print(name);
  }
}
''');
    await assertHasFix('''
import 'dart:async';
Future<void> main(Stream<String> names) async {
  await for (String name in names) {
    print(name);
  }
}
''');
  }

  Future<void> test_blockFunctionBody_function() async {
    await resolveTestUnit('''
foo() {}
main() {
  await foo();
}
''');
    await assertHasFix('''
foo() {}
main() async {
  await foo();
}
''');
  }

  Future<void> test_blockFunctionBody_getter() async {
    await resolveTestUnit('''
int get foo => null;
int f() {
  await foo;
  return 1;
}
''');
    await assertHasFix('''
int get foo => null;
Future<int> f() async {
  await foo;
  return 1;
}
''', errorFilter: (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT;
    });
  }

  Future<void> test_closure() async {
    await resolveTestUnit('''
import 'dart:async';

void takeFutureCallback(Future callback()) {}

void doStuff() => takeFutureCallback(() => await 1);
''');
    await assertHasFix('''
import 'dart:async';

void takeFutureCallback(Future callback()) {}

void doStuff() => takeFutureCallback(() async => await 1);
''', errorFilter: (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT;
    });
  }

  Future<void> test_expressionFunctionBody() async {
    await resolveTestUnit('''
foo() {}
main() => await foo();
''');
    await assertHasFix('''
foo() {}
main() async => await foo();
''');
  }

  Future<void> test_nullFunctionBody() async {
    await resolveTestUnit('''
var F = await;
''');
    await assertNoFix();
  }

  Future<void> test_returnFuture_alreadyFuture() async {
    await resolveTestUnit('''
import 'dart:async';
foo() {}
Future<int> main() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
import 'dart:async';
foo() {}
Future<int> main() async {
  await foo();
  return 42;
}
''', errorFilter: (AnalysisError error) {
      return error.errorCode == CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT;
    });
  }

  Future<void> test_returnFuture_dynamic() async {
    await resolveTestUnit('''
foo() {}
dynamic main() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
foo() {}
dynamic main() async {
  await foo();
  return 42;
}
''');
  }

  Future<void> test_returnFuture_nonFuture() async {
    await resolveTestUnit('''
foo() {}
int main() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
foo() {}
Future<int> main() async {
  await foo();
  return 42;
}
''');
  }

  Future<void> test_returnFuture_noType() async {
    await resolveTestUnit('''
foo() {}
main() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
foo() {}
main() async {
  await foo();
  return 42;
}
''');
  }
}

@reflectiveTest
class AvoidReturningNullForFutureTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_ASYNC;

  @override
  String get lintCode => LintNames.avoid_returning_null_for_future;

  Future<void> test_asyncFor() async {
    await resolveTestUnit('''
Future<String> f() {
  return null;
}
''');
    await assertHasFix('''
Future<String> f() async {
  return null;
}
''');
  }
}
