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
    defineReflectiveTests(RemoveAwaitBulkTest);
    defineReflectiveTests(RemoveAwaitTest);
    defineReflectiveTests(UnnecessaryAwaitInReturnLintTest);
  });
}

@reflectiveTest
class RemoveAwaitBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.await_only_futures;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f() async {
  print(await 23);
}

f2() async {
  print(await 'hola');
}
''');
    await assertHasFix('''
f() async {
  print(23);
}

f2() async {
  print('hola');
}
''');
  }
}

@reflectiveTest
class RemoveAwaitTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_AWAIT;

  @override
  String get lintCode => LintNames.await_only_futures;

  Future<void> test_intLiteral() async {
    await resolveTestCode('''
bad() async {
  print(await 23);
}
''');
    await assertHasFix('''
bad() async {
  print(23);
}
''');
  }

  Future<void> test_stringLiteral() async {
    await resolveTestCode('''
bad() async {
  print(await 'hola');
}
''');
    await assertHasFix('''
bad() async {
  print('hola');
}
''');
  }
}

@reflectiveTest
class UnnecessaryAwaitInReturnLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_AWAIT;

  @override
  String get lintCode => LintNames.unnecessary_await_in_return;

  Future<void> test_arrow() async {
    await resolveTestCode(r'''
class A {
  Future<int> f() async => await future;
}
final future = Future.value(1);
''');
    await assertHasFix(r'''
class A {
  Future<int> f() async => future;
}
final future = Future.value(1);
''');
  }

  Future<void> test_expressionBody() async {
    await resolveTestCode(r'''
class A {
  Future<int> f() async {
    return await future;
  }
}
final future = Future.value(1);
''');
    await assertHasFix(r'''
class A {
  Future<int> f() async {
    return future;
  }
}
final future = Future.value(1);
''');
  }
}
