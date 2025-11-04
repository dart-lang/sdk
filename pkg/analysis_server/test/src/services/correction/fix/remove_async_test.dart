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
    defineReflectiveTests(RemoveAsyncIllegalReturnTest);
    defineReflectiveTests(RemoveAsyncTest);
  });
}

@reflectiveTest
class RemoveAsyncIllegalReturnTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeAsync;

  Future<void> test_invalidReturn() async {
    await resolveTestCode('''
int f() async {
  return '';
}
''');
    await assertNoFix();
  }

  Future<void> test_noReturn() async {
    await resolveTestCode('''
int f() async {
}
''');
    await assertHasFix('''
int f() {
}
''');
  }

  Future<void> test_returnInClosure() async {
    await resolveTestCode('''
int f() async {
  () {
    return '';
  };
}
''');
    await assertHasFix('''
int f() {
  () {
    return '';
  };
}
''');
  }

  Future<void> test_returnInClosureExpression() async {
    await resolveTestCode('''
int f() async {
  () => '';
}
''');
    await assertHasFix('''
int f() {
  () => '';
}
''');
  }

  Future<void> test_returnInClosureExpression2() async {
    await resolveTestCode('''
int f() async {
  () => 0;
  return '';
}
''');
    await assertNoFix();
  }

  Future<void> test_validReturn() async {
    await resolveTestCode('''
int f() async {
  return 0;
}
''');
    await assertHasFix('''
int f() {
  return 0;
}
''');
  }

  Future<void> test_wrongReturnInClosure() async {
    await resolveTestCode('''
int f() async {
  () {
    return '';
  };
}
''');
    await assertHasFix('''
int f() {
  () {
    return '';
  };
}
''');
  }

  Future<void> test_wrongReturnInClosureExpression() async {
    await resolveTestCode('''
int f() async {
  () => '';
}
''');
    await assertHasFix('''
int f() {
  () => '';
}
''');
  }
}

@reflectiveTest
class RemoveAsyncTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeAsync;

  @override
  String get lintCode => LintNames.unnecessary_async;

  Future<void> test_closure() async {
    await resolveTestCode('''
void f() {
  () async {};
}
''');
    await assertHasFix('''
void f() {
  () {};
}
''');
  }

  Future<void> test_future() async {
    await resolveTestCode('''
Future<void> test() async => Future.value(null);
''');
    await assertHasFix('''
Future<void> test() => Future.value(null);
''');
  }

  Future<void> test_futureOr() async {
    await resolveTestCode('''
import 'dart:async';

FutureOr<void> test() async {}
''');
    await assertHasFix('''
import 'dart:async';

FutureOr<void> test() {}
''');
  }

  Future<void> test_method() async {
    await resolveTestCode('''
import 'dart:async';

class A {
  FutureOr<void> test() async {}
}
''');
    await assertHasFix('''
import 'dart:async';

class A {
  FutureOr<void> test() {}
}
''');
  }

  Future<void> test_void() async {
    await resolveTestCode('''
void test() async {}
''');
    await assertHasFix('''
void test() {}
''');
  }
}
