// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_context.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddAsyncTest);
    defineReflectiveTests(AddAsyncWithNullSafetyTest);
    defineReflectiveTests(AvoidReturningNullForFutureTest);
  });
}

@reflectiveTest
class AddAsyncTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_ASYNC;

  Future<void> test_asyncFor() async {
    await resolveTestCode('''
void main(Stream<String> names) {
  await for (String name in names) {
    print(name);
  }
}
''');
    await assertHasFix('''
Future<void> main(Stream<String> names) async {
  await for (String name in names) {
    print(name);
  }
}
''');
  }

  Future<void> test_blockFunctionBody_function() async {
    await resolveTestCode('''
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
    await resolveTestCode('''
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
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT;
    });
  }

  Future<void> test_closure() async {
    await resolveTestCode('''
void takeFutureCallback(Future callback()) {}

void doStuff() => takeFutureCallback(() => await 1);
''');
    await assertHasFix('''
void takeFutureCallback(Future callback()) {}

void doStuff() => takeFutureCallback(() async => await 1);
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT;
    });
  }

  Future<void> test_expressionFunctionBody() async {
    await resolveTestCode('''
foo() {}
main() => await foo();
''');
    await assertHasFix('''
foo() {}
main() async => await foo();
''');
  }

  Future<void> test_missingReturn_hasReturn() async {
    await resolveTestCode('''
Future<int> f(bool b) {
  if (b) {
    return 0;
  }
}
''');
    await assertNoFix(errorFilter: (error) {
      return error.errorCode ==
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION;
    });
  }

  Future<void> test_missingReturn_notVoid() async {
    await resolveTestCode('''
Future<int> f() {
  print('');
}
''');
    await assertNoFix();
  }

  Future<void> test_missingReturn_void() async {
    await resolveTestCode('''
Future<void> f() {
  print('');
}
''');
    await assertHasFix('''
Future<void> f() async {
  print('');
}
''');
  }

  Future<void> test_nullFunctionBody() async {
    await resolveTestCode('''
var F = await;
''');
    await assertNoFix();
  }

  Future<void> test_returnFuture_alreadyFuture() async {
    await resolveTestCode('''
foo() {}
Future<int> main() {
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
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT;
    });
  }

  Future<void> test_returnFuture_dynamic() async {
    await resolveTestCode('''
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
    await resolveTestCode('''
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
    await resolveTestCode('''
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
class AddAsyncWithNullSafetyTest extends FixProcessorTest
    with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.ADD_ASYNC;

  Future<void> test_missingReturn_method_hasReturn() async {
    await resolveTestCode('''
class C {
  Future<int> m(bool b) {
    if (b) {
      return 0;
    }
  }
}
''');
    await assertNoFix(errorFilter: (error) {
      return error.errorCode ==
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD;
    });
  }

  Future<void> test_missingReturn_method_notVoid() async {
    await resolveTestCode('''
class C {
  Future<int> m() {
    print('');
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_missingReturn_method_notVoid_inherited() async {
    await resolveTestCode('''
abstract class A {
  Future<int> foo();
}

class B implements A {
  foo() {
  print('');
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_missingReturn_method_void() async {
    await resolveTestCode('''
class C {
  Future<void> m() {
    print('');
  }
}
''');
    await assertHasFix('''
class C {
  Future<void> m() async {
    print('');
  }
}
''');
  }

  Future<void> test_missingReturn_method_void_inherited() async {
    await resolveTestCode('''
abstract class A {
  Future<void> foo();
}

class B implements A {
  foo() {
  print('');
  }
}
''');
    await assertHasFix('''
abstract class A {
  Future<void> foo();
}

class B implements A {
  foo() async {
  print('');
  }
}
''');
  }

  Future<void> test_missingReturn_topLevel_hasReturn() async {
    await resolveTestCode('''
Future<int> f(bool b) {
  if (b) {
    return 0;
  }
}
''');
    await assertNoFix(errorFilter: (error) {
      return error.errorCode ==
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION;
    });
  }

  Future<void> test_missingReturn_topLevel_notVoid() async {
    await resolveTestCode('''
Future<int> f() {
  print('');
}
''');
    await assertNoFix();
  }

  Future<void> test_missingReturn_topLevel_void() async {
    await resolveTestCode('''
Future<void> f() {
  print('');
}
''');
    await assertHasFix('''
Future<void> f() async {
  print('');
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
    await resolveTestCode('''
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
